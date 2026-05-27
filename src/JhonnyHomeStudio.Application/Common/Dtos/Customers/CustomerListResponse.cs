namespace JhonnyHomeStudio.Application.Common.Dtos.Customers;

public sealed class CustomerListResponse
{
    public Guid CustomerId { get; set; }
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? DocumentNumber { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}