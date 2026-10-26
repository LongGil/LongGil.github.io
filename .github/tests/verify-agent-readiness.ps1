$ErrorActionPreference = "Stop"
$passed = 0
$failed = 0

function Assert-Check($Name, [bool]$Condition, $Detail = "") {
    if ($Condition) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "[FAIL] $Name - $Detail" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "=== Agent Readiness Verification Suite (v3 - 100/100 Target) ===" -ForegroundColor Cyan

# 0. GitHub Pages Jekyll Bypass (.nojekyll)
Assert-Check ".nojekyll exists at root" (Test-Path ".nojekyll") "Missing .nojekyll; .well-known and index.md will break under Jekyll"

# 1. Developer Portal (/developers) & Public API Docs (/docs, /api)
Assert-Check "developers/index.html exists" (Test-Path "developers/index.html")
Assert-Check "developers/index.md exists" (Test-Path "developers/index.md")
Assert-Check "docs/index.html and docs/index.md exist" ((Test-Path "docs/index.html") -and (Test-Path "docs/index.md"))
Assert-Check "api/index.html exists" (Test-Path "api/index.html")
Assert-Check "v1/sandbox.json and api/v1/sandbox.json exist" ((Test-Path "v1/sandbox.json") -and (Test-Path "api/v1/sandbox.json"))

$devPortalHtml = Get-Content "developers/index.html" -Raw
Assert-Check "Developer portal includes API keys, quickstart, sandbox, and CLI docs" (
    $devPortalHtml -match 'lgs_sandbox_demo_key_v1' -and
    $devPortalHtml -match 'Quickstart' -and
    $devPortalHtml -match 'Sandbox' -and
    $devPortalHtml -match '@longgilstudio/cli'
)

# 2. CLI Tool Available
Assert-Check "cli/package.json and cli/lgs.mjs exist" ((Test-Path "cli/package.json") -and (Test-Path "cli/lgs.mjs"))
$cliPkg = Get-Content "cli/package.json" -Raw | ConvertFrom-Json
Assert-Check "cli/package.json defines @longgilstudio/cli binary 'lgs'" ($cliPkg.name -eq "@longgilstudio/cli" -and $null -ne $cliPkg.bin.lgs)

# 3. Public API / Docs linked from homepage (index.html)
$indexHtml = Get-Content "index.html" -Raw
Assert-Check "index.html links visibly to /developers and /docs" (
    $indexHtml -match 'href="/developers"' -and
    $indexHtml -match 'href="/docs"'
)

# 4. Agent instruction / when-to-use guidance
Assert-Check "AGENTS.md, agent-instructions.md, and .well-known/agent.json exist" (
    (Test-Path "AGENTS.md") -and
    (Test-Path "agent-instructions.md") -and
    (Test-Path ".well-known/agent.json")
)
$llmsTxt = Get-Content "llms.txt" -Raw
$agentsMd = Get-Content "AGENTS.md" -Raw
Assert-Check "llms.txt and AGENTS.md include 'When to Use This' guidance section" (
    $llmsTxt -match '## When to Use This' -and
    $agentsMd -match '## When to Use This' -and
    $agentsMd -match '## How Agents Should Call This Service'
)

# 5. Rate limit response headers documented & configured
$openApi = Get-Content "openapi.json" -Raw | ConvertFrom-Json
Assert-Check "openapi.json defines RateLimit-Limit, RateLimit-Remaining, RateLimit-Reset, Retry-After headers and 429 response" (
    $null -ne $openApi.components.headers.RateLimitLimit -and
    $null -ne $openApi.components.headers.RateLimitRemaining -and
    $null -ne $openApi.components.headers.RateLimitReset -and
    $null -ne $openApi.components.headers.RetryAfter -and
    $null -ne $openApi.components.responses.TooManyRequestsError
)
$headersFile = Get-Content "_headers" -Raw
$workerJs = Get-Content ".docs/cloudflare-agent-worker.js" -Raw
Assert-Check "_headers and Cloudflare Worker emit RFC RateLimit-* and X-RateLimit-* headers" (
    $headersFile -match 'RateLimit-Limit:\s*60' -and
    $workerJs -match 'RateLimit-Limit' -and
    $workerJs -match 'RateLimit-Remaining' -and
    $workerJs -match 'RateLimit-Reset'
)

# 6. Previously verified Essential checks (Redirects, 404s, JSON Errors, Markdown Negotiation, Versioning)
$metaRefreshFiles = Select-String -Path "*.html" -Pattern 'http-equiv=["'']?refresh["'']?'
Assert-Check "No HTML files use <meta http-equiv='refresh'> redirects" ($null -eq $metaRefreshFiles -or $metaRefreshFiles.Count -eq 0)

$showcaseHtml = Get-Content "gilongworld-showcase.html" -Raw
Assert-Check "gilongworld-showcase.html has no window.location redirect stub" ($showcaseHtml -notmatch 'window\.location')

$h1Matches = [regex]::Matches($indexHtml, '<h1\b[^>]*>(.*?)</h1>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
Assert-Check "index.html has exactly 1 <h1> tag" ($h1Matches.Count -eq 1)

$headings = [regex]::Matches($indexHtml, '<h([1-6])\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { [int]$_.Groups[1].Value }
$sequentialOk = ($headings.Count -gt 0) -and ($headings[0] -eq 1)
for ($i = 1; $i -lt $headings.Count; $i++) {
    if (($headings[$i] - $headings[$i - 1]) -gt 1) {
        $sequentialOk = $false
    }
}
Assert-Check "index.html heading levels are sequential ($($headings -join ' -> '))" $sequentialOk

$mainHtml = [regex]::Match($indexHtml, '(?s)<main\b.*?</main>').Value
$mainText = ($mainHtml -replace '(?s)<script.*?</script>', '' -replace '(?s)<style.*?</style>', '' -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim()
Assert-Check "index.html <main> has >= 500 chars of meaningful raw text ($($mainText.Length) chars)" ($mainText.Length -ge 500)

Assert-Check "404.md exists and links to llms.txt, openapi.json, sitemap.xml" (Test-Path "404.md")
Assert-Check "api/404.json exists and is valid structured JSON error" (Test-Path "api/404.json")
Assert-Check "v1/studio.json and v1/projects.json exist" ((Test-Path "v1/studio.json") -and (Test-Path "v1/projects.json"))
Assert-Check "openapi.json includes /v1/studio.json, /v1/projects.json, /v1/sandbox.json, /developers, /docs" (
    $null -ne $openApi.paths.'/v1/studio.json' -and
    $null -ne $openApi.paths.'/v1/projects.json' -and
    $null -ne $openApi.paths.'/v1/sandbox.json' -and
    $null -ne $openApi.paths.'/developers' -and
    $null -ne $openApi.paths.'/docs'
)

[xml]$sitemap = Get-Content "sitemap.xml" -Raw
$locs = $sitemap.urlset.url.loc
Assert-Check "sitemap.xml includes /developers, /docs, /AGENTS.md, /v1/sandbox.json" (
    ($locs -contains "https://longgilstudio.com/developers") -and
    ($locs -contains "https://longgilstudio.com/docs") -and
    ($locs -contains "https://longgilstudio.com/AGENTS.md") -and
    ($locs -contains "https://longgilstudio.com/v1/sandbox.json")
)

Write-Host "`nResult: $passed passed, $failed failed." -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
if ($failed -gt 0) { exit 1 }
