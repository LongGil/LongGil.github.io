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

Write-Host "=== Agent Readiness Verification Suite ===" -ForegroundColor Cyan

# 0. GitHub Pages Jekyll Bypass (.nojekyll)
Assert-Check ".nojekyll exists at root" (Test-Path ".nojekyll") "Missing .nojekyll; .well-known and index.md will break under Jekyll"

# 1. Issue #1: Content available without JS & Heading Hierarchy
$indexHtml = Get-Content "index.html" -Raw
$h1Matches = [regex]::Matches($indexHtml, '<h1\b[^>]*>(.*?)</h1>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
Assert-Check "index.html has exactly 1 <h1> tag" ($h1Matches.Count -eq 1) "Found $($h1Matches.Count) <h1> tags"

# Sequential heading hierarchy check (h1 -> h2 -> h3, no skipped levels)
$headings = [regex]::Matches($indexHtml, '<h([1-6])\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { [int]$_.Groups[1].Value }
$sequentialOk = ($headings.Count -gt 0) -and ($headings[0] -eq 1)
for ($i = 1; $i -lt $headings.Count; $i++) {
    if (($headings[$i] - $headings[$i - 1]) -gt 1) {
        $sequentialOk = $false
    }
}
Assert-Check "index.html heading levels are sequential ($($headings -join ' -> '))" $sequentialOk "Heading sequence jumped a level"

# Meaningful text length in <main> (> 500 chars)
$mainHtml = [regex]::Match($indexHtml, '(?s)<main\b.*?</main>').Value
$mainText = ($mainHtml -replace '(?s)<script.*?</script>', '' -replace '(?s)<style.*?</style>', '' -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim()
Assert-Check "index.html <main> has >= 500 chars of meaningful raw text ($($mainText.Length) chars)" ($mainText.Length -ge 500) "Only $($mainText.Length) chars"

# No unescaped HTML tags inside data-vi / data-en attributes
$unescapedData = [regex]::Matches($indexHtml, 'data-(vi|en)="[^"]*<[^"]*"')
Assert-Check "No unescaped HTML tags inside data-vi/data-en attributes" ($unescapedData.Count -eq 0) "Found $($unescapedData.Count) unescaped tags"

# No-JS fallback (<noscript> hides Loader-Page and expands FAQ)
Assert-Check "index.html has <noscript> fallback for Loader-Page & FAQ" ($indexHtml -match '<noscript>' -and $indexHtml -match '\.spinner-wrapper\s*\{\s*display:\s*none') "Missing <noscript> fallback"

# Visual design preservation in CSS for .photo-details h2
$dhCss = Get-Content "assets/css/dh-card-image-left-dark.css" -Raw
$indexCss = Get-Content "assets/css/index-styles.css" -Raw
Assert-Check "dh-card-image-left-dark.css styles .photo-details h2" ($dhCss -match '\.photo-details h2') "Missing .photo-details h2 in dh-card-image-left-dark.css"
Assert-Check "index-styles.css styles .photo-details h2" ($indexCss -match '\.photo-details h2') "Missing .photo-details h2 in index-styles.css"

# 2. Issue #2: AI Agents & Bot Rules in robots.txt
$robotsTxt = Get-Content "robots.txt" -Raw
$requiredBots = @("ChatGPT-User", "OAI-SearchBot", "GPTBot", "Claude-User", "ClaudeBot", "Claude-Web", "Anthropic", "PerplexityBot", "Google-Extended", "Applebot-Extended", "cohere-ai")
foreach ($bot in $requiredBots) {
    Assert-Check "robots.txt explicitly allows $bot" ($robotsTxt -match "(?m)^User-agent:\s*$([regex]::Escape($bot))\s*$") "Missing $bot in robots.txt"
}

# 3. Issue #3: OpenAPI Specification (/openapi.json and /api/openapi.yaml)
Assert-Check "openapi.json exists" (Test-Path "openapi.json")
Assert-Check "api/openapi.yaml exists" (Test-Path "api/openapi.yaml")
$openApi = Get-Content "openapi.json" -Raw | ConvertFrom-Json
Assert-Check "openapi.json is valid OpenAPI 3.1.0" ($openApi.openapi -eq "3.1.0") "Got $($openApi.openapi)"
Assert-Check "openapi.json documents '/' with text/markdown & Vary header" ($null -ne $openApi.paths.'/'.get.responses.'200'.content.'text/markdown' -and $null -ne $openApi.paths.'/'.get.responses.'200'.headers.Vary)

# 4. Issue #4: Structured JSON Error Responses
Assert-Check "openapi.json defines components.schemas.ErrorResponse with code, message, resolution" (
    $null -ne $openApi.components.schemas.ErrorResponse.properties.code -and
    $null -ne $openApi.components.schemas.ErrorResponse.properties.message -and
    $null -ne $openApi.components.schemas.ErrorResponse.properties.resolution
)
Assert-Check "api/404.json exists and is valid structured JSON error" (Test-Path "api/404.json")
$errJson = Get-Content "api/404.json" -Raw | ConvertFrom-Json
Assert-Check "api/404.json contains code, message, status, resolution, and error object" (
    $errJson.code -eq "RESOURCE_NOT_FOUND" -and
    $errJson.status -eq 404 -and
    $errJson.message.Length -gt 10 -and
    $errJson.resolution.Length -gt 10 -and
    $null -ne $errJson.error
)
$html404 = Get-Content "404.html" -Raw
Assert-Check "404.html embeds machine-readable application/problem+json error block" ($html404 -match 'application/problem\+json')
Assert-Check ".well-known/ai-plugin.json exists and is valid JSON" (Test-Path ".well-known/ai-plugin.json")
$aiPlugin = Get-Content ".well-known/ai-plugin.json" -Raw | ConvertFrom-Json
Assert-Check ".well-known/ai-plugin.json links to openapi.json" ($aiPlugin.api.url -eq "https://longgilstudio.com/openapi.json")

# 5. Issue #5: Markdown Content Negotiation & Clean Markdown Files
Assert-Check "index.md exists" (Test-Path "index.md")
$indexMd = Get-Content "index.md" -Raw
Assert-Check "index.md starts with H1 (# ) and has no Jekyll YAML frontmatter conflict" ($indexMd.StartsWith("# ") -and -not $indexMd.StartsWith("---"))
Assert-Check "index.md has >= 500 chars ($($indexMd.Length) chars)" ($indexMd.Length -ge 500)
Assert-Check "llms.txt exists and has >= 500 chars" ((Get-Content "llms.txt" -Raw).Length -ge 500)

# 6. Sitemap XML validation
[xml]$sitemap = Get-Content "sitemap.xml" -Raw
$locs = $sitemap.urlset.url.loc
Assert-Check "sitemap.xml is well-formed XML and includes openapi.json, api/openapi.yaml, index.md, llms.txt" (
    ($locs -contains "https://longgilstudio.com/openapi.json") -and
    ($locs -contains "https://longgilstudio.com/api/openapi.yaml") -and
    ($locs -contains "https://longgilstudio.com/index.md") -and
    ($locs -contains "https://longgilstudio.com/llms.txt")
)

Write-Host "`nResult: $passed passed, $failed failed." -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
if ($failed -gt 0) { exit 1 }

