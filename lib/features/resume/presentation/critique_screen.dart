import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'resume_provider.dart';
import '../domain/critique_item.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../interview/presentation/interview_provider.dart';
import '../../quiz/presentation/quiz_provider.dart';
import '../../../core/services/pdf_parser_service.dart';
import '../../../core/services/local_storage_service.dart';

/// High-Fidelity Analyze Resume & Critique Screen matching the M3 / Tailwind design.
class CritiqueScreen extends StatefulWidget {
  const CritiqueScreen({super.key});

  @override
  State<CritiqueScreen> createState() => _CritiqueScreenState();
}

class _CritiqueScreenState extends State<CritiqueScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    final provider = context.read<ResumeProvider>();
    final targetScore = provider.atsScore > 0 ? provider.atsScore.toDouble() : 85.0;

    _scoreAnimation = Tween<double>(begin: 0, end: targetScore).animate(
      CurvedAnimation(parent: _scoreAnimationController, curve: Curves.easeOutCubic),
    );

    if (provider.extractedText.isNotEmpty || provider.critiques.isNotEmpty) {
      _scoreAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resumeProvider = context.watch<ResumeProvider>();
    final pdfParser = context.read<PdfParserService>();
    final storage = context.read<LocalStorageService>();

    final hasData = resumeProvider.extractedText.isNotEmpty || resumeProvider.critiques.isNotEmpty;
    final isAnalyzing = resumeProvider.isAnalyzing ||
        resumeProvider.state == IngestionState.parsing ||
        resumeProvider.state == IngestionState.analyzing;

    // Theme palette matching HTML design
    final bgColor = isDark ? const Color(0xFF0B1C30) : const Color(0xFFF8F9FF);
    final cardBgColor = isDark ? const Color(0xFF142438) : Colors.white;
    final borderCol = isDark ? const Color(0xFF23354D) : const Color(0xFFE5EEFF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1C30);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Main Core Layout
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Title Block
                    _buildHeaderBlock(textPrimary, textMuted),
                    const SizedBox(height: 32),

                    // Switch between Dropzone (Empty) or Results View (Analyzed)
                    if (!hasData && !isAnalyzing)
                      _buildUploadDropzone(context, resumeProvider, pdfParser, isDark, cardBgColor, borderCol, textPrimary, textMuted)
                    else
                      _buildResultsGrid(context, resumeProvider, storage, isDark, cardBgColor, borderCol, textPrimary, textMuted),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header Title Section
  Widget _buildHeaderBlock(Color textPrimary, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyze Your Resume',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Upload your resume to get instant feedback on ATS compatibility and content strength.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Empty State Upload Card (Redirects to main Ingestion Screen)
  Widget _buildUploadDropzone(
    BuildContext context,
    ResumeProvider provider,
    PdfParserService pdfParser,
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF006A61).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined, size: 42, color: Color(0xFF006A61)),
          ),
          const SizedBox(height: 20),
          Text(
            'Upload Your Resume for AI Analysis',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Select your target role and upload your resume PDF or text to unlock real-time ATS scoring, targeted skill critiques, and career suggestions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: textMuted, height: 1.5),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.upload_file, color: Colors.white, size: 20),
            label: Text(
              'Upload Resume Now',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A61),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 3,
              shadowColor: const Color(0xFF006A61).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // Main Results Split Grid View
  Widget _buildResultsGrid(
    BuildContext context,
    ResumeProvider provider,
    LocalStorageService storage,
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
  ) {
    final atsScore = provider.atsScore > 0 ? provider.atsScore : 85;
    final targetRole = provider.targetRole.isNotEmpty ? provider.targetRole : 'Senior Product Designer';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (1 Col on Desktop): ATS Score & Action Buttons
            Expanded(
              flex: isWide ? 1 : 0,
              child: Column(
                children: [
                  _buildAtsScoreCard(atsScore, targetRole, cardBg, borderCol, textPrimary, textMuted, isDark),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, provider, storage, textPrimary),
                ],
              ),
            ),
            if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),

            // Right Column (2 Cols on Desktop): Missing Keywords & What to Improve Cards
            Expanded(
              flex: isWide ? 2 : 0,
              child: Column(
                children: [
                  _buildMissingKeywordsCard(provider, cardBg, borderCol, textPrimary, textMuted, isDark),
                  const SizedBox(height: 24),
                  _buildWhatToImproveCard(provider, cardBg, borderCol, textPrimary, textMuted, isDark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ATS Score Card Widget with Circular Progress Painter
  Widget _buildAtsScoreCard(
    int atsScore,
    String targetRole,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ATS Compatibility',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Circular SVG Progress Ring
          SizedBox(
            width: 180,
            height: 180,
            child: AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                final displayScore = _scoreAnimation.value.round();
                return CustomPaint(
                  painter: _CircularGaugePainter(
                    score: _scoreAnimation.value,
                    maxScore: 100.0,
                    color: const Color(0xFF3525CD),
                    trackColor: const Color(0xFFE5EEFF),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$displayScore',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Dynamic Target Role Match Badge
          _buildMatchBadge(atsScore, targetRole),
        ],
      ),
    );
  }

  Widget _buildMatchBadge(int score, String role) {
    String matchLabel;
    Color bgColor;
    Color textColor;

    if (score >= 80) {
      matchLabel = 'Excellent match for $role';
      bgColor = const Color(0xFF86F2E4).withValues(alpha: 0.25);
      textColor = const Color(0xFF006A61);
    } else if (score >= 60) {
      matchLabel = 'Good match for $role';
      bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.2);
      textColor = const Color(0xFF1E40AF);
    } else if (score >= 40) {
      matchLabel = 'Moderate match for $role';
      bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.2);
      textColor = const Color(0xFF92400E);
    } else {
      matchLabel = 'Poor match for $role (Needs Improvement)';
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
      textColor = const Color(0xFF991B1B);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        matchLabel,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // Action Buttons Stack Widget
  Widget _buildActionButtons(
    BuildContext context,
    ResumeProvider provider,
    LocalStorageService storage,
    Color textPrimary,
  ) {
    return Column(
      children: [
        // Primary Button: Generate Interview Prep
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final uid = context.read<AuthProvider>().currentUser?.uid ?? 'anonymous';
              final text = provider.extractedText.isNotEmpty ? provider.extractedText : 'Software Engineer';
              context.read<InterviewProvider>().loadOrGenerateQuestions(uid, text);
              context.go('/workspace/prep');
            },
            icon: const Icon(Icons.psychology, color: Colors.white, size: 20),
            label: Text(
              'Practice Interview Questions',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3525CD),
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Button 3: Go to Skills Quiz
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final uid = context.read<AuthProvider>().currentUser?.uid ?? 'anonymous';
              final text = provider.extractedText;
              final skills = provider.recommendedSkills.isNotEmpty
                  ? provider.recommendedSkills
                  : ['Flutter', 'Dart', 'Firebase'];
              context.read<QuizProvider>().startQuiz(uid, 'custom', skills, text);
              context.go('/workspace/quiz');
            },
            icon: Icon(Icons.quiz, color: textPrimary, size: 20),
            label: Text(
              'Go to Skills Quiz',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC7C4D8)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // Missing Keywords Card Widget
  Widget _buildMissingKeywordsCard(
    ResumeProvider provider,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final missingSkills = provider.recommendedSkills.isNotEmpty
        ? provider.recommendedSkills
        : ['Figma Variables', 'Design Systems', 'A/B Testing'];

    final detectedSkills = provider.detectedSkills.isNotEmpty
        ? provider.detectedSkills
        : ['User Research', 'Prototyping'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF86F2E4).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.vpn_key, color: Color(0xFF006A61), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Missing Keywords',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'These industry-specific terms are found in top job descriptions but are missing from your resume.',
            style: GoogleFonts.inter(fontSize: 14, color: textMuted, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Skill Chips Container
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...missingSkills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    skill,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF93000A),
                    ),
                  ),
                );
              }),
              ...detectedSkills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE9FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    skill,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF464555),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // What to Improve Card Widget
  Widget _buildWhatToImproveCard(
    ResumeProvider provider,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final List<CritiqueItem> critiques = provider.critiques.isNotEmpty
        ? provider.critiques
        : [
            CritiqueItem(
              id: 'c1',
              title: 'Quantify your achievements',
              description: 'Add metrics to your experience at "Acme Corp". Example: "Increased user retention by 25%".',
              beforeText: 'Managed engineering projects.',
              afterText: 'Increased user retention by 25% across 250k active users.',
              type: 'weakness',
            ),
            CritiqueItem(
              id: 'c2',
              title: 'Formatting Issue',
              description: 'Inconsistent bullet point styles detected in the "Education" section. Use standard disc bullets.',
              beforeText: '• Degree in CS',
              afterText: 'Bachelor of Science in Computer Science',
              type: 'suggestion',
            ),
            CritiqueItem(
              id: 'c3',
              title: 'Length Optimization',
              description: 'Your summary is a bit long (over 100 words). Try to condense it to a punchy 3-4 sentences.',
              beforeText: 'Long summary text block...',
              afterText: 'Condensed 3-sentence summary highlighting core strengths.',
              type: 'suggestion',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDDB8).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.build, color: Color(0xFF684000), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'What to Improve',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Critique Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: critiques.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = critiques[index];
              final isError = item.type == 'weakness';
              final iconColor = isError ? const Color(0xFFBA1A1A) : const Color(0xFF684000);
              final iconData = isError ? Icons.error : Icons.warning;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconData, color: iconColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom Circular Progress Gauge Painter
class _CircularGaugePainter extends CustomPainter {
  final double score;
  final double maxScore;
  final Color color;
  final Color trackColor;

  _CircularGaugePainter({
    required this.score,
    required this.maxScore,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 10.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background track ring
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active score ring arc
    final double sweepAngle = max(0.001, 2 * pi * (score / maxScore));
    final Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
