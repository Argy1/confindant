import 'package:confindant/app/theme/app_gradients.dart';
import 'package:flutter/material.dart';

class AppGradientScaffold extends StatelessWidget {
  const AppGradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding = EdgeInsets.zero,
    this.safeArea = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsets padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: body);

    return Scaffold(
      appBar: appBar,
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: safeArea ? SafeArea(child: content) : content,
      ),
    );
  }
}
