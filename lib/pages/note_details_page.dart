import 'package:flutter/material.dart';
import '../data/notes_repository.dart';
import '../models/note.dart';

class NoteDetailsPage extends StatelessWidget {
  final int id;
  final NotesRepository repo;
  
  const NoteDetailsPage({
    super.key,
    required this.id,
    required this.repo,
  });

  void _showEditDialog(BuildContext context, Note note) {
    final titleController = TextEditingController(text: note.title);
    final bodyController = TextEditingController(text: note.body);
    final bool isLocal = note.id < 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isLocal ? 'Редактировать локальную запись' : 'Редактировать запись'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Содержимое',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 6,
              ),
              if (!isLocal)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Примечание: JSONPlaceholder API не сохраняет изменения на сервере. Это демонстрация PATCH запроса.',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              final newBody = bodyController.text.trim();
              
              if (newTitle.isEmpty || newBody.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заполните все поля'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                if (isLocal) {
                  // Локальное обновление
                  repo.updateLocal(note.id, newTitle, newBody);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Запись обновлена локально'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'OK',
                        onPressed: () {},
                      ),
                    ),
                  );
                } else {
                  // Демо PATCH запрос (JSONPlaceholder)
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Отправка PATCH запроса...'),
                        ],
                      ),
                    ),
                  );
                  
                  // Демонстрация PATCH запроса
                  await Future.delayed(const Duration(seconds: 1));
                  
                  await repo.update(note.id, newTitle, newBody);
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Закрыть loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✅ PATCH запрос успешно отправлен!'),
                            const SizedBox(height: 4),
                            Text(
                              'Метод: PATCH /posts/${note.id}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'Подробнее',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('PATCH запрос'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Отправленные данные:'),
                                    const SizedBox(height: 8),
                                    Text('Title: "$newTitle"'),
                                    Text('Body: "$newBody"'),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Важно: JSONPlaceholder API не сохраняет изменения на сервере. Это демонстрация формата запроса.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Закрыть'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                }
                
                if (context.mounted) {
                  Navigator.pop(context); // Закрыть диалог редактирования
                  Navigator.pop(context); // Вернуться к списку
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Закрыть loading dialog если открыт
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибка'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(navigatorKey.currentContext!),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              const Text(
                'Не удалось загрузить запись',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Возможные причины:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildReason('• Проблема с интернет-соединением'),
                    _buildReason('• Запись не найдена (ID: $id)'),
                    _buildReason('• Ошибка сервера API'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(navigatorKey.currentContext!),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Назад к списку'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Можно добавить повторную попытку
                      Navigator.pop(navigatorKey.currentContext!);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReason(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Note?>(
          future: repo.get(id),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final note = snapshot.data!;
              return Text(note.id < 0 ? 'Локальная запись' : 'Запись #${note.id}');
            }
            return const Text('Загрузка...');
          },
        ),
        actions: [
          FutureBuilder<Note?>(
            future: repo.get(id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Редактировать',
                  onPressed: () => _showEditDialog(context, snapshot.data!),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Note?>(
        future: repo.get(id),
        builder: (context, snapshot) {
          // Состояние загрузки
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          // Ошибка или данные отсутствуют
          if (snapshot.hasError || snapshot.data == null) {
            return _buildErrorScreen();
          }

          // Успешная загрузка данных
          final note = snapshot.data!;
          final isLocal = note.id < 0;
          
          return _buildNoteContent(context, note, isLocal);
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Column(
      children: [
        LinearProgressIndicator(
          backgroundColor: Colors.blue.shade50,
          color: Colors.blue,
          minHeight: 2,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
                const SizedBox(height: 20),
                Text(
                  'Загрузка записи...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: $id',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteContent(BuildContext context, Note note, bool isLocal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о типе записи
          if (isLocal)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.device_hub,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Локальная запись',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Эта запись хранится только в памяти приложения и не будет сохранена на сервере после перезагрузки.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Создано: ${DateTime.fromMillisecondsSinceEpoch(-note.id).toString().substring(0, 16)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_done,
                        color: Colors.green.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Запись с сервера',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Эта запись загружена с JSONPlaceholder API. Редактирование демонстрирует формат PATCH запроса, но изменения не сохранятся на сервере.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Источник: https://jsonplaceholder.typicode.com/posts/$id',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // Заголовок записи
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Text(
              note.title,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: isLocal ? const Color(0xFF1A237E) : Colors.grey.shade800,
                height: 1.3,
              ),
            ),
          ),

          // Разделитель
          Divider(
            thickness: 1,
            color: Colors.grey.shade300,
            height: 32,
          ),

          // Основное содержимое
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            child: Text(
              note.body,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),
          ),

          // Информационная карточка
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Техническая информация',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    icon: Icons.numbers,
                    label: 'ID записи',
                    value: note.id.toString(),
                    color: Colors.blue,
                  ),
                  
                  _buildInfoRow(
                    icon: Icons.category,
                    label: 'Тип записи',
                    value: isLocal ? 'Локальная' : 'Серверная',
                    color: isLocal ? Colors.amber : Colors.green,
                  ),
                  
                  _buildInfoRow(
                    icon: Icons.text_fields,
                    label: 'Длина заголовка',
                    value: '${note.title.length} символов',
                    color: Colors.purple,
                  ),
                  
                  _buildInfoRow(
                    icon: Icons.description,
                    label: 'Длина текста',
                    value: '${note.body.length} символов',
                    color: Colors.deepOrange,
                  ),
                  
                  if (!isLocal)
                    _buildInfoRow(
                      icon: Icons.api,
                      label: 'API эндпоинт',
                      value: '/posts/$id',
                      color: Colors.teal,
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context, note),
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Назад'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Добавьте глобальный ключ для навигации
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();