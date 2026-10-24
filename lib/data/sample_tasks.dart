import '../models/task.dart';

final List<TaskItem> sampleTasks = [
  const TaskItem(
    id: 'task-1',
    title: 'Implementasi Arsitektur & UI TaskMate',
    course: 'Pemrograman Berbasis Mobile',
    deadline: '28 Okt 2026, 23:59 WITA',
    priority: 'Tinggi',
    status: 'Belum Selesai',
    description:
        'Menyelesaikan struktur folder arsitektur aplikasi TaskMate dan membangun antarmuka 6 screen awal '
        'menggunakan Flutter Material Design sesuai dengan pedoman pengerjaan UTS Pemrograman Mobile.',
  ),
  const TaskItem(
    id: 'task-2',
    title: 'Makalah Etika Profesi Teknologi Informasi',
    course: 'Etika Profesi TI',
    deadline: '30 Okt 2026, 17:00 WITA',
    priority: 'Sedang',
    status: 'Belum Selesai',
    description:
        'Menyusun pembahasan kode etik pengembang perangkat lunak, hak cipta digital, dan studi kasus profesionalisme TI.',
  ),
  const TaskItem(
    id: 'task-3',
    title: 'Proyek Akhir Kecerdasan Buatan',
    course: 'Kecerdasan Buatan',
    deadline: '5 Nov 2026, 23:59 WITA',
    priority: 'Tinggi',
    status: 'Belum Selesai',
    description:
        'Membuat model klasifikasi machine learning dengan dataset evaluasi performa dan visualisasi akurasi.',
  ),
  const TaskItem(
    id: 'task-4',
    title: 'Review Jurnal Rekayasa Perangkat Lunak',
    course: 'Rekayasa Perangkat Lunak',
    deadline: '25 Okt 2026, 20:00 WITA',
    priority: 'Rendah',
    status: 'Selesai',
    description:
        'Analisis metodologi Agile dalam pengembangan sistem mobile modern dan perbandingan siklus Scrum vs Kanban.',
  ),
  const TaskItem(
    id: 'task-5',
    title: 'Desain Wireframe Sistem Informasi Akademik',
    course: 'Interaksi Manusia dan Komputer',
    deadline: '24 Okt 2026, 15:00 WITA',
    priority: 'Sedang',
    status: 'Selesai',
    description:
        'Membuat prototipe tampilan antarmuka berpusat pada pengalaman pengguna (UX) dan pengujian heuristik.',
  ),
];
