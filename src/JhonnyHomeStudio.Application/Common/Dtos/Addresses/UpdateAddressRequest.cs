namespace JhonnyHomeStudio.Application.Common.Dtos.Addresses;

public sealed class UpdateAddressRequest
{
    public string Street { get; set; } = string.Empty;
    public string Number { get; set; } = string.Empty;
    public string Neighborhood { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string ZipCode { get; set; } = string.Empty;
    public string? Complement { get; set; }
    public string? ReferencePoint { get; set; }
    public bool IsDefault { get; set; }
}