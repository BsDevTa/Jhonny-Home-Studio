using JhonnyHomeStudio.Application.Common.Dtos.Customers;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class CustomerService : ICustomerService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;

    public CustomerService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<CustomerProfileResponse> GetMyProfileAsync(Guid userId)
    {
        var customer = await GetCustomerWithUserAsync(userId, trackChanges: false, requireActiveUser: true);
        return ToProfileResponse(customer);
    }

    public async Task<CustomerProfileResponse> UpdateMyProfileAsync(Guid userId, UpdateCustomerProfileRequest request)
    {
        ValidateUpdateRequest(request);

        var customer = await GetCustomerWithUserAsync(userId, trackChanges: true, requireActiveUser: true);

        customer.User.FullName = request.FullName.Trim();
        customer.User.Phone = string.IsNullOrWhiteSpace(request.Phone) ? null : NormalizePhone(request.Phone);
        customer.DocumentNumber = string.IsNullOrWhiteSpace(request.DocumentNumber) ? null : request.DocumentNumber.Trim();
        customer.BirthDate = request.BirthDate;
        customer.User.UpdatedAt = DateTime.UtcNow;
        customer.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ToProfileResponse(customer);
    }

    public async Task<IEnumerable<CustomerListResponse>> GetAllAsync()
    {
        return await _dbContext.Customers
            .AsNoTracking()
            .Include(x => x.User)
            .OrderBy(x => x.User.FullName)
            .Select(x => new CustomerListResponse
            {
                CustomerId = x.Id,
                UserId = x.UserId,
                FullName = x.User.FullName,
                Email = x.User.Email,
                Phone = x.User.Phone,
                DocumentNumber = x.DocumentNumber,
                IsActive = x.User.IsActive,
                CreatedAt = x.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<CustomerProfileResponse?> GetByIdAsync(Guid customerId)
    {
        return await _dbContext.Customers
            .AsNoTracking()
            .Include(x => x.User)
            .Where(x => x.Id == customerId)
            .Select(x => new CustomerProfileResponse
            {
                CustomerId = x.Id,
                UserId = x.UserId,
                FullName = x.User.FullName,
                Email = x.User.Email,
                Phone = x.User.Phone,
                DocumentNumber = x.DocumentNumber,
                BirthDate = x.BirthDate,
                IsActive = x.User.IsActive,
                CreatedAt = x.CreatedAt,
                UpdatedAt = x.UpdatedAt
            })
            .FirstOrDefaultAsync();
    }

    public async Task<bool> ActivateAsync(Guid customerId)
    {
        var customer = await _dbContext.Customers
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.Id == customerId);

        if (customer is null)
        {
            return false;
        }

        customer.User.IsActive = true;
        customer.User.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeactivateAsync(Guid customerId)
    {
        var customer = await _dbContext.Customers
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.Id == customerId);

        if (customer is null)
        {
            return false;
        }

        customer.User.IsActive = false;
        customer.User.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        return true;
    }

    private async Task<Customer> GetCustomerWithUserAsync(Guid userId, bool trackChanges, bool requireActiveUser)
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
            throw new ValidationAppException("Cliente não encontrado.", new[] { "Não foi possível localizar o perfil do cliente autenticado." });
        }

        if (requireActiveUser && !customer.User.IsActive)
        {
            throw new ForbiddenAppException("Usuário inativo.", new[] { "Seu acesso está bloqueado. Entre em contato com o suporte." });
        }

        return customer;
    }

    private static CustomerProfileResponse ToProfileResponse(Customer customer)
    {
        return new CustomerProfileResponse
        {
            CustomerId = customer.Id,
            UserId = customer.UserId,
            FullName = customer.User.FullName,
            Email = customer.User.Email,
            Phone = customer.User.Phone,
            DocumentNumber = customer.DocumentNumber,
            BirthDate = customer.BirthDate,
            IsActive = customer.User.IsActive,
            CreatedAt = customer.CreatedAt,
            UpdatedAt = customer.UpdatedAt
        };
    }

    private static void ValidateUpdateRequest(UpdateCustomerProfileRequest request)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            errors.Add("Nome completo é obrigatório.");
        }

        if (!string.IsNullOrWhiteSpace(request.Phone) && !IsValidPhone(request.Phone))
        {
            errors.Add("Telefone informado é inválido.");
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Não foi possível atualizar o perfil.", errors);
        }
    }

    private static string? NormalizePhone(string? phone)
    {
        return string.IsNullOrWhiteSpace(phone) ? null : phone.Trim();
    }

    private static bool IsValidPhone(string phone)
    {
        return System.Text.RegularExpressions.Regex.IsMatch(phone.Trim(), "^[0-9()+\\-\\s]{8,20}$");
    }
}