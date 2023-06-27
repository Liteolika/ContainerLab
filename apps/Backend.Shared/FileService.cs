namespace Backend.Shared
{
    public interface IFileService
    {
        Task CreateFile(string serviceName);
    }

    public class FileService : IFileService
    {
        private const string storagePath = "/storage";
        
        public Task CreateFile(string serviceName)
        {
            var fileName = $"{serviceName}{DateTime.Now:yyyyMMddhhmmsstttt}";
            return File.AppendAllTextAsync(Path.Combine(storagePath, fileName), serviceName);
        }
    }
}