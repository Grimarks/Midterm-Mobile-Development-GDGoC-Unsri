# 📱MIDTERM MOBILE DEVELOPMENT

Repositori ini digunakan untuk **pengumpulan tugas Midterm Mobile Development**.

## Sistem Pengumpulan

- **Metode pengumpulan**: lakukan **fork** repository ini, lalu kerjakan tugas pada repository hasil fork.
- **Deadline**: **28 Juni 2026, 23.59 WIB**
- **Tema aplikasi**: bebas
- **Ketentuan utama**:
  - Wajib menggunakan **Flutter**
  - Wajib memiliki **backend**
  - Proyek harus berupa **aplikasi fullstack mobile development**
  - Tidak cukup hanya membuat UI Flutter
  - Repository hasil fork wajib memiliki **README baru** yang menjelaskan proyek masing-masing
  - README proyek harus berisi cara menjalankan aplikasi, versi dan dependensi yang dipakai, fitur yang tersedia, dan informasi backend yang digunakan
  - Hasil akhir harus menyertakan **build installer Android ataupun iOS** tergantung device yang dipakai

---

## Ketentuan Penilaian

Penilaian dilakukan secara **Norm-Referenced Grading**, sehingga nilai setiap peserta bergantung pada kualitas proyek dibandingkan peserta lain. Meski begitu, penilaian tetap mengikuti guideline umum berikut.

### 1. Arsitektur & Manajemen State (Flutter)
Menilai kerapian struktur kode dan pengelolaan state aplikasi.

**Biasa saja**
- Semua kode UI, logika bisnis, dan API menumpuk di satu file atau widget
- Menggunakan `setState` untuk semua hal
- Struktur folder tidak jelas

**Bagus**
- Struktur folder rapi
- Menggunakan state management seperti Provider, Bloc, atau Riverpod
- Logic dan UI dipisahkan

**Sangat bagus**
- Menerapkan Clean Architecture
- Kode modular dan mengikuti prinsip SOLID
- State management efisien dan minim re-render tidak perlu

### 2. Integrasi Backend & API (Networking)
Menilai bagaimana aplikasi berkomunikasi dengan server.

**Biasa saja**
- Memanggil API langsung di widget tanpa error handling
- Aplikasi mudah crash atau blank saat server bermasalah
- Kredensial API ditulis hardcoded

**Bagus**
- Menggunakan Dio atau library serupa
- Ada error handling dasar
- Konfigurasi backend disimpan di file `.env`

**Sangat bagus**
- Error handling matang
- Ada custom error page atau snackbar informatif
- Mendukung caching saat offline
- Token JWT dapat diperbarui otomatis melalui interceptor

### 3. Manajemen Autentikasi & Data Pengguna
Menilai proses login, register, dan penyimpanan sesi pengguna.

**Biasa saja**
- Login hanya mencocokkan teks
- Pengguna harus login ulang setelah aplikasi ditutup

**Bagus**
- Menggunakan JWT atau Firebase Authentication
- Token disimpan aman di Flutter Secure Storage
- Auto-login jika token masih valid

**Sangat bagus**
- Alur autentikasi sangat mulus
- Mendukung Biometric Auth seperti Fingerprint atau Face ID
- Token kedaluwarsa ditangani otomatis
- Logout membersihkan data lokal dengan rapi

### 4. Desain UI/UX & Performa
Menilai kenyamanan dan performa aplikasi.

**Biasa saja**
- Tampilan standar tanpa kustomisasi
- Tidak responsif di berbagai ukuran layar
- Performa terasa lambat saat memuat data atau gambar

**Bagus**
- Desain menarik dan konsisten
- Responsif di berbagai ukuran layar
- Ada loading indicator atau shimmer saat data sedang dimuat

**Sangat bagus**
- Ada animasi halus atau micro-interactions
- Mendukung Dark Mode dan Light Mode
- Performa optimal dan efisien

### 5. Dokumentasi & Repositori GitHub
Menilai kesiapan repository untuk diperiksa dan dijalankan.

**Biasa saja**
- Repository berantakan
- Tidak memakai `.gitignore`
- README kosong atau hanya isi default Flutter

**Bagus**
- `.gitignore` bersih
- README menjelaskan nama proyek, fitur utama, dan cara menjalankan aplikasi
- Endpoint backend dicantumkan

**Sangat bagus**
- README sangat lengkap
- Ada diagram arsitektur
- Ada dokumentasi API seperti Postman atau Swagger
- Ada screenshot atau GIF aplikasi
- Riwayat commit rapi menggunakan Conventional Commits

---

## Yang Harus Ada di Repository Hasil Fork

Repository hasil fork minimal harus memuat:
- Source code aplikasi Flutter
- Source code backend jika menggunakan backend tradisional
- README baru yang menjelaskan proyek
- Instruksi instalasi dan cara menjalankan
- Daftar fitur aplikasi
- Informasi endpoint API atau dokumentasi backend
- Build installer untuk Android dan iOS

---

## Ringkasan Ketentuan

Singkatnya, proyek midterm ini harus berupa:
- **Aplikasi mobile Flutter**
- **Memiliki backend**
- **Dikerjakan dengan baik dan terdokumentasi**
- **Dikumpulkan melalui fork repository**
- **Selesai sebelum 28 Juni 2026, 23.59 WIB**

---

## Catatan

Tema aplikasi bebas, tetapi kualitas implementasi, kerapian kode, integrasi backend, pengalaman pengguna, dan dokumentasi repository akan sangat memengaruhi hasil penilaian.

Happy Coding Folks! 