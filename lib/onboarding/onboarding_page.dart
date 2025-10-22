import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String? imagePath;       
  final String title;
  final String body;
  final VoidCallback? onNext;
  final bool isLastPage;

  const OnboardingPage({
    Key? key,
    this.imagePath,
    required this.title,
    required this.body,
    this.onNext,
    this.isLastPage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath!,
              height: size.height * .45,
              fit: BoxFit.contain,
            )
          else
            const SizedBox(height: 120),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: onNext,
              child: Text(isLastPage ? 'Commencer' : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }
}