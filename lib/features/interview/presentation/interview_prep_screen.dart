import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'interview_provider.dart';
import '../domain/interview_question.dart';
import '../../resume/presentation/resume_provider.dart';

class InterviewPrepScreen extends StatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
  String _activeCategoryFilter = 'All Questions';
  String _sortByOption = 'Relevance';
  final Set<String> _expandedQuestionIds = {};

  final List<String> _categories = [
    'All Questions',
    'Common Questions',
    'Resume-Based',
  ];

  final List<String> _sortOptions = [
    'Relevance',
    'Category',
    'Difficulty',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final interviewProvider = context.watch<InterviewProvider>();
    final rawQuestions = interviewProvider.questions;
    final isLoading = interviewProvider.isLoading;
    final targetRole = context.select<ResumeProvider, String>(
      (p) => p.targetRole.isNotEmpty ? p.targetRole : 'Software Engineer',
    );
    final hasResume = context.select<ResumeProvider, bool>(
      (p) => p.extractedText.isNotEmpty || p.critiques.isNotEmpty,
    );

    // 1. Fetch dynamic questions
    final List<InterviewQuestion> allQuestions = List.from(rawQuestions);

    // 2. Filter questions by active category pill
    var filteredQuestions = _activeCategoryFilter == 'All Questions'
        ? allQuestions
        : allQuestions.where((q) {
            final catLower = q.category.toLowerCase();
            final activeLower = _activeCategoryFilter.toLowerCase();
            if (activeLower.contains('common')) {
              return catLower.contains('common') || catLower.contains('tech') || catLower.contains('behav');
            } else {
              return catLower.contains('resume') || catLower.contains('lead') || catLower.contains('scenar');
            }
          }).toList();

    // 3. Dynamic Sorting Logic
    if (_sortByOption == 'Category') {
      filteredQuestions.sort((a, b) => a.category.compareTo(b.category));
    } else if (_sortByOption == 'Difficulty') {
      const difficultyRank = {'Easy': 1, 'Medium': 2, 'Hard': 3};
      filteredQuestions.sort((a, b) =>
          (difficultyRank[a.difficulty] ?? 2).compareTo(difficultyRank[b.difficulty] ?? 2));
    }

    // Color Palette matching HTML spec
    final bgColor = isDark ? const Color(0xFF0B1C30) : const Color(0xFFF8F9FF);
    final cardBgColor = isDark ? const Color(0xFF142438) : Colors.white;
    final borderCol = isDark ? const Color(0xFF23354D) : const Color(0xFFC7C4D8).withValues(alpha: 0.3);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1C30);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555);

    // Fixed-height header + filter widgets
    final headerSliver = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader(targetRole, textPrimary, textMuted),
              const SizedBox(height: 32),
              _buildCategoryFilters(textMuted, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    // Body sliver depending on state
    Widget bodySliver;
    if (isLoading && filteredQuestions.isEmpty) {
      // AI is generating — show inline skeleton loader
      bodySliver = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildLoadingState(cardBgColor, borderCol, textPrimary, textMuted, isDark),
        ),
      );
    } else if (filteredQuestions.isEmpty) {
      bodySliver = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildEmptyState(context, hasResume, cardBgColor, borderCol, textPrimary, textMuted),
        ),
      );
    } else {
      bodySliver = SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList.separated(
          itemCount: filteredQuestions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final question = filteredQuestions[index];
            final isExpanded = _expandedQuestionIds.contains(question.id);
            return RepaintBoundary(
              child: _InterviewAccordionCard(
                key: ValueKey(question.id),
                question: question,
                isExpanded: isExpanded,
                onToggle: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedQuestionIds.remove(question.id);
                    } else {
                      _expandedQuestionIds.add(question.id);
                    }
                  });
                },
                cardBg: cardBgColor,
                borderCol: borderCol,
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          headerSliver,
          bodySliver,
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // Inline AI-generating skeleton loader
  Widget _buildLoadingState(Color cardBg, Color borderCol, Color textPrimary, Color textMuted, bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3525CD)),
                  backgroundColor: const Color(0xFF3525CD).withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Generating your personalized interview questions...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'AI is analyzing your resume and crafting targeted questions',
                style: GoogleFonts.inter(fontSize: 14, color: textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        ...List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _SkeletonQuestionCard(cardBg: cardBg, borderCol: borderCol, isDark: isDark),
        )),
      ],
    );
  }

  // Header Title Section Widget
  Widget _buildPageHeader(String targetRole, Color textPrimary, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personalized Interview Questions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Based on your ',
                style: GoogleFonts.inter(fontSize: 16, color: textMuted),
              ),
              TextSpan(
                text: '$targetRole Resume',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3525CD),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Category Filter Pills & Interactive Sort Dropdown Control Widget
  Widget _buildCategoryFilters(Color textMuted, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isActive = _activeCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeCategoryFilter = cat;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF3525CD)
                              : (isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF3525CD)
                                : const Color(0xFFC7C4D8).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive ? Colors.white : textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (isMobile) const SizedBox(height: 12),

            // Interactive Sort By Dropdown
            PopupMenuButton<String>(
              onSelected: (selectedVal) {
                setState(() {
                  _sortByOption = selectedVal;
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => _sortOptions.map((opt) {
                final isSelected = opt == _sortByOption;
                return PopupMenuItem<String>(
                  value: opt,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        opt,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF3525CD) : null,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check, size: 16, color: Color(0xFF3525CD)),
                    ],
                  ),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7C4D8).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort, color: Color(0xFF777587), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Sort by: $_sortByOption',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF777587), size: 18),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Dynamic Empty State Widget (Upload Your Resume for AI Analysis)
  Widget _buildEmptyState(
    BuildContext context,
    bool hasResumeText,
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
            color: Colors.black.withValues(alpha: 0.04),
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
              'Upload your resume to generate personalized interview questions tailored to your experience and target position.',
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
}

/// Standalone Stateful Accordion Card Widget for Butter-Smooth 60-120 FPS Hover Performance.
/// Manages its own local hover state without rebuilding the parent screen.
class _InterviewAccordionCard extends StatefulWidget {
  final InterviewQuestion question;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Color cardBg;
  final Color borderCol;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  const _InterviewAccordionCard({
    super.key,
    required this.question,
    required this.isExpanded,
    required this.onToggle,
    required this.cardBg,
    required this.borderCol,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  State<_InterviewAccordionCard> createState() => _InterviewAccordionCardState();
}

class _InterviewAccordionCardState extends State<_InterviewAccordionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Category Badge Styling (Common Questions vs Resume-Based)
    Color categoryBg;
    Color categoryText;
    final catLower = widget.question.category.toLowerCase();

    if (catLower.contains('common') || catLower.contains('tech') || catLower.contains('behav')) {
      categoryBg = const Color(0xFF3525CD).withValues(alpha: 0.12);
      categoryText = const Color(0xFF3525CD);
    } else {
      categoryBg = const Color(0xFF006A61).withValues(alpha: 0.12);
      categoryText = const Color(0xFF006A61);
    }

    final categoryDisplay = catLower.contains('resume') || catLower.contains('lead')
        ? 'RESUME-BASED'
        : 'COMMON QUESTION';

    final suggestedAnswer = _getSuggestedAnswer(widget.question);
    final keyPoints = _getKeyPointsToHit(widget.question);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.006 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? const Color(0xFF3525CD) : widget.borderCol,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? (widget.isDark ? 0.3 : 0.08) : (widget.isDark ? 0.2 : 0.04)),
                blurRadius: _isHovered ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Header Trigger
              InkWell(
                onTap: widget.onToggle,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: categoryBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    categoryDisplay,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: categoryText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'High Probability',
                                  style: GoogleFonts.inter(fontSize: 12, color: widget.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _isHovered ? const Color(0xFF3525CD) : widget.textPrimary,
                                height: 1.4,
                              ),
                              child: Text(widget.question.text),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Expand Icon Button Container (Matches HTML group-hover:bg-primary-container)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? const Color(0xFF3525CD)
                              : (widget.isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF)),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedRotation(
                          turns: widget.isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Icon(
                            Icons.expand_more,
                            color: _isHovered ? Colors.white : widget.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Accordion Content Body
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF0F1B2B).withValues(alpha: 0.6)
                        : const Color(0xFFEFF4FF).withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(color: widget.borderCol)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 650;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Pane: Suggested Answer (Actual Answer Text + Practical Example)
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lightbulb, color: Color(0xFF3525CD), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Suggested Answer & Example',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF3525CD),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  suggestedAnswer,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: widget.textMuted,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isWide) const SizedBox(width: 24) else const SizedBox(height: 20),

                          // Right Pane: Key Points to Hit Box
                          Container(
                            width: isWide ? 260 : double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: widget.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.borderCol),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Key Points to Hit',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: widget.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Divider(height: 1, color: widget.borderCol),
                                const SizedBox(height: 12),
                                Column(
                                  children: keyPoints.map((point) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.check_circle, color: Color(0xFF006A61), size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              point,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: widget.textMuted,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                crossFadeState: widget.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 280),
                firstCurve: Curves.easeInOut,
                secondCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Clear, beginner-friendly answers with practical real-world examples
  String _getSuggestedAnswer(InterviewQuestion question) {
    if (question.savedAnswer.isNotEmpty) return question.savedAnswer;
    final lower = question.text.toLowerCase();
    if (lower.contains('flutter') || lower.contains('react') || lower.contains('stateless')) {
      return 'Flutter is Google\'s UI framework that compiles directly to native ARM machine code using Dart, rendering everything onto a canvas without relying on JavaScript bridges like React Native.\n\nExample: In a shopping app, a Stateless Widget is used for static elements like product titles, while a Stateful Widget is used for the cart item counter that updates dynamically when a user taps "+".';
    } else if (lower.contains('migration') || lower.contains('led') || lower.contains('project')) {
      return 'I led our team\'s architectural transition from a monolithic backend to modular microservices. By organizing bi-weekly knowledge sessions and implementing domain-driven design, we migrated 80% of core services without downtime.\n\nExample: In an e-commerce checkout service, breaking off payments into an isolated microservice prevented traffic surges during sale events from crashing the catalog browsing service.';
    } else {
      return 'I focus on clear communication and practical prototyping when presenting technical proposals to team members or product managers.\n\nExample: When proposing a caching layer to improve screen load times, I built a quick 1-day prototype showing load times dropping from 2.5 seconds to 300 milliseconds, which convinced stakeholders to approve the sprint item.';
    }
  }

  // Key Points to Hit helper
  List<String> _getKeyPointsToHit(InterviewQuestion question) {
    final lower = question.text.toLowerCase();
    if (lower.contains('flutter') || lower.contains('react')) {
      return [
        'Explain Dart canvas rendering vs JS bridge.',
        'Contrast Stateless vs Stateful widgets.',
        'Give a practical real-world app example.',
      ];
    } else if (lower.contains('migration') || lower.contains('led')) {
      return [
        'State concrete tools (Docker, K8s).',
        'Highlight zero-downtime strategy.',
        'Quantify results (80% migrated).',
      ];
    } else {
      return [
        'Focus on clear communication.',
        'Provide metric-driven evidence.',
        'Share a real-world project example.',
      ];
    }
  }
}

/// Shimmer-style placeholder skeleton card while questions are being generated
class _SkeletonQuestionCard extends StatefulWidget {
  final Color cardBg;
  final Color borderCol;
  final bool isDark;
  const _SkeletonQuestionCard({required this.cardBg, required this.borderCol, required this.isDark});

  @override
  State<_SkeletonQuestionCard> createState() => _SkeletonQuestionCardState();
}

class _SkeletonQuestionCardState extends State<_SkeletonQuestionCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _shimmerAnim = CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmerColor = widget.isDark ? const Color(0xFF1E2D42) : const Color(0xFFE8EAF6);
    final highlightColor = widget.isDark ? const Color(0xFF2A3F5C) : const Color(0xFFF0F2FF);

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Color.lerp(shimmerColor, highlightColor, _shimmerAnim.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Color.lerp(shimmerColor, highlightColor, _shimmerAnim.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Color.lerp(shimmerColor, highlightColor, _shimmerAnim.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 260,
                height: 16,
                decoration: BoxDecoration(
                  color: Color.lerp(shimmerColor, highlightColor, _shimmerAnim.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
