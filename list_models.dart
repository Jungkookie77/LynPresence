import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyA5scstYpphX_-5_-FMrw9rYJ3cz4UHMdA';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(url);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    print(body);
    client.close();
  } catch (e) {
    print('Error: $e');
  }
}
