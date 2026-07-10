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
    private readonly IFileStorageService _fileStorage;
    private readonly ILogger<StoriesController> _logger;

    public StoriesController(
        IStoryService storyService,
        IFileStorageService fileStorage,
        ILogger<StoriesController> logger)
    {
        _storyService = storyService;
        _fileStorage = fileStorage;
        _logger = logger;
    }

    [HttpGet("active")]
    public async Task<IActionResult> GetActive()
    {
        var response = await _storyService.GetActiveAsync();
        return Ok(ApiResponse<IEnumerable<StoryResponse>>.SuccessResponse("Stories ativos localizados com sucesso.", NormalizeStories(response)));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetPublicById(Guid id)
    {
        var response = await _storyService.GetPublicByIdAsync(id);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Story não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Story localizado com sucesso.", NormalizeStory(response)));
    }

    [HttpGet("/api/admin/stories")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllAdmin()
    {
        var response = await _storyService.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<StoryResponse>>.SuccessResponse("Stories localizados com sucesso.", NormalizeStories(response)));
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

        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Story localizado com sucesso.", NormalizeStory(response)));
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

        try
        {
            await using var stream = file.OpenReadStream();
            var storedFile = await _fileStorage.SaveAsync(
                stream,
                file.FileName,
                file.ContentType,
                "uploads/stories",
                "story",
                GetPublicOrigin());

            return Ok(ApiResponse<object>.SuccessResponse(
                "Imagem enviada com sucesso.",
                BuildUploadResponse(storedFile, "Image")));
        }
        catch (Exception exception)
        {
            _logger.LogError(exception, "Falha ao salvar imagem do story. FileName={FileName}; ContentType={ContentType}; Length={Length}", file.FileName, file.ContentType, file.Length);
            throw new ValidationAppException("Não foi possível enviar a imagem.");
        }
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

        try
        {
            await using var stream = file.OpenReadStream();
            var storedFile = await _fileStorage.SaveAsync(
                stream,
                file.FileName,
                file.ContentType,
                "uploads/stories",
                "story",
                GetPublicOrigin());

            var mediaType = isVideo ? "Video" : "Image";
            return Ok(ApiResponse<object>.SuccessResponse(
                "Mídia enviada com sucesso.",
                BuildUploadResponse(storedFile, mediaType)));
        }
        catch (Exception exception)
        {
            _logger.LogError(exception, "Falha ao salvar mídia do story. FileName={FileName}; ContentType={ContentType}; Length={Length}", file.FileName, file.ContentType, file.Length);
            throw new ValidationAppException("Não foi possível enviar a mídia.");
        }
    }

    [HttpPost("/api/admin/stories")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateStoryRequest request)
    {
        var adminUserId = User.GetUserIdOrThrow();
        var response = await _storyService.CreateAsync(adminUserId, request);
        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Story criado com sucesso.", NormalizeStory(response)));
    }

    [HttpPut("/api/admin/stories/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateStoryRequest request)
    {
        var response = await _storyService.UpdateAsync(id, request);
        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Story atualizado com sucesso.", NormalizeStory(response)));
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

        return Ok(ApiResponse<StoryResponse>.SuccessResponse("Status do story atualizado com sucesso.", NormalizeStory(response)));
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

    private Uri GetPublicOrigin()
    {
        return new Uri($"{Request.Scheme}://{Request.Host}");
    }

    private IEnumerable<StoryResponse> NormalizeStories(IEnumerable<StoryResponse> stories)
    {
        return stories.Select(NormalizeStory).ToArray();
    }

    private StoryResponse NormalizeStory(StoryResponse story)
    {
        story.ImageUrl = ResolveUrl(story.ImageUrl);
        return story;
    }

    private string? ResolveUrl(string? value)
    {
        var url = value?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(url) || Uri.TryCreate(url, UriKind.Absolute, out _))
        {
            return value;
        }

        var path = url.StartsWith('/') ? url : $"/{url}";
        return new Uri(GetPublicOrigin(), path).ToString();
    }

    private static object BuildUploadResponse(StoredFileResponse storedFile, string mediaType)
    {
        return new
        {
            success = storedFile.Exists,
            url = storedFile.PublicUrl,
            imageUrl = storedFile.PublicUrl,
            mediaUrl = storedFile.PublicUrl,
            relativePath = storedFile.RelativePath,
            fileName = storedFile.FileName,
            contentType = storedFile.ContentType,
            sizeBytes = storedFile.SizeBytes,
            mediaType,
            storageProvider = storedFile.StorageProvider
        };
    }
}
