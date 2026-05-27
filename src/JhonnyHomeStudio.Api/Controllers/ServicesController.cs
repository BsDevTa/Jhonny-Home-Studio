using JhonnyHomeStudio.Application.Common.Dtos.Services;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/services")]
public sealed class ServicesController : ControllerBase
{
    private readonly IServiceService _serviceService;

    public ServicesController(IServiceService serviceService)
    {
        _serviceService = serviceService;
    }

    [HttpGet("active")]
    public async Task<IActionResult> GetActive()
    {
        var response = await _serviceService.GetActiveAsync();
        return Ok(ApiResponse<IEnumerable<ServiceResponse>>.SuccessResponse("Serviços ativos localizados com sucesso.", response));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var response = await _serviceService.GetByIdAsync(id);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Serviço não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ServiceResponse>.SuccessResponse("Serviço localizado com sucesso.", response));
    }

    [HttpGet("category/{categoryId:guid}")]
    public async Task<IActionResult> GetByCategory(Guid categoryId)
    {
        var response = await _serviceService.GetByCategoryAsync(categoryId);
        return Ok(ApiResponse<IEnumerable<ServiceResponse>>.SuccessResponse("Serviços da categoria localizados com sucesso.", response));
    }

    [HttpGet("/api/admin/services")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllAdmin()
    {
        var response = await _serviceService.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<ServiceResponse>>.SuccessResponse("Serviços localizados com sucesso.", response));
    }

    [HttpPost("/api/admin/services")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateServiceRequest request)
    {
        var response = await _serviceService.CreateAsync(request);
        return Ok(ApiResponse<ServiceResponse>.SuccessResponse("Serviço criado com sucesso.", response));
    }

    [HttpPut("/api/admin/services/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateServiceRequest request)
    {
        var response = await _serviceService.UpdateAsync(id, request);
        return Ok(ApiResponse<ServiceResponse>.SuccessResponse("Serviço atualizado com sucesso.", response));
    }

    [HttpPatch("/api/admin/services/{id:guid}/activate")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Activate(Guid id)
    {
        var updated = await _serviceService.ActivateAsync(id);
        if (!updated)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Serviço não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Serviço ativado com sucesso.", new { id, isActive = true }));
    }

    [HttpPatch("/api/admin/services/{id:guid}/deactivate")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        var updated = await _serviceService.DeactivateAsync(id);
        if (!updated)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Serviço não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Serviço desativado com sucesso.", new { id, isActive = false }));
    }

    [HttpDelete("/api/admin/services/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var deleted = await _serviceService.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Serviço não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Serviço removido com sucesso.", new { id, isActive = false }));
    }
}