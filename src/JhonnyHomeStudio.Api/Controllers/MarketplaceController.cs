using JhonnyHomeStudio.Application.Common.Dtos.Marketplace;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/marketplace")]
public sealed class MarketplaceController : ControllerBase
{
    private const long MaxImageSizeBytes = 5 * 1024 * 1024;
    private static readonly HashSet<string> AllowedImageExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    };

    private readonly IMarketplaceService _marketplaceService;
    private readonly IFileStorageService _fileStorage;
    private readonly ILogger<MarketplaceController> _logger;

    public MarketplaceController(
        IMarketplaceService marketplaceService,
        IFileStorageService fileStorage,
        ILogger<MarketplaceController> logger)
    {
        _marketplaceService = marketplaceService;
        _fileStorage = fileStorage;
        _logger = logger;
    }

    [HttpGet("products")]
    public async Task<IActionResult> GetPublicProducts([FromQuery] bool? featured = null, [FromQuery] string? search = null)
    {
        var response = await _marketplaceService.GetProductsAsync(includeInactive: false, featured, search);
        return Ok(ApiResponse<IEnumerable<ProductResponse>>.SuccessResponse("Produtos localizados com sucesso.", NormalizeProducts(response)));
    }

    [HttpGet("products/featured")]
    public async Task<IActionResult> GetFeaturedProducts()
    {
        var response = await _marketplaceService.GetProductsAsync(includeInactive: false, featured: true);
        return Ok(ApiResponse<IEnumerable<ProductResponse>>.SuccessResponse("Produtos em destaque localizados com sucesso.", NormalizeProducts(response)));
    }

    [HttpGet("products/{id:guid}")]
    public async Task<IActionResult> GetPublicProductById(Guid id)
    {
        var response = await _marketplaceService.GetProductByIdAsync(id, includeInactive: false);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Produto nao encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Produto localizado com sucesso.", NormalizeProduct(response)));
    }

    [HttpGet("/api/admin/marketplace/products")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminProducts()
    {
        var response = await _marketplaceService.GetProductsAsync(includeInactive: true);
        return Ok(ApiResponse<IEnumerable<ProductResponse>>.SuccessResponse("Produtos localizados com sucesso.", NormalizeProducts(response)));
    }

    [HttpGet("/api/admin/marketplace/products/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminProductById(Guid id)
    {
        var response = await _marketplaceService.GetProductByIdAsync(id, includeInactive: true);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Produto nao encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Produto localizado com sucesso.", NormalizeProduct(response)));
    }

    [HttpPost("/api/admin/marketplace/products")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateProduct([FromBody] UpsertProductRequest request)
    {
        var response = await _marketplaceService.CreateProductAsync(request);
        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Produto criado com sucesso.", NormalizeProduct(response)));
    }

    [HttpPut("/api/admin/marketplace/products/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateProduct(Guid id, [FromBody] UpsertProductRequest request)
    {
        var response = await _marketplaceService.UpdateProductAsync(id, request);
        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Produto atualizado com sucesso.", NormalizeProduct(response)));
    }

    [HttpPatch("/api/admin/marketplace/products/{id:guid}/toggle-active")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ToggleProduct(Guid id)
    {
        var response = await _marketplaceService.ToggleProductAsync(id);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Produto nao encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Status do produto atualizado com sucesso.", NormalizeProduct(response)));
    }

    [HttpDelete("/api/admin/marketplace/products/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteProduct(Guid id)
    {
        var deleted = await _marketplaceService.DeleteProductAsync(id);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Produto nao encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Produto removido com sucesso.", new { id }));
    }

    [HttpPost("/api/admin/marketplace/products/upload-image")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UploadImage([FromForm] IFormFile? file)
    {
        if (file is null || file.Length == 0)
        {
            throw new ValidationAppException("Arquivo nao enviado.");
        }
        if (file.Length > MaxImageSizeBytes)
        {
            throw new ValidationAppException("Imagem muito grande. O limite e 5MB.");
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedImageExtensions.Contains(extension))
        {
            throw new ValidationAppException("Formato de imagem nao permitido.");
        }

        try
        {
            await using var stream = file.OpenReadStream();
            var storedFile = await _fileStorage.SaveAsync(
                stream,
                file.FileName,
                file.ContentType,
                "uploads/products",
                "product",
                GetPublicOrigin());

            return Ok(ApiResponse<object>.SuccessResponse(
                "Imagem enviada com sucesso.",
                new
                {
                    success = storedFile.Exists,
                    url = storedFile.PublicUrl,
                    imageUrl = storedFile.PublicUrl,
                    relativePath = storedFile.RelativePath,
                    fileName = storedFile.FileName,
                    contentType = storedFile.ContentType,
                    sizeBytes = storedFile.SizeBytes,
                    storageProvider = storedFile.StorageProvider
                }));
        }
        catch (Exception exception)
        {
            _logger.LogError(exception, "Falha ao salvar imagem do produto. FileName={FileName}; ContentType={ContentType}; Length={Length}", file.FileName, file.ContentType, file.Length);
            throw new ValidationAppException("Nao foi possivel enviar a imagem.");
        }
    }

    private IEnumerable<ProductResponse> NormalizeProducts(IEnumerable<ProductResponse> products)
    {
        return products.Select(NormalizeProduct).ToArray();
    }

    private ProductResponse NormalizeProduct(ProductResponse product)
    {
        product.MainImageUrl = ResolveUrl(product.MainImageUrl);
        product.Images = product.Images
            .Select(image =>
            {
                image.ImageUrl = ResolveUrl(image.ImageUrl);
                return image;
            })
            .ToArray();

        return product;
    }

    private string ResolveUrl(string? value)
    {
        var url = value?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(url) || Uri.TryCreate(url, UriKind.Absolute, out _))
        {
            return url;
        }

        var path = url.StartsWith('/') ? url : $"/{url}";
        return new Uri(GetPublicOrigin(), path).ToString();
    }

    private Uri GetPublicOrigin()
    {
        return new Uri($"{Request.Scheme}://{Request.Host}");
    }
}
