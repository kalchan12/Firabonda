import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/stat_tile.dart';

/// Sample data set for the Phase 2 design checkpoint. Replaced by real
/// providers in Phase 5.
final class _DashboardSample {
  static const spentCents = 1240000;
  static const earnedCents = 1890000;
  static const profitCents = 650000;
  static const stockValueCents = 3820000;

  static const bestSellers = <_BestSeller>[
    _BestSeller(category: 'Shirts', sold: 24, profitCents: 288000),
    _BestSeller(category: 'T-shirts', sold: 31, profitCents: 155000),
    _BestSeller(category: 'Jeans', sold: 9, profitCents: 81000),
  ];

  static const lowStock = <_LowStock>[
    _LowStock(category: 'Jackets', stockLeft: 2),
    _LowStock(category: 'Shorts', stockLeft: 4),
  ];

  static const chartCents = <double>[
    210000,
    185000,
    402000,
    360000,
    512000,
    470000,
    650000,
  ];
}

final class _BestSeller {
  const _BestSeller({
    required this.category,
    required this.sold,
    required this.profitCents,
  });

  final String category;
  final int sold;
  final int profitCents;
}

final class _LowStock {
  const _LowStock({required this.category, required this.stockLeft});

  final String category;
  final int stockLeft;
}

/// Dashboard screen (design checkpoint sample).
final class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

final class _DashboardScreenState extends State<DashboardScreen> {
  String _period = 'Week';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Fira Bonda',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  'Demo data',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            SegmentedButton<String>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.comfortable,
              ),
              segments: [
                for (final period in const ['Today', 'Week', 'Month', 'All'])
                  ButtonSegment(value: period, label: Text(period)),
              ],
              selected: {_period},
              onSelectionChanged: (selection) =>
                  setState(() => _period = selection.first),
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Spent',
                    value: Money.etb(_DashboardSample.spentCents),
                    tone: StatTone.loss,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: StatTile(
                    label: 'Earned',
                    value: Money.etb(_DashboardSample.earnedCents),
                    tone: StatTone.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            StatTile(
              hero: true,
              label: 'Profit ($_period)',
              value: '+ ${Money.etb(_DashboardSample.profitCents)}',
              tone: StatTone.profit,
            ),
            const SizedBox(height: AppSpacing.m),
            const _ProfitChartCard(valuesCents: _DashboardSample.chartCents),
            const SizedBox(height: AppSpacing.m),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best sellers ($_period)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  for (final seller in _DashboardSample.bestSellers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              seller.category,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          Text(
                            '${seller.sold} sold',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.l),
                          Text(
                            '+ ${Money.amount(seller.profitCents)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.profit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Stock value',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Text(
                        Money.etb(_DashboardSample.stockValueCents),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: colors.warning,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'Low stock',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  for (final item in _DashboardSample.lowStock)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.category)),
                          Text(
                            '${item.stockLeft} left',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 96),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'demo-theme',
        onPressed: () => context.push('/add-purchase'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

final class _ProfitChartCard extends StatelessWidget {
  const _ProfitChartCard({required this.valuesCents});

  final List<double> valuesCents;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profit trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.l),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: colors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceVariant,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          Money.amount(spot.y.round()),
                          TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final (index, value) in valuesCents.indexed)
                        FlSpot(index.toDouble(), value),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: colors.profit,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.profit.withValues(alpha: 0.25),
                          colors.profit.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
