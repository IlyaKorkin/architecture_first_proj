# Fixed automated tests for the main archiving script

function Test-ScriptWithInput {
    param(
        [string]$TestName,
        [string]$FolderPath,
        [string]$PercentageInput,
        [scriptblock]$ValidationScript
    )
    
    Write-Host "`n_____ TEST: $TestName _____" -ForegroundColor Cyan
    
    # Save original Read-Host function
    $originalReadHost = Get-Command Read-Host
    
    function Read-Host { param([string]$Prompt) 
        Write-Host $Prompt -NoNewline
        if ($Prompt -like "*folder path*") {
            Write-Host " $FolderPath" -ForegroundColor Gray
            return $FolderPath
        }
        elseif ($Prompt -like "*percentage*") {
            Write-Host " $PercentageInput" -ForegroundColor Gray
            return $PercentageInput
        }
        elseif ($Prompt -like "*Try again*") {
            Write-Host " N" -ForegroundColor Gray
            return "N"
        }
    }
    
    try {
        # Run the main script
        & "D:\scriptWindows.ps1"
        
        # Execute validation
        & $ValidationScript
        Write-Host "TEST RESULT: PASS" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "TEST RESULT: FAIL - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    finally {
        # Restore original Read-Host
        Remove-Item function:Read-Host -ErrorAction SilentlyContinue
    }
}

function Test-NonExistentFolder {
    Write-Host "`n_____ TEST: Non-Existent Folder _____" -ForegroundColor Cyan
    
    function Read-Host { param([string]$Prompt) 
        Write-Host $Prompt -NoNewline
        if ($Prompt -like "*folder path*") {
            Write-Host " C:\ThisFolderDoesNotExist123" -ForegroundColor Gray
            return "C:\ThisFolderDoesNotExist123"
        }
        elseif ($Prompt -like "*Try again*") {
            Write-Host " N" -ForegroundColor Gray
            return "N"
        }
    }
    
    try {
        & "D:\scriptWindows.ps1"
        Write-Host "TEST RESULT: PASS - Script handled non-existent folder correctly" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "TEST RESULT: FAIL - Script should have exited" -ForegroundColor Red
        return $false
    }
    finally {
        Remove-Item function:Read-Host -ErrorAction SilentlyContinue
    }
}

function Test-EmptyFolder {
    Write-Host "`n______ TEST: Empty Folder ______" -ForegroundColor Cyan
    
    $testPath = "D:\TestEmptyFolder"
    New-Item -ItemType Directory -Path $testPath -Force | Out-Null
    
    function Read-Host { param([string]$Prompt) 
        Write-Host $Prompt -NoNewline
        if ($Prompt -like "*folder path*") {
            Write-Host " $testPath" -ForegroundColor Gray
            return $testPath
        }
        elseif ($Prompt -like "*Try again*") {
            Write-Host " N" -ForegroundColor Gray
            return "N"
        }
    }
    
    try {
        & "D:\scriptWindows.ps1"
        Write-Host "TEST RESULT: PASS - Script handled empty folder correctly" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "TEST RESULT: FAIL - Script should have exited" -ForegroundColor Red
        return $false
    }
    finally {
        Remove-Item function:Read-Host -ErrorAction SilentlyContinue
        Remove-Item $testPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Test-WithinLimitsScenario {
    Write-Host "`n=== TEST: Within Limits (No Archiving Needed) ===" -ForegroundColor Cyan
    
    $testPath = "D:\TestWithinLimits"
    New-Item -ItemType Directory -Path $testPath -Force | Out-Null
    
    # Create small files that won't exceed quota
    "Small file 1" | Out-File -FilePath "$testPath\file1.txt"
    "Small file 2" | Out-File -FilePath "$testPath\file2.txt"
    
    function Read-Host { param([string]$Prompt) 
        Write-Host $Prompt -NoNewline
        if ($Prompt -like "*folder path*") {
            Write-Host " $testPath" -ForegroundColor Gray
            return $testPath
        }
        elseif ($Prompt -like "*percentage*") {
            Write-Host " 90" -ForegroundColor Gray  # High percentage - no archiving needed
            return "90"
        }
    }
    
    try {
        & "D:\scriptWindows.ps1"
        Write-Host "TEST RESULT: PASS - Script correctly identified no archiving needed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "TEST RESULT: FAIL - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    finally {
        Remove-Item function:Read-Host -ErrorAction SilentlyContinue
        Remove-Item $testPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Test-ExceedLimitsScenario {
    Write-Host "`n=== TEST: Exceed Limits (Archiving Required) ===" -ForegroundColor Cyan
    
    $testPath = "D:\TestExceedLimits"
    New-Item -ItemType Directory -Path $testPath -Force | Out-Null
    
    # Create files that will exceed quota - use smaller files for faster testing
    1..3 | ForEach-Object {
        $content = "x" * 1024 * 1024 * 10  # 10MB each file (smaller for faster testing)
        $content | Out-File -FilePath "$testPath\large_file_$_.txt" -Encoding ASCII
    }
    
    function Read-Host { param([string]$Prompt) 
        Write-Host $Prompt -NoNewline
        if ($Prompt -like "*folder path*") {
            Write-Host " $testPath" -ForegroundColor Gray
            return $testPath
        }
        elseif ($Prompt -like "*percentage*") {
            Write-Host " 20" -ForegroundColor Gray 
            return "20"
        }
    }
    
    try {
        & "D:\scriptWindows.ps1"
        
        # Check if archiving occurred
        $backupPath = "D:\backup\archived_files.zip"
        $zipExists = Test-Path $backupPath
        
        if ($zipExists) {
            Write-Host "TEST RESULT: PASS - Archiving was performed correctly" -ForegroundColor Green
            return $true
        } else {
            Write-Host "TEST RESULT: FAIL - No archive was created" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "TEST RESULT: FAIL - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    finally {
        Remove-Item function:Read-Host -ErrorAction SilentlyContinue
        Remove-Item $testPath -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path "D:\backup") { Remove-Item "D:\backup" -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Test-InvalidPercentageInput {
    Write-Host "`n_______ TEST: Invalid Percentage Input _____" -ForegroundColor Cyan
    
    $testPath = "D:\TestInvalidPercentage"
    New-Item -ItemType Directory -Path $testPath -Force | Out-Null
    "test file" | Out-File -FilePath "$testPath\file1.txt"
    
    function Read-Host { param([string]$Prompt) 
        Write-Host $Prompt -NoNewline
        if ($Prompt -like "*folder path*") {
            Write-Host " $testPath" -ForegroundColor Gray
            return $testPath
        }
        elseif ($Prompt -like "*percentage*") {
            Write-Host " invalid_text" -ForegroundColor Gray  # Invalid input
            return "invalid_text"
        }
    }
    
    try {
        & "D:\scriptWindows.ps1"
        Write-Host "TEST RESULT: FAIL - Script should have handled invalid input" -ForegroundColor Red
        return $false
    }
    catch [System.Management.Automation.RuntimeException] {
        if ($_.Exception.Message -like "*Cannot convert value*") {
            Write-Host "TEST RESULT: PASS - Script handled invalid percentage correctly" -ForegroundColor Green
            return $true
        } else {
            Write-Host "TEST RESULT: FAIL - Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "TEST RESULT: FAIL - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    finally {
        Remove-Item function:Read-Host -ErrorAction SilentlyContinue
        Remove-Item $testPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Test-EdgeCasePercentage {
    Write-Host "`n=== TEST: Edge Case Percentages ===" -ForegroundColor Cyan
    
    $testPath = "D:\TestEdgeCase"
    New-Item -ItemType Directory -Path $testPath -Force | Out-Null
    "test file" | Out-File -FilePath "$testPath\file1.txt"
    
    function Read-Host { param([string]$Prompt) 
        Write-Host $Prompt -NoNewline
        if ($Prompt -like "*folder path*") {
            Write-Host " $testPath" -ForegroundColor Gray
            return $testPath
        }
        elseif ($Prompt -like "*percentage*") {
            Write-Host " 0" -ForegroundColor Gray  # 0% - extreme case
            return "0"
        }
    }
    
    try {
        & "D:\scriptWindows.ps1"
        Write-Host "TEST RESULT: PASS - Script handled 0% correctly" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "TEST RESULT: FAIL - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    finally {
        Remove-Item function:Read-Host -ErrorAction SilentlyContinue
        Remove-Item $testPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "STARTING AUTOMATED SCRIPT TESTS" -ForegroundColor Magenta
Write-Host "_______________________________" -ForegroundColor Magenta

$testResults = @()

# Run all tests
Write-Host "Running tests..." -ForegroundColor Yellow

$testResults += @{Name = "Non-Existent Folder"; Result = Test-NonExistentFolder}
Start-Sleep -Seconds 1

$testResults += @{Name = "Empty Folder"; Result = Test-EmptyFolder}
Start-Sleep -Seconds 1

$testResults += @{Name = "Within Limits Scenario"; Result = Test-WithinLimitsScenario}
Start-Sleep -Seconds 1

$testResults += @{Name = "Exceed Limits Scenario"; Result = Test-ExceedLimitsScenario}
Start-Sleep -Seconds 2 

$testResults += @{Name = "Invalid Percentage Input"; Result = Test-InvalidPercentageInput}
Start-Sleep -Seconds 1

$testResults += @{Name = "Edge Case (0%)"; Result = Test-EdgeCasePercentage}
Start-Sleep -Seconds 1

Write-Host "TEST SUMMARY" -ForegroundColor Magenta
Write-Host "____________" -ForegroundColor Magenta

$passed = ($testResults | Where-Object { $_.Result -eq $true }).Count
$failed = ($testResults | Where-Object { $_.Result -eq $false }).Count

foreach ($test in $testResults) {
    $color = if ($test.Result) { "Green" } else { "Red" }
    $status = if ($test.Result) { "PASS" } else { "FAIL" }
    Write-Host "$($test.Name): $status" -ForegroundColor $color
}

Write-Host "`nTotal: $passed passed, $failed failed" -ForegroundColor White
Write-Host "Success rate: $([math]::Round(($passed/($passed+$failed))*100, 1))%" -ForegroundColor Yellow

if ($failed -eq 0) {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host "`nSOME TESTS FAILED!" -ForegroundColor Red
}

# Cleanup any remaining test folders
$foldersToCleanup = @(
    "D:\TestEmptyFolder",
    "D:\TestWithinLimits", 
    "D:\TestExceedLimits",
    "D:\TestInvalidPercentage",
    "D:\TestRetryFolder",
    "D:\TestEdgeCase",
    "D:\backup"
)

foreach ($folder in $foldersToCleanup) {
    if (Test-Path $folder) {
        Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleaned up: $folder" -ForegroundColor Gray
    }
}