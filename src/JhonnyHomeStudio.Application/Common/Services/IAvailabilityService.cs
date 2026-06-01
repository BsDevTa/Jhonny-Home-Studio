using JhonnyHomeStudio.Application.Common.Dtos.Availability;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IAvailabilityService
{
    Task<IEnumerable<BusinessHourResponse>> GetBusinessHoursAsync();
    Task<IEnumerable<BusinessHourResponse>> UpdateBusinessHoursAsync(IEnumerable<UpdateBusinessHourRequest> requests);
    Task<IEnumerable<BlockedDateResponse>> GetBlockedDatesAsync();
    Task<BlockedDateResponse?> GetBlockedDateByIdAsync(Guid blockedDateId);
    Task<BlockedDateResponse> CreateBlockedDateAsync(UpsertBlockedDateRequest request);
    Task<BlockedDateResponse> UpdateBlockedDateAsync(Guid blockedDateId, UpsertBlockedDateRequest request);
    Task<bool> DeleteBlockedDateAsync(Guid blockedDateId);
}
