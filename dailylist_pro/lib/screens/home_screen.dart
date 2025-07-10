import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/ads_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_header.dart';
import '../widgets/task_item.dart';
import '../widgets/task_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/about_modal.dart';
import '../widgets/ad_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  AppSettings _settings = AppSettings.defaultSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize all services
    await AdsService.initialize();
    await NotificationService.initialize();
    
    // Load data from storage
    await _loadData();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    try {
      final tasks = await StorageService.loadTasks();
      final settings = await StorageService.loadSettings();
      
      setState(() {
        _tasks = tasks;
        _settings = settings;
      });

      // Reschedule notifications
      await _rescheduleNotifications();
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _rescheduleNotifications() async {
    await NotificationService.rescheduleNotifications(_tasks, _settings.notificationsEnabled);
  }

  void _showTaskModal({Task? task}) {
    showDialog(
      context: context,
      builder: (context) => TaskModal(
        task: task,
        onSave: _handleSaveTask,
      ),
    );
  }

  Future<void> _handleSaveTask(Map<String, dynamic> taskData) async {
    Navigator.of(context).pop(); // Close modal

    if (taskData.containsKey('id')) {
      // Editing existing task
      final taskId = taskData['id'] as String;
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      
      if (taskIndex != -1) {
        final updatedTask = _tasks[taskIndex].copyWith(
          title: taskData['title'],
          description: taskData['description'],
        );
        
        setState(() {
          _tasks[taskIndex] = updatedTask;
        });
      }
    } else {
      // Adding new task
      final newTask = Task(
        id: DateTime.now().toIso8601String(),
        title: taskData['title'],
        description: taskData['description'],
        completed: false,
      );
      
      setState(() {
        _tasks.add(newTask);
      });
    }

    // Save to storage
    await StorageService.saveTasks(_tasks);
  }

  Future<void> _handleDeleteTask(String taskId) async {
    setState(() {
      _tasks.removeWhere((task) => task.id == taskId);
    });
    
    await StorageService.saveTasks(_tasks);
  }

  Future<void> _handleToggleComplete(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final updatedTask = task.copyWith(completed: !task.completed);
    
    setState(() {
      _tasks[taskIndex] = updatedTask;
    });

    await StorageService.saveTasks(_tasks);
  }

  void _showSettingsModal() {
    showDialog(
      context: context,
      builder: (context) => SettingsModal(
        currentSettings: _settings,
        onSettingsChanged: _handleSettingsChange,
      ),
    );
  }

  Future<void> _handleSettingsChange(AppSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    
    await StorageService.saveSettings(_settings);
  }

  void _showAboutModal() {
    showDialog(
      context: context,
      builder: (context) => const AboutModal(),
    );
  }

  List<Task> get _incompleteTasks => _tasks.where((task) => !task.completed).toList();
  List<Task> get _completedTasks => _tasks.where((task) => task.completed).toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppHeader(
        onSettingsPressed: _showSettingsModal,
        onAboutPressed: _showAboutModal,
      ),
      body: Column(
        children: [
          Expanded(
            child: _tasks.isEmpty ? _buildEmptyState() : _buildTasksList(),
          ),
          const AdBanner(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskModal(),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to DailyList Pro!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Click the \'+\' button to add your first task.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Incomplete tasks section
          if (_incompleteTasks.isNotEmpty) ...[
            Text(
              'To-Do',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._incompleteTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskItem(
                task: task,
                onEdit: () => _showTaskModal(task: task),
                onDelete: () => _handleDeleteTask(task.id),
                onToggleComplete: () => _handleToggleComplete(task.id),
              ),
            )),
            
            if (_completedTasks.isNotEmpty) const SizedBox(height: 32),
          ],
          
          // Show message if no incomplete tasks
          if (_incompleteTasks.isEmpty && _completedTasks.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All tasks are done. Great job!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
          
          // Completed tasks section
          if (_completedTasks.isNotEmpty) ...[
            Text(
              'Completed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._completedTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskItem(
                task: task,
                onEdit: () => _showTaskModal(task: task),
                onDelete: () => _handleDeleteTask(task.id),
                onToggleComplete: () => _handleToggleComplete(task.id),
              ),
            )),
          ],
          
          // Bottom padding for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}