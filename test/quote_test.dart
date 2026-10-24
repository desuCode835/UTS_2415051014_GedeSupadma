import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uts_2415051014_gedesupadma/models/quote.dart';
import 'package:uts_2415051014_gedesupadma/services/api_service.dart';
import 'package:uts_2415051014_gedesupadma/repositories/quote_repository.dart';
import 'package:uts_2415051014_gedesupadma/providers/quote_provider.dart';
import 'package:uts_2415051014_gedesupadma/screens/home_screen.dart';
import 'package:provider/provider.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class FakeQuoteRepository extends QuoteRepository {
  Quote? quoteToReturn;
  Exception? exceptionToThrow;

  FakeQuoteRepository({this.quoteToReturn, this.exceptionToThrow});

  @override
  Future<Quote> getRandomQuote() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return quoteToReturn ??
        const Quote(
          id: 1,
          quote: 'Kutipan uji coba sukses.',
          author: 'Penulis Uji',
        );
  }
}

void main() {
  group('Tahap 8 — ApiService & QuoteRepository Tests', () {
    test('ApiService parses valid response correctly', () async {
      final client = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 99,
            'quote': 'Do what you can, with what you have, where you are.',
            'author': 'Theodore Roosevelt',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiService(client: client);
      final quote = await service.getRandomQuote();

      expect(quote.id, 99);
      expect(quote.quote, 'Do what you can, with what you have, where you are.');
      expect(quote.author, 'Theodore Roosevelt');
    });

    test('ApiService throws HttpException on non-200 response', () async {
      final client = MockHttpClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = ApiService(client: client);
      expect(() => service.getRandomQuote(), throwsA(isA<HttpException>()));
    });

    test('ApiService throws FormatException on invalid json format', () async {
      final client = MockHttpClient((request) async {
        return http.Response('["invalid", "list"]', 200);
      });

      final service = ApiService(client: client);
      expect(() => service.getRandomQuote(), throwsA(isA<FormatException>()));
    });

    test('QuoteRepository delegates to ApiService correctly', () async {
      final client = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 10,
            'quote': 'Simple repository quote.',
            'author': 'Author X',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = QuoteRepository(apiService: ApiService(client: client));
      final quote = await repository.getRandomQuote();

      expect(quote.id, 10);
      expect(quote.quote, 'Simple repository quote.');
      expect(quote.author, 'Author X');
    });
  });

  group('Tahap 8 — QuoteProvider Tests', () {
    test('Initial state is empty and not loading', () {
      final provider = QuoteProvider();
      expect(provider.quote, isNull);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('fetchQuote() sets quote and ends loading on success', () async {
      final fakeRepo = FakeQuoteRepository(
        quoteToReturn: const Quote(
          id: 42,
          quote: 'Sukses adalah sebuah perjalanan.',
          author: 'Anonim',
        ),
      );

      final provider = QuoteProvider(repository: fakeRepo);
      expect(provider.isLoading, false);

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.fetchQuote();

      expect(notified, isTrue);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.quote?.id, 42);
      expect(provider.quote?.quote, 'Sukses adalah sebuah perjalanan.');
      expect(provider.quote?.author, 'Anonim');
    });

    test('fetchQuote() handles error and sets errorMessage', () async {
      final fakeRepo = FakeQuoteRepository(
        exceptionToThrow: const SocketException('No Internet'),
      );

      final provider = QuoteProvider(repository: fakeRepo);
      await provider.fetchQuote();

      expect(provider.isLoading, false);
      expect(provider.quote, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('koneksi internet'));
    });

    test('Reload retaining previous quote when refresh fails', () async {
      final fakeRepo = FakeQuoteRepository(
        quoteToReturn: const Quote(
          id: 1,
          quote: 'Kutipan awal.',
          author: 'Penulis Awal',
        ),
      );

      final provider = QuoteProvider(repository: fakeRepo);
      await provider.fetchQuote();
      expect(provider.quote?.quote, 'Kutipan awal.');

      // Next fetch fails
      fakeRepo.exceptionToThrow = const SocketException('Connection lost');
      await provider.fetchQuote(isRefresh: true);

      // Quote should be preserved!
      expect(provider.quote, isNotNull);
      expect(provider.quote?.quote, 'Kutipan awal.');
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, false);
    });

    test('clearError() clears error message', () async {
      final fakeRepo = FakeQuoteRepository(
        exceptionToThrow: const SocketException('Error test'),
      );

      final provider = QuoteProvider(repository: fakeRepo);
      await provider.fetchQuote();
      expect(provider.errorMessage, isNotNull);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });

  group('Tahap 8 — HomeScreen Quote UI Tests', () {
    testWidgets('Displays quote and author when QuoteProvider has data',
        (WidgetTester tester) async {
      final fakeRepo = FakeQuoteRepository(
        quoteToReturn: const Quote(
          id: 77,
          quote: 'Hiduplah seolah kamu akan mati besok.',
          author: 'Mahatma Gandhi',
        ),
      );
      final quoteProvider = QuoteProvider(repository: fakeRepo);
      await quoteProvider.fetchQuote();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<QuoteProvider>.value(
            value: quoteProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KUTIPAN MOTIVASI'), findsOneWidget);
      expect(
        find.text('“Hiduplah seolah kamu akan mati besok.”'),
        findsOneWidget,
      );
      expect(find.text('— Mahatma Gandhi'), findsOneWidget);
    });

    testWidgets('Displays error and retry button when QuoteProvider has error',
        (WidgetTester tester) async {
      final fakeRepo = FakeQuoteRepository(
        exceptionToThrow: const SocketException('Offline test'),
      );
      final quoteProvider = QuoteProvider(repository: fakeRepo);
      await quoteProvider.fetchQuote();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<QuoteProvider>.value(
            value: quoteProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GAGAL MEMUAT KUTIPAN'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });
}
