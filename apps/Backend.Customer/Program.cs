using Azure.Identity;
using Backend.Shared;

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

//builder.Logging.AddApplicationInsights();

builder.Logging.AddApplicationInsights(configureTelemetryConfiguration: (config) =>
{
    if (builder.Environment.IsProduction())
    {
        config.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
    }
}, configureApplicationInsightsLoggerOptions: (options) =>
{

});

// Add services to the container.
builder.Services.AddApplicationInsightsTelemetry();

builder.Services.AddRazorPages();
builder.Services.AddTransient<IFileService, FileService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
