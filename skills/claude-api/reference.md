# Anthropic Claude API — Engineering Best Practices

A durable, global reference for building any Claude-API app. All code uses the official
Anthropic **Python** SDK (`pip install anthropic`). Verified against the live docs
(`platform.claude.com/docs`) on **2026-06-23**. Source URLs are inline so every claim is checkable.

> **The one rule that pays for itself:** if you send the same long system prompt + few-shot
> examples on every request and only the user input changes, **prompt caching** (below) cuts
> your input cost ~90% and your latency materially. Set it up first.

---

## Quick reference — models (verified vs docs)

Source: <https://platform.claude.com/docs/en/about-claude/models/overview> · <https://platform.claude.com/docs/en/about-claude/pricing>

| Model | API ID | Input $/MTok | Output $/MTok | Context | Max output | Vision |
|---|---|---:|---:|---|---|---|
| Claude Opus 4.8 | `claude-opus-4-8` | $5.00 | $25.00 | 1M | 128K | ✅ |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | $3.00 | $15.00 | 1M | 128K | ✅ |
| Claude Haiku 4.5 | `claude-haiku-4-5` | $1.00 | $5.00 | 200K | 64K | ✅ |
| Claude Fable 5 | `claude-fable-5` | $10.00 | $50.00 | 1M | 128K | ✅ |

- **All current models support text + image (vision) input and multilingual.**
- Use exact ID strings — **do not append date suffixes** to current-gen IDs (`claude-opus-4-8`, not `...-20260xxx`). Haiku's pinned ID is `claude-haiku-4-5-20251001`; the alias `claude-haiku-4-5` resolves to it.
- Max-output values are for the synchronous Messages API; the Batches API can go to 300K output with the `output-300k-2026-03-24` beta header.
- `max_tokens > ~16000` non-streaming risks an SDK HTTP timeout — **stream** for large outputs (use `.stream()` + `.get_final_message()`).

### Picking a model
- **Haiku 4.5** — high-volume, latency-critical, simple work (classification, routing, short extraction). Cheapest.
- **Sonnet 4.6** — the default production workhorse; best speed/intelligence balance.
- **Opus 4.8** — hardest reasoning, long-horizon agentic, when correctness > cost.
- **Fable 5** — most capable widely-released model; demanding reasoning/long-horizon only. Premium pricing, different API surface (always-on thinking, refusal handling, 30-day retention required). Use only when explicitly chosen.

---

## Prompt caching (PRIORITY)

Source: <https://platform.claude.com/docs/en/build-with-claude/prompt-caching>

### The one invariant everything follows from
**Caching is a prefix match. Any byte change anywhere in the prefix invalidates everything after it.**
Render order is `tools` → `system` → `messages`. Keep stable content first; put volatile content
(timestamps, per-request IDs, the varying user input) **after** the last `cache_control` breakpoint.

### What can carry `cache_control`
- **System** content blocks
- **Tool** definitions (in `tools`)
- **Message** content blocks: text, **images**, documents/PDFs, `tool_use`, and `tool_result` (user *and* assistant turns)
- **Cannot** be marked directly: thinking blocks (they cache alongside the surrounding assistant turn), sub-blocks like citations (cache the parent), empty text blocks.

### TTL and minimum thresholds
- TTL: **5 minutes (default)** or **1 hour** (`"ttl": "1h"`). The cache is **refreshed for free on every hit** — continuous traffic keeps it warm indefinitely; the TTL is an *idle* expiry.
- Max **4** `cache_control` breakpoints per request.
- **Minimum cacheable prefix (model-specific).** Below the minimum, content silently won't cache (no error; `cache_creation_input_tokens: 0`):

  | Model | Minimum |
  |---|---:|
  | **Opus 4.8** | **1,024** |
  | **Sonnet 4.6** | **1,024** |
  | **Haiku 4.5** | **4,096** |
  | Fable 5 | 512 |
  | Opus 4.7 | 2,048 |
  | Opus 4.6 | 4,096 |

  (These are corrected against the live docs — note Opus 4.8 is **1,024**, not 4,096.)

### How hits/misses are billed (multipliers on base input price)
- **Cache write (miss / first write):** 5-min TTL = **1.25×**; 1-hour TTL = **2×**.
- **Cache read (hit):** **0.1×** baseline — but **0.5× on Opus 4.8** and **0.3× on Fable 5**. Budget the read multiplier for *your* model.
- **Uncached input:** 1× (full price). Cache breakpoints themselves are free.
- **Break-even (5-min TTL):** ~2 requests (1.25× write + 0.1× read = 1.35× vs 2× uncached). 1-hour TTL needs ~3 reads to pay off its 2× write.

### Verify it's working — the `usage` response
```python
u = response.usage
u.cache_creation_input_tokens  # tokens written to cache this request (paid 1.25× or 2×)
u.cache_read_input_tokens      # tokens served from cache this request (paid ~0.1×/0.5×)
u.input_tokens                 # uncached remainder (full price), AFTER the last breakpoint
# total prompt size = creation + read + input_tokens
```
If `cache_read_input_tokens` stays **0** across repeated identical-prefix requests, a silent
invalidator is at work (see below). Diff the rendered prompt bytes between two requests to find it.

### Invalidation hierarchy (only your tier and below break)
| Change | Tools | System | Messages |
|---|:--:|:--:|:--:|
| Tool defs add/remove/reorder · model switch | ❌ | ❌ | ❌ |
| `tool_choice`, images toggle, `thinking` toggle, web-search/citations/`speed` | varies | varies | ❌ |
| System prompt content | ✅ | ❌ | ❌ |
| Message content | ✅ | ✅ | ❌ |

So you can flip `tool_choice` or toggle thinking per-request without losing the tools+system cache.
**Tool-definition and model changes force a full rebuild** — never change tools or model mid-conversation.

### Silent invalidators (grep your prompt-assembly path for these)
| Pattern | Why it breaks |
|---|---|
| `datetime.now()` / `time.time()` in system prompt | prefix differs every request |
| `uuid4()` / request IDs early in content | every request unique |
| `json.dumps(d)` without `sort_keys=True` / iterating a `set` | nondeterministic byte order |
| f-string interpolating user/session ID into system prompt | per-user prefix, no sharing |
| `if flag: system += ...` conditional sections | each combo is a distinct prefix |
| `tools=build_tools(user)` varying per user | tools at position 0 → nothing caches |

**Fix:** move the dynamic piece *after* the last breakpoint, make it deterministic, or delete it.

### Structuring the prompt: stable prefix cached, variable suffix not
The exact pattern for a classifier/drafter — frozen system + few-shot cached, only the user input varies:

```python
import anthropic
client = anthropic.Anthropic()

SYSTEM = [
    {"type": "text", "text": INSTRUCTIONS_AND_FIELD_DEFINITIONS},   # frozen
    {"type": "text", "text": FEW_SHOT_EXAMPLES,                     # frozen
     "cache_control": {"type": "ephemeral"}},                       # breakpoint on last stable block
]

def classify(email_body: str):
    resp = client.messages.create(
        model="claude-opus-4-8",
        max_tokens=1024,
        system=SYSTEM,                                  # tools + system render before messages → cached together
        messages=[{"role": "user", "content": email_body}],  # the ONLY thing that changes — no breakpoint here
    )
    print(resp.usage.cache_read_input_tokens)           # should be > 0 from the 2nd call on
    return resp
```

If you also use tools, put the breakpoint on the last system block — tools render first, so one
marker caches tools + system. Keep tool order deterministic (sort by name).

### Multi-turn placement
Put a breakpoint on the **last content block of the most recent turn**; each request reuses the prior
conversation prefix. Watch the **20-block lookback window**: a single turn adding >20 content blocks
(agentic loops with many tool_use/tool_result pairs) can push the next breakpoint out of range —
add an intermediate breakpoint every ~15 blocks.

### Automatic caching (simplest)
Top-level `cache_control={"type": "ephemeral"}` on `messages.create()` auto-places the breakpoint on
the last cacheable block. Use it when you don't need fine-grained placement.

### Pre-warming (kill first-request latency)
Send a `max_tokens: 0` request at startup with the breakpoint on the **shared** block (not the
placeholder user message). It runs prefill, writes the cache, returns `content: []` immediately, bills
only the cache-write. Re-warm within the TTL if traffic has idle gaps; skip it if traffic is continuous.

### Caching gotchas
- Caches are **per-model** and **per-workspace** (org-level on Bedrock/Vertex). Forking an operation
  (summarize, sub-agent) must reuse the parent's exact `system`/`tools`/`model` or it misses entirely.
- N parallel requests with the same prefix all pay full price — the cache is readable only once the
  first response *begins streaming*. Fan-out: fire 1, await first token, then fire the rest.
- **Automatic caching is not on Bedrock/Vertex** (explicit `cache_control` works there).

---

## Message Batches API (50% off, async)

Source: <https://platform.claude.com/docs/en/build-with-claude/batch-processing>

For non-latency-sensitive bulk work (evals, backfills, bulk classification): **50% of standard price**,
all token types.
- Endpoint: `POST /v1/messages/batches`. Limits: **100,000 requests or 256 MB**, whichever first.
- Most batches finish **< 1 hour**; hard max **24 hours** (else `expired`, unbilled).
- Results available **29 days** after creation.
- Supports **everything** the Messages API does — vision, tools, prompt caching.
- **Results return in any order — key by `custom_id`, never by position.**

```python
from anthropic.types.message_create_params import MessageCreateParamsNonStreaming
from anthropic.types.messages.batch_create_params import Request

batch = client.messages.batches.create(requests=[
    Request(custom_id=f"email-{i}",
            params=MessageCreateParamsNonStreaming(
                model="claude-haiku-4-5", max_tokens=256,
                system=SYSTEM,  # shared cached system works across all requests in the batch
                messages=[{"role": "user", "content": body}]))
    for i, body in enumerate(bodies)
])

import time
while client.messages.batches.retrieve(batch.id).processing_status != "ended":
    time.sleep(30)

results = {}
for r in client.messages.batches.results(batch.id):     # arbitrary order
    if r.result.type == "succeeded":
        results[r.custom_id] = r.result.message.content
# r.result.type ∈ succeeded | errored | canceled | expired
```

---

## Token counting

Source: <https://platform.claude.com/docs/en/build-with-claude/token-counting>

Count before you send — for cost estimates, routing, and context-fit. **Free** (subject to a separate
RPM limit: 100/2,000/4,000/8,000 by tier). **Never use `tiktoken`** — it's OpenAI's tokenizer and
undercounts Claude by ~15–20%+.

```python
n = client.messages.count_tokens(
    model="claude-opus-4-8",
    system=SYSTEM,
    tools=tools,        # accepts the same shape as create(): system, tools, images, PDFs
    messages=messages,
).input_tokens          # → {"input_tokens": N}; an estimate, model-specific
```
Token counting is **stateless** and does **not** use caching. Previous-turn thinking blocks are
excluded; current-turn thinking counts.

---

## Tool use / function calling + structured output

Source: <https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview> · <https://platform.claude.com/docs/en/build-with-claude/structured-outputs>

### Tool definition
```python
tools = [{
    "name": "categorize_email",
    "description": "Categorize an email. Call this for every incoming email.",  # be prescriptive about WHEN
    "input_schema": {
        "type": "object",
        "properties": {
            "category": {"type": "string", "enum": ["refund", "shipping", "other"]},
            "confidence": {"type": "number"},
        },
        "required": ["category", "confidence"],
        "additionalProperties": False,
    },
}]
```
`tool_choice`: `{"type":"auto"}` (default) · `{"type":"any"}` (must use some tool) ·
`{"type":"tool","name":"..."}` (force one) · `{"type":"none"}`.

### Force a tool call to get validated JSON
The cleanest way to get a guaranteed-shape struct out of Claude — force the tool, then read `.input`:
```python
resp = client.messages.create(
    model="claude-opus-4-8", max_tokens=1024, tools=tools,
    tool_choice={"type": "tool", "name": "categorize_email"},
    messages=[{"role": "user", "content": email_body}],
)
block = next(b for b in resp.content if b.type == "tool_use")
data = block.input    # already parsed dict matching the schema
```
Add `"strict": True` (top-level on the tool def, alongside `name`/`input_schema`; requires
`additionalProperties: False` + `required`) to **guarantee** the input validates exactly.

### Structured outputs (alternative to tools, for response JSON)
- `client.messages.parse(..., output_format=MyPydanticModel)` → `resp.parsed_output` is a validated instance.
- Or raw schema via `output_config={"format": {"type": "json_schema", "schema": {...}}}`.
- Supported: Opus 4.8, Sonnet 4.6, Haiku 4.5, Fable 5. **Incompatible with citations** (400).
- The old top-level `output_format` param on `create()` is deprecated — use `output_config.format`.

### Loop hygiene
Always parse `tool_use.input` as structured data — **never raw-string-match** the serialized input
(4.6+/Fable escape JSON differently). Return **all** parallel `tool_result` blocks in **one** user
message (splitting them trains Claude to stop parallelizing). Failed tool → `tool_result` with
`"is_error": True`, don't drop it.

---

## Vision / image input

Source: <https://platform.claude.com/docs/en/build-with-claude/vision>

```python
import base64
img = base64.standard_b64encode(open("photo.png", "rb").read()).decode()  # no newlines
client.messages.create(model="claude-opus-4-8", max_tokens=1024, messages=[{
    "role": "user",
    "content": [
        {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": img}},
        {"type": "text", "text": "What's in this image?"},
    ],
}])
```
- Also `{"type":"image","source":{"type":"url","url":...}}`, or a Files-API `file_id`.
- **Images and caching:** an image block can carry `cache_control` and caches like any other block.
  But toggling images on/off invalidates the **system** cache tier and below (not just messages) —
  keep image presence stable across cached requests where possible.

---

## Streaming

Source: <https://platform.claude.com/docs/en/build-with-claude/streaming>

Default to streaming for long input/output or high `max_tokens` (avoids HTTP timeouts):
```python
with client.messages.stream(model="claude-opus-4-8", max_tokens=64000,
                            messages=[{"role": "user", "content": "..."}]) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
    final = stream.get_final_message()   # full Message, even when streaming — use this, don't hand-roll
```
The SDK **raises `ValueError`** for non-streaming requests it estimates will exceed ~10 min — pass
`stream=True` or override `timeout`. `message_delta` events carry `stop_reason` + usage.

---

## Error handling, retries, rate limits

Source: <https://platform.claude.com/docs/en/api/errors> · <https://platform.claude.com/docs/en/api/rate-limits>

| Code | Type | Retryable | Cause |
|---|---|---|---|
| 400 | `invalid_request_error` | No | malformed / bad params |
| 401 | `authentication_error` | No | bad/missing key |
| 403 | `permission_error` | No | key lacks access |
| 404 | `not_found_error` | No | bad model ID / endpoint |
| 413 | `request_too_large` | No | request too big |
| 429 | `rate_limit_error` | **Yes** | RPM/TPM/TPD exceeded — read `retry-after` |
| 500 | `api_error` | **Yes** | transient server error |
| 529 | `overloaded_error` | **Yes** | API overloaded — back off (or try Haiku) |

**The SDK already retries 408/409/429/5xx + connection errors with exponential backoff** (default
`max_retries=2`). Configure rather than reimplement:
```python
client = anthropic.Anthropic(max_retries=5, timeout=30.0)
client.with_options(max_retries=0).messages.create(...)   # per-request override
```
Catch a **chain, most-specific-first** — don't collapse retryable and fatal into one `except`:
```python
try:
    resp = client.messages.create(...)
except anthropic.NotFoundError:        # 404 — bad model, don't retry
    ...
except anthropic.RateLimitError as e:  # 429 — back off
    wait = int(e.response.headers.get("retry-after", "60"))
except anthropic.APIStatusError as e:  # other non-2xx
    if e.status_code >= 500: ...       # retryable
except anthropic.APIConnectionError:   # network, before any response
    ...
```
- **Idempotency:** Batches use `custom_id` for de-dup; for unary calls, since SDK retries are
  transparent, guard side-effecting work (sends, writes) with your own idempotency key keyed off the
  request, not the response.
- Log `response._request_id` (the `request-id` header) when reporting issues to Anthropic.

---

## System prompt, temperature, max_tokens, stop sequences

Sources: <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering> · model overview

- **System prompt:** put role, rules, output format, and few-shot here — and **keep it byte-frozen**
  for caching (inject dynamic context into `messages`, not the system prompt). On 4.6+ models,
  dial back aggressive `CRITICAL:`/`MUST`/`If in doubt` language — they over-trigger.
- **`temperature`:** 0.0–1.0; pass *either* `temperature` or `top_p`, never both (400 on Claude 4+).
  **Removed entirely on Opus 4.7/4.8 and Fable 5** (sending it → 400) — steer via prompting + `effort`.
- **`max_tokens`:** required. Default ~16000 non-streaming (timeout safety), ~64000 streaming. Lower
  only with reason (classification ~256, cost caps, or `max_tokens: 0` for cache pre-warm). Hitting the
  cap gives `stop_reason: "max_tokens"` and truncates mid-thought.
- **`stop_sequences`:** list of strings that end generation early; `stop_reason: "stop_sequence"`.
- **Always check `stop_reason`** before reading `content`: `end_turn` | `max_tokens` | `stop_sequence`
  | `tool_use` | `pause_turn` | `refusal`. On `refusal`, `content` may be empty — guard index access.
- **Thinking (Opus 4.6/4.7/4.8, Sonnet 4.6):** use `thinking={"type":"adaptive"}` +
  `output_config={"effort": "low|medium|high|max"}`. `budget_tokens` is removed on 4.7/4.8 (400).

---

## Cost-optimization checklist

1. **Cache the stable prefix.** Frozen system + few-shot behind a `cache_control` breakpoint; only the
   variable input after it. Verify `cache_read_input_tokens > 0`. Biggest single lever (~90% input savings).
2. **Batch anything non-latency-sensitive** → 50% off. Stacks with caching.
3. **Right-size the model.** Haiku for classification/routing, Sonnet for the workhorse, Opus only
   where correctness dominates. Don't default everything to the biggest model.
4. **Discipline `max_tokens`.** Set it to the realistic ceiling per task (classification → ~256), not a
   blanket large number — you're billed for output generated, and oversized caps invite verbosity.
5. **Count before you send** (free) to estimate cost and catch context-fit problems early.
6. **Lower `effort` / disable thinking** on routine work; reserve high effort for hard tasks.
7. **Keep tools + model stable** within a conversation so the cache survives the whole session.

---

## Email-triage classifier/drafter — caching takeaways (the headline)

For an app that sends the **same long system prompt + few-shot on every request, varying only the
email body**: put the frozen instructions, field/category definitions, and few-shot examples in the
`system` array with a single `cache_control: {"type": "ephemeral"}` breakpoint on the **last stable
block**, and pass the email body as the **only** content after it (in `messages`, no breakpoint). The
shared prefix is written to cache once and read at ~0.1× base input price on every subsequent request
(≈0.5× on Opus 4.8) — roughly a 90% input-cost cut on the bulk of each prompt and a real latency
drop, with the 5-minute TTL auto-refreshing on every hit so steady traffic keeps it warm for free
(pre-warm with a `max_tokens: 0` call to kill cold-start latency). The discipline that makes or breaks
it: keep that prefix **byte-identical** — no `datetime.now()`, UUIDs, per-user IDs, unsorted
`json.dumps`, or conditional system sections anywhere in it, and never change the tool set or model
mid-stream, since any of those silently zeroes `cache_read_input_tokens` and you pay full price for
the whole prompt. Confirm it's actually working by asserting `cache_read_input_tokens > 0` from the
second request on. Make sure the prefix clears the minimum cacheable size for your model (**1,024
tokens on Opus 4.8/Sonnet 4.6, 4,096 on Haiku 4.5**) — below it, caching silently no-ops. Stack with
the Batches API (another 50% off) for any triage that doesn't need a real-time reply.
