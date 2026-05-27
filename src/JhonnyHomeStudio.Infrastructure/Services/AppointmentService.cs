using JhonnyHomeStudio.Application.Common.Dtos.Appointments;
using JhonnyHomeStudio.Application.Common.Dtos.Customers;
using JhonnyHomeStudio.Application.Common.Dtos.Addresses;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Domain.Enums;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class AppointmentService : IAppointmentService
{
    private static readonly TimeSpan OpeningTime = TimeSpan.FromHours(8);
    private static readonly TimeSpan ClosingTime = TimeSpan.FromHours(18);
    private static readonly TimeSpan SlotStep = TimeSpan.FromMinutes(30);
    private static readonly HashSet<AppointmentStatus> BlockingStatuses = new()
    {
        AppointmentStatus.Pending,
        AppointmentStatus.WaitingPayment,
        AppointmentStatus.Confirmed,
        AppointmentStatus.OnTheWay,
        AppointmentStatus.InProgress,
        AppointmentStatus.Completed
    };

    private readonly JhonnyHomeStudioDbContext _dbContext;

    public AppointmentService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<AppointmentResponse> CreateMyAppointmentAsync(Guid userId, CreateAppointmentRequest request)
    {
        ValidateCreateRequest(request);

        var customer = await GetCustomerByUserIdAsync(userId);
        var service = await GetActiveServiceAsync(request.ServiceId);
        var address = await GetOwnedAddressAsync(customer.Id, request.AddressId);
        var scheduledLocal = NormalizeLocalDateTime(request.ScheduledAt);

        ValidateScheduledDate(scheduledLocal, service.EstimatedDurationMinutes);

        var scheduledStartUtc = ToUtc(scheduledLocal);
        var scheduledEndUtc = ToUtc(scheduledLocal.AddMinutes(service.EstimatedDurationMinutes));

        await EnsureNoConflictAsync(scheduledLocal, scheduledStartUtc, scheduledEndUtc);

        var appointment = new Appointment
        {
            CustomerId = customer.Id,
            ServiceId = service.Id,
            AddressId = address.Id,
            ScheduledAtUtc = scheduledStartUtc,
            ServicePriceSnapshot = service.Price,
            EstimatedDurationMinutesSnapshot = service.EstimatedDurationMinutes,
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
                ServiceName = x.Service.Name,
                ScheduledAt = x.ScheduledAtUtc,
                Status = x.Status.ToString(),
                ServicePriceSnapshot = x.ServicePriceSnapshot,
                EstimatedDurationMinutesSnapshot = x.EstimatedDurationMinutesSnapshot
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
                ServiceName = x.Service.Name,
                ScheduledAt = x.ScheduledAtUtc,
                Status = x.Status.ToString(),
                ServicePriceSnapshot = x.ServicePriceSnapshot,
                EstimatedDurationMinutesSnapshot = x.EstimatedDurationMinutesSnapshot
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

        await _dbContext.SaveChangesAsync();
        return await BuildAppointmentResponseAsync(appointment.Id);
    }

    public async Task<IEnumerable<AvailableSlotResponse>> GetAvailableSlotsAsync(Guid serviceId, DateTime date)
    {
        var service = await GetActiveServiceAsync(serviceId);
        var localDate = date.Date;

        if (localDate < DateTime.Now.Date)
        {
            throw new ValidationAppException("Data inválida.", new[] { "Não é possível consultar disponibilidade para datas passadas." });
        }

        var slots = new List<AvailableSlotResponse>();
        var start = localDate.Add(OpeningTime);
        var latestStart = localDate.Add(ClosingTime).AddMinutes(-service.EstimatedDurationMinutes);

        if (localDate.DayOfWeek == DayOfWeek.Sunday)
        {
            return slots;
        }

        var existingAppointments = await GetBlockingAppointmentsInUtcRangeAsync(localDate);

        for (var slotStart = start; slotStart <= latestStart; slotStart = slotStart.Add(SlotStep))
        {
            var slotEnd = slotStart.AddMinutes(service.EstimatedDurationMinutes);
            var slotStartUtc = ToUtc(slotStart);
            var slotEndUtc = ToUtc(slotEnd);
            var blockedByStatus = existingAppointments.Any(x => IsBlockingStatus(x.Status) && Overlaps(slotStartUtc, slotEndUtc, x.ScheduledAtUtc, x.ScheduledAtUtc.AddMinutes(x.EstimatedDurationMinutesSnapshot)));
            var isAvailable = slotStart >= DateTime.Now && !blockedByStatus;

            slots.Add(new AvailableSlotResponse
            {
                StartAt = slotStart,
                EndAt = slotEnd,
                IsAvailable = isAvailable
            });
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
            .Include(x => x.ServiceCategory)
            .FirstOrDefaultAsync(x => x.Id == serviceId);

        if (service is null)
        {
            throw new ValidationAppException("Serviço inválido.", new[] { "O serviço informado não existe." });
        }

        if (!service.IsActive || !service.ServiceCategory.IsActive)
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
        if (string.IsNullOrWhiteSpace(request.Status))
        {
            throw new ValidationAppException("Status obrigatório.", new[] { "O status do agendamento é obrigatório." });
        }
    }

    private static void ValidateScheduledDate(DateTime scheduledLocal, int serviceDurationMinutes)
    {
        var nowLocal = DateTime.Now;

        if (scheduledLocal < nowLocal)
        {
            throw new ValidationAppException("Data inválida.", new[] { "A data e hora do agendamento não podem estar no passado." });
        }

        if (scheduledLocal.DayOfWeek == DayOfWeek.Sunday)
        {
            throw new ValidationAppException("Horário indisponível.", new[] { "Domingo está fechado para agendamentos." });
        }

        var slotStart = scheduledLocal.TimeOfDay;
        var slotEnd = scheduledLocal.AddMinutes(serviceDurationMinutes).TimeOfDay;

        if (slotStart < OpeningTime || slotStart > ClosingTime)
        {
            throw new ValidationAppException("Horário indisponível.", new[] { "O horário informado está fora do horário comercial." });
        }

        if (slotEnd > ClosingTime)
        {
            throw new ValidationAppException("Horário indisponível.", new[] { "O serviço informado termina após o horário comercial." });
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

    private static System.Linq.Expressions.Expression<Func<Appointment, AppointmentResponse>> ToResponseProjection()
    {
        return x => new AppointmentResponse
        {
            Id = x.Id,
            CustomerId = x.CustomerId,
            CustomerName = x.Customer.User.FullName,
            ServiceId = x.ServiceId,
            ServiceName = x.Service.Name,
            AddressId = x.AddressId,
            AddressText = x.Address.Street + ", " + x.Address.Number + " - " + x.Address.Neighborhood + ", " + x.Address.City + "/" + x.Address.State + ", CEP " + x.Address.ZipCode,
            ScheduledAt = x.ScheduledAtUtc,
            ServicePriceSnapshot = x.ServicePriceSnapshot,
            EstimatedDurationMinutesSnapshot = x.EstimatedDurationMinutesSnapshot,
            Status = x.Status.ToString(),
            CustomerNotes = x.CustomerNotes,
            CreatedAt = x.CreatedAt,
            UpdatedAt = x.UpdatedAt
        };
    }
}