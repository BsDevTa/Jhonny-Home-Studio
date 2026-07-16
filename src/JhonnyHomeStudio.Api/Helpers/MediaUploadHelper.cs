using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;

namespace JhonnyHomeStudio.Api.Helpers;

public static class MediaUploadHelper
{
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
        if (file is null || file.Length == 0)
        {
            throw new ValidationAppException("Arquivo não enviado.");
        }

        if (file.Length > target.MaxSizeBytes)
        {
            throw new ValidationAppException(target.TooLargeMessage);
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        var isImage = AllowedImageExtensions.Contains(extension);
        var isVideo = target.AllowsVideo && AllowedVideoExtensions.Contains(extension);
        if (!isImage && !isVideo)
        {
            throw new ValidationAppException(target.InvalidFormatMessage);
        }

        try
        {
            await using var stream = file.OpenReadStream();
            var storedFile = await fileStorage.SaveAsync(
                stream,
                file.FileName,
                file.ContentType,
                target.RelativeFolder,
                target.FilePrefix,
                publicOrigin,
                cancellationToken);

            var exists = VerifyStoredFile(storedFile);
            logger.LogInformation(
                "Upload concluído. Folder={Folder}; PhysicalPath={PhysicalPath}; PublicUrl={PublicUrl}; Exists={Exists}",
                target.RelativeFolder,
                storedFile.PhysicalPath,
                storedFile.PublicUrl,
                exists);

            if (!exists)
            {
                throw new IOException($"Upload não foi confirmado em {storedFile.PhysicalPath ?? storedFile.RelativePath}.");
            }

            return ApiResponse<object>.SuccessResponse(
                target.SuccessMessage,
                BuildUploadResponse(storedFile, isVideo ? "Video" : "Image"));
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
            throw new ValidationAppException(target.FailureMessage);
        }
    }

    private static object BuildUploadResponse(StoredFileResponse storedFile, string mediaType)
    {
        return new
        {
            success = storedFile.Exists,
            url = storedFile.PublicUrl,
            imageUrl = storedFile.PublicUrl,
            mediaUrl = storedFile.PublicUrl,
            relativePath = storedFile.RelativePath,
            fileName = storedFile.FileName,
            contentType = storedFile.ContentType,
            sizeBytes = storedFile.SizeBytes,
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
