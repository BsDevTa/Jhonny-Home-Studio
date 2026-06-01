using JhonnyHomeStudio.Application.Common.Dtos.Loyalty;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface ILoyaltyService
{
    Task<LoyaltyResponse> GetMyAsync(Guid userId);
    Task<LoyaltyResponse?> GetForAdminAsync(Guid customerId);
    Task AwardForCompletedAppointmentAsync(Guid customerId, Guid appointmentId, decimal servicePrice);
}
