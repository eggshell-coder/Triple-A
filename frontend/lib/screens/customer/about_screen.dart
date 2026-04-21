// lib/screens/customer/about_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../widgets/shared_widgets.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Hero Banner ───────────────────────────────────────────
            Container(
              height: isWide ? 400 : 280,
              decoration:
                  const BoxDecoration(color: AppColors.primaryContainer),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=1400&q=80',
                    fit: BoxFit.cover,
                    color: AppColors.primary.withOpacity(0.6),
                    colorBlendMode: BlendMode.multiply,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.primaryContainer),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 96 : 32, vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OUR STORY',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Born from a passion\nfor authentic craft.',
                          style: GoogleFonts.newsreader(
                            fontSize: isWide ? 52 : 34,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Brand Story ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 96 : 32, vertical: 64),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _storyText()),
                        const SizedBox(width: 80),
                        Expanded(flex: 4, child: _valuesCard()),
                      ],
                    )
                  : Column(children: [
                      _storyText(),
                      const SizedBox(height: 48),
                      _valuesCard(),
                    ]),
            ),

            // ─── Stats Bar ─────────────────────────────────────────────
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem('500+', 'Happy Customers'),
                  _StatDivider(),
                  _StatItem('100+', 'Products'),
                  _StatDivider(),
                  _StatItem('2024', 'Est. Year'),
                  _StatDivider(),
                  _StatItem('Dhaka', 'Based In'),
                ],
              ),
            ),

            // ─── Mission Section ───────────────────────────────────────
            Container(
              margin: EdgeInsets.symmetric(
                  horizontal: isWide ? 96 : 32, vertical: 64),
              padding: const EdgeInsets.all(48),
              color: AppColors.surfaceLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OUR MISSION',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: AppColors.tertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Premium quality at honest prices.',
                    style: GoogleFonts.newsreader(
                      fontSize: isWide ? 32 : 24,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'We believe every person deserves to wear quality clothing without spending a fortune. '
                    'Triple A was founded with a simple goal: curate premium T-shirts, casual wear, and '
                    'seasonal collections that look great, feel great, and last long — all at prices that '
                    'respect your budget.',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: AppColors.onSurfaceVariant,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Location Section ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 96 : 32, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIND US',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: AppColors.tertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'re based in Dhaka, Bangladesh.',
                    style: GoogleFonts.newsreader(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 24),
                  // Google Maps embed
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: _MapEmbed(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text('Dhaka, Bangladesh',
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(width: 24),
                    const Icon(Icons.phone_outlined,
                        size: 18, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text('+880 1700-000000',
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant)),
                  ]),
                ],
              ),
            ),

            // ─── CTA ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 64),
              color: AppColors.surfaceLow,
              child: Column(children: [
                Text(
                  'Ready to shop?',
                  style: GoogleFonts.newsreader(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore our latest collections.',
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/products'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 18)),
                  child: const Text('SHOP NOW'),
                ),
              ]),
            ),

            // Footer
            _Footer(),
          ],
        ),
      ),
    );
  }

  Widget _storyText() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHO WE ARE',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: AppColors.tertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A small family venture\nwith big quality standards.',
            style: GoogleFonts.newsreader(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Triple A started as a passion project — a belief that everyday clothing '
            'could be both premium and affordable. We hand-pick every item in our store '
            'based on fabric quality, stitching, and durability.',
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: AppColors.onSurfaceVariant,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'From seasonal collections like Eid Special and Summer 2026 to everyday '
            'essentials — everything we carry reflects our commitment to quality you '
            'can feel and prices you can trust.',
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: AppColors.onSurfaceVariant,
              height: 1.8,
            ),
          ),
        ],
      );

  Widget _valuesCard() => Container(
        padding: const EdgeInsets.all(32),
        color: AppColors.primaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OUR VALUES',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 24),
            _ValueItem(Icons.verified_outlined, 'Quality First',
                'Every product is selected for premium quality.'),
            const SizedBox(height: 20),
            _ValueItem(Icons.price_check_outlined, 'Honest Pricing',
                'No markups. Fair prices for everyone.'),
            const SizedBox(height: 20),
            _ValueItem(Icons.local_shipping_outlined, 'Fast Delivery',
                'Dhaka delivery in 1–2 days. Outside Dhaka in 3–5 days.'),
            const SizedBox(height: 20),
            _ValueItem(Icons.support_agent_outlined, 'Customer First',
                'We\'ll call you to confirm every order personally.'),
          ],
        ),
      );
}

class _ValueItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ValueItem(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.white60,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      );
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: GoogleFonts.newsreader(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
                letterSpacing: 1)),
      ]);
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: Colors.white24);
}

class _MapEmbed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simple iframe embed for Dhaka
    return Container(
      color: AppColors.surfaceHigh,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined,
                size: 48, color: AppColors.outline),
            const SizedBox(height: 12),
            Text('Dhaka, Bangladesh',
                style: GoogleFonts.manrope(
                    fontSize: 14, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('23.8103° N, 90.4125° E',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppColors.outline)),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRIPLE A',
                    style: GoogleFonts.newsreader(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('Premium clothing for everyday life.',
                    style: GoogleFonts.manrope(
                        color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CONTACT',
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white60)),
              const SizedBox(height: 12),
              Text('📞 +880 1700-000000',
                  style: GoogleFonts.manrope(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('📍 Dhaka, Bangladesh',
                  style: GoogleFonts.manrope(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}