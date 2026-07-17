using System.Globalization;
using JhonnyHomeStudio.Application.Common.Dtos.Availability;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class AvailabilityService : IAvailabilityService
{
    private static readonly string[] DayNames =
    {
        "Domingo",
        "Segunda-feira",
        "Terça-feira",
        "Quarta-feira",
        "Quinta-feira",
        "Sexta-feira",
        "Sábado"
    };

    private readonly JhonnyHomeStudioDbContext _dbContext;

    public AvailabilityService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IEnumerable<BusinessHourResponse>> GetBusinessHoursAsync()
    {
        await EnsureDefaultBusinessHoursAsync();

        var businessHours = await _dbContext.BusinessHours
            .AsNoTracking()
            .OrderBy(x => x.DayOfWeek)
            .ToListAsync();

        return businessHours.Select(ToBusinessHourResponse);
    }

    public async Task<IEnumerable<BusinessHourResponse>> UpdateBusinessHoursAsync(IEnumerable<UpdateBusinessHourRequest> requests)
    {
        var items = requests.ToList();
        ValidateBusinessHours(items);
        await EnsureDefaultBusinessHoursAsync();

        var existing = await _dbContext.BusinessHours.ToDictionaryAsync(x => x.DayOfWeek);

        foreach (var request in items)
        {
            var businessHour = existing[request.DayOfWeek];
            businessHour.IsOpen = request.IsOpen;
            businessHour.StartTime = ParseTimeOrDefault(request.StartTime, businessHour.StartTime);
            businessHour.EndTime = ParseTimeOrDefault(request.EndTime, businessHour.EndTime);
            businessHour.SlotIntervalMinutes = request.SlotIntervalMinutes;
            businessHour.UpdatedAt = DateTime.UtcNow;
        }

        await _dbContext.SaveChangesAsync();
        return await GetBusinessHoursAsync();
    }

    public async Task<IEnumerable<BlockedDateResponse>> GetBlockedDatesAsync()
    {
        var blockedDates = await _dbContext.BlockedDates
            .AsNoTracking()
            .OrderBy(x => x.Date)
            .ThenBy(x => x.StartTime)
            .ToListAsync();

        return blockedDates.Select(ToBlockedDateResponse);
    }

    public async Task<BlockedDateResponse?> GetBlockedDateByIdAsync(Guid blockedDateId)
    {
        var blockedDate = await _dbContext.BlockedDates
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == blockedDateId);

        return blockedDate is null ? null : ToBlockedDateResponse(blockedDate);
    }

    public async Task<BlockedDateResponse> CreateBlockedDateAsync(UpsertBlockedDateRequest request)
    {
        var (startTime, endTime) = ValidateBlockedDate(request);
        var blockedDate = new BlockedDate
        {
            Date = request.Date,
            Reason = request.Reason.Trim(),
            IsFullDay = request.IsFullDay,
            StartTime = startTime,
            EndTime = endTime
        };

        _dbContext.BlockedDates.Add(blockedDate);
        await _dbContext.SaveChangesAsync();
        return ToBlockedDateResponse(blockedDate);
    }

    public async Task<BlockedDateResponse> UpdateBlockedDateAsync(Guid blockedDateId, UpsertBlockedDateRequest request)
    {
        var (startTime, endTime) = ValidateBlockedDate(request);
        var blockedDate = await _dbContext.BlockedDates
            .FirstOrDefaultAsync(x => x.Id == blockedDateId)
            ?? throw new ValidationAppException("Bloqueio não encontrado.", new[] { "Verifique o identificador informado." });

        blockedDate.Date = request.Date;
        blockedDate.Reason = request.Reason.Trim();
        blockedDate.IsFullDay = request.IsFullDay;
        blockedDate.StartTime = startTime;
        blockedDate.EndTime = endTime;
        blockedDate.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ToBlockedDateResponse(blockedDate);
    }

    public async Task<bool> DeleteBlockedDateAsync(Guid blockedDateId)
    {
        var blockedDate = await _dbContext.BlockedDates
            .FirstOrDefaultAsync(x => x.Id == blockedDateId);

        if (blockedDate is null)
        {
            return false;
        }

        _dbContext.BlockedDates.Remove(blockedDate);
        await _dbContext.SaveChangesAsync();
        return true;
    }

    public static IReadOnlyCollection<BusinessHour> CreateDefaultBusinessHours()
    {
        var hours = new List<BusinessHour>();

        for (var day = 0; day <= 6; day++)
        {
            hours.Add(new BusinessHour
            {
                DayOfWeek = day,
                IsOpen = day != (int)DayOfWeek.Sunday,
                StartTime = new TimeOnly(9, 0),
                EndTime = new TimeOnly(17, 0),
                SlotIntervalMinutes = 30
            });
        }

        return hours;
    }

    private async Task EnsureDefaultBusinessHoursAsync()
    {
        var existingDays = await _dbContext.BusinessHours
            .Select(x => x.DayOfWeek)
            .ToListAsync();

        var missing = CreateDefaultBusinessHours()
            .Where(x => !existingDays.Contains(x.DayOfWeek))
            .ToList();

        if (missing.Count == 0)
        {
            return;
        }

        _dbContext.BusinessHours.AddRange(missing);
        await _dbContext.SaveChangesAsync();
    }

    private static void ValidateBusinessHours(IReadOnlyCollection<UpdateBusinessHourRequest> requests)
    {
        var errors = new List<string>();

        if (requests.Count != 7 || requests.Select(x => x.DayOfWeek).Distinct().Count() != 7)
        {
            errors.Add("Informe uma configuração única para cada dia da semana.");
        }

        foreach (var request in requests)
        {
            if (request.DayOfWeek is < 0 or > 6)
            {
                errors.Add("Dia da semana inválido.");
                continue;
            }

            if (request.SlotIntervalMinutes is < 15 or > 120)
            {
                errors.Add($"{DayNames[request.DayOfWeek]}: o intervalo deve ficar entre 15 e 120 minutos.");
            }

            if (!request.IsOpen)
            {
                continue;
            }

            if (!TryParseTime(request.StartTime, out var startTime) || !TryParseTime(request.EndTime, out var endTime))
            {
                errors.Add($"{DayNames[request.DayOfWeek]}: informe hora inicial e final válidas.");
            }
            else if (startTime >= endTime)
            {
                errors.Add($"{DayNames[request.DayOfWeek]}: a hora inicial deve ser anterior à hora final.");
            }
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Horários de atendimento inválidos.", errors.Distinct());
        }
    }

    private static (TimeOnly? StartTime, TimeOnly? EndTime) ValidateBlockedDate(UpsertBlockedDateRequest request)
    {
        var errors = new List<string>();
        TimeOnly? startTime = null;
        TimeOnly? endTime = null;

        if (request.Date == default)
        {
            errors.Add("Data é obrigatória.");
        }

        if (string.IsNullOrWhiteSpace(request.Reason))
        {
            errors.Add("Motivo é obrigatório.");
        }
        else if (request.Reason.Trim().Length > 180)
        {
            errors.Add("Motivo deve ter no máximo 180 caracteres.");
        }

        if (!request.IsFullDay)
        {
            if (!TryParseTime(request.StartTime, out var parsedStart) || !TryParseTime(request.EndTime, out var parsedEnd))
            {
                errors.Add("Informe hora inicial e final válidas para o bloqueio parcial.");
            }
            else if (parsedStart >= parsedEnd)
            {
                errors.Add("A hora inicial do bloqueio deve ser anterior à hora final.");
            }
            else
            {
                startTime = parsedStart;
                endTime = parsedEnd;
            }
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Bloqueio de data inválido.", errors);
        }

        return (startTime, endTime);
    }

    private static TimeOnly ParseTimeOrDefault(string? value, TimeOnly fallback)
    {
        return TryParseTime(value, out var parsed) ? parsed : fallback;
    }

    private static bool TryParseTime(string? value, out TimeOnly parsed)
    {
        return TimeOnly.TryParseExact(
            value,
            new[] { "H:mm", "HH:mm", "H:mm:ss", "HH:mm:ss" },
            CultureInfo.InvariantCulture,
            DateTimeStyles.None,
            out parsed);
    }

    private static BusinessHourResponse ToBusinessHourResponse(BusinessHour businessHour)
    {
        return new BusinessHourResponse
        {
            Id = businessHour.Id,
            DayOfWeek = businessHour.DayOfWeek,
            DayName = DayNames[businessHour.DayOfWeek],
            IsOpen = businessHour.IsOpen,
            StartTime = businessHour.StartTime.ToString("HH:mm", CultureInfo.InvariantCulture),
            EndTime = businessHour.EndTime.ToString("HH:mm", CultureInfo.InvariantCulture),
            SlotIntervalMinutes = businessHour.SlotIntervalMinutes
        };
    }

    private static BlockedDateResponse ToBlockedDateResponse(BlockedDate blockedDate)
    {
        return new BlockedDateResponse
        {
            Id = blockedDate.Id,
            Date = blockedDate.Date,
            Reason = blockedDate.Reason,
            IsFullDay = blockedDate.IsFullDay,
            StartTime = blockedDate.StartTime?.ToString("HH:mm", CultureInfo.InvariantCulture),
            EndTime = blockedDate.EndTime?.ToString("HH:mm", CultureInfo.InvariantCulture),
            CreatedAt = blockedDate.CreatedAt,
            UpdatedAt = blockedDate.UpdatedAt
        };
    }
}
