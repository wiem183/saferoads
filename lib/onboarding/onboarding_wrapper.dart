// ignore_for_file: use_super_parameters

import 'package:covoiturage_app/screens/choice_screen.dart';
import 'package:flutter/material.dart';
import 'onboarding_page.dart';

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({Key? key}) : super(key: key);

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_current == 1) {
      // Navigate to HomeShell after onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                children: [
                  OnboardingPage(
                    imagePath: 'assets/images/bus.png',
                    title: 'Public transport\nwasting too much\nneeded time?',
                    body: '',
                    onNext: _next,
                  ),
                  OnboardingPage(
                    imagePath: 'assets/images/car.png',
                    title: 'Need a car to get home?',
                    body: '',
                    onNext: _next,
                    isLastPage: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _current == i ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
