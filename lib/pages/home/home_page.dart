import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Ini import yang BENAR
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../profile/profile_page.dart';
import '../../services/firestore_service.dart';
import '../report/create_report_page.dart';
import '../report/report_detail_page.dart';
import '../search/search_page.dart';
import '../auth/login.dart';

// ======================================================
// HOMEPAGE (NAVIGASI UTAMA)
// ======================================================
// (Tidak ada perubahan di sini, ini sudah benar)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    DashboardPage(),
    SearchPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Cari',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// DASHBOARD PAGE
// ======================================================
// (Perubahan ada di dalam class ini)
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _userProfile;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  /// 🔍 Cek apakah user adalah tamu atau sudah login
  Future<void> _checkUserStatus() async {
    // (Kode ini sudah benar, tidak diubah)
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _isGuest = true;
      });
      return;
    }
    if (user.isAnonymous) {
      setState(() {
        _isGuest = true;
      });
      return;
    }
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    // (Kode ini sudah benar, tidak diubah)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final userProfile = await _firestoreService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _isGuest = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil data user: $e");
    }
  }

  //
  // ⭐️ --- 1. FUNGSI QUERY BARU DITAMBAHKAN DI SINI --- ⭐️
  //
  /// Get reports untuk dashboard (hanya yang belum resolved/selesai)
  Stream<QuerySnapshot> _getActiveReportsStream(String status) {
    Query query = FirebaseFirestore.instance
        .collection('reports')
        .where('isResolved', isEqualTo: false) // ⭐ FILTER: Hanya yang belum selesai
        .where('status', isEqualTo: status);  // ⭐ FILTER: Berdasarkan status (lost/found)

    // Urutkan berdasarkan tanggal laporan
    // ⚠️ PERINGATAN: Ini 100% butuh Composite Index di Firestore
    return query.orderBy('reportDate', descending: true).snapshots();
  }
  // ⭐️ ------------------------------------------------ ⭐️
  //

  @override
  Widget build(BuildContext context) {
    // (Kode ini sudah benar, tidak diubah)
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildModernHeader(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildActionCards(context),
                const SizedBox(height: 32),
                _buildSection(
                    "Baru Ditemukan", "found", Icons.check_circle_rounded),
                const SizedBox(height: 32),
                _buildSection("Baru Hilang", "lost", Icons.error_rounded),
                const SizedBox(height: 24),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    // (Kode ini sudah benar, tidak diubah)
    String displayName = "Tamu";

    if (!_isGuest) {
      displayName = _userProfile?.name ??
          FirebaseAuth.instance.currentUser?.displayName ??
          "Pengguna";
    }

    return SliverAppBar(
      backgroundColor: Colors.white,
      pinned: true,
      floating: true,
      elevation: 0,
      expandedHeight: 140.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF6C63FF).withOpacity(0.03),
              ],
            ),
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _isGuest
                    ? Colors.grey.withOpacity(0.2)
                    : const Color(0xFF6C63FF).withOpacity(0.1),
                backgroundImage: (!_isGuest &&
                        _userProfile?.photoUrl != null &&
                        _userProfile!.photoUrl!.isNotEmpty)
                    ? NetworkImage(_userProfile!.photoUrl!)
                    : null,
                child: (_isGuest ||
                        _userProfile?.photoUrl == null ||
                        _userProfile!.photoUrl!.isEmpty)
                    ? Icon(
                        _isGuest ? Icons.person_outline : Icons.person,
                        color: _isGuest ? Colors.grey : const Color(0xFF6C63FF),
                        size: 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isGuest
                        ? "Halo, Tamu 👋"
                        : "Halo, ${displayName.split(' ')[0]} 👋",
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isGuest
                        ? "Login untuk lapor kehilangan"
                        : "Semoga harimu menyenangkan!",
                    style: TextStyle(
                      fontSize: 12,
                      color: _isGuest ? Colors.orange : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 24),
            color: const Color(0xFF6B7280),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context) {
    // (Kode ini sudah benar, tidak diubah)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _ModernActionCard(
              title: "Lapor Kehilangan",
              subtitle: "Barang hilang?",
              icon: Icons.search_off_rounded,
              gradientColors: const [Color(0xFF6C63FF), Color(0xFF5A52D5)],
              onTap: () => _handleReportAction(context, 'lost'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ModernActionCard(
              title: "Lapor Ditemukan",
              subtitle: "Temukan barang?",
              icon: Icons.verified_rounded,
              gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
              onTap: () => _handleReportAction(context, 'found'),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔐 Handle aksi lapor (cek apakah user tamu atau tidak)
  void _handleReportAction(BuildContext context, String status) {
    // (Kode ini sudah benar, tidak diubah)
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous || _isGuest) {
      _showLoginRequiredDialog(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReportPage(status: status),
      ),
    );
  }

  /// 🔒 Dialog muncul jika user belum login atau masih tamu
  void _showLoginRequiredDialog(BuildContext context) {
    // (Kode ini sudah benar, tidak diubah)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF6C63FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Login Diperlukan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          "Untuk melaporkan barang hilang atau ditemukan, kamu perlu login atau membuat akun terlebih dahulu.",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
            ),
            child: const Text(
              "Batal",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text(
              "Login Sekarang",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String status, IconData icon) {
    // (Kode ini sudah benar, tidak diubah)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: status == 'found'
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: status == 'found'
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchPage(initialFilter: status),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6C63FF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Row(
                  children: [
                    Text(
                      "Lihat semua",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildReportsList(status), // ⭐️ Perubahan akan terjadi di sini
      ],
    );
  }

  Widget _buildReportsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      //
      // ⭐️ --- 2. BAGIAN INI DIUBAH --- ⭐️
      //
      // stream: _firestoreService.getReportsByStatus(status), // <-- KODE LAMA
      stream: _getActiveReportsStream(status), // <-- KODE BARU
      //
      // ⭐️ ------------------------- ⭐️
      //
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 240,
            child: Center(
                child: CircularProgressIndicator(
              color: Color(0xFF6C63FF),
            )),
          );
        }

        if (snapshot.hasError) {
          // ⭐️ PESAN ERROR LEBIH JELAS UNTUK INDEX ⭐️
          debugPrint("Firestore Error: ${snapshot.error}");
          return SizedBox(
            height: 240,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Terjadi kesalahan. Anda mungkin perlu membuat Index di Firestore.\nCek Debug Console untuk link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _ModernEmptyState(
            icon: status == 'found'
                ? Icons.search_off_rounded
                : Icons.inventory_2_outlined,
            message:
                "Belum ada laporan ${status == 'found' ? 'ditemukan' : 'kehilangan'} yang aktif",
          );
        }

        final reports = snapshot.data!.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList();

        return SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _ModernItemCard(report: reports[index]);
            },
          ),
        );
      },
    );
  }
}

// ======================================================
// MODERN COMPONENTS
// ======================================================
// (Tidak ada perubahan di sini, ini sudah benar)
class _ModernItemCard extends StatelessWidget {
  final ReportModel report;

  const _ModernItemCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final imageUrl = report.imageUrl?.trim();

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 14, bottom: 8),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF6C63FF).withOpacity(0.1),
                                  const Color(0xFF10B981).withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: Color(0xFF9CA3AF),
                              size: 40,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF2D3142),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM y')
                                .format(report.reportDate.toDate()),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
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
      ),
    );
  }
}

class _ModernActionCard extends StatelessWidget {
  // (Kode ini sudah benar, tidak diubah)
  final String title, subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ModernActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernEmptyState extends StatelessWidget {
  // (Kode ini sudah benar, tidak diubah)
  final IconData icon;
  final String message;

  const _ModernEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 40, color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}