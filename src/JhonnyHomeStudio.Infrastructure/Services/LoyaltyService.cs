using JhonnyHomeStudio.Application.Common.Dtos.Loyalty;
using JhonnyHomeStudio.Application.Common.Exceptions;
using JhonnyHomeStudio.Application.Common.Services;
using JhonnyHomeStudio.Domain.Entities;
using JhonnyHomeStudio.Domain.Enums;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JhonnyHomeStudio.Infrastructure.Services;

public sealed class LoyaltyService : ILoyaltyService
{
    private readonly JhonnyHomeStudioDbContext _dbContext;

    public LoyaltyService(JhonnyHomeStudioDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<LoyaltyResponse> GetMyAsync(Guid userId)
    {
        var customer = await _dbContext.Customers
            .AsNoTracking()
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == userId)
            ?? throw new ValidationAppException("Cliente não encontrado.", new[] { "Não foi possível localizar o cliente autenticado." });

        if (!customer.User.IsActive)
        {
            throw new ForbiddenAppException("Usuário inativo.", new[] { "Seu acesso está bloqueado. Entre em contato com o suporte." });
        }

        return await BuildResponseAsync(customer.Id);
    }

    public async Task<LoyaltyResponse?> GetForAdminAsync(Guid customerId)
    {
        var customerExists = await _dbContext.Customers
            .AsNoTracking()
            .AnyAsync(x => x.Id == customerId);

        return customerExists ? await BuildResponseAsync(customerId) : null;
    }

    public async Task AwardForCompletedAppointmentAsync(Guid customerId, Guid appointmentId, decimal servicePrice)
    {
        var transactionExists = await _dbContext.LoyaltyTransactions
            .AnyAsync(x => x.AppointmentId == appointmentId);

        if (transactionExists)
        {
            return;
        }

        var awardedPoints = Math.Max(5, (int)Math.Floor(servicePrice / 10m));
        var loyalty = await _dbContext.CustomerLoyalties
            .FirstOrDefaultAsync(x => x.CustomerId == customerId);

        if (loyalty is null)
        {
            loyalty = new CustomerLoyalty
            {
                CustomerId = customerId,
                Points = awardedPoints,
                Level = CalculateLevel(awardedPoints)
            };
            _dbContext.CustomerLoyalties.Add(loyalty);
        }
        else
        {
            loyalty.Points += awardedPoints;
            loyalty.Level = CalculateLevel(loyalty.Points);
            loyalty.UpdatedAt = DateTime.UtcNow;
        }

        _dbContext.LoyaltyTransactions.Add(new LoyaltyTransaction
        {
            CustomerId = customerId,
            AppointmentId = appointmentId,
            Points = awardedPoints,
            Description = $"Atendimento concluído: +{awardedPoints} pontos."
        });
    }

    private async Task<LoyaltyResponse> BuildResponseAsync(Guid customerId)
    {
        var loyalty = await _dbContext.CustomerLoyalties
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.CustomerId == customerId);

        var points = loyalty?.Points ?? 0;
        var level = loyalty?.Level ?? LoyaltyLevel.Bronze;
        var transactions = await _dbContext.LoyaltyTransactions
            .AsNoTracking()
            .Where(x => x.CustomerId == customerId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(10)
            .Select(x => new LoyaltyTransactionResponse
            {
                Id = x.Id,
                AppointmentId = x.AppointmentId,
                Points = x.Points,
                Description = x.Description,
                CreatedAt = x.CreatedAt
            })
            .ToListAsync();

        var (nextLevel, nextThreshold) = GetNextLevel(level);
        return new LoyaltyResponse
        {
            CustomerId = customerId,
            Points = points,
            Level = level.ToString(),
            NextLevel = nextLevel?.ToString(),
            PointsToNextLevel = nextThreshold.HasValue ? Math.Max(0, nextThreshold.Value - points) : 0,
            Benefits = GetBenefits(level),
            RecentTransactions = transactions
        };
    }

    private static LoyaltyLevel CalculateLevel(int points)
    {
        return points switch
        {
            >= 600 => LoyaltyLevel.Diamond,
            >= 300 => LoyaltyLevel.Platinum,
            >= 100 => LoyaltyLevel.Gold,
            _ => LoyaltyLevel.Bronze
        };
    }

    private static (LoyaltyLevel? Level, int? Threshold) GetNextLevel(LoyaltyLevel level)
    {
        return level switch
        {
            LoyaltyLevel.Bronze => (LoyaltyLevel.Gold, 100),
            LoyaltyLevel.Gold => (LoyaltyLevel.Platinum, 300),
            LoyaltyLevel.Platinum => (LoyaltyLevel.Diamond, 600),
            _ => (null, null)
        };
    }

    private static IReadOnlyCollection<string> GetBenefits(LoyaltyLevel level)
    {
        return level switch
        {
            LoyaltyLevel.Diamond => new[]
            {
                "Atendimento prioritário",
                "Brindes exclusivos",
                "Horários especiais",
                "Acesso antecipado à agenda"
            },
            LoyaltyLevel.Platinum => new[]
            {
                "Acesso ao cartão fidelidade",
                "Benefícios em serviços selecionados",
                "Atendimento prioritário em campanhas"
            },
            LoyaltyLevel.Gold => new[]
            {
                "Acesso ao cartão fidelidade",
                "Benefícios em serviços selecionados"
            },
            _ => new[]
            {
                "Acesso ao cartão fidelidade"
            }
        };
    }
}
