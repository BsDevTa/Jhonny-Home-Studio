using JhonnyHomeStudio.Application.Common.Responses;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/customer")]
[Authorize(Roles = "Customer")]
public sealed class CustomerController : ControllerBase
{
    [HttpGet("test")]
    public IActionResult Test()
    {
        return Ok(ApiResponse<object>.SuccessResponse("Acesso de cliente autorizado.", new { role = "Customer" }));
    }
}