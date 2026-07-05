import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UpdateService extends GetxService {
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  static const String updateUrl = 'https://raw.githubusercontent.com/allam1768/solat/master/update.json';

  final _storage = GetStorage();
  var isChecking = false.obs;

  // ponytail: Simple semantic version comparison
  static bool isNewerVersion(String remoteVersion, String localVersion) {
    List<int> remoteParts = remoteVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> localParts = localVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    int maxLength = remoteParts.length > localParts.length ? remoteParts.length : localParts.length;
    for (int i = 0; i < maxLength; i++) {
      int remoteVal = i < remoteParts.length ? remoteParts[i] : 0;
      int localVal = i < localParts.length ? localParts[i] : 0;
      if (remoteVal > localVal) return true;
      if (remoteVal < localVal) return false;
    }
    return false;
  }

  Future<void> checkForUpdate({bool isManual = false}) async {
    if (isChecking.value) return;

    isChecking.value = true;

    try {
      final response = await http.get(Uri.parse(updateUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String remoteVersion = data['version'] ?? '1.0.0';
        final int remoteBuild = data['build_number'] ?? 1;
        final String downloadUrl = data['download_url'] ?? 'https://github.com/allam1768/solat/releases';
        final String releaseNotes = data['release_notes'] ?? '';

        bool hasUpdate = false;
        if (remoteBuild > buildNumber) {
          hasUpdate = true;
        } else if (remoteBuild == buildNumber || data['build_number'] == null) {
          hasUpdate = isNewerVersion(remoteVersion, appVersion);
        }

        if (hasUpdate) {
          final ignoredVersion = _storage.read('ignored_version');
          if (!isManual && ignoredVersion == remoteVersion) {
            isChecking.value = false;
            return;
          }

          _showUpdateDialog(remoteVersion, downloadUrl, releaseNotes, isManual);
        } else {
          if (isManual) {
            _showToast('already_latest'.tr);
          }
        }
      } else {
        if (isManual) {
          _showToast('failed_check'.tr);
        }
      }
    } catch (e) {
      debugPrint('Error checking update: $e');
      if (isManual) {
        _showToast('failed_check'.tr);
      }
    } finally {
      isChecking.value = false;
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey.shade700,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showUpdateDialog(String remoteVersion, String downloadUrl, String releaseNotes, bool isManual) {
    final context = Get.context;
    if (context == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? Colors.white30 : Colors.black12;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: 1.5.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.system_update_rounded, color: fgColor, size: 28.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'update_available'.tr,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: fgColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                '${'current_version'.tr}: $appVersion ➔ $remoteVersion',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: fgColor.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'update_prompt'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.4,
                  color: fgColor.withValues(alpha: 0.8),
                ),
              ),
              if (releaseNotes.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: fgColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: fgColor.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Changelog:',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: fgColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        releaseNotes,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: fgColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (!isManual) {
                        _storage.write('ignored_version', remoteVersion);
                      }
                      Get.back();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: fgColor.withValues(alpha: 0.6),
                    ),
                    child: Text(
                      'later'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () async {
                      final Uri url = Uri.parse(downloadUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fgColor,
                      foregroundColor: bgColor,
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'update_now'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: isManual,
    );
  }
}
