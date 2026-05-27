namespace JhonnyHomeStudio.Application.Common.Exceptions;

public abstract class AppException : Exception
{
    protected AppException(string message, IEnumerable<string>? errors = null)
        : base(message)
    {
        Errors = errors?.ToArray() ?? Array.Empty<string>();
    }

    public IReadOnlyCollection<string> Errors { get; }
}