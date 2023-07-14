using Yarp.ReverseProxy.Configuration;
using Yarp.ReverseProxy.Model;
using Yarp.ReverseProxy.Transforms;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddCustomReverseProxy();
builder.Configuration.AddEnvironmentVariables();

var app = builder.Build();

app.MapCustomReverseProxy();
app.UseHttpsRedirection();
app.UseAuthorization();

app.Run();

public static class ProxyConfigurator
{
    private static Dictionary<string, Uri> GetProxyClusters(IServiceCollection services)
    {
        var clusters = services.BuildServiceProvider().GetRequiredService<IConfiguration>().AsEnumerable()
            .Where(v => v.Key.StartsWith("CLUSTER_")).ToList();

        Dictionary<string, Uri> result = new Dictionary<string, Uri>();

        foreach (var cluster in clusters)
        {
            result.TryAdd(cluster.Key.Replace("CLUSTER_", ""), new Uri(cluster.Value));
        }

        return result;
    }

    public static IServiceCollection AddCustomReverseProxy(this IServiceCollection services)
    {
        // https://github.com/microsoft/reverse-proxy/blob/main

        var proxyClusters = GetProxyClusters(services);

        services.AddReverseProxy().LoadFromMemory(
            proxyClusters.Select(x=> CreateRouteFor(x.Key)).ToArray(),
            proxyClusters.Select(x=> CreateClusterFor(x.Key, x.Value)).ToArray()
            );
        return services;
    }

    public static IEndpointRouteBuilder MapCustomReverseProxy(this IEndpointRouteBuilder builder)
    {
        builder.MapReverseProxy(config =>
        {
            config.UseSessionAffinity();
            config.UseLoadBalancing();
            //config.Use(MyCustomProxyStep);
        });
        return builder;
    }

    private const string FinanceServiceName = "finance";
    private const string CustomerServiceName = "customer";

    private static RouteConfig CreateRouteFor(string serviceName)
    {
        return new RouteConfig()
        {
            RouteId = serviceName + Random.Shared.Next(), // Forces a new route id each time GetRoutes is called.
            ClusterId = $"{serviceName}Cluster",
            Match = new RouteMatch
            {
                // Path or Hosts are required for each route. This catch-all pattern matches all request paths.
                Path = $"/{serviceName}/{{**catchall}}"
            },
        }.WithTransform(transform =>
        {
            transform.Add("PathPattern", "{**catchall}");
        }).WithTransform(transform =>
        {
            transform.Add("RequestHeader", "X-Forwarded-Service");
            transform.Add("Set", serviceName);
        });
    }

    private static ClusterConfig CreateClusterFor(string serviceName, Uri uri,
        Dictionary<string, string>? metadata = null)
    {
        var cluster = new ClusterConfig()
        {
            ClusterId = $"{serviceName}Cluster",
            SessionAffinity = new SessionAffinityConfig
                { Enabled = true, Policy = "Cookie", AffinityKeyName = ".Yarp.ReverseProxy.Affinity" },
            Destinations = new Dictionary<string, DestinationConfig>(StringComparer.OrdinalIgnoreCase)
            {
                {
                    "default", new DestinationConfig()
                    {
                        Address = uri.ToString(),
                        Metadata = metadata
                    }
                },
            }
        };

        return cluster;
    }

    public static RouteConfig[] GetRoutes(IDictionary<string, string> services)
    {
        return services.Select(x => CreateRouteFor(x.Key)).ToArray();
        
        return new[]
        {
            CreateRouteFor("finance"),
            CreateRouteFor("customer")
            //new RouteConfig()
            //{
            //    RouteId = "finance" + Random.Shared.Next(), // Forces a new route id each time GetRoutes is called.
            //    ClusterId = "financeCluster",
            //    Match = new RouteMatch
            //    {
            //        // Path or Hosts are required for each route. This catch-all pattern matches all request paths.
            //        Path = "/finance/{**catchall}"
            //    },
            //}.WithTransform(transform =>
            //{
            //    transform.Add("PathPattern", "{**catchall}");
            //}).WithTransform(transform =>
            //{
            //    transform.Add("RequestHeader", "X-Forwarded-Service");
            //    transform.Add("Set", "finance");
            //})
            //    ,
            //new RouteConfig()
            //{
            //    RouteId = "customer" + Random.Shared.Next(), // Forces a new route id each time GetRoutes is called.
            //    ClusterId = "customerCluster",
            //    Match = new RouteMatch
            //    {
            //        // Path or Hosts are required for each route. This catch-all pattern matches all request paths.
            //        Path = "/customer/{**catchall}"
            //    },
            //}.WithTransform(transform =>
            //{
            //    transform.Add("PathPattern", "{**catchall}");
            //}).WithTransform(transform =>
            //{
            //    transform.Add("RequestHeader", "X-Forwarded-Service");
            //    transform.Add("Set", "customer");
            //})
        };
    }
    public static ClusterConfig[] GetClusters(IDictionary<string, string> services)
    {
        var debugMetadata = new Dictionary<string, string>();
        //debugMetadata.Add(DEBUG_METADATA_KEY, DEBUG_VALUE);

        return services.Select(x => CreateClusterFor(x.Key, new Uri(x.Value), debugMetadata)).ToArray();

        return new[]
        {
            CreateClusterFor("customer", new Uri("http://backend-customer:5001")),
            CreateClusterFor("finance", new Uri("http://backend-finance:5002")),
        };

        //return new[]
        //{
        //    new ClusterConfig()
        //    {
        //        ClusterId = "financeCluster",
        //        SessionAffinity = new SessionAffinityConfig { Enabled = true, Policy = "Cookie", AffinityKeyName = ".Yarp.ReverseProxy.Affinity" },
        //        Destinations = new Dictionary<string, DestinationConfig>(StringComparer.OrdinalIgnoreCase)
        //        {
        //            { "default", new DestinationConfig() {
        //                Address = "http://backend-finance:5002/",
        //                Metadata = debugMetadata  }
        //            },
        //        }
        //    },
        //    new ClusterConfig()
        //    {
        //        ClusterId = "customerCluster",
        //        SessionAffinity = new SessionAffinityConfig { Enabled = true, Policy = "Cookie", AffinityKeyName = ".Yarp.ReverseProxy.Affinity" },
        //        Destinations = new Dictionary<string, DestinationConfig>(StringComparer.OrdinalIgnoreCase)
        //        {
        //            {
        //                "default", new DestinationConfig() {
        //                    Address = "http://backend-customer:5001/",
        //                    //Metadata = debugMetadata
        //                }
        //            },
        //        }
        //    },
        //};
    }

    /// <summary>
    /// Custom proxy step that filters destinations based on a header in the inbound request
    /// Looks at each destination metadata, and filters in/out based on their debug flag and the inbound header
    /// </summary>
    public static Task MyCustomProxyStep(HttpContext context, Func<Task> next)
    {
        // Can read data from the request via the context
        //var useDebugDestinations = context.Request.Headers.TryGetValue(DEBUG_HEADER, out var headerValues) && headerValues.Count == 1 && headerValues[0] == DEBUG_VALUE;

        // The context also stores a ReverseProxyFeature which holds proxy specific data such as the cluster, route and destinations
        var availableDestinationsFeature = context.Features.Get<IReverseProxyFeature>();
        var filteredDestinations = new List<DestinationState>();

        // Filter destinations based on criteria
        foreach (var d in availableDestinationsFeature.AvailableDestinations)
        {
            //Todo: Replace with a lookup of metadata - but not currently exposed correctly here
            //if (d.DestinationId.Contains("debug") == useDebugDestinations) { filteredDestinations.Add(d); }
        }
        availableDestinationsFeature.AvailableDestinations = filteredDestinations;

        // Important - required to move to the next step in the proxy pipeline
        return next();
    }
}

