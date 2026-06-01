using JhonnyHomeStudio.Application.Common.Dtos.Stories;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IStoryService
{
    Task<IEnumerable<StoryResponse>> GetActiveAsync();
    Task<StoryResponse?> GetPublicByIdAsync(Guid id);
    Task<IEnumerable<StoryResponse>> GetAllAsync();
    Task<StoryResponse?> GetByIdAsync(Guid id);
    Task<StoryResponse> CreateAsync(Guid adminUserId, CreateStoryRequest request);
    Task<StoryResponse> UpdateAsync(Guid id, UpdateStoryRequest request);
    Task<StoryResponse?> ToggleActiveAsync(Guid id);
    Task<bool> DeleteAsync(Guid id);
}
