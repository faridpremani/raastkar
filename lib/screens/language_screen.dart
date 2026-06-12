import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageScreen extends StatefulWidget {
  final LanguageService languageService;

  const LanguageScreen({
    super.key,
    required this.languageService,
  });

  @override
  State<LanguageScreen> createState() =>
      _LanguageScreenState();
}

class _LanguageScreenState
    extends State<LanguageScreen> {
  String _selectedName = 'English';

  final List<Map<String, dynamic>> _languages = [
    {
      'name': 'English',
      'nativeName': 'English',
      'locale': Locale('en'),
      'flag': 'us',
      'subtitle': 'Default language',
    },
    {
      'name': 'Urdu',
      'nativeName': 'اردو',
      'locale': Locale('ur'),
      'flag': '🇵🇰',
      'subtitle': 'قومی زبان',
    },
    {
      'name': 'Sindhi',
      'nativeName': 'سنڌي',
      'locale': Locale('ur'),
      'flag': '🇵🇰',
      'subtitle': 'سنڌ جي ٻولي',
    },
    {
      'name': 'Punjabi',
      'nativeName': 'ਪੰਜਾਬੀ',
      'locale': Locale('en'),
      'flag': '🇵🇰',
      'subtitle': 'پنجاب دی بولی',
    },
    {
      'name': 'Pashto',
      'nativeName': 'پښتو',
      'locale': Locale('ur'),
      'flag': '🇵🇰',
      'subtitle': 'د پښتنو ژبه',
    },
    {
      'name': 'Arabic',
      'nativeName': 'العربية',
      'locale': Locale('ar'),
      'flag': '🇸🇦',
      'subtitle': 'اللغة العربية',
    },
    {
      'name': 'Hindi',
      'nativeName': 'हिंदी',
      'locale': Locale('en'),
      'flag': '🇮🇳',
      'subtitle': 'हिंदी भाषा',
    },
    {
      'name': 'Swahili',
      'nativeName': 'Kiswahili',
      'locale': Locale('en'),
      'flag': '🌍',
      'subtitle': 'Lugha ya Afrika',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedName =
        widget.languageService.currentLangName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D52),
        title: const Text(
          'Language — زبان',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme:
            const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1D9E75),
            child: const Column(
              children: [
                Icon(Icons.language,
                    color: Colors.white, size: 44),
                SizedBox(height: 8),
                Text(
                  'Choose your language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'اپنی زبان منتخب کریں',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected =
                    _selectedName == lang['name'];

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedName = lang['name'];
                    });
                    await widget.languageService
                        .changeLanguage(
                      lang['locale'] as Locale,
                      lang['name'] as String,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                        bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8F5E9)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E7D52)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(
                                    0xFF2E7D52)
                                : Colors.grey.shade100,
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                          ),
                          child: Center(
                            child: Text(
                              lang['flag'],
                              style: const TextStyle(
                                  fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                lang['nativeName'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: isSelected
                                      ? const Color(
                                          0xFF2E7D52)
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                lang['subtitle'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors
                                      .grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 28,
                            height: 28,
                            decoration:
                                const BoxDecoration(
                              color: Color(0xFF2E7D52),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        else
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors
                                      .grey.shade300),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}