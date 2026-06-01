using JhonnyHomeStudio.Application.Common.Dtos.Availability;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/admin/availability")]
[Authorize(Roles = "Admin")]
public sealed class AvailabilityController : ControllerBase
{
    private readonly IAvailabilityService _availabilityService;

    public AvailabilityController(IAvailabilityService availabilityService)
    {
        _availabilityService = availabilityService;
    }

    [HttpGet("business-hours")]
    public async Task<IActionResult> GetBusinessHours()
    {
        var response = await _availabilityService.GetBusinessHoursAsync();
        return Ok(ApiResponse<IEnumerable<BusinessHourResponse>>.SuccessResponse("Horários de atendimento localizados com sucesso.", response));
    }

    [HttpPut("business-hours")]
    public async Task<IActionResult> UpdateBusinessHours([FromBody] IEnumerable<UpdateBusinessHourRequest> requests)
    {
        var response = await _availabilityService.UpdateBusinessHoursAsync(requests);
        return Ok(ApiResponse<IEnumerable<BusinessHourResponse>>.SuccessResponse("Horários de atendimento atualizados com sucesso.", response));
    }

    [HttpGet("blocked-dates")]
    public async Task<IActionResult> GetBlockedDates()
    {
        var response = await _availabilityService.GetBlockedDatesAsync();
        return Ok(ApiResponse<IEnumerable<BlockedDateResponse>>.SuccessResponse("Datas bloqueadas localizadas com sucesso.", response));
    }

    [HttpGet("blocked-dates/{blockedDateId:guid}")]
    public async Task<IActionResult> GetBlockedDateById(Guid blockedDateId)
    {
        var response = await _availabilityService.GetBlockedDateByIdAsync(blockedDateId);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Bloqueio não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<BlockedDateResponse>.SuccessResponse("Data bloqueada localizada com sucesso.", response));
    }

    [HttpPost("blocked-dates")]
    public async Task<IActionResult> CreateBlockedDate([FromBody] UpsertBlockedDateRequest request)
    {
        var response = await _availabilityService.CreateBlockedDateAsync(request);
        return Ok(ApiResponse<BlockedDateResponse>.SuccessResponse("Data bloqueada com sucesso.", response));
    }

    [HttpPut("blocked-dates/{blockedDateId:guid}")]
    public async Task<IActionResult> UpdateBlockedDate(Guid blockedDateId, [FromBody] UpsertBlockedDateRequest request)
    {
        var response = await _availabilityService.UpdateBlockedDateAsync(blockedDateId, request);
        return Ok(ApiResponse<BlockedDateResponse>.SuccessResponse("Bloqueio atualizado com sucesso.", response));
    }

    [HttpDelete("blocked-dates/{blockedDateId:guid}")]
    public async Task<IActionResult> DeleteBlockedDate(Guid blockedDateId)
    {
        var deleted = await _availabilityService.DeleteBlockedDateAsync(blockedDateId);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Bloqueio não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Bloqueio excluído com sucesso.", new { blockedDateId }));
    }
}
