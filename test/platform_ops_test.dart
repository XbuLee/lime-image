import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limeimage/core/platform_ops.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('打开请求在监听就绪前缓存，之后按顺序交付且不重复', () async {
    PlatformOps.emitOpenFiles([]);
    final paths = ['cold-start.png'];
    PlatformOps.emitOpenFiles(paths);
    paths.clear();
    PlatformOps.emitOpenFiles(['during-initialization.png']);

    final received = <List<String>>[];
    var subscription = PlatformOps.openFileEvents.listen(received.add);
    PlatformOps.emitOpenFiles(['warm-start.png']);
    await Future<void>.delayed(Duration.zero);
    expect(received, [
      ['cold-start.png'],
      ['during-initialization.png'],
      ['warm-start.png'],
    ]);
    await subscription.cancel();

    received.clear();
    subscription = PlatformOps.openFileEvents.listen(received.add);
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    await subscription.cancel();
  });

  test('原生文件事件在页面建立前到达也不会丢失', () async {
    PlatformOps.initChannel();
    final reply = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'limeimage/platform',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('openFiles', ['Finder 图片.png']),
          ),
          (_) => reply.complete(),
        );
    await reply.future;

    final received = <List<String>>[];
    final subscription = PlatformOps.openFileEvents.listen(received.add);
    await Future<void>.delayed(Duration.zero);
    expect(received, [
      ['Finder 图片.png'],
    ]);
    await subscription.cancel();
  });
}
