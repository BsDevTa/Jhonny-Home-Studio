namespace JhonnyHomeStudio.Application.Common.Exceptions;

public sealed class StorageTimeoutAppException : AppException
{
    public StorageTimeoutAppException(string message, IEnumerable<string>? errors = null)
        : base(message, errors)
    {
    }
}
