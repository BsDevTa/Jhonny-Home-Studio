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
            var status = StorageConfigurationStatusFactory.Evaluate(configuration, environment);

            if (status.UseS3Storage)
            {
                logger.LogInformation(
                    "File storage provider selected. Provider={Provider}; BucketConfigured={BucketConfigured}; Endpoint={Endpoint}; PublicBaseUrlConfigured={PublicBaseUrlConfigured}; StorageAvailable={StorageAvailable}",
                    status.Provider,
                    status.HasBucket,
                    status.SanitizedEndpoint,
                    status.PublicBaseUrlConfigured,
                    status.StorageAvailable);

                return new S3FileStorageService(
                    configuration,
                    provider.GetRequiredService<ILogger<S3FileStorageService>>());
            }

            if (status.UseLocalStorage)
            {
                logger.LogInformation("File storage provider selected. Provider=Local; Environment={Environment}", environment.EnvironmentName);
                return new LocalFileStorageService(
                    environment,
                    provider.GetRequiredService<ILogger<LocalFileStorageService>>());
            }

            logger.LogWarning(
                "RailwayBucket foi selecionado, mas as variáveis obrigatórias não estão configuradas. A API continuará disponível e uploads retornarão 503. Provider={Provider}; BucketConfigured={BucketConfigured}; EndpointConfigured={EndpointConfigured}; Endpoint={Endpoint}; AccessKeyIdConfigured={AccessKeyIdConfigured}; SecretAccessKeyConfigured={SecretAccessKeyConfigured}; PublicBaseUrlConfigured={PublicBaseUrlConfigured}; Reason={Reason}",
                status.Provider,
                status.HasBucket,
                status.HasEndpoint,
                status.SanitizedEndpoint,
                status.HasAccessKeyId,
                status.HasSecretAccessKey,
                status.PublicBaseUrlConfigured,
                status.Reason);

            return new UnavailableFileStorageService(
                provider.GetRequiredService<ILogger<UnavailableFileStorageService>>(),
                status.Reason);
        });

        return services;
    }
}
