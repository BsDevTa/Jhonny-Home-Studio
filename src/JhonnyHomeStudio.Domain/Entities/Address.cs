using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class Address : Entity
{
    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;

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