# Not used for these API calls. May be used in future when certains APIs upgrade to v2/3.
# $ProjectID = "b4c4e408-6e13-4267-ab2d-16e60e4012d1"
# $EnvironmentID = "7c97c162-4311-4331-994a-7693a3a58d58"
$AppID = "b4c4e408-6e13-4267-ab2d-16e60e4012d1"
$AppName = "arrow"
$BranchName = "Test_Sprint122"
$EnvironmentName = "Test"

# PAT. Profile -> Developer settings -> Personal access token.
$MxToken = "7fvAVcJGAn1gLRqPLvsccKZB4aF5a6NmYmd4NzxeQXxx79CxpcqUwPb9ozw4i417shQ2Wy5NgG5pG3DvarqvxnwicwRR4YU9UVZo"
# API Key. Profile -> Developer settings -> Api keys.
$MxApiKey = "c6d7dd8c-a2c6-4dc4-9965-718705e3f848"
$MxUsername = "sam.farhan@finaps.nl"

Write-Host "Starting pipeline..."
Write-Host "Will deploy latest commit of branch $BranchName to $EnvironmentName"

# Get the latest commit.
$Url = "https://repository.api.mendix.com/v1/repositories/$AppID/branches/$BranchName/commits"
$Headers = @{
    Authorization="MxToken $MxToken"
    "MxToken" = $MxToken
}
$Response = Invoke-RestMethod -Method 'Get' -Uri $Url -Headers $Headers
$LatestCommit = $Response.items[0]
$LatestCommitID = $LatestCommit.id
$Author = $LatestCommit.author.name
$Message = $LatestCommit.message
$Date = $LatestCommit.date

# Show latest commit to user and get confirmation.
Write-Host "Latest Commit:`nID: $LatestCommitID`nMessage: $Message`nAuthor: $Author`nDate: $Date" -ForegroundColor Green
$confirmation = Read-Host "Are you sure that you want to deploy this commit to $EnvironmentName`? (y/n)" 
if ($confirmation -eq 'y') {
    Write-Host "Deploying..."
}
else {
    Write-Host "Stopping pipeline."
    exit
}

# Start building the package.
$Url = "https://deploy.mendix.com/api/1/apps/$AppName/packages"
$Body = @{
    "Branch" = "branches/$BranchName"
    "Revision" = "$LatestCommitID"
    "Version" = "1.2.5"
    "Description" = "Build from pipeline"
}
$Headers = @{
    "Mendix-Username" = $MxUsername
    "Mendix-ApiKey" = $MxApiKey
}
$Response = Invoke-RestMethod -Method 'Post' -Uri $Url -Headers $Headers -Body ($Body | ConvertTo-Json) -ContentType "application/json"
$PackageID = $Response.PackageId
Write-Host "Building package with ID: $PackageID"

# Check package status.
$Url = "https://deploy.mendix.com/api/1/apps/$AppName/packages/$PackageID`?url=false"
$Headers = @{
    "Mendix-Username" = $MxUsername
    "Mendix-ApiKey" = $MxApiKey
}
$ReTest = 1
$CheckCount = 0
$TimesToCheck = 10
# Keep checking if the package is done.
while ($ReTest -eq 1) 
{
    Start-Sleep -Seconds 60
    Write-Host "Checking package..."
    try {
        $Response = Invoke-RestMethod -Method 'Get' -Uri $Url -Headers $Headers
        $Status = $Response.Status;

        if($Status -eq "Succeeded") {
            Write-Host "Building package succeeded." -ForegroundColor Green
            $ReTest = 0
            break
        }
        elseif($Status -eq "Failed") {
            Write-Host "Building package failed: Check Sprintr for details. Exiting pipeline..." -ForegroundColor Red
            exit
        }
        else {
            Write-Host "Package is still being built..." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "Something went wrong. StatusCode:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Red
    }

    $CheckCount = $CheckCount + 1

    if($CheckCount -ge $TimesToCheck) {
        Write-Host "Building package failed: Took too long. Exiting pipeline..." -ForegroundColor Red
        exit
    }
}

# Transport package to environment.
$Url = "https://deploy.mendix.com/api/1/apps/$AppName/environments/$EnvironmentName/transport"
$Body = @{
    "PackageId" = "$PackageID"
}
$Headers = @{
    "Mendix-Username" = $MxUsername
    "Mendix-ApiKey" = $MxApiKey
}

Write-Host "Transporting package $PackageID to $EnvironmentName..."
$Response = Invoke-RestMethod -Method 'Post' -Uri $Url -Headers $Headers -Body ($Body | ConvertTo-Json) -ContentType "application/json"
$PackageStatus = $Response.Status

if($PackageStatus -eq "Succeeded") {
    Write-Host "Transporting package succeeded." -ForegroundColor Green
}
else {
    Write-Host "Transporting package failed. Exiting pipeline..." -ForegroundColor Red
    exit
}

# Stop environment.
$Url = "https://deploy.mendix.com/api/1/apps/$AppName/environments/$EnvironmentName/stop"
$Headers = @{
    "Mendix-Username" = $MxUsername
    "Mendix-ApiKey" = $MxApiKey
}

Write-Host "Stopping server..."
$Response = Invoke-RestMethod -Method 'Post' -Uri $Url -Headers $Headers
Write-Host "Server stopped." -ForegroundColor Green

# Start environment.
$Url = "https://deploy.mendix.com/api/1/apps/$AppName/environments/$EnvironmentName/start"
$Body = @{
    "AutoSyncDb" = "true"
}
$Headers = @{
    "Mendix-Username" = $MxUsername
    "Mendix-ApiKey" = $MxApiKey
}

Write-Host "Starting server..."
$Response = Invoke-RestMethod -Method 'Post' -Uri $Url -Headers $Headers -Body ($Body | ConvertTo-Json) -ContentType "application/json"
$JobID = $Response.JobId

# Check start environment status.
$Url = "https://deploy.mendix.com/api/1/apps/$AppName/environments/$EnvironmentName/start/$JobID"
$Headers = @{
    "Mendix-Username" = $MxUsername
    "Mendix-ApiKey" = $MxApiKey
}

$ReTest = 1
$CheckCount = 0
$TimesToCheck = 10
# Keep checking if the package is done.
while ($ReTest -eq 1) 
{
    $Response = Invoke-RestMethod -Method 'Get' -Uri $Url -Headers $Headers
    $Status = $Response.Status

    if($Status -eq "Started") {
        Write-Host "Server started." -ForegroundColor Green
        $ReTest = 0
        break
    }
    elseif($Status -eq "Starting") {
        Write-Host "Server starting..." -ForegroundColor Cyan
    }
    else {
        Write-Host "Something went wrong: Unexpected response. Exiting pipeline..." -ForegroundColor Red
        exit
    }

    $CheckCount = $CheckCount + 1

    if($CheckCount -ge $TimesToCheck) {
        Write-Host "Starting server failed: Took too long. Exiting pipeline..." -ForegroundColor Red
        exit
    }
}

Write-Host "Pipeline completed succesfully." -ForegroundColor Green
