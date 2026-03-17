const _invisibleCharsPattern = r'[\u00A0\u200B-\u200D\u2060\uFEFF\u3164\uFFA0]';

/// Menghapus karakter non-visual yang sering dipakai untuk bypass validasi.
String stripInvisibleChars(String value) {
  return value.replaceAll(RegExp(_invisibleCharsPattern), '');
}

/// True jika input memiliki konten bermakna setelah karakter non-visual dihapus.
bool hasMeaningfulText(String? value) {
  if (value == null) {
    return false;
  }
  return stripInvisibleChars(value).trim().isNotEmpty;
}

/// Sanitasi ringan sebelum dikirim ke API.
String sanitizeTextInput(String value) {
  return stripInvisibleChars(value).trim();
}
