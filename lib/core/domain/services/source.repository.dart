import '../model/source.dart';

abstract class SourceRepository {
  Future<List<Source>> getAll();
  Future<void> saveAll(List<Source> sources);
}
