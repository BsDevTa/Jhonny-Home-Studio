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
        var status = StorageConfigurationStatusFactory.Evaluate(_configuration, _environment);
        if (status.StorageAvailable)
        {
            _logger.LogInformation(
                "Storage startup configuration. Provider={Provider}; BucketConfigured={BucketConfigured}; Endpoint={Endpoint}; PublicBaseUrlConfigured={PublicBaseUrlConfigured}; ForcePathStyle={ForcePathStyle}; StorageAvailable={StorageAvailable}",
                status.Provider,
                status.HasBucket,
                status.SanitizedEndpoint,
                status.PublicBaseUrlConfigured,
                status.ForcePathStyle,
                status.StorageAvailable);
            return Task.CompletedTask;
        }

        _logger.LogError(
            "Storage provider unavailable. API will remain online. Media operations will return 503. Provider={Provider}; BucketConfigured={BucketConfigured}; EndpointConfigured={EndpointConfigured}; Endpoint={Endpoint}; AccessKeyIdConfigured={AccessKeyIdConfigured}; SecretAccessKeyConfigured={SecretAccessKeyConfigured}; PublicBaseUrlConfigured={PublicBaseUrlConfigured}; ForcePathStyle={ForcePathStyle}; StorageAvailable={StorageAvailable}; Reason={Reason}",
            status.Provider,
            status.HasBucket,
            status.HasEndpoint,
            status.SanitizedEndpoint,
            status.HasAccessKeyId,
            status.HasSecretAccessKey,
            status.PublicBaseUrlConfigured,
            status.ForcePathStyle,
            status.StorageAvailable,
            status.Reason);

        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }

}
