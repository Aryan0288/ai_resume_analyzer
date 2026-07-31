import 'package:flutter/material.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

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
                  'Premium Resume Templates',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'ATS-Optimized designs approved by professional recruiters.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 700 ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.3,
                  children: [
                    _buildTemplateCard(
                      context,
                      'Modern Minimalist',
                      'Clean typography and ample white space. Perfect for technology and design positions.',
                      'ATS Rating: 98%',
                      const Color(0xFF14B8A6),
                    ),
                    _buildTemplateCard(
                      context,
                      'Executive Professional',
                      'Traditional serif titles and left-border accents. Built for leadership and finance roles.',
                      'ATS Rating: 95%',
                      const Color(0xFF6366F1),
                    ),
                    _buildTemplateCard(
                      context,
                      'Tech Focused',
                      'Monospace subheadings, dense bullet points, and project metric callouts.',
                      'ATS Rating: 99%',
                      const Color(0xFFF59E0B),
                    ),
                    _buildTemplateCard(
                      context,
                      'Creative Bold',
                      'Right-hand column details list with modern gradients and Outfit headings.',
                      'ATS Rating: 90%',
                      const Color(0xFF818CF8),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    String name,
    String description,
    String rating,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rating,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Preview Template', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Use Template',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
