using JhonnyHomeStudio.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Persistence.Configurations;

public static class JhonnyHomeStudioModelConfiguration
{
    public static void Configure(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(x => x.Email).IsUnique();
            entity.Property(x => x.Email).HasMaxLength(180).IsRequired();
            entity.Property(x => x.FullName).HasMaxLength(180).IsRequired();
            entity.Property(x => x.PasswordHash).HasMaxLength(500).IsRequired();
            entity.Property(x => x.Phone).HasMaxLength(30);
            entity.Property(x => x.Role).HasConversion<string>().HasMaxLength(30);
        });

        modelBuilder.Entity<Customer>(entity =>
        {
            entity.HasIndex(x => x.UserId).IsUnique();
            entity.HasOne(x => x.User)
                .WithOne()
                .HasForeignKey<Customer>(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.Property(x => x.DocumentNumber).HasMaxLength(30);
        });

        modelBuilder.Entity<AdminUser>(entity =>
        {
            entity.HasIndex(x => x.UserId).IsUnique();
            entity.HasOne(x => x.User)
                .WithOne()
                .HasForeignKey<AdminUser>(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.Property(x => x.Notes).HasMaxLength(500);
        });

        modelBuilder.Entity<Address>(entity =>
        {
            entity.HasOne(x => x.Customer)
                .WithMany(x => x.Addresses)
                .HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.Property(x => x.Street).HasMaxLength(220).IsRequired();
            entity.Property(x => x.Number).HasMaxLength(30).IsRequired();
            entity.Property(x => x.Neighborhood).HasMaxLength(120).IsRequired();
            entity.Property(x => x.City).HasMaxLength(120).IsRequired();
            entity.Property(x => x.State).HasMaxLength(60).IsRequired();
            entity.Property(x => x.ZipCode).HasMaxLength(20).IsRequired();
            entity.Property(x => x.Complement).HasMaxLength(120);
            entity.Property(x => x.ReferencePoint).HasMaxLength(200);
        });

        modelBuilder.Entity<ServiceCategory>(entity =>
        {
            entity.HasIndex(x => x.Name).IsUnique();
            entity.Property(x => x.Name).HasMaxLength(120).IsRequired();
            entity.Property(x => x.Description).HasMaxLength(400);
        });

        modelBuilder.Entity<Service>(entity =>
        {
            entity.HasOne(x => x.ServiceCategory)
                .WithMany(x => x.Services)
                .HasForeignKey(x => x.ServiceCategoryId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(x => x.Name).HasMaxLength(160).IsRequired();
            entity.Property(x => x.Description).HasMaxLength(1000).IsRequired();
            entity.Property(x => x.ImageUrl).HasMaxLength(500);
            entity.Property(x => x.Price).HasPrecision(18, 2);
        });

        modelBuilder.Entity<Appointment>(entity =>
        {
            entity.HasOne(x => x.Customer)
                .WithMany(x => x.Appointments)
                .HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.Service)
                .WithMany(x => x.Appointments)
                .HasForeignKey(x => x.ServiceId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.Address)
                .WithMany()
                .HasForeignKey(x => x.AddressId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(x => x.Status).HasConversion<string>().HasMaxLength(30);
            entity.Property(x => x.ServicePriceSnapshot).HasPrecision(18, 2);
            entity.Property(x => x.CustomerNotes).HasMaxLength(1000);
        });

        modelBuilder.Entity<AppointmentStatusHistory>(entity =>
        {
            entity.HasOne(x => x.Appointment)
                .WithMany(x => x.StatusHistory)
                .HasForeignKey(x => x.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(x => x.ChangedByUser)
                .WithMany()
                .HasForeignKey(x => x.ChangedByUserId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.Property(x => x.Status).HasConversion<string>().HasMaxLength(30);
            entity.Property(x => x.Note).HasMaxLength(500);
        });

        modelBuilder.Entity<Story>(entity =>
        {
            entity.HasOne(x => x.CreatedByAdminUser)
                .WithMany()
                .HasForeignKey(x => x.CreatedByAdminUserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.Service)
                .WithMany(x => x.Stories)
                .HasForeignKey(x => x.ServiceId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.Property(x => x.Title).HasMaxLength(160).IsRequired();
            entity.Property(x => x.ShortText).HasMaxLength(280).IsRequired();
            entity.Property(x => x.ImageUrl).HasMaxLength(500);
            entity.Property(x => x.ActionButtonText).HasMaxLength(80);
            entity.Property(x => x.ActionType).HasConversion<string>().HasMaxLength(30);
            entity.Property(x => x.ActionValue).HasMaxLength(600);
        });

        modelBuilder.Entity<StoryView>(entity =>
        {
            entity.HasIndex(x => new { x.StoryId, x.CustomerId }).IsUnique();

            entity.HasOne(x => x.Story)
                .WithMany(x => x.Views)
                .HasForeignKey(x => x.StoryId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(x => x.Customer)
                .WithMany(x => x.StoryViews)
                .HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<StudioSettings>(entity =>
        {
            entity.Property(x => x.StudioName).HasMaxLength(160).IsRequired();
            entity.Property(x => x.Subtitle).HasMaxLength(180).IsRequired();
            entity.Property(x => x.Slogan).HasMaxLength(280).IsRequired();
            entity.Property(x => x.LogoUrl).HasMaxLength(500);
            entity.Property(x => x.WhatsAppNumber).HasMaxLength(40);
            entity.Property(x => x.InstagramUrl).HasMaxLength(500);
            entity.Property(x => x.WelcomeTitle).HasMaxLength(180);
            entity.Property(x => x.WelcomeMessage).HasMaxLength(500);
            entity.Property(x => x.SupportMessage).HasMaxLength(500);
        });

        modelBuilder.Entity<BusinessHour>(entity =>
        {
            entity.HasIndex(x => x.DayOfWeek).IsUnique();
        });

        modelBuilder.Entity<BlockedDate>(entity =>
        {
            entity.HasIndex(x => x.Date);
            entity.Property(x => x.Reason).HasMaxLength(180).IsRequired();
        });

        modelBuilder.Entity<CustomerLoyalty>(entity =>
        {
            entity.HasIndex(x => x.CustomerId).IsUnique();
            entity.HasOne(x => x.Customer)
                .WithOne(x => x.Loyalty)
                .HasForeignKey<CustomerLoyalty>(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.Property(x => x.Level).HasConversion<string>().HasMaxLength(30);
        });

        modelBuilder.Entity<LoyaltyTransaction>(entity =>
        {
            entity.HasIndex(x => x.AppointmentId).IsUnique();
            entity.HasOne(x => x.Customer)
                .WithMany(x => x.LoyaltyTransactions)
                .HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(x => x.Appointment)
                .WithMany()
                .HasForeignKey(x => x.AppointmentId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(x => x.Description).HasMaxLength(220).IsRequired();
        });
    }
}
