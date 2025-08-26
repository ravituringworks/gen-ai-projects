import 'dart:convert'; import 'package:http/http.dart' as http;
class Api{ final String base; Api({this.base='http://127.0.0.1:8080'});
  Future<Map<String,dynamic>> home() async => jsonDecode((await http.get(Uri.parse('$base/v1/recs/home'))).body);
  Future<List<Map<String,dynamic>>> search(String q) async => (jsonDecode((await http.get(Uri.parse('$base/v1/catalog/search?q=$q'))).body)['items'] as List).cast<Map<String,dynamic>>();
  Future<Map<String,dynamic>> manifest(String id) async => jsonDecode((await http.get(Uri.parse('$base/v1/stream/manifest/$id'))).body);
}
