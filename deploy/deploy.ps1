# Deployment script for the demo application environment

# Create a deploy.secrets file with the variables to use
# Sample content
#           subscriptionId = aa33ffe1-1c6a-48b1-b25e-310fec6755fb
#           location = swedencentral
#           containerRegistryName = regname
#           containerRegistryResoureGroup = rg-acr

$secrets = Get-Content ".\deploy.secrets" | Out-String | ConvertFrom-StringData

az account set --subscription $secrets.subscriptionId

az deployment sub create `
    --name "AppDeployment" `
    --template-file bicep/main.bicep `
    --location $secrets.location `
    --parameters `
        location=$secrets.location `
        containerRegistryName=$secrets.containerRegistryName `
        containerRegistryResourceGroup=$secrets.containerRegistryResoureGroup
