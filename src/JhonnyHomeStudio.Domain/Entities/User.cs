using JhonnyHomeStudio.Domain.Common;
using JhonnyHomeStudio.Domain.Enums;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class User : Entity
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public UserRole Role { get; set; } = UserRole.Customer;
    public bool IsActive { get; set; } = true;
}