using JhonnyHomeStudio.Application.Common.Dtos.Settings;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IStudioSettingsService
{
    Task<PublicStudioSettingsResponse> GetPublicAsync();
    Task<StudioSettingsResponse> GetAdminAsync();
    Task<StudioSettingsResponse> UpdateAsync(UpdateStudioSettingsRequest request);
}
