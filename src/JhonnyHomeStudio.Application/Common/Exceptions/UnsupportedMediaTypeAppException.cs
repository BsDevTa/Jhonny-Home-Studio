namespace JhonnyHomeStudio.Application.Common.Exceptions;

public sealed class UnsupportedMediaTypeAppException : AppException
{
    public UnsupportedMediaTypeAppException(string message, IEnumerable<string>? errors = null)
        : base(message, errors)
    {
    }
}
