using Amazon;
using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class S3FileStorageService : IFileStorageService
{
    private readonly IAmazonS3 _client;
    private readonly ILogger<S3FileStorageService> _logger;
    private readonly string _bucketName;
    private readonly string? _publicBaseUrl;

    public S3FileStorageService(
        IConfiguration configuration,
        ILogger<S3FileStorageService> logger)
    {
        _logger = logger;
        _bucketName = ReadRequired(configuration, "Storage:S3:BucketName", "BUCKET");
        _publicBaseUrl = ReadOptional(configuration, "Storage:S3:PublicBaseUrl", "STORAGE_PUBLIC_BASE_URL");

        var accessKey = ReadRequired(configuration, "Storage:S3:AccessKeyId", "ACCESS_KEY_ID", "AWS_ACCESS_KEY_ID");
        var secretKey = ReadRequired(configuration, "Storage:S3:SecretAccessKey", "SECRET_ACCESS_KEY", "AWS_SECRET_ACCESS_KEY");
        var endpoint = ReadRequired(configuration, "Storage:S3:Endpoint", "ENDPOINT", "AWS_ENDPOINT_URL_S3", "AWS_ENDPOINT_URL");
        var region = ReadOptional(configuration, "Storage:S3:Region", "REGION", "AWS_REGION") ?? "auto";
        var forcePathStyle = bool.TryParse(
            ReadOptional(configuration, "Storage:S3:ForcePathStyle", "S3_FORCE_PATH_STYLE"),
            out var parsedForcePathStyle) && parsedForcePathStyle;

        var config = new AmazonS3Config
        {
            ServiceURL = endpoint,
            AuthenticationRegion = region,
            ForcePathStyle = forcePathStyle,
            UseHttp = endpoint.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
        };

        _client = new AmazonS3Client(new BasicAWSCredentials(accessKey, secretKey), config);
    }

    public async Task<StoredFileResponse> SaveAsync(
        Stream content,
        string originalFileName,
        string contentType,
        string relativeFolder,
        string filePrefix,
        Uri publicOrigin,
        CancellationToken cancellationToken = default)
    {
        var extension = Path.GetExtension(originalFileName).ToLowerInvariant();
        var normalizedFolder = relativeFolder
            .Trim()
            .Trim('/', '\\')
            .Replace('\\', '/');
        var fileName = $"{filePrefix}_{Guid.NewGuid():N}{extension}";
        var relativePath = $"/{normalizedFolder}/{fileName}";
        var objectKey = NormalizeObjectKey(relativePath);

        var normalizedContentType = NormalizeContentType(contentType, extension);
        var putRequest = new PutObjectRequest
        {
            BucketName = _bucketName,
            Key = objectKey,
            InputStream = content,
            ContentType = normalizedContentType,
            AutoCloseStream = false
        };

        await _client.PutObjectAsync(putRequest, cancellationToken);
        var metadata = await _client.GetObjectMetadataAsync(_bucketName, objectKey, cancellationToken);

        if (metadata.ContentLength <= 0)
        {
            throw new IOException($"Objeto S3 {objectKey} foi criado sem conteúdo.");
        }

        var publicUrl = BuildPublicUrl(publicOrigin, relativePath);

        _logger.LogInformation(
            "Upload Story/Media S3: Bucket={Bucket}; ObjectKey={ObjectKey}; PublicUrl={PublicUrl}; Exists={Exists}; SizeBytes={SizeBytes}",
            _bucketName,
            objectKey,
            publicUrl,
            true,
            metadata.ContentLength);

        return new StoredFileResponse
        {
            FileName = fileName,
            RelativePath = relativePath,
            PublicUrl = publicUrl,
            ContentType = normalizedContentType,
            SizeBytes = metadata.ContentLength,
            Exists = true,
            PhysicalPath = $"s3://{_bucketName}/{objectKey}",
            StorageProvider = "S3"
        };
    }

    public async Task<StoredFileDownload?> GetAsync(
        string relativePath,
        CancellationToken cancellationToken = default)
    {
        var objectKey = NormalizeObjectKey(relativePath);
        if (string.IsNullOrWhiteSpace(objectKey))
        {
            return null;
        }

        try
        {
            var response = await _client.GetObjectAsync(_bucketName, objectKey, cancellationToken);
            return new StoredFileDownload
            {
                Content = response.ResponseStream,
                ContentType = string.IsNullOrWhiteSpace(response.Headers.ContentType)
                    ? NormalizeContentType(string.Empty, Path.GetExtension(objectKey))
                    : response.Headers.ContentType,
                SizeBytes = response.Headers.ContentLength
            };
        }
        catch (AmazonS3Exception exception) when (
            exception.StatusCode == System.Net.HttpStatusCode.NotFound ||
            exception.ErrorCode == "NoSuchKey")
        {
            return null;
        }
    }

    public async Task DeleteAsync(
        string fileUrl,
        CancellationToken cancellationToken = default)
    {
        var objectKey = NormalizeObjectKey(ReadPath(fileUrl));
        if (string.IsNullOrWhiteSpace(objectKey))
        {
            return;
        }

        await _client.DeleteObjectAsync(_bucketName, objectKey, cancellationToken);
    }

    private string BuildPublicUrl(Uri publicOrigin, string relativePath)
    {
        if (!string.IsNullOrWhiteSpace(_publicBaseUrl))
        {
            return $"{_publicBaseUrl.TrimEnd('/')}/{relativePath.TrimStart('/')}";
        }

        return new Uri(publicOrigin, relativePath).ToString();
    }

    private static string NormalizeObjectKey(string relativePath)
    {
        var objectKey = relativePath
            .Trim()
            .Trim('/', '\\')
            .Replace('\\', '/');

        if (string.IsNullOrWhiteSpace(objectKey))
        {
            return string.Empty;
        }

        return objectKey.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase)
            ? objectKey
            : $"uploads/{objectKey}";
    }

    private static string ReadPath(string fileUrl)
    {
        if (Uri.TryCreate(fileUrl, UriKind.Absolute, out var uri))
        {
            return uri.LocalPath;
        }

        return fileUrl;
    }

    private static string NormalizeContentType(string contentType, string extension)
    {
        if (!string.IsNullOrWhiteSpace(contentType))
        {
            return contentType;
        }

        return extension.ToLowerInvariant() switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".mp4" => "video/mp4",
            ".mov" => "video/quicktime",
            ".webm" => "video/webm",
            _ => "application/octet-stream"
        };
    }

    private static string ReadRequired(IConfiguration configuration, params string[] keys)
    {
        var value = ReadOptional(configuration, keys);
        if (!string.IsNullOrWhiteSpace(value))
        {
            return value;
        }

        throw new InvalidOperationException($"Configuração de storage ausente. Informe uma destas variáveis: {string.Join(", ", keys)}.");
    }

    private static string? ReadOptional(IConfiguration configuration, params string[] keys)
    {
        foreach (var key in keys)
        {
            var value = configuration[key];
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim();
            }
        }

        return null;
    }
}
