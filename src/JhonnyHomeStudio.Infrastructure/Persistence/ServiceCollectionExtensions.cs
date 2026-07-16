using JhonnyHomeStudio.Application.Common.Services;
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
        services.AddScoped<IFileStorageService>(provider =>
        {
            var environment = provider.GetRequiredService<IHostEnvironment>();
            var storageProvider = configuration["Storage:Provider"] ?? configuration["STORAGE_PROVIDER"] ?? string.Empty;
            var hasRailwayBucketVariables =
                !string.IsNullOrWhiteSpace(configuration["BUCKET"]) &&
                !string.IsNullOrWhiteSpace(configuration["ENDPOINT"]);

            if (storageProvider.Equals("S3", StringComparison.OrdinalIgnoreCase) ||
                storageProvider.Equals("RailwayBucket", StringComparison.OrdinalIgnoreCase) ||
                hasRailwayBucketVariables)
            {
                return new S3FileStorageService(
                    configuration,
                    provider.GetRequiredService<ILogger<S3FileStorageService>>());
            }

            if (!environment.IsDevelopment())
            {
                throw new InvalidOperationException(
                    "Storage persistente não configurado. Em produção, defina Storage:Provider=S3 ou RailwayBucket com BUCKET, ENDPOINT, ACCESS_KEY_ID e SECRET_ACCESS_KEY.");
            }

            return new LocalFileStorageService(
                environment,
                provider.GetRequiredService<ILogger<LocalFileStorageService>>());
        });

        return services;
    }
}
