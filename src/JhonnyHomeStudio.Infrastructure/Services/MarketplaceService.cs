using JhonnyHomeStudio.Application.Common.Dtos.Marketplace;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class MarketplaceService : IMarketplaceService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;

    public MarketplaceService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IEnumerable<ProductCategoryResponse>> GetCategoriesAsync(bool includeInactive)
    {
        var query = _dbContext.ProductCategories.AsNoTracking().AsQueryable();
        if (!includeInactive)
        {
            query = query.Where(x => x.IsActive);
        }

        return await query
            .OrderBy(x => x.DisplayOrder)
            .ThenBy(x => x.Name)
            .Select(x => ToCategoryResponse(x))
            .ToListAsync();
    }

    public async Task<ProductCategoryResponse?> GetCategoryByIdAsync(Guid id, bool includeInactive)
    {
        var query = _dbContext.ProductCategories.AsNoTracking().Where(x => x.Id == id);
        if (!includeInactive)
        {
            query = query.Where(x => x.IsActive);
        }

        return await query.Select(x => ToCategoryResponse(x)).FirstOrDefaultAsync();
    }

    public async Task<ProductCategoryResponse> CreateCategoryAsync(UpsertProductCategoryRequest request)
    {
        ValidateCategory(request);
        await EnsureCategoryNameIsUniqueAsync(request.Name);

        var entity = new ProductCategory
        {
            Name = request.Name.Trim(),
            Description = NormalizeOptional(request.Description),
            DisplayOrder = request.DisplayOrder,
            IsActive = request.IsActive
        };

        _dbContext.ProductCategories.Add(entity);
        await _dbContext.SaveChangesAsync();
        return ToCategoryResponse(entity);
    }

    public async Task<ProductCategoryResponse> UpdateCategoryAsync(Guid id, UpsertProductCategoryRequest request)
    {
        ValidateCategory(request);
        var entity = await _dbContext.ProductCategories.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new ValidationAppException("Categoria não encontrada.", new[] { "Verifique o identificador informado." });

        await EnsureCategoryNameIsUniqueAsync(request.Name, id);
        entity.Name = request.Name.Trim();
        entity.Description = NormalizeOptional(request.Description);
        entity.DisplayOrder = request.DisplayOrder;
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ToCategoryResponse(entity);
    }

    public async Task<ProductCategoryResponse?> ToggleCategoryAsync(Guid id)
    {
        var entity = await _dbContext.ProductCategories.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return null;
        }

        entity.IsActive = !entity.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return ToCategoryResponse(entity);
    }

    public async Task<bool> DeleteCategoryAsync(Guid id)
    {
        var entity = await _dbContext.ProductCategories.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return false;
        }

        entity.IsActive = false;
        entity.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<ProductResponse>> GetProductsAsync(bool includeInactive, Guid? categoryId = null, bool? featured = null, string? search = null)
    {
        var query = ProductsQuery(includeInactive);
        if (categoryId.HasValue)
        {
            query = query.Where(x => x.ProductCategoryId == categoryId.Value);
        }
        if (featured.HasValue)
        {
            query = query.Where(x => x.IsFeatured == featured.Value);
        }
        if (!string.IsNullOrWhiteSpace(search))
        {
            var normalizedSearch = search.Trim().ToLowerInvariant();
            query = query.Where(x => x.Name.ToLower().Contains(normalizedSearch) || x.Description.ToLower().Contains(normalizedSearch));
        }

        return await query
            .OrderBy(x => x.DisplayOrder)
            .ThenBy(x => x.Name)
            .Select(x => ToProductResponse(x))
            .ToListAsync();
    }

    public async Task<ProductResponse?> GetProductByIdAsync(Guid id, bool includeInactive)
    {
        return await ProductsQuery(includeInactive)
            .Where(x => x.Id == id)
            .Select(x => ToProductResponse(x))
            .FirstOrDefaultAsync();
    }

    public async Task<ProductResponse> CreateProductAsync(UpsertProductRequest request)
    {
        await ValidateProductAsync(request);
        var entity = new Product();
        ApplyProduct(entity, request);

        _dbContext.Products.Add(entity);
        await _dbContext.SaveChangesAsync();
        return await GetProductByIdRequiredAsync(entity.Id);
    }

    public async Task<ProductResponse> UpdateProductAsync(Guid id, UpsertProductRequest request)
    {
        await ValidateProductAsync(request);
        var entity = await _dbContext.Products
            .Include(x => x.Images)
            .FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new ValidationAppException("Produto não encontrado.", new[] { "Verifique o identificador informado." });

        ApplyProduct(entity, request);
        entity.UpdatedAt = DateTime.UtcNow;
        entity.Images.Clear();
        foreach (var image in BuildImages(request))
        {
            entity.Images.Add(image);
        }

        await _dbContext.SaveChangesAsync();
        return await GetProductByIdRequiredAsync(entity.Id);
    }

    public async Task<ProductResponse?> ToggleProductAsync(Guid id)
    {
        var entity = await _dbContext.Products.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return null;
        }

        entity.IsActive = !entity.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return await GetProductByIdRequiredAsync(id);
    }

    public async Task<bool> DeleteProductAsync(Guid id)
    {
        var entity = await _dbContext.Products.FirstOrDefaultAsync(x => x.Id == id);
        if (entity is null)
        {
            return false;
        }

        entity.IsActive = false;
        entity.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return true;
    }

    private IQueryable<Product> ProductsQuery(bool includeInactive)
    {
        var query = _dbContext.Products
            .AsNoTracking()
            .Include(x => x.ProductCategory)
            .Include(x => x.Images)
            .AsQueryable();

        if (!includeInactive)
        {
            query = query.Where(x => x.IsActive && x.ProductCategory.IsActive);
        }

        return query;
    }

    private async Task<ProductResponse> GetProductByIdRequiredAsync(Guid id)
    {
        return await GetProductByIdAsync(id, includeInactive: true)
            ?? throw new ValidationAppException("Produto não encontrado.", new[] { "Verifique o identificador informado." });
    }

    private async Task ValidateProductAsync(UpsertProductRequest request)
    {
        var errors = new List<string>();
        if (request.ProductCategoryId == Guid.Empty)
        {
            errors.Add("Categoria é obrigatória.");
        }
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            errors.Add("Nome é obrigatório.");
        }
        if (string.IsNullOrWhiteSpace(request.Description))
        {
            errors.Add("Descrição é obrigatória.");
        }
        if (request.Price <= 0)
        {
            errors.Add("Preço deve ser maior que zero.");
        }
        if (request.PromotionalPrice.HasValue && request.PromotionalPrice.Value <= 0)
        {
            errors.Add("Preço promocional deve ser maior que zero.");
        }
        if (request.PromotionalPrice.HasValue && request.PromotionalPrice.Value >= request.Price)
        {
            errors.Add("Preço promocional deve ser menor que o preço normal.");
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Dados inválidos.", errors);
        }

        var categoryExists = await _dbContext.ProductCategories.AnyAsync(x => x.Id == request.ProductCategoryId);
        if (!categoryExists)
        {
            throw new ValidationAppException("Categoria inválida.", new[] { "A categoria informada não existe." });
        }
    }

    private static void ApplyProduct(Product entity, UpsertProductRequest request)
    {
        entity.ProductCategoryId = request.ProductCategoryId;
        entity.Name = request.Name.Trim();
        entity.Description = request.Description.Trim();
        entity.ShortDescription = NormalizeOptional(request.ShortDescription);
        entity.Price = request.Price;
        entity.PromotionalPrice = request.PromotionalPrice;
        entity.MainImageUrl = NormalizeOptional(request.MainImageUrl);
        entity.IsActive = request.IsActive;
        entity.IsFeatured = request.IsFeatured;
        entity.DisplayOrder = request.DisplayOrder;
        entity.StockQuantity = request.StockQuantity;

        if (!entity.Images.Any())
        {
            foreach (var image in BuildImages(request))
            {
                entity.Images.Add(image);
            }
        }
    }

    private static IEnumerable<ProductImage> BuildImages(UpsertProductRequest request)
    {
        var images = request.Images
            .Where(x => !string.IsNullOrWhiteSpace(x.ImageUrl))
            .Select(x => new ProductImage
            {
                ImageUrl = x.ImageUrl.Trim(),
                DisplayOrder = x.DisplayOrder,
                IsMain = x.IsMain
            })
            .ToList();

        if (!string.IsNullOrWhiteSpace(request.MainImageUrl) && images.All(x => x.ImageUrl != request.MainImageUrl.Trim()))
        {
            images.Add(new ProductImage
            {
                ImageUrl = request.MainImageUrl.Trim(),
                DisplayOrder = 0,
                IsMain = true
            });
        }

        return images;
    }

    private async Task EnsureCategoryNameIsUniqueAsync(string name, Guid? id = null)
    {
        var normalizedName = name.Trim().ToLowerInvariant();
        var exists = await _dbContext.ProductCategories.AnyAsync(x => x.Name.ToLower() == normalizedName && (!id.HasValue || x.Id != id.Value));
        if (exists)
        {
            throw new ConflictAppException("Categoria já cadastrada.", new[] { "Já existe uma categoria de produto com este nome." });
        }
    }

    private static void ValidateCategory(UpsertProductCategoryRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new ValidationAppException("Dados inválidos.", new[] { "Nome é obrigatório." });
        }
    }

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private static ProductCategoryResponse ToCategoryResponse(ProductCategory entity)
    {
        return new ProductCategoryResponse
        {
            Id = entity.Id,
            Name = entity.Name,
            Description = entity.Description,
            DisplayOrder = entity.DisplayOrder,
            IsActive = entity.IsActive,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }

    private static ProductResponse ToProductResponse(Product entity)
    {
        return new ProductResponse
        {
            Id = entity.Id,
            ProductCategoryId = entity.ProductCategoryId,
            ProductCategoryName = entity.ProductCategory.Name,
            Name = entity.Name,
            Description = entity.Description,
            ShortDescription = entity.ShortDescription,
            Price = entity.Price,
            PromotionalPrice = entity.PromotionalPrice,
            MainImageUrl = entity.MainImageUrl,
            IsActive = entity.IsActive,
            IsFeatured = entity.IsFeatured,
            DisplayOrder = entity.DisplayOrder,
            StockQuantity = entity.StockQuantity,
            Images = entity.Images
                .OrderBy(x => x.DisplayOrder)
                .Select(x => new ProductImageResponse
                {
                    Id = x.Id,
                    ProductId = x.ProductId,
                    ImageUrl = x.ImageUrl,
                    DisplayOrder = x.DisplayOrder,
                    IsMain = x.IsMain,
                    CreatedAt = x.CreatedAt
                }),
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }
}
