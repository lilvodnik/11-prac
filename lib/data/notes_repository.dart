import 'package:dio/dio.dart';
import '../models/note.dart';
import 'api_client.dart';

class NotesRepository {
  final ApiClient _client;
  final List<Note> _localNotes = [];

  NotesRepository(this._client);

  // Геттер для проверки, является ли заметка локальной
  bool isLocalNote(int id) => id < 0;

  Future<List<Note>> list({int page = 1, int limit = 20}) async {
    try {
      final resp = await _client.dio.get(
        '/posts',
        queryParameters: {'_page': page, '_limit': limit},
      );
      
      if (resp.statusCode == 200) {
        final data = resp.data as List<dynamic>;
        final serverNotes = data.map((e) => 
            Note.fromJson(e as Map<String, dynamic>)).toList();
        return [..._localNotes, ...serverNotes];
      }
      return _localNotes;
    } catch (e) {
      print('Ошибка загрузки с сервера: $e');
      return _localNotes;
    }
  }

  Future<Note?> get(int id) async {
    // Сначала ищем в локальных заметках
    final localNote = _localNotes.firstWhere(
      (note) => note.id == id,
      orElse: () => Note(id: -1, title: '', body: ''),
    );
    
    if (localNote.id != -1) {
      return localNote;
    }
    
    // Если не нашли локально, пробуем загрузить с сервера
    try {
      final resp = await _client.dio.get('/posts/$id');
      if (resp.statusCode == 200) {
        return Note.fromJson(resp.data as Map<String, dynamic>);
      }
    } catch (e) {
      print('Ошибка загрузки деталей: $id: $e');
    }
    
    return null;
  }

  // ===== МЕТОДЫ ДЛЯ ЛОКАЛЬНЫХ ЗАМЕТОК =====

  /// Создание новой локальной заметки
  Note createLocal(String title, String body) {
    final int newId = -DateTime.now().millisecondsSinceEpoch;
    final newNote = Note(id: newId, title: title, body: body);
    _localNotes.insert(0, newNote);
    return newNote;
  }

  /// Обновление существующей локальной заметки
  void updateLocal(int id, String title, String body) {
    final index = _localNotes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _localNotes[index] = Note(id: id, title: title, body: body);
      print('Локальная заметка $id обновлена');
    } else {
      print('Локальная заметка $id не найдена для обновления');
    }
  }

  /// Удаление локальной заметки
  bool deleteLocal(int id) {
    final index = _localNotes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _localNotes.removeAt(index);
      return true;
    }
    return false;
  }

  /// Восстановление удаленной локальной заметки
  void restoreLocalNote(Note note) {
    _localNotes.insert(0, note);
  }

  // ===== МЕТОДЫ ДЛЯ СЕРВЕРНЫХ ЗАМЕТОК (ДЕМО) =====

  /// Демонстрация POST запроса (создание на сервере)
  Future<Note> create(String title, String body) async {
    try {
      final resp = await _client.dio.post(
        '/posts',
        data: {
          'title': title,
          'body': body,
          'userId': 1, // Требуется по JSONPlaceholder API
        },
      );
      
      if (resp.statusCode == 201) {
        print('✅ POST запрос успешен (демо)');
        return Note.fromJson(resp.data as Map<String, dynamic>);
      } else {
        throw Exception('Ошибка сервера: ${resp.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка POST запроса: $e');
      rethrow;
    }
  }

  /// Демонстрация PATCH запроса (обновление на сервере)
  Future<Note> update(int id, String title, String body) async {
    try {
      final resp = await _client.dio.patch(
        '/posts/$id',
        data: {
          'title': title,
          'body': body,
        },
      );
      
      if (resp.statusCode == 200) {
        print('✅ PATCH запрос успешен (демо)');
        return Note.fromJson(resp.data as Map<String, dynamic>);
      } else {
        throw Exception('Ошибка сервера: ${resp.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка PATCH запроса: $e');
      rethrow;
    }
  }

  /// Демонстрация DELETE запроса (удаление с сервера)
  Future<void> delete(int id) async {
    try {
      final resp = await _client.dio.delete('/posts/$id');
      
      if (resp.statusCode == 200) {
        print('✅ DELETE запрос успешен (демо)');
      } else {
        throw Exception('Ошибка сервера: ${resp.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка DELETE запроса: $e');
      rethrow;
    }
  }

  // ===== ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ =====

  /// Получение всех локальных заметок (для отладки)
  List<Note> getAllLocalNotes() {
    return List.from(_localNotes);
  }

  /// Получение количества локальных заметок
  int get localNotesCount => _localNotes.length;

  /// Очистка всех локальных заметок (для тестирования)
  void clearLocalNotes() {
    _localNotes.clear();
    print('Все локальные заметки очищены');
  }
}