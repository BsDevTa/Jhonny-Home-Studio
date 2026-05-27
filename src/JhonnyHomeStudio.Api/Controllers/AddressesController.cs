using JhonnyHomeStudio.Api.Extensions;
using JhonnyHomeStudio.Application.Common.Dtos.Addresses;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/customers/me/addresses")]
public sealed class AddressesController : ControllerBase
{
    private readonly IAddressService _addressService;

    public AddressesController(IAddressService addressService)
    {
        _addressService = addressService;
    }

    [HttpGet]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> GetMyAddresses()
    {
        var userId = GetAuthenticatedUserId();
        var response = await _addressService.GetMyAddressesAsync(userId);
        return Ok(ApiResponse<IEnumerable<AddressResponse>>.SuccessResponse("Endereços localizados com sucesso.", response));
    }

    [HttpGet("{addressId:guid}")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> GetMyAddressById(Guid addressId)
    {
        var userId = GetAuthenticatedUserId();
        var response = await _addressService.GetMyAddressByIdAsync(userId, addressId);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Endereço não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<AddressResponse>.SuccessResponse("Endereço localizado com sucesso.", response));
    }

    [HttpPost]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> Create([FromBody] CreateAddressRequest request)
    {
        var userId = GetAuthenticatedUserId();
        var response = await _addressService.CreateMyAddressAsync(userId, request);
        return Ok(ApiResponse<AddressResponse>.SuccessResponse("Endereço cadastrado com sucesso.", response));
    }

    [HttpPut("{addressId:guid}")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> Update(Guid addressId, [FromBody] UpdateAddressRequest request)
    {
        var userId = GetAuthenticatedUserId();
        var response = await _addressService.UpdateMyAddressAsync(userId, addressId, request);
        return Ok(ApiResponse<AddressResponse>.SuccessResponse("Endereço atualizado com sucesso.", response));
    }

    [HttpPatch("{addressId:guid}/set-default")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> SetDefault(Guid addressId)
    {
        var userId = GetAuthenticatedUserId();
        var updated = await _addressService.SetDefaultAddressAsync(userId, addressId);
        if (!updated)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Endereço não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Endereço definido como padrão com sucesso.", new { addressId, isDefault = true }));
    }

    [HttpDelete("{addressId:guid}")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> Delete(Guid addressId)
    {
        var userId = GetAuthenticatedUserId();
        var deleted = await _addressService.DeleteMyAddressAsync(userId, addressId);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Endereço não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Endereço removido com sucesso.", new { addressId }));
    }

    [HttpGet]
    [Route("/api/admin/customers/{customerId:guid}/addresses")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetByCustomerIdForAdmin(Guid customerId)
    {
        var response = await _addressService.GetAddressesByCustomerIdForAdminAsync(customerId);
        return Ok(ApiResponse<IEnumerable<AddressResponse>>.SuccessResponse("Endereços localizados com sucesso.", response));
    }

    private Guid GetAuthenticatedUserId()
    {
        return User.GetUserIdOrThrow();
    }
}