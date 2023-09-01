import 'package:flutter/material.dart';

import 'ticking_builder.dart';

typedef ReactiveWidgetBuilder = Widget Function(
    BuildContext context, double time, Size bounds);

class ReactiveWidget extends StatefulWidget {
  final ReactiveWidgetBuilder builder;
  const ReactiveWidget({
    super.key,
    required this.builder,
  });

  @override
  State<ReactiveWidget> createState() => _ReactWidgetState();
}

class _ReactWidgetState extends State<ReactiveWidget> {
  @override
  Widget build(BuildContext context) {
    return TickingBuilder(
      builder: (_, time) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return widget.builder(context, time, constraints.biggest);
          },
        );
      },
    );
  }
}
