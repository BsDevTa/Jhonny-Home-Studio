using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using JhonnyHomeStudio.Application.Common.Exceptions;

namespace JhonnyHomeStudio.Api.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetUserIdOrThrow(this ClaimsPrincipal principal)
    {
        var userIdValue = principal.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? principal.FindFirstValue(JwtRegisteredClaimNames.Sub);

        if (!Guid.TryParse(userIdValue, out var userId))
        {
            throw new UnauthorizedAppException("Usuário não autenticado.", new[] { "Não foi possível identificar o usuário autenticado." });
        }

        return userId;
    }
}