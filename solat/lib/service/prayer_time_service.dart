import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/prayer_time_model.dart';
import 'dart:io';

class PrayerTimeService extends GetxService {
  Future<PrayerTimeModel> fetchPrayerTimes(double latitude, double longitude) async {
    try {
      String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

      String url = 'https://api.aladhan.com/v1/timings/$formattedDate'
          '?latitude=$latitude'
          '&longitude=$longitude'
          '&method=3';

      debugPrint('Fetching prayer times from: $url');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception("Connection Timeout");
        },
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PrayerTimeModel.fromJson(data);
      } else {
        debugPrint('Failed to load prayer times: ${response.statusCode}');
        throw Exception("Server Error: ${response.statusCode}");
      }
    } on SocketException {
      debugPrint('No Internet connection');
      Get.snackbar('No Connection', 'Please check your internet connection.');
      return PrayerTimeModel.error();
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
      Get.snackbar('Error', 'Gagal memuat jadwal shalat: $e');
      return PrayerTimeModel.error();
    }
  }
}
