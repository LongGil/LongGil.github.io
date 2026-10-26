# Long Gil Studio — Developer Portal & API Documentation

Welcome to the official Developer Portal for **Long Gil Studio** (`https://longgilstudio.com/developers`). This portal provides quickstart guides, authentication and sandbox API keys, interactive sandbox endpoints, CLI tooling, and full REST API v1 documentation.

## 1. Quickstart Guide

Fetch structured JSON data from our REST API v1 or request Markdown content negotiation:

```bash
# Fetch studio metadata, founder profile, and versioning policy
curl -sS https://longgilstudio.com/v1/studio.json \
  -H "Accept: application/json" \
  -H "X-API-Version: v1"

# Fetch complete games & applications catalog
curl -sS https://longgilstudio.com/v1/projects.json \
  -H "Accept: application/json" \
  -H "X-API-Version: v1"

# Request homepage in Markdown via Content Negotiation
curl -sS -L -H "Accept: text/markdown" https://longgilstudio.com/
```

## 2. Authentication & API Keys

- **Public Read-Only Access**: All catalog and discovery endpoints (`GET /v1/studio.json`, `GET /v1/projects.json`, `GET /openapi.json`, `GET /llms.txt`) require no authentication (`auth: none`).
- **Sandbox API Key**: Use `lgs_sandbox_demo_key_v1` via `X-API-Key: lgs_sandbox_demo_key_v1` or `Authorization: Bearer lgs_sandbox_demo_key_v1` to test authenticated agent flows.
- **Partner API Keys**: Request dedicated partner keys via `info@longgilstudio.com`.

## 3. Sandbox Environment

- **Sandbox Endpoint**: [https://longgilstudio.com/v1/sandbox.json](https://longgilstudio.com/v1/sandbox.json)
- **Sandbox Header**: Pass `X-Sandbox-Mode: true` and `X-API-Key: lgs_sandbox_demo_key_v1` to any `/v1/*` endpoint.

## 4. Official CLI Tool (`@longgilstudio/cli`)

Agents and developers can script interactions with Long Gil Studio using our CLI tool:

```bash
# Run via npx (npm)
npx @longgilstudio/cli info
npx @longgilstudio/cli projects --format json

# Install via npm, PyPI, or Homebrew
npm install -g @longgilstudio/cli
pip install longgilstudio
brew install longgilstudio/tap/lgs

# Or run the standalone ESM script directly
curl -sS https://longgilstudio.com/cli/lgs.mjs -o lgs.mjs && node lgs.mjs projects
```

- **CLI Package Manifest**: [https://longgilstudio.com/cli/package.json](https://longgilstudio.com/cli/package.json)
- **CLI Standalone Script**: [https://longgilstudio.com/cli/lgs.mjs](https://longgilstudio.com/cli/lgs.mjs)

## 5. REST API v1 Endpoints & Specifications

- `GET /v1/studio.json` — Studio profile, founder biography, and API versioning metadata.
- `GET /v1/projects.json` — Catalog of PC and mobile games/apps (`GilongWorld`, `Fruit Dodgeball`, `CTU-KHHT`, `Cute Hide: Query-chan`, `Quiz 3000 English Words`).
- `GET /v1/sandbox.json` — Sandbox environment health, test API keys, and rate-limit configuration.
- `GET /openapi.json` & `GET /api/openapi.yaml` — OpenAPI 3.1.0 specification.
- `GET /llms.txt` & `GET /AGENTS.md` — Agent instructions and when-to-use guidance.

## 6. Rate Limits & Versioning Policy

- **Rate Limit Headers**: Every API response includes `RateLimit-Limit: 60`, `RateLimit-Remaining: 59`, `RateLimit-Reset: 60`, `RateLimit-Policy: 60;w=60`, and `RateLimit: limit=60, remaining=59, reset=60` (plus `Retry-After: 60` on HTTP `429 Too Many Requests`).
- **Versioning**: URL path versioning (`/v1/`) and `X-API-Version: v1` header.
- **Deprecation**: Deprecated endpoints emit `Deprecation` (RFC 9745) and `Sunset` (RFC 8594) headers at least 90 days before removal.

