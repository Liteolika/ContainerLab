using Azure.Identity;
using Backend.Shared;
using Microsoft.ApplicationInsights.AspNetCore.Extensions;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.Extensions.Logging.ApplicationInsights;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddUserSecrets<Program>();
}

builder.Configuration.AddEnvironmentVariables();

if (builder.Environment.IsProduction())
{
    builder.Configuration.AddAzureKeyVault(
        new Uri($"https://{builder.Configuration["KeyVaultName"]}.vault.azure.net/"),
        new DefaultAzureCredential(new DefaultAzureCredentialOptions
        {
            ManagedIdentityClientId = builder.Configuration["AzureADManagedIdentityClientId"]
        }));
}

// For YARP Reverse Proxy
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

builder.Logging.AddApplicationInsights(configureTelemetryConfiguration: (config) =>
{
    if (builder.Environment.IsProduction())
    {
        config.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
    }
}, configureApplicationInsightsLoggerOptions: (options) =>
{

});


//builder.Logging.AddFilter<ApplicationInsightsLoggerProvider>("your-category", LogLevel.Trace);

// Add services to the container.
builder.Services.AddApplicationInsightsTelemetry();

builder.Services.AddRazorPages();
builder.Services.AddTransient<IFileService, FileService>();

var app = builder.Build();

app.Use((context, next) =>
{
    if (context.Request.Headers.TryGetValue("X-Forwarded-Service", out var forwardedServiceName))
    {
        context.Request.PathBase = new PathString($"/{forwardedServiceName}");
    }
    return next(context);
});

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

// app.UseHttpsRedirection();
app.UseStaticFiles();

// For YARP Reverse Proxy
app.UseForwardedHeaders();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
