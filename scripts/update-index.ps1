# update-index.ps1 — Upsert a savepoint entry in index.json
# No external dependencies. Uses native PowerShell JSON support.
#
# Usage:
#   update-index.ps1 <index_json_path> <savepoint_name> <session_id> [-CommitHash <hash>]
#
# If index.json doesn't exist, creates it.
# If the savepoint name already exists, updates it.
# If the savepoint name is new, appends it.

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$IndexPath,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$SavepointName,

    [Parameter(Mandatory=$true, Position=2)]
    [string]$SessionId,

    [string]$CommitHash = ""
)

$CreatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Build the new entry
$newEntry = [ordered]@{
    name       = $SavepointName
    created_at = $CreatedAt
}
if ($CommitHash -ne "") {
    $newEntry["commit_hash"] = $CommitHash
}

# If index.json doesn't exist, create from scratch
if (-not (Test-Path $IndexPath)) {
    $index = [ordered]@{
        session_id = $SessionId
        savepoints = @($newEntry)
    }
    $index | ConvertTo-Json -Depth 10 | Set-Content -Path $IndexPath -Encoding UTF8
    Write-Host "Created $IndexPath with savepoint '$SavepointName'"
    exit 0
}

# Read existing index
$content = Get-Content -Path $IndexPath -Raw -Encoding UTF8
$index = $content | ConvertFrom-Json

# Ensure savepoints is a mutable list
$savepoints = [System.Collections.ArrayList]@()
foreach ($sp in $index.savepoints) {
    [void]$savepoints.Add($sp)
}

# Find existing entry by name
$existingIdx = -1
for ($i = 0; $i -lt $savepoints.Count; $i++) {
    if ($savepoints[$i].name -eq $SavepointName) {
        $existingIdx = $i
        break
    }
}

if ($existingIdx -ge 0) {
    # Update existing
    $savepoints[$existingIdx] = [PSCustomObject]$newEntry
    Write-Host "Savepoint '$SavepointName' already exists - updating."
} else {
    # Append new
    [void]$savepoints.Add([PSCustomObject]$newEntry)
    Write-Host "Adding savepoint '$SavepointName' to index."
}

# Write back
$index.savepoints = $savepoints.ToArray()
$index | ConvertTo-Json -Depth 10 | Set-Content -Path $IndexPath -Encoding UTF8
Write-Host "Updated $IndexPath"
