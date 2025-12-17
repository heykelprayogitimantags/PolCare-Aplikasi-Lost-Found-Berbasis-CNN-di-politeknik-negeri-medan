import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/api_service.dart';
import '../report/report_detail_page.dart';

class SearchPage extends StatefulWidget {
  final String? initialFilter;

  const SearchPage({super.key, this.initialFilter});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedStatus;
  List<String>? _imageSearchResultIds;
  bool _isSearchingByImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _selectedStatus = widget.initialFilter;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isIdle {
    return _query.isEmpty &&
        _selectedStatus == null &&
        _imageSearchResultIds == null;
  }

  Future<void> _pickAndSearchImage(ImageSource source) async {
    Navigator.pop(context);

    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _isSearchingByImage = true;
      _query = '';
      _searchController.clear();
      _imageSearchResultIds = null;
    });

    try {
      final List<String> matchedIds =
          await ApiService.searchByImage(File(image.path));

      setState(() {
        _imageSearchResultIds = matchedIds.isNotEmpty ? matchedIds : [];
      });

      if (mounted) {
        if (matchedIds.isEmpty) {
          _showSnackBar(
            'Tidak ada hasil yang cocok',
            Icons.info_outline_rounded,
            const Color(0xFF6B7280),
          );
        } else {
          _showSnackBar(
            'Ditemukan ${matchedIds.length} hasil',
            Icons.check_circle_outline_rounded,
            const Color(0xFF10B981),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error searching by image: $e");
      setState(() {
        _imageSearchResultIds = [];
      });

      if (mounted) {
        _showSnackBar(
          e.toString().contains('connect')
              ? 'Tidak dapat terhubung ke server AI'
              : 'Gagal mencari dengan gambar',
          Icons.error_outline_rounded,
          const Color(0xFFEF4444),
        );
      }
    } finally {
      setState(() {
        _isSearchingByImage = false;
      });
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // Title
            const Text(
              'Cari dengan AI',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih sumber foto untuk pencarian',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Camera option
            _buildSourceOption(
              icon: Icons.camera_alt_outlined,
              title: 'Ambil Foto',
              subtitle: 'Gunakan kamera perangkat',
              color: const Color(0xFF6366F1),
              onTap: () => _pickAndSearchImage(ImageSource.camera),
            ),
            const SizedBox(height: 12),

            // Gallery option
            _buildSourceOption(
              icon: Icons.photo_library_outlined,
              title: 'Pilih dari Galeri',
              subtitle: 'Buka galeri foto',
              color: const Color(0xFF10B981),
              onTap: () => _pickAndSearchImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getStream() {
    if (_imageSearchResultIds != null) {
      return _firestoreService.getReportsByIds(_imageSearchResultIds!);
    } else if (_query.isNotEmpty || _selectedStatus != null) {
      return _firestoreService
          .searchReports(_query, filters: {'status': _selectedStatus});
    } else {
      return _firestoreService.getAllReports();
    }
  }

  Widget _buildIdleState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.1),
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.search_rounded,
                  size: 56,
                  color: const Color(0xFF6366F1).withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Temukan Barang Anda',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Ketik nama barang atau gunakan AI\nuntuk pencarian lebih akurat',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // AI Search CTA
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showImageSourceSheet,
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Cari dengan AI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.stars_rounded,
                                    color: Color(0xFFFBBF24),
                                    size: 18,
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Upload foto untuk hasil akurat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Atau filter cepat',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
              ],
            ),
            const SizedBox(height: 32),

            // Quick filters
            Row(
              children: [
                Expanded(
                  child: _buildQuickFilterChip(
                    label: 'Hilang',
                    icon: Icons.search_off_rounded,
                    color: const Color(0xFFEF4444),
                    onPressed: () {
                      setState(() => _selectedStatus = 'lost');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickFilterChip(
                    label: 'Ditemukan',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                    onPressed: () {
                      setState(() => _selectedStatus = 'found');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _getStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isSearchingByImage) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                    strokeWidth: 3,
                  ),
                  if (_isSearchingByImage) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Mencari dengan AI...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final reports = snapshot.data!.docs;
          List<DocumentSnapshot> sortedReports = List.from(reports);

          if (_imageSearchResultIds != null) {
            sortedReports.sort((a, b) {
              int indexA = _imageSearchResultIds!.indexOf(a.id);
              int indexB = _imageSearchResultIds!.indexOf(b.id);
              return indexA.compareTo(indexB);
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.list_alt_rounded,
                        size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${sortedReports.length} laporan ditemukan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: sortedReports.length,
                  itemBuilder: (context, index) {
                    final reportDoc = sortedReports[index];
                    final data = reportDoc.data() as Map<String, dynamic>;
                    return _buildReportCard(data, reportDoc.id);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'Tanpa Judul';
    final desc = data['description'] ?? '';
    final status = data['status'] ?? 'unknown';
    final imageUrl = data['imageUrl'] ?? '';
    final locationName = data['locationName'] ?? 'Lokasi tidak diketahui';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // INI KODE BARUNYA
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailPage(reportId: docId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 85,
                          height: 85,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(status),
                        )
                      : _buildPlaceholder(status),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      _buildStatusBadge(status),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
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
      ),
    );
  }

  Widget _buildPlaceholder(String status) {
    final isFound = status == 'found';
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        color: isFound
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isFound ? Icons.check_circle_outline : Icons.search_off_rounded,
        color: isFound ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        size: 32,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isFound = status == 'found';
    final color = isFound ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFound ? Icons.check_circle : Icons.search_off,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isFound ? 'Ditemukan' : 'Hilang',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'Tidak ada hasil';
    String subtitle = 'Coba kata kunci lain';

    if (_imageSearchResultIds != null) {
      message = 'Tidak ada kecocokan';
      subtitle = 'Coba dengan foto lain';
    } else if (_query.isNotEmpty) {
      message = 'Tidak ada hasil untuk "$_query"';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1F2937),
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
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _query = '';
                  _searchController.clear();
                  _selectedStatus = null;
                  _imageSearchResultIds = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reset'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: widget.initialFilter != null,
        leading: widget.initialFilter != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: const Color(0xFF1F2937),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Cari Laporan',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari berdasarkan judul barang...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey[400],
                          size: 22,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                color: Colors.grey[400],
                                onPressed: () {
                                  setState(() {
                                    _query = '';
                                    _searchController.clear();
                                    _imageSearchResultIds = null;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _query = value.trim();
                          _imageSearchResultIds = null;
                        });
                      },
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE5E7EB),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, size: 22),
                    color: const Color(0xFF6366F1),
                    onPressed: _showImageSourceSheet,
                    tooltip: 'AI Search',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            // Active Filters
            if (_imageSearchResultIds != null || _selectedStatus != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_imageSearchResultIds != null)
                    _buildActiveFilterBadge(
                      label: 'AI Search',
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF6366F1),
                      onRemove: () {
                        setState(() => _imageSearchResultIds = null);
                      },
                    ),
                  if (_selectedStatus != null)
                    _buildActiveFilterBadge(
                      label: _selectedStatus == 'lost' ? 'Hilang' : 'Ditemukan',
                      icon: _selectedStatus == 'lost'
                          ? Icons.search_off_rounded
                          : Icons.check_circle_rounded,
                      color: _selectedStatus == 'lost'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      onRemove: () {
                        setState(() => _selectedStatus = null);
                      },
                    ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Content
            _isIdle ? Expanded(child: _buildIdleState()) : _buildResultsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterBadge({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}
