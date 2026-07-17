using JhonnyHomeStudio.Application.Common.Dtos.Marketplace;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class MarketplaceService : IMarketplaceService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;
    private readonly ILogger<MarketplaceService> _logger;

    public MarketplaceService(
        JhonnyHomeStudioDbContext dbContext,
        ILogger<MarketplaceService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task<IEnumerable<ProductResponse>> GetProductsAsync(bool includeInactive, bool? featured = null, string? search = null)
    {
        var query = ProductsQuery(includeInactive);
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
        ValidateProduct(request);
        var entity = new Product();
        ApplyProductDetails(entity, request);
        ApplyProductImages(entity, request, preserveExistingWhenEmpty: false);

        _dbContext.Products.Add(entity);
        await _dbContext.SaveChangesAsync();
        _logger.LogInformation(
            "Product image create. ProductId={ProductId}; MainImageUrl={MainImageUrl}; ImagesCount={ImagesCount}",
            entity.Id,
            entity.MainImageUrl,
            entity.Images.Count);
        return await GetProductByIdRequiredAsync(entity.Id);
    }

    public async Task<ProductResponse> UpdateProductAsync(Guid id, UpsertProductRequest request)
    {
        ValidateProduct(request);
        var entity = await _dbContext.Products
            .Include(x => x.Images)
            .FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new ValidationAppException("Produto nao encontrado.", new[] { "Verifique o identificador informado." });

        var previousMainImageUrl = entity.MainImageUrl;
        var previousImagesCount = entity.Images.Count;
        var requestImagesCount = request.Images.Count();
        ApplyProductDetails(entity, request);
        ApplyProductImages(entity, request, preserveExistingWhenEmpty: true);
        entity.UpdatedAt = DateTime.UtcNow;
        _logger.LogInformation(
            "Product image edit. ProductId={ProductId}; OldMainImageUrl={OldMainImageUrl}; RequestMainImageUrl={RequestMainImageUrl}; NewMainImageUrl={NewMainImageUrl}; RemoveImage={RemoveImage}; OldImagesCount={OldImagesCount}; RequestImagesCount={RequestImagesCount}; NewImagesCount={NewImagesCount}",
            entity.Id,
            previousMainImageUrl,
            request.MainImageUrl,
            entity.MainImageUrl,
            request.RemoveImage,
            previousImagesCount,
            requestImagesCount,
            entity.Images.Count);

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
            .Include(x => x.Images)
            .AsQueryable();

        if (!includeInactive)
        {
            query = query.Where(x => x.IsActive);
        }

        return query;
    }

    private async Task<ProductResponse> GetProductByIdRequiredAsync(Guid id)
    {
        return await GetProductByIdAsync(id, includeInactive: true)
            ?? throw new ValidationAppException("Produto nao encontrado.", new[] { "Verifique o identificador informado." });
    }

    private static void ValidateProduct(UpsertProductRequest request)
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            errors.Add("Nome e obrigatorio.");
        }
        if (string.IsNullOrWhiteSpace(request.Description))
        {
            errors.Add("Descricao e obrigatoria.");
        }
        if (request.Price <= 0)
        {
            errors.Add("Preco deve ser maior que zero.");
        }
        if (request.PromotionalPrice.HasValue && request.PromotionalPrice.Value <= 0)
        {
            errors.Add("Preco promocional deve ser maior que zero.");
        }
        if (request.PromotionalPrice.HasValue && request.PromotionalPrice.Value >= request.Price)
        {
            errors.Add("Preco promocional deve ser menor que o preco normal.");
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Dados invalidos.", errors);
        }
    }

    private static void ApplyProductDetails(Product entity, UpsertProductRequest request)
    {
        entity.Name = request.Name.Trim();
        entity.Description = request.Description.Trim();
        entity.ShortDescription = NormalizeOptional(request.ShortDescription);
        entity.Price = request.Price;
        entity.PromotionalPrice = request.PromotionalPrice;
        entity.IsActive = request.IsActive;
        entity.IsFeatured = request.IsFeatured;
        entity.DisplayOrder = request.DisplayOrder;
        entity.StockQuantity = request.StockQuantity;
    }

    private static void ApplyProductImages(
        Product entity,
        UpsertProductRequest request,
        bool preserveExistingWhenEmpty)
    {
        if (request.RemoveImage)
        {
            entity.MainImageUrl = null;
            entity.Images.Clear();
            return;
        }

        var images = BuildImages(request).ToList();
        if (preserveExistingWhenEmpty && images.Count == 0)
        {
            return;
        }

        entity.MainImageUrl = NormalizeOptional(request.MainImageUrl)
            ?? images.FirstOrDefault(x => x.IsMain)?.ImageUrl
            ?? images.FirstOrDefault()?.ImageUrl;

        entity.Images.Clear();
        foreach (var image in images)
        {
            entity.Images.Add(image);
        }
    }

    private static IEnumerable<ProductImage> BuildImages(UpsertProductRequest request)
    {
        var images = request.Images
            .Select(x => new
            {
                ImageUrl = NormalizeOptional(x.ImageUrl),
                x.DisplayOrder,
                x.IsMain
            })
            .Where(x => !string.IsNullOrWhiteSpace(x.ImageUrl))
            .Select(x => new ProductImage
            {
                ImageUrl = x.ImageUrl!,
                DisplayOrder = x.DisplayOrder,
                IsMain = x.IsMain
            })
            .ToList();

        var mainImageUrl = NormalizeOptional(request.MainImageUrl);
        if (!string.IsNullOrWhiteSpace(mainImageUrl) && images.All(x => x.ImageUrl != mainImageUrl))
        {
            images.Add(new ProductImage
            {
                ImageUrl = mainImageUrl,
                DisplayOrder = 0,
                IsMain = true
            });
        }

        return images;
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

    private static ProductResponse ToProductResponse(Product entity)
    {
        return new ProductResponse
        {
            Id = entity.Id,
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
