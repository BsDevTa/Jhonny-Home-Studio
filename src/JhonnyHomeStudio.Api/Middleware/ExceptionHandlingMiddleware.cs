using System.Net;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Responses;

namespace JhonnyHomeStudio.Api.Middleware;

public sealed class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;

    public ExceptionHandlingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception exception)
        {
            await HandleExceptionAsync(context, exception);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, response) = exception switch
        {
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

        context.Response.StatusCode = (int)statusCode;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(response);
    }
}