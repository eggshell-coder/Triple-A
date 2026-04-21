// our_story_screen.dart  — NEW FILE
// Route: /about
// Added to navbar as "Our Story"

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OurStoryScreen extends StatelessWidget {
  const OurStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('OUR STORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              height: 260,
              color: const Color(0xFF1A1A1A),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TRIPLE A',
                    style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Born in Dhaka. Built for the streets.',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14, letterSpacing: 1),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeading('Who We Are'),
                  SizedBox(height: 12),
                  _BodyText(
                    'Triple A is a Dhaka-based premium T-shirt brand founded by students of East West University. '
                    'We believe that great style doesn\'t require a great price tag — it requires great design, quality fabric, '
                    'and a brand that actually understands its people.',
                  ),
                  SizedBox(height: 32),

                  _SectionHeading('Our Mission'),
                  SizedBox(height: 12),
                  _BodyText(
                    'To put premium, locally-made T-shirts within reach of every young person in Bangladesh. '
                    'We cut out the middlemen, work directly with manufacturers, and pass the savings on to you. '
                    'Every piece we release is a statement — minimalist, intentional, and made to last.',
                  ),
                  SizedBox(height: 32),

                  _SectionHeading('Why T-shirts?'),
                  SizedBox(height: 12),
                  _BodyText(
                    'A great T-shirt is the most versatile item in your wardrobe. It\'s the first thing you reach for. '
                    'We specialise in six cuts — Oversized, Polo, Full-Sleeve, Half-Sleeve, Drop-Shoulder, and Basic — '
                    'because we\'d rather do six things perfectly than fifty things poorly.',
                  ),
                  SizedBox(height: 32),

                  _SectionHeading('Made in Bangladesh'),
                  SizedBox(height: 12),
                  _BodyText(
                    'Bangladesh is the garment capital of the world. We\'re proud of that. '
                    'Triple A T-shirts are designed, sourced, and fulfilled entirely within Bangladesh. '
                    'When you buy Triple A, you\'re supporting local craft and local economy.',
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
  );
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF444444)),
  );
}