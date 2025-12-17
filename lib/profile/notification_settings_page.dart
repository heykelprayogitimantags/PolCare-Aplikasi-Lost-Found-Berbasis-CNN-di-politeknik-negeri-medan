import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _reportStatusUpdates = true;
  bool _newComments = true;
  bool _chatMessages = true;
  bool _foundItemMatches = true;
  bool _systemAnnouncements = false;
  bool _emailNotifications = false;
  bool _pushNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reportStatusUpdates = prefs.getBool('reportStatusUpdates') ?? true;
      _newComments = prefs.getBool('newComments') ?? true;
      _chatMessages = prefs.getBool('chatMessages') ?? true;
      _foundItemMatches = prefs.getBool('foundItemMatches') ?? true;
      _systemAnnouncements = prefs.getBool('systemAnnouncements') ?? false;
      _emailNotifications = prefs.getBool('emailNotifications') ?? false;
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Pengaturan ${value ? "diaktifkan" : "dinonaktifkan"}'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ),
    );
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
          "Pengaturan Notifikasi",
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
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: const Color(0xFF6C63FF),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kelola notifikasi yang ingin Anda terima',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Types Section
            _buildSectionTitle('Jenis Notifikasi', Icons.notifications_active_rounded),
            const SizedBox(height: 12),
            _buildNotificationCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.update_rounded,
                  title: 'Update Status Laporan',
                  subtitle: 'Notifikasi saat status laporan berubah',
                  value: _reportStatusUpdates,
                  onChanged: (value) {
                    setState(() => _reportStatusUpdates = value);
                    _saveSetting('reportStatusUpdates', value);
                  },
                  color: const Color(0xFF6C63FF),
                ),
                const Divider(height: 1, indent: 68),
                _buildSwitchTile(
                  icon: Icons.comment_rounded,
                  title: 'Komentar Baru',
                  subtitle: 'Notifikasi saat ada komentar di laporan Anda',
                  value: _newComments,
                  onChanged: (value) {
                    setState(() => _newComments = value);
                    _saveSetting('newComments', value);
                  },
                  color: const Color(0xFF10B981),
                ),
                const Divider(height: 1, indent: 68),
                _buildSwitchTile(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Pesan Chat',
                  subtitle: 'Notifikasi pesan dari pelapor lain',
                  value: _chatMessages,
                  onChanged: (value) {
                    setState(() => _chatMessages = value);
                    _saveSetting('chatMessages', value);
                  },
                  color: const Color(0xFF3B82F6),
                ),
                const Divider(height: 1, indent: 68),
                _buildSwitchTile(
                  icon: Icons.search_rounded,
                  title: 'Barang Cocok Ditemukan',
                  subtitle: 'Notifikasi saat ada barang yang cocok',
                  value: _foundItemMatches,
                  onChanged: (value) {
                    setState(() => _foundItemMatches = value);
                    _saveSetting('foundItemMatches', value);
                  },
                  color: const Color(0xFFF59E0B),
                ),
                const Divider(height: 1, indent: 68),
                _buildSwitchTile(
                  icon: Icons.campaign_rounded,
                  title: 'Pengumuman Sistem',
                  subtitle: 'Info penting dari aplikasi',
                  value: _systemAnnouncements,
                  onChanged: (value) {
                    setState(() => _systemAnnouncements = value);
                    _saveSetting('systemAnnouncements', value);
                  },
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Delivery Methods
            _buildSectionTitle('Metode Pengiriman', Icons.send_rounded),
            const SizedBox(height: 12),
            _buildNotificationCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_rounded,
                  title: 'Push Notification',
                  subtitle: 'Notifikasi di perangkat Anda',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                    _saveSetting('pushNotifications', value);
                  },
                  color: const Color(0xFF6C63FF),
                ),
                const Divider(height: 1, indent: 68),
                _buildSwitchTile(
                  icon: Icons.email_rounded,
                  title: 'Email Notification',
                  subtitle: 'Kirim notifikasi ke email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                    _saveSetting('emailNotifications', value);
                  },
                  color: const Color(0xFF10B981),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sound & Vibration
            _buildSectionTitle('Suara & Getar', Icons.volume_up_rounded),
            const SizedBox(height: 12),
            _buildNotificationCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.music_note_rounded,
                  title: 'Suara Notifikasi',
                  subtitle: 'Mainkan suara saat notifikasi masuk',
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() => _soundEnabled = value);
                    _saveSetting('soundEnabled', value);
                  },
                  color: const Color(0xFF3B82F6),
                ),
                const Divider(height: 1, indent: 68),
                _buildSwitchTile(
                  icon: Icons.vibration_rounded,
                  title: 'Getaran',
                  subtitle: 'Getar saat notifikasi masuk',
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() => _vibrationEnabled = value);
                    _saveSetting('vibrationEnabled', value);
                  },
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Reset Button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text('Reset Pengaturan?'),
                      content: const Text(
                        'Semua pengaturan notifikasi akan dikembalikan ke default.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            setState(() {
                              _reportStatusUpdates = true;
                              _newComments = true;
                              _chatMessages = true;
                              _foundItemMatches = true;
                              _systemAnnouncements = false;
                              _emailNotifications = false;
                              _pushNotifications = true;
                              _soundEnabled = true;
                              _vibrationEnabled = true;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Pengaturan direset ke default'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Reset ke Default'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}