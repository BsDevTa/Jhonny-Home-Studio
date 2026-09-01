using JhonnyHomeStudio.Application.Common.Dtos.Services;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class ServiceService : IServiceService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;
    private readonly ILogger<ServiceService> _logger;

    public ServiceService(
        JhonnyHomeStudioDbContext dbContext,
        ILogger<ServiceService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task<IEnumerable<ServiceResponse>> GetAllAsync()
    {
        return await QueryServices(includeInactive: true)
            .OrderBy(x => x.Name)
            .ToListAsync();
    }

    public async Task<IEnumerable<ServiceResponse>> GetActiveAsync()
    {
        return await QueryServices(includeInactive: false)
            .OrderBy(x => x.Name)
            .ToListAsync();
    }

    public async Task<ServiceResponse?> GetByIdAsync(Guid id)
    {
        return await QueryServices(includeInactive: true)
            .FirstOrDefaultAsync(x => x.Id == id);
    }

    public async Task<ServiceResponse> CreateAsync(CreateServiceRequest request)
    {
        ValidateRequest(request.Name, request.Price);

        var entity = new Service
        {
            Name = request.Name.Trim(),
            Description = NormalizeOptional(request.Description),
            Price = request.Price,
            ImageUrl = NormalizeOptional(request.ImageUrl),
            IsActive = request.IsActive
        };

        _dbContext.Services.Add(entity);
        await _dbContext.SaveChangesAsync();
        _logger.LogInformation(
            "Service image create. ServiceId={ServiceId}; ImageUrl={ImageUrl}",
            entity.Id,
            entity.ImageUrl);

        return await GetByIdRequiredAsync(entity.Id);
    }

    public async Task<ServiceResponse> UpdateAsync(Guid id, UpdateServiceRequest request)
    {
        ValidateRequest(request.Name, request.Price);

        var entity = await _dbContext.Services.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new ValidationAppException("Servico nao encontrado.", new[] { "Verifique o identificador informado." });

        var previousImageUrl = entity.ImageUrl;
        entity.Name = request.Name.Trim();
        entity.Description = NormalizeOptional(request.Description);
        entity.Price = request.Price;
        ApplyImageUpdate(entity, request.ImageUrl, request.RemoveImage);
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        _logger.LogInformation(
            "Service image edit. ServiceId={ServiceId}; OldImageUrl={OldImageUrl}; RequestImageUrl={RequestImageUrl}; NewImageUrl={NewImageUrl}; RemoveImage={RemoveImage}",
            entity.Id,
            previousImageUrl,
            request.ImageUrl,
            entity.ImageUrl,
            request.RemoveImage);

        await _dbContext.SaveChangesAsync();
        return await GetByIdRequiredAsync(entity.Id);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var entity = await _dbContext.Services.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return false;
        }

        entity.IsActive = false;
        entity.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ActivateAsync(Guid id)
    {
        var entity = await _dbContext.Services.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return false;
        }

        entity.IsActive = true;
        entity.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeactivateAsync(Guid id)
    {
        var entity = await _dbContext.Services.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return false;
        }

        entity.IsActive = false;
        entity.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return true;
    }

    private IQueryable<ServiceResponse> QueryServices(bool includeInactive)
    {
        var query = _dbContext.Services.AsNoTracking();

        if (!includeInactive)
        {
            query = query.Where(x => x.IsActive);
        }

        return query.Select(x => new ServiceResponse
        {
            Id = x.Id,
            Name = x.Name,
            Description = x.Description,
            Price = x.Price,
            ImageUrl = x.ImageUrl,
            IsActive = x.IsActive,
            CreatedAt = x.CreatedAt,
            UpdatedAt = x.UpdatedAt
        });
    }

    private async Task<ServiceResponse> GetByIdRequiredAsync(Guid id)
    {
        return await QueryServices(includeInactive: true)
            .FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new ValidationAppException("Servico nao encontrado.", new[] { "Verifique o identificador informado." });
    }

    private static void ValidateRequest(string name, decimal price)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(name))
        {
            errors.Add("Nome e obrigatorio.");
        }

        if (price < 0)
        {
            errors.Add("Preco deve ser maior ou igual a zero.");
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Dados invalidos.", errors);
        }
    }

    private static string? NormalizeOptional(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        return string.Equals(trimmed, "null", StringComparison.OrdinalIgnoreCase) ? null : trimmed;
    }

    private static void ApplyImageUpdate(Service entity, string? imageUrl, bool removeImage)
    {
        if (removeImage)
        {
            entity.ImageUrl = null;
            return;
        }

        var normalizedImageUrl = NormalizeOptional(imageUrl);
        if (!string.IsNullOrWhiteSpace(normalizedImageUrl))
        {
            entity.ImageUrl = normalizedImageUrl;
        }
    }
}
