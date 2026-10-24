import 'package:flutter/material.dart';
import '../models/task.dart';
import '../data/sample_tasks.dart';
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
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tasks = List.from(sampleTasks);
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
      setState(() {
        _tasks.insert(0, newTask);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tugas "${newTask.title}" berhasil ditambahkan!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            tasks: _tasks,
            onNavigateToTasks: _navigateToTasks,
            onAddTask: _handleAddTask,
            onTaskTap: _handleTaskTap,
          ),
          TaskListScreen(
            tasks: _tasks,
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
