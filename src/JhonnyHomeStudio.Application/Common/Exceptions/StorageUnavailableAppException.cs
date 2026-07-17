namespace JhonnyHomeStudio.Application.Common.Exceptions;

public sealed class StorageUnavailableAppException : AppException
{
    public StorageUnavailableAppException(string message, IEnumerable<string>? errors = null)
        : base(message, errors)
    {
    }
}
