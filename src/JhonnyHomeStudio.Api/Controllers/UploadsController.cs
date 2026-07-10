using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
public sealed class UploadsController : ControllerBase
{
    private readonly IFileStorageService _fileStorage;

    public UploadsController(IFileStorageService fileStorage)
    {
        _fileStorage = fileStorage;
    }

    [HttpGet("/uploads/{**path}")]
    public async Task<IActionResult> GetUpload(string path, CancellationToken cancellationToken)
    {
        var file = await _fileStorage.GetAsync(path, cancellationToken);
        if (file is null)
        {
            return NotFound();
        }

        Response.Headers.CacheControl = "public,max-age=3600";
        return File(file.Content, file.ContentType);
    }
}
