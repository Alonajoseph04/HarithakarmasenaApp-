import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Household rates the worker after a collection — 4 structured questions.
class WorkerFeedbackScreen extends StatefulWidget {
  final Map<String, dynamic> collection;
  const WorkerFeedbackScreen({super.key, required this.collection});

  @override
  State<WorkerFeedbackScreen> createState() => _WorkerFeedbackScreenState();
}

class _WorkerFeedbackScreenState extends State<WorkerFeedbackScreen> {
  final _api = ApiService();
  final _commentCtrl = TextEditingController();

  // 1=Poor 2=Average 3=Good 4=Excellent (null = not answered yet)
  int? _punctuality, _cleanliness, _attitude, _overall;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _overall != null;

  Future<void> _submit() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LanguageProvider>().strings.feedbackOverall + ' required')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.rateWorker(
        widget.collection['id'] as int,
        _overall!,
        punctuality: _punctuality,
        cleanliness: _cleanliness,
        attitude: _attitude,
        feedback: _commentCtrl.text.trim(),
      );
      if (mounted) setState(() { _submitted = true; _submitting = false; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final c = widget.collection;
    final workerUser = c['worker']?['user'] as Map<String, dynamic>? ?? {};
    final workerName = '${workerUser['first_name'] ?? ''} ${workerUser['last_name'] ?? ''}'.trim();
    final alreadyRated = c['worker_rating'] != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.rateWorker),
        actions: [const LangToggleButton(), const ThemeToggleButton(), const SizedBox(width: 8)],
      ),
      body: _submitted
          ? _ThankYou(workerName: workerName, s: s)
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // Worker summary card
                _WorkerCard(collection: c, workerName: workerName),
                const SizedBox(height: 22),

                if (alreadyRated)
                  _AlreadyRatedBanner(collection: c, s: s)
                else ...[
                  Text(s.howWasService,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(s.feedbackHelps,
                      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  // 4 rating questions
                  _RatingQuestion(
                    label: s.feedbackOverall,
                    icon: Icons.star_rounded,
                    value: _overall,
                    s: s,
                    required: true,
                    onChanged: (v) => setState(() => _overall = v),
                  ),
                  const SizedBox(height: 16),
                  _RatingQuestion(
                    label: s.feedbackPunctuality,
                    icon: Icons.access_time_rounded,
                    value: _punctuality,
                    s: s,
                    onChanged: (v) => setState(() => _punctuality = v),
                  ),
                  const SizedBox(height: 16),
                  _RatingQuestion(
                    label: s.feedbackCleanliness,
                    icon: Icons.cleaning_services_rounded,
                    value: _cleanliness,
                    s: s,
                    onChanged: (v) => setState(() => _cleanliness = v),
                  ),
                  const SizedBox(height: 16),
                  _RatingQuestion(
                    label: s.feedbackAttitude,
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    value: _attitude,
                    s: s,
                    onChanged: (v) => setState(() => _attitude = v),
                  ),
                  const SizedBox(height: 20),

                  // Comment
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: s.feedbackComment,
                      prefixIcon: const Icon(Icons.comment_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: (_submitting || !_canSubmit) ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: Text(_submitting ? '...' : s.submitRating),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _canSubmit ? AppTheme.primary : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────

class _RatingQuestion extends StatelessWidget {
  final String label;
  final IconData icon;
  final int? value;
  final AppStrings s;
  final bool required;
  final ValueChanged<int> onChanged;

  const _RatingQuestion({
    required this.label,
    required this.icon,
    required this.value,
    required this.s,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null ? AppStrings.ratingColors[value! - 1] : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            required ? '$label *' : label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ]),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) {
            final selected = value == i + 1;
            final color = AppStrings.ratingColors[i];
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color : color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color, width: selected ? 2 : 1),
                ),
                child: Text(
                  s.ratingLabels[i],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> collection;
  final String workerName;
  const _WorkerCard({required this.collection, required this.workerName});

  @override
  Widget build(BuildContext context) {
    final c = collection;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withAlpha(40)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primary,
          child: Text(
            (workerName.isEmpty ? 'W' : workerName[0]).toUpperCase(),
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(workerName.isEmpty ? 'Worker' : workerName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('${c['waste_type']} • ${c['date']} • ${c['weight']}kg',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
        ])),
      ]),
    );
  }
}

class _AlreadyRatedBanner extends StatelessWidget {
  final Map<String, dynamic> collection;
  final AppStrings s;
  const _AlreadyRatedBanner({required this.collection, required this.s});

  @override
  Widget build(BuildContext context) {
    final rating = collection['worker_rating'] as int? ?? 0;
    final color = rating > 0 ? AppStrings.ratingColors[rating - 1] : Colors.grey;
    final label = rating > 0 ? s.ratingLabels[rating - 1] : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(children: [
        Icon(Icons.check_circle_rounded, color: color, size: 40),
        const SizedBox(height: 8),
        Text('${s.alreadyRated}: $label',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: color),
            textAlign: TextAlign.center),
        if ((collection['worker_feedback'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('"${collection['worker_feedback']}"',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
              textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}

class _ThankYou extends StatelessWidget {
  final String workerName;
  final AppStrings s;
  const _ThankYou({required this.workerName, required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.star_rounded, size: 80, color: Colors.amber),
        const SizedBox(height: 16),
        Text(s.feedbackThankYou,
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(s.feedbackSent,
            style: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.back),
        ),
      ]),
    ));
  }
}
