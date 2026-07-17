using JhonnyHomeStudio.Api.Extensions;
using JhonnyHomeStudio.Api.Helpers;
using JhonnyHomeStudio.Application.Common.Dtos.Stories;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/stories")]
public sealed class StoriesController : ControllerBase
{
    private readonly IStoryService _storyService;
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<StoriesController> _logger;

    public StoriesController(
        IStoryService storyService,
        IServiceProvider serviceProvider,
        ILogger<StoriesController> logger)
    {
        _storyService = storyService;
        _serviceProvider = serviceProvider;
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
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadImage([FromForm] IFormFile? file, CancellationToken cancellationToken)
    {
        LogUploadEndpointStarted("stories", file);
        var fileStorage = ResolveFileStorage("stories");
        var response = await MediaUploadHelper.SaveAsync(
            file,
            MediaUploadHelper.StoryImage,
            fileStorage,
            GetPublicOrigin(),
            _logger,
            cancellationToken);

        _logger.LogInformation("Upload endpoint returning success. Folder={Folder}; TraceId={TraceId}", "stories", HttpContext.TraceIdentifier);
        return Ok(response);
    }

    [HttpPost("/api/admin/stories/upload-media")]
    [Authorize(Roles = "Admin")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadMedia(
        [FromForm] IFormFile? file,
        [FromForm] string? folder,
        CancellationToken cancellationToken)
    {
        LogUploadEndpointStarted(folder, file);
        var target = MediaUploadHelper.ResolveTarget(folder);
        _logger.LogInformation(
            "Upload endpoint target resolved. RequestedFolder={RequestedFolder}; TargetFolder={TargetFolder}; TraceId={TraceId}",
            folder,
            target.RelativeFolder,
            HttpContext.TraceIdentifier);
        var fileStorage = ResolveFileStorage(target.FormValue);

        var response = await MediaUploadHelper.SaveAsync(
            file,
            target,
            fileStorage,
            GetPublicOrigin(),
            _logger,
            cancellationToken);

        _logger.LogInformation("Upload endpoint returning success. Folder={Folder}; TraceId={TraceId}", target.FormValue, HttpContext.TraceIdentifier);
        return Ok(response);
    }

    private void LogUploadEndpointStarted(string? folder, IFormFile? file)
    {
        _logger.LogInformation(
            "Upload endpoint started. Path={Path}; RequestedFolder={RequestedFolder}; HasFile={HasFile}; FileName={FileName}; ContentType={ContentType}; Length={Length}; RequestContentLength={RequestContentLength}; TraceId={TraceId}",
            Request.Path,
            folder,
            file is not null,
            file?.FileName,
            file?.ContentType,
            file?.Length,
            Request.ContentLength,
            HttpContext.TraceIdentifier);
    }

    private IFileStorageService ResolveFileStorage(string folder)
    {
        _logger.LogInformation("Resolving file storage. Folder={Folder}; TraceId={TraceId}", folder, HttpContext.TraceIdentifier);
        var fileStorage = _serviceProvider.GetRequiredService<IFileStorageService>();
        _logger.LogInformation(
            "Resolved storage implementation: {StorageType}. Folder={Folder}; TraceId={TraceId}",
            fileStorage.GetType().Name,
            folder,
            HttpContext.TraceIdentifier);
        return fileStorage;
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

}
