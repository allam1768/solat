import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse('https://github.com/allam1768/solat');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : Colors.black;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final borderColor = isDark ? Colors.white30 : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Top Bar
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: fgColor,
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'privacy policy',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: fgColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Title & Subtitle Centered
              Center(
                child: Column(
                  children: [
                    Text(
                      'Solat app',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: fgColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'TERAKHIR DIPERBARUI: 24 JULI 2026',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: fgColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Boxed Intro Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: borderColor, width: 4.w),
                ),
                child: Text(
                  'Terima kasih telah memilih Solat App. Kami berkomitmen untuk melindungi privasi kamu dan memastikan kamu memiliki pengalaman yang nyaman dan aman saat menggunakan aplikasi kami.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: fgColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // 1. Information Collection and Use
              _buildSectionTitle(
                  '1. Pengumpulan dan Penggunaan Informasi', fgColor),
              SizedBox(height: 16.h),

              _buildSubHeader('A. DATA LOKASI', fgColor),
              SizedBox(height: 10.h),

              _buildLabeledParagraph(
                  'Apa yang Kami Kumpulkan:',
                  'Data lokasi perkiraan (coarse) dan presisi (fine) (koordinat GPS).',
                  fgColor),
              SizedBox(height: 12.h),

              _buildLabeledParagraph(
                  'Alasan Kami Mengumpulkannya:',
                  'Data lokasi digunakan khusus untuk menghitung jadwal sholat harian (Subuh, Dzuhur, Ashar, Maghrib, Isya) dan menentukan arah kiblat di lokasi kamu secara akurat.',
                  fgColor),
              SizedBox(height: 12.h),

              _buildHandledParagraph(fgColor),
              SizedBox(height: 20.h),

              _buildSubHeader('B. INFORMASI PERANGKAT & IZIN', fgColor),
              SizedBox(height: 14.h),

              _buildPermissionItem(
                icon: Icons.notifications_none_rounded,
                title: 'Izin Notifikasi',
                description:
                    'Digunakan khusus untuk mengabarkan pengingat waktu sholat dan persiapan sholat Jumat.',
                fgColor: fgColor,
              ),
              SizedBox(height: 14.h),

              _buildPermissionItem(
                icon: Icons.alarm_rounded,
                title: 'Izin Alarm Presisi',
                description:
                    'Digunakan untuk menjadwalkan alarm presisi agar pengingat sholat dan notifikasi pengingat layar penuh (overlay) muncul tepat waktu.',
                fgColor: fgColor,
              ),
              SizedBox(height: 14.h),

              _buildPermissionItem(
                icon: Icons.layers_outlined,
                title: 'Izin Jendela Overlay',
                description:
                    'Digunakan untuk menampilkan pengingat layar penuh di atas aplikasi lain saat waktu sholat makin dekat.',
                fgColor: fgColor,
              ),
              SizedBox(height: 32.h),

              // 2. Data Storage and Security
              _buildSectionTitle('2. Penyimpanan dan Keamanan Data', fgColor),
              SizedBox(height: 12.h),

              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.5,
                    color: fgColor.withValues(alpha: 0.85),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Semua preferensi pengguna (seperti tema pilihan dan pengingat yang aktif) disimpan secara lokal di perangkat kamu menggunakan ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: fgColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4.r),
                          border:
                              Border.all(color: fgColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'GetStorage',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: fgColor,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Boxed Lock Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: borderColor, width: 1.8.w),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: fgColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Kami tidak memiliki atau mengelola database eksternal untuk mengumpulkan data pribadi pengguna.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: fgColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // 3. Third-Party Services
              _buildSectionTitle('3. Layanan Pihak Ketiga', fgColor),
              SizedBox(height: 12.h),
              Text(
                'Aplikasi kami tidak menjual, memperdagangkan, atau memindahkan informasi pribadi kamu ke pihak luar.',
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.5,
                  color: fgColor.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: 32.h),

              // 4. Children's Privacy
              _buildSectionTitle('4. Privasi Anak-Anak', fgColor),
              SizedBox(height: 12.h),
              Text(
                'Aplikasi kami aman untuk semua umur dan tidak mengumpulkan informasi pribadi apa pun dari anak-anak.',
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.5,
                  color: fgColor.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: 32.h),

              // 5. Changes to This Privacy Policy
              _buildSectionTitle('5. Perubahan Kebijakan Privasi Ini', fgColor),
              SizedBox(height: 12.h),
              Text(
                'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Kamu disarankan untuk memeriksa halaman ini secara berkala jika ada perubahan.',
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.5,
                  color: fgColor.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: 32.h),

              // 6. Contact Us
              _buildSectionTitle('6. Hubungi Kami', fgColor),
              SizedBox(height: 12.h),
              Text(
                'Jika kamu punya pertanyaan atau saran tentang Kebijakan Privasi kami, silakan hubungi kami melalui:',
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.5,
                  color: fgColor.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: 16.h),

              // GitHub Button
              InkWell(
                onTap: _launchGitHub,
                borderRadius: BorderRadius.circular(30.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        color: isDark ? Colors.black : Colors.white,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Kunjungi GitHub',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color fgColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        color: fgColor,
      ),
    );
  }

  Widget _buildSubHeader(String title, Color fgColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: fgColor,
      ),
    );
  }

  Widget _buildLabeledParagraph(String label, String content, Color fgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          content,
          style: TextStyle(
            fontSize: 13.sp,
            height: 1.5,
            color: fgColor.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildHandledParagraph(Color fgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bagaimana Data Dikelola:',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
        SizedBox(height: 2.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.5,
              color: fgColor.withValues(alpha: 0.85),
              fontFamily: 'Plus Jakarta Sans',
            ),
            children: [
              const TextSpan(
                text:
                    'Semua perhitungan lokasi dilakukan secara lokal di perangkat kamu menggunakan algoritma offline. Data lokasi kamu ',
              ),
              TextSpan(
                text: 'tidak pernah',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  color: fgColor,
                ),
              ),
              const TextSpan(
                text:
                    ' diunggah ke server, dijual, atau dibagikan ke pihak ketiga mana pun.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color fgColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(
            icon,
            size: 20.sp,
            color: fgColor,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.4,
                  color: fgColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
