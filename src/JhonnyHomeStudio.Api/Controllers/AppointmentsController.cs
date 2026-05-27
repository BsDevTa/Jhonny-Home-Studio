using JhonnyHomeStudio.Api.Extensions;
using JhonnyHomeStudio.Application.Common.Dtos.Appointments;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/appointments")]
public sealed class AppointmentsController : ControllerBase
{
    private readonly IAppointmentService _appointmentService;

    public AppointmentsController(IAppointmentService appointmentService)
    {
        _appointmentService = appointmentService;
    }

    [HttpGet("my")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> GetMyAppointments()
    {
        var userId = User.GetUserIdOrThrow();
        var response = await _appointmentService.GetMyAppointmentsAsync(userId);
        return Ok(ApiResponse<IEnumerable<AppointmentListResponse>>.SuccessResponse("Agendamentos localizados com sucesso.", response));
    }

    [HttpGet("my/{appointmentId:guid}")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> GetMyAppointmentById(Guid appointmentId)
    {
        var userId = User.GetUserIdOrThrow();
        var response = await _appointmentService.GetMyAppointmentByIdAsync(userId, appointmentId);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Agendamento não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<AppointmentResponse>.SuccessResponse("Agendamento localizado com sucesso.", response));
    }

    [HttpPost]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> Create([FromBody] CreateAppointmentRequest request)
    {
        var userId = User.GetUserIdOrThrow();
        var response = await _appointmentService.CreateMyAppointmentAsync(userId, request);
        return Ok(ApiResponse<AppointmentResponse>.SuccessResponse("Agendamento criado com sucesso.", response));
    }

    [HttpPatch("my/{appointmentId:guid}/cancel")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> Cancel(Guid appointmentId)
    {
        var userId = User.GetUserIdOrThrow();
        var updated = await _appointmentService.CancelMyAppointmentAsync(userId, appointmentId);
        if (!updated)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Agendamento não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<object>.SuccessResponse("Agendamento cancelado com sucesso.", new { appointmentId, status = "Canceled" }));
    }

    [HttpGet("available-slots")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> GetAvailableSlots([FromQuery] Guid serviceId, [FromQuery] DateTime date)
    {
        var response = await _appointmentService.GetAvailableSlotsAsync(serviceId, date);
        return Ok(ApiResponse<IEnumerable<AvailableSlotResponse>>.SuccessResponse("Horários disponíveis localizados com sucesso.", response));
    }

    [HttpGet]
    [Route("/api/admin/appointments")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllForAdmin([FromQuery] DateTime? date = null, [FromQuery] Guid? customerId = null, [FromQuery] Guid? serviceId = null)
    {
        var response = await _appointmentService.GetAllForAdminAsync(date, customerId, serviceId);
        return Ok(ApiResponse<IEnumerable<AppointmentListResponse>>.SuccessResponse("Agendamentos localizados com sucesso.", response));
    }

    [HttpGet]
    [Route("/api/admin/appointments/{appointmentId:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetByIdForAdmin(Guid appointmentId)
    {
        var response = await _appointmentService.GetByIdForAdminAsync(appointmentId);
        if (response is null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("Agendamento não encontrado.", new[] { "Verifique o identificador informado." }));
        }

        return Ok(ApiResponse<AppointmentResponse>.SuccessResponse("Agendamento localizado com sucesso.", response));
    }

    [HttpPatch]
    [Route("/api/admin/appointments/{appointmentId:guid}/status")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateStatusForAdmin(Guid appointmentId, [FromBody] UpdateAppointmentStatusRequest request)
    {
        var adminUserId = User.GetUserIdOrThrow();
        var response = await _appointmentService.UpdateStatusForAdminAsync(adminUserId, appointmentId, request);
        return Ok(ApiResponse<AppointmentResponse>.SuccessResponse("Status do agendamento atualizado com sucesso.", response));
    }
}