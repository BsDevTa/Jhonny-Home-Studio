using JhonnyHomeStudio.Application.Common.Dtos.ServiceCategories;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class ServiceCategoryService : IServiceCategoryService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;

    public ServiceCategoryService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IEnumerable<ServiceCategoryResponse>> GetAllAsync()
    {
        return await _dbContext.ServiceCategories
            .AsNoTracking()
            .OrderBy(x => x.Name)
            .Select(x => ToResponse(x))
            .ToListAsync();
    }

    public async Task<IEnumerable<ServiceCategoryResponse>> GetActiveAsync()
    {
        return await _dbContext.ServiceCategories
            .AsNoTracking()
            .Where(x => x.IsActive)
            .OrderBy(x => x.Name)
            .Select(x => ToResponse(x))
            .ToListAsync();
    }

    public async Task<ServiceCategoryResponse?> GetByIdAsync(Guid id)
    {
        return await _dbContext.ServiceCategories
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => ToResponse(x))
            .FirstOrDefaultAsync();
    }

    public async Task<ServiceCategoryResponse> CreateAsync(CreateServiceCategoryRequest request)
    {
        ValidateRequest(request.Name);

        var normalizedName = NormalizeName(request.Name);
        var nameExists = await _dbContext.ServiceCategories.AnyAsync(x => x.Name.ToLower() == normalizedName);
        if (nameExists)
        {
            throw new ConflictAppException("Categoria já cadastrada.", new[] { "Já existe uma categoria com este nome." });
        }

        var entity = new ServiceCategory
        {
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            IsActive = true
        };

        _dbContext.ServiceCategories.Add(entity);
        await _dbContext.SaveChangesAsync();

        return ToResponse(entity);
    }

    public async Task<ServiceCategoryResponse> UpdateAsync(Guid id, UpdateServiceCategoryRequest request)
    {
        ValidateRequest(request.Name);

        var entity = await _dbContext.ServiceCategories.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new ValidationAppException("Categoria não encontrada.", new[] { "Verifique o identificador informado." });

        var normalizedName = NormalizeName(request.Name);
        var nameExists = await _dbContext.ServiceCategories.AnyAsync(x => x.Id != id && x.Name.ToLower() == normalizedName);
        if (nameExists)
        {
            throw new ConflictAppException("Categoria já cadastrada.", new[] { "Já existe uma categoria com este nome." });
        }

        entity.Name = request.Name.Trim();
        entity.Description = request.Description?.Trim();
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ToResponse(entity);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var entity = await _dbContext.ServiceCategories.FirstOrDefaultAsync(x => x.Id == id);
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
        var entity = await _dbContext.ServiceCategories.FirstOrDefaultAsync(x => x.Id == id);
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
        var entity = await _dbContext.ServiceCategories.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return false;
        }

        entity.IsActive = false;
        entity.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return true;
    }

    private static void ValidateRequest(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ValidationAppException("Dados inválidos.", new[] { "Nome é obrigatório." });
        }
    }

    private static string NormalizeName(string name)
    {
        return name.Trim().ToLowerInvariant();
    }

    private static ServiceCategoryResponse ToResponse(ServiceCategory entity)
    {
        return new ServiceCategoryResponse
        {
            Id = entity.Id,
            Name = entity.Name,
            Description = entity.Description,
            IsActive = entity.IsActive,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }
}