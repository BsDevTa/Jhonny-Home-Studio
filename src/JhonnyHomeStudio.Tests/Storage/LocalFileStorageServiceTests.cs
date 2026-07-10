using JhonnyHomeStudio.Infrastructure.Services;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace JhonnyHomeStudio.Tests.Storage;

public sealed class LocalFileStorageServiceTests
{
    [Fact]
    public async Task SaveAsync_WritesFileAndCanReadItBackFromUploadsPath()
    {
        var rootPath = Path.Combine(Path.GetTempPath(), $"jhonny-storage-{Guid.NewGuid():N}");
        Directory.CreateDirectory(rootPath);

        try
        {
            var service = new LocalFileStorageService(
                new TestHostEnvironment(rootPath),
                NullLogger<LocalFileStorageService>.Instance);
            var bytes = new byte[] { 1, 2, 3, 4 };

            await using var stream = new MemoryStream(bytes);
            var result = await service.SaveAsync(
                stream,
                "foto.jpeg",
                "image/jpeg",
                "uploads/stories",
                "story",
                new Uri("https://api.example.com"));

            Assert.True(result.Exists);
            Assert.Equal("Local", result.StorageProvider);
            Assert.Equal("image/jpeg", result.ContentType);
            Assert.Equal(bytes.Length, result.SizeBytes);
            Assert.StartsWith("/uploads/stories/story_", result.RelativePath);
            Assert.EndsWith(".jpeg", result.RelativePath);
            Assert.Equal($"https://api.example.com{result.RelativePath}", result.PublicUrl);
            Assert.True(File.Exists(result.PhysicalPath));

            var download = await service.GetAsync(result.RelativePath);

            Assert.NotNull(download);
            Assert.Equal("image/jpeg", download.ContentType);
            using var memory = new MemoryStream();
            await using (download!.Content)
            {
                await download.Content.CopyToAsync(memory);
            }

            Assert.Equal(bytes, memory.ToArray());
        }
        finally
        {
            if (Directory.Exists(rootPath))
            {
                Directory.Delete(rootPath, recursive: true);
            }
        }
    }

    private sealed class TestHostEnvironment : IHostEnvironment
    {
        public TestHostEnvironment(string contentRootPath)
        {
            ContentRootPath = contentRootPath;
        }

        public string EnvironmentName { get; set; } = "Development";
        public string ApplicationName { get; set; } = "JhonnyHomeStudio.Tests";
        public string ContentRootPath { get; set; }
        public Microsoft.Extensions.FileProviders.IFileProvider ContentRootFileProvider { get; set; } = null!;
    }
}
