import 'package:intl/intl.dart';

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60)  return 'just now';
  if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)    return '${diff.inHours}h ago';
  if (diff.inDays < 7)      return '${diff.inDays}d ago';
  if (diff.inDays < 30)     return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365)    return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

String formatDate(DateTime date) =>
    DateFormat('MMM d, yyyy').format(date);

String formatSalary(int? min, int? max, {String currency = '₹', String unit = 'lpa'}) {
  if (min == null && max == null) return 'Salary not disclosed';
  final label = unit == 'thousands' ? 'K/mo' : 'LPA';
  final fmt   = unit == 'thousands' ? _compactK : _compactLPA;
  if (min != null && max != null) return '$currency${fmt(min)}–${fmt(max)} $label';
  if (min != null) return '$currency${fmt(min)}+ $label';
  return 'Up to $currency${fmt(max!)} $label';
}

String _compactLPA(int n) {
  // Values stored as whole LPA (e.g. 22 = ₹22 LPA)
  return n.toString();
}

String _compactK(int n) {
  // Values stored as thousands (e.g. 50 = ₹50K/month)
  return n.toString();
}

String getInitials(String? name) {
  // Guard against a whitespace-only name (e.g. "   ") slipping past a bare
  // .isEmpty check — trim first, then bail out to '?' if nothing is left,
  // otherwise parts[0][0] below can index into an empty string and crash.
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
}

String jobTypeLabel(String type) {
  const map = {
    'full_time':  'Full Time',
    'part_time':  'Part Time',
    'internship': 'Internship',
    'freelance':  'Freelance',
    'contract':   'Contract',
  };
  return map[type] ?? type;
}

String jobModeLabel(String mode) {
  const map = {
    'remote': 'Remote',
    'hybrid': 'Hybrid',
    'onsite': 'On-site',
  };
  return map[mode] ?? mode;
}

String appStatusLabel(String status) {
  const map = {
    'applied':     'Applied',
    'shortlisted': 'Shortlisted',
    'interview':   'Interview',
    'offer':       'Offer',
    'rejected':    'Rejected',
    'withdrawn':   'Withdrawn',
  };
  return map[status] ?? status;
}
