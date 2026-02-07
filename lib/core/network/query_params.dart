Map<String, String> buildPagedQueryParams({
  required int page,
  required int limit,
  String? query,
  DateTime? start,
  DateTime? end,
  Map<String, String?> extra = const {},
}) {
  final params = <String, String>{
    'page': page.toString(),
    'limit': limit.toString(),
  };
  final trimmed = query?.trim() ?? '';
  if (trimmed.isNotEmpty) {
    params['q'] = trimmed;
  }
  for (final entry in extra.entries) {
    final value = entry.value;
    if (value != null && value.isNotEmpty) {
      params[entry.key] = value;
    }
  }
  if (start != null) {
    params['start'] = start.toUtc().toIso8601String();
  }
  if (end != null) {
    params['end'] = end.toUtc().toIso8601String();
  }
  return params;
}
