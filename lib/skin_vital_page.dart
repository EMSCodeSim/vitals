import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';

class SkinVitalPage extends StatefulWidget {
  const SkinVitalPage({super.key});

  @override
  State<SkinVitalPage> createState() => _SkinVitalPageState();
}

class _SkinVitalPageState extends State<SkinVitalPage> {
  SkinFinding _selected = SkinFinding.paleCoolClammy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSVitalsScaffold(
      title: 'Skin Signs',
      subtitle: 'Compare a baseline skin sample with abnormal skin findings. Document skin as color, temperature, and moisture.',
      bodySlivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EMSSectionCard(
                      title: 'Compare Skin Signs',
                      subtitle: 'Normal baseline stays on the left. Tap a finding below to change the sample on the right.',
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _SkinSampleCard(
                                  label: 'Baseline',
                                  finding: SkinFinding.normal,
                                  isBaseline: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SkinSampleCard(
                                  label: 'Sample',
                                  finding: _selected,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final finding in SkinFinding.values.where((f) => f != SkinFinding.normal))
                                ChoiceChip(
                                  label: Text(finding.shortLabel),
                                  selected: _selected == finding,
                                  onSelected: (_) => setState(() => _selected = finding),
                                  showCheckmark: false,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _selected == finding ? cs.onPrimary : cs.onSurface,
                                  ),
                                  selectedColor: cs.primary,
                                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.42),
                                  side: BorderSide(color: cs.outline.withValues(alpha: 0.18)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Document It',
                      subtitle: _selected.charting,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FindingRow(icon: Icons.palette, label: 'Color', value: _selected.colorText),
                          const SizedBox(height: 10),
                          _FindingRow(icon: Icons.thermostat, label: 'Temperature', value: _selected.tempText),
                          const SizedBox(height: 10),
                          _FindingRow(icon: Icons.water_drop, label: 'Moisture', value: _selected.moistureText),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
                            ),
                            child: Text(
                              _selected.studentNote,
                              style: context.textStyles.bodyMedium?.copyWith(height: 1.35, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkinSampleCard extends StatelessWidget {
  const _SkinSampleCard({required this.label, required this.finding, this.isBaseline = false});

  final String label;
  final SkinFinding finding;
  final bool isBaseline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 0.82,
            child: CustomPaint(
              painter: _SkinSamplePainter(finding),
              child: Center(
                child: Icon(
                  isBaseline ? Icons.check_circle : finding.icon,
                  size: 34,
                  color: finding.iconColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            finding.shortLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SkinSamplePainter extends CustomPainter {
  const _SkinSamplePainter(this.finding);

  final SkinFinding finding;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [finding.skinLight, finding.skinBase, finding.skinDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(rrect, basePaint);

    final highlight = Paint()..color = Colors.white.withValues(alpha: finding.highlightAlpha);
    canvas.drawOval(Rect.fromLTWH(size.width * .16, size.height * .12, size.width * .42, size.height * .20), highlight);

    if (finding.showSweat) {
      final sweatPaint = Paint()..color = Colors.white.withValues(alpha: .72);
      for (final point in [
        Offset(size.width * .25, size.height * .25),
        Offset(size.width * .62, size.height * .28),
        Offset(size.width * .42, size.height * .58),
        Offset(size.width * .73, size.height * .68),
      ]) {
        final path = Path()
          ..moveTo(point.dx, point.dy - 8)
          ..quadraticBezierTo(point.dx + 8, point.dy + 2, point.dx, point.dy + 13)
          ..quadraticBezierTo(point.dx - 8, point.dy + 2, point.dx, point.dy - 8)
          ..close();
        canvas.drawPath(path, sweatPaint);
      }
    }

    if (finding.showDryLines) {
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: .38)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < 5; i++) {
        final y = size.height * (.26 + i * .12);
        final path = Path()
          ..moveTo(size.width * .18, y)
          ..quadraticBezierTo(size.width * .38, y - 9, size.width * .58, y)
          ..quadraticBezierTo(size.width * .72, y + 7, size.width * .84, y - 2);
        canvas.drawPath(path, linePaint);
      }
    }

    if (finding.showMottling) {
      final blotchPaint = Paint()..color = const Color(0xFF7C3AED).withValues(alpha: .22);
      for (final rect in [
        Rect.fromCircle(center: Offset(size.width * .25, size.height * .30), radius: 18),
        Rect.fromCircle(center: Offset(size.width * .68, size.height * .42), radius: 22),
        Rect.fromCircle(center: Offset(size.width * .38, size.height * .72), radius: 24),
        Rect.fromCircle(center: Offset(size.width * .78, size.height * .77), radius: 16),
      ]) {
        canvas.drawOval(rect, blotchPaint);
      }
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withValues(alpha: .08);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SkinSamplePainter oldDelegate) => oldDelegate.finding != finding;
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.emsBlue),
          const SizedBox(width: 10),
          Text('$label: ', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          Expanded(child: Text(value, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
        ],
      ),
    );
  }
}

enum SkinFinding {
  normal,
  paleCoolClammy,
  flushedHotDry,
  wetDiaphoretic,
  dryHot,
  cyanotic,
  mottled;

  String get shortLabel => switch (this) {
        SkinFinding.normal => 'Warm / Pink / Dry',
        SkinFinding.paleCoolClammy => 'Pale / Cool / Clammy',
        SkinFinding.flushedHotDry => 'Flushed / Hot / Dry',
        SkinFinding.wetDiaphoretic => 'Wet / Diaphoretic',
        SkinFinding.dryHot => 'Dry / Hot',
        SkinFinding.cyanotic => 'Cyanotic',
        SkinFinding.mottled => 'Mottled',
      };

  String get colorText => switch (this) {
        SkinFinding.normal => 'Pink / appropriate for baseline',
        SkinFinding.paleCoolClammy => 'Pale',
        SkinFinding.flushedHotDry => 'Flushed / red',
        SkinFinding.wetDiaphoretic => 'May be pale or ashen',
        SkinFinding.dryHot => 'May be flushed',
        SkinFinding.cyanotic => 'Blue / gray around lips or nail beds',
        SkinFinding.mottled => 'Blotchy / uneven color',
      };

  String get tempText => switch (this) {
        SkinFinding.normal => 'Warm',
        SkinFinding.paleCoolClammy => 'Cool',
        SkinFinding.flushedHotDry => 'Hot',
        SkinFinding.wetDiaphoretic => 'Cool or warm',
        SkinFinding.dryHot => 'Hot',
        SkinFinding.cyanotic => 'Variable',
        SkinFinding.mottled => 'Cool or poor perfusion',
      };

  String get moistureText => switch (this) {
        SkinFinding.normal => 'Dry',
        SkinFinding.paleCoolClammy => 'Clammy',
        SkinFinding.flushedHotDry => 'Dry',
        SkinFinding.wetDiaphoretic => 'Wet / sweaty',
        SkinFinding.dryHot => 'Dry',
        SkinFinding.cyanotic => 'Variable',
        SkinFinding.mottled => 'Variable',
      };

  String get charting => switch (this) {
        SkinFinding.normal => 'Example: Skin warm, pink, and dry.',
        SkinFinding.paleCoolClammy => 'Example: Skin pale, cool, and clammy.',
        SkinFinding.flushedHotDry => 'Example: Skin flushed, hot, and dry.',
        SkinFinding.wetDiaphoretic => 'Example: Skin diaphoretic; note color and temperature.',
        SkinFinding.dryHot => 'Example: Skin hot and dry; consider fever/heat exposure in context.',
        SkinFinding.cyanotic => 'Example: Cyanosis noted around lips/nail beds.',
        SkinFinding.mottled => 'Example: Mottled skin noted; reassess perfusion and overall presentation.',
      };

  String get studentNote => switch (this) {
        SkinFinding.normal => 'Normal skin signs should still be documented clearly. Avoid writing only “skin normal.”',
        SkinFinding.paleCoolClammy => 'Think poor perfusion, shock, pain, anxiety, or other sympathetic response. Compare with pulse, BP, and mental status.',
        SkinFinding.flushedHotDry => 'Think fever, heat illness, exertion, or sepsis depending on the rest of the assessment.',
        SkinFinding.wetDiaphoretic => 'Diaphoresis can be important with chest pain, shock, hypoglycemia, or distress.',
        SkinFinding.dryHot => 'Hot dry skin may be concerning with heat illness. Treat based on protocols and the full patient picture.',
        SkinFinding.cyanotic => 'Cyanosis is a serious oxygenation/perfusion warning sign. Assess airway, breathing, SpO₂, and mental status.',
        SkinFinding.mottled => 'Mottling can suggest poor perfusion, shock, sepsis, or severe illness. Recheck vitals and trend changes.',
      };

  Color get skinLight => switch (this) {
        SkinFinding.normal => const Color(0xFFFFC49A),
        SkinFinding.paleCoolClammy => const Color(0xFFFFE1C8),
        SkinFinding.flushedHotDry => const Color(0xFFFF9A82),
        SkinFinding.wetDiaphoretic => const Color(0xFFFFCDB2),
        SkinFinding.dryHot => const Color(0xFFFFB083),
        SkinFinding.cyanotic => const Color(0xFFC7D2FE),
        SkinFinding.mottled => const Color(0xFFD9B59A),
      };

  Color get skinBase => switch (this) {
        SkinFinding.normal => const Color(0xFFEAA06F),
        SkinFinding.paleCoolClammy => const Color(0xFFE9CDB9),
        SkinFinding.flushedHotDry => const Color(0xFFFF5A5F),
        SkinFinding.wetDiaphoretic => const Color(0xFFE7A779),
        SkinFinding.dryHot => const Color(0xFFFF7A59),
        SkinFinding.cyanotic => const Color(0xFF7F9CF5),
        SkinFinding.mottled => const Color(0xFFC9997B),
      };

  Color get skinDark => switch (this) {
        SkinFinding.normal => const Color(0xFFC97A4D),
        SkinFinding.paleCoolClammy => const Color(0xFFCBB8AA),
        SkinFinding.flushedHotDry => const Color(0xFFD73745),
        SkinFinding.wetDiaphoretic => const Color(0xFFC7815B),
        SkinFinding.dryHot => const Color(0xFFD75A37),
        SkinFinding.cyanotic => const Color(0xFF4455A8),
        SkinFinding.mottled => const Color(0xFF9B6E86),
      };

  IconData get icon => switch (this) {
        SkinFinding.normal => Icons.check_circle,
        SkinFinding.paleCoolClammy => Icons.ac_unit,
        SkinFinding.flushedHotDry => Icons.local_fire_department,
        SkinFinding.wetDiaphoretic => Icons.water_drop,
        SkinFinding.dryHot => Icons.wb_sunny,
        SkinFinding.cyanotic => Icons.air,
        SkinFinding.mottled => Icons.warning_amber,
      };

  Color get iconColor => switch (this) {
        SkinFinding.normal => const Color(0xFF16A34A),
        SkinFinding.paleCoolClammy => const Color(0xFF2563EB),
        SkinFinding.flushedHotDry => const Color(0xFFDC2626),
        SkinFinding.wetDiaphoretic => const Color(0xFF0EA5E9),
        SkinFinding.dryHot => const Color(0xFFF97316),
        SkinFinding.cyanotic => const Color(0xFF3730A3),
        SkinFinding.mottled => const Color(0xFF7C3AED),
      };

  bool get showSweat => this == SkinFinding.paleCoolClammy || this == SkinFinding.wetDiaphoretic;
  bool get showDryLines => this == SkinFinding.flushedHotDry || this == SkinFinding.dryHot;
  bool get showMottling => this == SkinFinding.mottled;
  double get highlightAlpha => showSweat ? .44 : .24;
}
