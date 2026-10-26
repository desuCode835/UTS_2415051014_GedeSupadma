# TaskMate — Solusi Manajemen Tugas Kuliah Mahasiswa

[![Flutter](https://img.shields.io/badge/Flutter-v3.13+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Provider](https://img.shields.io/badge/State_Management-Provider_v6.1.5+-blue)](https://pub.dev/packages/provider)
[![Supabase](https://img.shields.io/badge/Backend-Supabase_v2.18+-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![UTS](https://img.shields.io/badge/UTS-Pemrograman_Berbasis_Mobile-orange)]()

**TaskMate** adalah aplikasi mobile berbasis Flutter yang dikembangkan sebagai proyek Ujian Tengah Semester (UTS) mata kuliah **Pemrograman Berbasis Mobile**. Aplikasi ini dirancang khusus untuk memfasilitasi mahasiswa dalam mencatat, mengorganisasi, memprioritaskan, mengarsipkan, serta menyelesaikan tugas-tugas perkuliahan secara terstruktur, rapi, dan efisien.

TaskMate mengintegrasikan arsitektur berlapis (*Layered Architecture*) yang bersih dengan pemisahan tanggung jawab (*Separation of Concerns*), manajemen status aplikasi menggunakan **Provider**, konsumsi kutipan inspiratif harian melalui **REST API publik**, serta persistensi data real-time berbasis *cloud* dengan **Supabase** (Database PostgREST, Anonymous Authentication, dan Cloud Storage).

---

## 👨‍🎓 Identitas Mahasiswa

| Informasi | Keterangan |
| :--- | :--- |
| **Nama Lengkap** | Gede Supadma |
| **NIM** | 2415051014 |
| **Kelas** | PTI 5A |
| **Program Studi** | Pendidikan Teknik Informatika |
| **Jurusan** | Teknik Informatika |
| **Fakultas** | Fakultas Teknik dan Kejuruan |
| **Perguruan Tinggi** | Universitas Pendidikan Ganesha (UNDIKSHA) |
| **Mata Kuliah** | Pemrograman Berbasis Mobile |
| **Repository GitHub** | [UTS_2415051014_GedeSupadma](https://github.com/desuCode835/UTS_2415051014_GedeSupadma) |

---

## ✨ Fitur Aplikasi

TaskMate dibangun dengan rangkaian fitur lengkap yang telah diuji dan diimplementasikan secara aktual:

1. **Dashboard & Statistik Tugas Interaktif**
   - Ringkasan statistik tugas aktif: Total Tugas, Tugas Selesai, Tugas Tertunda (*Pending*), dan Tugas Diarsipkan.
   - Bilah progres penyelesaian tugas (*progress bar*) dalam persentase kalkulasi otomatis.
   - Kartu kutipan inspirasi dinamis dari REST API untuk memotivasi produktivitas belajar mahasiswa.
   - Akses cepat (*shortcut*) untuk membuat tugas baru dan melihat arsip tugas.

2. **Integrasi REST API (Kutipan Motivasi Harian)**
   - Mengambil kutipan inspiratif acak dari endpoint publik secara real-time.
   - Dilengkapi *state indicator*: *loading shimmer/spinner*, kartu kutipan rapi, serta kartu penanganan error dan tombol *Retry* (*Coba Lagi*) saat perangkat offline atau mengalami kendala koneksi.

3. **Daftar Tugas & Manajemen Prioritas**
   - Menampilkan daftar tugas terstruktur dengan kartu modern (*TaskCard*).
   - Penanda prioritas visual: **Tinggi** (Merah), **Sedang** (Oranye/Kuning), dan **Rendah** (Hijau/Biru).
   - Penanda kategori mata kuliah dan tanggal tenggat waktu (*deadline*).
   - Indikator visual tugas selesai dengan coretan teks (*strikethrough*) dan perubahan gaya kartu.

4. **Pencarian Real-Time & Penyaringan (Filter)**
   - Fitur pencarian instan berdasarkan judul tugas secara live dan *case-insensitive*.
   - Filter status tugas: **Semua**, **Belum Selesai**, dan **Selesai**.
   - Filter kategori mata kuliah dinamis berdasarkan mata kuliah yang telah didaftarkan.

5. **Detail Tugas Mendalam**
   - Menampilkan informasi lengkap tugas perkuliahan: Judul, Kategori Mata Kuliah, Tingkat Prioritas, Tanggal Deadline, Status Penyelesaian, Status Arsip, dan Catatan/Deskripsi Tambahan.
   - Tombol aksi terpadu: Tandai Selesai / Batal Selesai, Edit Tugas, Arsipkan / Pulihkan Tugas, dan Hapus Tugas.

6. **Operasi CRUD Tugas (Create, Read, Update, Delete)**
   - **Tambah Tugas**: Form dengan validasi input (judul wajib diisi, validasi deadline, pilihan prioritas, dan pemilihan/input kategori mata kuliah).
   - **Edit Tugas**: Memperbarui rincian tugas yang sudah tersimpan dengan mempertahankan ID dan integritas relasi akun.
   - **Toggle Status Selesai**: Mengubah status penyelesaian tugas langsung dari kartu tugas di daftar maupun dari halaman detail tugas.
   - **Hapus Tugas**: Penghapusan tugas yang aman didahului dialog konfirmasi bertuliskan judul tugas yang akan dihapus untuk mencegah ketidaksengajaan.

7. **Fitur Pengarsipan & Pemulihan (Archive & Restore)**
   - Memindahkan tugas yang telah usai atau tidak aktif ke tab Arsip (*ArchiveScreen*) agar daftar tugas utama tetap fokus dan teratur.
   - Tugas dalam arsip dapat dipulihkan (*restore*) sewaktu-waktu ke daftar tugas utama.

8. **Manajemen Profil Mahasiswa & Foto Profil**
   - Menampilkan kartu identitas mahasiswa (Nama, NIM, Kelas, Program Studi, dan Universitas).
   - Avatar monogram berbasis inisial nama secara otomatis jika belum memiliki foto.
   - Formulir pengubahan profil mahasiswa.
   - Unggah foto profil secara langsung dari galeri perangkat ke Supabase Cloud Storage (bucket `avatars`).

9. **Desain Responsif & Adaptif**
   - Penyesuaian tata letak otomatis (*Breakpoints*):
     - Mode ponsel (*Compact*, lebar < 600px): Tata letak vertikal 1 kolom ramah jemari.
     - Mode tablet / layar lebar (lebar >= 600px): Tata letak grid multi-kolom yang luas dan proporsional.
   - Seluruh komponen teruji bebas dari visual overflow pada resolusi 320px hingga 1000px+.

10. **Umpan Balik Pengguna & Penanganan Status Komprehensif**
    - Status *Loading* yang halus pada setiap proses asinkron.
    - *Empty State* yang informatif dan ramah ketika data tugas kosong, hasil pencarian tidak ditemukan, atau arsip kosong.
    - Notifikasi *Floating SnackBar* yang hanya mengonfirmasi keberhasilan jika operasi database/jaringan benar-benar sukses.
    - Penanganan kegagalan yang aman tanpa menyembunyikan galat (*rethrow/error logging* terukur).

---

## 🛠️ Teknologi yang Digunakan

Aplikasi TaskMate dibangun menggunakan ekosistem teknologi terkini:

- **Framework**: [Flutter](https://flutter.dev/) (SDK `>=3.13.0`)
- **Bahasa Pemrograman**: [Dart](https://dart.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider) (`^6.1.5+1`) dengan pola `ChangeNotifier` & `MultiProvider`
- **HTTP Client**: [http](https://pub.dev/packages/http) (`^1.6.0`) untuk komunikasi REST API
- **Backend & Cloud Platform**: [supabase_flutter](https://pub.dev/packages/supabase_flutter) (`^2.18.3`)
  - **Database**: PostgreSQL dengan PostgREST API
  - **Autentikasi**: Supabase Anonymous Authentication (`signInAnonymously`)
  - **Storage**: Supabase Cloud Storage (Bucket `avatars`)
  - **Keamanan**: Row Level Security (RLS) terisolasi per akun
- **Environment Manager**: [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) (`^6.0.1`) untuk pembacaan konfigurasi `.env`
- **Media Selector**: [image_picker](https://pub.dev/packages/image_picker) (`^1.2.4`) untuk pemilihan berkas foto profil
- **Ikonografi & Gaya**: Material Design 3 dengan palet warna bernuansa Slate & Indigo yang modern

---

## 🌐 Integrasi REST API

TaskMate memanfaatkan REST API publik untuk menampilkan kutipan motivasi yang berubah-ubah secara dinamis pada dashboard:

| Properti | Keterangan |
| :--- | :--- |
| **Endpoint URL** | `https://dummyjson.com/quotes/random` |
| **Metode HTTP** | `GET` |
| **Headers** | `Accept: application/json` |
| **Batas Waktu (Timeout)** | 10 Detik |
| **Format Respons** | JSON Object (`{ "id": 1, "quote": "...", "author": "..." }`) |
| **Model Dart** | `lib/models/quote.dart` |
| **Service Layer** | `lib/services/api_service.dart` (`ApiService.getRandomQuote`) |
| **Repository Layer** | `lib/repositories/quote_repository.dart` (`QuoteRepository.getRandomQuote`) |
| **State Provider** | `lib/providers/quote_provider.dart` (`QuoteProvider.fetchQuote`) |

### Penanganan Error REST API
- `SocketException`: Ditangkap dan disajikan dengan pesan informatif mengenai kendala konektivitas internet.
- `TimeoutException`: Ditangkap jika permintaan melebihi batas 10 detik.
- `HttpException`: Ditangkap jika status kode HTTP bukan 200 OK.
- `FormatException`: Ditangkap jika JSON kosong atau tidak sesuai struktur data model.
- Pada antarmuka pengguna (`HomeScreen`), kegagalan akan memunculkan kartu peringatan elegan disertai tombol **Coba Lagi** (*Retry*) tanpa memblokir fungsi aplikasi lainnya.

---

## 🗄️ Database dan Supabase

Penyimpanan persisten data tugas dan profil pengguna menggunakan platform BaaS **Supabase**.

### 1. Struktur Tabel `tasks`

| Kolom | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, default `gen_random_uuid()` |
| `user_id` | `uuid` | Relasi ke ID pengguna Supabase (`auth.users.id`), mematuhi isolasi data RLS |
| `title` | `text` | Judul tugas kuliah (wajib diisi) |
| `description` | `text` | Rincian atau catatan tugas (opsional) |
| `course_category` | `text` | Kategori atau nama mata kuliah (opsional) |
| `deadline` | `text` / `timestamptz` | Tanggal dan waktu batas pengumpulan |
| `priority` | `text` | Tingkat prioritas tugas (`Tinggi`, `Sedang`, `Rendah`) |
| `is_completed` | `boolean` | Status penyelesaian tugas (default: `false`) |
| `is_archived` | `boolean` | Status pengarsipan tugas (default: `false`) |
| `created_at` | `timestamptz` | Waktu pencatatan data tugas |

### 2. Struktur Tabel `profiles`

| Kolom | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, terikat langsung dengan `auth.users.id` |
| `name` | `text` | Nama lengkap mahasiswa |
| `student_id` | `text` | Nomor Induk Mahasiswa (NIM) |
| `class_name` | `text` | Kelas perkuliahan (misal: `PTI 5A`) |
| `study_program` | `text` | Program studi mahasiswa |
| `university` | `text` | Nama universitas |
| `photo_url` | `text` | Tautan publik foto profil dari Supabase Storage |
| `updated_at` | `timestamptz` | Waktu pembaruan profil terakhir |

### 3. Supabase Cloud Storage
- **Bucket**: `avatars`
- **Fungsi**: Menyimpan berkas gambar avatar profil pengguna yang diunggah melalui `image_picker`.
- **Lokasi Path**: `{userId}/avatar_{timestamp}.{ext}`
- **Akses**: URL publik dihasilkan via `client.storage.from('avatars').getPublicUrl(storagePath)`.

### 4. Autentikasi & Row Level Security (RLS)
- Aplikasi mengimplementasikan **Supabase Anonymous Authentication** (`client.auth.signInAnonymously()`) yang diinisialisasi secara otomatis saat aplikasi dimulai.
- Hal ini memungkinkan aplikasi langsung siap digunakan tanpa mengharuskan pengguna melewati form login manual, sembari tetap memastikan setiap pengguna memiliki *Session* dan `user_id` yang valid untuk mematuhi kebijakan **Row Level Security (RLS)** pada tabel `tasks` dan `profiles`.

> **Catatan Batas Verifikasi**: Struktur tabel, tipe kolom, dan relasi di atas diverifikasi melalui implementasi model serialisasi (`Task.fromJson`, `UserProfile.fromJson`), mapper Supabase (`toSupabaseMap`), serta query PostgREST pada `lib/services/supabase_service.dart`. Akses langsung ke dashboard administrasi Supabase merupakan batas lingkungan eksternal.

---

## 🏛️ Arsitektur Proyek

TaskMate mengadopsi prinsip arsitektur perangkat lunak yang bersih (*Clean Layered Architecture*), di mana setiap lapisan memiliki tanggung jawab tunggal (*Single Responsibility Principle*):

```text
UI (Screens & Widgets) ➔ State Management (Providers) ➔ Repositories ➔ Services / Data Sources ➔ Supabase DB & REST API
```

### Penjelasan Tanggung Jawab Lapisan:
1. **`lib/screens/` & `lib/widgets/` (UI Layer)**:
   - Menampilkan antarmuka Material 3, mengumpulkan input formulir, merespons interaksi tombol, serta menampilkan dialog konfirmasi dan notifikasi SnackBar.
   - **Aturan Ketat**: Tidak boleh ada pemanggilan HTTP (`http.get`) maupun query database Supabase secara langsung di dalam screen.
2. **`lib/providers/` (State Management Layer)**:
   - Menggunakan `ChangeNotifier` (`TaskProvider`, `QuoteProvider`, `ProfileProvider`).
   - Menyimpan status data aktif, status pemuatan (`isLoading`), dan pesan kesalahan (`errorMessage`).
   - Memberitahu widget yang mendengarkan melalui `notifyListeners()`.
3. **`lib/repositories/` (Repository Layer)**:
   - Mengabstraksikan sumber data untuk provider (`TaskRepository`, `ProfileRepository`, `QuoteRepository`).
   - Menyediakan mekanisme *fallback* data lokal (*sample tasks* / *in-memory model*) jika Supabase belum diinisialisasi atau saat pengujian berjalan offline.
4. **`lib/services/` (Data Source / Service Layer)**:
   - Menangani komunikasi teknis tingkat rendah dengan infrastruktur luar (`ApiService` untuk endpoint REST HTTP, dan `SupabaseService` untuk koneksi PostgREST, Auth, dan Storage).
5. **`lib/models/` (Domain Model Layer)**:
   - Merepresentasikan entitas data (`Task`, `Quote`, `UserProfile`) lengkap dengan method factory `fromJson`, `toJson`, `toSupabaseMap`, dan `copyWith`.
6. **`lib/config/`**:
   - Berisi kelas utilitas pembaca konfigurasi terpusat (`SupabaseConfig`) yang memuat data aman dari file `.env`.

---

## 📂 Struktur Folder Proyek

Berikut adalah struktur berkas dan direktori aktual dari proyek TaskMate:

```text
uts_2415051014_gedesupadma/
├── .env.example                     # Berkas template konfigurasi environment
├── .gitignore                       # Aturan pengabaian berkas sensitif dan build Git
├── analysis_options.yaml            # Konfigurasi linter Dart & Flutter
├── pubspec.yaml                     # Manifest dependensi dan aset aplikasi
├── README.md                        # Dokumentasi komprehensif proyek
├── android/                         # Konfigurasi platform Android & Gradle
│   ├── app/
│   │   ├── build.gradle.kts         # Skrip build modul aplikasi Android
│   │   └── src/main/
│   │       └── AndroidManifest.xml  # Manifest Android (termasuk izin INTERNET)
│   └── build.gradle.kts
├── docs/                            # Aset dokumentasi dan arsitektur
│   ├── Logo_Application/            # Berkas logo aplikasi TaskMate
│   │   └── Logo.png
│   └── architecture.md              # Ringkasan arsitektur proyek
├── lib/                             # Kode sumber utama aplikasi Flutter
│   ├── main.dart                    # Titik masuk utama aplikasi (main entrypoint)
│   ├── config/                      # Konfigurasi global
│   │   └── supabase_config.dart     # Pembaca variabel konfigurasi Supabase
│   ├── data/                        # Data awal / mock offline
│   │   └── sample_tasks.dart        # Kumpulan data tugas contoh
│   ├── models/                      # Entitas model data
│   │   ├── quote.dart               # Model kutipan REST API
│   │   ├── task.dart                # Model tugas kuliah
│   │   └── user_profile.dart        # Model profil pengguna/mahasiswa
│   ├── providers/                   # State management (ChangeNotifier)
│   │   ├── profile_provider.dart    # Pengelola status profil
│   │   ├── quote_provider.dart      # Pengelola status kutipan API
│   │   └── task_provider.dart       # Pengelola status tugas kuliah
│   ├── repositories/                # Abstraksi akses data
│   │   ├── profile_repository.dart  # Repositori data profil
│   │   ├── quote_repository.dart    # Repositori kutipan motivasi
│   │   └── task_repository.dart     # Repositori data tugas
│   ├── screens/                     # Halaman antarmuka aplikasi
│   │   ├── add_task_screen.dart     # Layar tambah tugas baru
│   │   ├── archive_screen.dart      # Layar daftar tugas yang diarsipkan
│   │   ├── edit_profile_screen.dart # Layar sunting profil pengguna
│   │   ├── edit_task_screen.dart    # Layar sunting tugas
│   │   ├── home_screen.dart         # Layar beranda (dashboard & statistik)
│   │   ├── main_navigation_screen.dart # Layar navigasi utama (NavigationBar)
│   │   ├── profile_screen.dart      # Layar profil pengguna
│   │   ├── task_detail_screen.dart  # Layar detail tugas
│   │   └── task_list_screen.dart    # Layar daftar semua tugas & filter
│   ├── services/                    # Komunikasi jaringan & backend
│   │   ├── api_service.dart         # Layanan client HTTP REST API
│   │   └── supabase_service.dart    # Layanan Supabase (PostgREST, Auth, Storage)
│   └── widgets/                     # Komponen UI modular & reusable
│       ├── empty_state.dart         # Widget tampilan data kosong
│       ├── summary_card.dart        # Widget kartu ringkasan metrik dashboard
│       └── task_card.dart           # Widget kartu item tugas
└── test/                            # Rangkaian pengujian otomatis (Unit, Widget, UI)
    ├── archive_feature_test.dart
    ├── course_category_feature_test.dart
    ├── edit_task_and_profile_test.dart
    ├── error_handling_test.dart
    ├── models_test.dart
    ├── navigation_flow_test.dart
    ├── quote_test.dart
    ├── responsive_layout_test.dart
    ├── supabase_integration_test.dart
    ├── task_deletion_test.dart
    ├── task_management_interactions_test.dart
    ├── task_provider_test.dart
    └── widget_test.dart
```

---

## 🚀 Prasyarat dan Cara Menjalankan

### Prasyarat Perangkat Lunak
- **Flutter SDK**: Versi `3.13.0` atau yang lebih baru ([Panduan Instalasi Flutter](https://docs.flutter.dev/get-started/install)).
- **Dart SDK**: Versi `3.0.0` atau yang lebih baru (termasuk di dalam instalasi Flutter).
- **Android Studio** atau **VS Code** dengan ekstensi Flutter & Dart.
- **Git**: Untuk pengelolaan kode sumber.

### Langkah-Langkah Menjalankan Aplikasi

1. **Klon Repository**
   Buka terminal atau PowerShell, lalu klon repository proyek:
   ```powershell
   git clone https://github.com/desuCode835/UTS_2415051014_GedeSupadma.git
   cd UTS_2415051014_GedeSupadma
   ```

2. **Unduh Dependensi**
   Jalankan perintah berikut untuk mengunduh seluruh paket yang dibutuhkan:
   ```powershell
   flutter pub get
   ```

3. **Konfigurasi Environment (`.env`)**
   Salin berkas template `.env.example` menjadi `.env` pada *root* proyek:
   ```powershell
   Copy-Item .env.example .env
   ```
   Buka berkas `.env` yang baru dibuat dan isi kredensial Supabase Anda:
   ```env
   # Konfigurasi Supabase TaskMate
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-supabase-publishable-key-here
   ```
   > **Catatan**: Aplikasi mendukung pembacaan `SUPABASE_ANON_KEY` maupun `SUPABASE_PUBLISHABLE_KEY`. Jika file `.env` tidak disediakan atau Supabase belum dikonfigurasi, aplikasi tetap dapat berjalan menggunakan data lokal cadangan (*offline fallback*).

4. **Jalankan Aplikasi**
   Pastikan emulator Android aktif atau perangkat fisik terhubung dengan mode USB Debugging, lalu jalankan:
   ```powershell
   flutter run
   ```

---

## 🧪 Pengujian Otomatis

Aplikasi TaskMate dilengkapi dengan pengujian otomatis (*automated testing*) yang menyeluruh untuk menjamin stabilitas kode, kebenaran fungsional, dan integritas arsitektur.

### 1. Analisis Statis Kode (Linter)
Perintah untuk memeriksa standar penulisan kode dan ketiadaan error statis:
```powershell
flutter analyze
```
**Hasil Aktual**:
```text
Analyzing uts_2415051014_gedesupadma...
No issues found!
```
*(Lulus 100% tanpa error, warning, maupun masalah linter)*.

### 2. Pengujian Unit, Widget, dan Integrasi
Perintah untuk menjalankan seluruh rangkaian tes:
```powershell
flutter test
```
**Hasil Aktual**:
```text
00:15 +188: All tests passed!
```
**Total Test**: **188 pengujian** pada 13 berkas pengujian lulus seluruhnya tanpa ada test yang di-skip atau dilemahkan.

### Cakupan Pengujian:
- **Pengujian Model & Serialisasi**: Validasi parser JSON, deserialisasi, fallback nilai default, dan mapper Supabase.
- **Pengujian Repositori & Provider**: Pengujian aliran state, isolasi penanganan error, dan sinkronisasi status data.
- **Pengujian UI & Widget**: Pengujian interaksi formulir, validasi input, konfirmasi dialog penghapusan, dan umpan balik SnackBar.
- **Pengujian Alur Navigasi**: Perpindahan tab pada `NavigationBar` dan konsistensi state.
- **Pengujian Ketahanan Galat (*Error Handling*)**: Simulasi kegagalan koneksi REST API dan penolakan database.
- **Pengujian Tata Letak Responsif**: Audit ketiadaan visual overflow pada berbagai rentang lebar layar (320px, 390px, 700px, 1000px).

---

## 🔐 Keamanan dan Praktik Baik

Keamanan data menjadi prioritas penting dalam pengembangan TaskMate:
1. **Tidak Ada Kredensial Sensitif di Git**:
   - Berkas `.env` telah didaftarkan di dalam `.gitignore` sehingga kunci API rahasia atau nilai konfigurasi lokal tidak akan terunggah ke repositori publik GitHub.
   - Proyek hanya melacak `.env.example` sebagai referensi struktur konfigurasi yang aman.
2. **Kunci Klien vs Kunci Layanan**:
   - Aplikasi **hanya** menggunakan Supabase `anonKey` (kunci publik klien) yang dibatasi oleh kebijakan Row Level Security (RLS).
   - Kunci sensitif seperti Supabase `service_role` key **tidak pernah** dimasukkan ke dalam kode sumber aplikasi, aset, maupun dokumentasi.
3. **Isolasi Data Pengguna (RLS)**:
   - Setiap operasi penulisan, pembaruan, dan penghapusan data tugas mengikat `user_id` dari sesi autentikasi aktif pengguna guna mencegah manipulasi data lintas pengguna.

---

## 📦 Pembuatan APK Rilis

Untuk menghasilkan paket instalasi mandiri Android (*Release APK*):
```powershell
flutter build apk --release
```
Hasil kompilasi APK rilis akan berada pada direktori:
`build/app/outputs/flutter-apk/app-release.apk`

---

*TaskMate — Dibuat dengan bangga oleh Gede Supadma (2415051014) untuk UTS Pemrograman Berbasis Mobile PTI 5A.*
