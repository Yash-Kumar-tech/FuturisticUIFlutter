import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shaders_example/assets.dart';
import 'package:shaders_example/shaders/cust_shader_config.dart';
import 'package:shaders_example/shaders/cust_shader_widget.dart';
import 'package:shaders_example/styles.dart';
import 'package:shaders_example/title_screen/particle_overlay.dart';
import 'package:shaders_example/title_screen/title_screen_ui.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  final _orbKey = GlobalKey<CustShaderWidgetState>();
  final _minReceiveLightAmt = .35;
  final _maxReceiveLightAmt = .7;

  final _minEmitLightAmt = .5;
  final _maxEmitLightAmt = 1;

  var _mousePos = Offset.zero;

  Color get _emitColor =>
      AppColors.emitColors[_difficultyOverride ?? _difficulty];

  Color get _orbColor =>
      AppColors.orbColors[_difficultyOverride ?? _difficulty];

  int _difficulty = 0;

  int? _difficultyOverride;
  double _orbEnergy = 0;
  double _minOrbEnergy = 0;

  double get _finalReceiveLightAmt {
    final light =
        lerpDouble(_minReceiveLightAmt, _maxReceiveLightAmt, _orbEnergy) ?? 0;
    return light + _pulseEffect.value * .05 * _orbEnergy;
  }

  double get _finalEmitLightAmt {
    return lerpDouble(_minEmitLightAmt, _maxEmitLightAmt, _orbEnergy) ?? 0;
  }

  late final _pulseEffect = AnimationController(
    vsync: this,
    duration: _getRndPulseDuration(),
    lowerBound: -1,
    upperBound: 1,
  );

  @override
  void initState() {
    super.initState();
    _pulseEffect.forward();
    _pulseEffect.addListener(_handlePulseEffectUpdate);
  }

  void _handlePulseEffectUpdate() {
    if (_pulseEffect.status == AnimationStatus.completed) {
      _pulseEffect.reverse();
      _pulseEffect.duration = _getRndPulseDuration();
    } else if (_pulseEffect.status == AnimationStatus.dismissed) {
      _pulseEffect.duration = _getRndPulseDuration();
      _pulseEffect.forward();
    }
  }

  Duration _getRndPulseDuration() => 100.ms + 200.ms * Random().nextDouble();

  void _handleDifficultyPressed(int value) {
    setState(() => _difficulty = value);
    _bumpMinEnergy();
  }

  void _handleDifficultyFocused(int? value) {
    setState(() {
      _difficultyOverride = value;
      if (value == null) {
        _minOrbEnergy = _getMinEnergyForDifficulty(_difficulty);
      } else {
        _minOrbEnergy = _getMinEnergyForDifficulty(value);
      }
    });
  }

  void _handleMouseMove(PointerHoverEvent e) {
    setState(() {
      _mousePos = e.localPosition;
    });
  }

  void _handleStartPressed() => _bumpMinEnergy(0.3);

  Future<void> _bumpMinEnergy([double amount = 0.1]) async {
    setState(() {
      _minOrbEnergy = _getMinEnergyForDifficulty(_difficulty) + amount;
    });
    await Future<void>.delayed(.2.seconds);
    setState(() {
      _minOrbEnergy = _getMinEnergyForDifficulty(_difficulty);
    });
  }

  double _getMinEnergyForDifficulty(int difficulty) => switch (difficulty) {
        1 => 0.3,
        2 => 0.6,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: MouseRegion(
          onHover: _handleMouseMove,
          child: _AnimatedColors(
            orbColor: _orbColor,
            emitColor: _emitColor,
            builder: (_, orbColor, emitColor) {
              return Stack(
                children: [
                  Image.asset(AssetPaths.titleBgBase),
                  _LitImage(
                    color: _orbColor,
                    imgSrc: AssetPaths.titleBgReceive,
                    lightAmt: _finalReceiveLightAmt,
                    pulseEffect: _pulseEffect,
                  ),
                  Positioned.fill(
                      child: Stack(
                    children: [
                      CustShaderWidget(
                        key: _orbKey,
                        mousePos: _mousePos,
                        minEnergy: _minOrbEnergy,
                        config: CustShaderConfig(
                          ambientLightColor: orbColor,
                          materialColor: orbColor,
                          lightColor: orbColor,
                        ),
                        onUpdate: (energy) => setState(() {
                          _orbEnergy = energy;
                        }),
                      ),
                    ],
                  )),
                  _LitImage(
                    color: _orbColor,
                    imgSrc: AssetPaths.titleMgBase,
                    lightAmt: _finalReceiveLightAmt,
                    pulseEffect: _pulseEffect,
                  ),
                  _LitImage(
                    color: _orbColor,
                    imgSrc: AssetPaths.titleMgReceive,
                    lightAmt: _finalReceiveLightAmt,
                    pulseEffect: _pulseEffect,
                  ),
                  _LitImage(
                    color: _emitColor,
                    imgSrc: AssetPaths.titleMgEmit,
                    lightAmt: _finalEmitLightAmt,
                    pulseEffect: _pulseEffect,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ParticleOverlay(
                        color: orbColor,
                        energy: _orbEnergy,
                      ),
                    ),
                  ),
                  Image.asset(AssetPaths.titleFgBase),
                  _LitImage(
                    color: _orbColor,
                    imgSrc: AssetPaths.titleFgReceive,
                    lightAmt: _finalReceiveLightAmt,
                    pulseEffect: _pulseEffect,
                  ),
                  _LitImage(
                    color: _emitColor,
                    imgSrc: AssetPaths.titleFgEmit,
                    lightAmt: _finalEmitLightAmt,
                    pulseEffect: _pulseEffect,
                  ),
                  Positioned.fill(
                    child: TitleScreenUi(
                      difficulty: _difficulty,
                      onDifficultyPressed: _handleDifficultyPressed,
                      onDifficultyFocused: _handleDifficultyFocused,
                      onStartPressed: _handleStartPressed,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 1.seconds, delay: .3.seconds);
            },
          ),
        ),
      ),
    );
  }
}

class _LitImage extends StatelessWidget {
  final Color color;
  final String imgSrc;
  final double lightAmt;
  final AnimationController pulseEffect;

  const _LitImage({
    super.key,
    required this.color,
    required this.imgSrc,
    required this.lightAmt,
    required this.pulseEffect,
  });

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    return ListenableBuilder(
      listenable: pulseEffect,
      builder: (context, child) {
        return Image.asset(
          imgSrc,
          color: hsl.withLightness(hsl.lightness * lightAmt).toColor(),
          colorBlendMode: BlendMode.modulate,
        );
      },
    );
  }
}

class _AnimatedColors extends StatelessWidget {
  final Color emitColor;
  final Color orbColor;
  final Widget Function(BuildContext context, Color orbColor, Color emitColor)
      builder;

  const _AnimatedColors({
    required this.emitColor,
    required this.orbColor,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final duration = .5.seconds;
    return TweenAnimationBuilder(
      tween: ColorTween(begin: emitColor, end: emitColor),
      duration: duration,
      builder: (_, emitColor, __) {
        return TweenAnimationBuilder(
          tween: ColorTween(begin: orbColor, end: orbColor),
          duration: duration,
          builder: (context, orbColor, __) {
            return builder(context, orbColor!, emitColor!);
          },
        );
      },
    );
  }
}
