using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence.Configurations;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Persistence;

public sealed class JhonnyHomeStudioDbContext : DbContext
{
    public JhonnyHomeStudioDbContext(DbContextOptions<JhonnyHomeStudioDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<AdminUser> AdminUsers => Set<AdminUser>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<ServiceCategory> ServiceCategories => Set<ServiceCategory>();
    public DbSet<Service> Services => Set<Service>();
    public DbSet<Appointment> Appointments => Set<Appointment>();
    public DbSet<AppointmentStatusHistory> AppointmentStatusHistory => Set<AppointmentStatusHistory>();
    public DbSet<Story> Stories => Set<Story>();
    public DbSet<StoryView> StoryViews => Set<StoryView>();
    public DbSet<StudioSettings> StudioSettings => Set<StudioSettings>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        JhonnyHomeStudioModelConfiguration.Configure(modelBuilder);
    }
}
