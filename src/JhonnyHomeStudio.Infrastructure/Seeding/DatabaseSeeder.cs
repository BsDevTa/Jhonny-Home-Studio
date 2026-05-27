using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Domain.Enums;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace JhonnyHomeStudio.Infrastructure.Seeding;

public static class DatabaseSeeder
{
    public static async Task SeedInitialDataAsync(this IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<JhonnyHomeStudioDbContext>();
        var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();

        await dbContext.Database.MigrateAsync();

        var adminEmail = "admin@jhonnyhomestudio.com";
        var normalizedEmail = adminEmail.Trim().ToLowerInvariant();

        var adminExists = await dbContext.Users.AnyAsync(x => x.Email == normalizedEmail && x.Role == UserRole.Admin);
        if (adminExists)
        {
            return;
        }

        var user = new User
        {
            FullName = "Administrador",
            Email = normalizedEmail,
            Phone = null,
            PasswordHash = passwordHasher.Hash("Admin@123456"),
            Role = UserRole.Admin,
            IsActive = true
        };

        var adminUser = new AdminUser
        {
            User = user,
            Notes = "Administrador inicial do sistema"
        };

        dbContext.Users.Add(user);
        dbContext.AdminUsers.Add(adminUser);
        await dbContext.SaveChangesAsync();
    }
}