using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Application.Common.Settings;
using JhonnyHomeStudio.Infrastructure.Authentication;
using JhonnyHomeStudio.Infrastructure.Security;
using JhonnyHomeStudio.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

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
        services.AddScoped<IPasswordHasher, PasswordHasher>();
        services.AddScoped<IJwtTokenService, JwtTokenService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IServiceCategoryService, ServiceCategoryService>();
        services.AddScoped<IServiceService, ServiceService>();
        services.AddScoped<ICustomerService, CustomerService>();
        services.AddScoped<IAddressService, AddressService>();
        services.AddScoped<IAppointmentService, AppointmentService>();

        return services;
    }
}