using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Settings;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using JhonnyHomeStudio.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Xunit;

using StudioService = JhonnyHomeStudio.Domain.Entities.Service;

namespace JhonnyHomeStudio.Tests.Appointments;

public sealed class AppointmentServiceAvailabilityTests
{
    [Fact]
    public void DefaultBusinessHours_OpenMondayThroughSaturdayFromNineToSeventeen()
    {
        var hours = AvailabilityService.CreateDefaultBusinessHours()
            .OrderBy(x => x.DayOfWeek)
            .ToList();

        Assert.Equal(7, hours.Count);

        foreach (var businessHour in hours)
        {
            Assert.Equal(new TimeOnly(9, 0), businessHour.StartTime);
            Assert.Equal(new TimeOnly(17, 0), businessHour.EndTime);
            Assert.Equal(businessHour.DayOfWeek != (int)DayOfWeek.Sunday, businessHour.IsOpen);
        }
    }

    [Fact]
    public async Task GetAvailableSlotsAsync_UsesMorningAndAfternoonShiftsWithoutLunchSlots()
    {
        await using var dbContext = CreateDbContext();
        var serviceEntity = await SeedActiveServiceAsync(dbContext);
        var date = NextDate(DayOfWeek.Monday);
        SeedBusinessHour(dbContext, date.DayOfWeek);
        await dbContext.SaveChangesAsync();

        var appointmentService = CreateAppointmentService(dbContext);

        var slots = (await appointmentService.GetAvailableSlotsAsync(serviceEntity.Id, date)).ToList();
        var startTimes = slots.Select(x => TimeOnly.FromDateTime(x.StartAt)).ToList();

        Assert.Contains(new TimeOnly(9, 0), startTimes);
        Assert.Contains(new TimeOnly(11, 0), startTimes);
        Assert.DoesNotContain(new TimeOnly(12, 0), startTimes);
        Assert.DoesNotContain(new TimeOnly(12, 30), startTimes);
        Assert.Contains(new TimeOnly(13, 0), startTimes);
        Assert.Contains(new TimeOnly(16, 0), startTimes);
        Assert.All(slots, slot =>
            Assert.False(slot.StartAt.TimeOfDay < TimeSpan.FromHours(13) && slot.EndAt.TimeOfDay > TimeSpan.FromHours(12)));
    }

    [Fact]
    public async Task CreateMyAppointmentAsync_RejectsAppointmentDuringLunchBreak()
    {
        await using var dbContext = CreateDbContext();
        var user = new User
        {
            FullName = "Cliente",
            Email = "cliente@example.com",
            PasswordHash = "hash",
            IsActive = true
        };
        var customer = new Customer
        {
            User = user
        };
        var address = new Address
        {
            Customer = customer,
            Street = "Rua A",
            Number = "123",
            Neighborhood = "Centro",
            City = "Salvador",
            State = "BA",
            ZipCode = "40000000",
            IsDefault = true
        };
        var serviceEntity = new StudioService
        {
            Name = "Escova",
            Price = 80,
            IsActive = true
        };
        var date = NextDate(DayOfWeek.Monday);

        dbContext.Users.Add(user);
        dbContext.Customers.Add(customer);
        dbContext.Addresses.Add(address);
        dbContext.Services.Add(serviceEntity);
        SeedBusinessHour(dbContext, date.DayOfWeek);
        await dbContext.SaveChangesAsync();

        var appointmentService = CreateAppointmentService(dbContext);

        var exception = await Assert.ThrowsAsync<ValidationAppException>(() =>
            appointmentService.CreateMyAppointmentAsync(
                user.Id,
                new()
                {
                    ServiceId = serviceEntity.Id,
                    AddressId = address.Id,
                    ScheduledAt = date.AddHours(12)
                }));

        Assert.Contains(exception.Errors, error => error.Contains("turnos de atendimento", StringComparison.OrdinalIgnoreCase));
    }

    private static AppointmentService CreateAppointmentService(JhonnyHomeStudioDbContext dbContext)
    {
        return new AppointmentService(
            dbContext,
            new LoyaltyService(dbContext),
            new AppointmentSchedulingSettings
            {
                DefaultDurationMinutes = 60
            });
    }

    private static async Task<StudioService> SeedActiveServiceAsync(JhonnyHomeStudioDbContext dbContext)
    {
        var serviceEntity = new StudioService
        {
            Name = "Corte",
            Price = 120,
            IsActive = true
        };

        dbContext.Services.Add(serviceEntity);
        await dbContext.SaveChangesAsync();

        return serviceEntity;
    }

    private static void SeedBusinessHour(JhonnyHomeStudioDbContext dbContext, DayOfWeek dayOfWeek)
    {
        dbContext.BusinessHours.Add(new BusinessHour
        {
            DayOfWeek = (int)dayOfWeek,
            IsOpen = true,
            StartTime = new TimeOnly(9, 0),
            EndTime = new TimeOnly(17, 0),
            SlotIntervalMinutes = 30
        });
    }

    private static DateTime NextDate(DayOfWeek dayOfWeek)
    {
        var date = DateTime.Today.AddDays(1);

        while (date.DayOfWeek != dayOfWeek)
        {
            date = date.AddDays(1);
        }

        return date;
    }

    private static JhonnyHomeStudioDbContext CreateDbContext()
    {
        var options = new DbContextOptionsBuilder<JhonnyHomeStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new JhonnyHomeStudioDbContext(options);
    }
}
