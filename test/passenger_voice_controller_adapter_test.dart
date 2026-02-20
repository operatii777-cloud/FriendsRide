import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:friendsride_app/voice/passenger/passenger_voice_controller.dart';
import 'package:friendsride_app/voice/passenger/passenger_voice_controller_adapter.dart';

class MockPassengerVoiceController extends Mock implements PassengerVoiceController {
  @override
  void addListener(VoidCallback listener) =>
      super.noSuchMethod(Invocation.method(#addListener, [listener]));

  @override
  void removeListener(VoidCallback listener) =>
      super.noSuchMethod(Invocation.method(#removeListener, [listener]));

  @override
  bool get wakeWordEnabled =>
      super.noSuchMethod(Invocation.getter(#wakeWordEnabled), returnValue: false);

  @override
  bool get continuousListeningEnabled =>
      super.noSuchMethod(Invocation.getter(#continuousListeningEnabled), returnValue: false);

  @override
  Future<void> toggleWakeWordDetection() => super.noSuchMethod(
        Invocation.method(#toggleWakeWordDetection, []),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );

  @override
  Future<void> enableWakeWordDetection() => super.noSuchMethod(
        Invocation.method(#enableWakeWordDetection, []),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );

  @override
  Future<void> toggleContinuousListening() => super.noSuchMethod(
        Invocation.method(#toggleContinuousListening, []),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );

  @override
  Future<void> enableContinuousListening() => super.noSuchMethod(
        Invocation.method(#enableContinuousListening, []),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );
}

void main() {
  late MockPassengerVoiceController controller;
  late PassengerVoiceControllerAdapter adapter;

  setUp(() {
    controller = MockPassengerVoiceController();
    when(controller.wakeWordEnabled).thenReturn(false);
    when(controller.continuousListeningEnabled).thenReturn(false);
    adapter = PassengerVoiceControllerAdapter(controller: controller);
  });

  test('exposes wake word and continuous listening states from controller', () {
    when(controller.wakeWordEnabled).thenReturn(true);
    when(controller.continuousListeningEnabled).thenReturn(false);

    expect(adapter.isWakeWordEnabled, isTrue);
    expect(adapter.isContinuousListening, isFalse);
  });

  test('toggleWakeWord forwards call to controller', () async {
    adapter.toggleWakeWord();
    await Future<void>.delayed(Duration.zero);
    verify(controller.toggleWakeWordDetection()).called(1);
  });

  test('enableWakeWordDetection forwards call to controller', () async {
    adapter.enableWakeWordDetection();
    await Future<void>.delayed(Duration.zero);
    verify(controller.enableWakeWordDetection()).called(1);
  });

  test('toggleContinuousListening forwards call to controller', () async {
    adapter.toggleContinuousListening();
    await Future<void>.delayed(Duration.zero);
    verify(controller.toggleContinuousListening()).called(1);
  });

  test('startContinuousListening forwards call to controller', () async {
    adapter.startContinuousListening();
    await Future<void>.delayed(Duration.zero);
    verify(controller.enableContinuousListening()).called(1);
  });
}

