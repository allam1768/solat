import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/app_colors.dart';
import 'SettingsController.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // SECTION 1: NOTIFIKASI WAKTU SHOLAT
              // ==========================================
              Text(
                'Notifikasi Waktu Sholat',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Notifikasi muncul tepat saat masuk waktu sholat',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Notification Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Toggle Notifikasi
                    Obx(() => SwitchListTile(
                      title: const Text(
                        'Aktifkan Notifikasi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Tampilkan notifikasi saat masuk waktu sholat',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: controller.notificationEnabled.value,
                      activeColor: AppColors.primary,
                      onChanged: controller.toggleNotification,
                    )),

                    const Divider(height: 1),

                    // Test Notifikasi Button
                    ListTile(
                      leading: const Icon(
                        Icons.notifications_active,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Test Notifikasi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Kirim notifikasi test',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: controller.testNotification,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ==========================================
              // SECTION 2: PENGINGAT OVERLAY (SELALU AKTIF)
              // ==========================================
              Text(
                'Pengingat Layar Penuh',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Overlay selalu aktif, atur durasi tampilan saja',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Overlay Permission Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Permission Status
                    Obx(() => ListTile(
                      leading: Icon(
                        controller.hasOverlayPermission.value
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: controller.hasOverlayPermission.value
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(
                        controller.hasOverlayPermission.value
                            ? 'Izin Overlay Diberikan'
                            : 'Izin Overlay Belum Diberikan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        controller.hasOverlayPermission.value
                            ? 'Overlay dapat ditampilkan'
                            : 'Ketuk untuk memberikan izin',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: controller.hasOverlayPermission.value
                          ? null
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: controller.hasOverlayPermission.value
                          ? null
                          : controller.requestOverlayPermission,
                    )),

                    const Divider(height: 1),

                    // Test Overlay Button
                    ListTile(
                      leading: const Icon(
                        Icons.fullscreen,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Test Overlay',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Tampilkan overlay test',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: controller.testOverlay,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Duration Settings
              Text(
                'Durasi Tampilan Overlay',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Overlay akan menutup setelah',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Obx(() => Text(
                          '${controller.overlayDuration.value} menit',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.durationOptions
                          .map((minutes) => Obx(() => ChoiceChip(
                        label: Text('$minutes min'),
                        selected: controller.overlayDuration.value == minutes,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: controller.overlayDuration.value == minutes
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: controller.overlayDuration.value == minutes
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            controller.setOverlayDuration(minutes);
                          }
                        },
                      )))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info Card - Jadwal Overlay
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kapan Overlay Muncul?',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('• Subuh: 30 menit sebelum terbit'),
                    _buildInfoItem('• Dzuhur: 30 menit sebelum Ashar'),
                    _buildInfoItem('• Ashar: 30 menit sebelum Maghrib'),
                    _buildInfoItem('• Maghrib: 30 menit sebelum Isya'),
                    _buildInfoItem('• Isya: 30 menit setelah masuk waktu'),
                    const SizedBox(height: 8),
                    Text(
                      'Overlay selalu aktif dan tidak dapat dimatikan',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info Card - Perbedaan Notifikasi dan Overlay
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Perbedaan',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem2(
                      'Notifikasi: Muncul saat MASUK waktu sholat (bisa dimatikan)',
                      Colors.orange.shade700,
                    ),
                    _buildInfoItem2(
                      'Overlay: Muncul 30 menit SEBELUM habis waktu (selalu aktif)',
                      Colors.orange.shade700,
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

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoItem2(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}