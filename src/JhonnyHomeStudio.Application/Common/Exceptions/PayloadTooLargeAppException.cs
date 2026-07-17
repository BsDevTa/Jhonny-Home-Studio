namespace JhonnyHomeStudio.Application.Common.Exceptions;

public sealed class PayloadTooLargeAppException : AppException
{
    public PayloadTooLargeAppException(string message, IEnumerable<string>? errors = null)
        : base(message, errors)
    {
    }
}
