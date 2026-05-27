namespace JhonnyHomeStudio.Application.Common.Dtos.Auth;

public sealed class RegisterCustomerRequest
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Password { get; set; } = string.Empty;
    public string ConfirmPassword { get; set; } = string.Empty;
}