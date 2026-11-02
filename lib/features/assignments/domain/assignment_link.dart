String? assignmentLinkError(String? value) {
  final link = value?.trim() ?? '';
  if (link.isEmpty) return null;
  final uri = Uri.tryParse(link);
  if (link.length > 2048 ||
      uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return 'Enter a valid HTTPS link.';
  }
  return null;
}
