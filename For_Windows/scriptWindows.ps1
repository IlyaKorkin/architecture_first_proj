# установка лимита
$Global:QuotaMB = 100

# находим размер папки
function Get-FolderSizeMB {
    param([string]$Path)
    if (Test-Path $Path) {
        $files = Get-ChildItem $Path -File | Where-Object { $_.Name -ne "archived_files.zip" }
        if ($files) {
            return [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        }
    }
    return 0
}

# сколько файлов архивируем
function Get-FilesToArchiveCount {
    param(
        [string]$SourcePath,
        [double]$CurrentSizeMB,
        [double]$MaxAllowedSizeMB
    )
    
    $allFiles = Get-ChildItem $SourcePath -File | Where-Object { $_.Name -ne "archived_files.zip" } | Sort-Object LastWriteTime
    
    if ($allFiles.Count -eq 0) {
        return 0, 0
    }
    
    $neededReductionMB = $CurrentSizeMB - $MaxAllowedSizeMB
    Write-Host "Need to reduce size by: $neededReductionMB MB" -ForegroundColor Gray
    
    $accumulatedSizeMB = 0
    $filesToArchive = @()
    
    foreach ($file in $allFiles) {
        $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
        
        if ($accumulatedSizeMB -lt $neededReductionMB) {
            $filesToArchive += $file
            $accumulatedSizeMB += $fileSizeMB
            Write-Host ("  Will archive: {0,-40} ({1,6} MB)" -f $file.Name, $fileSizeMB) -ForegroundColor Gray
        }
        else {
            break
        }
    }
    
    return $filesToArchive, $accumulatedSizeMB
}

# архивация
function Compress-FilesToSingleZip {
    param(
        [string]$SourcePath,
        [array]$FilesToArchive
    )
    
    if ($FilesToArchive.Count -eq 0) {
        Write-Host "No files to archive" -ForegroundColor Green
        return 0, 0
    }
    
    $backupFolder = "D:\backup"
    
    if (-not (Test-Path $backupFolder)) {
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        Write-Host "Created backup folder: $backupFolder" -ForegroundColor Gray
    }

    $zipPath = Join-Path $backupFolder "archived_files.zip"
    
    $filesToArchivePaths = @()
    $totalSize = 0
    
    foreach ($file in $FilesToArchive) {
        $filesToArchivePaths += $file.FullName
        $totalSize += $file.Length
        $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Host ("Adding to archive: {0,-40} ({1,6} MB)" -f $file.Name, $fileSizeMB) -ForegroundColor Gray
    }
    
    try {
        if (Test-Path $zipPath) {
            Write-Host "Updating existing archive..." -ForegroundColor Yellow
            Compress-Archive -Path $filesToArchivePaths -Update -DestinationPath $zipPath -CompressionLevel Optimal
        }
        else {
            Write-Host "Creating new archive..." -ForegroundColor Yellow
            Compress-Archive -Path $filesToArchivePaths -DestinationPath $zipPath -CompressionLevel Optimal
        }
        
        $deletedCount = 0
        foreach ($filePath in $filesToArchivePaths) {
            if (Test-Path $filePath) {
                Remove-Item -Path $filePath -Force
                Write-Host "Deleted original file: $(Split-Path $filePath -Leaf)" -ForegroundColor Gray
                $deletedCount++
            }
        }
        
        $freedMB = [math]::Round($totalSize / 1MB, 2)
        Write-Host "Successfully archived $deletedCount files ($freedMB MB)" -ForegroundColor Green
        return $freedMB, $deletedCount
    }
    catch {
        Write-Host "Error creating archive: $($_.Exception.Message)" -ForegroundColor Red
        return 0, 0
    }
}

# процент использования
function Get-UsagePercentage {
    param(
        [double]$CurrentSize,
        [double]$QuotaSize
    )
    if ($QuotaSize -eq 0) { return 0 }
    return [math]::Round(($CurrentSize / $QuotaSize) * 100, 2)
}

do {
    $FolderPath = Read-Host "Enter folder path to monitor"
    
    if (-not (Test-Path $FolderPath)) {
        Write-Host "Error: Folder '$FolderPath' does not exist! Please enter a different path." -ForegroundColor Red
        $retry = Read-Host "Try again? (Y/N)"
        if ($retry -ne 'Y' -and $retry -ne 'y') { exit }
        continue
    }
    
    $filesInFolder = Get-ChildItem $FolderPath -File | Where-Object { $_.Name -ne "archived_files.zip" }
    if ($filesInFolder.Count -eq 0) {
        Write-Host "Folder is empty. Nothing to archive. Please select a folder with files." -ForegroundColor Yellow
        $retry = Read-Host "Try again? (Y/N)"
        if ($retry -ne 'Y' -and $retry -ne 'y') { exit }
        continue
    }
    
    break
    
} while ($true)

Start-Sleep -Milliseconds 500

Write-Host "`n_____ QUOTA SETTINGS _____" -ForegroundColor Magenta
Write-Host "Using predefined quota: $QuotaMB MB" -ForegroundColor Gray

Write-Host "`n_____ ARCHIVING SETTINGS ____" -ForegroundColor Magenta
$ExceedPercent = Read-Host "Enter maximum usage percentage: "

$MaxUsagePercentage = [int]$ExceedPercent
$MaxAllowedSizeMB = $QuotaMB * ($MaxUsagePercentage / 100)

Start-Sleep -Milliseconds 500

Write-Host "`n_____ SETTINGS _____" -ForegroundColor Magenta
Write-Host "Folder: $FolderPath" -ForegroundColor White
Write-Host "Quota: $QuotaMB MB" -ForegroundColor White
Write-Host "Maximum allowed usage: $MaxUsagePercentage%" -ForegroundColor Yellow
Write-Host "Maximum allowed size: $MaxAllowedSizeMB MB" -ForegroundColor Yellow

Start-Sleep -Milliseconds 500

$currentSize = Get-FolderSizeMB -Path $FolderPath
$currentPercentage = Get-UsagePercentage -CurrentSize $currentSize -QuotaSize $QuotaMB

Write-Host "`nCurrent status:" -ForegroundColor Magenta
Write-Host "Folder size: $currentSize MB" -ForegroundColor White
Write-Host "Current usage: $currentPercentage% of $QuotaMB MB" -ForegroundColor White
Write-Host "Files in folder: $(($filesInFolder = Get-ChildItem $FolderPath -File | Where-Object { $_.Name -ne "archived_files.zip" }).Count)" -ForegroundColor White

Start-Sleep -Milliseconds 800

if ($currentSize -le $MaxAllowedSizeMB) {
    Write-Host "Usage within limits ($currentPercentage% <= $MaxUsagePercentage%). Archiving not required." -ForegroundColor Green
    exit
}

Write-Host "USAGE EXCEEDED! ($currentPercentage% > $MaxUsagePercentage%)" -ForegroundColor Red
Write-Host "Calculating which files need to be archived..." -ForegroundColor Yellow

Start-Sleep -Milliseconds 1000

$filesToArchive, $totalArchiveSizeMB = Get-FilesToArchiveCount -SourcePath $FolderPath -CurrentSizeMB $currentSize -MaxAllowedSizeMB $MaxAllowedSizeMB

Start-Sleep -Milliseconds 800

if ($filesToArchive.Count -eq 0) {
    Write-Host "Cannot reduce folder size to target. Files are too large or no files available." -ForegroundColor Red
    exit
}

Write-Host "Will archive $($filesToArchive.Count) files" -ForegroundColor Blue
Write-Host "Expected size reduction: $totalArchiveSizeMB MB" -ForegroundColor Blue
Write-Host "Expected final size: $($currentSize - $totalArchiveSizeMB) MB" -ForegroundColor Blue

Start-Sleep -Milliseconds 1000

Write-Host "`nStarting archiving process..." -ForegroundColor Green
$freedSpace, $filesArchived = Compress-FilesToSingleZip -SourcePath $FolderPath -FilesToArchive $filesToArchive

Start-Sleep -Milliseconds 1000

$finalSize = Get-FolderSizeMB -Path $FolderPath
$finalPercentage = Get-UsagePercentage -CurrentSize $finalSize -QuotaSize $QuotaMB

Write-Host "`n_____ FINAL RESULT _____" -ForegroundColor Magenta
Write-Host "Files archived: $filesArchived" -ForegroundColor White
Write-Host "Space freed: $freedSpace MB" -ForegroundColor White
Write-Host "Final folder size: $finalSize MB" -ForegroundColor White
Write-Host "Final usage: $finalPercentage% of $QuotaMB MB" -ForegroundColor White

Start-Sleep -Milliseconds 800

Write-Host "`nRemaining files:" -ForegroundColor DarkGreen
$remainingFiles = Get-ChildItem $FolderPath -File | Where-Object { $_.Name -ne "archived_files.zip" } | Sort-Object LastWriteTime

if ($remainingFiles.Count -gt 0) {
    $remainingFiles | Format-Table Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB,2)}}, LastWriteTime -AutoSize
} else {
    Write-Host "No files left in folder (only ZIP archive remains)" -ForegroundColor Gray
}

Start-Sleep -Milliseconds 500

$zipPath = Join-Path $FolderPath "archived_files.zip"
if (Test-Path $zipPath) {
    $zipInfo = Get-Item $zipPath
    Write-Host "`nZIP archive created: archived_files.zip" -ForegroundColor Gray
    Write-Host "Archive size: $([math]::Round($zipInfo.Length/1MB,2)) MB" -ForegroundColor White
    Write-Host "Contains: $filesArchived files" -ForegroundColor White
}