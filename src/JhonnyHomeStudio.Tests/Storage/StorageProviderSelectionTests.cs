using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Infrastructure.Persistence;
using JhonnyHomeStudio.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Xunit;

namespace JhonnyHomeStudio.Tests.Storage;

public sealed class StorageProviderSelectionTests
{
    [Fact]
    public async Task ProductionWithRailwayBucketMissingSettings_DoesNotFailStartupAndResolvesUnavailableStorage()
    {
        await using var provider = BuildProvider(
            environmentName: "Production",
            new Dictionary<string, string?>
            {
                ["STORAGE_PROVIDER"] = "RailwayBucket"
            });

        foreach (var hostedService in provider.GetServices<IHostedService>())
        {
            await hostedService.StartAsync(CancellationToken.None);
        }

        var storage = provider.GetRequiredService<IFileStorageService>();

        Assert.IsType<UnavailableFileStorageService>(storage);

        await using var stream = new MemoryStream(new byte[] { 1, 2, 3 });
        var exception = await Assert.ThrowsAsync<StorageUnavailableAppException>(() =>
            storage.SaveAsync(
                stream,
                "foto.png",
                "image/png",
                "uploads/stories",
                "story",
                new Uri("https://api.example.com")));

        Assert.Equal("O armazenamento de mídia não está configurado.", exception.Message);
    }

    [Fact]
    public async Task ProductionWithoutPersistentStorage_DoesNotUseLocalFallback()
    {
        await using var provider = BuildProvider(
            environmentName: "Production",
            new Dictionary<string, string?>());

        foreach (var hostedService in provider.GetServices<IHostedService>())
        {
            await hostedService.StartAsync(CancellationToken.None);
        }

        var storage = provider.GetRequiredService<IFileStorageService>();

        Assert.IsType<UnavailableFileStorageService>(storage);
    }

    [Fact]
    public void ProductionWithRailwayBucketConfigured_ResolvesS3Storage()
    {
        using var provider = BuildProvider(
            environmentName: "Production",
            new Dictionary<string, string?>
            {
                ["STORAGE_PROVIDER"] = "RailwayBucket",
                ["BUCKET"] = "johnny-home-studio-test",
                ["ENDPOINT"] = "https://storage.railway.app",
                ["ACCESS_KEY_ID"] = "test-access-key",
                ["SECRET_ACCESS_KEY"] = "test-secret-key"
            });

        var storage = provider.GetRequiredService<IFileStorageService>();

        Assert.IsType<S3FileStorageService>(storage);
    }

    [Fact]
    public void DevelopmentWithoutPersistentStorage_KeepsLocalStorage()
    {
        using var provider = BuildProvider(
            environmentName: "Development",
            new Dictionary<string, string?>());

        var storage = provider.GetRequiredService<IFileStorageService>();

        Assert.IsType<LocalFileStorageService>(storage);
    }

    private static ServiceProvider BuildProvider(
        string environmentName,
        IDictionary<string, string?> values)
    {
        var configurationValues = new Dictionary<string, string?>(values)
        {
            ["ConnectionStrings:DefaultConnection"] = "Host=localhost;Database=jhonny_tests;Username=test;Password=test",
            ["JwtSettings:SecretKey"] = "test-secret-key-with-at-least-32-characters",
            ["JwtSettings:Issuer"] = "JhonnyHomeStudio.Tests",
            ["JwtSettings:Audience"] = "JhonnyHomeStudio.Tests"
        };
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(configurationValues)
            .Build();
        var services = new ServiceCollection();

        services.AddLogging();
        services.AddSingleton<IConfiguration>(configuration);
        services.AddSingleton<IHostEnvironment>(new TestHostEnvironment(environmentName));
        services.AddInfrastructure(configuration);

        return services.BuildServiceProvider();
    }

    private sealed class TestHostEnvironment : IHostEnvironment
    {
        public TestHostEnvironment(string environmentName)
        {
            EnvironmentName = environmentName;
            ContentRootPath = Path.GetTempPath();
        }

        public string EnvironmentName { get; set; }
        public string ApplicationName { get; set; } = "JhonnyHomeStudio.Tests";
        public string ContentRootPath { get; set; }
        public Microsoft.Extensions.FileProviders.IFileProvider ContentRootFileProvider { get; set; } = null!;
    }
}
