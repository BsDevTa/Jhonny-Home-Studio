using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;

namespace JhonnyHomeStudio.Api.Helpers;

public static class MediaUploadHelper
{
    private static readonly TimeSpan StorageUploadTimeout = TimeSpan.FromSeconds(30);

    private static readonly HashSet<string> AllowedImageExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    };

    private static readonly HashSet<string> AllowedVideoExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".mp4",
        ".mov",
        ".webm"
    };

    public static readonly MediaUploadTarget StoryImage = new(
        FormValue: "stories",
        RelativeFolder: "uploads/stories",
        FilePrefix: "story",
        MaxSizeBytes: 5 * 1024 * 1024,
        AllowsVideo: false,
        TooLargeMessage: "Imagem muito grande. O limite é 5MB.",
        InvalidFormatMessage: "Formato de imagem não permitido.",
        FailureMessage: "Não foi possível enviar a imagem.",
        SuccessMessage: "Imagem enviada com sucesso.");

    public static readonly MediaUploadTarget StoryMedia = StoryImage with
    {
        MaxSizeBytes = 50 * 1024 * 1024,
        AllowsVideo = true,
        TooLargeMessage = "Mídia muito grande. O limite é 50MB.",
        InvalidFormatMessage = "Formato de mídia não permitido.",
        FailureMessage = "Não foi possível enviar a mídia.",
        SuccessMessage = "Mídia enviada com sucesso."
    };

    public static readonly MediaUploadTarget ProductImage = new(
        FormValue: "products",
        RelativeFolder: "uploads/products",
        FilePrefix: "product",
        MaxSizeBytes: 5 * 1024 * 1024,
        AllowsVideo: false,
        TooLargeMessage: "Imagem muito grande. O limite é 5MB.",
        InvalidFormatMessage: "Formato de imagem não permitido.",
        FailureMessage: "Não foi possível enviar a imagem.",
        SuccessMessage: "Imagem enviada com sucesso.");

    public static readonly MediaUploadTarget ServiceImage = new(
        FormValue: "services",
        RelativeFolder: "uploads/services",
        FilePrefix: "service",
        MaxSizeBytes: 10 * 1024 * 1024,
        AllowsVideo: false,
        TooLargeMessage: "Imagem muito grande. O limite é 10MB.",
        InvalidFormatMessage: "Arquivo inválido. Envie uma imagem JPG, JPEG, PNG ou WEBP.",
        FailureMessage: "Não foi possível enviar a imagem.",
        SuccessMessage: "Imagem enviada com sucesso.");

    public static MediaUploadTarget ResolveTarget(string? folder)
    {
        var normalized = (folder ?? string.Empty).Trim().Trim('/', '\\').ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(normalized) || normalized is "story" or "stories")
        {
            return StoryMedia;
        }

        return normalized switch
        {
            "service" or "services" => ServiceImage,
            "product" or "products" => ProductImage,
            _ => throw new ValidationAppException("Destino de upload inválido.", new[] { "Use stories, services ou products." })
        };
    }

    public static async Task<ApiResponse<object>> SaveAsync(
        IFormFile? file,
        MediaUploadTarget target,
        IFileStorageService fileStorage,
        Uri publicOrigin,
        ILogger logger,
        CancellationToken cancellationToken = default)
    {
        logger.LogInformation(
            "Upload helper started. Folder={Folder}; FileReceived={FileReceived}; FileName={FileName}; ContentType={ContentType}; Length={Length}",
            target.RelativeFolder,
            file is not null,
            file?.FileName,
            file?.ContentType,
            file?.Length);

        if (file is null || file.Length == 0)
        {
            logger.LogWarning("Upload validation failed. Folder={Folder}; Reason=MissingFile", target.RelativeFolder);
            throw new ValidationAppException("Arquivo não enviado.");
        }

        logger.LogInformation(
            "Upload validation started. Folder={Folder}; FileName={FileName}; ContentType={ContentType}; Length={Length}; MaxSizeBytes={MaxSizeBytes}",
            target.RelativeFolder,
            file.FileName,
            file.ContentType,
            file.Length,
            target.MaxSizeBytes);

        if (file.Length > target.MaxSizeBytes)
        {
            logger.LogWarning(
                "Upload validation failed. Folder={Folder}; Reason=TooLarge; Length={Length}; MaxSizeBytes={MaxSizeBytes}",
                target.RelativeFolder,
                file.Length,
                target.MaxSizeBytes);
            throw new PayloadTooLargeAppException(target.TooLargeMessage, new[] { target.TooLargeMessage });
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        var isImage = AllowedImageExtensions.Contains(extension);
        var isVideo = target.AllowsVideo && AllowedVideoExtensions.Contains(extension);
        if (!isImage && !isVideo)
        {
            logger.LogWarning(
                "Upload validation failed. Folder={Folder}; Reason=UnsupportedExtension; Extension={Extension}; ContentType={ContentType}",
                target.RelativeFolder,
                extension,
                file.ContentType);
            throw new UnsupportedMediaTypeAppException(target.InvalidFormatMessage, new[] { target.InvalidFormatMessage });
        }

        logger.LogInformation(
            "Upload validation completed. Folder={Folder}; Extension={Extension}; MediaKind={MediaKind}",
            target.RelativeFolder,
            extension,
            isVideo ? "Video" : "Image");

        try
        {
            await using var stream = file.OpenReadStream();
            if (stream.CanSeek)
            {
                stream.Position = 0;
            }

            using var timeoutCancellationTokenSource = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeoutCancellationTokenSource.CancelAfter(StorageUploadTimeout);

            logger.LogInformation(
                "Upload storage call starting. Folder={Folder}; FileName={FileName}; ContentType={ContentType}; Length={Length}; TimeoutSeconds={TimeoutSeconds}; StreamCanSeek={StreamCanSeek}; StreamPosition={StreamPosition}",
                target.RelativeFolder,
                file.FileName,
                file.ContentType,
                file.Length,
                StorageUploadTimeout.TotalSeconds,
                stream.CanSeek,
                stream.CanSeek ? stream.Position : null);

            var storedFile = await fileStorage.SaveAsync(
                stream,
                file.FileName,
                file.ContentType,
                target.RelativeFolder,
                target.FilePrefix,
                publicOrigin,
                timeoutCancellationTokenSource.Token);

            var exists = VerifyStoredFile(storedFile);
            logger.LogInformation(
                "Upload storage call completed. Folder={Folder}; PhysicalPath={PhysicalPath}; PublicUrl={PublicUrl}; Exists={Exists}; StorageProvider={StorageProvider}; SizeBytes={SizeBytes}",
                target.RelativeFolder,
                storedFile.PhysicalPath,
                storedFile.PublicUrl,
                exists,
                storedFile.StorageProvider,
                storedFile.SizeBytes);

            if (!exists)
            {
                throw new IOException($"Upload não foi confirmado em {storedFile.PhysicalPath ?? storedFile.RelativePath}.");
            }

            logger.LogInformation(
                "Upload response building. Folder={Folder}; PublicUrl={PublicUrl}; FileName={FileName}; ContentType={ContentType}; SizeBytes={SizeBytes}; StorageProvider={StorageProvider}",
                target.FormValue,
                storedFile.PublicUrl,
                storedFile.FileName,
                storedFile.ContentType,
                storedFile.SizeBytes,
                storedFile.StorageProvider);

            return ApiResponse<object>.SuccessResponse(
                target.SuccessMessage,
                BuildUploadResponse(storedFile, target.FormValue, isVideo ? "Video" : "Image"));
        }
        catch (OperationCanceledException exception) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogError(
                exception,
                "Upload storage call timed out. Folder={Folder}; FileName={FileName}; TimeoutSeconds={TimeoutSeconds}",
                target.RelativeFolder,
                file.FileName,
                StorageUploadTimeout.TotalSeconds);
            throw new StorageTimeoutAppException(
                "Timeout ao enviar mídia para o storage.",
                new[] { "O storage não respondeu dentro de 30 segundos." });
        }
        catch (StorageUnavailableAppException exception)
        {
            logger.LogWarning(
                exception,
                "Upload unavailable. Folder={Folder}; FileName={FileName}; ContentType={ContentType}; Length={Length}",
                target.RelativeFolder,
                file.FileName,
                file.ContentType,
                file.Length);
            throw;
        }
        catch (AppException)
        {
            throw;
        }
        catch (Exception exception)
        {
            logger.LogError(
                exception,
                "Falha ao salvar upload. Folder={Folder}; FileName={FileName}; ContentType={ContentType}; Length={Length}",
                target.RelativeFolder,
                file.FileName,
                file.ContentType,
                file.Length);
            throw new StorageUnavailableAppException(
                "Storage de mídia indisponível.",
                new[] { target.FailureMessage });
        }
    }

    private static object BuildUploadResponse(StoredFileResponse storedFile, string folder, string mediaType)
    {
        return new
        {
            success = storedFile.Exists,
            url = storedFile.PublicUrl,
            imageUrl = storedFile.PublicUrl,
            mediaUrl = storedFile.PublicUrl,
            folder,
            relativePath = storedFile.RelativePath,
            fileName = storedFile.FileName,
            contentType = storedFile.ContentType,
            sizeBytes = storedFile.SizeBytes,
            size = storedFile.SizeBytes,
            mediaType,
            storageProvider = storedFile.StorageProvider
        };
    }

    private static bool VerifyStoredFile(StoredFileResponse storedFile)
    {
        if (!storedFile.Exists)
        {
            return false;
        }

        if (storedFile.StorageProvider.Equals("Local", StringComparison.OrdinalIgnoreCase))
        {
            return !string.IsNullOrWhiteSpace(storedFile.PhysicalPath) && File.Exists(storedFile.PhysicalPath);
        }

        return true;
    }
}

public sealed record MediaUploadTarget(
    string FormValue,
    string RelativeFolder,
    string FilePrefix,
    long MaxSizeBytes,
    bool AllowsVideo,
    string TooLargeMessage,
    string InvalidFormatMessage,
    string FailureMessage,
    string SuccessMessage);
