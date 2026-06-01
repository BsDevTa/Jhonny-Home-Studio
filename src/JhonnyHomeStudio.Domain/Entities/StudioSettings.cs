using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class StudioSettings : Entity
{
    public string StudioName { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string Slogan { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string? WhatsAppNumber { get; set; }
    public string? InstagramUrl { get; set; }
    public string? WelcomeTitle { get; set; }
    public string? WelcomeMessage { get; set; }
    public string? SupportMessage { get; set; }
    public bool IsActive { get; set; } = true;
}
