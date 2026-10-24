import '../models/quote.dart';
import '../services/api_service.dart';

class QuoteRepository {
  final ApiService _apiService;

  QuoteRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<Quote> getRandomQuote() async {
    return await _apiService.getRandomQuote();
  }
}
