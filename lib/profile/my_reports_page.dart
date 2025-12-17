import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';
import '../pages/report/report_detail_page.dart';
import '../services/firestore_service.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getReportsStream(String? filterStatus,
      {bool showResolved = false}) {
    if (_userId == null) {
      return Stream.empty();
    }

    if (showResolved) {
      return _firestoreService.getMyResolvedReports(_userId!);
    } else {
      return _firestoreService.getMyActiveReports(_userId!,
          status: filterStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF2D3142),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Laporan Saya",
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF6C63FF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Hilang'),
            Tab(text: 'Ditemukan'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: _userId == null
          ? const Center(
              child: Text("Tidak dapat memuat laporan. Silakan login kembali."),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportsList(null, showResolved: false), // Aktif
                _buildReportsList('lost', showResolved: false), // Hilang aktif
                _buildReportsList('found',
                    showResolved: false), // Ditemukan aktif
                _buildReportsList(null, showResolved: true), // Selesai semua
              ],
            ),
    );
  }

  Widget _buildReportsList(String? filterStatus, {bool showResolved = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getReportsStream(filterStatus, showResolved: showResolved),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          );
        }

        if (snapshot.hasError) {
          debugPrint("Firestore Error: ${snapshot.error}");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_rounded,
                    size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  'Terjadi kesalahan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    // <-- DIUBAH: Menampilkan error yang sebenarnya
                    "Error: ${snapshot.error}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(filterStatus, showResolved);
        }

        final reports = snapshot.data!.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    '${reports.length} Laporan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (showResolved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Terselesaikan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  return _buildReportCard(reports[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportCard(ReportModel report) {
    final isLost = report.status == 'lost';
    final isResolved = report.isResolved ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isResolved
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
          width: isResolved ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailPage(reportId: report.reportId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        report.imageUrl != null && report.imageUrl!.isNotEmpty
                            ? Image.network(
                                report.imageUrl!,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholderImage(isLost),
                              )
                            : _buildPlaceholderImage(isLost),
                  ),
                  // Overlay jika resolved
                  if (isResolved)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isResolved
                                  ? Colors.grey[600]
                                  : const Color(0xFF2D3142),
                              height: 1.3,
                              decoration: isResolved
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(report.status, isResolved),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM y', 'id_ID')
                              .format(report.reportDate.toDate()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.locationName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isLost) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLost
              ? [
                  const Color(0xFFEF4444).withOpacity(0.15),
                  const Color(0xFFDC2626).withOpacity(0.15)
                ]
              : [
                  const Color(0xFF10B981).withOpacity(0.15),
                  const Color(0xFF059669).withOpacity(0.15)
                ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isLost ? Icons.search_off_rounded : Icons.check_circle_rounded,
        color: isLost ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        size: 36,
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isResolved) {
    final isLost = status == 'lost';

    if (isResolved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF10B981),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 11,
              color: Color(0xFF10B981),
            ),
            SizedBox(width: 4),
            Text(
              "Selesai",
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLost
            ? const Color(0xFFEF4444).withOpacity(0.1)
            : const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLost ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLost ? Icons.search_off_rounded : Icons.check_circle_rounded,
            size: 11,
            color: isLost ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
          const SizedBox(width: 4),
          Text(
            isLost ? "Hilang" : "Ditemukan",
            style: TextStyle(
              color: isLost ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String? filterStatus, bool showResolved) {
    String message;
    String subtitle;
    IconData icon;

    if (showResolved) {
      icon = Icons.check_circle_rounded;
      message = "Belum Ada Laporan Selesai";
      subtitle = "Laporan yang sudah diselesaikan akan muncul di sini";
    } else if (filterStatus == 'lost') {
      icon = Icons.search_off_rounded;
      message = "Belum Ada Laporan Hilang";
      subtitle = "Laporan barang hilang yang aktif akan muncul di sini";
    } else if (filterStatus == 'found') {
      icon = Icons.check_circle_rounded;
      message = "Belum Ada Laporan Ditemukan";
      subtitle = "Laporan barang ditemukan yang aktif akan muncul di sini";
    } else {
      icon = Icons.inventory_2_rounded;
      message = "Belum Ada Laporan Aktif";
      subtitle = "Mulai buat laporan untuk barang hilang atau ditemukan";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF2D3142),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
