abstract class UnlockCodeRepository {
  Future<bool> isValid(String code);
  Future<void> update(String oldCode, String newCode);
}
