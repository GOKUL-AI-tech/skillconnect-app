import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/auth_provider.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});
  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _form        = GlobalKey<FormState>();
  final _title       = TextEditingController();
  final _description = TextEditingController();
  final _company     = TextEditingController();
  final _location    = TextEditingController();
  final _salaryMin   = TextEditingController();
  final _salaryMax   = TextEditingController();
  final _openings    = TextEditingController(text: '1');
  final _skillInput  = TextEditingController();

  String _type       = 'full_time';
  String _mode       = 'onsite';
  String _level      = 'mid';
  String _salaryUnit = 'lpa'; // 'lpa' | 'thousands'
  bool   _isActive   = true;
  bool   _isFeatured = false;
  bool   _posting    = false;

  final List<String> _skills = [];

  static const _types  = ['full_time', 'part_time', 'contract', 'internship', 'freelance'];
  static const _modes  = ['remote', 'hybrid', 'onsite'];
  static const _levels = ['entry', 'junior', 'mid', 'senior', 'lead', 'executive'];

  String _label(String s) => s.replaceAll('_', ' ').toUpperCase();

  @override
  void dispose() {
    for (final c in [_title, _description, _company, _location,
                     _salaryMin, _salaryMax, _openings, _skillInput]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSkill() {
    final s = _skillInput.text.trim();
    if (s.isEmpty || _skills.contains(s)) return;
    setState(() { _skills.add(s); _skillInput.clear(); });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one required skill'),
        backgroundColor: AppColors.warning500));
      return;
    }

    setState(() => _posting = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      // Upsert company by name, get back the id
      final db = DatabaseService();
      final companyName = _company.text.trim();
      final companyRes = await db.upsertCompany(companyName, user.id);
      final companyId  = companyRes['id'] as String;

      await db.postJob({
        'title':           _title.text.trim(),
        'description':     _description.text.trim(),
        'type':            _type,
        'mode':            _mode,
        'level':           _level,
        'location':        _location.text.trim().isEmpty ? null : _location.text.trim(),
        'salary_min':      _salaryMin.text.trim().isEmpty ? null : int.tryParse(_salaryMin.text.trim()),
        'salary_max':      _salaryMax.text.trim().isEmpty ? null : int.tryParse(_salaryMax.text.trim()),
        'salary_unit':     _salaryUnit,
        'openings':        int.tryParse(_openings.text.trim()) ?? 1,
        'skills_required': _skills,
        'is_active':       _isActive,
        'is_featured':     _isFeatured,
        'company_id':      companyId,
        'posted_by':       user.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Job posted successfully! 🎉'),
          backgroundColor: AppColors.success500));
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.danger500));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surface950 : AppColors.warmBg,
      appBar: AppBar(
        title: const Text('Post a Job', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _posting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _posting
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Publish', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),

      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Job Basics ─────────────────────────────────────────────
            _SectionCard(isDark: isDark, title: 'Job Details', children: [
              _field(_title, 'Job Title *', Icons.work_outline, required: true,
                hint: 'e.g. Senior Flutter Developer'),
              _field(_company, 'Company Name *', Icons.business_outlined, required: true,
                hint: 'e.g. Google'),
              _field(_description, 'Job Description *', Icons.description_outlined,
                required: true, maxLines: 6,
                hint: 'Describe the role, responsibilities, and requirements…'),
            ]),

            // ── Type / Mode / Level ─────────────────────────────────────
            _SectionCard(isDark: isDark, title: 'Job Type & Mode', children: [
              _label2('Job Type', isDark),
              Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) =>
                _chip(t.replaceAll('_', ' '), _type == t, () => setState(() => _type = t), isDark,
                  color: AppColors.accent500),
              ).toList()),
              const SizedBox(height: 14),
              _label2('Work Mode', isDark),
              Wrap(spacing: 8, runSpacing: 8, children: _modes.map((m) =>
                _chip(m[0].toUpperCase() + m.substring(1), _mode == m, () => setState(() => _mode = m), isDark,
                  color: AppColors.teal500),
              ).toList()),
              const SizedBox(height: 14),
              _label2('Experience Level', isDark),
              Wrap(spacing: 8, runSpacing: 8, children: _levels.map((l) =>
                _chip(l[0].toUpperCase() + l.substring(1), _level == l, () => setState(() => _level = l), isDark,
                  color: AppColors.purple500),
              ).toList()),
            ]),

            // ── Location & Salary ───────────────────────────────────────
            _SectionCard(isDark: isDark, title: 'Location & Salary', children: [
              _field(_location, 'Location', Icons.location_on_outlined,
                hint: 'e.g. Bangalore, India (leave blank if remote)'),

              // ── Salary Unit selector ──────────────────────────────────
              _label2('Salary Unit', isDark),
              Row(children: [
                Expanded(child: _unitChip('LPA', 'lpa', isDark)),
                const SizedBox(width: 10),
                Expanded(child: _unitChip('Thousands / Month', 'thousands', isDark)),
              ]),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: _field(_salaryMin,
                  _salaryUnit == 'lpa' ? 'Min (LPA)' : 'Min (₹K/mo)',
                  Icons.currency_rupee,
                  keyboard: TextInputType.number,
                  hint: _salaryUnit == 'lpa' ? 'e.g. 6' : 'e.g. 50')),
                const SizedBox(width: 12),
                Expanded(child: _field(_salaryMax,
                  _salaryUnit == 'lpa' ? 'Max (LPA)' : 'Max (₹K/mo)',
                  Icons.currency_rupee,
                  keyboard: TextInputType.number,
                  hint: _salaryUnit == 'lpa' ? 'e.g. 22' : 'e.g. 100')),
              ]),
              _field(_openings, 'No. of Openings', Icons.people_outline,
                keyboard: TextInputType.number, hint: '1'),
            ]),

            // ── Skills ──────────────────────────────────────────────────
            _SectionCard(isDark: isDark, title: 'Required Skills', children: [
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _skillInput,
                    decoration: InputDecoration(
                      hintText: 'e.g. Flutter, Dart, Firebase',
                      prefixIcon: const Icon(Icons.code_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.surface700 : AppColors.surface200),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surface800 : AppColors.surface50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onFieldSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSkill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Add'),
                ),
              ]),
              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: _skills.map((s) =>
                  Chip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.teal500.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(color: AppColors.teal600, fontWeight: FontWeight.w600),
                    deleteIconColor: AppColors.teal500,
                    onDeleted: () => setState(() => _skills.remove(s)),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ).toList()),
              ],
            ]),

            // ── Options ─────────────────────────────────────────────────
            _SectionCard(isDark: isDark, title: 'Publishing Options', children: [
              _toggle('Set as Active', 'Job will be visible to candidates immediately',
                _isActive, (v) => setState(() => _isActive = v), isDark),
              const SizedBox(height: 8),
              _toggle('Feature this Job', 'Appear in "Recommended" on student dashboard',
                _isFeatured, (v) => setState(() => _isFeatured = v), isDark),
            ]),

            const SizedBox(height: 16),

            // ── Submit button ────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _posting ? null : _submit,
              icon: _posting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(_posting ? 'Publishing…' : 'Publish Job',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _unitChip(String label, String value, bool isDark) {
    final selected = _salaryUnit == value;
    return GestureDetector(
      onTap: () => setState(() => _salaryUnit = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand600 : (isDark ? AppColors.surface700 : AppColors.surface100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.brand600 : (isDark ? AppColors.surface600 : AppColors.surface300)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 16,
            color: selected ? Colors.white : (isDark ? AppColors.surface400 : AppColors.surface500),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : (isDark ? Colors.white : AppColors.surface800),
          )),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, bool isDark,
      {Color color = AppColors.brand600}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : (isDark ? AppColors.surface700 : AppColors.surface100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : (isDark ? AppColors.surface600 : AppColors.surface300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : (isDark ? Colors.white : AppColors.surface800),
          ),
        ),
      ),
    );

  Widget _label2(String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: isDark ? AppColors.surface400 : AppColors.surface500,
        letterSpacing: 0.3)),
  );

  Widget _toggle(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, bool isDark) =>
    Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface700 : AppColors.surface50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.surface600 : AppColors.surface200),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.surface900)),
        subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12,
            color: isDark ? AppColors.surface400 : AppColors.surface500)),
        activeColor: AppColors.brand600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    bool required = false, String? hint, int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surface700 : AppColors.surface200),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surface800 : AppColors.surface50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
}

// ── Section Card ───────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final bool     isDark;
  final String   title;
  final List<Widget> children;
  const _SectionCard({required this.isDark, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppColors.surface800 : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.brand900.withValues(alpha: 0.05)),
      boxShadow: isDark ? [] : [
        BoxShadow(color: AppColors.brand900.withValues(alpha: 0.08),
          blurRadius: 16, offset: const Offset(0, 5)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.surface900)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );
}
