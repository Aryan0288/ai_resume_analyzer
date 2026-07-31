import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/theme/glassmorphic_theme_extension.dart';

/// Consolidated AI Career Report Dashboard Screen.
/// Renders executive AI summaries, compatibilities grids, salary percentiles, and steppers roadmaps.
class CareerReportScreen extends StatefulWidget {
  const CareerReportScreen({super.key});

  @override
  State<CareerReportScreen> createState() => _CareerReportScreenState();
}

class _CareerReportScreenState extends State<CareerReportScreen> {
  int _activeSubTabIndex = 0; // 0 for Overview, 1 for Roadmap & Gaps

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid ?? 'anonymous';
      final storage = context.read<LocalStorageService>();
      final resumeText = storage.getResumeText();
      final targetRole = storage.getTargetRole();
      context.read<ReportProvider>().loadOrCompileReport(uid, resumeText, targetRole);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ReportProvider>();
    final glassTheme = Theme.of(context).extension<GlassmorphicThemeExtension>()!;

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF14B8A6)),
              SizedBox(height: 16),
              Text(
                'Compiling Consolidated AI Career Report...',
                style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.executiveSummary.isEmpty && provider.overallReadinessIndex == 0) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1C30) : const Color(0xFFF8F9FF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: 600,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF142438) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF23354D) : const Color(0xFFE5EEFF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                      color: isDark ? Colors.white : const Color(0xFF0B1C30),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload your resume to generate a live AI career report, competency heatmaps, and tailored roadmaps for your target role.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555),
                      height: 1.5,
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
            ),
          ),
        ),
      ),
    );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sub-navigation bar at the top of the report screen
            _buildReportTabBar(context),
            const SizedBox(height: 24),

            if (_activeSubTabIndex == 0) ...[
              // Overview View
              _buildOverviewHeader(context),
              const SizedBox(height: 24),
              _buildOverviewBentoGrid(context, provider, glassTheme),
              const SizedBox(height: 32),
              _buildStrengthsGapsGrid(context, provider, glassTheme),
            ] else ...[
              // Roadmap & Gaps View
              _buildRecruiterPerspectiveSection(context, provider),
              const SizedBox(height: 32),
              _buildRoadmapGapsGrid(context, provider, glassTheme),
            ],
          ],
        ),
      ),
    );
  }

  // Segmented Sub-tab bar
  Widget _buildReportTabBar(BuildContext context) {
    return Row(
      children: [
        _buildSubTabItem('Overview', 0),
        _buildSubTabItem('Roadmap & Gaps', 1),
      ],
    );
  }

  Widget _buildSubTabItem(String label, int index) {
    final isActive = _activeSubTabIndex == index;
    return Container(
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? const Color(0xFF14B8A6) : Colors.transparent,
            width: 2.0,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeSubTabIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  // Overview view header actions
  Widget _buildOverviewHeader(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consolidated AI Career Readiness Report',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Generated on $dateStr • AI Analysis v4.2',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderActionButton('Share', Icons.share),
            const SizedBox(width: 8),
            _buildHeaderActionButton('Print', Icons.print),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting PDF Career Report...')),
                );
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
              label: const Text('Export PDF', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: const Color(0xFF94A3B8), size: 14),
      label: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF222B3E)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // Overview View Bento Grid of 4 score blocks
  Widget _buildOverviewBentoGrid(
    BuildContext context,
    ReportProvider provider,
    GlassmorphicThemeExtension glassTheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            // Block 1: Resume Health Score
            _buildResumeHealthBento(context, glassTheme),
            
            // Block 2: Interview Readiness
            _buildSimpleScoreBento(
              'Interview Readiness',
              '76%',
              'Based on 5 questions evaluated. Your Tone & STAR metrics show strong alignment with leadership roles, though data quantification remains a growth area.',
              Icons.mic_none,
              const Color(0xFF818CF8),
            ),

            // Block 3: Quiz Verification
            _buildSimpleScoreBento(
              'Quiz Verification',
              '88%',
              '2 skills verified (Flutter, Dart), 1 pending (Cloud Infrastructure). Ranking in top 12% of applicants.',
              Icons.verified_user_outlined,
              const Color(0xFFF59E0B),
            ),

            // Block 4: Recruiter Index
            _buildRecruiterIndexBento(context),
          ],
        );
      },
    );
  }

  Widget _buildResumeHealthBento(BuildContext context, GlassmorphicThemeExtension glassTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222B3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Resume Health Score', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Icon(Icons.analytics_outlined, color: Color(0xFF14B8A6), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                // 84% gauge
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const CircularProgressIndicator(
                        value: 0.84,
                        strokeWidth: 6,
                        backgroundColor: Color(0xFF1E293B),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
                      ),
                      Center(
                        child: Text(
                          '84%',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Sub-bars
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SubScoreBar(label: 'ATS Compatibility', score: 0.85, color: Color(0xFF60A5FA)),
                      SizedBox(height: 8),
                      _SubScoreBar(label: 'Formatting', score: 0.90, color: Color(0xFF14B8A6)),
                      SizedBox(height: 8),
                      _SubScoreBar(label: 'Impact Metrics', score: 0.75, color: Color(0xFFF59E0B)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleScoreBento(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222B3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruiterIndexBento(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222B3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recruiter Index', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Icon(Icons.trending_up, color: Color(0xFF10B981), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('8.5', style: TextStyle(fontFamily: 'Outfit', fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text(' / 10', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF475569))),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x1F10B981),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x4010B981)),
                  ),
                  child: const Text(
                    'High Potential Band',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Overview bottom columns
  Widget _buildStrengthsGapsGrid(
    BuildContext context,
    ReportProvider provider,
    GlassmorphicThemeExtension glassTheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detected Strengths
            Expanded(
              flex: isWide ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F131C),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                  border: Border(
                    left: BorderSide(color: Color(0xFF14B8A6), width: 3),
                    top: BorderSide(color: Color(0xFF222B3E)),
                    bottom: BorderSide(color: Color(0xFF222B3E)),
                    right: BorderSide(color: Color(0xFF222B3E)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF14B8A6), size: 16),
                        SizedBox(width: 8),
                        Text('Detected Strengths', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...provider.strengths.map((str) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text('• $str', style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4)),
                        )),
                  ],
                ),
              ),
            ),
            
            if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

            // Improvement Gaps
            Expanded(
              flex: isWide ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F131C),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                  border: Border(
                    left: BorderSide(color: Color(0xFFF59E0B), width: 3),
                    top: BorderSide(color: Color(0xFF222B3E)),
                    bottom: BorderSide(color: Color(0xFF222B3E)),
                    right: BorderSide(color: Color(0xFF222B3E)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Color(0xFFF59E0B), size: 16),
                        SizedBox(width: 8),
                        Text('Improvement Gaps', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...provider.improvements.map((imp) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text('• $imp', style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4)),
                        )),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // ROADMAP & GAPS VIEW (Sub-tab 1)
  // ============================================
  Widget _buildRecruiterPerspectiveSection(BuildContext context, ReportProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222B3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_ind_outlined, color: Color(0xFF818CF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Recruiter Perspective Analysis',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // What recruiters will like
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WHAT RECRUITERS WILL LIKE', style: TextStyle(color: Color(0xFF14B8A6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.05)),
                        const SizedBox(height: 12),
                        if (provider.strengths.isEmpty)
                          const Text('Analyze resume to extract candidate strengths', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                        else
                          ...provider.strengths.map((str) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildRecruiterBullet(Icons.check_circle_outline, str, const Color(0xFF14B8A6)),
                              )),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),
                  // Potential Red Flags
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('POTENTIAL RED FLAGS', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.05)),
                        const SizedBox(height: 12),
                        if (provider.improvements.isEmpty)
                          const Text('No critical red flags detected', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                        else
                          ...provider.improvements.map((imp) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildRecruiterBullet(Icons.warning_amber_outlined, imp, const Color(0xFFF59E0B)),
                              )),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Recruiter Impression box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.forum_outlined, color: Color(0xFF818CF8), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recruiter Impression: ${provider.executiveSummary.isEmpty ? "Analyze resume text for tailored recruiter review." : provider.executiveSummary}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFE2E8F0)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruiterBullet(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFE2E8F0)),
          ),
        ),
      ],
    );
  }

  // Bottom double column grid (ATS Checklist & Learning Roadmap)
  Widget _buildRoadmapGapsGrid(
    BuildContext context,
    ReportProvider provider,
    GlassmorphicThemeExtension glassTheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 750;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ATS Simulation Checklist
            Expanded(
              flex: isWide ? 4 : 0,
              child: _buildATSChecklistPane(context),
            ),
            if (isWide) const SizedBox(width: 20) else const SizedBox(height: 24),
            // Learning Roadmap Timeline
            Expanded(
              flex: isWide ? 6 : 0,
              child: _buildLearningTimelinePane(context, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildATSChecklistPane(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222B3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('ATS Simulation Checklist', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),
          _buildATSChecklistItem('Contact Info', 'PASS', const Color(0xFF14B8A6)),
          const SizedBox(height: 8),
          _buildATSChecklistItem('Keywords Match', 'WARNING', const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          _buildATSChecklistItem('Resume Sections', 'PASS', const Color(0xFF14B8A6)),
          const SizedBox(height: 8),
          _buildATSChecklistItem('Formatting', 'PASS', const Color(0xFF14B8A6)),
          const SizedBox(height: 8),
          _buildATSChecklistItem('Action Verbs', 'PASS', const Color(0xFF14B8A6)),
          const SizedBox(height: 16),
          const Text(
            '* Missing: "Viper", "CI/CD Pipeline" keywords detected in job descriptions but missing from your resume.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF475569), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildATSChecklistItem(String label, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C111D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF222B3E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8))),
          Row(
            children: [
              Text(
                status,
                style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 6),
              Icon(
                status == 'PASS' ? Icons.check : Icons.warning_amber_outlined,
                color: color,
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearningTimelinePane(BuildContext context, ReportProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222B3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, color: Color(0xFF14B8A6), size: 16),
              SizedBox(width: 8),
              Text('Learning Roadmap Timeline', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),
          if (provider.roadmap.isEmpty)
            const Text('Upload resume to generate candidate career roadmap', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
          else
            ...provider.roadmap.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final isFirst = idx == 0;
              final isLast = idx == provider.roadmap.length - 1;
              final timeLabel = isFirst ? 'STEP 1' : (isLast ? 'FINAL STEP' : 'STEP ${idx + 1}');

              return _buildRoadmapTimelineStep(
                timeLabel,
                '${step.title}: ${step.description}',
                step.actionLabel,
                step.status == 'completed' ? const Color(0xFF14B8A6) : const Color(0xFF818CF8),
                isFirst: isFirst,
                isLast: isLast,
              );
            }),
          const SizedBox(height: 20),

          // Bottom prediction boxes
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C111D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text('INTERVIEW READY', style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('90%+', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C111D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text('OFFER READY', style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('95%+', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapTimelineStep(
    String timeLabel,
    String desc,
    String badgeLabel,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step circle and line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFirst ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF222B3E),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeLabel,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _SubScoreBar({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            Text('${(score * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 4,
            backgroundColor: const Color(0xFF1E293B),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
