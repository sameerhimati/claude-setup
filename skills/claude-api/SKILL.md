---
name: claude-api
description: >-
  Reference for the Claude API and Anthropic SDK. Use when adding prompt caching or
  cache_control to an Anthropic API call, writing or debugging code against the Claude API,
  choosing between Claude models, or answering questions about model ids, pricing, rate limits,
  streaming, tool use, token counting, or migration.
allowed-tools: Read, Grep, WebFetch, WebSearch
---

# Claude API Engineering

When the task touches the Claude/Anthropic API, read `reference.md` in this skill directory FIRST — it is the verified source of truth for model IDs, pricing, prompt caching, tool use, batching, streaming, and error handling. Model IDs and pricing drift; do not answer from training memory.

## When to use (TRIGGER)
Read `reference.md` before opening the target file whenever:
- The prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`).
- The user asks about an LLM's pricing, model choice, limits, or caching.
- The task is LLM-shaped with the provider unstated (agent / MCP / tool-definition / multi-agent / RAG / LLM-judge; generate/summarize/extract/classify/rewrite over natural language; debugging refusals/cutoffs/streaming/tool-calls/tokens).

## When to skip (SKIP)
Skip only when another provider is clearly the subject: OpenAI/GPT, Gemini, Llama, Mistral, Cohere, or Ollama is named, or the project imports those SDKs. If no provider is named, grep the project for those imports first.

## Non-negotiable
Prompt caching for any app resending a stable prefix: add `cache_control` breakpoints and verify via `cache_read_input_tokens` in the usage response. See `reference.md` → Prompt Caching.

End with a completion status (DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT).
