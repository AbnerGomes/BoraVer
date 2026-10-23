import '../domain/models/movie.dart';

/// Acesso aos filmes salvos. A interface isola o armazenamento: trocar o
/// banco local por um backend na nuvem exige apenas outra implementação.
abstract interface class MovieRepository {
  Future<List<Movie>> loadAll();
  Future<void> save(Movie movie);
  Future<void> saveAll(Iterable<Movie> movies);
  Future<void> delete(String id);
}
