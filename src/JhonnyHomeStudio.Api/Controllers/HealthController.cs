using JhonnyHomeStudio.Application.Common.Responses;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(ApiResponse<object>.SuccessResponse(
            "API Jhonny Home Studio está no ar",
            new { status = "healthy" }));
    }
}