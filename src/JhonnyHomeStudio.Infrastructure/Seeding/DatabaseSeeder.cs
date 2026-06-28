using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Domain.Enums;
using JhonnyHomeStudio.Infrastructure.Persistence;
using JhonnyHomeStudio.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace JhonnyHomeStudio.Infrastructure.Seeding;

public static class DatabaseSeeder
{
    public static async Task SeedInitialDataAsync(this IServiceProvider serviceProvider, CancellationToken cancellationToken = default)
    {
        using var scope = serviceProvider.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<JhonnyHomeStudioDbContext>();
        var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();

        await dbContext.Database.MigrateAsync(cancellationToken);

        var adminEmail = "admin@jhonnyhomestudio.com";
        var normalizedEmail = adminEmail.Trim().ToLowerInvariant();

        var adminUser = await dbContext.Users
            .FirstOrDefaultAsync(x => x.Email == normalizedEmail, cancellationToken);

        if (adminUser is null)
        {
            adminUser = new User
            {
                FullName = "Administrador",
                Email = normalizedEmail,
                Phone = null,
                PasswordHash = passwordHasher.Hash("Admin@1234"),
                Role = UserRole.Admin,
                IsActive = true
            };

            dbContext.Users.Add(adminUser);
        }

        if (!await dbContext.AdminUsers.AnyAsync(x => x.UserId == adminUser.Id, cancellationToken))
        {
            adminUser.Role = UserRole.Admin;
            adminUser.IsActive = true;

            var adminProfile = new AdminUser
            {
                User = adminUser,
                Notes = "Administrador inicial do sistema"
            };

            dbContext.AdminUsers.Add(adminProfile);
        }

        var settingsExist = await dbContext.StudioSettings.AnyAsync(cancellationToken);
        if (!settingsExist)
        {
            dbContext.StudioSettings.Add(StudioSettingsService.CreateDefault());
        }

        var businessHoursExist = await dbContext.BusinessHours.AnyAsync(cancellationToken);
        if (!businessHoursExist)
        {
            dbContext.BusinessHours.AddRange(AvailabilityService.CreateDefaultBusinessHours());
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
