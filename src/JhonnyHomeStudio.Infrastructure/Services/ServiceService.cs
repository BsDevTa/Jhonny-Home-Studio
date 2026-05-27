using JhonnyHomeStudio.Application.Common.Dtos.Services;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class ServiceService : IServiceService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;

    public ServiceService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
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

    public async Task<IEnumerable<ServiceResponse>> GetByCategoryAsync(Guid categoryId)
    {
        return await QueryServices(includeInactive: false)
            .Where(x => x.ServiceCategoryId == categoryId)
            .OrderBy(x => x.Name)
            .ToListAsync();
    }

    public async Task<ServiceResponse> CreateAsync(CreateServiceRequest request)
    {
        ValidateRequest(request.Name, request.Price, request.EstimatedDurationMinutes, request.ServiceCategoryId);

        var categoryExists = await _dbContext.ServiceCategories.AnyAsync(x => x.Id == request.ServiceCategoryId);
        if (!categoryExists)
        {
            throw new ValidationAppException("Categoria inválida.", new[] { "A categoria informada não existe." });
        }

        var entity = new Service
        {
            ServiceCategoryId = request.ServiceCategoryId,
            Name = request.Name.Trim(),
            Description = request.Description.Trim(),
            Price = request.Price,
            EstimatedDurationMinutes = request.EstimatedDurationMinutes,
            ImageUrl = request.ImageUrl?.Trim(),
            IsActive = true
        };

        _dbContext.Services.Add(entity);
        await _dbContext.SaveChangesAsync();

        return await GetByIdRequiredAsync(entity.Id);
    }

    public async Task<ServiceResponse> UpdateAsync(Guid id, UpdateServiceRequest request)
    {
        ValidateRequest(request.Name, request.Price, request.EstimatedDurationMinutes, request.ServiceCategoryId);

        var entity = await _dbContext.Services.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new ValidationAppException("Serviço não encontrado.", new[] { "Verifique o identificador informado." });

        var categoryExists = await _dbContext.ServiceCategories.AnyAsync(x => x.Id == request.ServiceCategoryId);
        if (!categoryExists)
        {
            throw new ValidationAppException("Categoria inválida.", new[] { "A categoria informada não existe." });
        }

        entity.ServiceCategoryId = request.ServiceCategoryId;
        entity.Name = request.Name.Trim();
        entity.Description = request.Description.Trim();
        entity.Price = request.Price;
        entity.EstimatedDurationMinutes = request.EstimatedDurationMinutes;
        entity.ImageUrl = request.ImageUrl?.Trim();
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;

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
        var query = _dbContext.Services
            .AsNoTracking()
            .Include(x => x.ServiceCategory)
            .AsQueryable();

        if (!includeInactive)
        {
            query = query.Where(x => x.IsActive && x.ServiceCategory.IsActive);
        }

        return query.Select(x => new ServiceResponse
        {
            Id = x.Id,
            ServiceCategoryId = x.ServiceCategoryId,
            ServiceCategoryName = x.ServiceCategory.Name,
            Name = x.Name,
            Description = x.Description,
            Price = x.Price,
            EstimatedDurationMinutes = x.EstimatedDurationMinutes,
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
            ?? throw new ValidationAppException("Serviço não encontrado.", new[] { "Verifique o identificador informado." });
    }

    private static void ValidateRequest(string name, decimal price, int estimatedDurationMinutes, Guid categoryId)
    {
        var errors = new List<string>();

        if (categoryId == Guid.Empty)
        {
            errors.Add("Categoria é obrigatória.");
        }

        if (string.IsNullOrWhiteSpace(name))
        {
            errors.Add("Nome é obrigatório.");
        }

        if (price <= 0)
        {
            errors.Add("Preço deve ser maior que zero.");
        }

        if (estimatedDurationMinutes <= 0)
        {
            errors.Add("Duração deve ser maior que zero.");
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Dados inválidos.", errors);
        }
    }
}