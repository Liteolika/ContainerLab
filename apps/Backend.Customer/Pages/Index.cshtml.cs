using Backend.Shared;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Backend.Customer.Pages
{
    public class IndexModel : PageModel
    {
        private readonly ILogger<IndexModel> _logger;
        private readonly IFileService _fileService;

        public IndexModel(ILogger<IndexModel> logger, IFileService fileService)
        {
            _logger = logger;
            _fileService = fileService;
        }

        public async Task OnGet()
        {
            await _fileService.CreateFile(nameof(Customer));
        }
    }
}