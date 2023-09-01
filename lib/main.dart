import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shaders_example/assets.dart';
import 'package:shaders_example/title_screen/title_screen.dart';
import 'package:window_size/window_size.dart';

void main() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isLinux)) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowMinSize(const Size(800, 600));
  }
  Animate.restartOnHotReload = true;
  runApp(
    FutureProvider<FragmentPrograms?>(
      create: (context) => loadFragmentPrograms(),
      initialData: null,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: const TitleScreen(),
    );
  }
}
