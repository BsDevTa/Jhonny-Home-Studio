using JhonnyHomeStudio.Application.Common.Responses;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Infrastructure.Services;
using Amazon.S3;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JhonnyHomeStudio.Api.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "Admin")]
public sealed class AdminController : ControllerBase
{
    private readonly IFileStorageService _fileStorage;

    public AdminController(IFileStorageService fileStorage)
    {
        _fileStorage = fileStorage;
    }

    [HttpGet("test")]
    public IActionResult Test()
    {
        return Ok(ApiResponse<object>.SuccessResponse("Acesso administrativo autorizado.", new { role = "Admin" }));
    }

    // TEMPORARY diagnostic endpoint. Remove after the one-time S3 test.
    [HttpPost("diagnostics/temporary/s3-put")]
    public async Task<IActionResult> RunTemporaryS3PutDiagnostic(CancellationToken cancellationToken)
    {
        if (_fileStorage is not S3FileStorageService s3Storage)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                Success = false,
                StatusCode = (int)StatusCodes.Status503ServiceUnavailable,
                ErrorCode = "S3DiagnosticUnavailable",
                Message = "O storage S3 não está configurado para esta aplicação.",
                RequestId = (string?)null,
                AmazonId2 = (string?)null,
                ExceptionType = (string?)null
            });
        }

        try
        {
            await s3Storage.RunMinimalPutDiagnosticAsync(cancellationToken);
            return Ok(new
            {
                Success = true,
                StatusCode = StatusCodes.Status200OK,
                ErrorCode = (string?)null,
                Message = "PutObject mínimo concluído.",
                RequestId = (string?)null,
                AmazonId2 = (string?)null,
                ExceptionType = (string?)null
            });
        }
        catch (AmazonS3Exception exception)
        {
            return StatusCode(StatusCodes.Status502BadGateway, new
            {
                Success = false,
                StatusCode = (int)exception.StatusCode,
                ErrorCode = exception.ErrorCode,
                Message = exception.Message,
                RequestId = exception.RequestId,
                AmazonId2 = exception.AmazonId2,
                ExceptionType = exception.GetType().Name
            });
        }
        catch (Exception exception)
        {
            return StatusCode(StatusCodes.Status502BadGateway, new
            {
                Success = false,
                StatusCode = (int?)null,
                ErrorCode = (string?)null,
                Message = exception.Message,
                RequestId = (string?)null,
                AmazonId2 = (string?)null,
                ExceptionType = exception.GetType().Name
            });
        }
    }
}
