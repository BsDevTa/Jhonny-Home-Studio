using JhonnyHomeStudio.Application.Common.Dtos.Appointments;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IAppointmentService
{
    Task<AppointmentResponse> CreateMyAppointmentAsync(Guid userId, CreateAppointmentRequest request);
    Task<IEnumerable<AppointmentListResponse>> GetMyAppointmentsAsync(Guid userId);
    Task<AppointmentResponse?> GetMyAppointmentByIdAsync(Guid userId, Guid appointmentId);
    Task<bool> CancelMyAppointmentAsync(Guid userId, Guid appointmentId);
    Task<IEnumerable<AppointmentListResponse>> GetAllForAdminAsync(DateTime? date = null, Guid? customerId = null, Guid? serviceId = null);
    Task<AppointmentResponse?> GetByIdForAdminAsync(Guid appointmentId);
    Task<AppointmentResponse> UpdateStatusForAdminAsync(Guid adminUserId, Guid appointmentId, UpdateAppointmentStatusRequest request);
    Task<IEnumerable<AvailableSlotResponse>> GetAvailableSlotsAsync(Guid serviceId, DateTime date);
}