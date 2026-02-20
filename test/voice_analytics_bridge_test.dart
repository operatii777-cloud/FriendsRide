import 'package:flutter_test/flutter_test.dart';
import 'package:friendsride_app/voice/core/voice_analytics.dart';
import 'package:friendsride_app/voice/core/voice_analytics_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceAnalyticsBridge', () {
    late VoiceAnalytics analytics;
    late Map<String, Object?> customKeys;
    late List<Map<String, dynamic>> breadcrumbs;
    late VoiceAnalyticsBridge bridge;

    setUp(() async {
      analytics = VoiceAnalytics();
      await analytics.initialize();
      customKeys = {};
      breadcrumbs = [];

      bridge = VoiceAnalyticsBridge(
        analytics: analytics,
        crashlyticsKeySetter: (key, value) async {
          customKeys[key] = value;
        },
        breadcrumbRecorder: (category, data) {
          breadcrumbs.add({
            'category': category,
            'data': data,
          });
        },
      )..start();
    });

    tearDown(() {
      bridge.dispose();
    });

    test('forwards voice events and metrics to provided callbacks', () async {
      analytics.trackEvent(
        VoiceEventType.userInteraction,
        data: {'action': 'test'},
        userId: 'user-1',
        sessionId: 'session-1',
      );

      analytics.trackPerformance(
        'latency',
        value: 123,
        unit: 'ms',
        metadata: {'phase': 'demo'},
      );

      analytics.trackError(
        errorType: 'voice_error',
        errorMessage: 'microphone blocked',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(customKeys['voice_last_event'], equals('error'));
      expect(customKeys['voice_metric_latency'], equals(123));
      expect(customKeys['voice_last_error'], equals('microphone blocked'));
      expect(breadcrumbs.isNotEmpty, isTrue);

      bridge.recordCrash('monitor_error');
      expect(bridge.snapshot.totalErrors, equals(2));
      expect(bridge.snapshot.totalEvents, equals(2));
      expect(bridge.snapshot.totalMetrics, equals(1));
      expect(bridge.snapshot.lastEventAt, isNotNull);
    });
  });
}

