using System.Security.Claims;
using JhonnyHomeStudio.Api.Extensions;
using JhonnyHomeStudio.Application.Common.Dtos.Customers;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/customers")]
public sealed class CustomersController : ControllerBase
{
    private readonly ICustomerService _customerService;

    public CustomersController(ICustomerService customerService)
    {
        _customerService = customerService;
    }

    [HttpGet("me")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> GetMyProfile()
    {
        var userId = GetAuthenticatedUserId();
        var response = await _customerService.GetMyProfileAsync(userId);
        return Ok(ApiResponse<CustomerProfileResponse>.SuccessResponse("Perfil localizado com sucesso.", response));
    }

    [HttpPut("me")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateCustomerProfileRequest request)
    {
        var userId = GetAuthenticatedUserId();
        var response = await _customerService.UpdateMyProfileAsync(userId, request);
        return Ok(ApiResponse<CustomerProfileResponse>.SuccessResponse("Perfil atualizado com sucesso.", response));
    }

    [HttpGet]
    [Route("/api/admin/customers")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllAdmin()
    {
        var response = await _customerService.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<CustomerListResponse>>.SuccessResponse("Clientes localizados com sucesso.", response));
    }

    [HttpGet]
    [Route("/api/admin/customers/{customerId:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetByIdAdmin(Guid customerId)
    {
        var response = await _customerService.GetByIdAsync(customerId);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Cliente não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<CustomerProfileResponse>.SuccessResponse("Cliente localizado com sucesso.", response));
    }

    [HttpPatch]
    [Route("/api/admin/customers/{customerId:guid}/activate")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ActivateAdmin(Guid customerId)
    {
        var updated = await _customerService.ActivateAsync(customerId);
        if (!updated)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Cliente não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Cliente ativado com sucesso.", new { customerId, isActive = true }));
    }

    [HttpPatch]
    [Route("/api/admin/customers/{customerId:guid}/deactivate")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeactivateAdmin(Guid customerId)
    {
        var updated = await _customerService.DeactivateAsync(customerId);
        if (!updated)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Cliente não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Cliente desativado com sucesso.", new { customerId, isActive = false }));
    }

    private Guid GetAuthenticatedUserId()
    {
        return User.GetUserIdOrThrow();
    }
}