import 'dart:convert';
import 'dart:io';

import 'package:mydiary/api/json.dart';

/// Respuestas de ejemplo de la API (`test/fixtures/`), escritas según `openapi.json`.
Json fixture(String name) =>
    asJson(jsonDecode(File('test/fixtures/$name.json').readAsStringSync()));
