using JhonnyHomeStudio.Application.Common.Dtos.Auth;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Domain.Enums;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class AuthService : IAuthService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IPasswordHasher _passwordHasher;

    public AuthService(
        JhonnyHomeStudioDbContext dbContext,
        IJwtTokenService jwtTokenService,
        IPasswordHasher passwordHasher)
    {
        _dbContext = dbContext;
        _jwtTokenService = jwtTokenService;
        _passwordHasher = passwordHasher;
    }

    public async Task<AuthResponse> RegisterCustomerAsync(RegisterCustomerRequest request, CancellationToken cancellationToken = default)
    {
        ValidateRegisterRequest(request);

        var normalizedEmail = NormalizeEmail(request.Email);

        var emailExists = await _dbContext.Users.AnyAsync(x => x.Email == normalizedEmail, cancellationToken);
        if (emailExists)
        {
            throw new ConflictAppException("E-mail já cadastrado.", new[] { "Utilize outro e-mail para continuar." });
        }

        var user = new User
        {
            FullName = request.FullName.Trim(),
            Email = normalizedEmail,
            Phone = request.Phone?.Trim(),
            PasswordHash = _passwordHasher.Hash(request.Password),
            Role = UserRole.Customer,
            IsActive = true
        };

        var customer = new Customer
        {
            User = user
        };

        _dbContext.Users.Add(user);
        _dbContext.Customers.Add(customer);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var tokenResult = _jwtTokenService.GenerateToken(user);

        return BuildAuthResponse(user, tokenResult.Token, tokenResult.ExpiresAt);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
        {
            throw new ValidationAppException("Dados de login inválidos.", new[] { "E-mail e senha são obrigatórios." });
        }

        var normalizedEmail = NormalizeEmail(request.Email);

        var user = await _dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Email == normalizedEmail, cancellationToken);

        if (user is null || !_passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedAppException("E-mail ou senha inválidos.", new[] { "Verifique suas credenciais e tente novamente." });
        }

        if (!user.IsActive)
        {
            throw new ForbiddenAppException("Usuário inativo.", new[] { "Entre em contato com o suporte para reativar sua conta." });
        }

        var tokenResult = _jwtTokenService.GenerateToken(user);
        return BuildAuthResponse(user, tokenResult.Token, tokenResult.ExpiresAt);
    }

    private static void ValidateRegisterRequest(RegisterCustomerRequest request)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            errors.Add("Nome completo é obrigatório.");
        }

        if (string.IsNullOrWhiteSpace(request.Email))
        {
            errors.Add("E-mail é obrigatório.");
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            errors.Add("Senha é obrigatória.");
        }

        if (string.IsNullOrWhiteSpace(request.ConfirmPassword))
        {
            errors.Add("Confirmação de senha é obrigatória.");
        }

        if (!string.Equals(request.Password, request.ConfirmPassword, StringComparison.Ordinal))
        {
            errors.Add("As senhas não conferem.");
        }

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Não foi possível concluir o cadastro.", errors);
        }
    }

    private static string NormalizeEmail(string email)
    {
        return email.Trim().ToLowerInvariant();
    }

    private static AuthResponse BuildAuthResponse(User user, string token, DateTime expiresAt)
    {
        return new AuthResponse
        {
            Token = token,
            ExpiresAt = expiresAt,
            UserId = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.Role.ToString()
        };
    }
}