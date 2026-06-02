using JhonnyHomeStudio.Api.Extensions;
using JhonnyHomeStudio.Application.Common.Dtos.Stories;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/stories")]
public sealed class StoriesController : ControllerBase
{
    private const long MaxImageSizeBytes = 5 * 1024 * 1024;
    private const long MaxMediaSizeBytes = 50 * 1024 * 1024;
    private static readonly HashSet<string> AllowedImageExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    };
    private static readonly HashSet<string> AllowedVideoExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".mp4",
        ".mov",
        ".webm"
    };

    private readonly IStoryService _storyService;
    private readonly IWebHostEnvironment _environment;

    public StoriesController(IStoryService storyService, IWebHostEnvironment environment)
    {
        _storyService = storyService;
        _environment = environment;
    }

    [HttpGet("active")]
    public async Task<IActionResult> GetActive()
    {
        var response = await _storyService.GetActiveAsync();
        return Ok(ApiResponse<IEnumerable<StoryResponse>>.SuccessResponse("Stories ativos localizados com sucesso.", response));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetPublicById(Guid id)
    {
        var response = await _storyService.GetPublicByIdAsync(id);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Story não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Story localizado com sucesso.", response));
    }

    [HttpGet("/api/admin/stories")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllAdmin()
    {
        var response = await _storyService.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<StoryResponse>>.SuccessResponse("Stories localizados com sucesso.", response));
    }

    [HttpGet("/api/admin/stories/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetByIdAdmin(Guid id)
    {
        var response = await _storyService.GetByIdAsync(id);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Story não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Story localizado com sucesso.", response));
    }

    [HttpPost("/api/admin/stories/upload-image")]
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
        var storiesPath = Path.Combine(webRootPath, "uploads", "stories");
        Directory.CreateDirectory(storiesPath);

        var fileName = $"story_{Guid.NewGuid():N}{extension}";
        var destinationPath = Path.Combine(storiesPath, fileName);

        try
        {
            await using var destination = System.IO.File.Create(destinationPath);
            await file.CopyToAsync(destination);
        }
        catch (Exception)
        {
            throw new ValidationAppException("Não foi possível enviar a imagem.");
        }

        var imageUrl = $"{Request.Scheme}://{Request.Host}/uploads/stories/{fileName}";
        return Ok(ApiResponse<object>.SuccessResponse("Imagem enviada com sucesso.", new { imageUrl }));
    }

    [HttpPost("/api/admin/stories/upload-media")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UploadMedia([FromForm] IFormFile? file)
    {
        if (file is null || file.Length == 0)
        {
            throw new ValidationAppException("Arquivo não enviado.");
        }

        if (file.Length > MaxMediaSizeBytes)
        {
            throw new ValidationAppException("Mídia muito grande. O limite é 50MB.");
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        var isImage = AllowedImageExtensions.Contains(extension);
        var isVideo = AllowedVideoExtensions.Contains(extension);
        if (!isImage && !isVideo)
        {
            throw new ValidationAppException("Formato de mídia não permitido.");
        }

        var webRootPath = _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot");
        var storiesPath = Path.Combine(webRootPath, "uploads", "stories");
        Directory.CreateDirectory(storiesPath);

        var fileName = $"story_{Guid.NewGuid():N}{extension}";
        var destinationPath = Path.Combine(storiesPath, fileName);

        try
        {
            await using var destination = System.IO.File.Create(destinationPath);
            await file.CopyToAsync(destination);
        }
        catch (Exception)
        {
            throw new ValidationAppException("Não foi possível enviar a mídia.");
        }

        var mediaUrl = $"{Request.Scheme}://{Request.Host}/uploads/stories/{fileName}";
        var mediaType = isVideo ? "Video" : "Image";
        return Ok(ApiResponse<object>.SuccessResponse("Mídia enviada com sucesso.", new { mediaUrl, mediaType, imageUrl = mediaUrl }));
    }

    [HttpPost("/api/admin/stories")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateStoryRequest request)
    {
        var adminUserId = User.GetUserIdOrThrow();
        var response = await _storyService.CreateAsync(adminUserId, request);
        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Story criado com sucesso.", response));
    }

    [HttpPut("/api/admin/stories/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateStoryRequest request)
    {
        var response = await _storyService.UpdateAsync(id, request);
        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Story atualizado com sucesso.", response));
    }

    [HttpPatch("/api/admin/stories/{id:guid}/toggle-active")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ToggleActive(Guid id)
    {
        var response = await _storyService.ToggleActiveAsync(id);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Story não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Status do story atualizado com sucesso.", response));
    }

    [HttpDelete("/api/admin/stories/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var deleted = await _storyService.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Story não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Story removido com sucesso.", new { id }));
    }
}
