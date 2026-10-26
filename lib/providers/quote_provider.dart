import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/quote.dart';
import '../repositories/quote_repository.dart';

class QuoteProvider with ChangeNotifier {
  final QuoteRepository _repository;

  Quote? _quote;
  bool _isLoading = false;
  String? _errorMessage;

  QuoteProvider({QuoteRepository? repository})
      : _repository = repository ?? QuoteRepository();

  Quote? get quote => _quote;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchQuote({bool isRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.getRandomQuote();
      _quote = fetched;
      _errorMessage = null;
    } on SocketException catch (e) {
      _errorMessage =
          'Tidak ada koneksi internet. Periksa koneksi internet dan coba lagi (${e.message}).';
    } on TimeoutException {
      _errorMessage =
          'Koneksi waktu habis saat memuat kutipan. Silakan coba lagi.';
    } on HttpException catch (e) {
      _errorMessage = 'Data kutipan belum dapat dimuat: ${e.message}';
    } on FormatException catch (e) {
      _errorMessage = 'Data kutipan tidak valid: ${e.message}';
    } catch (_) {
      _errorMessage =
          'Data belum dapat dimuat. Periksa koneksi internet dan coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
