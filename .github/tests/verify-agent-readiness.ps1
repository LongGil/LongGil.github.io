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

Write-Host "=== Agent Readiness Verification Suite (v2) ===" -ForegroundColor Cyan

# 0. GitHub Pages Jekyll Bypass (.nojekyll)
Assert-Check ".nojekyll exists at root" (Test-Path ".nojekyll") "Missing .nojekyll; .well-known and index.md will break under Jekyll"

# 1. Issue #1: Redirects resolve cleanly (No meta-refresh or stub redirects)
$metaRefreshFiles = Select-String -Path "*.html" -Pattern 'http-equiv=["'']?refresh["'']?'
Assert-Check "No HTML files use <meta http-equiv='refresh'> redirects" ($null -eq $metaRefreshFiles -or $metaRefreshFiles.Count -eq 0) "Found meta-refresh in HTML files"

$showcaseHtml = Get-Content "gilongworld-showcase.html" -Raw
Assert-Check "gilongworld-showcase.html has no window.location redirect stub" ($showcaseHtml -notmatch 'window\.location')
Assert-Check "gilongworld-showcase.html has full semantic content (>= 500 chars) and <h1>" ($showcaseHtml.Length -ge 500 -and $showcaseHtml -match '<h1\b')

$legacyShowcaseLinks = Select-String -Path "index.html","cv.html","hire-me.html","404.html","sitemap.xml" -Pattern 'gilongworld-showcase\.html'
Assert-Check "All pages & sitemap link directly to https://gilongworld.com/ instead of gilongworld-showcase.html" ($null -eq $legacyShowcaseLinks -or $legacyShowcaseLinks.Count -eq 0)

# Content available without JS & Heading Hierarchy
$indexHtml = Get-Content "index.html" -Raw
$h1Matches = [regex]::Matches($indexHtml, '<h1\b[^>]*>(.*?)</h1>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
Assert-Check "index.html has exactly 1 <h1> tag" ($h1Matches.Count -eq 1) "Found $($h1Matches.Count) <h1> tags"

$headings = [regex]::Matches($indexHtml, '<h([1-6])\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { [int]$_.Groups[1].Value }
$sequentialOk = ($headings.Count -gt 0) -and ($headings[0] -eq 1)
for ($i = 1; $i -lt $headings.Count; $i++) {
    if (($headings[$i] - $headings[$i - 1]) -gt 1) {
        $sequentialOk = $false
    }
}
Assert-Check "index.html heading levels are sequential ($($headings -join ' -> '))" $sequentialOk "Heading sequence jumped a level"

$mainHtml = [regex]::Match($indexHtml, '(?s)<main\b.*?</main>').Value
$mainText = ($mainHtml -replace '(?s)<script.*?</script>', '' -replace '(?s)<style.*?</style>', '' -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim()
Assert-Check "index.html <main> has >= 500 chars of meaningful raw text ($($mainText.Length) chars)" ($mainText.Length -ge 500) "Only $($mainText.Length) chars"

$unescapedData = [regex]::Matches($indexHtml, 'data-(vi|en)="[^"]*<[^"]*"')
Assert-Check "No unescaped HTML tags inside data-vi/data-en attributes" ($unescapedData.Count -eq 0) "Found $($unescapedData.Count) unescaped tags"
Assert-Check "index.html has <noscript> fallback for Loader-Page & FAQ" ($indexHtml -match '<noscript>' -and $indexHtml -match '\.spinner-wrapper\s*\{\s*display:\s*none')

$dhCss = Get-Content "assets/css/dh-card-image-left-dark.css" -Raw
$indexCss = Get-Content "assets/css/index-styles.css" -Raw
Assert-Check "dh-card-image-left-dark.css styles .photo-details h2" ($dhCss -match '\.photo-details h2')
Assert-Check "index-styles.css styles .photo-details h2" ($indexCss -match '\.photo-details h2')

# 2. Issue #2: Agent-friendly 404s (Markdown error body & links)
Assert-Check "404.md exists" (Test-Path "404.md")
$md404 = Get-Content "404.md" -Raw
Assert-Check "404.md has >= 100 chars and links to llms.txt, openapi.json, sitemap.xml" (
    $md404.Length -ge 100 -and
    $md404 -match 'llms\.txt' -and
    $md404 -match 'openapi\.json' -and
    $md404 -match 'sitemap\.xml'
)
$html404 = Get-Content "404.html" -Raw
Assert-Check "404.html embeds application/problem+json and links to 404.md & llms.txt" (
    $html404 -match 'application/problem\+json' -and
    $html404 -match '404\.md' -and
    $html404 -match 'llms\.txt'
)

# 3. Issue #3: JSON error responses & OpenAPI Spec
Assert-Check "openapi.json exists" (Test-Path "openapi.json")
Assert-Check "api/openapi.yaml exists" (Test-Path "api/openapi.yaml")
$openApi = Get-Content "openapi.json" -Raw | ConvertFrom-Json
Assert-Check "openapi.json is valid OpenAPI 3.1.0" ($openApi.openapi -eq "3.1.0")
Assert-Check "openapi.json defines components.schemas.ErrorResponse with code, message, hint, resolution" (
    $null -ne $openApi.components.schemas.ErrorResponse.properties.code -and
    $null -ne $openApi.components.schemas.ErrorResponse.properties.message -and
    $null -ne $openApi.components.schemas.ErrorResponse.properties.hint -and
    $null -ne $openApi.components.schemas.ErrorResponse.properties.resolution
)
Assert-Check "api/404.json exists and contains code, status, message, hint, resolution, and error object" (Test-Path "api/404.json")
$errJson = Get-Content "api/404.json" -Raw | ConvertFrom-Json
Assert-Check "api/404.json schema validation" (
    $errJson.code -eq "RESOURCE_NOT_FOUND" -and
    $errJson.status -eq 404 -and
    $errJson.hint.Length -gt 10 -and
    $errJson.resolution.Length -gt 10 -and
    $null -ne $errJson.error
)

# 4. Issue #4: Markdown Content Negotiation
Assert-Check "index.md exists, starts with H1 (# ), >= 500 chars" ((Test-Path "index.md") -and (Get-Content "index.md" -Raw).StartsWith("# ") -and (Get-Content "index.md" -Raw).Length -ge 500)
Assert-Check "openapi.json documents '/' with text/markdown & Vary header" ($null -ne $openApi.paths.'/'.get.responses.'200'.content.'text/markdown' -and $null -ne $openApi.paths.'/'.get.responses.'200'.headers.Vary)
$workerJs = Get-Content ".docs/cloudflare-agent-worker.js" -Raw
Assert-Check "Cloudflare Worker handles Accept: text/markdown on / and 404, plus JSON 404 and 301 redirects" (
    $workerJs -match 'text/markdown' -and
    $workerJs -match 'Vary' -and
    $workerJs -match 'REDIRECT_MAP' -and
    $workerJs -match 'RESOURCE_NOT_FOUND'
)

# 5. Issue #5: REST Versioning (/v1/) & Deprecation Policy
Assert-Check "v1/studio.json and api/v1/studio.json exist" ((Test-Path "v1/studio.json") -and (Test-Path "api/v1/studio.json"))
Assert-Check "v1/projects.json and api/v1/projects.json exist" ((Test-Path "v1/projects.json") -and (Test-Path "api/v1/projects.json"))
$studioV1 = Get-Content "v1/studio.json" -Raw | ConvertFrom-Json
$projectsV1 = Get-Content "v1/projects.json" -Raw | ConvertFrom-Json
Assert-Check "v1/studio.json has api_version='v1' and deprecation policy object" ($studioV1.api_version -eq "v1" -and $null -ne $studioV1.deprecation.policy)
Assert-Check "v1/projects.json has api_version='v1' and 5 projects" ($projectsV1.api_version -eq "v1" -and $projectsV1.projects.Count -eq 5)
Assert-Check "openapi.json includes /v1/studio.json & /v1/projects.json paths" (
    $null -ne $openApi.paths.'/v1/studio.json' -and
    $null -ne $openApi.paths.'/v1/projects.json'
)
Assert-Check "openapi.json defines ApiVersionHeader (X-API-Version) and Deprecation/Sunset headers" (
    $openApi.components.parameters.ApiVersionHeader.name -eq "X-API-Version" -and
    $null -ne $openApi.components.headers.Deprecation -and
    $null -ne $openApi.components.headers.Sunset -and
    $openApi.info.description -match 'Deprecation' -and
    $openApi.info.description -match 'Sunset'
)

# 6. Robots.txt & Sitemap XML validation
$robotsTxt = Get-Content "robots.txt" -Raw
$requiredBots = @("ChatGPT-User", "OAI-SearchBot", "GPTBot", "Claude-User", "ClaudeBot", "Claude-Web", "Anthropic", "PerplexityBot", "Google-Extended", "Applebot-Extended", "cohere-ai")
foreach ($bot in $requiredBots) {
    Assert-Check "robots.txt explicitly allows $bot" ($robotsTxt -match "(?m)^User-agent:\s*$([regex]::Escape($bot))\s*$")
}

[xml]$sitemap = Get-Content "sitemap.xml" -Raw
$locs = $sitemap.urlset.url.loc
Assert-Check "sitemap.xml includes v1 endpoints, openapi.json, api/openapi.yaml, index.md, llms.txt" (
    ($locs -contains "https://longgilstudio.com/v1/studio.json") -and
    ($locs -contains "https://longgilstudio.com/v1/projects.json") -and
    ($locs -contains "https://longgilstudio.com/openapi.json") -and
    ($locs -contains "https://longgilstudio.com/api/openapi.yaml") -and
    ($locs -contains "https://longgilstudio.com/index.md") -and
    ($locs -contains "https://longgilstudio.com/llms.txt")
)

Write-Host "`nResult: $passed passed, $failed failed." -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
if ($failed -gt 0) { exit 1 }
