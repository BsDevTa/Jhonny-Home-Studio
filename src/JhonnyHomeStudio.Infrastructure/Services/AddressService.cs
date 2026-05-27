using JhonnyHomeStudio.Application.Common.Dtos.Addresses;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class AddressService : IAddressService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;

    public AddressService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IEnumerable<AddressResponse>> GetMyAddressesAsync(Guid userId)
    {
        var customer = await GetOwnedCustomerAsync(userId, trackChanges: false, requireActiveUser: true);

        return await _dbContext.Addresses
            .AsNoTracking()
            .Where(x => x.CustomerId == customer.Id)
            .OrderByDescending(x => x.IsDefault)
            .ThenByDescending(x => x.CreatedAt)
            .Select(ToResponseProjection())
            .ToListAsync();
    }

    public async Task<AddressResponse?> GetMyAddressByIdAsync(Guid userId, Guid addressId)
    {
        var customer = await GetOwnedCustomerAsync(userId, trackChanges: false, requireActiveUser: true);

        return await _dbContext.Addresses
            .AsNoTracking()
            .Where(x => x.CustomerId == customer.Id && x.Id == addressId)
            .Select(ToResponseProjection())
            .FirstOrDefaultAsync();
    }

    public async Task<AddressResponse> CreateMyAddressAsync(Guid userId, CreateAddressRequest request)
    {
        ValidateAddressRequest(request);

        var customer = await GetOwnedCustomerAsync(userId, trackChanges: true, requireActiveUser: true);
        var hasAddresses = await _dbContext.Addresses.AnyAsync(x => x.CustomerId == customer.Id);

        var entity = new Address
        {
            CustomerId = customer.Id,
            Street = request.Street.Trim(),
            Number = request.Number.Trim(),
            Neighborhood = request.Neighborhood.Trim(),
            City = request.City.Trim(),
            State = request.State.Trim(),
            ZipCode = request.ZipCode.Trim(),
            Complement = string.IsNullOrWhiteSpace(request.Complement) ? null : request.Complement.Trim(),
            ReferencePoint = string.IsNullOrWhiteSpace(request.ReferencePoint) ? null : request.ReferencePoint.Trim(),
            IsDefault = !hasAddresses
        };

        _dbContext.Addresses.Add(entity);
        await _dbContext.SaveChangesAsync();

        return await GetOwnedAddressRequiredAsync(customer.Id, entity.Id);
    }

    public async Task<AddressResponse> UpdateMyAddressAsync(Guid userId, Guid addressId, UpdateAddressRequest request)
    {
        ValidateAddressRequest(request);

        var customer = await GetOwnedCustomerAsync(userId, trackChanges: true, requireActiveUser: true);
        var address = await _dbContext.Addresses.FirstOrDefaultAsync(x => x.Id == addressId && x.CustomerId == customer.Id)
            ?? throw new ValidationAppException("Endereço não encontrado.", new[] { "O endereço informado não pertence ao cliente autenticado." });

        address.Street = request.Street.Trim();
        address.Number = request.Number.Trim();
        address.Neighborhood = request.Neighborhood.Trim();
        address.City = request.City.Trim();
        address.State = request.State.Trim();
        address.ZipCode = request.ZipCode.Trim();
        address.Complement = string.IsNullOrWhiteSpace(request.Complement) ? null : request.Complement.Trim();
        address.ReferencePoint = string.IsNullOrWhiteSpace(request.ReferencePoint) ? null : request.ReferencePoint.Trim();
        address.IsDefault = request.IsDefault;
        address.UpdatedAt = DateTime.UtcNow;

        if (request.IsDefault)
        {
            await ClearOtherDefaultsAsync(customer.Id, address.Id);
        }

        await _dbContext.SaveChangesAsync();
        return await GetOwnedAddressRequiredAsync(customer.Id, address.Id);
    }

    public async Task<bool> DeleteMyAddressAsync(Guid userId, Guid addressId)
    {
        var customer = await GetOwnedCustomerAsync(userId, trackChanges: true, requireActiveUser: true);
        var address = await _dbContext.Addresses.FirstOrDefaultAsync(x => x.Id == addressId && x.CustomerId == customer.Id);
        if (address is null)
        {
            return false;
        }

        _dbContext.Addresses.Remove(address);
        await _dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SetDefaultAddressAsync(Guid userId, Guid addressId)
    {
        var customer = await GetOwnedCustomerAsync(userId, trackChanges: true, requireActiveUser: true);
        var address = await _dbContext.Addresses.FirstOrDefaultAsync(x => x.Id == addressId && x.CustomerId == customer.Id);
        if (address is null)
        {
            return false;
        }

        await ClearOtherDefaultsAsync(customer.Id, address.Id);
        address.IsDefault = true;
        address.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<AddressResponse>> GetAddressesByCustomerIdForAdminAsync(Guid customerId)
    {
        var customerExists = await _dbContext.Customers.AnyAsync(x => x.Id == customerId);
        if (!customerExists)
        {
            throw new ValidationAppException("Cliente não encontrado.", new[] { "Verifique o identificador informado." });
        }

        return await _dbContext.Addresses
            .AsNoTracking()
            .Where(x => x.CustomerId == customerId)
            .OrderByDescending(x => x.IsDefault)
            .ThenByDescending(x => x.CreatedAt)
            .Select(ToResponseProjection())
            .ToListAsync();
    }

    private async Task<Customer> GetOwnedCustomerAsync(Guid userId, bool trackChanges, bool requireActiveUser)
    {
        var query = _dbContext.Customers
            .Include(x => x.User)
            .Where(x => x.UserId == userId);

        if (!trackChanges)
        {
            query = query.AsNoTracking();
        }

        var customer = await query.FirstOrDefaultAsync();
        if (customer is null)
        {
            throw new ValidationAppException("Cliente não encontrado.", new[] { "Não foi possível localizar o cliente autenticado." });
        }

        if (requireActiveUser && !customer.User.IsActive)
        {
            throw new ForbiddenAppException("Usuário inativo.", new[] { "Seu acesso está bloqueado. Entre em contato com o suporte." });
        }

        return customer;
    }

    private async Task ClearOtherDefaultsAsync(Guid customerId, Guid keepAddressId)
    {
        var otherDefaults = await _dbContext.Addresses
            .Where(x => x.CustomerId == customerId && x.Id != keepAddressId && x.IsDefault)
            .ToListAsync();

        foreach (var other in otherDefaults)
        {
            other.IsDefault = false;
            other.UpdatedAt = DateTime.UtcNow;
        }
    }

    private async Task<AddressResponse> GetOwnedAddressRequiredAsync(Guid customerId, Guid addressId)
    {
        var response = await _dbContext.Addresses
            .AsNoTracking()
            .Where(x => x.CustomerId == customerId && x.Id == addressId)
            .Select(ToResponseProjection())
            .FirstOrDefaultAsync();

        return response ?? throw new ValidationAppException("Endereço não encontrado.", new[] { "Verifique o identificador informado." });
    }

    private static void ValidateAddressRequest(CreateAddressRequest request)
    {
        var errors = new List<string>();
        ValidateAddressFields(request.Street, request.Number, request.Neighborhood, request.City, request.State, request.ZipCode, errors);
        if (errors.Count > 0)
        {
            throw new ValidationAppException("Não foi possível cadastrar o endereço.", errors);
        }
    }

    private static void ValidateAddressRequest(UpdateAddressRequest request)
    {
        var errors = new List<string>();
        ValidateAddressFields(request.Street, request.Number, request.Neighborhood, request.City, request.State, request.ZipCode, errors);
        if (errors.Count > 0)
        {
            throw new ValidationAppException("Não foi possível atualizar o endereço.", errors);
        }
    }

    private static void ValidateAddressFields(string street, string number, string neighborhood, string city, string state, string zipCode, ICollection<string> errors)
    {
        if (string.IsNullOrWhiteSpace(street)) errors.Add("Rua é obrigatória.");
        if (string.IsNullOrWhiteSpace(number)) errors.Add("Número é obrigatório.");
        if (string.IsNullOrWhiteSpace(neighborhood)) errors.Add("Bairro é obrigatório.");
        if (string.IsNullOrWhiteSpace(city)) errors.Add("Cidade é obrigatória.");
        if (string.IsNullOrWhiteSpace(state)) errors.Add("Estado é obrigatório.");
        if (string.IsNullOrWhiteSpace(zipCode)) errors.Add("CEP é obrigatório.");
    }

    private static System.Linq.Expressions.Expression<Func<Address, AddressResponse>> ToResponseProjection()
    {
        return x => new AddressResponse
        {
            Id = x.Id,
            CustomerId = x.CustomerId,
            Street = x.Street,
            Number = x.Number,
            Neighborhood = x.Neighborhood,
            City = x.City,
            State = x.State,
            ZipCode = x.ZipCode,
            Complement = x.Complement,
            ReferencePoint = x.ReferencePoint,
            IsDefault = x.IsDefault,
            CreatedAt = x.CreatedAt,
            UpdatedAt = x.UpdatedAt
        };
    }
}