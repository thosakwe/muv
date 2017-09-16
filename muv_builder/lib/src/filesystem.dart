import 'dart:async';
import 'package:build/build.dart';
import 'package:muv/muv.dart';

class AssetFileSystem implements MuvFileSystem {
  final BuildStep buildStep;

  AssetFileSystem(this.buildStep);

  @override
  MuvFile resolve(Uri path) {
    return new _AssetFile(
        new AssetId(buildStep.inputId.package, path.path), buildStep);
  }
}

class _AssetFile implements MuvFile {
  final AssetId assetId;
  final BuildStep buildStep;

  _AssetFile(this.assetId, this.buildStep);

  @override
  Uri get uri => assetId.uri;

  @override
  Future<String> readAsString() => buildStep.readAsString(assetId);
}
