import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

class ZikirItem {
  final String arabic;
  final String latin;
  final String translation;
  final int targetCount;

  ZikirItem({
    required this.arabic,
    required this.latin,
    required this.translation,
    this.targetCount = 1,
  });
}

class ZikirController extends GetxController {
  var activeTabIndex = 0.obs; // 0: Ba'da Sholat, 1: Tasbih Counter
  
  // Tasbih Counter State
  var counter = 0.obs;
  var target = 33.obs;
  var currentPhase = 0.obs; // 0: Subhanallah (33), 1: Alhamdulillah (33), 2: Allahu Akbar (33)

  final List<String> phaseNames = ['Subhanallah', 'Alhamdulillah', 'Allahu Akbar'];
  final List<String> phaseArab = ['سُبْحَانَ اللهِ', 'الْحَمْدُ لِلَّهِ', 'اللهُ أَكْبَرُ'];

  void incrementCounter() async {
    if (counter.value < target.value) {
      counter.value++;
      
      // Light haptic feedback on tap
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        if (counter.value == target.value) {
          Vibration.vibrate(pattern: [0, 40, 50, 40]); // Double tap on completion
        } else {
          Vibration.vibrate(duration: 30);
        }
      }

      if (counter.value >= target.value && currentPhase.value < 2) {
        // Move to next phase automatically after completion
        Future.delayed(const Duration(milliseconds: 300), () {
          currentPhase.value++;
          counter.value = 0;
        });
      }
    }
  }

  void resetCounter() {
    counter.value = 0;
    currentPhase.value = 0;
  }

  final List<ZikirItem> badaSholatList = [
    ZikirItem(
      arabic: 'أَسْتَغْفِرُ اللهَ (٣x)',
      latin: 'Astaghfirullah (3x)',
      translation: 'Aku memohon ampunan kepada Allah (3 kali).',
      targetCount: 3,
    ),
    ZikirItem(
      arabic: 'اللَّهُمَّ أَنْتَ السَّلاَمُ وَمِنْكَ السَّلاَمُ تَبَارَكْتَ يَا ذَا الْجَلاَلِ وَالإِكْرَامِ',
      latin: 'Allahumma antas-salam wa minkas-salam tabarakta ya dzal-jalali wal-ikram.',
      translation: 'Ya Allah, Engkau Mahasejahtera dan dari-Mu kesejahteraan, Mahasuci Engkau wahai Rabb Pemilik Keagungan dan Kemuliaan.',
    ),
    ZikirItem(
      arabic: 'لاَ إِلَهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      latin: 'Laa ilaaha illallahu wahdahu laa syariika lah, lahul mulku wa lahul hamdu wa huwa \'ala kulli syai\'in qadiir.',
      translation: 'Tiada sesembahan yang berhak disembah selain Allah semata, tidak ada sekutu bagi-Nya...',
    ),
    ZikirItem(
      arabic: 'اللَّهُمَّ لاَ مَانِعَ لِمَا أَعْطَيْتَ وَلاَ مُعْطِيَ لِمَا مَنَعْتَ وَلاَ يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
      latin: 'Allahumma laa maani\'a limaa a\'thaita wa laa mu\'thiya limaa mana\'ta wa laa yanfa\'u dzal-jaddi minkal-jaddu.',
      translation: 'Ya Allah, tidak ada yang dapat mencegah apa yang Engkau berikan dan tidak ada yang dapat memberi apa yang Engkau cegah...',
    ),
    ZikirItem(
      arabic: 'آيَةُ الْكُرْسِيِّ (اللهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ...)',
      latin: 'Ayat Kursi (Allahu laa ilaaha illa huwal hayyul qayyum...)',
      translation: 'Membaca Ayat Kursi setelah sholat fardhu.',
    ),
  ];
}
