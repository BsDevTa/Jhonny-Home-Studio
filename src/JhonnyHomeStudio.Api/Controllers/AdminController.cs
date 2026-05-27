using JhonnyHomeStudio.Application.Common.Responses;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "Admin")]
public sealed class AdminController : ControllerBase
{
    [HttpGet("test")]
    public IActionResult Test()
    {
        return Ok(ApiResponse<object>.SuccessResponse("Acesso administrativo autorizado.", new { role = "Admin" }));
    }
}