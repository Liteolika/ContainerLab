// Check this!
// https://github.com/Azure-Samples/dotNET-FrontEnd-to-BackEnd-on-Azure-Container-Apps/blob/main/infra/core/host/container-app-upsert.bicep

param location string
param appEnvironmentId string

param containerRegistryLoginServer string

param externalIngressEnabled bool
// param externalIngressTargetPort int = 80

@description('e.g. /something/imagename:v1')
param containerImage string
param containerName string
param identityId string

param env array = []

param allowedOrigins array = []

var defaultEnv = [
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: 'Production'
  }
  {
    name: 'ASPNETCORE_URLS'
    value: 'http://+:80'
    //value: 'http://+:80:https://*:443'
  }
]

resource containerApp 'Microsoft.App/containerApps@2022-11-01-preview' = {
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
      // ingress: ingressEnabled ? {
      //   external: true  // Bool indicating if app exposes an external http endpoint
      //   targetPort: 80  // Target Port in containers for traffic from ingress
      //   //exposedPort: 80   // Exposed Port in containers for TCP traffic from ingress
      //   transport: 'auto'
      //   corsPolicy: {
      //     allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
      //   }
      // } : null
      ingress: {
        external: externalIngressEnabled
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
output containerName string = containerApp.name
