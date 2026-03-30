import 'package:flutter/material.dart';

/// Soft entrance used when a screen or sheet first appears.
class ScreenEntrance extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset beginOffset;

  const ScreenEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 620),
    this.beginOffset = const Offset(0, 0.14),
  });

  @override
  State<ScreenEntrance> createState() => _ScreenEntranceState();
}

class _ScreenEntranceState extends State<ScreenEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Staggered fade + slide for a vertical list of blocks (dashboard sections, forms).
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final double beginSlideY;
  final int staggerMs;
  final int baseDurationMs;

  const StaggeredColumn({
    super.key,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.beginSlideY = 0.22,
    this.staggerMs = 64,
    this.baseDurationMs = 520,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _StaggeredColumnBody(
      key: ValueKey(children.length),
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      beginSlideY: beginSlideY,
      staggerMs: staggerMs,
      baseDurationMs: baseDurationMs,
      children: children,
    );
  }
}

class _StaggeredColumnBody extends StatefulWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final double beginSlideY;
  final int staggerMs;
  final int baseDurationMs;

  const _StaggeredColumnBody({
    super.key,
    required this.crossAxisAlignment,
    required this.mainAxisAlignment,
    required this.beginSlideY,
    required this.staggerMs,
    required this.baseDurationMs,
    required this.children,
  });

  @override
  State<_StaggeredColumnBody> createState() => _StaggeredColumnBodyState();
}

class _StaggeredColumnBodyState extends State<_StaggeredColumnBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late List<Animation<double>> _itemAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    final n = widget.children.length;
    final totalMs = widget.baseDurationMs +
        (n > 0 ? (n - 1) * widget.staggerMs : 0);
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs.clamp(420, 1800)),
    );

    _itemAnims = List.generate(n, (i) {
      final interval = _staggerInterval(i, n);
      return CurvedAnimation(
        parent: _c,
        curve: Interval(interval.$1, interval.$2, curve: Curves.easeOutCubic),
      );
    });

    _slideAnims = List.generate(n, (i) {
      return Tween<Offset>(
        begin: Offset(0, widget.beginSlideY),
        end: Offset.zero,
      ).animate(_itemAnims[i]);
    });

    _c.forward();
  }

  /// (start, end) in 0..1 for stagger item [index] of [count].
  static (double, double) _staggerInterval(int index, int count) {
    if (count <= 1) return (0.0, 1.0);
    final step = 0.65 / (count + 0.5);
    final start = (index * step).clamp(0.0, 0.85);
    final end = (start + 0.42).clamp(start + 0.08, 1.0);
    return (start, end);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) {
      return Column(
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisAlignment: widget.mainAxisAlignment,
        children: widget.children,
      );
    }
    final n = widget.children.length;
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisAlignment: widget.mainAxisAlignment,
      children: [
        for (int i = 0; i < n; i++)
          FadeTransition(
            opacity: _itemAnims[i],
            child: SlideTransition(
              position: _slideAnims[i],
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}

/// Light press feedback for tappable rows and chips.
class AnimatedTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const AnimatedTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<AnimatedTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animating = TickerMode.valuesOf(context).enabled;
    return GestureDetector(
      onTapDown: (_) {
        if (animating) _c.forward();
      },
      onTapUp: (_) {
        if (animating) _c.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        if (animating) _c.reverse();
      },
      child: animating
          ? ScaleTransition(
              scale: _scale,
              child: widget.child,
            )
          : widget.child,
    );
  }
}
