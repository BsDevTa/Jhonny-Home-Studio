namespace JhonnyHomeStudio.Application.Common.Responses;

public sealed class ApiResponse<T>
{
    public bool Success { get; init; }
    public string Message { get; init; } = string.Empty;
    public T? Data { get; init; }
    public IReadOnlyCollection<string> Errors { get; init; } = Array.Empty<string>();

    public static ApiResponse<T> SuccessResponse(string message, T? data = default)
    {
        return new ApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data
        };
    }

    public static ApiResponse<T> FailureResponse(string message, IEnumerable<string>? errors = null)
    {
        return new ApiResponse<T>
        {
            Success = false,
            Message = message,
            Errors = errors?.ToArray() ?? Array.Empty<string>()
        };
    }
}