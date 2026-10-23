/// Gêneros suportados. O [id] é o valor persistido e nunca deve mudar.
enum Genre {
  action('acao', 'Ação'),
  adventure('aventura', 'Aventura'),
  animation('animacao', 'Animação'),
  comedy('comedia', 'Comédia'),
  crime('crime', 'Crime'),
  documentary('documentario', 'Documentário'),
  drama('drama', 'Drama'),
  family('familia', 'Família'),
  fantasy('fantasia', 'Fantasia'),
  scienceFiction('ficcao_cientifica', 'Ficção científica'),
  history('historico', 'Histórico'),
  horror('terror', 'Terror'),
  musical('musical', 'Musical'),
  mystery('misterio', 'Mistério'),
  romance('romance', 'Romance'),
  thriller('suspense', 'Suspense'),
  war('guerra', 'Guerra'),
  western('faroeste', 'Faroeste');

  const Genre(this.id, this.label);

  final String id;
  final String label;

  static Genre? fromId(String id) {
    for (final genre in values) {
      if (genre.id == id) return genre;
    }
    return null;
  }

  /// Gêneros em ordem alfabética do rótulo (para exibir em listas).
  static final List<Genre> sorted = [...values]
    ..sort((a, b) => a.label.compareTo(b.label));
}
