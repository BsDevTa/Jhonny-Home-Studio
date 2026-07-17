using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using JhonnyHomeStudio.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace JhonnyHomeStudio.Tests.Stories;

public sealed class StoryServiceTests
{
    [Fact]
    public async Task GetActiveAsync_MapsImageUrlToPublicResponse()
    {
        var options = new DbContextOptionsBuilder<JhonnyHomeStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        await using var dbContext = new JhonnyHomeStudioDbContext(options);
        var now = DateTime.UtcNow;
        dbContext.Stories.Add(new Story
        {
            CreatedByAdminUserId = Guid.NewGuid(),
            Title = "Loira",
            ShortText = "Destaque",
            ImageUrl = "/uploads/stories/story-test.jpeg",
            StartsAtUtc = now.AddMinutes(-10),
            ExpiresAtUtc = now.AddDays(1),
            IsActive = true,
            SortOrder = 1
        });
        await dbContext.SaveChangesAsync();

        var service = new StoryService(dbContext, NullLogger<StoryService>.Instance);

        var story = Assert.Single(await service.GetActiveAsync());

        Assert.Equal("/uploads/stories/story-test.jpeg", story.ImageUrl);
    }
}
