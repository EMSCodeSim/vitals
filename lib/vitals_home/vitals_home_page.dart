import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class VitalsHomePage extends StatelessWidget {
  const VitalsHomePage({super.key});

  static const Color _navy = Color(0xFF061326);
  static const Color _navy2 = Color(0xFF0A1D3A);
  static const Color _card = Color(0xFF0D1F3A);
  static const Color _line = Color(0xFF163A69);
  static const Color _muted = Color(0xFF9FB3CB);
  static const Color _cyan = Color(0xFF22D3FF);
  static const Color _blue = Color(0xFF1677FF);
  static const Color _red = Color(0xFFFF4B55);
  static const Color _orange = Color(0xFFFFA51F);

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, TrainingMode>((s) => s.mode);
    final instructor = context.select<AppState, bool>((s) => s.instructorMode);

    return Scaffold(
      backgroundColor: _navy,
      bottomNavigationBar: _BottomNav(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_navy, Color(0xFF071A33), _navy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              _TopBar(mode: mode, instructor: instructor),
              const SizedBox(height: 18),
              const _BrandHero(),
              const SizedBox(height: 20),
              _StartVitalsCard(
                onStart: () => context.push(AppRoutes.learnVitals),
                onSkip: () => context.push(AppRoutes.assessmentTools),
              ),
              const SizedBox(height: 14),
              _MainActionTile(
                icon: Icons.monitor_heart,
                iconColor: _red,
                title: 'Vitals',
                subtitle: 'Walkthroughs & practice',
                onTap: () => context.push(AppRoutes.learnVitals),
              ),
              _MainActionTile(
                icon: Icons.fact_check,
                iconColor: _blue,
                title: 'Assessment Tools',
                subtitle: 'SAMPLE, OPQRST, primary assessment',
                onTap: () => context.push(AppRoutes.assessmentTools),
              ),
              _MainActionTile(
                icon: Icons.person_search,
                iconColor: const Color(0xFF23D6C8),
                title: 'Patient Assessment',
                subtitle: 'Put it all together',
                onTap: () {
                  context.read<AppState>().markModuleOpened(TrainingModule.walkthrough);
                  context.push(AppRoutes.walkthrough);
                },
              ),
              _SmallFeatureTile(
                icon: Icons.medication,
                title: 'Treatments & Meds',
                subtitle: 'Common treatments & medications',
                label: 'NEW',
                onTap: () {
                  context.read<AppState>().markModuleOpened(TrainingModule.treatments);
                  context.push(AppRoutes.treatments);
                },
              ),
              const SizedBox(height: 10),
              _NormalNotNormalCard(),
              const SizedBox(height: 12),
              _ModeStrip(mode: mode),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.mode, required this.instructor});
  final TrainingMode mode;
  final bool instructor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: const Icon(Icons.menu_rounded, color: Colors.white70),
        ),
        const Spacer(),
        _TopPill(icon: Icons.school, label: mode.label),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => context.read<AppState>().setInstructorMode(!instructor),
          child: _TopPill(
            icon: instructor ? Icons.visibility : Icons.visibility_off,
            label: instructor ? 'Instructor' : 'Student',
          ),
        ),
      ],
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF9CC9FF)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'EMS', style: TextStyle(color: Color(0xFF2281FF), fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
              TextSpan(text: 'Code', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
              TextSpan(text: 'Sim', style: TextStyle(color: Color(0xFFFF4B55), fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'EMT Patient Assessment Trainer',
          style: TextStyle(color: Color(0xFF9FB3CB), fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        const SizedBox(height: 154, child: _HeroGraphic()),
      ],
    );
  }
}

class _HeroGraphic extends StatelessWidget {
  const _HeroGraphic();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CustomPaint(painter: _EmsHeroPainter())),
        Icon(Icons.medical_services, size: 104, color: const Color(0xFF1677FF).withValues(alpha: 0.20)),
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [const Color(0xFF1677FF).withValues(alpha: 0.18), Colors.transparent]),
          ),
        ),
      ],
    );
  }
}

class _EmsHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final glowBlue = Paint()
      ..color = const Color(0xFF22D3FF).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final blue = Paint()
      ..color = const Color(0xFF22D3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final orange = Paint()
      ..color = const Color(0xFFFFA51F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final y = size.height * 0.55;
    final left = Path()
      ..moveTo(0, y)
      ..lineTo(size.width * .22, y)
      ..lineTo(size.width * .25, y - 12)
      ..lineTo(size.width * .28, y + 12)
      ..lineTo(size.width * .31, y - 54)
      ..lineTo(size.width * .35, y + 42)
      ..lineTo(size.width * .39, y)
      ..lineTo(size.width * .47, y);
    canvas.drawPath(left, glowBlue);
    canvas.drawPath(left, blue);

    final divider = Paint()
      ..color = const Color(0xFF22D3FF).withValues(alpha: .85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * .50, 38), Offset(size.width * .50, size.height - 16), divider);

    final right = Path()
      ..moveTo(size.width * .53, y)
      ..lineTo(size.width * .62, y)
      ..lineTo(size.width * .65, y - 20)
      ..lineTo(size.width * .69, y + 48)
      ..lineTo(size.width * .73, y - 44)
      ..lineTo(size.width * .78, y + 18)
      ..lineTo(size.width * .82, y - 14)
      ..lineTo(size.width * .86, y)
      ..lineTo(size.width, y);
    canvas.drawPath(right, Paint()..color = const Color(0xFFFFA51F).withValues(alpha: 0.24)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(right, orange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StartVitalsCard extends StatelessWidget {
  const _StartVitalsCard({required this.onStart, required this.onSkip});
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderColor: const Color(0xFF1677FF).withValues(alpha: 0.50),
      child: Column(
        children: [
          Row(
            children: [
              const _RoundIcon(icon: Icons.favorite_border, color: Color(0xFF1677FF), size: 66),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start with Vitals', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    SizedBox(height: 6),
                    Text('Learn what’s normal, what’s not normal, and why.', style: TextStyle(color: Color(0xFFC1D2E7), fontSize: 16, height: 1.3)),
                  ],
                ),
              ),
              _CircleArrow(onTap: onStart),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: .08)),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onSkip,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already know vitals? ', style: TextStyle(color: Color(0xFFAABBD0), fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('Skip ahead.', style: TextStyle(color: Color(0xFF39A2FF), fontSize: 15, fontWeight: FontWeight.w900)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 20, color: Color(0xFF39A2FF)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainActionTile extends StatelessWidget {
  const _MainActionTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            _RoundIcon(icon: icon, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFFAABBD0), fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC6D3E4), size: 38),
          ],
        ),
      ),
    );
  }
}

class _SmallFeatureTile extends StatelessWidget {
  const _SmallFeatureTile({required this.icon, required this.title, required this.subtitle, required this.label, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: const Color(0xFF7C3AED).withValues(alpha: .35),
      child: Row(
        children: [
          const _RoundIcon(icon: Icons.medication, color: Color(0xFF8B5CF6), size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFFAABBD0), fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: .22), borderRadius: BorderRadius.circular(10)),
            child: Text(label, style: const TextStyle(color: Color(0xFFC9A7FF), fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _NormalNotNormalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderColor: const Color(0xFF1677FF).withValues(alpha: .48),
      child: Row(
        children: [
          SizedBox(width: 74, height: 74, child: CustomPaint(painter: _MagnifyPulsePainter())),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Normal or Not Normal?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('❤️  Pulse 110 and irregular →', style: TextStyle(color: Color(0xFFE5EEF9), fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Not normal: fast and not regular.', style: TextStyle(color: Color(0xFFFF5E69), fontSize: 15, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MagnifyPulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF62B7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(size.width * .42, size.height * .42), size.width * .34, stroke);
    canvas.drawLine(Offset(size.width * .67, size.height * .67), Offset(size.width * .92, size.height * .92), stroke..strokeWidth = 6);
    final pulse = Path()
      ..moveTo(size.width * .16, size.height * .42)
      ..lineTo(size.width * .32, size.height * .42)
      ..lineTo(size.width * .39, size.height * .24)
      ..lineTo(size.width * .47, size.height * .60)
      ..lineTo(size.width * .54, size.height * .42)
      ..lineTo(size.width * .66, size.height * .42);
    canvas.drawPath(pulse, Paint()..color = const Color(0xFF22D3FF)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModeStrip extends StatelessWidget {
  const _ModeStrip({required this.mode});
  final TrainingMode mode;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(10),
      child: SegmentedButton<TrainingMode>(
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF1677FF) : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : const Color(0xFFC6D3E4)),
          side: WidgetStatePropertyAll(BorderSide(color: Colors.white.withValues(alpha: .10))),
        ),
        segments: const [
          ButtonSegment(value: TrainingMode.learn, label: Text('Learn'), icon: Icon(Icons.school)),
          ButtonSegment(value: TrainingMode.practice, label: Text('Practice'), icon: Icon(Icons.fitness_center)),
          ButtonSegment(value: TrainingMode.test, label: Text('Test'), icon: Icon(Icons.timer)),
        ],
        selected: {mode},
        onSelectionChanged: (s) => context.read<AppState>().setMode(s.first),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF071326),
      selectedItemColor: const Color(0xFF1677FF),
      unselectedItemColor: const Color(0xFF7F91A8),
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(AppRoutes.home);
            break;
          case 1:
            context.push(AppRoutes.learnVitals);
            break;
          case 2:
            context.push(AppRoutes.cases);
            break;
          case 3:
            context.push(AppRoutes.instructor);
            break;
          case 4:
            context.push(AppRoutes.settings);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learn'),
        BottomNavigationBarItem(icon: Icon(Icons.business_center), label: 'Cases'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Instructor'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.borderColor});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [const Color(0xFF102A4D).withValues(alpha: .92), const Color(0xFF091A31).withValues(alpha: .98)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: .10)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .24), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(24), onTap: onTap, child: card);
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color, this.size = 58});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: .70), color.withValues(alpha: .16)]),
        border: Border.all(color: color.withValues(alpha: .38)),
      ),
      child: Icon(icon, color: Colors.white, size: size * .46),
    );
  }
}

class _CircleArrow extends StatelessWidget {
  const _CircleArrow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(0xFF2196FF), Color(0xFF1263FF)]),
        ),
        child: const Icon(Icons.chevron_right, color: Colors.white, size: 36),
      ),
    );
  }
}
