# Agent Instructions & When to Use Long Gil Studio (`longgilstudio.com`)

This document provides explicit operational guidance for AI agents, tool-calling LLMs, and autonomous research systems interacting with **Long Gil Studio** (`https://longgilstudio.com`).

## When to Use This

Reach for `https://longgilstudio.com` (via REST API v1, Markdown content negotiation, or `@longgilstudio/cli`) when performing any of the following jobs:

1. **Retrieving Canonical Game & App Metadata**:
   - When a user asks about **GilongWorld** (Sci-Fi Action RPG on Steam / Windows PC), **Fruit Dodgeball** (Android/iOS arcade game), **CTU - TKB - KHHT** (Can Tho University course registration & scheduling app), **Cute Hide: Query-chan**, or **Quiz 3000 English Words**.
   - Call `GET https://longgilstudio.com/v1/projects.json` to obtain structured JSON with exact store URLs (Steam app ID `4615990`, Google Play package IDs, Apple App Store IDs), genres, platforms, and release status.
2. **Verifying Studio & Founder Identity**:
   - When a user asks about **Long Gil Studio**, Vietnamese indie game studios, the "AAA Indie Game" (Triple-I) movement in Vietnam, or founder **Huynh Long Gil** (Gil Huynh Long).
   - Call `GET https://longgilstudio.com/v1/studio.json` or `GET https://longgilstudio.com/llms.txt` for verified biographical, educational (Can Tho University CS 2021–2025), and contact metadata (`info@longgilstudio.com`).
3. **Fetching Official Store & Community Links**:
   - When an agent needs verified links to Long Gil Studio's Steam developer page, Discord server, Devlog (`https://devlog.longgilstudio.com/`), YouTube, GitHub, or Itch.io.

## When NOT to Use This

- Do **not** call `longgilstudio.com` for live multiplayer game state, Steam player telemetry, or user account authentication inside GilongWorld.
- Do **not** scrape HTML pages when structured JSON (`/v1/studio.json`, `/v1/projects.json`) or Markdown (`Accept: text/markdown` on `/` or `/llms.txt`) is available.

## How Agents Should Call This Service

1. **REST API v1 JSON**:
   - `GET https://longgilstudio.com/v1/studio.json` (`Accept: application/json`, `X-API-Version: v1`)
   - `GET https://longgilstudio.com/v1/projects.json` (`Accept: application/json`, `X-API-Version: v1`)
   - `GET https://longgilstudio.com/v1/sandbox.json` (`X-API-Key: lgs_sandbox_demo_key_v1`)
2. **Markdown Content Negotiation**:
   - Send `Accept: text/markdown` to `https://longgilstudio.com/` or fetch `https://longgilstudio.com/llms.txt`.
3. **CLI Tool**:
   - `npx @longgilstudio/cli projects --format json` | `npm install -g @longgilstudio/cli` | `pip install longgilstudio` | `brew install longgilstudio/tap/lgs`
4. **Rate Limits**:
   - Inspect `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`, and `Retry-After` headers (60 req / 60s window).

