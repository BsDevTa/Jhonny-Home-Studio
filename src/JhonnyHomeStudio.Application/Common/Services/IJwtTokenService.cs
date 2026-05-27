using JhonnyHomeStudio.Domain.Entities;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IJwtTokenService
{
    (string Token, DateTime ExpiresAt) GenerateToken(User user);
}