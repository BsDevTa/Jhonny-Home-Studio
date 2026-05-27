using JhonnyHomeStudio.Application.Common.Dtos.ServiceCategories;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/service-categories")]
public sealed class ServiceCategoriesController : ControllerBase
{
    private readonly IServiceCategoryService _serviceCategoryService;

    public ServiceCategoriesController(IServiceCategoryService serviceCategoryService)
    {
        _serviceCategoryService = serviceCategoryService;
    }

    [HttpGet("active")]
    public async Task<IActionResult> GetActive()
    {
        var response = await _serviceCategoryService.GetActiveAsync();
        return Ok(ApiResponse<IEnumerable<ServiceCategoryResponse>>.SuccessResponse("Categorias ativas localizadas com sucesso.", response));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var response = await _serviceCategoryService.GetByIdAsync(id);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Categoria não encontrada.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<ServiceCategoryResponse>.SuccessResponse("Categoria localizada com sucesso.", response));
    }

    [HttpGet("/api/admin/service-categories")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllAdmin()
    {
        var response = await _serviceCategoryService.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<ServiceCategoryResponse>>.SuccessResponse("Categorias localizadas com sucesso.", response));
    }

    [HttpPost("/api/admin/service-categories")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateServiceCategoryRequest request)
    {
        var response = await _serviceCategoryService.CreateAsync(request);
        return Ok(ApiResponse<ServiceCategoryResponse>.SuccessResponse("Categoria criada com sucesso.", response));
    }

    [HttpPut("/api/admin/service-categories/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateServiceCategoryRequest request)
    {
        var response = await _serviceCategoryService.UpdateAsync(id, request);
        return Ok(ApiResponse<ServiceCategoryResponse>.SuccessResponse("Categoria atualizada com sucesso.", response));
    }

    [HttpPatch("/api/admin/service-categories/{id:guid}/activate")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Activate(Guid id)
    {
        var updated = await _serviceCategoryService.ActivateAsync(id);
        if (!updated)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Categoria não encontrada.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Categoria ativada com sucesso.", new { id, isActive = true }));
    }

    [HttpPatch("/api/admin/service-categories/{id:guid}/deactivate")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        var updated = await _serviceCategoryService.DeactivateAsync(id);
        if (!updated)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Categoria não encontrada.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Categoria desativada com sucesso.", new { id, isActive = false }));
    }

    [HttpDelete("/api/admin/service-categories/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var deleted = await _serviceCategoryService.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Categoria não encontrada.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Categoria removida com sucesso.", new { id, isActive = false }));
    }
}