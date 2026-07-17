using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

namespace JhonnyHomeStudio.Infrastructure.Services;

internal sealed record StorageConfigurationStatus(
    string Provider,
    bool UseS3Storage,
    bool UseLocalStorage,
    bool StorageAvailable,
    bool HasBucket,
    string? Bucket,
    bool HasEndpoint,
    string? Endpoint,
    string SanitizedEndpoint,
    bool HasAccessKeyId,
    bool HasSecretAccessKey,
    bool PublicBaseUrlConfigured,
    bool ForcePathStyle,
    string Reason);

internal static class StorageConfigurationStatusFactory
{
    public static StorageConfigurationStatus Evaluate(
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        var configuredProvider = ReadOptional(configuration, "STORAGE_PROVIDER", "Storage:Provider");
        var provider = string.IsNullOrWhiteSpace(configuredProvider)
            ? string.Empty
            : configuredProvider.Trim();

        var bucket = ReadOptional(configuration, "BUCKET", "Storage:S3:BucketName");
        var endpoint = ReadOptional(configuration, "ENDPOINT", "Storage:S3:Endpoint", "AWS_ENDPOINT_URL_S3", "AWS_ENDPOINT_URL");
        var accessKeyId = ReadOptional(configuration, "ACCESS_KEY_ID", "Storage:S3:AccessKeyId", "AWS_ACCESS_KEY_ID");
        var secretAccessKey = ReadOptional(configuration, "SECRET_ACCESS_KEY", "Storage:S3:SecretAccessKey", "AWS_SECRET_ACCESS_KEY");
        var hasBucket = !string.IsNullOrWhiteSpace(bucket);
        var hasEndpoint = !string.IsNullOrWhiteSpace(endpoint);
        var hasAccessKeyId = !string.IsNullOrWhiteSpace(accessKeyId);
        var hasSecretAccessKey = !string.IsNullOrWhiteSpace(secretAccessKey);
        var hasPersistentConfiguration =
            hasBucket ||
            hasEndpoint ||
            hasAccessKeyId ||
            hasSecretAccessKey;
        var isS3Provider =
            provider.Equals("S3", StringComparison.OrdinalIgnoreCase) ||
            provider.Equals("RailwayBucket", StringComparison.OrdinalIgnoreCase) ||
            (string.IsNullOrWhiteSpace(provider) && hasPersistentConfiguration);
        var isLocalProvider = provider.Equals("Local", StringComparison.OrdinalIgnoreCase);
        var effectiveProvider = string.IsNullOrWhiteSpace(provider)
            ? isS3Provider ? "RailwayBucket" : "Local"
            : provider;
        var publicBaseUrlConfigured = !string.IsNullOrWhiteSpace(ReadOptional(configuration, "STORAGE_PUBLIC_BASE_URL", "Storage:S3:PublicBaseUrl"));
        var forcePathStyle = ResolveForcePathStyle(configuration, effectiveProvider);
        var sanitizedEndpoint = SanitizeEndpoint(endpoint);

        if (isS3Provider)
        {
            var missingSettings = new List<string>();
            if (!hasBucket)
            {
                missingSettings.Add("BUCKET");
            }

            if (!hasEndpoint)
            {
                missingSettings.Add("ENDPOINT");
            }

            if (!hasAccessKeyId)
            {
                missingSettings.Add("ACCESS_KEY_ID");
            }

            if (!hasSecretAccessKey)
            {
                missingSettings.Add("SECRET_ACCESS_KEY");
            }

            if (missingSettings.Count > 0)
            {
                return Unavailable(
                    effectiveProvider,
                    bucket,
                    endpoint,
                    sanitizedEndpoint,
                    hasBucket,
                    hasEndpoint,
                    hasAccessKeyId,
                    hasSecretAccessKey,
                    publicBaseUrlConfigured,
                    forcePathStyle,
                    $"Variáveis obrigatórias ausentes: {string.Join(", ", missingSettings)}.");
            }

            var requireHttps = !environment.IsDevelopment() ||
                effectiveProvider.Equals("RailwayBucket", StringComparison.OrdinalIgnoreCase);
            if ((!Uri.TryCreate(endpoint, UriKind.Absolute, out var endpointUri) ||
                    !endpointUri.Scheme.Equals(Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase)) &&
                requireHttps)
            {
                return Unavailable(
                    effectiveProvider,
                    bucket,
                    endpoint,
                    sanitizedEndpoint,
                    hasBucket,
                    hasEndpoint,
                    hasAccessKeyId,
                    hasSecretAccessKey,
                    publicBaseUrlConfigured,
                    forcePathStyle,
                    "ENDPOINT precisa ser uma URL HTTPS válida.");
            }

            return new StorageConfigurationStatus(
                effectiveProvider,
                UseS3Storage: true,
                UseLocalStorage: false,
                StorageAvailable: true,
                hasBucket,
                bucket,
                hasEndpoint,
                endpoint,
                sanitizedEndpoint,
                hasAccessKeyId,
                hasSecretAccessKey,
                publicBaseUrlConfigured,
                forcePathStyle,
                "Storage persistente configurado.");
        }

        if (environment.IsDevelopment() && (string.IsNullOrWhiteSpace(provider) || isLocalProvider))
        {
            return new StorageConfigurationStatus(
                "Local",
                UseS3Storage: false,
                UseLocalStorage: true,
                StorageAvailable: true,
                hasBucket,
                bucket,
                hasEndpoint,
                endpoint,
                sanitizedEndpoint,
                hasAccessKeyId,
                hasSecretAccessKey,
                publicBaseUrlConfigured,
                forcePathStyle,
                "Storage local habilitado em Development.");
        }

        return Unavailable(
            string.IsNullOrWhiteSpace(effectiveProvider) ? "Unavailable" : effectiveProvider,
            bucket,
            endpoint,
            sanitizedEndpoint,
            hasBucket,
            hasEndpoint,
            hasAccessKeyId,
            hasSecretAccessKey,
            publicBaseUrlConfigured,
            forcePathStyle,
            string.IsNullOrWhiteSpace(provider)
                ? "Nenhum storage persistente configurado."
                : $"Provider de storage não disponível em {environment.EnvironmentName}: {provider}.");
    }

    private static StorageConfigurationStatus Unavailable(
        string provider,
        string? bucket,
        string? endpoint,
        string sanitizedEndpoint,
        bool hasBucket,
        bool hasEndpoint,
        bool hasAccessKeyId,
        bool hasSecretAccessKey,
        bool publicBaseUrlConfigured,
        bool forcePathStyle,
        string reason)
    {
        return new StorageConfigurationStatus(
            provider,
            UseS3Storage: false,
            UseLocalStorage: false,
            StorageAvailable: false,
            hasBucket,
            bucket,
            hasEndpoint,
            endpoint,
            sanitizedEndpoint,
            hasAccessKeyId,
            hasSecretAccessKey,
            publicBaseUrlConfigured,
            forcePathStyle,
            reason);
    }

    private static string? ReadOptional(IConfiguration configuration, params string[] keys)
    {
        foreach (var key in keys)
        {
            var value = configuration[key];
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim();
            }
        }

        return null;
    }

    private static bool ResolveForcePathStyle(IConfiguration configuration, string provider)
    {
        var configured = ReadOptional(configuration, "Storage:S3:ForcePathStyle", "S3_FORCE_PATH_STYLE");
        if (bool.TryParse(configured, out var parsed))
        {
            return parsed;
        }

        return provider.Equals("RailwayBucket", StringComparison.OrdinalIgnoreCase) ||
            !string.IsNullOrWhiteSpace(configuration["BUCKET"]);
    }

    private static string SanitizeEndpoint(string? endpoint)
    {
        if (string.IsNullOrWhiteSpace(endpoint) ||
            !Uri.TryCreate(endpoint, UriKind.Absolute, out var uri))
        {
            return "<not-configured>";
        }

        return uri.GetLeftPart(UriPartial.Authority);
    }
}
