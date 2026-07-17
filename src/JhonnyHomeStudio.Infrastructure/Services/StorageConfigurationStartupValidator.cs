using JhonnyHomeStudio.Application.Common.Exceptions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class StorageConfigurationStartupValidator : IHostedService
{
    private readonly IConfiguration _configuration;
    private readonly IHostEnvironment _environment;
    private readonly ILogger<StorageConfigurationStartupValidator> _logger;

    public StorageConfigurationStartupValidator(
        IConfiguration configuration,
        IHostEnvironment environment,
        ILogger<StorageConfigurationStartupValidator> logger)
    {
        _configuration = configuration;
        _environment = environment;
        _logger = logger;
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        var storageProvider = ReadOptional("STORAGE_PROVIDER", "Storage:Provider") ?? string.Empty;
        var hasRailwayBucketVariables =
            !string.IsNullOrWhiteSpace(ReadOptional("BUCKET", "Storage:S3:BucketName")) &&
            !string.IsNullOrWhiteSpace(ReadOptional("ENDPOINT", "Storage:S3:Endpoint"));
        var usesPersistentStorage =
            storageProvider.Equals("S3", StringComparison.OrdinalIgnoreCase) ||
            storageProvider.Equals("RailwayBucket", StringComparison.OrdinalIgnoreCase) ||
            hasRailwayBucketVariables;

        if (!usesPersistentStorage)
        {
            if (!_environment.IsDevelopment())
            {
                throw new StorageUnavailableAppException(
                    "Storage persistente não configurado.",
                    new[] { "Em produção, defina STORAGE_PROVIDER=RailwayBucket com BUCKET, ENDPOINT, ACCESS_KEY_ID e SECRET_ACCESS_KEY." });
            }

            _logger.LogInformation(
                "Storage startup configuration. Provider=Local; Environment={Environment}; PersistentStorage=False",
                _environment.EnvironmentName);
            return Task.CompletedTask;
        }

        var providerName = string.IsNullOrWhiteSpace(storageProvider) ? "RailwayBucket" : storageProvider.Trim();
        var bucket = ReadRequired("BUCKET", "Storage:S3:BucketName");
        var endpoint = ReadRequired("ENDPOINT", "Storage:S3:Endpoint", "AWS_ENDPOINT_URL_S3", "AWS_ENDPOINT_URL");
        _ = ReadRequired("ACCESS_KEY_ID", "Storage:S3:AccessKeyId", "AWS_ACCESS_KEY_ID");
        _ = ReadRequired("SECRET_ACCESS_KEY", "Storage:S3:SecretAccessKey", "AWS_SECRET_ACCESS_KEY");
        var sanitizedEndpoint = SanitizeEndpoint(endpoint);
        var forcePathStyle = ResolveForcePathStyle(providerName);

        var requireHttps = !_environment.IsDevelopment() ||
            providerName.Equals("RailwayBucket", StringComparison.OrdinalIgnoreCase);
        if ((!Uri.TryCreate(endpoint, UriKind.Absolute, out var endpointUri) ||
                !endpointUri.Scheme.Equals(Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase)) &&
            requireHttps)
        {
            throw new StorageUnavailableAppException(
                "Endpoint do storage inválido.",
                new[] { "Configure ENDPOINT com uma URL HTTPS válida para o Railway Bucket." });
        }

        _logger.LogInformation(
            "Storage startup configuration. Provider={Provider}; Bucket={Bucket}; Endpoint={Endpoint}; PublicBaseUrlConfigured={PublicBaseUrlConfigured}; ForcePathStyle={ForcePathStyle}",
            providerName,
            bucket,
            sanitizedEndpoint,
            !string.IsNullOrWhiteSpace(ReadOptional("STORAGE_PUBLIC_BASE_URL", "Storage:S3:PublicBaseUrl")),
            forcePathStyle);

        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }

    private string ReadRequired(params string[] keys)
    {
        var value = ReadOptional(keys);
        if (!string.IsNullOrWhiteSpace(value))
        {
            return value;
        }

        throw new StorageUnavailableAppException(
            "Configuração de storage ausente.",
            new[] { $"Informe uma destas variáveis: {string.Join(", ", keys)}." });
    }

    private string? ReadOptional(params string[] keys)
    {
        foreach (var key in keys)
        {
            var value = _configuration[key];
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim();
            }
        }

        return null;
    }

    private bool ResolveForcePathStyle(string providerName)
    {
        var configured = ReadOptional("Storage:S3:ForcePathStyle", "S3_FORCE_PATH_STYLE");
        if (bool.TryParse(configured, out var parsed))
        {
            return parsed;
        }

        return providerName.Equals("RailwayBucket", StringComparison.OrdinalIgnoreCase) ||
            !string.IsNullOrWhiteSpace(ReadOptional("BUCKET"));
    }

    private static string SanitizeEndpoint(string endpoint)
    {
        if (!Uri.TryCreate(endpoint, UriKind.Absolute, out var uri))
        {
            return "<invalid-endpoint>";
        }

        return uri.GetLeftPart(UriPartial.Authority);
    }
}
