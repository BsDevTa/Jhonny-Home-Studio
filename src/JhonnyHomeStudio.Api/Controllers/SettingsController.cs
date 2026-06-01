using JhonnyHomeStudio.Application.Common.Dtos.Settings;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/settings")]
public sealed class SettingsController : ControllerBase
{
    private readonly IStudioSettingsService _settingsService;

    public SettingsController(IStudioSettingsService settingsService)
    {
        _settingsService = settingsService;
    }

    [HttpGet("public")]
    public async Task<IActionResult> GetPublic()
    {
        var response = await _settingsService.GetPublicAsync();
        return Ok(ApiResponse<PublicStudioSettingsResponse>.SuccessResponse("Configurações públicas localizadas com sucesso.", response));
    }

    [HttpGet("/api/admin/settings")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdmin()
    {
        var response = await _settingsService.GetAdminAsync();
        return Ok(ApiResponse<StudioSettingsResponse>.SuccessResponse("Configurações localizadas com sucesso.", response));
    }

    [HttpPut("/api/admin/settings")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update([FromBody] UpdateStudioSettingsRequest request)
    {
        var response = await _settingsService.UpdateAsync(request);
        return Ok(ApiResponse<StudioSettingsResponse>.SuccessResponse("Configurações atualizadas com sucesso.", response));
    }
}
