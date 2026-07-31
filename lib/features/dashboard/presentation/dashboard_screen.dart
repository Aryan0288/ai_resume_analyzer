import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../interview/presentation/interview_provider.dart';
import '../../quiz/presentation/quiz_provider.dart';
import '../../resume/presentation/resume_provider.dart';
import '../domain/dashboard_models.dart';
import '../../../core/services/local_storage_service.dart';

class DashboardScreen extends StatefulWidget {
  final String searchQuery;

  const DashboardScreen({
    super.key,
    this.searchQuery = '',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _hoveredBarIndex;
  String? _lastSyncedUid;

  @override
  void initState() {
    super.initState();
    _checkAndSyncUser();
  }

  void _checkAndSyncUser() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != _lastSyncedUid) {
        _lastSyncedUid = uid;
        if (uid != null && uid.isNotEmpty) {
          context.read<LocalStorageService>().syncUserActivitiesFromFirestore(uid).then((_) {
            if (mounted) setState(() {});
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authProvider = context.watch<AuthProvider>();
    final resumeProvider = context.watch<ResumeProvider>();
    final interviewProvider = context.watch<InterviewProvider>();
    final quizProvider = context.watch<QuizProvider>();

    // 1. Dynamic User Greeting & Reactive Auth Sync
    final currentUser = authProvider.currentUser;
    final uid = currentUser?.uid;

    if (uid != _lastSyncedUid) {
      _lastSyncedUid = uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<LocalStorageService>().syncUserActivitiesFromFirestore(uid).then((_) {
          if (mounted) setState(() {});
        });
      }
    }

    final rawName = currentUser?.displayName ??
        (currentUser?.email.isNotEmpty == true ? currentUser!.email.split('@').first : 'Guest');
    final userName = rawName.isNotEmpty
        ? '${rawName[0].toUpperCase()}${rawName.substring(1)}'
        : 'Guest';

    final storage = context.read<LocalStorageService>();
    final savedActivitiesRaw = storage.getRecentActivities(uid);

    // 2. Dynamic Metric & State Calculations (True State - Fully Dynamic)
    final hasActiveResume = savedActivitiesRaw.isNotEmpty || resumeProvider.extractedText.isNotEmpty || resumeProvider.healthScore > 0;

    // Resumes Analyzed Count: Dynamic total count of analyzed resumes from saved user activities
    final resumesCount = savedActivitiesRaw.isNotEmpty ? savedActivitiesRaw.length : (hasActiveResume ? 1 : 0);

    // Latest ATS Score: From the most recent analyzed resume
    final liveAtsScore = savedActivitiesRaw.isNotEmpty
        ? ((savedActivitiesRaw.first['atsScore'] as num?)?.toInt() ?? 0)
        : (hasActiveResume ? resumeProvider.atsScore : 0);

    // Prep Progress Percentage: Dynamic calculation from interview practice & quiz performance
    final completedInterviews = interviewProvider.questions.where((q) => q.isCompleted).length;
    final totalInterviews = interviewProvider.questions.length;
    final interviewRatio = totalInterviews > 0 ? (completedInterviews / totalInterviews) : 0.0;
    final quizScoreRatio = quizProvider.quizScorePercentage > 0 ? (quizProvider.quizScorePercentage / 100.0) : 0.0;

    final hasPrepData = totalInterviews > 0 || quizProvider.quizScorePercentage > 0 || completedInterviews > 0;

    final double prepRatio = (totalInterviews > 0 && quizProvider.quizScorePercentage > 0)
        ? ((interviewRatio + quizScoreRatio) / 2)
        : (totalInterviews > 0 ? interviewRatio : (quizProvider.quizScorePercentage > 0 ? quizScoreRatio : 0.0));

    final prepProgressPercent = hasPrepData
        ? (prepRatio * 100).round().clamp(0, 100)
        : (hasActiveResume ? 15 : 0);

    // 3. Dynamic Activity Entries (Top 5 Recent Resumes - Read Only)
    final List<ResumeActivityItem> allActivities = savedActivitiesRaw.isNotEmpty
        ? savedActivitiesRaw.map((raw) {
            return ResumeActivityItem(
              id: raw['id'] ?? '1',
              documentName: raw['documentName'] ?? 'Uploaded_Resume.pdf',
              targetRole: raw['targetRole'] ?? 'Software Engineer',
              atsScore: raw['atsScore'] ?? 85,
              date: DateTime.tryParse(raw['date'] ?? '') ?? DateTime.now(),
            );
          }).toList()
        : (hasActiveResume
            ? [
                ResumeActivityItem(
                  id: '1',
                  documentName: resumeProvider.selectedFileName.isNotEmpty
                      ? resumeProvider.selectedFileName
                      : 'Uploaded_Resume.pdf',
                  targetRole: resumeProvider.targetRole.isNotEmpty
                      ? resumeProvider.targetRole
                      : 'Target Position Not Set',
                  atsScore: liveAtsScore,
                  date: DateTime.now(),
                ),
              ]
            : []);

    // Filter by search query and restrict strictly to Top 5
    final filteredActivities = (widget.searchQuery.trim().isEmpty
        ? allActivities
        : allActivities.where((item) {
            final query = widget.searchQuery.toLowerCase();
            return item.documentName.toLowerCase().contains(query) ||
                item.targetRole.toLowerCase().contains(query);
          }).toList()).take(5).toList();

    // 4. Dynamic Score Trend: Generated 100% directly from real user activity history
    final List<WeeklyScoreTrend> scoreTrends = savedActivitiesRaw.isNotEmpty
        ? savedActivitiesRaw.reversed.toList().asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final raw = entry.value;
            final scoreVal = (raw['atsScore'] as num?)?.toInt() ?? 85;
            return WeeklyScoreTrend(
              label: 'Run $idx',
              score: scoreVal,
            );
          }).toList()
        : (hasActiveResume
            ? [
                WeeklyScoreTrend(label: 'Run 1', score: liveAtsScore),
              ]
            : []);

    // Color Palette based on current Theme Mode
    final bgColor = isDark ? const Color(0xFF0B1C30) : const Color(0xFFF8F9FF);
    final cardBgColor = isDark ? const Color(0xFF142438) : Colors.white;
    final borderColor = isDark ? const Color(0xFF23354D) : const Color(0xFFC7C4D8).withValues(alpha: 0.3);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1C30);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Welcome Header Hero
                _buildWelcomeHeader(context, userName, cardBgColor, borderColor, textPrimary, textMuted, isDark),
                const SizedBox(height: 32),

                // 2. Metrics Bento Grid
                _buildBentoMetricsGrid(
                  context,
                  atsScore: liveAtsScore,
                  hasActiveResume: hasActiveResume,
                  resumesCount: resumesCount,
                  prepProgress: prepProgressPercent,
                  hasPrepData: hasPrepData,
                  cardBg: cardBgColor,
                  borderCol: borderColor,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),

                // 3. Lower Section Split Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Recent Activity Table
                        Expanded(
                          flex: isWide ? 2 : 0,
                          child: _buildRecentActivityPane(
                            context,
                            activities: filteredActivities,
                            hasData: hasActiveResume,
                            cardBg: cardBgColor,
                            borderCol: borderColor,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            isDark: isDark,
                          ),
                        ),
                        if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),

                        // Right Column: Quick Actions & Score Trend Chart
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: Column(
                            children: [
                              _buildQuickActionsPane(
                                context,
                                cardBg: cardBgColor,
                                borderCol: borderColor,
                                textPrimary: textPrimary,
                              ),
                              const SizedBox(height: 24),
                              _buildScoreTrendPane(
                                context,
                                trends: scoreTrends,
                                cardBg: cardBgColor,
                                borderCol: borderColor,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header Welcome Hero Widget
  Widget _buildWelcomeHeader(
    BuildContext context,
    String userName,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: isMobile ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 24 : 30,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Ready to level up your career? Here's your latest performance summary.",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMobile) const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.upload_file, color: Colors.white, size: 20),
                label: Text(
                  'Upload New Resume',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A61),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  elevation: 3,
                  shadowColor: const Color(0xFF006A61).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Bento Metrics Grid Widget (Handles true empty states)
  Widget _buildBentoMetricsGrid(
    BuildContext context, {
    required int atsScore,
    required bool hasActiveResume,
    required int resumesCount,
    required int prepProgress,
    required bool hasPrepData,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          children: [
            // Card 1: ATS Score
            Expanded(
              flex: isWide ? 1 : 0,
              child: Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3525CD).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fact_check, color: Color(0xFF3525CD), size: 22),
                        ),
                        if (hasActiveResume)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF86F2E4).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Active',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF006A61),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Latest ATS Score',
                      style: GoogleFonts.inter(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasActiveResume ? '$atsScore%' : 'N/A',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: hasActiveResume ? textPrimary : textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: hasActiveResume ? (atsScore / 100.0).clamp(0.0, 1.0) : 0.0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5EEFF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          hasActiveResume ? const Color(0xFF3525CD) : borderCol,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isWide) const SizedBox(width: 20) else const SizedBox(height: 16),

            // Card 2: Resumes Analyzed
            Expanded(
              flex: isWide ? 1 : 0,
              child: Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A61).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description, color: Color(0xFF006A61), size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Resumes Analyzed',
                      style: GoogleFonts.inter(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$resumesCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      resumesCount > 0 ? 'Across $resumesCount document${resumesCount > 1 ? 's' : ''}' : 'No resumes analyzed yet',
                      style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            ),
            if (isWide) const SizedBox(width: 20) else const SizedBox(height: 16),

            // Card 3: Prep Progress
            Expanded(
              flex: isWide ? 1 : 0,
              child: Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF684000).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.psychology, color: Color(0xFF684000), size: 22),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasPrepData
                                ? const Color(0xFFFFDDB8).withValues(alpha: 0.4)
                                : borderCol.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasPrepData ? 'In Progress' : 'Not Started',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasPrepData ? const Color(0xFF684000) : textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Prep Progress',
                      style: GoogleFonts.inter(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPrepData ? '$prepProgress%' : '0%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: hasPrepData ? textPrimary : textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (prepProgress / 100.0).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5EEFF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          hasPrepData ? const Color(0xFF684000) : borderCol,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Recent Activity Table Pane (Overflow Proof & Empty State Support)
  Widget _buildRecentActivityPane(
    BuildContext context, {
    required List<ResumeActivityItem> activities,
    required bool hasData,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (hasData)
                  TextButton(
                    onPressed: () => context.go('/history'),
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3525CD),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: borderCol),

          // Clean Empty State or Overflow-Proof Table
          activities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_add_outlined, size: 48, color: textMuted.withValues(alpha: 0.6)),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activity found.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Upload your resume to generate dynamic ATS scores and AI critiques.',
                          style: GoogleFonts.inter(color: textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
                          label: const Text('Upload Resume', style: TextStyle(color: Colors.white, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3525CD),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final tableWidth = max(constraints.maxWidth, 650.0);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: DataTable(
                          horizontalMargin: 20,
                          columnSpacing: 20,
                          headingRowColor: WidgetStateProperty.all(
                            isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF),
                          ),
                          columns: [
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Document Name',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'Target Role',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Text(
                                  'ATS Score',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Date',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted),
                              ),
                            ),
                          ],
                          rows: activities.map((item) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.description, color: Color(0xFF777587), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.documentName,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    item.targetRole,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 13, color: textMuted),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 38,
                                        child: Text(
                                          '${item.atsScore}%',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: item.scoreColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 60,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: item.atsScore / 100.0,
                                            minHeight: 6,
                                            backgroundColor: borderCol,
                                            valueColor: AlwaysStoppedAnimation<Color>(item.scoreColor),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    item.formattedDate,
                                    style: GoogleFonts.inter(fontSize: 13, color: textMuted),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // Quick Actions Card Widget
  Widget _buildQuickActionsPane(
    BuildContext context, {
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Action 1: Quiz
          InkWell(
            onTap: () => context.go('/workspace/quiz'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3525CD).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.quiz, color: Color(0xFF3525CD), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Take a Quick Quiz',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFC7C4D8), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Action 2: Top Interview Questions
          InkWell(
            onTap: () => context.go('/workspace/prep'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF006A61).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.record_voice_over, color: Color(0xFF006A61), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Top Interview Questions',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFC7C4D8), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Weekly Score Trend Bar Chart Widget (Empty State Support)
  Widget _buildScoreTrendPane(
    BuildContext context, {
    required List<WeeklyScoreTrend> trends,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score Trend',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                'Last 30 Days',
                style: GoogleFonts.inter(fontSize: 12, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Render Chart or Empty State
          trends.isEmpty
              ? Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: Text(
                    'No score trend history available yet.',
                    style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(trends.length, (index) {
                            final item = trends[index];
                            final heightFactor = (item.score / 100.0).clamp(0.1, 1.0);
                            final isHovered = _hoveredBarIndex == index;

                            return MouseRegion(
                              onEnter: (_) => setState(() => _hoveredBarIndex = index),
                              onExit: (_) => setState(() => _hoveredBarIndex = null),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    AnimatedOpacity(
                                      duration: const Duration(milliseconds: 150),
                                      opacity: isHovered || trends.length == 1 ? 1.0 : 0.0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF213145),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${item.score}%',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      width: 32,
                                      height: 80 * heightFactor,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [Color(0xFF3525CD), Color(0xFF6366F1)],
                                        ),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: borderCol),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: trends.asMap().entries.map((entry) {
                          return SizedBox(
                            width: 40,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                entry.value.label,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 10, color: textMuted),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
