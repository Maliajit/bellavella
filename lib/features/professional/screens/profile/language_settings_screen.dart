import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'sub': 'Default'},
    {'name': 'Hindi', 'sub': 'हिन्दी'},
    {'name': 'Gujarati', 'sub': 'ગુજરાતી'},
    {'name': 'Marathi', 'sub': 'मराठी'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('App Language', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(24),
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = _selectedLanguage == lang['name'];
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent, width: 1.5),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(lang['name']!, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              subtitle: Text(lang['sub']!, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
              onTap: () {
                setState(() => _selectedLanguage = lang['name']!);
                Future.delayed(const Duration(milliseconds: 300), () => Navigator.pop(context));
              },
            ),
          );
        },
      ),
    );
  }
}
