
# Create a deploy.secrets file with the variables to use
# Sample content
#           subscriptionId = aa33ffe1-1c6a-48b1-b25e-310fec6755fb
#           location = swedencentral
#           containerRegistryName = regname
#           containerRegistryResoureGroup = rg-acr
$secrets = Get-Content ".\deploy.secrets" | Out-String | ConvertFrom-StringData

$version = 10

$startLocation = Get-Location
Set-Location ../apps
dotnet clean Backend.Finance
dotnet clean Backend.Customer
docker build -t customer:build -f .\Backend.Customer\Dockerfile .
docker build -t finance:build -f .\Backend.Finance\Dockerfile .
Set-Location $startLocation
az acr login --name $($secrets.containerRegistryName)

docker tag finance:build "$($secrets.containerRegistryName).azurecr.io/testing/finance:$($version)"
docker tag finance:build "$($secrets.containerRegistryName).azurecr.io/testing/finance:latest"

docker tag customer:build "$($secrets.containerRegistryName).azurecr.io/testing/customer:$($version)"
docker tag customer:build "$($secrets.containerRegistryName).azurecr.io/testing/customer:latest"

docker push "$($secrets.containerRegistryName).azurecr.io/testing/finance:$($version)"
docker push "$($secrets.containerRegistryName).azurecr.io/testing/finance:latest"

docker push "$($secrets.containerRegistryName).azurecr.io/testing/customer:$($version)"
docker push "$($secrets.containerRegistryName).azurecr.io/testing/customer:latest"

docker image rm finance:build
docker image rm customer:build
docker image rm "$($secrets.containerRegistryName).azurecr.io/testing/finance:$($version)"
docker image rm "$($secrets.containerRegistryName).azurecr.io/testing/finance:latest"
docker image rm  "$($secrets.containerRegistryName).azurecr.io/testing/customer:$($version)"
docker image rm  "$($secrets.containerRegistryName).azurecr.io/testing/customer:latest"



