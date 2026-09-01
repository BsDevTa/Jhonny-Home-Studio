using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Settings;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Domain.Enums;
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
            Assert.Equal(60, businessHour.SlotIntervalMinutes);
        }
    }

    [Theory]
    [InlineData(DayOfWeek.Monday)]
    [InlineData(DayOfWeek.Tuesday)]
    [InlineData(DayOfWeek.Wednesday)]
    [InlineData(DayOfWeek.Thursday)]
    [InlineData(DayOfWeek.Friday)]
    [InlineData(DayOfWeek.Saturday)]
    public async Task GetAvailableSlotsAsync_ReturnsOnlyTwoShiftsFromMondayToSaturday(DayOfWeek dayOfWeek)
    {
        await using var dbContext = CreateDbContext();
        var serviceEntity = await SeedActiveServiceAsync(dbContext);
        var date = NextDate(dayOfWeek);
        SeedBusinessHour(dbContext, dayOfWeek, slotIntervalMinutes: 30);
        await dbContext.SaveChangesAsync();

        var appointmentService = CreateAppointmentService(dbContext);

        var slots = (await appointmentService.GetAvailableSlotsAsync(serviceEntity.Id, date)).ToList();

        AssertShift(slots[0], "Turno Matutino", date.AddHours(9), date.AddHours(12));
        AssertShift(slots[1], "Turno Vespertino", date.AddHours(13), date.AddHours(17));
        Assert.Equal(2, slots.Count);
    }

    [Fact]
    public async Task GetAvailableSlotsAsync_ReturnsNoSlotsOnSunday()
    {
        await using var dbContext = CreateDbContext();
        var serviceEntity = await SeedActiveServiceAsync(dbContext);
        var date = NextDate(DayOfWeek.Sunday);
        SeedBusinessHour(dbContext, DayOfWeek.Sunday, isOpen: false);
        await dbContext.SaveChangesAsync();

        var appointmentService = CreateAppointmentService(dbContext);

        var slots = await appointmentService.GetAvailableSlotsAsync(serviceEntity.Id, date);

        Assert.Empty(slots);
    }

    [Fact]
    public async Task GetAvailableSlotsAsync_HidesMorningShiftWhenMorningIsOccupied()
    {
        await using var dbContext = CreateDbContext();
        var serviceEntity = await SeedActiveServiceAsync(dbContext);
        var date = NextDate(DayOfWeek.Monday);
        SeedBusinessHour(dbContext, date.DayOfWeek);
        SeedAppointment(dbContext, serviceEntity, date.AddHours(9), 180);
        await dbContext.SaveChangesAsync();

        var appointmentService = CreateAppointmentService(dbContext);

        var slots = (await appointmentService.GetAvailableSlotsAsync(serviceEntity.Id, date)).ToList();

        var slot = Assert.Single(slots);
        AssertShift(slot, "Turno Vespertino", date.AddHours(13), date.AddHours(17));
    }

    [Fact]
    public async Task GetAvailableSlotsAsync_HidesAfternoonShiftWhenAfternoonIsOccupied()
    {
        await using var dbContext = CreateDbContext();
        var serviceEntity = await SeedActiveServiceAsync(dbContext);
        var date = NextDate(DayOfWeek.Monday);
        SeedBusinessHour(dbContext, date.DayOfWeek);
        SeedAppointment(dbContext, serviceEntity, date.AddHours(13), 240);
        await dbContext.SaveChangesAsync();

        var appointmentService = CreateAppointmentService(dbContext);

        var slots = (await appointmentService.GetAvailableSlotsAsync(serviceEntity.Id, date)).ToList();

        var slot = Assert.Single(slots);
        AssertShift(slot, "Turno Matutino", date.AddHours(9), date.AddHours(12));
    }

    [Fact]
    public async Task GetAvailableSlotsAsync_ReturnsNoSlotsWhenBothShiftsAreOccupied()
    {
        await using var dbContext = CreateDbContext();
        var serviceEntity = await SeedActiveServiceAsync(dbContext);
        var date = NextDate(DayOfWeek.Monday);
        SeedBusinessHour(dbContext, date.DayOfWeek);
        SeedAppointment(dbContext, serviceEntity, date.AddHours(9), 180);
        SeedAppointment(dbContext, serviceEntity, date.AddHours(13), 240);
        await dbContext.SaveChangesAsync();

        var appointmentService = CreateAppointmentService(dbContext);

        var slots = await appointmentService.GetAvailableSlotsAsync(serviceEntity.Id, date);

        Assert.Empty(slots);
    }

    [Fact]
    public async Task CreateMyAppointmentAsync_SavesSelectedMorningShiftAsFullBlock()
    {
        await using var dbContext = CreateDbContext();
        var serviceEntity = new StudioService
        {
            Name = "Escova",
            Price = 80,
            IsActive = true
        };
        var customer = SeedCustomerWithAddress(dbContext, out var address);
        var date = NextDate(DayOfWeek.Monday);

        dbContext.Services.Add(serviceEntity);
        SeedBusinessHour(dbContext, date.DayOfWeek);
        await dbContext.SaveChangesAsync();

        var appointmentService = CreateAppointmentService(dbContext);

        var response = await appointmentService.CreateMyAppointmentAsync(
            customer.UserId,
            new()
            {
                ServiceId = serviceEntity.Id,
                AddressId = address.Id,
                ScheduledAt = date.AddHours(9),
                ScheduledEndAt = date.AddHours(12)
            });

        var appointment = await dbContext.Appointments.FindAsync(response.Id);
        Assert.NotNull(appointment);
        Assert.Equal(180, appointment.EstimatedDurationMinutesSnapshot);
    }

    [Fact]
    public async Task CreateMyAppointmentAsync_RejectsIndividualHourlyStart()
    {
        await using var dbContext = CreateDbContext();
        var serviceEntity = new StudioService
        {
            Name = "Escova",
            Price = 80,
            IsActive = true
        };
        var customer = SeedCustomerWithAddress(dbContext, out var address);
        var date = NextDate(DayOfWeek.Monday);

        dbContext.Services.Add(serviceEntity);
        SeedBusinessHour(dbContext, date.DayOfWeek, slotIntervalMinutes: 30);
        await dbContext.SaveChangesAsync();

        var appointmentService = CreateAppointmentService(dbContext);

        var exception = await Assert.ThrowsAsync<ValidationAppException>(() =>
            appointmentService.CreateMyAppointmentAsync(
                customer.UserId,
                new()
                {
                    ServiceId = serviceEntity.Id,
                    AddressId = address.Id,
                    ScheduledAt = date.AddHours(10),
                    ScheduledEndAt = date.AddHours(11)
                }));

        Assert.Contains(exception.Errors, error => error.Contains("turnos disponíveis", StringComparison.OrdinalIgnoreCase));
    }

    private static void AssertShift(
        JhonnyHomeStudio.Application.Common.Dtos.Appointments.AvailableSlotResponse slot,
        string name,
        DateTime start,
        DateTime end)
    {
        Assert.Equal(name, slot.Name);
        Assert.Equal(start, slot.StartAt);
        Assert.Equal(end, slot.EndAt);
        Assert.True(slot.IsAvailable);
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

    private static void SeedAppointment(
        JhonnyHomeStudioDbContext dbContext,
        StudioService serviceEntity,
        DateTime start,
        int durationMinutes)
    {
        var customer = SeedCustomerWithAddress(dbContext, out var address);
        dbContext.Appointments.Add(new Appointment
        {
            Customer = customer,
            Service = serviceEntity,
            Address = address,
            ScheduledAtUtc = DateTime.SpecifyKind(start, DateTimeKind.Local).ToUniversalTime(),
            ServicePriceSnapshot = serviceEntity.Price,
            EstimatedDurationMinutesSnapshot = durationMinutes,
            Status = AppointmentStatus.Confirmed
        });
    }

    private static Customer SeedCustomerWithAddress(JhonnyHomeStudioDbContext dbContext, out Address address)
    {
        var user = new User
        {
            FullName = "Cliente",
            Email = $"cliente-{Guid.NewGuid():N}@example.com",
            PasswordHash = "hash",
            IsActive = true
        };
        var customer = new Customer
        {
            User = user
        };
        address = new Address
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

        dbContext.Users.Add(user);
        dbContext.Customers.Add(customer);
        dbContext.Addresses.Add(address);

        return customer;
    }

    private static void SeedBusinessHour(
        JhonnyHomeStudioDbContext dbContext,
        DayOfWeek dayOfWeek,
        bool isOpen = true,
        int slotIntervalMinutes = 60)
    {
        dbContext.BusinessHours.Add(new BusinessHour
        {
            DayOfWeek = (int)dayOfWeek,
            IsOpen = isOpen,
            StartTime = new TimeOnly(9, 0),
            EndTime = new TimeOnly(17, 0),
            SlotIntervalMinutes = slotIntervalMinutes
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
