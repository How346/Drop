import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// The HyperDrop logo mark — a gradient bolt in a rounded square. Used in the
/// nav rail, app bar and home hero so the brand feels consistent everywhere.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36, this.iconSize});
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: HDColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: HDShadows.glow(HDColors.primary),
      ),
      child: Icon(Icons.bolt_rounded, color: Colors.white, size: iconSize ?? size * 0.6),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.icon});
  final String text;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon, this.dot = false});
  final String label;
  final Color color;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ] else if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
        ],
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

IconData iconForKind(DeviceKind kind) {
  switch (kind) {
    case DeviceKind.androidPhone:
      return Icons.smartphone_rounded;
    case DeviceKind.androidTablet:
      return Icons.tablet_mac_rounded;
    case DeviceKind.windowsDesktop:
      return Icons.desktop_windows_rounded;
    case DeviceKind.windowsLaptop:
      return Icons.laptop_mac_rounded;
  }
}

/// Small icon badge with a soft tinted background — used throughout for
/// device kinds, file types and stat rows.
class HDIconBadge extends StatelessWidget {
  const HDIconBadge({
    super.key,
    required this.icon,
    this.color = HDColors.primary,
    this.size = 40,
    this.iconSize,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, size: iconSize ?? size * 0.5, color: color),
    );
  }
}

class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.device,
    this.trusted = false,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final Device device;
  final bool trusted;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? HDColors.primary.withOpacity(dark ? 0.14 : 0.08)
            : (dark ? HDColors.darkRaised : HDColors.lightRaised),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? HDColors.primary : (dark ? HDColors.darkBorder : HDColors.lightBorder),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              HDIconBadge(icon: iconForKind(device.kind)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(device.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (trusted) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 15, color: HDColors.accent),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text('${device.address}:${device.port}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  size: 20,
                  color: selected
                      ? HDColors.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: dark ? HDColors.darkRaised2 : HDColors.lightRaised,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(body,
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

/// Fades and gently slides its child in — used for lightweight, tasteful
/// page-level entrance motion without adding a dependency.
class HDFadeIn extends StatelessWidget {
  const HDFadeIn({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
        );
      },
      child: child,
    );
  }
}

/// A minimal live throughput chart — deliberately dependency-free. Draws a
/// smoothed line through recent speed samples so a transfer's live rate
/// feels tangible, not just a number that jumps around.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.color = HDColors.primary, this.height = 40});
  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(max) * 1.15 + 1;
    final stepX = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final x = i * stepX;
      final y = size.height - (values[i] / maxV) * size.height;
      return Offset(x, y.clamp(0, size.height));
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p0 = pointAt(i - 1);
      final p1 = pointAt(i);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      line.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    line.lineTo(pointAt(values.length - 1).dx, pointAt(values.length - 1).dy);

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.28), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values.length != values.length ||
      (values.isNotEmpty && oldDelegate.values.last != values.last);
}

/// A compact stat card used for lifetime totals (bytes sent/received) and
/// similar at-a-glance figures.
class HDStatTile extends StatelessWidget {
  const HDStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = HDColors.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HDPanel(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        HDIconBadge(icon: icon, color: color, size: 38, iconSize: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ]),
    );
  }
}
