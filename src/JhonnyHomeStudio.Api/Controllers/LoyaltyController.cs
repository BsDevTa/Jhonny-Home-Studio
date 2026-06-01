using JhonnyHomeStudio.Api.Extensions;
using JhonnyHomeStudio.Application.Common.Dtos.Loyalty;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/loyalty")]
public sealed class LoyaltyController : ControllerBase
{
    private readonly ILoyaltyService _loyaltyService;

    public LoyaltyController(ILoyaltyService loyaltyService)
    {
        _loyaltyService = loyaltyService;
    }

    [HttpGet("my")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> GetMy()
    {
        var response = await _loyaltyService.GetMyAsync(User.GetUserIdOrThrow());
        return Ok(ApiResponse<LoyaltyResponse>.SuccessResponse("Fidelidade localizada com sucesso.", response));
    }

    [HttpGet("/api/admin/customers/{customerId:guid}/loyalty")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetForAdmin(Guid customerId)
    {
        var response = await _loyaltyService.GetForAdminAsync(customerId);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Cliente não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<LoyaltyResponse>.SuccessResponse("Fidelidade localizada com sucesso.", response));
    }
}
