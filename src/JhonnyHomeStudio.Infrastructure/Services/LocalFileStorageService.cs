using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class LocalFileStorageService : IFileStorageService
{
    private readonly IHostEnvironment _environment;
    private readonly ILogger<LocalFileStorageService> _logger;

    public LocalFileStorageService(
        IHostEnvironment environment,
        ILogger<LocalFileStorageService> logger)
    {
        _environment = environment;
        _logger = logger;
    }

    public async Task<StoredFileResponse> SaveAsync(
        Stream content,
        string originalFileName,
        string contentType,
        string relativeFolder,
        string filePrefix,
        Uri publicOrigin,
        CancellationToken cancellationToken = default)
    {
        var extension = Path.GetExtension(originalFileName).ToLowerInvariant();
        var normalizedFolder = relativeFolder
            .Trim()
            .Trim('/', '\\')
            .Replace('\\', '/');
        var webRootPath = Path.Combine(_environment.ContentRootPath, "wwwroot");
        var storagePath = Path.Combine(
            webRootPath,
            normalizedFolder.Replace('/', Path.DirectorySeparatorChar));

        Directory.CreateDirectory(storagePath);

        var fileName = $"{filePrefix}_{Guid.NewGuid():N}{extension}";
        var destinationPath = Path.Combine(storagePath, fileName);

        await using (var destination = File.Create(destinationPath))
        {
            await content.CopyToAsync(destination, cancellationToken);
        }

        var fileInfo = new FileInfo(destinationPath);
        if (!fileInfo.Exists || fileInfo.Length <= 0)
        {
            throw new IOException($"Arquivo não foi gravado corretamente em {destinationPath}.");
        }

        var relativePath = $"/{normalizedFolder}/{fileName}";
        var publicUrl = new Uri(publicOrigin, relativePath).ToString();

        _logger.LogInformation(
            "Upload Story/Media Local: Root={Root}; PhysicalPath={PhysicalPath}; PublicUrl={PublicUrl}; Exists={Exists}; SizeBytes={SizeBytes}",
            webRootPath,
            destinationPath,
            publicUrl,
            fileInfo.Exists,
            fileInfo.Length);

        return new StoredFileResponse
        {
            FileName = fileName,
            RelativePath = relativePath,
            PublicUrl = publicUrl,
            ContentType = NormalizeContentType(contentType, extension),
            SizeBytes = fileInfo.Length,
            Exists = fileInfo.Exists,
            PhysicalPath = destinationPath,
            StorageProvider = "Local"
        };
    }

    public Task<StoredFileDownload?> GetAsync(
        string relativePath,
        CancellationToken cancellationToken = default)
    {
        var normalizedPath = NormalizeUploadsPath(relativePath);
        if (string.IsNullOrWhiteSpace(normalizedPath))
        {
            return Task.FromResult<StoredFileDownload?>(null);
        }

        var webRootPath = Path.Combine(_environment.ContentRootPath, "wwwroot");
        var physicalPath = Path.GetFullPath(Path.Combine(
            webRootPath,
            normalizedPath.Replace('/', Path.DirectorySeparatorChar)));
        var rootPath = Path.GetFullPath(webRootPath);

        if (!physicalPath.StartsWith(rootPath, StringComparison.OrdinalIgnoreCase) || !File.Exists(physicalPath))
        {
            return Task.FromResult<StoredFileDownload?>(null);
        }

        var fileInfo = new FileInfo(physicalPath);
        var extension = Path.GetExtension(physicalPath).ToLowerInvariant();
        return Task.FromResult<StoredFileDownload?>(new StoredFileDownload
        {
            Content = File.OpenRead(physicalPath),
            ContentType = NormalizeContentType(string.Empty, extension),
            SizeBytes = fileInfo.Length
        });
    }

    public Task DeleteAsync(
        string fileUrl,
        CancellationToken cancellationToken = default)
    {
        var normalizedPath = NormalizeUploadsPath(ReadPath(fileUrl));
        if (string.IsNullOrWhiteSpace(normalizedPath))
        {
            return Task.CompletedTask;
        }

        var webRootPath = Path.Combine(_environment.ContentRootPath, "wwwroot");
        var physicalPath = Path.GetFullPath(Path.Combine(
            webRootPath,
            normalizedPath.Replace('/', Path.DirectorySeparatorChar)));
        var rootPath = Path.GetFullPath(webRootPath);

        if (physicalPath.StartsWith(rootPath, StringComparison.OrdinalIgnoreCase) && File.Exists(physicalPath))
        {
            File.Delete(physicalPath);
        }

        return Task.CompletedTask;
    }

    private static string NormalizeUploadsPath(string relativePath)
    {
        var normalizedPath = relativePath
            .Trim()
            .Trim('/', '\\')
            .Replace('\\', '/');

        if (string.IsNullOrWhiteSpace(normalizedPath))
        {
            return string.Empty;
        }

        return normalizedPath.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase)
            ? normalizedPath
            : $"uploads/{normalizedPath}";
    }

    private static string ReadPath(string fileUrl)
    {
        if (Uri.TryCreate(fileUrl, UriKind.Absolute, out var uri))
        {
            return uri.LocalPath;
        }

        return fileUrl;
    }

    private static string NormalizeContentType(string contentType, string extension)
    {
        if (!string.IsNullOrWhiteSpace(contentType))
        {
            return contentType;
        }

        return extension.ToLowerInvariant() switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".mp4" => "video/mp4",
            ".mov" => "video/quicktime",
            ".webm" => "video/webm",
            _ => "application/octet-stream"
        };
    }
}
