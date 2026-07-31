import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'resume_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../interview/presentation/interview_provider.dart';
import '../../quiz/presentation/quiz_provider.dart';
import '../../../core/services/pdf_parser_service.dart';
import '../../../core/services/local_storage_service.dart';

class IngestionScreen extends StatefulWidget {
  const IngestionScreen({super.key});

  @override
  State<IngestionScreen> createState() => _IngestionScreenState();
}

class _IngestionScreenState extends State<IngestionScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ValueNotifier<bool> _isHoveringDropzone = ValueNotifier<bool>(false);

  late AnimationController _scannerAnimController;
  int _analysisProgress = 0;
  int _statusTextIndex = 0;
  Timer? _progressTimer;
  bool _progressCompleted = false;

  final List<String> _quickRoles = [
    'Software Engineer',
    'Product Manager',
    'Data Scientist',
    'UX Designer',
  ];

  final List<String> _targetRoles = [
    'Software Engineer',
    'Product Manager',
    'Data Scientist',
    'UX Designer',
    'Flutter Developer',
    'Mobile Engineer',
    'Frontend Engineer',
    'Full Stack Developer',
    'Backend Developer',
    'UI/UX Architect',
  ];

  final List<String> _scanningStatuses = [
    "Extracting document structure...",
    "Parsing contact information & summary...",
    "Identifying professional experience timeline...",
    "Extracting technical & soft skills...",
    "Matching against target role requirements...",
    "Calculating ATS compatibility score...",
    "Generating actionable AI feedback...",
  ];

  @override
  void initState() {
    super.initState();
    _scannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Always reset provider when this screen is mounted so navigating
    // back from Dashboard (where state is still 'success') never
    // auto-triggers analysis of the previous resume.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ResumeProvider>().reset();
      }
    });
  }

  @override
  void dispose() {
    _isHoveringDropzone.dispose();
    _scannerAnimController.dispose();
    _progressTimer?.cancel();
    _roleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startProgressSimulation() {
    // Only one run per analysis — guard against double-start and already-completed runs
    if (_progressTimer != null && _progressTimer!.isActive) return;
    if (_progressCompleted) return;
    _analysisProgress = 0;
    _statusTextIndex = 0;
    _progressCompleted = false;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _analysisProgress += 1;
        if (_analysisProgress >= 100) {
          _analysisProgress = 100;
          _progressCompleted = true;
          timer.cancel();
        }
        final expectedIndex = ((_analysisProgress / 100) * _scanningStatuses.length).floor().clamp(0, _scanningStatuses.length - 1);
        _statusTextIndex = expectedIndex;
      });
    });
  }

  void _resetProgressSimulation() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _progressCompleted = false;
    _analysisProgress = 0;
    _statusTextIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resumeProvider = context.watch<ResumeProvider>();
    final pdfParser = context.read<PdfParserService>();

    // Trigger password dialog if PDF is encrypted
    if (resumeProvider.requiresPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPasswordDialog(context, resumeProvider, pdfParser);
      });
    }

    final isParsing = resumeProvider.state == IngestionState.parsing;
    final isAnalyzing = resumeProvider.state == IngestionState.analyzing;

    if (isAnalyzing) {
      // Start only one clean 0→100 run per analysis session
      _startProgressSimulation();
    } else if (!isAnalyzing && _progressCompleted) {
      // Reset guard when analysis is done so next upload gets a fresh run
      WidgetsBinding.instance.addPostFrameCallback((_) => _resetProgressSimulation());
    }



    // Colors matching HTML palette
    final bgColor = isDark ? const Color(0xFF0B1C30) : const Color(0xFFF8F9FF);
    final cardBgColor = isDark ? const Color(0xFF142438) : Colors.white;
    final borderCol = isDark ? const Color(0xFF23354D) : const Color(0xFFC7C4D8).withValues(alpha: 0.4);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1C30);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Glow Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3525CD).withValues(alpha: isDark ? 0.2 : 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF006A61).withValues(alpha: isDark ? 0.2 : 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(),
              ),
            ),
          ),

          // Main Center Content Canvas
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    _buildHeaderSection(textPrimary, textMuted),
                    const SizedBox(height: 36),

                    // Bento Grid Layout (2:1 Ratio on Desktop, 1 Column on Mobile)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 720;
                        return Flex(
                          direction: isDesktop ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Upload Area (Span 2 cols)
                            Expanded(
                              flex: isDesktop ? 2 : 0,
                              child: _buildUploadCard(
                                context,
                                resumeProvider,
                                pdfParser,
                                cardBgColor,
                                borderCol,
                                textPrimary,
                                textMuted,
                                isDark,
                              ),
                            ),
                            if (isDesktop) const SizedBox(width: 24) else const SizedBox(height: 24),

                            // Configuration Area (Span 1 col)
                            Expanded(
                              flex: isDesktop ? 1 : 0,
                              child: _buildTargetRoleCard(
                                resumeProvider,
                                cardBgColor,
                                borderCol,
                                textPrimary,
                                textMuted,
                                isDark,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action Button & Sample Resume Row
                    _buildActionFooterRow(context, resumeProvider, pdfParser, isDark),
                    const SizedBox(height: 16),

                    // Error Notification Banner
                    if (resumeProvider.errorMessage.isNotEmpty)
                      _buildErrorBanner(resumeProvider.errorMessage),
                  ],
                ),
              ),
            ),
          ),

          // Simple upload loader (parsing state — file being read)
          if (isParsing)
            Positioned.fill(
              child: _buildUploadingOverlay(isDark),
            ),

          // Premium AI Analysis loader (analyzing state — AI processing)
          if (isAnalyzing)
            Positioned.fill(
              child: _buildScanningModalOverlay(cardBgColor, borderCol, textPrimary, textMuted, isDark, resumeProvider),
            ),

        ],
      ),
    );
  }

  // Header Hero Widget with Gradient Text Accent
  Widget _buildHeaderSection(Color textPrimary, Color textMuted) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.02,
              color: textPrimary,
              height: 1.2,
            ),
            children: [
              const TextSpan(text: 'Upload your resume for '),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF3525CD), Color(0xFF006A61)],
                  ).createShader(bounds),
                  child: Text(
                    'AI Analysis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "We'll scan your document against industry standards and your target role to provide actionable insights and improve your match rate.",
          style: GoogleFonts.inter(
            fontSize: 16,
            color: textMuted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Upload Area Bento Card (Span 2)
  Widget _buildUploadCard(
    BuildContext context,
    ResumeProvider provider,
    PdfParserService pdfParser,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final hasFile = provider.selectedFileName.isNotEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: _isHoveringDropzone,
      builder: (context, isHovering, _) {
        return MouseRegion(
          onEnter: (_) => _isHoveringDropzone.value = true,
          onExit: (_) => _isHoveringDropzone.value = false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(minHeight: 310),
            decoration: BoxDecoration(
              color: isHovering
                  ? const Color(0xFF3525CD).withValues(alpha: 0.05)
                  : cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovering ? const Color(0xFF3525CD) : borderCol,
                width: isHovering ? 2.0 : 1.5,
              ),
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
                if (!hasFile) ...[
                  // Default Dropzone State
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3525CD).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload,
                      size: 38,
                      color: Color(0xFF3525CD),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Drag & Drop your resume',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Supports PDF, DOCX, or TXT (Max 5MB)',
                    style: GoogleFonts.inter(fontSize: 14, color: textMuted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.pickAndParseFile(pdfParser),
                    icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Upload Resume Now',
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3525CD),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 2,
                    ),
                  ),
                ] else ...[
                  // Selected File State (100% Centered Layout)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderCol),
                              ),
                              child: const Icon(
                                Icons.description,
                                size: 36,
                                color: Color(0xFF3525CD),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF006A61),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.selectedFileName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'File ready for analysis',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006A61),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => provider.pickAndParseFile(pdfParser),
                          icon: const Icon(Icons.refresh, color: Color(0xFF3525CD), size: 18),
                          label: Text(
                            'Change File',
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
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Target Role Bento Card (Span 1)
  Widget _buildTargetRoleCard(
    ResumeProvider provider,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    if (_roleController.text != provider.targetRole && provider.targetRole.isNotEmpty) {
      _roleController.text = provider.targetRole;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(minHeight: 310),
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
              const Icon(Icons.track_changes, color: Color(0xFF006A61), size: 22),
              const SizedBox(width: 8),
              Text(
                'Target Role',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select or type the role you are aiming for to tailor the analysis.',
            style: GoogleFonts.inter(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Searchable Role Input Field
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return _targetRoles.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              _roleController.text = selection;
              provider.setTargetRole(selection);
            },
            // Theme-aware dropdown overlay
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? const Color(0xFF1E2D42) : Colors.white,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 280),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              option,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
                onChanged: (val) => provider.setTargetRole(val),
                decoration: InputDecoration(
                  hintText: 'e.g. Flutter Developer *',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: textMuted),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF777587)),
                  suffixIcon: textEditingController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFF777587)),
                          onPressed: () {
                            textEditingController.clear();
                            provider.setTargetRole('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderCol),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderCol),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF3525CD), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Quick Selectable Role Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickRoles.map((role) {
              final isSelected = provider.targetRole.toLowerCase() == role.toLowerCase();
              return InkWell(
                onTap: () {
                  _roleController.text = role;
                  provider.setTargetRole(role);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3525CD)
                        : (isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Footer Action Buttons Row
  Widget _buildActionFooterRow(
    BuildContext context,
    ResumeProvider provider,
    PdfParserService pdfParser,
    bool isDark,
  ) {
    final canAnalyze = provider.selectedFileName.isNotEmpty || provider.extractedText.isNotEmpty;
    final hasRole = provider.targetRole.trim().isNotEmpty;
    final authProvider = context.watch<AuthProvider>();
    final storage = context.read<LocalStorageService>();
    final uid = authProvider.currentUser?.uid ?? 'anonymous';
    final remainingAttempts = storage.getRemainingAttempts(uid);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Attempts Status Counter Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3525CD).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 6),
              Text(
                'Attempts Remaining (48h): ',
                style: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555)),
              ),
              Text(
                '$remainingAttempts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: remainingAttempts > 0 ? const Color(0xFF006A61) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),

        // Primary Start Analysis Button
        ElevatedButton.icon(
          onPressed: canAnalyze
              ? () {
                  // 1. Target Role Mandatory Validation
                  if (!hasRole) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select or enter a Target Role before analyzing.',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF3525CD),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }

                  // 2. Google Authentication Guard
                  if (!authProvider.isAuthenticated) {
                    _showGoogleAuthDialog(context);
                    return;
                  }

                  // 3. 48-Hour Attempt Limit Check (4 per 48 hours per UID)
                  if (remainingAttempts <= 0) {
                    if (kIsWeb) {
                      // Web: No AdMob — show clean limit-reached dialog
                      _showLimitReachedWebDialog(context);
                    } else {
                      // Android/iOS: Show AdMob rewarded ad dialog
                      _showAdMobUnlockDialog(context, storage, () {
                        storage.recordAnalysisAttempt(uid);
                        _executeAnalysisPipeline(context, provider, storage, uid);
                      });
                    }
                    return;
                  }

                  // Deduct attempt & run analysis
                  storage.recordAnalysisAttempt(uid);
                  _executeAnalysisPipeline(context, provider, storage, uid);
                }
              : null,
          icon: const Icon(Icons.analytics, color: Colors.white, size: 20),
          label: Text(
            'Start Analysis',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006A61),
            disabledBackgroundColor: const Color(0xFF006A61).withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: canAnalyze ? 3 : 0,
          ),
        ),
      ],
    );
  }

  void _executeAnalysisPipeline(
    BuildContext context,
    ResumeProvider provider,
    LocalStorageService storage,
    String uid,
  ) {
    provider.verifyAndProceed(
      storage,
      uid,
      () {
        final text = provider.extractedText;
        final targetRole = provider.targetRole.isNotEmpty ? provider.targetRole : 'Software Engineer';
        final skills = provider.detectedSkills.isNotEmpty
            ? provider.detectedSkills
            : provider.recommendedSkills;
        final interviewProvider = context.read<InterviewProvider>();
        final quizProvider = context.read<QuizProvider>();

        Future.microtask(() async {
          interviewProvider.resetAll();
          quizProvider.resetAll();
          interviewProvider.loadOrGenerateQuestions(uid, text, targetRole);
          await Future.delayed(const Duration(milliseconds: 800));
          quizProvider.startQuiz(uid, targetRole, skills, text);
        });

        if (mounted) {
          context.go('/workspace/critique');
        }
      },
    );
  }

  // Error Banner Widget
  Widget _buildErrorBanner(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBA1A1A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF93000A)),
            ),
          ),
        ],
      ),
    );
  }

  // Simple Upload Loader — shown while file is being read/parsed
  Widget _buildUploadingOverlay(bool isDark) {
    final overlayColor = isDark
        ? const Color(0xFF0B1220).withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.5);
    final cardColor = isDark
        ? const Color(0xFF0F1825).withValues(alpha: 0.97)
        : Colors.white.withValues(alpha: 0.97);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1C30);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: ColoredBox(
        color: overlayColor,
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 30,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular progress indicator
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3525CD)),
                    backgroundColor: const Color(0xFF3525CD).withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Uploading Resume...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reading your PDF file',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Premium AI Analysis Loader — Glassmorphic Card (Matching HTML Spec)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScanningModalOverlay(
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
    bool isDark,
    ResumeProvider resumeProvider,
  ) {
    // Only the PARSED % is truly real-time (driven by progress timer)
    final parsedPercent = _analysisProgress;
    // ATS score is only known after analysis finishes — null while in-flight
    final int? atsScore = resumeProvider.state == IngestionState.success
        ? resumeProvider.atsScore
        : null;

    // Footer cycling messages
    const footerMessages = [
      'Understanding your experience...',
      'Discovering missing keywords...',
      'Mapping skills to industry standards...',
    ];
    final footerIndex = (_analysisProgress ~/ 34).clamp(0, footerMessages.length - 1);

    final overlayColor = isDark
        ? const Color(0xFF0B1220).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.55);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: ColoredBox(
        color: overlayColor,
        child: Center(
          child: Container(
            width: 620,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F1825).withValues(alpha: 0.97)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.2 : 0.1),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. Header — Brand Logo + Title ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description, color: Color(0xFF3525CD), size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'ResumeAI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3525CD),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Analyzing Your Resume',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    'Our AI is extracting ATS insights, mapping core skills, and evaluating structural integrity.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 2. Central Animation Area — Rotating Rings + Floating Chips ──
                RepaintBoundary(
                  child: SizedBox(
                    width: 190,
                    height: 190,
                    child: AnimatedBuilder(
                      animation: _scannerAnimController,
                      builder: (context, _) {
                        final t = _scannerAnimController.value;
                        return Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Outer pulsing glow
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withValues(
                                      alpha: 0.12 + 0.08 * sin(t * 2 * pi),
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            // Rotating primary arc ring
                            Transform.rotate(
                              angle: t * 2 * pi,
                              child: SizedBox(
                                width: 135,
                                height: 135,
                                child: CircularProgressIndicator(
                                  value: 0.7,
                                  strokeWidth: 3,
                                  color: const Color(0xFF4F46E5),
                                  backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            // Counter-rotating secondary arc
                            Transform.rotate(
                              angle: -t * pi * 1.5,
                              child: SizedBox(
                                width: 108,
                                height: 108,
                                child: CircularProgressIndicator(
                                  value: 0.35,
                                  strokeWidth: 2,
                                  color: const Color(0xFF14B8A6).withValues(alpha: 0.6),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                            // Central icon with pulse scale
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0B1C30) : const Color(0xFFF8F9FF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Transform.scale(
                                scale: 1.0 + 0.05 * sin(t * 2 * pi),
                                child: const Icon(
                                  Icons.document_scanner,
                                  size: 30,
                                  color: Color(0xFF3525CD),
                                ),
                              ),
                            ),
                            // Floating chip — top-left
                            Positioned(
                              top: -6 + sin((t + 0.0) * 2 * pi) * 6,
                              left: -16,
                              child: _buildFloatingChip(
                                icon: Icons.check_circle,
                                label: 'React',
                                bgColor: isDark ? const Color(0xFF1E2D42) : const Color(0xFFD3E4FE),
                                textColor: const Color(0xFF3525CD),
                              ),
                            ),
                            // Floating chip — mid-right
                            Positioned(
                              top: 65 + sin((t + 0.33) * 2 * pi) * 6,
                              right: -36,
                              child: _buildFloatingChip(
                                icon: Icons.psychology,
                                label: 'Leadership',
                                bgColor: isDark ? const Color(0xFF1E2D42) : const Color(0xFFD3E4FE),
                                textColor: const Color(0xFF3525CD),
                              ),
                            ),
                            // Floating chip — bottom-left
                            Positioned(
                              bottom: -2 + sin((t + 0.66) * 2 * pi) * 6,
                              left: -8,
                              child: _buildFloatingChip(
                                icon: Icons.verified,
                                label: '85% ATS',
                                bgColor: isDark ? const Color(0xFF0D3331) : const Color(0xFF86F2E4),
                                textColor: const Color(0xFF006A61),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // ── 3. Progress Section — Gradient Bar + Cycling Status Text ──
                SizedBox(
                  width: 420,
                  child: Column(
                    children: [
                      // Gradient progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 8,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFDCE9FF),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    width: constraints.maxWidth * (_analysisProgress / 100.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4F46E5), Color(0xFF14B8A6)],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Cycling status text with slide-fade animation
                      SizedBox(
                        height: 24,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, anim) {
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            );
                          },
                          child: Row(
                            key: ValueKey<int>(_statusTextIndex),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _statusTextIndex < 2
                                    ? Icons.check
                                    : _statusTextIndex < 5
                                        ? Icons.memory
                                        : Icons.calculate,
                                size: 16,
                                color: const Color(0xFF3525CD),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _scanningStatuses[_statusTextIndex],
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── 4. Live Stats Grid — Parsed / ATS Score ──
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'PARSED',
                        value: parsedPercent,
                        valueColor: textPrimary,
                        textMuted: textMuted,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        label: 'ATS SCORE',
                        value: atsScore,
                        valueColor: const Color(0xFF3525CD),
                        textMuted: textMuted,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 5. Footer Cycling Text ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    footerMessages[footerIndex],
                    key: ValueKey<int>(footerIndex),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF777587),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Floating Chip Widget (for central animation orbit)
  Widget _buildFloatingChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Live Stat Counter Card Widget — value is null while result is loading
  Widget _buildStatCard({
    required String label,
    required int? value,
    required Color valueColor,
    required Color textMuted,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0B1C30).withValues(alpha: 0.5)
            : const Color(0xFFF8F9FF).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF23354D).withValues(alpha: 0.3)
              : const Color(0xFFC7C4D8).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: value != null
                ? Text(
                    '$value%',
                    key: ValueKey<int>(value),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  )
                : Text(
                    '---',
                    key: const ValueKey<String>('loading'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Password decryption popup modal triggers
  void _showPasswordDialog(
    BuildContext context,
    ResumeProvider provider,
    PdfParserService pdfParser,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F131C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0x14FFFFFF)),
            ),
            title: Text(
              'File Encrypted',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter PDF decryption password to parse text contents:',
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF222B3E)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF3525CD)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _passwordController.clear();
                  Navigator.of(context).pop();
                  provider.reset();
                },
                child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                onPressed: () {
                  final pass = _passwordController.text;
                  _passwordController.clear();
                  Navigator.of(context).pop();
                  provider.submitPassword(pdfParser, pass);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3525CD)),
                child: Text('Decrypt & Open', style: GoogleFonts.inter(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGoogleAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFF0F172A),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo Badge
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF006A61)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.psychology, color: Colors.white, size: 34),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Unlock AI Resume Analysis',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in with Google to get detailed ATS scoring, tailored interview prep, and skill quizzes.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Feature Highlights
                _buildModalFeatureRow(Icons.check_circle, '3 Free AI Resume Audits included'),
                const SizedBox(height: 10),
                _buildModalFeatureRow(Icons.check_circle, 'Instant Target Role Interview Questions'),
                const SizedBox(height: 10),
                _buildModalFeatureRow(Icons.check_circle, 'ATS Score Trends & Recommendations'),
                const SizedBox(height: 28),

                // Premium Google Sign-In Button
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF006A61)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      final authProvider = context.read<AuthProvider>();
                      await authProvider.signInWithGoogle();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0B1C30),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_png.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.g_mobiledata,
                            color: Color(0xFF4285F4),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1C30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Maybe Later',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF14B8A6), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFE2E8F0)),
          ),
        ),
      ],
    );
  }

  void _showLimitReachedWebDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF0F172A),
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 34),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Daily Limit Reached',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You've used all 4 free resume analyses for the next 48 hours. Come back soon!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Countdown hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, color: Color(0xFF64748B), size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Resets in 48 hours from your first analysis',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3525CD),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Got it',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAdMobUnlockDialog(
    BuildContext context,
    LocalStorageService storage,
    VoidCallback onUnlocked,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AdMobAdModal(
          onAdComplete: () async {
            await storage.incrementUnlockedBonusAttempts();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 +1 Attempt Unlocked! Starting analysis...', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF006A61),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              onUnlocked();
            }
          },
        );
      },
    );
  }
}

/// Simulated AdMob Video Ad Modal Dialog
class _AdMobAdModal extends StatefulWidget {
  final VoidCallback onAdComplete;
  const _AdMobAdModal({required this.onAdComplete});

  @override
  State<_AdMobAdModal> createState() => _AdMobAdModalState();
}

class _AdMobAdModalState extends State<_AdMobAdModal> {
  int _secondsRemaining = 5;
  Timer? _adTimer;
  bool _isPlaying = false;
  bool _isFinished = false;

  void _startAdPlayer() {
    setState(() {
      _isPlaying = true;
    });

    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isPlaying = false;
          _isFinished = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Extra Attempt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B1C30),
                        ),
                      ),
                      Text(
                        'Free attempts limit reached (4/4)',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF777587)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // AdMob Container Video Player Surface
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!_isPlaying && !_isFinished)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill, color: Color(0xFF6366F1), size: 56),
                        const SizedBox(height: 12),
                        Text(
                          'AdMob Rewarded Ad',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Unit ID: ca-app-pub-3940256099942544/6300978111',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    )
                  else if (_isPlaying)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 3),
                        const SizedBox(height: 16),
                        Text(
                          'Watching Ad... $_secondsRemaining s',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Reward will unlock when ad finishes',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF14B8A6), size: 56),
                        const SizedBox(height: 12),
                        Text(
                          'Ad Completed!',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '+1 Resume Analysis Attempt Granted',
                          style: GoogleFonts.inter(color: const Color(0xFF14B8A6), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                  // Top right Ad badge
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AD',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF777587))),
                ),
                if (!_isPlaying && !_isFinished)
                  ElevatedButton.icon(
                    onPressed: _startAdPlayer,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: Text('Watch Ad to Unlock', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3525CD),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else if (_isFinished)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onAdComplete();
                    },
                    icon: const Icon(Icons.bolt, color: Colors.white),
                    label: Text('Claim +1 Attempt & Analyze', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A61),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
