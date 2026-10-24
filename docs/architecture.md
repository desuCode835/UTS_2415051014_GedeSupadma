# TaskMate Application Architecture

## Project Overview

TaskMate adalah aplikasi Flutter untuk membantu mahasiswa
mengelola tugas kuliah.

## Architecture Layers

- Screens: menampilkan halaman dan menerima interaksi.
- Providers: mengelola state aplikasi.
- Repositories: mengatur akses dan sumber data.
- Services: berkomunikasi dengan REST API dan Supabase.
- Models: merepresentasikan struktur data.

## Data Flow

UI -> Provider -> Repository -> Service -> API/Database

## Main Data Sources

- REST API: sumber data kutipan untuk dashboard.
- Supabase: penyimpanan data tugas kuliah.
