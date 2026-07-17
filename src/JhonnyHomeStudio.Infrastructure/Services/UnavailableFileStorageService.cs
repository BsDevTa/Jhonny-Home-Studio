using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.Extensions.Logging;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class UnavailableFileStorageService : IFileStorageService
{
    private const string UnavailableMessage = "O armazenamento de mídia não está configurado.";

    private readonly ILogger<UnavailableFileStorageService> _logger;
    private readonly string _reason;

    public UnavailableFileStorageService(
        ILogger<UnavailableFileStorageService> logger,
        string reason)
    {
        _logger = logger;
        _reason = reason;
    }

    public Task<StoredFileResponse> SaveAsync(
        Stream content,
        string originalFileName,
        string contentType,
        string relativeFolder,
        string filePrefix,
        Uri publicOrigin,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        _logger.LogWarning(
            "Storage provider unavailable. API will remain online. Media operations will return 503. Operation=Save; Folder={Folder}; FileName={FileName}; Reason={Reason}",
            relativeFolder,
            originalFileName,
            _reason);

        return Task.FromException<StoredFileResponse>(CreateException());
    }

    public Task<StoredFileDownload?> GetAsync(
        string relativePath,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        _logger.LogWarning(
            "Storage provider unavailable. API will remain online. Media operations will return 503. Operation=Get; Path={Path}; Reason={Reason}",
            relativePath,
            _reason);

        return Task.FromException<StoredFileDownload?>(CreateException());
    }

    public Task DeleteAsync(
        string fileUrl,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        _logger.LogWarning(
            "Storage provider unavailable. API will remain online. Media operations will return 503. Operation=Delete; FileUrl={FileUrl}; Reason={Reason}",
            fileUrl,
            _reason);

        return Task.FromException(CreateException());
    }

    private static StorageUnavailableAppException CreateException()
    {
        return new StorageUnavailableAppException(
            UnavailableMessage,
            new[] { "Configure BUCKET, ENDPOINT, ACCESS_KEY_ID e SECRET_ACCESS_KEY no Railway." });
    }
}
