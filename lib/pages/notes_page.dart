import 'package:flutter/material.dart';
import '../data/notes_repository.dart';
import '../data/api_client.dart';
import '../models/note.dart';
import 'note_details_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late final NotesRepository repo;
  final List<Note> _items = [];
  int _page = 1;
  bool _canLoadMore = true;
  bool _loading = false;
  bool _hasError = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    final client = ApiClient(baseUrl: 'https://jsonplaceholder.typicode.com');
    repo = NotesRepository(client);
    _loadInitialData();
  }

  void _loadInitialData() {
    _loadMore();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
      _page = 1;
      _canLoadMore = true;
      _hasError = false;
    });
    
    try {
      final batch = await repo.list(page: _page, limit: 20);
      setState(() {
        _items.clear();
        _items.addAll(batch);
        _canLoadMore = batch.length >= 20; // JSONPlaceholder имеет ~100 записей
        if (_canLoadMore) _page++;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      _showErrorSnackbar('Ошибка обновления');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_canLoadMore || _loading || _isRefreshing) return;
    
    setState(() {
      _loading = true;
    });
    
    try {
      final batch = await repo.list(page: _page, limit: 20);
      
      // Проверяем, есть ли новые данные
      if (batch.isNotEmpty) {
        // Фильтруем дубликаты
        final newNotes = batch.where((note) => 
          !_items.any((existingNote) => existingNote.id == note.id)
        ).toList();
        
        setState(() {
          _items.addAll(newNotes);
          _canLoadMore = batch.length >= 20;
          if (_canLoadMore) _page++;
        });
      } else {
        setState(() {
          _canLoadMore = false;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Ошибка загрузки');
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать запись'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Содержимое',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
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
            onPressed: () {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              
              if (title.isEmpty || body.isEmpty) {
                _showErrorSnackbar('Заполните все поля');
                return;
              }
              
              // Добавляем локальную заметку
              final newNote = repo.createLocal(title, body);
              
              setState(() {
                _items.insert(0, newNote);
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Запись добавлена'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {},
                  ),
                ),
              );
              
              Navigator.pop(context);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(int index) {
    final deletedNote = _items[index];
    final bool isLocal = deletedNote.id < 0;
    
    setState(() {
      _items.removeAt(index);
    });
    
    if (isLocal) {
      repo.deleteLocal(deletedNote.id);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isLocal ? 'Локальная запись удалена' : 'Запись удалена (демо)'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            setState(() {
              _items.insert(index, deletedNote);
            });
            if (isLocal) {
                // Восстанавливаем в локальном списке
                repo.restoreLocalNote(deletedNote); // Теперь работает
            }
          },
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_items.isEmpty && _loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка данных...'),
          ],
        ),
      );
    }
    
    if (_items.isEmpty && _hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Не удалось загрузить данные',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Проверьте подключение к интернету',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить попытку'),
            ),
          ],
        ),
      );
    }
    
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Нет записей',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Нажмите + чтобы создать первую запись',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length + (_canLoadMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _items.length && _canLoadMore) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: _loading 
                ? const CircularProgressIndicator()
                : const Text(
                    'Загружаем ещё...',
                    style: TextStyle(color: Colors.grey),
                  ),
          );
        }
        
        if (i == _items.length && !_canLoadMore && _items.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: const Text(
              'Все записи загружены',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        
        final n = _items[i];
        final isLocal = n.id < 0;
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          color: isLocal ? Colors.blue.shade50 : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: CircleAvatar(
              backgroundColor: isLocal 
                  ? Colors.blue.shade100 
                  : Colors.green.shade100,
              child: Icon(
                isLocal ? Icons.edit : Icons.cloud_download,
                color: isLocal ? Colors.blue : Colors.green,
                size: 20,
              ),
            ),
            title: Text(
              n.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isLocal ? Colors.blue.shade900 : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                if (isLocal)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Локальная',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red.shade400,
              onPressed: () => _deleteNote(i),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteDetailsPage(id: n.id, repo: repo),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Notes Feed'),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Обновить',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildList(),
      ),
    );
  }
}