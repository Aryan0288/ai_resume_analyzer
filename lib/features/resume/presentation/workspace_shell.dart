import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'resume_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/services/local_storage_service.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'widgets/pdf_view_widget.dart';

/// App shell wrapping all dashboard & workspace screens.
/// Features responsive desktop SideNavBar, top docked Header with search & user profile,
/// draggable split pane for resume critique, and mobile bottom navigation layout.
class WorkspaceShell extends StatefulWidget {
  final Widget child;

  const WorkspaceShell({
    super.key,
    required this.child,
  });

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  double _splitRatio = 0.4; // Left PDF pane width ratio (40%)
  final double _minRatio = 0.25;
  final double _maxRatio = 0.60;

  bool _isDragging = false;


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 1024;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resumeProvider = context.watch<ResumeProvider>();
    final storage = context.read<LocalStorageService>();
    final authProvider = context.watch<AuthProvider>();

    final location = GoRouterState.of(context).matchedLocation;
    final isDashboardRoute = location == '/dashboard';
    final isSplitWorkspaceRoute = location.startsWith('/workspace/split');

    // Standard Theme Colors matching HTML Design
    final sidebarBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final headerBg = isDark ? const Color(0xFF0F172A).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9);
    final borderCol = isDark ? const Color(0xFF1E293B) : const Color(0xFFC7C4D8).withValues(alpha: 0.3);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1C30);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555);

    if (!isDesktop) {
      return _buildMobileTabletLayout(
        context,
        location: location,
        resumeProvider: resumeProvider,
        storage: storage,
        authProvider: authProvider,
        isDark: isDark,
      );
    }

    // -------------------------------------------------------------
    // DESKTOP LAYOUT (Sidebar + TopHeader + Main Canvas)
    // -------------------------------------------------------------
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // 1. Desktop Fixed SideNav (<aside>)
          _buildDesktopSidebar(
            context,
            location: location,
            sidebarBg: sidebarBg,
            borderCol: borderCol,
            textPrimary: textPrimary,
            textMuted: textMuted,
            storage: storage,
            isDark: isDark,
          ),

          // 2. Main Content Wrapper
          Expanded(
            child: Column(
              children: [
                // Top Docked Header (<header>)
                _buildTopDockedHeader(
                  context,
                  headerBg: headerBg,
                  borderCol: borderCol,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  authProvider: authProvider,
                ),

                // Main Canvas Content
                Expanded(
                  child: isDashboardRoute
                      ? const DashboardScreen()
                      : (isSplitWorkspaceRoute
                          ? _buildSplitWorkspaceView(context, resumeProvider, storage)
                          : widget.child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // DESKTOP SIDEBAR WIDGET
  // -------------------------------------------------------------
  Widget _buildDesktopSidebar(
    BuildContext context, {
    required String location,
    required Color sidebarBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
    required LocalStorageService storage,
    required bool isDark,
  }) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderCol)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ResumeAI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3525CD),
                      ),
                    ),
                    Text(
                      'Pro Plan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Main Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/dashboard',
                  isActive: location == '/dashboard',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.upload_file,
                  label: 'Analyze Resume',
                  route: '/workspace/critique',
                  isActive: location == '/workspace/critique' || location == '/',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.psychology,
                  label: 'Interview Prep',
                  route: '/workspace/prep',
                  isActive: location == '/workspace/prep',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.quiz,
                  label: 'Skills Quiz',
                  route: '/workspace/quiz',
                  isActive: location == '/workspace/quiz',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),


          // Footer Tabs (Settings & Theme)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderCol)),
            ),
            child: Column(
              children: [
                _buildFooterNavItem(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => context.go('/settings'),
                  textMuted: textMuted,
                ),
                const SizedBox(height: 4),
                _buildFooterNavItem(
                  context,
                  icon: Icons.contrast,
                  label: 'Theme (${isDark ? 'Dark' : 'Light'})',
                  onTap: () {
                    storage.saveThemeMode(!isDark);
                  },
                  textMuted: textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFDCE9FF).withValues(alpha: 0.6) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? const Border(right: BorderSide(color: Color(0xFF3525CD), width: 4))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF3525CD) : textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? const Color(0xFF3525CD) : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textMuted,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: textMuted, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP DOCKED HEADER WIDGET
  // -------------------------------------------------------------
  Widget _buildTopDockedHeader(
    BuildContext context, {
    required Color headerBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
    required AuthProvider authProvider,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userEmail = authProvider.currentUser?.email ?? 'guest@resumatch.ai';
    final userInitial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'G';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderCol)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Spacer replacing search bar
          const Spacer(),

          // Trailing Actions (Notifications, Help, Profile Avatar / Google Login CTA)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF464555)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Color(0xFF464555)),
                onPressed: () {
                  context.go('/workspace/prep');
                },
              ),
              const SizedBox(width: 12),

              // Unauthenticated -> Google Login CTA | Authenticated -> Profile Avatar Menu
              if (!authProvider.isAuthenticated)
                ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.signInWithGoogle();
                  },
                  // icon: Image.asset(
                  //   'assets/images/google_png.png',
                  //   width: 16,
                  //   height: 16,
                  //   errorBuilder: (_, _, _) => const Icon(
                  //     Icons.g_mobiledata,
                  //     color: Color(0xFF4285F4),
                  //     size: 18,
                  //   ),
                  // ),
                  label: Text(
                    'Sign In',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A61),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              else
                PopupMenuButton<String>(
                  offset: const Offset(0, 52),
                  color: isDark ? const Color(0xFF142438) : Colors.white,
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? const Color(0xFF23354D) : const Color(0xFFE5EEFF)),
                  ),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      _showSignOutConfirmationDialog(context, authProvider);
                    } else if (value == 'dashboard') {
                      context.go('/dashboard');
                    } else if (value == 'settings') {
                      context.go('/settings');
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (authProvider.currentUser?.displayName != null && authProvider.currentUser!.displayName!.isNotEmpty)
                                  ? authProvider.currentUser!.displayName!
                                  : userEmail.split('@').first,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuDivider(color: isDark ? const Color(0xFF23354D) : const Color(0xFFE5EEFF)),
                    PopupMenuItem(
                      value: 'dashboard',
                      child: Row(
                        children: [
                          Icon(Icons.dashboard_outlined, size: 18, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5)),
                          const SizedBox(width: 10),
                          Text(
                            'Dashboard',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 18, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5)),
                          const SizedBox(width: 10),
                          Text(
                            'Settings',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                          const SizedBox(width: 10),
                          Text(
                            'Sign Out',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3525CD),
                      shape: BoxShape.circle,
                      border: Border.all(color: borderCol),
                    ),
                    child: ClipOval(
                      child: (authProvider.currentUser?.photoUrl != null &&
                              authProvider.currentUser!.photoUrl!.isNotEmpty)
                          ? Image.network(
                              authProvider.currentUser!.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Text(
                                  userInitial,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                userInitial,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // DESKTOP SPLIT WORKSPACE VIEW (Left Editor + Right Route Child)
  // -------------------------------------------------------------
  Widget _buildSplitWorkspaceView(
    BuildContext context,
    ResumeProvider resumeProvider,
    LocalStorageService storage,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final leftWidth = totalWidth * _splitRatio;

        return Row(
          children: [
            // Left Pane: Resume Gutter PDF / Text Editor
            SizedBox(
              width: leftWidth,
              child: _buildLeftEditorPane(context, resumeProvider, storage),
            ),

            // Draggable Divider Resize Handle
            MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              onEnter: (_) => setState(() => _isDragging = true),
              onExit: (_) => setState(() => _isDragging = false),
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    final deltaRatio = details.delta.dx / totalWidth;
                    _splitRatio = (_splitRatio + deltaRatio).clamp(_minRatio, _maxRatio);
                  });
                },
                child: Container(
                  width: 8,
                  color: _isDragging ? const Color(0xFF3525CD) : const Color(0xFF23354D),
                  child: Center(
                    child: Container(
                      width: 2,
                      height: 32,
                      color: Colors.white30,
                    ),
                  ),
                ),
              ),
            ),

            // Right Pane: Active Workspace Child (Critique, Prep, Quiz)
            Expanded(
              child: widget.child,
            ),
          ],
        );
      },
    );
  }

  // Left Pane Editor (Original PDF Renderer + Text fallback)
  Widget _buildLeftEditorPane(
    BuildContext context,
    ResumeProvider provider,
    LocalStorageService storage,
  ) {
    final wordCount = provider.extractedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return Container(
      color: const Color(0xFF0C111D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF06090F),
              border: Border(bottom: BorderSide(color: Color(0xFF222B3E))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Color(0xFF14B8A6), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      provider.selectedFileName.isNotEmpty ? provider.selectedFileName : 'Uploaded_Resume.pdf',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: (provider.selectedFileBytes != null && provider.selectedFileBytes!.isNotEmpty)
                ? PdfViewWidget(
                    bytes: provider.selectedFileBytes!,
                    fileName: provider.selectedFileName,
                  )
                : Container(
                    color: const Color(0xFF0A0D14),
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1F2937)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.selectedFileName.isNotEmpty ? provider.selectedFileName : 'Parsed Text View',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Divider(color: Color(0xFF1F2937), height: 24),
                            SelectableText(
                              provider.extractedText.isEmpty
                                  ? 'No resume document loaded. Click "Upload New Resume" to begin.'
                                  : provider.extractedText,
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFE5E7EB), height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF06090F),
              border: Border(top: BorderSide(color: Color(0xFF222B3E))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Word Count: $wordCount',
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.upload_file, size: 14, color: Color(0xFF3525CD)),
                  label: const Text('Change PDF', style: TextStyle(color: Color(0xFF3525CD), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MOBILE / TABLET LAYOUT
  // -------------------------------------------------------------
  Widget _buildMobileTabletLayout(
    BuildContext context, {
    required String location,
    required ResumeProvider resumeProvider,
    required LocalStorageService storage,
    required AuthProvider authProvider,
    required bool isDark,
  }) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B1C30) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Color(0xFF3525CD)),
            const SizedBox(width: 8),
            Text(
              'ResumeAI',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF3525CD)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => _showSignOutConfirmationDialog(context, authProvider),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        selectedItemColor: const Color(0xFF3525CD),
        unselectedItemColor: const Color(0xFF94A3B8),
        currentIndex: _getMobileIndex(location),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/workspace/critique');
              break;
            case 2:
              context.go('/workspace/prep');
              break;
            case 3:
              context.go('/workspace/quiz');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Analyze'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Prep'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
        ],
      ),
    );
  }

  void _showSignOutConfirmationDialog(BuildContext context, AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign Out',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0B1C30),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to sign out of your account?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await authProvider.signOut();
                          if (context.mounted) {
                            context.go('/dashboard');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Sign Out',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getMobileIndex(String path) {
    if (path == '/dashboard') return 0;
    if (path == '/workspace/critique' || path == '/') return 1;
    if (path == '/workspace/prep') return 2;
    if (path == '/workspace/quiz') return 3;
    return 0;
  }
}
