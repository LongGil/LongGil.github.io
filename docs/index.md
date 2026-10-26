# Long Gil Studio — API Documentation (`/docs`)

Complete REST API v1 reference for **Long Gil Studio** (`https://longgilstudio.com`). For interactive sandbox testing and API keys, visit [https://longgilstudio.com/developers](https://longgilstudio.com/developers).

## Authentication

All public read endpoints (`GET /v1/studio.json`, `GET /v1/projects.json`, `GET /openapi.json`, `GET /llms.txt`) require no authentication (`auth: none`). For sandbox testing, pass `X-API-Key: lgs_sandbox_demo_key_v1`.

## Endpoints & Example Requests

```bash
# 1. Studio metadata
curl -sS https://longgilstudio.com/v1/studio.json -H "Accept: application/json" -H "X-API-Version: v1"

# 2. Projects catalog
curl -sS https://longgilstudio.com/v1/projects.json -H "Accept: application/json" -H "X-API-Version: v1"

# 3. Sandbox environment
curl -sS https://longgilstudio.com/v1/sandbox.json -H "X-API-Key: lgs_sandbox_demo_key_v1"

# 4. CLI usage
npx @longgilstudio/cli projects --format json
```

## Rate Limits & Versioning

- **Rate Limit Headers**: `RateLimit-Limit: 60`, `RateLimit-Remaining: 59`, `RateLimit-Reset: 60`, `RateLimit-Policy: 60;w=60`, and `Retry-After: 60` on HTTP `429`.
- **Versioning & Deprecation**: URL path `/v1/` and header `X-API-Version: v1`, with 90-day notice via `Deprecation` (RFC 9745) and `Sunset` (RFC 8594) headers.

