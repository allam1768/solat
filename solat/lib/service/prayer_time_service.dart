import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/prayer_time_model.dart';

class PrayerTimeService extends GetxService {
  Future<PrayerTimeModel> fetchPrayerTimes(double latitude, double longitude, {String? isoCountryCode}) async {
    try {
      debugPrint('Calculating prayer times locally for: $latitude, $longitude (Country: $isoCountryCode)');
      
      final coordinates = Coordinates(latitude, longitude);
      
      // Auto-detect Calculation Method based on Country Code
      CalculationParameters params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;

      if (isoCountryCode != null && isoCountryCode.isNotEmpty) {
        switch (isoCountryCode.toUpperCase()) {
          case 'US':
          case 'CA':
            params = CalculationMethod.north_america.getParameters();
            break;
          case 'EG':
          case 'SD':
          case 'DZ':
          case 'MA':
          case 'TN':
            params = CalculationMethod.egyptian.getParameters();
            break;
          case 'PK':
          case 'IN':
          case 'BD':
          case 'AF':
            params = CalculationMethod.karachi.getParameters();
            params.madhab = Madhab.hanafi;
            break;
          case 'SA':
            params = CalculationMethod.umm_al_qura.getParameters();
            break;
          case 'AE':
            params = CalculationMethod.dubai.getParameters();
            break;
          case 'QA':
            params = CalculationMethod.qatar.getParameters();
            break;
          case 'KW':
            params = CalculationMethod.kuwait.getParameters();
            break;
          case 'SG':
          case 'MY':
          case 'ID':
            params = CalculationMethod.singapore.getParameters();
            break;
          case 'TR':
            params = CalculationMethod.turkey.getParameters();
            params.madhab = Madhab.hanafi;
            break;
        }
      }

      final date = DateComponents.from(DateTime.now());
      
      final prayerTimes = PrayerTimes(coordinates, date, params);
      
      return PrayerTimeModel.fromAdhan(prayerTimes);
    } catch (e) {
      debugPrint('Error calculating prayer times: $e');
      Get.snackbar('Error', 'Gagal memuat jadwal shalat: $e');
      return PrayerTimeModel.error();
    }
  }
}
