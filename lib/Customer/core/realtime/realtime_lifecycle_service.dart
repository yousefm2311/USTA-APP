abstract class RealtimeAwareService {
  bool get isStarted;

  Future<void> start();

  Future<void> stop();
}
