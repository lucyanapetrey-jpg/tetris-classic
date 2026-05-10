import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../services/audio_service.dart';
import '../services/locale_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});
  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  static const _languages = <String, String>{
    'en': 'English',
    'zh': '中文',
    'es': 'Español',
    'hi': 'हिन्दी',
    'ar': 'العربية',
    'pt': 'Português',
    'ru': 'Русский',
    'ja': '日本語',
    'de': 'Deutsch',
    'fr': 'Français',
    'ro': 'Română',
  };

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final audio = AudioService();
    final locale = LocaleService();
    final currentCode = locale.locale?.languageCode;
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Settings',
                        style: TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              SwitchListTile(
                value: audio.enabled,
                onChanged: (v) async {
                  await audio.setEnabled(v);
                  setState(() {});
                },
                title: Text(audio.enabled ? s.musicOn : s.musicOff,
                    style: const TextStyle(color: Colors.white)),
                activeColor: const Color(0xFF00E5FF),
                tileColor: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('Language',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _languages.entries.map((e) {
                      final selected = currentCode == e.key;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0x4400E5FF) : Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: selected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white12),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(e.value,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: selected ? FontWeight.w900 : FontWeight.w400)),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF))
                              : null,
                          onTap: () async {
                            await locale.setLocale(e.key);
                            if (mounted) Navigator.of(context).pop();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await locale.setLocale(null);
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('System default',
                    style: TextStyle(color: Color(0xFFAB47BC))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
