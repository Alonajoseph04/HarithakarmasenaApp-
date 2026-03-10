import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';

class WasteGuidelinesScreen extends StatelessWidget {
  const WasteGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    final ml = context.watch<LanguageProvider>().isMalayalam;

    final categories = [
      _Cat(
        label: lang.organic,
        emoji: '🥦',
        color: const Color(0xFF4CAF50),
        icon: Icons.eco,
        description: ml
            ? 'ഭക്ഷണ അവശിഷ്ടങ്ങൾ, പഴ/പച്ചക്കറി തൊലി, തോട്ടക്കൃഷി മാലിന്യം, ഇലകൾ, മുട്ടത്തൊലി.'
            : 'Food scraps, fruit/vegetable peels, garden waste, leaves, eggshells, coffee grounds.',
        storageTitle: ml ? 'എങ്ങനെ സൂക്ഷിക്കാം' : 'How to store',
        storage: ml
            ? 'മൂടിയ പാത്രം ഉപയോഗിക്കുക. അധിക ദ്രാവകം ഒഴിക്കുക. ദിവസേന ശൂന്യമാക്കുക.'
            : 'Use a closed container. Drain excess liquid. Keep separate from dry waste. Empty daily.',
        doList: ml
            ? ['ഭക്ഷണ മാലിന്യം പ്ലാസ്റ്റിക്കിൽ നിന്ന് വേർതിരിക്കുക', 'ജൈവ ബാഗ് ഉപയോഗിക്കുക']
            : ['Separate food waste from packaging', 'Use biodegradable bags'],
        dontList: ml
            ? ['പ്ലാസ്റ്റിക്കുമായി കലർത്തരുത്', 'എണ്ണ ഒഴിക്കരുത്']
            : ["Do NOT mix with plastic or paper", "Do NOT pour oils into organic bin"],
      ),
      _Cat(
        label: lang.plastic,
        emoji: '♻️',
        color: const Color(0xFF2196F3),
        icon: Icons.local_drink,
        description: ml
            ? 'PET കുപ്പികൾ, പ്ലാസ്റ്റിക് ബാഗ്, ആവരണം, കോപ്പകൾ, ഫോം ആൻഡ് പ്ലാസ്റ്റിക് ബോക്സ്.'
            : 'PET bottles, plastic bags, wrappers, containers, cups, straws, foam packaging.',
        storageTitle: ml ? 'എങ്ങനെ സൂക്ഷിക്കാം' : 'How to store',
        storage: ml
            ? 'കുപ്പി കഴുകി ഒതുക്കുക. ഉണങ്ങിയ ബാഗിൽ സൂക്ഷിക്കുക. നനഞ്ഞ പ്ലാസ്റ്റിക് പുനരുപയോഗം ബുദ്ധിമുട്ടാണ്.'
            : 'Rinse plastic containers and crush flat. Store in a dry bag.',
        doList: ml
            ? ['കഴുകി ഒതുക്കുക', 'ശൂന്യ സ്ഥലം ലാഭിക്കാൻ ചുരുക്കുക']
            : ['Rinse bottles and containers', 'Flatten items to save space'],
        dontList: ml
            ? ['ഭക്ഷണ ബാക്കിയുള്ള പ്ലാസ്റ്റിക് കലർത്തരുത്']
            : ['Do NOT mix food-soiled plastic with clean plastic'],
      ),
      _Cat(
        label: lang.paper,
        emoji: '📦',
        color: const Color(0xFFFF9800),
        icon: Icons.newspaper,
        description: ml
            ? 'പത്രം, കാർഡ്‌ബോർഡ്, മാഗസിൻ, ഓഫീസ് പേപ്പർ, ക്യാർട്ടൺ.'
            : 'Newspapers, cardboard boxes, magazines, office paper, cartons.',
        storageTitle: ml ? 'എങ്ങനെ സൂക്ഷിക്കാം' : 'How to store',
        storage: ml
            ? 'ഉണക്കമുള്ളിടത്ത് സൂക്ഷിക്കുക. ബോക്സ് ചപ്പിടക്കുക. കെട്ടി സൂക്ഷിക്കുക.'
            : 'Keep paper dry. Flatten cardboard boxes. Bundle newspapers.',
        doList: ml
            ? ['ബോക്സ് ചപ്പിടക്കുക', 'ഭക്ഷണ മാലിന്യത്തിൽ നിന്ന് അകറ്റി നിർത്തുക']
            : ['Flatten boxes to save space', 'Keep away from food waste'],
        dontList: ml
            ? ['ഓഫ് ഗ്രീസ് പേപ്പർ (പിസ്സ ബോക്സ്) പുനരുപയോഗിക്കരുത്']
            : ['Do NOT recycle greasy paper (pizza boxes)', 'Do NOT wet paper before storing'],
      ),
      _Cat(
        label: lang.ewaste,
        emoji: '📱',
        color: const Color(0xFF9C27B0),
        icon: Icons.devices,
        description: ml
            ? 'പഴയ ഫോൺ, ബ്യാറ്ററി, ചാർജർ, കേബിൾ, ബൾബ്, ടിവി, കംബ്യൂട്ടർ.'
            : 'Old phones, batteries, chargers, cables, bulbs, TVs, computers.',
        storageTitle: ml ? 'പ്രത്യേക ശ്രദ്ധ' : 'Special handling',
        storage: ml
            ? 'യഥാർത്ഥ പാക്കേജിൽ സൂക്ഷിക്കുക. ബ്യാറ്ററി തകർക്കരുത്.'
            : 'Keep in original packaging. Never crush or puncture batteries.',
        doList: ml
            ? ['ഉപകരണങ്ങളിൽ നിന്ന് ബ്യാറ്ററി നീക്കം ചെയ്യുക', 'വലിയ വസ്തുക്കൾ മുൻകൂട്ടി അറിയിക്കുക']
            : ['Remove batteries from devices', 'Inform worker in advance for large items'],
        dontList: ml
            ? ['ബ്യാറ്ററി സാധാരണ ചവറ്റുകൊട്ടയിൽ ഇടരുത്', 'ഇ-വേസ്റ്റ് കത്തിക്കരുത്']
            : ['Do NOT throw batteries in regular waste', 'Do NOT burn e-waste'],
      ),
      _Cat(
        label: lang.glass,
        emoji: '🍶',
        color: const Color(0xFF00BCD4),
        icon: Icons.wine_bar,
        description: ml
            ? 'ഗ്ലാസ് കുപ്പികൾ, ചില്ലലകൾ, ജാറുകൾ, ലൈറ്റ് ബൾബ്.'
            : 'Glass bottles, jars, window glass, mirrors, light bulbs.',
        storageTitle: ml ? 'എങ്ങനെ സൂക്ഷിക്കാം' : 'How to store',
        storage: ml
            ? 'ജാർ കഴുകുക. ഒടിഞ്ഞ ഗ്ലാസ് കനത്ത കടലാസ്സിൽ പൊതിഞ്ഞ് ഒരു ബോക്സിൽ സൂക്ഷിക്കുക.'
            : 'Rinse jars and bottles. Wrap broken glass in thick paper. Keep in a sturdy box.',
        doList: ml
            ? ['ഉണ്ടാക്കുന്നതിന് മുൻപ് കഴുകുക', 'ഒടിഞ്ഞ ഗ്ലാസ് കൈകാര്യം ചെയ്യാൻ ഗ്ലൗസ് ഉപയോഗിക്കുക']
            : ['Rinse before disposal', 'Handle with gloves if broken'],
        dontList: ml
            ? ['ഒടിഞ്ഞ ഗ്ലാസ് അയഞ്ഞ് ഇടരുത്', 'സെറാമിക്സ് ഗ്ലാസ്സുമായി കലർത്തരുത്']
            : ['Do NOT mix broken glass loosely', 'Do NOT include ceramics with glass'],
      ),
      _Cat(
        label: lang.hazardous,
        emoji: '⚠️',
        color: const Color(0xFFF44336),
        icon: Icons.warning_amber,
        description: ml
            ? 'പെയ്ന്റ്, കെമിക്കൽ, കീടനാശിനി, മരുന്ന്, ലായകം, മോട്ടോർ ഓയിൽ.'
            : 'Paints, chemicals, pesticides, medicines, solvents, motor oil.',
        storageTitle: ml ? 'പ്രത്യേക ശ്രദ്ധ ആവശ്യം' : 'Special handling required',
        storage: ml
            ? 'സ്വകാര്യ ഭദ്രമായ കൺടെയ്‌നറിൽ സൂക്ഷിക്കുക. കുട്ടികളിൽ നിന്ന് അകറ്റി നിർത്തുക.'
            : 'Keep in original sealed containers. Store away from children and heat.',
        doList: ml
            ? ['ഒറിജിനൽ കൺടെയ്‌നറിൽ അടച്ചുവെക്കുക', 'ശേഖരണ വർക്കറെ മുൻകൂട്ടി അറിയിക്കുക']
            : ['Keep in sealed original containers', 'Inform the worker before collection'],
        dontList: ml
            ? ['ഡ്രെയ്‌നിലേക്ക് ഒഴിക്കരുത്', 'കെമിക്കൽ കുഴക്കരുത്', 'കത്തിക്കരുത്']
            : ['Do NOT pour chemicals down the drain', 'Do NOT mix chemicals', 'Do NOT burn hazardous waste'],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.guidelinesTitle),
        actions: const [LangToggleButton()],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Icon(Icons.recycling, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lang.sortBeforeCollection, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(lang.guidelinesSubtitle, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            );
          }
          final cat = categories[i - 1];
          return _CatCard(cat: cat, lang: lang);
        },
      ),
    );
  }
}

class _CatCard extends StatelessWidget {
  final _Cat cat;
  final AppStrings lang;
  const _CatCard({required this.cat, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: cat.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(cat.icon, color: cat.color, size: 24),
        ),
        title: Text(cat.label, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: cat.color)),
        subtitle: Text('${cat.emoji}  ${cat.description}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight), maxLines: 2, overflow: TextOverflow.ellipsis),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cat.color.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: cat.color),
                    const SizedBox(width: 6),
                    Text(cat.storageTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: cat.color)),
                  ]),
                  const SizedBox(height: 6),
                  Text(cat.storage, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
                ]),
              ),
              const SizedBox(height: 12),
              Text(lang.doTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green.shade700)),
              ...cat.doList.map((d) => Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.check_circle, size: 15, color: Colors.green),
                  const SizedBox(width: 7),
                  Expanded(child: Text(d, style: GoogleFonts.poppins(fontSize: 12))),
                ]),
              )),
              const SizedBox(height: 8),
              Text(lang.dontTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.red.shade700)),
              ...cat.dontList.map((d) => Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.cancel, size: 15, color: Colors.red),
                  const SizedBox(width: 7),
                  Expanded(child: Text(d, style: GoogleFonts.poppins(fontSize: 12))),
                ]),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Cat {
  final String label, emoji, description, storageTitle, storage;
  final Color color;
  final IconData icon;
  final List<String> doList, dontList;
  const _Cat({
    required this.label, required this.emoji, required this.color, required this.icon,
    required this.description, required this.storageTitle, required this.storage,
    required this.doList, required this.dontList,
  });
}
