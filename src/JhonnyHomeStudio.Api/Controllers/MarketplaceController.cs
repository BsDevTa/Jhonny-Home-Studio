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
    private readonly IWebHostEnvironment _environment;

    public MarketplaceController(IMarketplaceService marketplaceService, IWebHostEnvironment environment)
    {
        _marketplaceService = marketplaceService;
        _environment = environment;
    }

    [HttpGet("categories")]
    public async Task<IActionResult> GetPublicCategories()
    {
        var response = await _marketplaceService.GetCategoriesAsync(includeInactive: false);
        return Ok(ApiResponse<IEnumerable<ProductCategoryResponse>>.SuccessResponse("Categorias da loja localizadas com sucesso.", response));
    }

    [HttpGet("products")]
    public async Task<IActionResult> GetPublicProducts([FromQuery] Guid? categoryId = null, [FromQuery] bool? featured = null, [FromQuery] string? search = null)
    {
        var response = await _marketplaceService.GetProductsAsync(includeInactive: false, categoryId, featured, search);
        return Ok(ApiResponse<IEnumerable<ProductResponse>>.SuccessResponse("Produtos localizados com sucesso.", response));
    }

    [HttpGet("products/featured")]
    public async Task<IActionResult> GetFeaturedProducts()
    {
        var response = await _marketplaceService.GetProductsAsync(includeInactive: false, featured: true);
        return Ok(ApiResponse<IEnumerable<ProductResponse>>.SuccessResponse("Produtos em destaque localizados com sucesso.", response));
    }

    [HttpGet("products/{id:guid}")]
    public async Task<IActionResult> GetPublicProductById(Guid id)
    {
        var response = await _marketplaceService.GetProductByIdAsync(id, includeInactive: false);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Produto não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Produto localizado com sucesso.", response));
    }

    [HttpGet("/api/admin/marketplace/categories")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminCategories()
    {
        var response = await _marketplaceService.GetCategoriesAsync(includeInactive: true);
        return Ok(ApiResponse<IEnumerable<ProductCategoryResponse>>.SuccessResponse("Categorias localizadas com sucesso.", response));
    }

    [HttpGet("/api/admin/marketplace/categories/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminCategoryById(Guid id)
    {
        var response = await _marketplaceService.GetCategoryByIdAsync(id, includeInactive: true);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Categoria não encontrada.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ProductCategoryResponse>.SuccessResponse("Categoria localizada com sucesso.", response));
    }

    [HttpPost("/api/admin/marketplace/categories")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateCategory([FromBody] UpsertProductCategoryRequest request)
    {
        var response = await _marketplaceService.CreateCategoryAsync(request);
        return Ok(ApiResponse<ProductCategoryResponse>.SuccessResponse("Categoria criada com sucesso.", response));
    }

    [HttpPut("/api/admin/marketplace/categories/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateCategory(Guid id, [FromBody] UpsertProductCategoryRequest request)
    {
        var response = await _marketplaceService.UpdateCategoryAsync(id, request);
        return Ok(ApiResponse<ProductCategoryResponse>.SuccessResponse("Categoria atualizada com sucesso.", response));
    }

    [HttpPatch("/api/admin/marketplace/categories/{id:guid}/toggle-active")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ToggleCategory(Guid id)
    {
        var response = await _marketplaceService.ToggleCategoryAsync(id);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Categoria não encontrada.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ProductCategoryResponse>.SuccessResponse("Status da categoria atualizado com sucesso.", response));
    }

    [HttpDelete("/api/admin/marketplace/categories/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteCategory(Guid id)
    {
        var deleted = await _marketplaceService.DeleteCategoryAsync(id);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Categoria não encontrada.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Categoria removida com sucesso.", new { id }));
    }

    [HttpGet("/api/admin/marketplace/products")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminProducts()
    {
        var response = await _marketplaceService.GetProductsAsync(includeInactive: true);
        return Ok(ApiResponse<IEnumerable<ProductResponse>>.SuccessResponse("Produtos localizados com sucesso.", response));
    }

    [HttpGet("/api/admin/marketplace/products/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminProductById(Guid id)
    {
        var response = await _marketplaceService.GetProductByIdAsync(id, includeInactive: true);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Produto não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Produto localizado com sucesso.", response));
    }

    [HttpPost("/api/admin/marketplace/products")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateProduct([FromBody] UpsertProductRequest request)
    {
        var response = await _marketplaceService.CreateProductAsync(request);
        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Produto criado com sucesso.", response));
    }

    [HttpPut("/api/admin/marketplace/products/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateProduct(Guid id, [FromBody] UpsertProductRequest request)
    {
        var response = await _marketplaceService.UpdateProductAsync(id, request);
        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Produto atualizado com sucesso.", response));
    }

    [HttpPatch("/api/admin/marketplace/products/{id:guid}/toggle-active")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ToggleProduct(Guid id)
    {
        var response = await _marketplaceService.ToggleProductAsync(id);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Produto não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ProductResponse>.SuccessResponse("Status do produto atualizado com sucesso.", response));
    }

    [HttpDelete("/api/admin/marketplace/products/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteProduct(Guid id)
    {
        var deleted = await _marketplaceService.DeleteProductAsync(id);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Produto não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Produto removido com sucesso.", new { id }));
    }

    [HttpPost("/api/admin/marketplace/products/upload-image")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UploadImage([FromForm] IFormFile? file)
    {
        if (file is null || file.Length == 0)
        {
            throw new ValidationAppException("Arquivo não enviado.");
        }
        if (file.Length > MaxImageSizeBytes)
        {
            throw new ValidationAppException("Imagem muito grande. O limite é 5MB.");
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedImageExtensions.Contains(extension))
        {
            throw new ValidationAppException("Formato de imagem não permitido.");
        }

        var webRootPath = _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot");
        var productsPath = Path.Combine(webRootPath, "uploads", "products");
        Directory.CreateDirectory(productsPath);

        var fileName = $"product_{Guid.NewGuid():N}{extension}";
        var destinationPath = Path.Combine(productsPath, fileName);
        await using var destination = System.IO.File.Create(destinationPath);
        await file.CopyToAsync(destination);

        var imageUrl = $"{Request.Scheme}://{Request.Host}/uploads/products/{fileName}";
        return Ok(ApiResponse<object>.SuccessResponse("Imagem enviada com sucesso.", new { imageUrl }));
    }
}
