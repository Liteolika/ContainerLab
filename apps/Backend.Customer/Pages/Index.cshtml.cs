using Backend.Shared;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Backend.Customer.Pages
{
    public class IndexModel : PageModel
    {
        private readonly ILogger<IndexModel> _logger;
        private readonly IFileService _fileService;

        public Dictionary<string, string> Data = new Dictionary<string, string>();

        public IndexModel(ILogger<IndexModel> logger, IFileService fileService, IConfiguration configuration)
        {
            _logger = logger;
            _fileService = fileService;

            var keyVaultName = configuration["KeyVaultName"];
            Data.Add("KeyVaultName", keyVaultName);

            var azureAdManagedIdentityClientId = configuration["AzureADManagedIdentityClientId"];
            Data.Add("AzureADManagedIdentityClientId", azureAdManagedIdentityClientId);

        }

        public async Task OnGet()
        {
            _logger.LogWarning($"{nameof(IndexModel)} - {nameof(OnGet)}");

            await _fileService.CreateFile(nameof(Customer));
        }
    }
}