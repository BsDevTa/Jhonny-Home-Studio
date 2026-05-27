namespace JhonnyHomeStudio.Application.Common.Dtos.Customers;

public sealed class UpdateCustomerProfileRequest
{
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? DocumentNumber { get; set; }
    public DateTime? BirthDate { get; set; }
}