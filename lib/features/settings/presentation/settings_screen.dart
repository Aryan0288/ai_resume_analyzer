import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _activeTabIndex = 0; // 0: Profile, 1: Account, 2: Preferences, 3: Privacy
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }

  void _initializeUserData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final name = (user.displayName != null && user.displayName!.isNotEmpty)
          ? user.displayName!
          : user.email.split('@').first;
      final nameParts = name.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _emailController.text = user.email;
    } else {
      _firstNameController.text = '';
      _lastNameController.text = '';
      _emailController.text = '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final bgColor = isDark ? const Color(0xFF0B1C30) : const Color(0xFFF8F9FF);
    final cardBgColor = isDark ? const Color(0xFF142438) : Colors.white;
    final borderCol = isDark ? const Color(0xFF23354D) : const Color(0xFFE5EEFF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1C30);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF464555);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: _buildSettingsDrawer(isDark, cardBgColor, borderCol, textPrimary, textMuted),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;
          final tabNames = ['Profile', 'Account', 'Preferences', 'Privacy'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Header with Mobile Hamburger Icon
                    Row(
                      children: [
                        if (!isDesktop)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: IconButton(
                              icon: const Icon(Icons.menu, size: 26),
                              color: textPrimary,
                              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Settings',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: isDesktop ? 32 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  if (!isDesktop) ...[
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF006A61).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tabNames[_activeTabIndex],
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF006A61),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your account settings, preferences, and privacy.',
                                style: GoogleFonts.inter(
                                  fontSize: isDesktop ? 16 : 13,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Settings Inner Layout
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 240,
                            child: _buildSettingsTabRail(isDark, cardBgColor, borderCol, textPrimary, textMuted),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildActiveTabContent(context, user, isDark, cardBgColor, borderCol, textPrimary, textMuted),
                          ),
                        ],
                      )
                    else
                      _buildActiveTabContent(context, user, isDark, cardBgColor, borderCol, textPrimary, textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsDrawer(
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
  ) {
    final tabs = [
      {'icon': Icons.person_outline, 'label': 'Profile'},
      {'icon': Icons.shield_outlined, 'label': 'Account'},
      {'icon': Icons.tune, 'label': 'Preferences'},
      {'icon': Icons.lock_outline, 'label': 'Privacy'},
    ];

    return Drawer(
      backgroundColor: cardBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF006A61),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderCol),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _activeTabIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isSelected
                          ? const Color(0xFF006A61).withValues(alpha: 0.14)
                          : Colors.transparent,
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? const Color(0xFF006A61) : textMuted,
                        size: 22,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF006A61) : textPrimary,
                        ),
                      ),
                      onTap: () {
                        setState(() => _activeTabIndex = index);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTabRail(bool isDark, Color cardBg, Color borderCol, Color textPrimary, Color textMuted) {
    final tabs = [
      {'icon': Icons.person, 'label': 'Profile'},
      {'icon': Icons.shield_outlined, 'label': 'Account'},
      {'icon': Icons.tune, 'label': 'Preferences'},
      {'icon': Icons.lock_outline, 'label': 'Privacy'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _activeTabIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: () => setState(() => _activeTabIndex = index),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3525CD).withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF3525CD).withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? const Color(0xFF3525CD) : textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF3525CD) : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    dynamic user,
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
  ) {
    if (_activeTabIndex == 0) {
      return _buildProfileTab(context, user, isDark, cardBg, borderCol, textPrimary, textMuted);
    } else if (_activeTabIndex == 1) {
      return _buildGenericSection('Account Settings', 'Security, password & multi-factor authentication.', cardBg, borderCol, textPrimary, textMuted);
    } else if (_activeTabIndex == 2) {
      return _buildGenericSection('Preferences', 'Notification preferences, language & theme controls.', cardBg, borderCol, textPrimary, textMuted);
    } else {
      return _buildGenericSection('Privacy', 'Data retention policy, resume AI storage & permissions.', cardBg, borderCol, textPrimary, textMuted);
    }
  }

  Widget _buildProfileTab(
    BuildContext context,
    dynamic user,
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
  ) {
    final authProvider = context.read<AuthProvider>();
    final photoUrl = user?.photoUrl ?? '';
    final email = user?.email ?? 'Sign in to view account';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your profile photo and identity details are synced with Google Account.',
                  style: GoogleFonts.inter(fontSize: 14, color: textMuted),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderCol),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Display (NO Upload/Remove buttons as requested)
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3525CD),
                            border: Border.all(color: const Color(0xFF3525CD), width: 2),
                          ),
                          child: ClipOval(
                            child: photoUrl.isNotEmpty
                                ? Image.network(
                                    photoUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _buildLetterAvatar(initial),
                                  )
                                : _buildLetterAvatar(initial),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified, size: 18, color: Color(0xFF4285F4)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.displayName ?? 'Google User',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF006A61).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Google Synced',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF006A61),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.inter(fontSize: 14, color: textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Avatar & credentials managed via Google Sign-In',
                            style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Form Fields (First Name, Last Name, Email)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      children: [
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildFormField('First Name', _firstNameController, textPrimary, textMuted, borderCol, isDark),
                        ),
                        if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildFormField('Last Name', _lastNameController, textPrimary, textMuted, borderCol, isDark),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildFormField('Email Address', _emailController, textPrimary, textMuted, borderCol, isDark, readOnly: true),
                const SizedBox(height: 28),

                // Save Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final first = _firstNameController.text.trim();
                        final last = _lastNameController.text.trim();
                        final newName = "$first $last".trim();

                        final success = await authProvider.updateProfileName(newName.isNotEmpty ? newName : 'User');

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '🎉 Profile updated successfully!'
                                    : 'Failed to update profile: ${authProvider.errorMessage}',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              backgroundColor: success ? const Color(0xFF006A61) : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3525CD),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterAvatar(String initial) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    Color textPrimary,
    Color textMuted,
    Color borderCol,
    bool isDark, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
          decoration: InputDecoration(
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
              borderSide: const BorderSide(color: Color(0xFF3525CD)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: readOnly ? const Icon(Icons.lock, size: 16, color: Color(0xFF777587)) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGenericSection(
    String title,
    String description,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 14, color: textMuted),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF006A61), size: 20),
              const SizedBox(width: 8),
              Text(
                'Managed automatically by ResumeAI Cloud Service.',
                style: GoogleFonts.inter(fontSize: 13, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
