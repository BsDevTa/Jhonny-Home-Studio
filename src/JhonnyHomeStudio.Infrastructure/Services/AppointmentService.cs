using JhonnyHomeStudio.Application.Common.Dtos.Appointments;
using JhonnyHomeStudio.Application.Common.Dtos.Customers;
using JhonnyHomeStudio.Application.Common.Dtos.Addresses;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Application.Common.Settings;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Domain.Enums;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class AppointmentService : IAppointmentService
{
    private static readonly HashSet<AppointmentStatus> BlockingStatuses = new()
    {
        AppointmentStatus.Pending,
        AppointmentStatus.WaitingPayment,
        AppointmentStatus.Confirmed,
        AppointmentStatus.Rescheduled,
        AppointmentStatus.OnTheWay,
        AppointmentStatus.InProgress
    };

    private static readonly IReadOnlyCollection<(TimeOnly Start, TimeOnly End)> AppointmentWindows = new[]
    {
        (new TimeOnly(9, 0), new TimeOnly(12, 0)),
        (new TimeOnly(13, 0), new TimeOnly(17, 0))
    };

    private readonly JhonnyHomeStudioDbContext _dbContext;
    private readonly ILoyaltyService _loyaltyService;
    private readonly AppointmentSchedulingSettings _schedulingSettings;

    public AppointmentService(
        JhonnyHomeStudioDbContext dbContext,
        ILoyaltyService loyaltyService,
        AppointmentSchedulingSettings schedulingSettings)
    {
        _dbContext = dbContext;
        _loyaltyService = loyaltyService;
        _schedulingSettings = schedulingSettings;
    }

    public async Task<AppointmentResponse> CreateMyAppointmentAsync(Guid userId, CreateAppointmentRequest request)
    {
        ValidateCreateRequest(request);

        var customer = await GetCustomerByUserIdAsync(userId);
        var service = await GetActiveServiceAsync(request.ServiceId);
        var address = await GetOwnedAddressAsync(customer.Id, request.AddressId);
        var scheduledLocal = NormalizeLocalDateTime(request.ScheduledAt);
        var appointmentDurationMinutes = GetDefaultAppointmentDurationMinutes();

        await ValidateScheduledAvailabilityAsync(scheduledLocal, appointmentDurationMinutes);

        var scheduledStartUtc = ToUtc(scheduledLocal);
        var scheduledEndUtc = ToUtc(scheduledLocal.AddMinutes(appointmentDurationMinutes));

        await EnsureNoConflictAsync(scheduledLocal, scheduledStartUtc, scheduledEndUtc);

        var appointment = new Appointment
        {
            CustomerId = customer.Id,
            ServiceId = service.Id,
            AddressId = address.Id,
            ScheduledAtUtc = scheduledStartUtc,
            ServicePriceSnapshot = service.Price,
            EstimatedDurationMinutesSnapshot = appointmentDurationMinutes,
            Status = AppointmentStatus.Pending,
            CustomerNotes = string.IsNullOrWhiteSpace(request.CustomerNotes) ? null : request.CustomerNotes.Trim()
        };

        var statusHistory = new AppointmentStatusHistory
        {
            AppointmentId = appointment.Id,
            Status = AppointmentStatus.Pending,
            ChangedByUserId = userId,
            Note = "Agendamento criado pelo cliente.",
            ChangedAtUtc = DateTime.UtcNow
        };

        _dbContext.Appointments.Add(appointment);
        _dbContext.AppointmentStatusHistory.Add(statusHistory);
        await _dbContext.SaveChangesAsync();

        return await BuildAppointmentResponseAsync(appointment.Id);
    }

    public async Task<IEnumerable<AppointmentListResponse>> GetMyAppointmentsAsync(Guid userId)
    {
        var customer = await GetCustomerByUserIdAsync(userId);

        return await _dbContext.Appointments
            .AsNoTracking()
            .Include(x => x.Customer)
            .ThenInclude(x => x.User)
            .Include(x => x.Service)
            .Where(x => x.CustomerId == customer.Id)
            .OrderByDescending(x => x.ScheduledAtUtc)
            .Select(x => new AppointmentListResponse
            {
                Id = x.Id,
                CustomerName = x.Customer.User.FullName,
                CustomerPhone = x.Customer.User.Phone,
                ServiceName = x.Service.Name,
                ScheduledAt = x.ScheduledAtUtc,
                Status = x.Status.ToString(),
                ServicePriceSnapshot = x.ServicePriceSnapshot
            })
            .ToListAsync();
    }

    public async Task<AppointmentResponse?> GetMyAppointmentByIdAsync(Guid userId, Guid appointmentId)
    {
        var customer = await GetCustomerByUserIdAsync(userId);
        return await BuildAppointmentQuery()
            .Where(x => x.CustomerId == customer.Id && x.Id == appointmentId)
            .Select(ToResponseProjection())
            .FirstOrDefaultAsync();
    }

    public async Task<bool> CancelMyAppointmentAsync(Guid userId, Guid appointmentId)
    {
        var customer = await GetCustomerByUserIdAsync(userId);
        var appointment = await _dbContext.Appointments
            .FirstOrDefaultAsync(x => x.Id == appointmentId && x.CustomerId == customer.Id);

        if (appointment is null)
        {
            return false;
        }

        if (appointment.Status == AppointmentStatus.Completed)
        {
            throw new ValidationAppException("Não foi possível cancelar o agendamento.", new[] { "Agendamentos concluídos não podem ser cancelados." });
        }

        if (appointment.Status == AppointmentStatus.Canceled)
        {
            throw new ValidationAppException("Não foi possível cancelar o agendamento.", new[] { "O agendamento já está cancelado." });
        }

        appointment.Status = AppointmentStatus.Canceled;
        appointment.UpdatedAt = DateTime.UtcNow;

        _dbContext.AppointmentStatusHistory.Add(new AppointmentStatusHistory
        {
            AppointmentId = appointment.Id,
            Status = AppointmentStatus.Canceled,
            ChangedByUserId = userId,
            Note = "Agendamento cancelado pelo cliente.",
            ChangedAtUtc = DateTime.UtcNow
        });

        await _dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<AppointmentListResponse>> GetAllForAdminAsync(DateTime? date = null, Guid? customerId = null, Guid? serviceId = null)
    {
        var query = _dbContext.Appointments
            .AsNoTracking()
            .Include(x => x.Customer)
            .ThenInclude(x => x.User)
            .Include(x => x.Service)
            .AsQueryable();

        if (date.HasValue)
        {
            var (startUtc, endUtc) = GetUtcDayRange(date.Value.Date);
            query = query.Where(x => x.ScheduledAtUtc >= startUtc && x.ScheduledAtUtc < endUtc);
        }

        if (customerId.HasValue)
        {
            query = query.Where(x => x.CustomerId == customerId.Value);
        }

        if (serviceId.HasValue)
        {
            query = query.Where(x => x.ServiceId == serviceId.Value);
        }

        return await query
            .OrderByDescending(x => x.ScheduledAtUtc)
            .Select(x => new AppointmentListResponse
            {
                Id = x.Id,
                CustomerName = x.Customer.User.FullName,
                CustomerPhone = x.Customer.User.Phone,
                ServiceName = x.Service.Name,
                ScheduledAt = x.ScheduledAtUtc,
                Status = x.Status.ToString(),
                ServicePriceSnapshot = x.ServicePriceSnapshot
            })
            .ToListAsync();
    }

    public async Task<AppointmentResponse?> GetByIdForAdminAsync(Guid appointmentId)
    {
        return await BuildAppointmentQuery()
            .Where(x => x.Id == appointmentId)
            .Select(ToResponseProjection())
            .FirstOrDefaultAsync();
    }

    public async Task<AppointmentResponse> UpdateStatusForAdminAsync(Guid adminUserId, Guid appointmentId, UpdateAppointmentStatusRequest request)
    {
        ValidateUpdateStatusRequest(request);

        if (!Enum.TryParse<AppointmentStatus>(request.Status, ignoreCase: true, out var status))
        {
            throw new ValidationAppException("Status inválido.", new[] { "O status informado não existe no enum AppointmentStatus." });
        }

        var appointment = await _dbContext.Appointments
            .FirstOrDefaultAsync(x => x.Id == appointmentId)
            ?? throw new ValidationAppException("Agendamento não encontrado.", new[] { "Verifique o identificador informado." });

        appointment.Status = status;
        appointment.UpdatedAt = DateTime.UtcNow;

        _dbContext.AppointmentStatusHistory.Add(new AppointmentStatusHistory
        {
            AppointmentId = appointment.Id,
            Status = status,
            ChangedByUserId = adminUserId,
            Note = request.Note?.Trim(),
            ChangedAtUtc = DateTime.UtcNow
        });

        if (status == AppointmentStatus.Completed)
        {
            await _loyaltyService.AwardForCompletedAppointmentAsync(
                appointment.CustomerId,
                appointment.Id,
                appointment.ServicePriceSnapshot);
        }

        await _dbContext.SaveChangesAsync();
        return await BuildAppointmentResponseAsync(appointment.Id);
    }

    public async Task<IEnumerable<AvailableSlotResponse>> GetAvailableSlotsAsync(Guid serviceId, DateTime date)
    {
        await GetActiveServiceAsync(serviceId);
        var localDate = date.Date;

        if (localDate < DateTime.Now.Date)
        {
            throw new ValidationAppException("Data inválida.", new[] { "Não é possível consultar disponibilidade para datas passadas." });
        }

        var slots = new List<AvailableSlotResponse>();
        var businessHour = await GetBusinessHourAsync(localDate);
        if (businessHour is null || !businessHour.IsOpen || !IsSchedulingDay(localDate.DayOfWeek))
        {
            return slots;
        }

        var blockedDates = await GetBlockedDatesAsync(localDate);
        if (blockedDates.Any(x => x.IsFullDay))
        {
            return slots;
        }

        var appointmentDurationMinutes = GetDefaultAppointmentDurationMinutes();
        var slotStep = TimeSpan.FromMinutes(businessHour.SlotIntervalMinutes);
        var existingAppointments = await GetBlockingAppointmentsInUtcRangeAsync(localDate);

        foreach (var window in GetAppointmentWindows(localDate, businessHour))
        {
            var latestStart = window.End.AddMinutes(-appointmentDurationMinutes);

            for (var slotStart = window.Start; slotStart <= latestStart; slotStart = slotStart.Add(slotStep))
            {
                var slotEnd = slotStart.AddMinutes(appointmentDurationMinutes);
                var slotStartUtc = ToUtc(slotStart);
                var slotEndUtc = ToUtc(slotEnd);
                var blockedByStatus = existingAppointments.Any(x => IsBlockingStatus(x.Status) && Overlaps(slotStartUtc, slotEndUtc, x.ScheduledAtUtc, x.ScheduledAtUtc.AddMinutes(x.EstimatedDurationMinutesSnapshot)));
                var blockedByDate = IsBlockedByDate(slotStart, slotEnd, blockedDates);

                if (slotStart < DateTime.Now || blockedByStatus || blockedByDate)
                {
                    continue;
                }

                slots.Add(new AvailableSlotResponse
                {
                    StartAt = slotStart,
                    EndAt = slotEnd,
                    IsAvailable = true
                });
            }
        }

        return slots;
    }

    private async Task<AppointmentResponse> BuildAppointmentResponseAsync(Guid appointmentId)
    {
        var response = await BuildAppointmentQuery()
            .Where(x => x.Id == appointmentId)
            .Select(ToResponseProjection())
            .FirstOrDefaultAsync();

        return response ?? throw new ValidationAppException("Agendamento não encontrado.", new[] { "Verifique o identificador informado." });
    }

    private IQueryable<Appointment> BuildAppointmentQuery()
    {
        return _dbContext.Appointments
            .AsNoTracking()
            .Include(x => x.Customer)
            .ThenInclude(x => x.User)
            .Include(x => x.Service)
            .Include(x => x.Address);
    }

    private async Task<Customer> GetCustomerByUserIdAsync(Guid userId)
    {
        var customer = await _dbContext.Customers
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == userId);

        if (customer is null)
        {
            throw new ValidationAppException("Cliente não encontrado.", new[] { "Não foi possível localizar o cliente vinculado ao usuário autenticado." });
        }

        if (!customer.User.IsActive)
        {
            throw new ForbiddenAppException("Usuário inativo.", new[] { "Seu acesso está bloqueado. Entre em contato com o suporte." });
        }

        return customer;
    }

    private async Task<Service> GetActiveServiceAsync(Guid serviceId)
    {
        var service = await _dbContext.Services
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == serviceId);

        if (service is null)
        {
            throw new ValidationAppException("Serviço inválido.", new[] { "O serviço informado não existe." });
        }

        if (!service.IsActive)
        {
            throw new ValidationAppException("Serviço indisponível.", new[] { "O serviço informado está inativo." });
        }

        return service;
    }

    private async Task<Address> GetOwnedAddressAsync(Guid customerId, Guid addressId)
    {
        var address = await _dbContext.Addresses
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == addressId && x.CustomerId == customerId);

        if (address is null)
        {
            throw new ValidationAppException("Endereço inválido.", new[] { "O endereço informado não pertence ao cliente logado." });
        }

        return address;
    }

    private static void ValidateCreateRequest(CreateAppointmentRequest request)
    {
        var errors = new List<string>();

        if (request.ServiceId == Guid.Empty)
        {
            errors.Add("ServiceId é obrigatório.");
        }

        if (request.AddressId == Guid.Empty)
        {
            errors.Add("AddressId é obrigatório.");
        }

        if (request.ScheduledAt == default)
        {
            errors.Add("ScheduledAt é obrigatório.");
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Não foi possível criar o agendamento.", errors);
        }
    }

    private static void ValidateUpdateStatusRequest(UpdateAppointmentStatusRequest request)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(request.Status))
        {
            errors.Add("O status do agendamento é obrigatório.");
        }

        if (request.Note?.Trim().Length > 500)
        {
            errors.Add("A nota administrativa deve ter no máximo 500 caracteres.");
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Não foi possível atualizar o status.", errors);
        }
    }

    private async Task ValidateScheduledAvailabilityAsync(DateTime scheduledLocal, int serviceDurationMinutes)
    {
        var nowLocal = DateTime.Now;

        if (scheduledLocal < nowLocal)
        {
            throw new ValidationAppException("Data inválida.", new[] { "A data e hora do agendamento não podem estar no passado." });
        }

        var businessHour = await GetBusinessHourAsync(scheduledLocal.Date);
        if (businessHour is null || !businessHour.IsOpen || !IsSchedulingDay(scheduledLocal.DayOfWeek))
        {
            throw new ValidationAppException("Horário indisponível.", new[] { "Não há atendimento disponível nesta data." });
        }

        var scheduledEnd = scheduledLocal.AddMinutes(serviceDurationMinutes);
        var appointmentWindow = GetAppointmentWindows(scheduledLocal.Date, businessHour)
            .FirstOrDefault(window => scheduledLocal >= window.Start && scheduledEnd <= window.End);

        if (appointmentWindow == default)
        {
            throw new ValidationAppException("Horário indisponível.", new[] { "O horário informado está fora dos turnos de atendimento." });
        }

        if ((scheduledLocal - appointmentWindow.Start).Ticks % TimeSpan.FromMinutes(businessHour.SlotIntervalMinutes).Ticks != 0)
        {
            throw new ValidationAppException("Horário indisponível.", new[] { "Selecione um dos horários disponíveis para atendimento." });
        }

        var blockedDates = await GetBlockedDatesAsync(scheduledLocal.Date);
        if (IsBlockedByDate(scheduledLocal, scheduledEnd, blockedDates))
        {
            throw new ValidationAppException("Horário indisponível.", new[] { "Este período está bloqueado para atendimento." });
        }
    }

    private async Task EnsureNoConflictAsync(DateTime scheduledLocal, DateTime newStartUtc, DateTime newEndUtc)
    {
        var appointments = await GetBlockingAppointmentsInUtcRangeAsync(scheduledLocal.Date);

        if (appointments.Any(existing => Overlaps(newStartUtc, newEndUtc, existing.ScheduledAtUtc, existing.ScheduledAtUtc.AddMinutes(existing.EstimatedDurationMinutesSnapshot))))
        {
            throw new ValidationAppException("Horário indisponível.", new[] { "Já existe um agendamento reservado para este período." });
        }
    }

    private async Task<List<Appointment>> GetBlockingAppointmentsInUtcRangeAsync(DateTime localDate)
    {
        var (startUtc, endUtc) = GetUtcDayRange(localDate);

        var appointments = await _dbContext.Appointments
            .AsNoTracking()
            .Where(x => x.ScheduledAtUtc >= startUtc && x.ScheduledAtUtc < endUtc)
            .ToListAsync();

        // Futuramente, aqui é o ponto ideal para consultar bloqueios externos, como Google Calendar.
        return appointments.Where(x => IsBlockingStatus(x.Status)).ToList();
    }

    private async Task<BusinessHour?> GetBusinessHourAsync(DateTime localDate)
    {
        return await _dbContext.BusinessHours
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.DayOfWeek == (int)localDate.DayOfWeek);
    }

    private async Task<List<BlockedDate>> GetBlockedDatesAsync(DateTime localDate)
    {
        var date = DateOnly.FromDateTime(localDate);
        return await _dbContext.BlockedDates
            .AsNoTracking()
            .Where(x => x.Date == date)
            .ToListAsync();
    }

    private static bool IsBlockedByDate(DateTime slotStart, DateTime slotEnd, IEnumerable<BlockedDate> blockedDates)
    {
        foreach (var blockedDate in blockedDates)
        {
            if (blockedDate.IsFullDay)
            {
                return true;
            }

            if (blockedDate.StartTime is null || blockedDate.EndTime is null)
            {
                continue;
            }

            var blockedStart = slotStart.Date.Add(blockedDate.StartTime.Value.ToTimeSpan());
            var blockedEnd = slotStart.Date.Add(blockedDate.EndTime.Value.ToTimeSpan());
            if (Overlaps(slotStart, slotEnd, blockedStart, blockedEnd))
            {
                return true;
            }
        }

        return false;
    }

    private static IEnumerable<(DateTime Start, DateTime End)> GetAppointmentWindows(
        DateTime localDate,
        BusinessHour businessHour)
    {
        foreach (var appointmentWindow in AppointmentWindows)
        {
            var start = Max(businessHour.StartTime, appointmentWindow.Start);
            var end = Min(businessHour.EndTime, appointmentWindow.End);

            if (start >= end)
            {
                continue;
            }

            yield return (localDate.Add(start.ToTimeSpan()), localDate.Add(end.ToTimeSpan()));
        }
    }

    private static bool IsSchedulingDay(DayOfWeek dayOfWeek)
    {
        return dayOfWeek is >= DayOfWeek.Monday and <= DayOfWeek.Saturday;
    }

    private static TimeOnly Max(TimeOnly left, TimeOnly right)
    {
        return left > right ? left : right;
    }

    private static TimeOnly Min(TimeOnly left, TimeOnly right)
    {
        return left < right ? left : right;
    }

    private static bool IsBlockingStatus(AppointmentStatus status)
    {
        return BlockingStatuses.Contains(status);
    }

    private static bool Overlaps(DateTime newStart, DateTime newEnd, DateTime existingStart, DateTime existingEnd)
    {
        return newStart < existingEnd && newEnd > existingStart;
    }

    private static DateTime NormalizeLocalDateTime(DateTime value)
    {
        return DateTime.SpecifyKind(value, DateTimeKind.Unspecified);
    }

    private static DateTime ToUtc(DateTime localDateTime)
    {
        return DateTime.SpecifyKind(localDateTime, DateTimeKind.Local).ToUniversalTime();
    }

    private static (DateTime StartUtc, DateTime EndUtc) GetUtcDayRange(DateTime localDate)
    {
        var startLocal = DateTime.SpecifyKind(localDate.Date, DateTimeKind.Local);
        var endLocal = startLocal.AddDays(1);
        return (startLocal.ToUniversalTime(), endLocal.ToUniversalTime());
    }

    private int GetDefaultAppointmentDurationMinutes()
    {
        return _schedulingSettings.DefaultDurationMinutes > 0
            ? _schedulingSettings.DefaultDurationMinutes
            : 60;
    }

    private static System.Linq.Expressions.Expression<Func<Appointment, AppointmentResponse>> ToResponseProjection()
    {
        return x => new AppointmentResponse
        {
            Id = x.Id,
            CustomerId = x.CustomerId,
            CustomerName = x.Customer.User.FullName,
            CustomerPhone = x.Customer.User.Phone,
            ServiceId = x.ServiceId,
            ServiceName = x.Service.Name,
            AddressId = x.AddressId,
            AddressText = x.Address.Street + ", " + x.Address.Number + " - " + x.Address.Neighborhood + ", " + x.Address.City + "/" + x.Address.State + ", CEP " + x.Address.ZipCode,
            ScheduledAt = x.ScheduledAtUtc,
            ServicePriceSnapshot = x.ServicePriceSnapshot,
            Status = x.Status.ToString(),
            CustomerNotes = x.CustomerNotes,
            CreatedAt = x.CreatedAt,
            UpdatedAt = x.UpdatedAt
        };
    }
}
