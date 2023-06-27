
# Create a deploy.secrets file with the variables to use
# Sample content
#           subscriptionId = aa33ffe1-1c6a-48b1-b25e-310fec6755fb
#           location = swedencentral
#           containerRegistryName = regname
#           containerRegistryResoureGroup = rg-acr
$secrets = Get-Content ".\deploy.secrets" | Out-String | ConvertFrom-StringData

$startLocation = Get-Location
Set-Location ../apps
dotnet clean Backend.Finance
dotnet clean Backend.Customer
docker build -t customer:dev -f .\Backend.Customer\Dockerfile .
docker build -t finance:dev -f .\Backend.Finance\Dockerfile .
Set-Location $startLocation
az acr login --name $ACR_NAME
$customerTag = "$($secrets.containerRegistryName).azurecr.io/testing/customer:v1"
$financeTag = "$($secrets.containerRegistryName).azurecr.io/testing/finance:v1"
docker tag finance:dev $financeTag
docker tag customer:dev $customerTag
docker push $financeTag
docker push $customerTag


