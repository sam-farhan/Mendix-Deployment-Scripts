# Mendix Deployment Scripts

This is a set (currently just 1) of scripts written to speed up the deployment process.

## The scripts

 - **release-pipeline.ps1:** will retrieve the latest commit from the specified branch, wait for user confirmation, build a package, transport and restart.
  - **deploy-to-test.ps1:** invokes *release-pipeline.ps1* and allows the user to configure various settings. You need to edit this one for the script to work.

## Usage

 - Clone this repository.
 - Edit *deploy-to-test.ps* to reflect your application's config.
 - Run *deploy-to-test.ps*.