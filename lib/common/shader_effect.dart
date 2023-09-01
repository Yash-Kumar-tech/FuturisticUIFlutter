import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';

@immutable
class ShaderEffect extends Effect<double> {
  final ui.FragmentShader? shader;
  final ShaderUpdateCallback? update;
  final ShaderLayer layer;

  const ShaderEffect({
    super.delay,
    super.duration,
    super.curve,
    this.shader,
    this.update,
    ShaderLayer? layer,
  })  : layer = layer ?? ShaderLayer.replace,
        super(begin: 0, end: 1);

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    double ratio = 1 / MediaQuery.of(context).devicePixelRatio;
    Animation<double> animation = buildAnimation(controller, entry);
    return getOptimizedBuilder<double>(
      animation: animation,
      builder: (_, __) {
        return AnimatedSampler(
          (image, size, canvas) {
            EdgeInsets? insets;
            if (update != null) {
              insets = update!(shader!, animation.value, size, image);
            }
            Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
            rect = insets?.inflateRect(rect) ?? rect;

            void drawImage() {
              canvas.save();
              canvas.scale(ratio, ratio);
              canvas.drawImage(image, Offset.zero, Paint());
              canvas.restore();
            }

            if (layer == ShaderLayer.foreground) drawImage();
            if (shader != null) canvas.drawRect(rect, Paint()..shader = shader);
            if (layer == ShaderLayer.background) drawImage();
          },
          enabled: shader != null,
          child: child,
        );
      },
    );
  }
}

extension ShaderEffectExtensions<T> on AnimateManager<T> {
  T shader({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    ui.FragmentShader? shader,
    ShaderUpdateCallback? update,
    ShaderLayer? layer,
  }) =>
      addEffect(ShaderEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        shader: shader,
        update: update,
        layer: layer,
      ));
}

enum ShaderLayer { foreground, background, replace }

typedef ShaderUpdateCallback = EdgeInsets? Function(
  ui.FragmentShader shader,
  double value,
  Size size,
  ui.Image image,
);

typedef AnimatedSamplerBuilder = void Function(
  ui.Image image,
  Size size,
  ui.Canvas canvas,
);

class AnimatedSampler extends StatelessWidget {
  final AnimatedSamplerBuilder builder;
  final bool enabled;
  final Widget child;

  const AnimatedSampler(
    this.builder, {
    super.key,
    this.enabled = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _ShaderSamplerBuilder(
      builder,
      enabled: enabled,
      child: child,
    );
  }
}

class _ShaderSamplerBuilder extends SingleChildRenderObjectWidget {
  final AnimatedSamplerBuilder builder;
  final bool enabled;

  const _ShaderSamplerBuilder(this.builder,
      {required this.enabled, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderShaderSamplerBuilderWidget(
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
      builder: builder,
      enabled: enabled,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderShaderSamplerBuilderWidget)
      ..devicePixelRatio = MediaQuery.of(context).devicePixelRatio
      ..builder = builder
      ..enabled = enabled;
  }
}

class _RenderShaderSamplerBuilderWidget extends RenderProxyBox {
  // Create a new [_RenderSnapshotWidget].
  _RenderShaderSamplerBuilderWidget({
    required double devicePixelRatio,
    required AnimatedSamplerBuilder builder,
    required bool enabled,
  })  : _devicePixelRatio = devicePixelRatio,
        _builder = builder,
        _enabled = enabled;

  @override
  OffsetLayer updateCompositedLayer(
      {required covariant _ShaderSamplerBuilderLayer? oldLayer}) {
    final _ShaderSamplerBuilderLayer layer =
        oldLayer ?? _ShaderSamplerBuilderLayer(builder);
    layer
      ..callback = builder
      ..size = size
      ..devicePixelRatio = devicePixelRatio;
    return layer;
  }

  /// The device pixel ratio used to create the child image.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsCompositedLayerUpdate();
  }

  /// The painter used to paint the child snapshot or child widgets.
  AnimatedSamplerBuilder get builder => _builder;
  AnimatedSamplerBuilder _builder;
  set builder(AnimatedSamplerBuilder value) {
    if (value == builder) {
      return;
    }
    _builder = value;
    markNeedsCompositedLayerUpdate();
  }

  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (value == enabled) {
      return;
    }
    _enabled = value;
    markNeedsPaint();
    markNeedsCompositingBitsUpdate();
  }

  @override
  bool get isRepaintBoundary => alwaysNeedsCompositing;

  @override
  bool get alwaysNeedsCompositing => enabled;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty || !_enabled) {
      return;
    }
    assert(offset == Offset.zero);
    return super.paint(context, offset);
  }
}

/// A [Layer] that uses an [AnimatedSamplerBuilder] to create a [ui.Picture]
/// every time it is added to a scene.
class _ShaderSamplerBuilderLayer extends OffsetLayer {
  _ShaderSamplerBuilderLayer(this._callback);

  Size get size => _size;
  Size _size = Size.zero;
  set size(Size value) {
    if (value == size) {
      return;
    }
    _size = value;
    markNeedsAddToScene();
  }

  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio = 1.0;
  set devicePixelRatio(double value) {
    if (value == devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsAddToScene();
  }

  AnimatedSamplerBuilder get callback => _callback;
  AnimatedSamplerBuilder _callback;
  set callback(AnimatedSamplerBuilder value) {
    if (value == callback) {
      return;
    }
    _callback = value;
    markNeedsAddToScene();
  }

  ui.Image _buildChildScene(Rect bounds, double pixelRatio) {
    final ui.SceneBuilder builder = ui.SceneBuilder();
    final Matrix4 transform =
        Matrix4.diagonal3Values(pixelRatio, pixelRatio, 1);
    builder.pushTransform(transform.storage);
    addChildrenToScene(builder);
    builder.pop();
    return builder.build().toImageSync(
          (pixelRatio * bounds.width).ceil(),
          (pixelRatio * bounds.height).ceil(),
        );
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    if (size.isEmpty) return;
    final ui.Image image = _buildChildScene(
      offset & size,
      devicePixelRatio,
    );
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    try {
      callback(image, size, canvas);
    } finally {
      image.dispose();
    }
    final ui.Picture picture = pictureRecorder.endRecording();
    builder.addPicture(offset, picture);
  }
}
