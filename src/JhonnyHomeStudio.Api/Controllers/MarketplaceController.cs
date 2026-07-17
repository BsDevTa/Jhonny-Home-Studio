using JhonnyHomeStudio.Api.Helpers;
using JhonnyHomeStudio.Application.Common.Dtos.Marketplace;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/marketplace")]
public sealed class MarketplaceController : ControllerBase
{
    private readonly IMarketplaceService _marketplaceService;
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<MarketplaceController> _logger;

    public MarketplaceController(
        IMarketplaceService marketplaceService,
        IServiceProvider serviceProvider,
        ILogger<MarketplaceController> logger)
    {
        _marketplaceService = marketplaceService;
        _serviceProvider = serviceProvider;
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
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadImage([FromForm] IFormFile? file, CancellationToken cancellationToken)
    {
        _logger.LogInformation(
            "Marketplace upload endpoint started. Path={Path}; HasFile={HasFile}; FileName={FileName}; ContentType={ContentType}; Length={Length}; RequestContentLength={RequestContentLength}; TraceId={TraceId}",
            Request.Path,
            file is not null,
            file?.FileName,
            file?.ContentType,
            file?.Length,
            Request.ContentLength,
            HttpContext.TraceIdentifier);

        _logger.LogInformation("Resolving file storage. Folder={Folder}; TraceId={TraceId}", "products", HttpContext.TraceIdentifier);
        var fileStorage = _serviceProvider.GetRequiredService<IFileStorageService>();
        _logger.LogInformation(
            "File storage resolved. Folder={Folder}; StorageType={StorageType}; TraceId={TraceId}",
            "products",
            fileStorage.GetType().Name,
            HttpContext.TraceIdentifier);

        var response = await MediaUploadHelper.SaveAsync(
            file,
            MediaUploadHelper.ProductImage,
            fileStorage,
            GetPublicOrigin(),
            _logger,
            cancellationToken);

        _logger.LogInformation("Marketplace upload endpoint returning success. Folder={Folder}; TraceId={TraceId}", "products", HttpContext.TraceIdentifier);
        return Ok(response);
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
