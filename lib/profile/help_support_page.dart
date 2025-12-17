import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'Bagaimana cara melaporkan barang hilang?',
      answer: 'Tap tombol "Lapor Kehilangan" di halaman beranda, isi formulir dengan lengkap (judul, deskripsi, lokasi, dan foto), lalu tap "Kirim Laporan". Laporan Anda akan langsung muncul di feed.',
    ),
    FAQItem(
      question: 'Bagaimana cara melaporkan barang yang saya temukan?',
      answer: 'Tap tombol "Lapor Ditemukan" di halaman beranda, isi detail barang yang Anda temukan, tandai lokasi di peta, dan upload foto. Pemilik barang akan dapat menghubungi Anda.',
    ),
    FAQItem(
      question: 'Apakah saya bisa mencari tanpa membuat akun?',
      answer: 'Ya! Anda bisa browse dan mencari laporan sebagai tamu. Namun untuk membuat laporan dan menghubungi pelapor, Anda harus login terlebih dahulu.',
    ),
    FAQItem(
      question: 'Bagaimana cara menghubungi pelapor?',
      answer: 'Buka detail laporan, scroll ke bawah hingga melihat informasi pelapor, lalu tap tombol "Hubungi Pelapor". Anda bisa memilih untuk chat via WhatsApp atau Email.',
    ),
    FAQItem(
      question: 'Bagaimana cara menandai lokasi di peta?',
      answer: 'Saat membuat laporan, tap tombol "Tandai di Peta". Anda bisa tap lokasi di peta, search alamat, atau gunakan GPS untuk lokasi saat ini. Tap "Konfirmasi Lokasi" untuk menyimpan.',
    ),
    FAQItem(
      question: 'Bagaimana cara mengedit atau menghapus laporan saya?',
      answer: 'Buka "Profil" → "Laporan Saya", pilih laporan yang ingin diedit/dihapus. Di halaman detail, tap icon titik tiga untuk opsi edit atau hapus.',
    ),
    FAQItem(
      question: 'Apakah data saya aman?',
      answer: 'Ya, kami menggunakan Firebase yang memiliki enkripsi tingkat enterprise. Data pribadi Anda hanya akan ditampilkan saat Anda membuat laporan dan tidak akan dibagikan ke pihak ketiga.',
    ),
    FAQItem(
      question: 'Bagaimana cara mengubah pengaturan notifikasi?',
      answer: 'Buka "Profil" → "Notifikasi" → Atur jenis notifikasi yang ingin Anda terima. Anda bisa mengaktifkan/menonaktifkan notifikasi untuk berbagai event.',
    ),
  ];

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
          "Bantuan & Dukungan",
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            _buildQuickActions(),
            
            const SizedBox(height: 32),

            // FAQ Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 20,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Pertanyaan Umum (FAQ)",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // FAQ List
            ..._faqItems.map((faq) => _buildFAQCard(faq)),

            const SizedBox(height: 32),

            // Contact Support
            _buildContactSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.video_library_rounded,
                title: 'Tutorial Video',
                subtitle: 'Panduan lengkap',
                color: const Color(0xFFEF4444),
                onTap: () {
                  _showComingSoonDialog('Tutorial Video');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.quiz_rounded,
                title: 'Panduan',
                subtitle: 'Cara menggunakan',
                color: const Color(0xFF10B981),
                onTap: () {
                  _showUserGuideDialog();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.chat_bubble_rounded,
                title: 'Live Chat',
                subtitle: 'Chat dengan tim',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  _launchWhatsApp();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.bug_report_rounded,
                title: 'Laporkan Bug',
                subtitle: 'Ada masalah?',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  _showReportBugDialog();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.quiz_rounded,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
          children: [
            Text(
              faq.answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Masih Butuh Bantuan?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tim support kami siap membantu Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchEmail,
                  icon: const Icon(Icons.email_rounded, size: 20),
                  label: const Text('Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/6281324633258?text=Halo, saya butuh bantuan dengan aplikasi Polcare');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Tidak dapat membuka WhatsApp');
      }
    } catch (e) {
      _showError('Gagal membuka WhatsApp: $e');
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'heykelprayogtimanta@students.polmed.ac.id',
      query: 'subject=Bantuan Aplikasi Polcare',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError('Tidak dapat membuka aplikasi email');
      }
    } catch (e) {
      _showError('Gagal membuka email: $e');
    }
  }

  void _showUserGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Panduan Pengguna'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideStep('1', 'Login atau masuk sebagai tamu'),
              _buildGuideStep('2', 'Browse laporan di halaman beranda'),
              _buildGuideStep('3', 'Gunakan pencarian atau Gunakan AI'),
              _buildGuideStep('4', 'Buat laporan kehilangan/penemuan'),
              _buildGuideStep('5', 'Hubungi pelapor via WhatsApp/Email'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog() {
    final TextEditingController bugController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Laporkan Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Jelaskan masalah yang Anda alami:'),
            const SizedBox(height: 12),
            TextField(
              controller: bugController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Deskripsi bug...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Kirim bug report
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bug report berhasil dikirim. Terima kasih!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 64, color: Color(0xFF6C63FF)),
            const SizedBox(height: 16),
            Text(
              '$feature Segera Hadir!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Fitur ini sedang dalam pengembangan'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}