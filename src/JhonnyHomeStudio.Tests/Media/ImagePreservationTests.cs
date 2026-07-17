using JhonnyHomeStudio.Application.Common.Dtos.Marketplace;
using JhonnyHomeStudio.Application.Common.Dtos.Services;
using JhonnyHomeStudio.Application.Common.Dtos.Stories;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using JhonnyHomeStudio.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

using StudioService = JhonnyHomeStudio.Domain.Entities.Service;

namespace JhonnyHomeStudio.Tests.Media;

public sealed class ImagePreservationTests
{
    [Fact]
    public async Task StoryUpdate_PreservesImageUrl_WhenNoNewImageAndNoRemoveCommand()
    {
        await using var dbContext = CreateDbContext();
        var now = DateTime.UtcNow;
        var story = new Story
        {
            CreatedByAdminUserId = Guid.NewGuid(),
            Title = "Story original",
            ShortText = "Descricao original",
            ImageUrl = "/uploads/stories/original.webp",
            StartsAtUtc = now.AddMinutes(-5),
            ExpiresAtUtc = now.AddDays(1),
            IsActive = true,
            SortOrder = 1
        };

        dbContext.Stories.Add(story);
        await dbContext.SaveChangesAsync();

        var storyService = new StoryService(dbContext, NullLogger<StoryService>.Instance);

        var response = await storyService.UpdateAsync(story.Id, new UpdateStoryRequest
        {
            Title = "Story editado",
            Subtitle = "Descricao editada",
            ImageUrl = null,
            RemoveImage = false,
            DisplayOrder = 2,
            IsActive = false
        });

        Assert.Equal("/uploads/stories/original.webp", response.ImageUrl);
        Assert.Equal("Story editado", response.Title);
        Assert.Equal(2, response.DisplayOrder);
        Assert.False(response.IsActive);
    }

    [Fact]
    public async Task ServiceUpdate_PreservesImageUrl_WhenNoNewImageAndNoRemoveCommand()
    {
        await using var dbContext = CreateDbContext();
        var serviceEntity = new StudioService
        {
            Name = "Corte",
            Description = "Original",
            Price = 80,
            ImageUrl = "/uploads/services/original.jpg",
            IsActive = true
        };

        dbContext.Services.Add(serviceEntity);
        await dbContext.SaveChangesAsync();

        var serviceService = new ServiceService(dbContext, NullLogger<ServiceService>.Instance);

        var response = await serviceService.UpdateAsync(serviceEntity.Id, new UpdateServiceRequest
        {
            Name = "Corte atualizado",
            Description = "Descricao atualizada",
            Price = 95,
            ImageUrl = string.Empty,
            RemoveImage = false,
            IsActive = false
        });

        Assert.Equal("/uploads/services/original.jpg", response.ImageUrl);
        Assert.Equal("Corte atualizado", response.Name);
        Assert.Equal(95, response.Price);
        Assert.False(response.IsActive);
    }

    [Fact]
    public async Task ProductUpdate_PreservesMainImage_WhenNoNewImageAndNoRemoveCommand()
    {
        await using var dbContext = CreateDbContext();
        var product = new Product
        {
            Name = "Pomada",
            Description = "Original",
            Price = 49,
            MainImageUrl = "/uploads/products/original.png",
            IsActive = true
        };
        product.Images.Add(new ProductImage
        {
            ProductId = product.Id,
            ImageUrl = "/uploads/products/original.png",
            DisplayOrder = 0,
            IsMain = true
        });

        dbContext.Products.Add(product);
        await dbContext.SaveChangesAsync();

        var marketplaceService = new MarketplaceService(dbContext, NullLogger<MarketplaceService>.Instance);

        var response = await marketplaceService.UpdateProductAsync(product.Id, new UpsertProductRequest
        {
            Name = "Pomada editada",
            Description = "Descricao editada",
            Price = 59,
            MainImageUrl = "null",
            RemoveImage = false,
            IsActive = true,
            IsFeatured = true,
            Images = Array.Empty<UpsertProductImageRequest>()
        });

        Assert.Equal("/uploads/products/original.png", response.MainImageUrl);
        Assert.Contains(response.Images, image => image.ImageUrl == "/uploads/products/original.png");
        Assert.Equal("Pomada editada", response.Name);
        Assert.True(response.IsFeatured);
    }

    private static JhonnyHomeStudioDbContext CreateDbContext()
    {
        var options = new DbContextOptionsBuilder<JhonnyHomeStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new JhonnyHomeStudioDbContext(options);
    }
}
