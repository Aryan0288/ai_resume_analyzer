import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../resume/presentation/resume_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final quizProvider = context.watch<QuizProvider>();
    final resumeProvider = context.watch<ResumeProvider>();
    final authProvider = context.watch<AuthProvider>();

    final targetRole = resumeProvider.targetRole.isNotEmpty
        ? resumeProvider.targetRole
        : 'Software Engineer';

    // Theme palette matching HTML spec
    final bgColor = isDark ? const Color(0xFF0B1C30) : const Color(0xFFF8F9FF);
    final cardBgColor = isDark ? const Color(0xFF142438) : Colors.white;
    final borderCol = isDark ? const Color(0xFF23354D) : const Color(0xFFC7C4D8).withValues(alpha: 0.3);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1C30);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555);

    // 1. Loading State
    if (quizProvider.isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3525CD)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Generating Skill Quiz via AI Engine...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3525CD),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tailoring questions based on your resume skills.',
                style: GoogleFonts.inter(fontSize: 14, color: textMuted),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Active Quiz State
    if (quizProvider.isTakingQuiz) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuizHeaderCard(quizProvider, targetRole, cardBgColor, borderCol, textPrimary, textMuted, isDark),
                  const SizedBox(height: 24),
                  _buildActiveQuestionCard(context, quizProvider, cardBgColor, borderCol, textPrimary, textMuted, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Quiz Results Summary State
    if (quizProvider.showResults) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: _buildQuizResultsSummary(context, quizProvider, cardBgColor, borderCol, textPrimary, textMuted, isDark),
            ),
          ),
        ),
      );
    }

    // 4. Initial Quiz Setup / Dashboard State (Idle)
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _buildQuizDashboard(context, quizProvider, resumeProvider, authProvider, cardBgColor, borderCol, textPrimary, textMuted, isDark),
          ),
        ),
      ),
    );
  }

  // Quiz Header Card Widget with Real-time Counters and Progress Bar
  Widget _buildQuizHeaderCard(
    QuizProvider provider,
    String targetRole,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final questions = provider.questions;
    final activeIndex = provider.activeQuestionIndex;
    final qTotal = questions.isNotEmpty ? questions.length : 1;
    final qNum = activeIndex + 1;
    final progressPercent = ((qNum / qTotal) * 100).round();

    // Calculate dynamic correct and wrong counters
    int correctCount = 0;
    int wrongCount = 0;
    provider.userAnswers.forEach((qId, userAns) {
      final questionIndex = questions.indexWhere((q) => q.id == qId);
      if (questionIndex != -1) {
        if (userAns == questions[questionIndex].correctOptionIndex) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }
    });

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
          // Top Row: Quiz Title & Real-time Counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$targetRole Quiz',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Intermediate Level',
                      style: GoogleFonts.inter(fontSize: 14, color: textMuted),
                    ),
                  ],
                ),
              ),

              // Score Counters Pill (Correct / Wrong)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF006A61),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Correct: $correctCount',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 14, color: borderCol),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFBA1A1A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Wrong: $wrongCount',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar Block
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question $qNum of $qTotal',
                    style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                  ),
                  Text(
                    '$progressPercent% Complete',
                    style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: qNum / qTotal,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5EEFF),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3525CD)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Active Question Card Widget (Options A/B/C/D + Explanation Block)
  Widget _buildActiveQuestionCard(
    BuildContext context,
    QuizProvider provider,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final questions = provider.questions;
    final activeIndex = provider.activeQuestionIndex;
    if (questions.isEmpty || activeIndex >= questions.length) {
      return const SizedBox.shrink();
    }

    final question = questions[activeIndex];
    final isSubmitted = provider.isAnswerSubmitted;
    final selectedOption = provider.selectedOptionIndex;

    return Container(
      padding: const EdgeInsets.all(28),
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
          // Question Title Text
          Text(
            question.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Options List (A, B, C, D)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: question.options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final letter = String.fromCharCode(65 + index); // A, B, C, D
              final optionText = question.options[index];
              final isOptionSelected = selectedOption == index;
              final isCorrectOption = index == question.correctOptionIndex;

              // Styling per HTML specification
              Color cardBorder = borderCol;
              Color cardBgColor = isDark ? const Color(0xFF1E2D42) : const Color(0xFFF8F9FF);
              Color badgeBg = isDark ? const Color(0xFF283A54) : const Color(0xFFEFF4FF);
              Color badgeTextColor = textMuted;
              Widget? iconBadge;

              if (isSubmitted) {
                if (isCorrectOption) {
                  // Green Correct Success State
                  cardBorder = const Color(0xFF006A61);
                  cardBgColor = const Color(0xFF86F2E4).withValues(alpha: 0.15);
                  badgeBg = const Color(0xFF006A61);
                  badgeTextColor = Colors.white;
                  iconBadge = const Icon(Icons.check, size: 16, color: Colors.white);
                } else if (isOptionSelected && !isCorrectOption) {
                  // Red Error State
                  cardBorder = const Color(0xFFBA1A1A);
                  cardBgColor = const Color(0xFFFFDAD6).withValues(alpha: 0.2);
                  badgeBg = const Color(0xFFBA1A1A);
                  badgeTextColor = Colors.white;
                  iconBadge = const Icon(Icons.close, size: 16, color: Colors.white);
                }
              } else if (isOptionSelected) {
                // Active Pre-submit Selection (Primary Violet)
                cardBorder = const Color(0xFF3525CD);
                cardBgColor = const Color(0xFF3525CD).withValues(alpha: 0.08);
                badgeBg = const Color(0xFF3525CD);
                badgeTextColor = Colors.white;
              }

              return InkWell(
                onTap: () {
                  if (!isSubmitted) {
                    provider.selectOption(index);
                    provider.submitCurrentAnswer(); // Instant feedback matching HTML spec
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder, width: isOptionSelected || (isSubmitted && isCorrectOption) ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      // Circular Option Letter Badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeBg,
                        ),
                        child: Center(
                          child: iconBadge ??
                              Text(
                                letter,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: badgeTextColor,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Option Body Text
                      Expanded(
                        child: Text(
                          optionText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: (isSubmitted && isCorrectOption) || isOptionSelected ? FontWeight.w600 : FontWeight.w400,
                            color: textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Feedback / Explanation Block (Visible after selection)
          if (isSubmitted) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2B3E) : const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: const Color(0xFF006A61), width: 4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Color(0xFF006A61), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explanation',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.coachExplanation.isNotEmpty
                              ? question.coachExplanation
                              : 'Option ${String.fromCharCode(65 + question.correctOptionIndex)} is the correct answer based on industry best practices.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions Footer (Next Question Button)
          if (isSubmitted) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  final uid = context.read<AuthProvider>().currentUser?.uid ?? 'anonymous';
                  provider.nextQuestion(uid: uid);
                },
                icon: Text(
                  activeIndex < questions.length - 1 ? 'Next Question' : 'View Results',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                label: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3525CD),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Quiz Results Summary View
  Widget _buildQuizResultsSummary(
    BuildContext context,
    QuizProvider provider,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final total = provider.questions.length;
    final correct = provider.correctAnswersCount;
    final percentage = provider.quizScorePercentage;

    return Container(
      padding: const EdgeInsets.all(32),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF3525CD).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics, size: 44, color: Color(0xFF3525CD)),
          ),
          const SizedBox(height: 20),
          Text(
            'Quiz Completed!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here is a summary of your performance on this skill assessment.',
            style: GoogleFonts.inter(fontSize: 15, color: textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Score Gauge Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$percentage%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3525CD),
                      ),
                    ),
                    Text(
                      'Accuracy Score',
                      style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: borderCol),
                Column(
                  children: [
                    Text(
                      '$correct / $total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF006A61),
                      ),
                    ),
                    Text(
                      'Correct Answers',
                      style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Actions Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  provider.resetQuiz();
                },
                icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF3525CD)),
                label: Text(
                  'Retake Quiz',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3525CD),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC7C4D8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  provider.resetAll();
                },
                icon: const Icon(Icons.dashboard, size: 18, color: Colors.white),
                label: Text(
                  'Back to Assessments',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3525CD),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quiz Setup / Dashboard Idle State Widget
  Widget _buildQuizDashboard(
    BuildContext context,
    QuizProvider quizProvider,
    ResumeProvider resumeProvider,
    AuthProvider authProvider,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final hasResumeText = resumeProvider.state == IngestionState.success &&
        resumeProvider.extractedText.trim().isNotEmpty;

    if (!hasResumeText) {
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
                'Upload your resume to generate personalized technical and skill assessment quizzes matched to your target role.',
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

    final targetRole = resumeProvider.targetRole.isNotEmpty
        ? resumeProvider.targetRole
        : 'Software Engineer';

    final skills = resumeProvider.recommendedSkills.isNotEmpty
        ? resumeProvider.recommendedSkills
        : ['React', 'System Design', 'Flutter', 'Firebase'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Banner
        Text(
          'Skills Quiz & Assessments',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Test your technical expertise with AI-generated skill quizzes based on your resume.',
          style: GoogleFonts.inter(fontSize: 16, color: textMuted),
        ),
        const SizedBox(height: 32),

        // Primary Quiz Start Card
        Container(
          padding: const EdgeInsets.all(28),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3525CD).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.quiz, color: Color(0xFF3525CD), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$targetRole Core Assessment',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '10 Questions • 15 Mins • Adaptive Difficulty',
                          style: GoogleFonts.inter(fontSize: 13, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Skills Chips List
              Text(
                'Covered Skills:',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((sk) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      sk,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  final uid = authProvider.currentUser?.uid ?? 'anonymous';
                  final resumeText = resumeProvider.extractedText;
                  quizProvider.startQuiz(uid, targetRole, skills, resumeText);
                },
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                label: Text(
                  'Start Skill Quiz',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3525CD),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
