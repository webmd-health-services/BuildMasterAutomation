# Requires an API key with access to the Native API and the Release & Build Deployment API.
$baseUrl = 'http://localhost:8622'
$apiKey = Get-Content -Path '.apikey' -ReadCount 1 -EA Ignore

if (-not $apiKey)
{
    $apiKey = Read-Host "Enter API key"
}

$headers = @{ 'X-ApiKey' = $apiKey }
$suffix = [IO.Path]::GetRandomFileName()

function Invoke-NativeApi($Name, $Parameter)
{
    Invoke-RestMethod -Method Post -Uri "$baseUrl/api/json/$Name" -Headers $headers -ContentType 'application/json' `
                      -Body ($Parameter | ConvertTo-Json)
}

# 1. Create a global pipeline in a raft.
$raftName = "BugRepro-$suffix"
Write-Host "Creating raft: $raftName"
$raftId = Invoke-NativeApi 'Rafts_CreateOrUpdateRaft' @{ Raft_Name = $raftName }

$pipelineName = "BugRepro-$suffix"
Write-Host "Creating pipeline: $pipelineName"
$pipelineJson = @{ Name = $pipelineName; Color = ''; EnforceStageSequence = $false; Stages = $null } | ConvertTo-Json
$pipelineId = Invoke-NativeApi 'Rafts_CreateOrUpdateRaftItem' @{
    Raft_Id = $raftId
    RaftItemType_Code = 8 # Pipeline
    RaftItem_Name = $pipelineName
    Content_Bytes = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pipelineJson))
    ModifiedOn_Date = (Get-Date).ToString('o')
    ModifiedBy_User_Name = 'BugRepro'
}

# 2. Create an application
Write-Host "Creating application: BugRepro-$suffix"
$appId = Invoke-NativeApi 'Applications_CreateApplication' @{ Application_Name = "BugRepro-$suffix" }

# 3. Create a release for that application using the pipeline.
# Expected: the release is created.
# Actual:   after ~30 seconds, HTTP 400 "CreateRelease Failed: Object reference not set to an instance of an object."
Write-Host "Creating release for application: BugRepro-$suffix"
Invoke-RestMethod -Method Post -Uri "$baseUrl/api/releases/create" -Headers $headers `
                  -ContentType 'application/json' `
                  -Body (@{
                        applicationId = $appId;
                        releaseNumber = '1.0.0';
                        pipelineName = "${raftName}::${pipelineName}"
                    } | ConvertTo-Json)
