using Amazon;
using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Diagnostics;
using System.Net.Http.Headers;
using System.Text.RegularExpressions;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class S3FileStorageService : IFileStorageService
{
    private static readonly TimeSpan StorageOperationTimeout = TimeSpan.FromSeconds(30);
    private static readonly HttpClient StorageApiClient = new()
    {
        Timeout = StorageOperationTimeout
    };

    private readonly IAmazonS3 _client;
    private readonly ILogger<S3FileStorageService> _logger;
    private readonly string _bucketName;
    private readonly string _endpoint;
    private readonly string _serviceUrl;
    private readonly string _authenticationRegion;
    private readonly string _storageProvider;
    private readonly bool _forcePathStyle;
    private readonly string? _publicBaseUrl;

    internal string? SupabaseServiceKey { get; }

    public S3FileStorageService(
        IConfiguration configuration,
        ILogger<S3FileStorageService> logger)
    {
        _logger = logger;
        _bucketName = ReadRequired(configuration, "Storage:S3:BucketName", "BUCKET");
        _publicBaseUrl = ReadOptional(configuration, "Storage:S3:PublicBaseUrl", "STORAGE_PUBLIC_BASE_URL");
        SupabaseServiceKey = ReadOptional(configuration, "Storage:SupabaseServiceKey");
        _storageProvider = ReadOptional(configuration, "STORAGE_PROVIDER", "Storage:Provider") ?? "S3";

        var accessKey = ReadRequired(configuration, "Storage:S3:AccessKeyId", "ACCESS_KEY_ID", "AWS_ACCESS_KEY_ID");
        var secretKey = ReadRequired(configuration, "Storage:S3:SecretAccessKey", "SECRET_ACCESS_KEY", "AWS_SECRET_ACCESS_KEY");
        _endpoint = ReadRequired(configuration, "Storage:S3:Endpoint", "ENDPOINT", "AWS_ENDPOINT_URL_S3", "AWS_ENDPOINT_URL")
            .Trim()
            .TrimEnd('/');
        _authenticationRegion = ReadOptional(configuration, "Storage:S3:Region", "REGION", "AWS_REGION") ?? "auto";
        _forcePathStyle = ResolveForcePathStyle(configuration, _storageProvider);

        // AmazonS3Client resolve a URL de cada requisição combinando ServiceURL + chave do objeto
        // como URI relativa (RFC 3986): sem a barra final, o último segmento do path customizado
        // (ex.: "/storage/v1/s3" do gateway S3 do Supabase) é descartado em vez de preservado.
        _serviceUrl = $"{_endpoint}/";

        var config = new AmazonS3Config
        {
            ServiceURL = _serviceUrl,
            AuthenticationRegion = _authenticationRegion,
            ForcePathStyle = _forcePathStyle,
            UseHttp = _serviceUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase),
            Timeout = StorageOperationTimeout
        };

        _client = new AmazonS3Client(new BasicAWSCredentials(accessKey, secretKey), config);

        _logger.LogInformation(
            "S3 client configuration. Provider={Provider}; ServiceURL={ServiceURL}; AuthenticationRegion={AuthenticationRegion}; ForcePathStyle={ForcePathStyle}; Bucket={Bucket}",
            _storageProvider,
            config.ServiceURL,
            config.AuthenticationRegion,
            config.ForcePathStyle,
            _bucketName);
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
        var normalizedFolder = NormalizePathSegments(relativeFolder);
        var fileName = $"{filePrefix}_{Guid.NewGuid():N}{extension}";
        var relativePath = $"/{normalizedFolder}/{fileName}";
        var objectKey = NormalizeObjectKey(relativePath);

        var normalizedContentType = NormalizeContentType(contentType, extension);
        var stopwatch = Stopwatch.StartNew();
        try
        {
            if (string.IsNullOrWhiteSpace(SupabaseServiceKey))
            {
                throw new StorageUnavailableAppException(
                    "Configuração de autenticação do Supabase Storage ausente.",
                    new[] { "Informe a variável Storage__SupabaseServiceKey." });
            }

            var projectUrl = DeriveSupabaseProjectUrl(_endpoint);
            var objectUrl = BuildStorageObjectUrl(projectUrl, _bucketName, objectKey);

            _logger.LogInformation(
                "Supabase Storage HTTP upload started. Provider={StorageProvider}; ProjectUrl={ProjectUrl}; Bucket={Bucket}; Key={Key}; ContentType={ContentType}; TimeoutSeconds={TimeoutSeconds}",
                _storageProvider,
                projectUrl.GetLeftPart(UriPartial.Authority),
                _bucketName,
                objectKey,
                normalizedContentType,
                StorageOperationTimeout.TotalSeconds);

            _logger.LogInformation(
                "Supabase Storage HTTP operation. Method={Method}; ProjectUrl={ProjectUrl}; Bucket={Bucket}",
                HttpMethod.Post,
                projectUrl.GetLeftPart(UriPartial.Authority),
                _bucketName);

            var uploadStream = new CountingLeaveOpenStream(content);
            using (var request = new HttpRequestMessage(HttpMethod.Post, objectUrl))
            {
                AddSupabaseStorageAuthentication(request);
                request.Content = new StreamContent(uploadStream);
                request.Content.Headers.ContentType = MediaTypeHeaderValue.Parse(normalizedContentType);

                using var response = await StorageApiClient.SendAsync(
                    request,
                    HttpCompletionOption.ResponseHeadersRead,
                    cancellationToken);

                if (!response.IsSuccessStatusCode)
                {
                    var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
                    LogStorageApiFailure(response.StatusCode, errorBody);
                    throw new HttpRequestException(
                        $"Supabase Storage upload returned HTTP {(int)response.StatusCode}.",
                        null,
                        response.StatusCode);
                }
            }

            var sizeBytes = uploadStream.BytesRead;

            if (sizeBytes <= 0)
            {
                throw new IOException($"Objeto Supabase Storage {objectKey} foi criado sem conteúdo.");
            }

            var publicUrl = BuildPublicUrl(publicOrigin, relativePath, objectKey);

            _logger.LogInformation(
                "Storage upload completed. Provider={StorageProvider}; Endpoint={Endpoint}; Bucket={Bucket}; ObjectKey={ObjectKey}; PublicUrl={PublicUrl}; Exists={Exists}; SizeBytes={SizeBytes}; ElapsedMs={ElapsedMs}",
                _storageProvider,
                _endpoint,
                _bucketName,
                objectKey,
                publicUrl,
                true,
                sizeBytes,
                stopwatch.ElapsedMilliseconds);

            return new StoredFileResponse
            {
                FileName = fileName,
                RelativePath = relativePath,
                PublicUrl = publicUrl,
                ContentType = normalizedContentType,
                SizeBytes = sizeBytes,
                Exists = true,
                PhysicalPath = $"s3://{_bucketName}/{objectKey}",
                StorageProvider = _storageProvider
            };
        }
        catch (TaskCanceledException exception)
        {
            _logger.LogError(
                exception,
                "Storage upload timed out. Provider={StorageProvider}; Endpoint={Endpoint}; Bucket={Bucket}; ObjectKey={ObjectKey}; ContentType={ContentType}; ElapsedMs={ElapsedMs}",
                _storageProvider,
                _endpoint,
                _bucketName,
                objectKey,
                normalizedContentType,
                stopwatch.ElapsedMilliseconds);

            throw new StorageTimeoutAppException(
                "Timeout ao enviar mídia para o storage.",
                new[] { "O storage não respondeu dentro de 30 segundos." });
        }
        catch (Exception exception) when (exception is AmazonS3Exception or HttpRequestException or IOException)
        {
            if (exception is AmazonS3Exception s3Exception)
            {
                _logger.LogError(
                    "S3 upload failed. ExceptionType={ExceptionType}; ErrorCode={ErrorCode}; StatusCode={StatusCode}; Message={Message}; RequestId={RequestId}; AmazonId2={AmazonId2}",
                    s3Exception.GetType().Name,
                    s3Exception.ErrorCode,
                    s3Exception.StatusCode,
                    s3Exception.Message,
                    s3Exception.RequestId,
                    s3Exception.AmazonId2);
            }
            else
            {
                _logger.LogError(
                    exception,
                    "Storage upload failed. Provider={StorageProvider}; Endpoint={Endpoint}; Bucket={Bucket}; Key={Key}; ContentType={ContentType}; ElapsedMs={ElapsedMs}; ErrorType={ErrorType}",
                    _storageProvider,
                    _endpoint,
                    _bucketName,
                    objectKey,
                    normalizedContentType,
                    stopwatch.ElapsedMilliseconds,
                    exception.GetType().Name);
            }

            throw new StorageUnavailableAppException(
                "Storage de mídia indisponível.",
                new[] { "Não foi possível gravar o arquivo no storage persistente." });
        }
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

    private string BuildPublicUrl(Uri publicOrigin, string relativePath, string objectKey)
    {
        if (!string.IsNullOrWhiteSpace(_publicBaseUrl))
        {
            return $"{_publicBaseUrl.Trim().TrimEnd('/')}/{objectKey.TrimStart('/')}";
        }

        return new Uri(publicOrigin, relativePath).ToString();
    }

    private void AddSupabaseStorageAuthentication(HttpRequestMessage request)
    {
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", SupabaseServiceKey);
        request.Headers.Add("apikey", SupabaseServiceKey);
    }

    private void LogStorageApiFailure(System.Net.HttpStatusCode statusCode, string responseBody)
    {
        var safeBody = SanitizeStorageErrorBody(responseBody, SupabaseServiceKey);
        _logger.LogError(
            "Supabase Storage HTTP request failed. StatusCode={StatusCode}; ErrorBody={ErrorBody}",
            (int)statusCode,
            safeBody);
    }

    private static string SanitizeStorageErrorBody(string responseBody, string? serviceKey)
    {
        var safeBody = responseBody;
        if (!string.IsNullOrEmpty(serviceKey))
        {
            safeBody = safeBody.Replace(serviceKey, "[REDACTED]", StringComparison.Ordinal);
        }

        safeBody = Regex.Replace(
            safeBody,
            @"(?i)(bearer\s+)[A-Za-z0-9._~+/=-]+",
            "$1[REDACTED]");
        safeBody = Regex.Replace(
            safeBody,
            @"(?i)(authorization|apikey|access[_-]?key|secret[_-]?key|token|signature)(""?\s*[:=]\s*""?)[^""\s,}]+",
            "$1$2[REDACTED]");

        return safeBody.Length <= 1024 ? safeBody : safeBody[..1024];
    }

    private static Uri DeriveSupabaseProjectUrl(string storageEndpoint)
    {
        if (!Uri.TryCreate(storageEndpoint, UriKind.Absolute, out var endpointUri) ||
            !endpointUri.Scheme.Equals(Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase))
        {
            throw new StorageUnavailableAppException(
                "Endpoint do Supabase Storage inválido.",
                new[] { "O endpoint configurado deve usar HTTPS e o domínio S3 do Supabase." });
        }

        const string storageDomainSuffix = ".storage.supabase.co";
        var endpointHost = endpointUri.IdnHost;
        if (!endpointHost.EndsWith(storageDomainSuffix, StringComparison.OrdinalIgnoreCase))
        {
            throw new StorageUnavailableAppException(
                "Não foi possível derivar a URL do projeto Supabase.",
                new[] { "Configure o endpoint S3 no formato https://{project-ref}.storage.supabase.co." });
        }

        var projectRef = endpointHost[..^storageDomainSuffix.Length];
        if (string.IsNullOrWhiteSpace(projectRef) ||
            projectRef.Any(character => !char.IsAsciiLetterOrDigit(character) && character != '-'))
        {
            throw new StorageUnavailableAppException(
                "Não foi possível derivar a URL do projeto Supabase.",
                new[] { "O host do endpoint S3 não contém um identificador de projeto Supabase válido." });
        }

        return new Uri($"https://{projectRef}.supabase.co/");
    }

    private static Uri BuildStorageObjectUrl(Uri projectUrl, string bucketName, string objectKey)
    {
        var escapedBucket = Uri.EscapeDataString(bucketName);
        var escapedKey = string.Join(
            '/',
            objectKey.Split('/', StringSplitOptions.RemoveEmptyEntries)
                .Select(Uri.EscapeDataString));

        return new Uri(projectUrl, $"storage/v1/object/{escapedBucket}/{escapedKey}");
    }

    private sealed class CountingLeaveOpenStream(Stream innerStream) : Stream
    {
        private long _bytesRead;

        public long BytesRead => Interlocked.Read(ref _bytesRead);
        public override bool CanRead => innerStream.CanRead;
        public override bool CanSeek => innerStream.CanSeek;
        public override bool CanWrite => false;
        public override long Length => innerStream.Length;
        public override long Position
        {
            get => innerStream.Position;
            set => innerStream.Position = value;
        }

        public override void Flush() => innerStream.Flush();
        public override int Read(byte[] buffer, int offset, int count)
        {
            var bytesRead = innerStream.Read(buffer, offset, count);
            Interlocked.Add(ref _bytesRead, bytesRead);
            return bytesRead;
        }

        public override int Read(Span<byte> buffer)
        {
            var bytesRead = innerStream.Read(buffer);
            Interlocked.Add(ref _bytesRead, bytesRead);
            return bytesRead;
        }

        public override async ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default)
        {
            var bytesRead = await innerStream.ReadAsync(buffer, cancellationToken);
            Interlocked.Add(ref _bytesRead, bytesRead);
            return bytesRead;
        }

        public override async Task<int> ReadAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            var bytesRead = await innerStream.ReadAsync(buffer, offset, count, cancellationToken);
            Interlocked.Add(ref _bytesRead, bytesRead);
            return bytesRead;
        }
        public override long Seek(long offset, SeekOrigin origin) => innerStream.Seek(offset, origin);
        public override void SetLength(long value) => throw new NotSupportedException();
        public override void Write(byte[] buffer, int offset, int count) => throw new NotSupportedException();

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
        }
    }

    private static string NormalizeObjectKey(string relativePath)
    {
        var objectKey = NormalizePathSegments(relativePath);

        if (string.IsNullOrWhiteSpace(objectKey))
        {
            return string.Empty;
        }

        return objectKey.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase)
            ? objectKey
            : $"uploads/{objectKey}";
    }

    private static string NormalizePathSegments(string value)
    {
        return string.Join(
            '/',
            value
                .Trim()
                .Trim('/', '\\')
                .Replace('\\', '/')
                .Split('/', StringSplitOptions.RemoveEmptyEntries));
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

        throw new StorageUnavailableAppException(
            "Configuração de storage ausente.",
            new[] { $"Informe uma destas variáveis: {string.Join(", ", keys)}." });
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

    private static bool ResolveForcePathStyle(IConfiguration configuration, string storageProvider)
    {
        var configured = ReadOptional(configuration, "Storage:S3:ForcePathStyle", "S3_FORCE_PATH_STYLE");
        if (bool.TryParse(configured, out var parsedForcePathStyle))
        {
            return parsedForcePathStyle;
        }

        return storageProvider.Equals("RailwayBucket", StringComparison.OrdinalIgnoreCase) ||
            !string.IsNullOrWhiteSpace(configuration["BUCKET"]);
    }

}
