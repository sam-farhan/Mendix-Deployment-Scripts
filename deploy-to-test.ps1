# Configuration, please adjust.
$Config = @{
    # App ID. App -> General -> Settings.
    AppID = "aaaa-bbbb-cccc-dddd-eeeeeeee"
    # This doesn't seem to be shown anywhere, just try various things until it works.
    AppName = "myapp"
    # The branch you want to deploy.
    BranchName = "Test"
    # Test, Acceptance or Production.
    EnvironmentName = "Test"
    # Personal Access Token. Profile -> Developer Settings -> Personal Access Tokens.
    MxToken = "ThisIsYourPersonalAccessToken"
    # Mendix API Key. Profile -> Developer Settings -> API Keys.    
    MxApiKey = "aaaa-bbbb-cccc-dddd-eeeeeeee"
    # Obvious.
    MxUsername = "a.developer@finaps.nl"
}

# Invoke the release-pipeline.ps1.
$Script = "$PSScriptRoot\release-pipeline.ps1"
. $Script $Config
