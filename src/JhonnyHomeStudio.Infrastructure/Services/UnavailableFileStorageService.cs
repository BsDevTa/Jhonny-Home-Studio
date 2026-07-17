using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.Extensions.Logging;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class UnavailableFileStorageService : IFileStorageService
{
    private const string UnavailableMessage = "O armazenamento de mídia não está configurado.";

    private readonly ILogger<UnavailableFileStorageService> _logger;
    private readonly string _reason;
    private readonly string _provider;
    private readonly bool _bucketConfigured;
    private readonly bool _endpointConfigured;
    private readonly bool _accessKeyConfigured;
    private readonly bool _secretKeyConfigured;
    private readonly bool _publicBaseUrlConfigured;

    public UnavailableFileStorageService(
        ILogger<UnavailableFileStorageService> logger,
        string reason,
        string provider,
        bool bucketConfigured,
        bool endpointConfigured,
        bool accessKeyConfigured,
        bool secretKeyConfigured,
        bool publicBaseUrlConfigured)
    {
        _logger = logger;
        _reason = reason;
        _provider = provider;
        _bucketConfigured = bucketConfigured;
        _endpointConfigured = endpointConfigured;
        _accessKeyConfigured = accessKeyConfigured;
        _secretKeyConfigured = secretKeyConfigured;
        _publicBaseUrlConfigured = publicBaseUrlConfigured;
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
            "Storage upload unavailable. Provider={Provider}; BucketConfigured={BucketConfigured}; EndpointConfigured={EndpointConfigured}; AccessKeyConfigured={AccessKeyConfigured}; SecretKeyConfigured={SecretKeyConfigured}; PublicBaseUrlConfigured={PublicBaseUrlConfigured}; Operation=Save; Folder={Folder}; FileName={FileName}; Reason={Reason}",
            _provider,
            _bucketConfigured,
            _endpointConfigured,
            _accessKeyConfigured,
            _secretKeyConfigured,
            _publicBaseUrlConfigured,
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
            "Storage upload unavailable. Provider={Provider}; BucketConfigured={BucketConfigured}; EndpointConfigured={EndpointConfigured}; AccessKeyConfigured={AccessKeyConfigured}; SecretKeyConfigured={SecretKeyConfigured}; PublicBaseUrlConfigured={PublicBaseUrlConfigured}; Operation=Get; Path={Path}; Reason={Reason}",
            _provider,
            _bucketConfigured,
            _endpointConfigured,
            _accessKeyConfigured,
            _secretKeyConfigured,
            _publicBaseUrlConfigured,
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
            "Storage upload unavailable. Provider={Provider}; BucketConfigured={BucketConfigured}; EndpointConfigured={EndpointConfigured}; AccessKeyConfigured={AccessKeyConfigured}; SecretKeyConfigured={SecretKeyConfigured}; PublicBaseUrlConfigured={PublicBaseUrlConfigured}; Operation=Delete; FileUrl={FileUrl}; Reason={Reason}",
            _provider,
            _bucketConfigured,
            _endpointConfigured,
            _accessKeyConfigured,
            _secretKeyConfigured,
            _publicBaseUrlConfigured,
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
