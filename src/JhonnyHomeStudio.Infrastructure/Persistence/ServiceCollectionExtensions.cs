using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Settings;
using JhonnyHomeStudio.Infrastructure.Authentication;
using JhonnyHomeStudio.Infrastructure.Security;
using JhonnyHomeStudio.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace JhonnyHomeStudio.Infrastructure.Persistence;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");

        services.AddDbContext<JhonnyHomeStudioDbContext>(options =>
        {
            options.UseNpgsql(connectionString);
        });

        var jwtSettings = new JwtSettings
        {
            SecretKey = configuration["JwtSettings:SecretKey"] ?? string.Empty,
            Issuer = configuration["JwtSettings:Issuer"] ?? string.Empty,
            Audience = configuration["JwtSettings:Audience"] ?? string.Empty,
            ExpirationMinutes = int.TryParse(configuration["JwtSettings:ExpirationMinutes"], out var expirationMinutes)
                ? expirationMinutes
                : 120
        };
        services.AddSingleton(jwtSettings);
        var schedulingSettings = new AppointmentSchedulingSettings
        {
            DefaultDurationMinutes = int.TryParse(configuration["Scheduling:DefaultAppointmentDurationMinutes"], out var defaultDurationMinutes)
                ? defaultDurationMinutes
                : 60
        };
        services.AddSingleton(schedulingSettings);
        services.AddScoped<IPasswordHasher, PasswordHasher>();
        services.AddScoped<IJwtTokenService, JwtTokenService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IServiceService, ServiceService>();
        services.AddScoped<ICustomerService, CustomerService>();
        services.AddScoped<IAddressService, AddressService>();
        services.AddScoped<IAppointmentService, AppointmentService>();
        services.AddScoped<IStoryService, StoryService>();
        services.AddScoped<IStudioSettingsService, StudioSettingsService>();
        services.AddScoped<IAvailabilityService, AvailabilityService>();
        services.AddScoped<ILoyaltyService, LoyaltyService>();
        services.AddScoped<IMarketplaceService, MarketplaceService>();
        services.AddHostedService<StorageConfigurationStartupValidator>();
        services.AddScoped<IFileStorageService>(provider =>
        {
            var environment = provider.GetRequiredService<IHostEnvironment>();
            var logger = provider.GetRequiredService<ILoggerFactory>().CreateLogger("FileStorage");
            var storageProvider = ReadOptional(configuration, "STORAGE_PROVIDER", "Storage:Provider") ?? string.Empty;
            var hasRailwayBucketVariables =
                !string.IsNullOrWhiteSpace(ReadOptional(configuration, "BUCKET", "Storage:S3:BucketName")) &&
                !string.IsNullOrWhiteSpace(ReadOptional(configuration, "ENDPOINT", "Storage:S3:Endpoint", "AWS_ENDPOINT_URL_S3", "AWS_ENDPOINT_URL"));

            if (storageProvider.Equals("S3", StringComparison.OrdinalIgnoreCase) ||
                storageProvider.Equals("RailwayBucket", StringComparison.OrdinalIgnoreCase) ||
                hasRailwayBucketVariables)
            {
                logger.LogInformation(
                    "File storage provider selected. Provider={Provider}; HasBucket={HasBucket}; HasEndpoint={HasEndpoint}; HasPublicBaseUrl={HasPublicBaseUrl}",
                    string.IsNullOrWhiteSpace(storageProvider) ? "RailwayBucket" : storageProvider,
                    !string.IsNullOrWhiteSpace(ReadOptional(configuration, "BUCKET", "Storage:S3:BucketName")),
                    !string.IsNullOrWhiteSpace(ReadOptional(configuration, "ENDPOINT", "Storage:S3:Endpoint", "AWS_ENDPOINT_URL_S3", "AWS_ENDPOINT_URL")),
                    !string.IsNullOrWhiteSpace(ReadOptional(configuration, "STORAGE_PUBLIC_BASE_URL", "Storage:S3:PublicBaseUrl")));

                return new S3FileStorageService(
                    configuration,
                    provider.GetRequiredService<ILogger<S3FileStorageService>>());
            }

            if (!environment.IsDevelopment())
            {
                throw new StorageUnavailableAppException(
                    "Storage persistente não configurado. Defina STORAGE_PROVIDER=RailwayBucket, BUCKET, ENDPOINT, ACCESS_KEY_ID e SECRET_ACCESS_KEY.",
                    new[] { "No Railway, adicione um Storage Bucket ao projeto e vincule essas variáveis ao serviço da API." });
            }

            logger.LogInformation("File storage provider selected. Provider=Local; Environment={Environment}", environment.EnvironmentName);
            return new LocalFileStorageService(
                environment,
                provider.GetRequiredService<ILogger<LocalFileStorageService>>());
        });

        return services;
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
}
