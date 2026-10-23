const _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ý': 'y',
  'ÿ': 'y',
};

/// Normaliza texto para comparação e busca: minúsculas, sem acentos,
/// sem pontuação e com espaços simples.
String normalizeText(String input) {
  final buffer = StringBuffer();
  for (final char in input.toLowerCase().split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Compara textos ignorando maiúsculas e acentos (para ordenação).
int compareText(String a, String b) =>
    normalizeText(a).compareTo(normalizeText(b));
