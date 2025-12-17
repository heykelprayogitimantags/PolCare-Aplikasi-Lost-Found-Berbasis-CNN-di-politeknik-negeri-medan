import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';
import '../models/user_model.dart';
import '../models/report_model.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReport({
    required String title,
    required String description,
    required String status, // 'lost' | 'found'
    required String locationName,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? category,
    String? brand,
    String? dominantColor,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User belum login");

      final Map<String, dynamic> reportData = {
        'title': title.trim(),
        'title_lowercase': title.trim().toLowerCase(),
        'description': description.trim(),
        'status': status.trim(),
        'locationName': locationName.trim(),
        'category': category ?? '',
        'brand': brand ?? '',
        'dominantColor': dominantColor ?? '',
        'imageUrl': imageUrl ?? '',
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userEmail': user.email ?? '',
        'userPhoto': user.photoURL ?? '',
        'reportDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'isResolved': false,
      };

      if (latitude != null && longitude != null) {
        // Nama field disamakan dengan di ReportModel
        reportData['locationGeoPoint'] = GeoPoint(latitude, longitude);
      }
    

      await _firestore.collection('reports').add(reportData);
      log("✅ Laporan berhasil ditambahkan ke Firestore (dengan lokasi)");
    } catch (e) {
      log("❌ Gagal menambahkan laporan: $e");
      rethrow;
    }
  }

  /// 🔹 Ambil stream laporan berdasarkan status ('lost' / 'found')
  /// Method ini tetap ada jika dipakai di halaman lain (spt Home)
  Stream<QuerySnapshot> getReportsByStatus(String status) {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: status)
        // Tambahkan ini jika Anda hanya ingin yang aktif di halaman Home
        .where('isResolved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 🔹 Ambil semua laporan
  /// Method ini tetap ada sebagai fallback
  Stream<QuerySnapshot> getAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  ///  Helper internal untuk menerapkan filter
  Query _applyFiltersToQuery(Query query, Map<String, dynamic>? filters) {
    if (filters == null) return query;

    if (filters['status'] != null) {
      query = query.where('status', isEqualTo: filters['status']);
    }
    if (filters['category'] != null) {
      query = query.where('category', isEqualTo: filters['category']);
    }
    // Tambahkan filter lain di sini jika ada (misal: 'brand')
    return query;
  }

  /// ⭐️ BARU: Ambil laporan berdasarkan filter saja (tanpa query teks)
  Stream<QuerySnapshot> getFilteredReports({Map<String, dynamic>? filters}) {
    // Mulai dengan query dasar (bisa diurutkan)
    Query query =
        _firestore.collection('reports').orderBy('createdAt', descending: true);

    // Terapkan filter yang ada
    return _applyFiltersToQuery(query, filters).snapshots();
  }

  /// ⭐️ UPGRADE: Cari laporan berdasarkan judul (DENGAN filter)
  Stream<QuerySnapshot> searchReports(String query,
      {Map<String, dynamic>? filters}) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      // Jika query kosong, kembalikan berdasarkan filter saja
      return getFilteredReports(filters: filters);
    }

    // ⚠️ PERINGATAN COMPOSITE INDEX:
    // Query ini menggabungkan range query ('title_lowercase')
    // dengan filter 'where' (dari _applyFiltersToQuery).
    // Ini MEMERLUKAN Composite Index di Firestore.
    //
    // Jika Anda mendapat error, BUKA LINK di log console debug Anda
    // untuk membuat index yang diperlukan secara otomatis.

    // Mulai dengan query pencarian teks
    Query dbQuery = _firestore
        .collection('reports')
        .where('title_lowercase', isGreaterThanOrEqualTo: trimmedQuery)
        .where('title_lowercase', isLessThanOrEqualTo: '$trimmedQuery\uf8ff');

    // Terapkan filter di atas query pencarian
    dbQuery = _applyFiltersToQuery(dbQuery, filters);

    // Karena kita tidak bisa orderBy('createdAt') setelah range query di field lain,
    // kita bisa orderBy('title_lowercase') untuk setidaknya memberi urutan.
    // Pengurutan berdasarkan 'createdAt' tidak diizinkan di sini oleh Firestore.
    return dbQuery.orderBy('title_lowercase').snapshots();
  }

  /// ⭐️ BARU: Ambil laporan berdasarkan daftar ID (untuk hasil AI)
  Stream<QuerySnapshot> getReportsByIds(List<String> ids) {
    if (ids.isEmpty) {
      // Kembalikan stream kosong jika tidak ada ID yang cocok
      return Stream.empty();
    }

    // ⚠️ PERINGATAN LIMITASI:
    // Query 'whereIn' Firestore dibatasi maksimal 30 item per request.
    List<String> limitedIds = ids.length > 30 ? ids.sublist(0, 30) : ids;

    if (ids.length > 30) {
      log("Peringatan: Hasil pencarian AI terpotong, hanya 30 item pertama yang diambil.");
    }

    return _firestore
        .collection('reports')
        .where(FieldPath.documentId, whereIn: limitedIds)
        .snapshots();

    // Catatan: Query 'whereIn' TIDAK menjamin urutan.
    // Urutan harus ditangani di sisi client (Flutter).
  }

  /// 🔹 Ambil satu laporan berdasarkan ID dan ubah ke ReportModel
  Future<ReportModel?> getReportById(String docId) async {
    try {
      final doc = await _firestore.collection('reports').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return ReportModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      log("❌ Gagal memuat laporan: $e");
      rethrow;
    }
  }

  /// Tandai laporan sebagai selesai/resolved
  Future<void> markReportAsResolved(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'isResolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Laporan $reportId ditandai selesai");
    } catch (e) {
      debugPrint("❌ Error marking report as resolved: $e");
      rethrow;
    }
  }

  /// Get reports untuk dashboard (hanya yang belum resolved)
  Stream<QuerySnapshot> getActiveReportsStream({String? filterStatus}) {
    // --- ⭐ INI BAGIAN YANG DIPERBAIKI ⭐ ---

    // 1. Mulai query dasar
    Query query = _firestore.collection('reports');

    // 2. Terapkan filter 'where' WAJIB
    query = query.where('isResolved', isEqualTo: false);

    // 3. Terapkan filter 'where' OPSIONAL
    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus);
    }

    // 4. Terapkan 'orderBy' di AKHIR
    // Catatan: Query ini mungkin butuh Composite Index di Firestore
    // (Anda akan melihat link error di debug console jika butuh)
    query = query.orderBy('reportDate', descending: true);

    return query.snapshots();
    // --- ⭐ BATAS PERBAIKAN ⭐ ---
  }

  /// 🔹 Hapus laporan berdasarkan ID
  Future<void> deleteReport(String docId) async {
    try {
      await _firestore.collection('reports').doc(docId).delete();
      log("🗑️ Laporan $docId berhasil dihapus");
    } catch (e) {
      log("❌ Gagal menghapus laporan: $e");
      rethrow;
    }
  }

  /// 🔹 Ambil profil user berdasarkan UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      log("❌ Gagal ambil user profile: $e");
      return null;
    }
  }

  // ⭐️ --- METHOD BARU YANG DITAMBAHKAN --- ⭐️
  /// 🔹 Update profil user (nama, no. telp, foto)
  /// Method ini dipanggil oleh EditProfilePage
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      log("✅ User profile $uid berhasil diperbarui");
    } catch (e) {
      log("❌ Gagal update user profile: $e");
      rethrow;
    }
  }
  // ⭐️ ------------------------------------- ⭐️

  /// 🔹 Update laporan (misalnya jika user ingin edit)
  Future<void> updateReport(String docId, Map<String, dynamic> data) async {
    try {
      // Buat data update terpisah untuk menambahkan 'lastUpdatedAt'
      Map<String, dynamic> updateData = {
        ...data,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      // ✅ TAMBAHAN: Jika judul diubah, update juga 'title_lowercase'
      if (data.containsKey('title')) {
        updateData['title_lowercase'] =
            data['title'].toString().trim().toLowerCase();
      }

      //
      // ⭐ --- BAGIAN LOKASI (SUDAH BENAR) --- ⭐
      //
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        // Nama field disamakan dengan di ReportModel
        updateData['locationGeoPoint'] =
            GeoPoint(data['latitude'], data['longitude']);

        // Hapus data mentah lat/long agar tidak tersimpan duplikat
        updateData.remove('latitude');
        updateData.remove('longitude');
      }
      // ⭐ --------------------------------- ⭐
      //

      await _firestore.collection('reports').doc(docId).update(updateData);
      log("✅ Laporan berhasil diperbarui");
    } catch (e) {
      log("❌ Gagal update laporan: $e");
      rethrow;
    }
  }

  // ⭐️ --- METHOD BARU UNTUK "LAPORAN SAYA" (Tambahan) --- ⭐️
  // Fungsi-fungsi ini khusus untuk halaman "Laporan Saya" yang
  // memfilter berdasarkan `userId`.

  /// 🔹 Ambil laporan SAYA (Aktif)
  /// (Untuk tab "Aktif", "Hilang", & "Ditemukan" di Laporan Saya)
  Stream<QuerySnapshot> getMyActiveReports(String userId, {String? status}) {
    // 1. Mulai query dasar
    Query query = _firestore.collection('reports');

    // 2. Filter WAJIB: Hanya milik user ini DAN yang aktif
    query = query
        .where('userId', isEqualTo: userId)
        .where('isResolved', isEqualTo: false); // <-- Hanya yang aktif

    // 3. Filter OPSIONAL: status ('lost' atau 'found')
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    // 4. Urutkan
    query = query.orderBy('createdAt', descending: true);
    return query.snapshots();

    // ⚠️ PERINGATAN: Query ini memerlukan Composite Index di Firestore.
    // Jika error, cek debug console untuk link pembuatan index otomatis.
    // Kemungkinan index yang dibutuhkan:
    // 1. (userId, isResolved, createdAt)
    // 2. (userId, isResolved, status, createdAt)
  }

  Stream<QuerySnapshot> getMyResolvedReports(String userId) {
    Query query = _firestore.collection('reports');

    query = query
        .where('userId', isEqualTo: userId)
        .where('isResolved', isEqualTo: true);

    query = query.orderBy('createdAt', descending: true);
    return query.snapshots();
  }
}
