// Minimal no-op Live Activities wrapper to keep builds stable across platforms.
// The concrete ActivityKit integration can be enabled on iOS 16.1+ with the
// live_activities plugin once provisioned on device and configured in Xcode.

class LiveActivityService {
  static final LiveActivityService instance = LiveActivityService._();
  LiveActivityService._();

  bool get isSupported => false; // Real support wired at native/Xcode stage

  Future<bool> startExamCountdown({
    required String course,
    required DateTime examDate,
  }) async {
    return false;
  }

  Future<void> updateCountdown({required Duration remaining}) async {}

  Future<void> endExamCountdown() async {}
}


