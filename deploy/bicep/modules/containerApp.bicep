param location string
param appEnvironmentId string

param containerRegistryLoginServer string

@description('e.g. /something/imagename:v1')
param containerImage string
param containerName string
param identityId string

param env array = []

var defaultEnv = [
  {
    name: 'defaultEnv'
    value: 'defaultEnvValue'
  }
]

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: appEnvironmentId
    configuration: {
      secrets: []
      ingress: {
        external: true
        targetPort: 80
      }
      registries: [
        {
          identity: identityId
          server: containerRegistryLoginServer
        }
      ]
    }
    template: {
      containers: [
        {
          //This is in the format of myregistry.azurecr.io
          image: '${containerRegistryLoginServer}${containerImage}'
          name: containerName
          env: concat(defaultEnv, env)
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
