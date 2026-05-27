using JhonnyHomeStudio.Application.Common.Dtos.Auth;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IAuthService
{
    Task<AuthResponse> RegisterCustomerAsync(RegisterCustomerRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
}