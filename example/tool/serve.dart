import 'dart:io';
import 'package:build_runner/build_runner.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'actions.dart';

main() async {
  var handler = await watch(buildActions, deleteFilesByDefault: true);
  var server = await shelf_io.serve(handler.handle, InternetAddress.LOOPBACK_IP_V4, 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}