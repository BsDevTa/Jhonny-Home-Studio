namespace JhonnyHomeStudio.Application.Common.Exceptions;

public sealed class UnauthorizedAppException : AppException
{
    public UnauthorizedAppException(string message, IEnumerable<string>? errors = null)
        : base(message, errors)
    {
    }
}