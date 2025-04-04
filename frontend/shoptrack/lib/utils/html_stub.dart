// lib/utils/html_stub.dart
// This file provides stubs for dart:html APIs used in the app
// It's imported on non-web platforms as a substitute for dart:html

class Blob {
  Blob(List<dynamic> contents, String type) {}
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
}

class Window {
  void open(String url, String target) {}
}

final window = Window();