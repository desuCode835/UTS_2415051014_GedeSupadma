import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'home_screen.dart';
import 'task_list_screen.dart';
import 'profile_screen.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _navigateToTasks() {
    setState(() {
      _currentIndex = 1;
    });
  }

  Future<void> _handleAddTask() async {
    final Task? newTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );

    if (newTask != null && mounted) {
      final taskProvider = context.read<TaskProvider>();
      if (!taskProvider.tasks.any((t) => t.id == newTask.id)) {
        taskProvider.addTask(newTask);
      }
      setState(() {
        _currentIndex = 1;
      });
    }
  }

  Future<void> _handleTaskTap(Task task) async {
    final Task? updatedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          task: task,
          onTaskUpdated: _handleUpdateTask,
        ),
      ),
    );

    if (updatedTask != null && mounted) {
      _handleUpdateTask(updatedTask);
    }
  }

  void _handleUpdateTask(Task updatedTask) {
    context.read<TaskProvider>().updateTask(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            tasks: taskProvider.tasks,
            onNavigateToTasks: _navigateToTasks,
            onAddTask: _handleAddTask,
            onTaskTap: _handleTaskTap,
          ),
          TaskListScreen(
            tasks: taskProvider.tasks,
            isLoading: taskProvider.isLoading,
            errorMessage: taskProvider.errorMessage,
            onRetry: () => context.read<TaskProvider>().loadTasks(),
            onTaskTap: _handleTaskTap,
            onAddTask: _handleAddTask,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEFF6FF),
        elevation: 3,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF2563EB)),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded, color: Color(0xFF2563EB)),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF2563EB)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
