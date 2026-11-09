import 'package:flutter/material.dart';

/// Interactive onboarding walkthrough for first-time application launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.onFinished,
    super.key,
  });

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _slides = const [
    (
      icon: Icons.security,
      title: 'Privasi Mutlak & 100% Offline',
      description:
          'Semua dokumen dan data Anda tetap berada di penyimpanan perangkat. Tanpa server luar, tanpa akun, tanpa iklan, dan bebas pelacak.',
    ),
    (
      icon: Icons.edit_document,
      title: 'Pembaca & Editor Dokumen Lengkap',
      description:
          'Buka dan edit PDF, Word (.docx), Excel (.xlsx), CSV, TXT, dan Gambar dengan lancar, hemat memori, dan pemulihan otomatis saat force close.',
    ),
    (
      icon: Icons.document_scanner,
      title: 'Pindai Dokumen & OCR Lokal',
      description:
          'Deteksi sudut otomatis, koreksi perspektif, filter peningkatan kontras, dan pengenalan teks OCR offline Bahasa Indonesia & Inggris.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: widget.onFinished,
                  child: const Text('Lewati'),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primaryContainer
                                .withOpacity(0.5),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator Dots & Navigation Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(_slides.length, (index) {
                      final active = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started button
                  FilledButton(
                    onPressed: isLastPage
                        ? widget.onFinished
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                    child: Text(isLastPage ? 'Mulai Sekarang' : 'Lanjut'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
