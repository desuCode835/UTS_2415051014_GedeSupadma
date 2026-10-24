import '../models/task.dart';

final List<Task> sampleTasks = [
  const Task(
    id: 'task-1',
    title: 'Implementasi Arsitektur & UI TaskMate',
    description:
        'Menyelesaikan struktur folder arsitektur aplikasi TaskMate dan membangun antarmuka 6 screen awal '
        'menggunakan Flutter Material Design sesuai dengan pedoman pengerjaan UTS Pemrograman Mobile.',
    deadline: '28 Okt 2026, 23:59 WITA',
    priority: 'Tinggi',
    isCompleted: false,
  ),
  const Task(
    id: 'task-2',
    title: 'Makalah Etika Profesi Teknologi Informasi',
    description:
        'Menyusun pembahasan kode etik pengembang perangkat lunak, hak cipta digital, dan studi kasus profesionalisme TI.',
    deadline: '30 Okt 2026, 17:00 WITA',
    priority: 'Sedang',
    isCompleted: false,
  ),
  const Task(
    id: 'task-3',
    title: 'Proyek Akhir Kecerdasan Buatan',
    description:
        'Membuat model klasifikasi machine learning dengan dataset evaluasi performa dan visualisasi akurasi.',
    deadline: '5 Nov 2026, 23:59 WITA',
    priority: 'Tinggi',
    isCompleted: false,
  ),
  const Task(
    id: 'task-4',
    title: 'Review Jurnal Rekayasa Perangkat Lunak',
    description:
        'Analisis metodologi Agile dalam pengembangan sistem mobile modern dan perbandingan siklus Scrum vs Kanban.',
    deadline: '25 Okt 2026, 20:00 WITA',
    priority: 'Rendah',
    isCompleted: true,
  ),
  const Task(
    id: 'task-5',
    title: 'Desain Wireframe Sistem Informasi Akademik',
    description:
        'Membuat prototipe tampilan antarmuka berpusat pada pengalaman pengguna (UX) dan pengujian heuristik.',
    deadline: '24 Okt 2026, 15:00 WITA',
    priority: 'Sedang',
    isCompleted: true,
  ),
];
