param location string
param appEnvironmentId string

param containerRegistryLoginServer string
param containerRegistryUser string
@secure() 
param containerRegistryPassword string
@description('e.g. /something/imagename:v1')
param containerImage string
param containerName string

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerName
  location: location
  properties: {
    managedEnvironmentId: appEnvironmentId
    configuration: {
      secrets: [
        {
          name: 'container-registry-password'
          value: containerRegistryPassword
        }
      ]
      ingress: {
        external: true
        targetPort: 80
      }
      registries: [
        {
          //server is in the format of myregistry.azurecr.io
          server: containerRegistryLoginServer
          username: containerRegistryUser
          passwordSecretRef: 'container-registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          //This is in the format of myregistry.azurecr.io
          image: '${containerRegistryLoginServer}${containerImage}'
          name: containerName
          resources: {
            cpu: '0.5'
            memory: '1.0Gi'
          }
          volumeMounts: [
            {
              mountPath: '/storage'
              volumeName: 'appvolume'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      volumes: [
        {
          name: 'appvolume'
          storageType: 'AzureFile'
          storageName: 'environmentstorage'
        }
      ]
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
