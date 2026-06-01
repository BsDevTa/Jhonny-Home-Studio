using JhonnyHomeStudio.Application.Common.Dtos.Settings;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class StudioSettingsService : IStudioSettingsService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;

    public StudioSettingsService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<PublicStudioSettingsResponse> GetPublicAsync()
    {
        var settings = await _dbContext.StudioSettings
            .AsNoTracking()
            .Where(x => x.IsActive)
            .OrderBy(x => x.CreatedAt)
            .FirstOrDefaultAsync();

        return ToPublicResponse(settings ?? CreateDefault());
    }

    public async Task<StudioSettingsResponse> GetAdminAsync()
    {
        var settings = await GetOrCreateAsync();
        return ToResponse(settings);
    }

    public async Task<StudioSettingsResponse> UpdateAsync(UpdateStudioSettingsRequest request)
    {
        ValidateRequest(request);

        var settings = await GetOrCreateAsync();
        settings.StudioName = request.StudioName.Trim();
        settings.Subtitle = request.Subtitle.Trim();
        settings.Slogan = request.Slogan.Trim();
        settings.LogoUrl = NormalizeOptional(request.LogoUrl);
        settings.WhatsAppNumber = NormalizeOptional(request.WhatsAppNumber);
        settings.InstagramUrl = NormalizeOptional(request.InstagramUrl);
        settings.WelcomeTitle = NormalizeOptional(request.WelcomeTitle);
        settings.WelcomeMessage = NormalizeOptional(request.WelcomeMessage);
        settings.SupportMessage = NormalizeOptional(request.SupportMessage);
        settings.IsActive = request.IsActive;
        settings.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ToResponse(settings);
    }

    public static StudioSettings CreateDefault()
    {
        return new StudioSettings
        {
            StudioName = "Jhonny Home Studio",
            Subtitle = "Experiência premium",
            Slogan = "Beleza, exclusividade e conforto onde você estiver.",
            WelcomeTitle = "Seu momento beauty começa aqui.",
            WelcomeMessage = "Escolha sua experiência e agende com exclusividade.",
            SupportMessage = "Como podemos ajudar?",
            IsActive = true
        };
    }

    private async Task<StudioSettings> GetOrCreateAsync()
    {
        var settings = await _dbContext.StudioSettings
            .OrderBy(x => x.CreatedAt)
            .FirstOrDefaultAsync();

        if (settings is not null)
        {
            return settings;
        }

        settings = CreateDefault();
        _dbContext.StudioSettings.Add(settings);
        await _dbContext.SaveChangesAsync();
        return settings;
    }

    private static void ValidateRequest(UpdateStudioSettingsRequest request)
    {
        var errors = new List<string>();

        ValidateRequired(request.StudioName, "Nome do estúdio", 160, errors);
        ValidateRequired(request.Subtitle, "Subtítulo", 180, errors);
        ValidateRequired(request.Slogan, "Slogan", 280, errors);
        ValidateOptional(request.LogoUrl, "URL da logo", 500, errors);
        ValidateOptional(request.WhatsAppNumber, "WhatsApp", 40, errors);
        ValidateOptional(request.InstagramUrl, "Instagram", 500, errors);
        ValidateOptional(request.WelcomeTitle, "Título de boas-vindas", 180, errors);
        ValidateOptional(request.WelcomeMessage, "Mensagem de boas-vindas", 500, errors);
        ValidateOptional(request.SupportMessage, "Mensagem de suporte", 500, errors);

        if (errors.Count > 0)
        {
            throw new ValidationAppException("Dados inválidos.", errors);
        }
    }

    private static void ValidateRequired(string value, string field, int maxLength, ICollection<string> errors)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            errors.Add($"{field} é obrigatório.");
        }
        else if (value.Trim().Length > maxLength)
        {
            errors.Add($"{field} deve ter no máximo {maxLength} caracteres.");
        }
    }

    private static void ValidateOptional(string? value, string field, int maxLength, ICollection<string> errors)
    {
        if (value?.Trim().Length > maxLength)
        {
            errors.Add($"{field} deve ter no máximo {maxLength} caracteres.");
        }
    }

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private static StudioSettingsResponse ToResponse(StudioSettings settings)
    {
        return new StudioSettingsResponse
        {
            Id = settings.Id,
            StudioName = settings.StudioName,
            Subtitle = settings.Subtitle,
            Slogan = settings.Slogan,
            LogoUrl = settings.LogoUrl,
            WhatsAppNumber = settings.WhatsAppNumber,
            InstagramUrl = settings.InstagramUrl,
            WelcomeTitle = settings.WelcomeTitle,
            WelcomeMessage = settings.WelcomeMessage,
            SupportMessage = settings.SupportMessage,
            IsActive = settings.IsActive,
            CreatedAt = settings.CreatedAt,
            UpdatedAt = settings.UpdatedAt
        };
    }

    private static PublicStudioSettingsResponse ToPublicResponse(StudioSettings settings)
    {
        return new PublicStudioSettingsResponse
        {
            StudioName = settings.StudioName,
            Subtitle = settings.Subtitle,
            Slogan = settings.Slogan,
            LogoUrl = settings.LogoUrl,
            WhatsAppNumber = settings.WhatsAppNumber,
            InstagramUrl = settings.InstagramUrl,
            WelcomeTitle = settings.WelcomeTitle,
            WelcomeMessage = settings.WelcomeMessage,
            SupportMessage = settings.SupportMessage
        };
    }
}
