Add-Type -AssemblyName System.Web

# ─── YOUR CREDENTIALS ───
$User     = "1000000077"
$Password = "Password1000@2"
$Customer = "7701111111"
$Agent    = "1000000066"

# ─── SETUP ───
$scriptDir = "C:\Maestro Project\Practice Project\FastPay Agent"
$reportDir = "$scriptDir\reports"

if (!(Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FastPay Agent - Running All Tests     " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ─── CHECK DEVICE ───
Write-Host "Checking device..." -ForegroundColor Yellow
adb devices
Write-Host ""

# ─── RUN BASEFILE.YAML ───
$startTime = Get-Date

Write-Host "Starting Maestro tests..." -ForegroundColor Yellow
Write-Host ""

$baseFilePath = "$scriptDir\BaseFile.yaml"

$tempOutputFile = "$scriptDir\maestro_output.txt"

$process = Start-Process -FilePath "maestro" `
    -ArgumentList "test -e User=$User -e Password=$Password -e Customer=$Customer -e Agent=$Agent `"$baseFilePath`"" `
    -NoNewWindow `
    -Wait `
    -PassThru `
    -RedirectStandardOutput $tempOutputFile `
    -RedirectStandardError "$scriptDir\maestro_error.txt"

$overallExitCode = $process.ExitCode

$endTime = Get-Date
$totalDuration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)

# Read output
$output = ""
if (Test-Path $tempOutputFile) {
    $output = Get-Content $tempOutputFile -Raw
    Write-Host $output
}
if (Test-Path "$scriptDir\maestro_error.txt") {
    $errorOutput = Get-Content "$scriptDir\maestro_error.txt" -Raw
    if ($errorOutput) {
        Write-Host $errorOutput
        $output += "`n$errorOutput"
    }
}

# Cleanup temp files
Remove-Item $tempOutputFile -ErrorAction SilentlyContinue
Remove-Item "$scriptDir\maestro_error.txt" -ErrorAction SilentlyContinue

# ─── PARSE RESULTS FOR EACH FLOW ───
$flows = @(
    @{ Name = "Login";          File = "Login.yaml" },
    @{ Name = "Sell Balance";   File = "Sell Balance.yaml" },
    @{ Name = "Transfer Money"; File = "Transfer Money.yaml" }
)

$results = @()

foreach ($flow in $flows) {
    $escapedFile = [regex]::Escape($flow.File)
    $escapedName = [regex]::Escape($flow.Name)

    # More comprehensive pattern matching
    $patterns = @(
        "(?i)Running flow.*?$escapedFile",
        "(?i)$escapedFile.*?(passed|completed|successful)",
        "(?i)$escapedName.*?(passed|completed|successful)",
        "(?i)runFlow.*?$escapedFile"
    )

    $failPatterns = @(
        "(?i)$escapedFile.*?(failed|error)",
        "(?i)$escapedName.*?(failed|error)",
        "(?i)Flow.*?$escapedFile.*?failed"
    )

    $wasRun = $false
    foreach ($pattern in $patterns) {
        if ($output -match $pattern) {
            $wasRun = $true
            break
        }
    }

    $hasFailed = $false
    foreach ($failPattern in $failPatterns) {
        if ($output -match $failPattern) {
            $hasFailed = $true
            break
        }
    }

    if (-not $wasRun) {
        $status = "NOT RUN"
    }
    elseif ($hasFailed) {
        $status = "FAILED"
    }
    else {
        $status = "PASSED"
    }

    $results += @{
        Name   = $flow.Name
        File   = $flow.File
        Status = $status
    }
}

# ─── CONSOLE SUMMARY ───
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "         TEST RESULTS SUMMARY           " -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

foreach ($r in $results) {
    if ($r.Status -eq "PASSED") {
        Write-Host "  PASS : $($r.Name) - Successful" -ForegroundColor Green
    }
    elseif ($r.Status -eq "FAILED") {
        Write-Host "  FAIL : $($r.Name) - Failed" -ForegroundColor Red
    }
    else {
        Write-Host "  SKIP : $($r.Name) - Not Run" -ForegroundColor Yellow
    }
}

$passedCount = ($results | Where-Object { $_.Status -eq "PASSED" }).Count
$failedCount = ($results | Where-Object { $_.Status -eq "FAILED" }).Count
$skippedCount = ($results | Where-Object { $_.Status -eq "NOT RUN" }).Count

Write-Host ""
Write-Host "  Total: $($results.Count) | Passed: $passedCount | Failed: $failedCount | Skipped: $skippedCount"
Write-Host "  Duration: ${totalDuration}s"
Write-Host "========================================" -ForegroundColor Yellow

# ─── GENERATE HTML REPORT ───
$escapedOutput = [System.Web.HttpUtility]::HtmlEncode($output)

$testRowsHtml = ""
$index = 1
foreach ($r in $results) {
    $statusColor = switch ($r.Status) {
        "PASSED"  { "#4CAF50" }
        "FAILED"  { "#f44336" }
        "NOT RUN" { "#FF9800" }
        default   { "#999999" }
    }
    
    $statusText = switch ($r.Status) {
        "PASSED"  { "Successful" }
        "FAILED"  { "Failed" }
        "NOT RUN" { "Not Run" }
        default   { "Unknown" }
    }
    
    $statusIcon = switch ($r.Status) {
        "PASSED"  { "&#9989;" }
        "FAILED"  { "&#10060;" }
        "NOT RUN" { "&#9888;" }
        default   { "&#10067;" }
    }

    $testRowsHtml += @"
    <tr>
        <td style="text-align:center;">$index</td>
        <td>$($r.Name)</td>
        <td>$($r.File)</td>
        <td style="color:$statusColor; font-weight:bold; text-align:center;">
            $statusIcon $statusText
        </td>
    </tr>
"@
    $index++
}

$overallBanner = if ($failedCount -eq 0 -and $skippedCount -eq 0) {
    '<div class="overall pass">&#9989; ALL TESTS PASSED</div>'
} elseif ($failedCount -gt 0) {
    '<div class="overall fail">&#10060; SOME TESTS FAILED</div>'
} else {
    '<div class="overall warning">&#9888; SOME TESTS SKIPPED</div>'
}

$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>FastPay Agent - Test Report</title>
    <style>
        * { box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            margin: 0; padding: 20px; background: #f0f2f5;
        }
        .header {
            background: linear-gradient(135deg, #1a73e8, #0d47a1);
            color: white; padding: 30px; border-radius: 12px;
        }
        .header h1 { margin: 0 0 8px; font-size: 28px; }
        .header p { margin: 0; opacity: 0.85; font-size: 14px; }
        .overall {
            text-align: center; padding: 20px; border-radius: 12px;
            margin: 20px 0; font-size: 22px; font-weight: bold;
        }
        .overall.pass { background: #e8f5e9; color: #2e7d32; }
        .overall.fail { background: #ffebee; color: #c62828; }
        .overall.warning { background: #fff3e0; color: #f57c00; }
        .cards { display: flex; gap: 15px; margin: 20px 0; }
        .card {
            background: white; padding: 25px; border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
            flex: 1; text-align: center;
        }
        .card h2 { margin: 0; font-size: 40px; }
        .card p { margin: 8px 0 0; color: #888; font-size: 13px; }
        .card.total h2  { color: #1a73e8; }
        .card.passed h2 { color: #4CAF50; }
        .card.failed h2 { color: #f44336; }
        .card.skipped h2 { color: #FF9800; }
        .card.time h2   { color: #9C27B0; font-size: 30px; }
        table {
            width: 100%; border-collapse: collapse;
            background: white; border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        th {
            background: #1a73e8; color: white;
            padding: 14px 20px; text-align: left;
        }
        td { padding: 14px 20px; border-bottom: 1px solid #f0f0f0; }
        tr:last-child td { border-bottom: none; }
        tr:hover { background: #fafafa; }
        .log-box {
            margin-top: 20px; background: white;
            border-radius: 12px; overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        .log-box h3 {
            margin: 0; padding: 15px 20px;
            background: #fafafa; border-bottom: 1px solid #eee;
        }
        .log-box pre {
            margin: 0; padding: 20px;
            background: #1e1e1e; color: #d4d4d4;
            font-size: 12px; max-height: 400px;
            overflow: auto; white-space: pre-wrap;
        }
        .footer {
            text-align: center; padding: 20px;
            color: #999; font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>FastPay Agent - Test Report</h1>
        <p>App ID: com.fastpay.agent</p>
        <p>Report Generated: $timestamp</p>
    </div>

    $overallBanner

    <div class="cards">
        <div class="card total">
            <h2>$($results.Count)</h2>
            <p>Total Flows</p>
        </div>
        <div class="card passed">
            <h2>$passedCount</h2>
            <p>Successful</p>
        </div>
        <div class="card failed">
            <h2>$failedCount</h2>
            <p>Failed</p>
        </div>
        <div class="card skipped">
            <h2>$skippedCount</h2>
            <p>Skipped</p>
        </div>
        <div class="card time">
            <h2>${totalDuration}s</h2>
            <p>Total Duration</p>
        </div>
    </div>

    <table>
        <tr>
            <th style="text-align:center; width:50px;">#</th>
            <th>Flow Name</th>
            <th>File</th>
            <th style="text-align:center;">Result</th>
        </tr>
        $testRowsHtml
    </table>

    <div class="log-box">
        <h3>Maestro Execution Log</h3>
        <pre>$escapedOutput</pre>
    </div>

    <div class="footer">
        Generated by Maestro Test Runner
    </div>
</body>
</html>
"@

$htmlPath = "$reportDir\TestReport_$timestamp.html"
$html | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Host ""
Write-Host "HTML Report saved at:" -ForegroundColor Cyan
Write-Host "$htmlPath" -ForegroundColor Green
Write-Host ""

Start-Process $htmlPath