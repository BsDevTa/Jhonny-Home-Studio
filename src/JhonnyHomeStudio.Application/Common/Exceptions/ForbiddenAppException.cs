namespace JhonnyHomeStudio.Application.Common.Exceptions;

public sealed class ForbiddenAppException : AppException
{
    public ForbiddenAppException(string message, IEnumerable<string>? errors = null)
        : base(message, errors)
    {
    }
}