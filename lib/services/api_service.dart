import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/quote.dart';

class ApiService {
  static const String quoteUrl = 'https://dummyjson.com/quotes/random';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Quote> getRandomQuote({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final response = await _client.get(
        Uri.parse(quoteUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          throw const FormatException('Respons server kosong.');
        }
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (!decoded.containsKey('quote') ||
              decoded['quote'] == null ||
              (decoded['quote'] is String &&
                  (decoded['quote'] as String).trim().isEmpty)) {
            throw const FormatException(
              'Data kutipan tidak ditemukan atau bernilai kosong dalam respons server.',
            );
          }
          return Quote.fromJson(decoded);
        } else {
          throw const FormatException('Format respons JSON tidak valid.');
        }
      } else {
        throw HttpException(
          'Gagal memuat kutipan dari server (Status HTTP ${response.statusCode}).',
        );
      }
    } on SocketException catch (e) {
      throw SocketException('Koneksi internet bermasalah: ${e.message}');
    } on TimeoutException {
      throw TimeoutException('Permintaan kutipan melebihi batas waktu (timeout).');
    } on FormatException catch (e) {
      throw FormatException('Gagal memproses data kutipan: ${e.message}');
    } catch (e) {
      if (e is HttpException ||
          e is SocketException ||
          e is TimeoutException ||
          e is FormatException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat mengambil kutipan: $e');
    }
  }
}
