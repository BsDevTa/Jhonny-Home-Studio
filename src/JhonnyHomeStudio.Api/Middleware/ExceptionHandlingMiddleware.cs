using System.Net;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Responses;

namespace JhonnyHomeStudio.Api.Middleware;

public sealed class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception exception)
        {
            await HandleExceptionAsync(context, exception, _logger);
        }
    }

    private static async Task HandleExceptionAsync(
        HttpContext context,
        Exception exception,
        ILogger logger)
    {
        if (context.Response.HasStarted)
        {
            throw exception;
        }

        var (statusCode, response) = exception switch
        {
            PayloadTooLargeAppException payloadTooLargeException =>
                (HttpStatusCode.RequestEntityTooLarge, ApiResponse<object>.FailureResponse(payloadTooLargeException.Message, payloadTooLargeException.Errors)),
            UnsupportedMediaTypeAppException unsupportedMediaTypeException =>
                (HttpStatusCode.UnsupportedMediaType, ApiResponse<object>.FailureResponse(unsupportedMediaTypeException.Message, unsupportedMediaTypeException.Errors)),
            StorageUnavailableAppException storageUnavailableException =>
                (HttpStatusCode.ServiceUnavailable, ApiResponse<object>.FailureResponse(storageUnavailableException.Message, storageUnavailableException.Errors)),
            StorageTimeoutAppException storageTimeoutException =>
                (HttpStatusCode.GatewayTimeout, ApiResponse<object>.FailureResponse(storageTimeoutException.Message, storageTimeoutException.Errors)),
            BadHttpRequestException badRequestException when badRequestException.StatusCode == StatusCodes.Status413PayloadTooLarge =>
                (HttpStatusCode.RequestEntityTooLarge, ApiResponse<object>.FailureResponse("Falha no upload: arquivo muito grande.", new[] { "O arquivo excede o limite permitido." })),
            ValidationAppException validationException =>
                (HttpStatusCode.BadRequest, ApiResponse<object>.FailureResponse(validationException.Message, validationException.Errors)),
            ConflictAppException conflictException =>
                (HttpStatusCode.Conflict, ApiResponse<object>.FailureResponse(conflictException.Message, conflictException.Errors)),
            UnauthorizedAppException unauthorizedException =>
                (HttpStatusCode.Unauthorized, ApiResponse<object>.FailureResponse(unauthorizedException.Message, unauthorizedException.Errors)),
            ForbiddenAppException forbiddenException =>
                (HttpStatusCode.Forbidden, ApiResponse<object>.FailureResponse(forbiddenException.Message, forbiddenException.Errors)),
            AppException appException =>
                (HttpStatusCode.BadRequest, ApiResponse<object>.FailureResponse(appException.Message, appException.Errors)),
            _ =>
                (HttpStatusCode.InternalServerError, ApiResponse<object>.FailureResponse("Erro interno ao processar a requisição."))
        };

        if ((int)statusCode >= StatusCodes.Status500InternalServerError)
        {
            logger.LogError(exception, "Unhandled API exception. StatusCode={StatusCode}; Path={Path}", (int)statusCode, context.Request.Path);
        }
        else
        {
            logger.LogWarning(exception, "Handled API exception. StatusCode={StatusCode}; Path={Path}", (int)statusCode, context.Request.Path);
        }

        context.Response.StatusCode = (int)statusCode;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(response);
    }
}
