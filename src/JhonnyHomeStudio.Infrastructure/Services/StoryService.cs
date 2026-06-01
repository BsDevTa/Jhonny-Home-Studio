using System.Linq.Expressions;
using JhonnyHomeStudio.Application.Common.Dtos.Stories;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Domain.Enums;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class StoryService : IStoryService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;

    public StoryService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IEnumerable<StoryResponse>> GetActiveAsync()
    {
        var now = DateTime.UtcNow;
        return await BuildQuery()
            .Where(x => x.IsActive && x.StartsAtUtc <= now && x.ExpiresAtUtc >= now)
            .OrderBy(x => x.SortOrder)
            .ThenByDescending(x => x.CreatedAt)
            .Select(ToResponseProjection())
            .ToListAsync();
    }

    public async Task<StoryResponse?> GetPublicByIdAsync(Guid id)
    {
        var now = DateTime.UtcNow;
        return await BuildQuery()
            .Where(x => x.Id == id && x.IsActive && x.StartsAtUtc <= now && x.ExpiresAtUtc >= now)
            .Select(ToResponseProjection())
            .FirstOrDefaultAsync();
    }

    public async Task<IEnumerable<StoryResponse>> GetAllAsync()
    {
        return await BuildQuery()
            .OrderBy(x => x.SortOrder)
            .ThenByDescending(x => x.CreatedAt)
            .Select(ToResponseProjection())
            .ToListAsync();
    }

    public async Task<StoryResponse?> GetByIdAsync(Guid id)
    {
        return await BuildQuery()
            .Where(x => x.Id == id)
            .Select(ToResponseProjection())
            .FirstOrDefaultAsync();
    }

    public async Task<StoryResponse> CreateAsync(Guid adminUserId, CreateStoryRequest request)
    {
        var now = DateTime.UtcNow;
        var startsAtUtc = NormalizeUtc(request.StartsAt ?? now);
        var expiresAtUtc = NormalizeUtc(request.EndsAt ?? startsAtUtc.AddDays(30));

        ValidateRequest(request.Title, request.Subtitle, request.ImageUrl, request.DisplayOrder, startsAtUtc, expiresAtUtc);
        await ValidateServiceAsync(request.ServiceId);

        var adminUser = await _dbContext.AdminUsers
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == adminUserId)
            ?? throw new ValidationAppException("Administrador não encontrado.", new[] { "Não foi possível localizar o administrador autenticado." });

        var entity = new Story
        {
            CreatedByAdminUserId = adminUser.Id,
            ServiceId = request.ServiceId,
            Title = request.Title.Trim(),
            ShortText = request.Subtitle?.Trim() ?? string.Empty,
            ImageUrl = NormalizeOptional(request.ImageUrl),
            ActionType = request.ServiceId.HasValue ? StoryActionType.Service : StoryActionType.None,
            ActionValue = request.ServiceId?.ToString(),
            StartsAtUtc = startsAtUtc,
            ExpiresAtUtc = expiresAtUtc,
            IsActive = request.IsActive,
            SortOrder = request.DisplayOrder
        };

        _dbContext.Stories.Add(entity);
        await _dbContext.SaveChangesAsync();
        return await GetByIdRequiredAsync(entity.Id);
    }

    public async Task<StoryResponse> UpdateAsync(Guid id, UpdateStoryRequest request)
    {
        var entity = await _dbContext.Stories.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new ValidationAppException("Story não encontrado.", new[] { "Verifique o identificador informado." });

        var startsAtUtc = NormalizeUtc(request.StartsAt ?? entity.StartsAtUtc);
        var expiresAtUtc = NormalizeUtc(request.EndsAt ?? entity.ExpiresAtUtc);

        ValidateRequest(request.Title, request.Subtitle, request.ImageUrl, request.DisplayOrder, startsAtUtc, expiresAtUtc);
        await ValidateServiceAsync(request.ServiceId);

        entity.ServiceId = request.ServiceId;
        entity.Title = request.Title.Trim();
        entity.ShortText = request.Subtitle?.Trim() ?? string.Empty;
        entity.ImageUrl = NormalizeOptional(request.ImageUrl);
        entity.ActionType = request.ServiceId.HasValue ? StoryActionType.Service : StoryActionType.None;
        entity.ActionValue = request.ServiceId?.ToString();
        entity.StartsAtUtc = startsAtUtc;
        entity.ExpiresAtUtc = expiresAtUtc;
        entity.IsActive = request.IsActive;
        entity.SortOrder = request.DisplayOrder;
        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return await GetByIdRequiredAsync(entity.Id);
    }

    public async Task<StoryResponse?> ToggleActiveAsync(Guid id)
    {
        var entity = await _dbContext.Stories.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return null;
        }

        entity.IsActive = !entity.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return await GetByIdRequiredAsync(entity.Id);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var entity = await _dbContext.Stories.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return false;
        }

        _dbContext.Stories.Remove(entity);
        await _dbContext.SaveChangesAsync();
        return true;
    }

    private IQueryable<Story> BuildQuery()
    {
        return _dbContext.Stories
            .AsNoTracking()
            .Include(x => x.Service);
    }

    private async Task<StoryResponse> GetByIdRequiredAsync(Guid id)
    {
        return await GetByIdAsync(id)
            ?? throw new ValidationAppException("Story não encontrado.", new[] { "Verifique o identificador informado." });
    }

    private async Task ValidateServiceAsync(Guid? serviceId)
    {
        if (!serviceId.HasValue)
        {
            return;
        }

        var serviceExists = await _dbContext.Services.AnyAsync(x => x.Id == serviceId.Value);
        if (!serviceExists)
        {
            throw new ValidationAppException("Serviço inválido.", new[] { "O serviço vinculado ao story não existe." });
        }
    }

    private static void ValidateRequest(
        string title,
        string? subtitle,
        string? imageUrl,
        int displayOrder,
        DateTime startsAtUtc,
        DateTime expiresAtUtc)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(title))
        {
            errors.Add("Título é obrigatório.");
        }
        else if (title.Trim().Length > 160)
        {
            errors.Add("Título deve ter no máximo 160 caracteres.");
        }

        if (subtitle?.Trim().Length > 280)
        {
            errors.Add("Subtítulo deve ter no máximo 280 caracteres.");
        }

        if (imageUrl?.Trim().Length > 500)
        {
            errors.Add("URL da imagem deve ter no máximo 500 caracteres.");
        }

        if (displayOrder < 0)
        {
            errors.Add("Ordem de exibição não pode ser negativa.");
        }

        if (expiresAtUtc <= startsAtUtc)
        {
            errors.Add("Data final deve ser posterior à data inicial.");
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Dados inválidos.", errors);
        }
    }

    private static DateTime NormalizeUtc(DateTime value)
    {
        return value.Kind == DateTimeKind.Utc ? value : value.ToUniversalTime();
    }

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private static Expression<Func<Story, StoryResponse>> ToResponseProjection()
    {
        return x => new StoryResponse
        {
            Id = x.Id,
            Title = x.Title,
            Subtitle = x.ShortText,
            ImageUrl = x.ImageUrl,
            ServiceId = x.ServiceId,
            ServiceName = x.Service == null ? null : x.Service.Name,
            DisplayOrder = x.SortOrder,
            IsActive = x.IsActive,
            StartsAt = x.StartsAtUtc,
            EndsAt = x.ExpiresAtUtc,
            CreatedAt = x.CreatedAt,
            UpdatedAt = x.UpdatedAt
        };
    }
}
