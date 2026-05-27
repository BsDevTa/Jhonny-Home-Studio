namespace JhonnyHomeStudio.Application.Common.Exceptions;

public sealed class ValidationAppException : AppException
{
    public ValidationAppException(string message, IEnumerable<string>? errors = null)
        : base(message, errors)
    {
    }
}