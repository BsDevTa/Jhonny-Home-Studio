namespace JhonnyHomeStudio.Application.Common.Services;

public interface IFileStorageService
{
    Task<StoredFileResponse> SaveAsync(
        Stream content,
        string originalFileName,
        string contentType,
        string relativeFolder,
        string filePrefix,
        Uri publicOrigin,
        CancellationToken cancellationToken = default);

    Task<StoredFileDownload?> GetAsync(
        string relativePath,
        CancellationToken cancellationToken = default);
}

public sealed class StoredFileResponse
{
    public string FileName { get; set; } = string.Empty;
    public string RelativePath { get; set; } = string.Empty;
    public string PublicUrl { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
    public bool Exists { get; set; }
    public string? PhysicalPath { get; set; }
    public string StorageProvider { get; set; } = string.Empty;
}

public sealed class StoredFileDownload
{
    public Stream Content { get; set; } = Stream.Null;
    public string ContentType { get; set; } = "application/octet-stream";
    public long? SizeBytes { get; set; }
}
