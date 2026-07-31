import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis History',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Access past resume audits and generated prep configurations.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // History List Table
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F131C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222B3E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableHeader(),
                  const Divider(color: Color(0xFF222B3E), height: 1),
                  _buildHistoryRow(context, 'Flutter_Senior_Architect_2026.pdf', 'Senior Flutter Engineer', '84%', 'Oct 24, 2024', const Color(0xFF14B8A6)),
                  const Divider(color: Color(0xFF222B3E), height: 1),
                  _buildHistoryRow(context, 'CV_Frontend_Dev.pdf', 'Mobile Engineer', '72%', 'Oct 22, 2024', const Color(0xFFF59E0B)),
                  const Divider(color: Color(0xFF222B3E), height: 1),
                  _buildHistoryRow(context, 'Resume_Generalist.pdf', 'Software Engineer', '65%', 'Oct 20, 2024', const Color(0xFFEF4444)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text('DOCUMENT NAME', style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text('TARGET POSITION', style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('DATE AUDITED', style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('ATS SCORE', style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 48), // Action space alignment
        ],
      ),
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    String filename,
    String targetRole,
    String score,
    String date,
    Color scoreColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    filename,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(targetRole, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(date, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    score,
                    style: TextStyle(color: scoreColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Color(0xFF6366F1), size: 16),
            onPressed: () {
              context.go('/workspace/critique');
            },
          ),
        ],
      ),
    );
  }
}
