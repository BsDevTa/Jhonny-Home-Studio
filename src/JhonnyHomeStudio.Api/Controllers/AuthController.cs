using JhonnyHomeStudio.Application.Common.Dtos.Auth;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register-customer")]
    [AllowAnonymous]
    public async Task<IActionResult> RegisterCustomer([FromBody] RegisterCustomerRequest request, CancellationToken cancellationToken)
    {
        var response = await _authService.RegisterCustomerAsync(request, cancellationToken);
        return Ok(ApiResponse<AuthResponse>.SuccessResponse("Cliente cadastrado com sucesso.", response));
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
    {
        var response = await _authService.LoginAsync(request, cancellationToken);
        return Ok(ApiResponse<AuthResponse>.SuccessResponse("Login realizado com sucesso.", response));
    }
}