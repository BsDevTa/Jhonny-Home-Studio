using JhonnyHomeStudio.Application.Common.Dtos.Addresses;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IAddressService
{
    Task<IEnumerable<AddressResponse>> GetMyAddressesAsync(Guid userId);
    Task<AddressResponse?> GetMyAddressByIdAsync(Guid userId, Guid addressId);
    Task<AddressResponse> CreateMyAddressAsync(Guid userId, CreateAddressRequest request);
    Task<AddressResponse> UpdateMyAddressAsync(Guid userId, Guid addressId, UpdateAddressRequest request);
    Task<bool> DeleteMyAddressAsync(Guid userId, Guid addressId);
    Task<bool> SetDefaultAddressAsync(Guid userId, Guid addressId);
    Task<IEnumerable<AddressResponse>> GetAddressesByCustomerIdForAdminAsync(Guid customerId);
}