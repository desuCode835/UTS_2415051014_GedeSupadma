import 'package:flutter_test/flutter_test.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/models/quote.dart';

void main() {
  group('Tahap 6 — Task Model Tests', () {
    test('Task can be instantiated and serialization to JSON works', () {
      const task = Task(
        id: 'task-101',
        title: 'Belajar Flutter State Management',
        description: 'Mempelajari konsep stateful widget dan navigasi.',
        deadline: '28 Okt 2026, 23:59 WITA',
        priority: 'Tinggi',
        isCompleted: false,
      );

      final json = task.toJson();

      expect(json, {
        'id': 'task-101',
        'title': 'Belajar Flutter State Management',
        'description': 'Mempelajari konsep stateful widget dan navigasi.',
        'deadline': '28 Okt 2026, 23:59 WITA',
        'priority': 'Tinggi',
        'isCompleted': false,
      });
    });

    test('Task can be deserialized from JSON correctly', () {
      final json = {
        'id': 'task-102',
        'title': 'Integrasi REST API',
        'description': 'Mengambil quotes motivasi dari API dummyjson.',
        'deadline': '30 Okt 2026, 12:00 WITA',
        'priority': 'Sedang',
        'isCompleted': true,
      };

      final task = Task.fromJson(json);

      expect(task.id, 'task-102');
      expect(task.title, 'Integrasi REST API');
      expect(task.description, 'Mengambil quotes motivasi dari API dummyjson.');
      expect(task.deadline, '30 Okt 2026, 12:00 WITA');
      expect(task.priority, 'Sedang');
      expect(task.isCompleted, true);
    });

    test('Task copyWith correctly updates specified fields', () {
      const original = Task(
        id: 'task-103',
        title: 'Judul Asli',
        description: 'Deskripsi Asli',
        deadline: '1 Nov 2026',
        priority: 'Rendah',
        isCompleted: false,
      );

      final updated = original.copyWith(
        title: 'Judul Diperbarui',
        isCompleted: true,
      );

      expect(updated.id, 'task-103');
      expect(updated.title, 'Judul Diperbarui');
      expect(updated.description, 'Deskripsi Asli');
      expect(updated.deadline, '1 Nov 2026');
      expect(updated.priority, 'Rendah');
      expect(updated.isCompleted, true);
    });
  });

  group('Tahap 6 — Quote Model Tests', () {
    test('Quote can be instantiated and serialization to JSON works', () {
      const quote = Quote(
        id: 1,
        quote: 'The only way to do great work is to love what you do.',
        author: 'Steve Jobs',
      );

      final json = quote.toJson();

      expect(json, {
        'id': 1,
        'quote': 'The only way to do great work is to love what you do.',
        'author': 'Steve Jobs',
      });
    });

    test('Quote can be deserialized from JSON correctly', () {
      final json = {
        'id': 42,
        'quote': 'Stay hungry, stay foolish.',
        'author': 'Whole Earth Catalog',
      };

      final quote = Quote.fromJson(json);

      expect(quote.id, 42);
      expect(quote.quote, 'Stay hungry, stay foolish.');
      expect(quote.author, 'Whole Earth Catalog');
    });

    test('Quote copyWith correctly updates specified fields', () {
      const original = Quote(
        id: 10,
        quote: 'Kata mutiara lama',
        author: 'Penulis Lama',
      );

      final updated = original.copyWith(
        quote: 'Kata mutiara baru',
        author: 'Penulis Baru',
      );

      expect(updated.id, 10);
      expect(updated.quote, 'Kata mutiara baru');
      expect(updated.author, 'Penulis Baru');
    });
  });
}
