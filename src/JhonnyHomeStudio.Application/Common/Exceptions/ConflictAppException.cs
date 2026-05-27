namespace JhonnyHomeStudio.Application.Common.Exceptions;

public sealed class ConflictAppException : AppException
{
    public ConflictAppException(string message, IEnumerable<string>? errors = null)
        : base(message, errors)
    {
    }
}