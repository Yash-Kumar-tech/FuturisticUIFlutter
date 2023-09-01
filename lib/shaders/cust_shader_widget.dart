import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shaders_example/assets.dart';
import 'package:shaders_example/common/reactive_widget.dart';
import 'package:shaders_example/shaders/cust_shader_config.dart';
import 'package:shaders_example/shaders/cust_shader_painter.dart';

class CustShaderWidget extends StatefulWidget {
  const CustShaderWidget({
    super.key,
    required this.config,
    this.onUpdate,
    required this.mousePos,
    required this.minEnergy,
  });

  final double minEnergy;
  final CustShaderConfig config;
  final Offset mousePos;
  final void Function(double energy)? onUpdate;

  @override
  State<CustShaderWidget> createState() => CustShaderWidgetState();
}

class CustShaderWidgetState extends State<CustShaderWidget>
    with SingleTickerProviderStateMixin {
  final _sequence = TweenSequence(
    [
      TweenSequenceItem(tween: ConstantTween(0), weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 12),
      TweenSequenceItem(
          tween: Tween(begin: 0.2, end: 0.8)
              .chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 6),
      TweenSequenceItem(
          tween: Tween(begin: 0.8, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 10),
    ],
  );

  late final _anim = AnimationController(vsync: this, duration: 3000.ms)
    ..repeat();
  @override
  Widget build(BuildContext context) => Consumer<FragmentPrograms?>(
        builder: (context, fragmentPrograms, _) {
          if (fragmentPrograms == null) return const SizedBox.expand();
          return ListenableBuilder(
            listenable: _anim,
            builder: (_, __) {
              final energy = _anim.drive(_sequence).value;
              return TweenAnimationBuilder(
                tween: Tween<double>(
                    begin: widget.minEnergy, end: widget.minEnergy),
                duration: 300.ms,
                curve: Curves.easeOutCubic,
                builder: (context, minEnergy, child) {
                  return ReactiveWidget(builder: (context, time, size) {
                    double energyLevel = 0;
                    if (size.shortestSide != 0) {
                      final d = (Offset(size.width, size.height) / 2 -
                              widget.mousePos)
                          .distance;
                      final hitSize = size.shortestSide * .5;
                      energyLevel = 1 - min(1, (d / hitSize));
                      scheduleMicrotask(
                          () => widget.onUpdate?.call(energyLevel));
                    }
                    energyLevel += (1.3 - energyLevel) * energy * 0.1;
                    energyLevel = lerpDouble(minEnergy, 1, energyLevel)!;
                    return CustomPaint(
                      size: size,
                      painter: CustShaderPainter(
                        fragmentPrograms.orb.fragmentShader(),
                        config: widget.config,
                        time: time,
                        mousePos: widget.mousePos,
                        energy: energyLevel,
                      ),
                    );
                  });
                },
              );
            },
          );
        },
      );
}
