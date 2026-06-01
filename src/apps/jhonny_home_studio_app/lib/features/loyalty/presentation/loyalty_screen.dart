import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/premium_empty_state.dart';
import '../../../shared/widgets/premium_gradient_border_card.dart';
import '../data/loyalty_api.dart';
import '../data/loyalty_model.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  late final LoyaltyApi _loyaltyApi;
  LoyaltyModel? _loyalty;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loyaltyApi = LoyaltyApi(apiClient: context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loyalty = await _loyaltyApi.getMyLoyalty();
      if (mounted) {
        setState(() {
          _loyalty = loyalty;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Não foi possível carregar seu Clube Premium.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loyalty = _loyalty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surfaceElevated,
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 2,
                  ),
                )
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: PremiumEmptyState(
                      icon: Icons.error_outline,
                      title: 'Não foi possível carregar',
                      message: _errorMessage!,
                      actionLabel: 'Tentar novamente',
                      onAction: _load,
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Cartão Fidelidade',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Cada atendimento concluído aproxima você de novos benefícios.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _LoyaltySummaryCard(
                                loyalty: loyalty ?? LoyaltyModel.empty,
                              ),
                              const SizedBox(height: 18),
                              _BenefitsCard(
                                loyalty: loyalty ?? LoyaltyModel.empty,
                              ),
                              const SizedBox(height: 18),
                              _HistoryCard(
                                loyalty: loyalty ?? LoyaltyModel.empty,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _LoyaltySummaryCard extends StatelessWidget {
  const _LoyaltySummaryCard({required this.loyalty});

  final LoyaltyModel loyalty;

  @override
  Widget build(BuildContext context) {
    return PremiumGradientBorderCard(
      subtleGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLIENTE ${loyalty.level.toUpperCase()}',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${loyalty.points} pontos',
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: loyalty.progress,
              minHeight: 5,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loyalty.nextLevel.isEmpty
                ? 'Você chegou ao nível máximo.'
                : 'Faltam ${loyalty.pointsToNextLevel} pontos para ${loyalty.nextLevel}.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.loyalty});

  final LoyaltyModel loyalty;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Seus benefícios',
      child: Column(
        children: loyalty.benefits
            .map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.gold,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.loyalty});

  final LoyaltyModel loyalty;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Histórico de pontos',
      child: loyalty.recentTransactions.isEmpty
          ? const Text(
              'Conclua seu primeiro atendimento para começar a acumular pontos.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          : Column(
              children: loyalty.recentTransactions
                  .map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.description,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (transaction.createdAt != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(transaction.createdAt!.toLocal()),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '+${transaction.points}',
                            style: const TextStyle(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
