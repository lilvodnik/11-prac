#11 практика
<img width="1512" height="982" alt="Снимок экрана 2025-12-16 в 12 53 27 PM" src="https://github.com/user-attachments/assets/36d73d86-b25c-45b5-b851-615bf1c4ed56" />
начальная страница
<img width="1512" height="982" alt="Снимок экрана 2025-12-16 в 12 53 38 PM" src="https://github.com/user-attachments/assets/1db8e0ec-0e83-49af-9b0e-480ba5f3a252" />
<img width="1512" height="982" alt="Снимок экрана 2025-12-16 в 12 53 42 PM" src="https://github.com/user-attachments/assets/89d8d816-c861-47cc-ac20-2bab61c48143" />
создание первой заметки
<img width="1512" height="982" alt="Снимок экрана 2025-12-16 в 12 53 48 PM" src="https://github.com/user-attachments/assets/ef950990-5228-4950-bc81-3b088fb4d87c" />
<img width="1512" height="982" alt="Снимок экрана 2025-12-16 в 12 54 00 PM" src="https://github.com/user-attachments/assets/8b2669fe-1f5f-48fc-8fcb-639e10deda2f" />
<img width="1512" height="982" alt="Снимок экрана 2025-12-16 в 12 54 21 PM" src="https://github.com/user-attachments/assets/bf86b092-902c-40b9-89d8-d32348a05854" />
редактирование и информация о заметки
<img width="1512" height="982" alt="Снимок экрана 2025-12-16 в 12 54 25 PM" src="https://github.com/user-attachments/assets/b4061fec-09a8-4c50-bcce-3e35fd092863" />
удааление заметки

Вариант A (только чтение): JSONPlaceholder API
Базовый URL: https://jsonplaceholder.typicode.com
Эндпоинты:```
GET /posts — получение списка записей с пагинацие
GET /posts/{id} — получение конкретной записи
POST /posts — демонстрация создания записи (не сохраняется)
PATCH /posts/{id} — демонстрация обновления записи (не сохраняется)
DELETE /posts/{id} — демонстрация удаления записи (не сохраняется)```
Модель Note (lib/models/note.dart):```
class Note {
  final int id;
  final String title;
  final String body;
  Note({required this.id, required this.title, required this.body});  
  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    body: json['body'] ?? json['content'] ?? '',
  );
}```
Репозиторий (lib/data/notes_repository.dart):
Использует паттерн Repository для разделения слоя данных и UI:```
list() — загрузка данных с пагинацией
get() — получение конкретной записи (сначала локально, потом с сервера)
createLocal()/updateLocal()/deleteLocal() — работа с локальными заметками
create()/update()/delete() — демо-методы для HTTP-запросов```
Ключевая особенность: гибридный подход — серверные данные от API + локальные демо-заметки с отрицательными ID.
Ключевые функции:
Пагинация:```
// В notes_repository.dart
Future<List<Note>> list({int page = 1, int limit = 20}) async {
  final resp = await _client.dio.get('/posts', queryParameters: {
    '_page': page, 
    '_limit': limit
  });
}
// В notes_page.dart — бесконечный скролл
itemBuilder: (context, i) {
  if (i == _items.length && _canLoadMore) {
    _loadMore(); // Подгрузка следующей страницы
    return LoadingIndicator();
  }
}```
Обработка ошибок и тайм-ауты:```
// В api_client.dart — настройка Dio
factory ApiClient({required String baseUrl}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
}
// В notes_page.dart — обработка сетевых ошибок
try {
  final batch = await repo.list(page: _page);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Ошибка загрузки')),
  );
}```
UX состояния (loading/empty/error/data):
Loading: CircularProgressIndicator при первичной загрузке
Empty: информационный экран с предложением создать первую запись
Error: Snackbar с сообщением об ошибке + кнопка повтора
Data: список с разделением локальных и серверных записей
