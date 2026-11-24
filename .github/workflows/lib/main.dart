import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final prefs = await SharedPreferences.getInstance();
  runApp(AthkarProApp(prefs: prefs));
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
    } catch (_) {}
  }

  static Future<void> scheduleDailyAdhkar() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'athkar_daily',
          'تذكير الأذكار',
          channelDescription: 'تنبيهات أذكار الصباح والمساء والصلاة',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      Future<void> addDaily(int id, int h, int m, String title, String body) async {
        final now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      await addDaily(1, 6, 0, 'أذكار الصباح ☀️', 'حصّن يومك بذكر الله');
      await addDaily(2, 17, 0, 'أذكار المساء 🌙', 'حان موعد أذكار المساء');
      await addDaily(3, 22, 0, 'أذكار النوم 🛌', 'اختم يومك بأذكار النوم والوتر');
    } catch (_) {}
  }
}

class DhikrItem {
  final String text, virtue;
  final int count;
  const DhikrItem({required this.text, required this.count, this.virtue = ''});
}

class DhikrCategory {
  final String id, title, subtitle;
  final IconData icon;
  final Color color;
  final List<DhikrItem> items;
  final bool isAsma;
  const DhikrCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
    this.isAsma = false,
  });
}

const _kursi =
    '﴿اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ﴾';
const _muaw =
    '﴿قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ﴾\n\n'
    '﴿قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ﴾\n\n'
    '﴿قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ﴾';
const _sayyid =
    'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.';

final List<DhikrCategory> kCategories = [
  DhikrCategory(
    id: 'morning', title: 'أذكار الصباح', subtitle: 'حصنك في بداية اليوم',
    icon: Icons.wb_sunny_rounded, color: const Color(0xFFD97706),
    items: const [
      DhikrItem(text: _kursi, count: 1, virtue: 'أُجير من الجن حتى يمسي.'),
      DhikrItem(text: _muaw, count: 3, virtue: 'تكفيك من كل شيء.'),
      DhikrItem(text: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ.', count: 1),
      DhikrItem(text: _sayyid, count: 1, virtue: 'سيد الاستغفار.'),
      DhikrItem(text: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.', count: 3),
      DhikrItem(text: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا.', count: 3),
      DhikrItem(text: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.', count: 1),
      DhikrItem(text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.', count: 100, virtue: 'حُطَّت خطاياه وإن كانت مثل زبد البحر.'),
    ],
  ),
  DhikrCategory(
    id: 'evening', title: 'أذكار المساء', subtitle: 'سكينة وطمأنينة للمساء',
    icon: Icons.nights_stay_rounded, color: const Color(0xFF1E3A8A),
    items: const [
      DhikrItem(text: _kursi, count: 1, virtue: 'أُجير من الجن حتى يصبح.'),
      DhikrItem(text: _muaw, count: 3, virtue: 'تكفيك من كل شيء.'),
      DhikrItem(text: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا.', count: 1),
      DhikrItem(text: _sayyid, count: 1, virtue: 'سيد الاستغفار.'),
      DhikrItem(text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.', count: 3),
      DhikrItem(text: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.', count: 3),
      DhikrItem(text: 'اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ.', count: 4, virtue: 'من قالها أربعاً أعتقه الله من النار.'),
    ],
  ),
  DhikrCategory(
    id: 'sleep', title: 'أذكار النوم', subtitle: 'نوم هادئ في حفظ الله',
    icon: Icons.bedtime_rounded, color: const Color(0xFF5B21B6),
    items: const [
      DhikrItem(text: _kursi, count: 1),
      DhikrItem(text: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ.', count: 1),
      DhikrItem(text: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.', count: 3),
      DhikrItem(text: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.', count: 1),
      DhikrItem(text: 'سُبْحَانَ اللَّهِ.', count: 33),
      DhikrItem(text: 'الْحَمْدُ لِلَّهِ.', count: 33),
      DhikrItem(text: 'اللَّهُ أَكْبَرُ.', count: 34),
    ],
  ),
  DhikrCategory(
    id: 'prayer', title: 'أذكار بعد الصلاة', subtitle: 'الأذكار المشروعة بعد السلام',
    icon: Icons.mosque_rounded, color: const Color(0xFF0F766E),
    items: const [
      DhikrItem(text: 'أَسْتَغْفِرُ اللَّهَ.', count: 3),
      DhikrItem(text: 'اللَّهُمَّ أَنْتَ السَّلَامُ، وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.', count: 1),
      DhikrItem(text: 'سُبْحَانَ اللَّهِ.', count: 33),
      DhikrItem(text: 'الْحَمْدُ لِلَّهِ.', count: 33),
      DhikrItem(text: 'اللَّهُ أَكْبَرُ.', count: 33),
      DhikrItem(text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.', count: 1, virtue: 'تمام المائة.'),
      DhikrItem(text: _kursi, count: 1, virtue: 'لم يمنعه من دخول الجنة إلا أن يموت.'),
    ],
  ),
  DhikrCategory(
    id: 'duas', title: 'أدعية جامعة ورقية', subtitle: 'من القرآن والسنة النبوية',
    icon: Icons.volunteer_activism_rounded, color: const Color(0xFF047857),
    items: const [
      DhikrItem(text: '﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ﴾', count: 1),
      DhikrItem(text: '﴿لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ﴾', count: 1, virtue: 'دعوة ذي النون.'),
      DhikrItem(text: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ.', count: 1),
      DhikrItem(text: 'اللَّهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَاسَ، اشْفِهِ وَأَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا.', count: 3),
    ],
  ),
  const DhikrCategory(
    id: 'asma', title: 'أسماء الله الحسنى', subtitle: '99 اسماً بمعانيها الجليلة',
    icon: Icons.auto_awesome_rounded, color: Color(0xFFB45309), isAsma: true, items: [],
  ),
];

const _asmaData =
    'الله:الجامع لصفات الكمال|الرحمن:ذو الرحمة الواسعة|الرحيم:الموصل رحمته لمن يشاء|الملك:المالك المتصرف|القدوس:المنزه عن كل نقص|السلام:واهب السلام|المؤمن:واهب الأمان|المهيمن:الرقيب الحافظ|العزيز:القوي الغالب|الجبار:المنفذ لمشيئته|المتكبر:المتعالي عن الخلق|الخالق:المبدع من عدم|البارئ:خالق الخلق بتناسق|المصور:مصوّر المخلوقات|الغفار:كثير المغفرة|القهار:الغالب لكل شيء|الوهاب:كثير العطاء|الرزاق:المتكفل بالأرزاق|الفتاح:فاتح أبواب الرحمة|العليم:المحيط علمه بكل شيء|القابض:قابض الأرزاق|الباسط:باسط الرزق|الخافض:خافض الظالمين|الرافع:رافع المؤمنين|المعز:واهب العزة|المذل:مذل المتكبرين|السميع:سامع الأصوات|البصير:يرى كل شيء|الحكم:الحاكم بالحق|العدل:المنزه عن الظلم|اللطيف:الرفيق بعباده|الخبير:العالم بالبواطن|الحليم:لا يعجل بالعقوبة|العظيم:ذو العظمة|الغفور:غافر الذنوب|الشكور:مضاعف الأجر|العلي:المرتفع فوق خلقه|الكبير:لا شيء أكبر منه|الحفيظ:حافظ الكون|المقيت:معطي الأقوات|الحسيب:الكافي والمحاسب|الجليل:عظيم القدر|الكريم:كثير الخير|الرقيب:المطلع على كل شيء|المجيب:مجيب الدعاء|الواسع:وسعت رحمته كل شيء|الحكيم:واضع الشيء في موضعه|الودود:المحب لعباده|المجيد:البالغ المجد|الباعث:باعث الخلق|الشهيد:لا يغيب عنه شيء|الحق:الثابت وجوده|الوكيل:القائم بأمور عباده|القوي:تام القدرة|المتين:شديد القوة|الولي:الناصر والمحب|الحميد:المستحق للحمد|المحصي:المحيط بالعدد|المبدئ:مبتدئ الخلق|المعيد:معيد الخلق|المحيي:واهب الحياة|المميت:مقدر الموت|الحي:الدائم الحياة|القيوم:القائم بنفسه|الواجد:الغني|الماجد:عظيم الشرف|الواحد:المتفرد|الصمد:المقصود في الحوائج|القادر:المتمكن|المقتدر:تام القدرة|المقدم:مقدم ما يشاء|المؤخر:مؤخر ما يشاء|الأول:ليس قبله شيء|الآخر:ليس بعده شيء|الظاهر:العالي فوق كل شيء|الباطن:العالم بالخفايا|الوالي:المالك المتصرف|المتعالي:المنزه|البر:كثير الإحسان|التواب:قابل التوبة|المنتقم:المعاقب للمجرمين|العفو:ماحي السيئات|الرؤوف:شديد الرحمة|مالك الملك:المتصرف المطلق|ذو الجلال والإكرام:صاحب العظمة|المقسط:العادل|الجامع:جامع الناس|الغني:المستغني|المغني:مغني من يشاء|المانع:المانع بحكمته|الضار:مقدر الابتلاء|النافع:موصل النفع|النور:منور السماوات|الهادي:المرشد للحق|البديع:المبدع بلا مثال|الباقي:الدائم|الوارث:الباقي بعد الخلق|الرشيد:المرشد للصواب|الصبور:لا يعاجل بالعقوبة';

class AthkarProApp extends StatefulWidget {
  final SharedPreferences prefs;
  const AthkarProApp({super.key, required this.prefs});
  @override
  State<AthkarProApp> createState() => _AthkarProAppState();
}

class _AthkarProAppState extends State<AthkarProApp> {
  late bool _dark;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _dark = widget.prefs.getBool('dark') ?? false;
    _fontSize = widget.prefs.getDouble('font') ?? 21.0;
  }

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF0F5132);
    return MaterialApp(
      title: 'أذكار المسلم',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: emerald, primary: emerald, secondary: const Color(0xFFC9A227), surface: const Color(0xFFF6F4EC)),
        scaffoldBackgroundColor: const Color(0xFFF6F4EC),
        textTheme: GoogleFonts.cairoTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: emerald, brightness: Brightness.dark, primary: const Color(0xFF34D399), secondary: const Color(0xFFC9A227), surface: const Color(0xFF15221B)),
        scaffoldBackgroundColor: const Color(0xFF0D1511),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      ),
      builder: (_, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: MainShell(
        prefs: widget.prefs,
        isDark: _dark,
        fontSize: _fontSize,
        onToggleDark: () {
          setState(() => _dark = !_dark);
          widget.prefs.setBool('dark', _dark);
        },
        onFontChanged: (v) {
          setState(() => _fontSize = v);
          widget.prefs.setDouble('font', v);
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final SharedPreferences prefs;
  final bool isDark;
  final double fontSize;
  final VoidCallback onToggleDark;
  final ValueChanged<double> onFontChanged;
  const MainShell({super.key, required this.prefs, required this.isDark, required this.fontSize, required this.onToggleDark, required this.onFontChanged});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  double _lat = 30.0444, _lng = 31.2357;
  String _cityName = 'القاهرة - مصر';

  @override
  void initState() {
    super.initState();
    _lat = widget.prefs.getDouble('lat') ?? 30.0444;
    _lng = widget.prefs.getDouble('lng') ?? 31.2357;
    _cityName = widget.prefs.getString('city') ?? 'القاهرة - مصر';
  }

  Future<void> _detectLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _cityName = 'موقعي الحالي (GPS)';
      });
      widget.prefs.setDouble('lat', _lat);
      widget.prefs.setDouble('lng', _lng);
      widget.prefs.setString('city', _cityName);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(prefs: widget.prefs, lat: _lat, lng: _lng, cityName: _cityName, fontSize: widget.fontSize, onFontChanged: widget.onFontChanged, onGoPrayers: () => setState(() => _tab = 1)),
      PrayersAndQiblaTab(lat: _lat, lng: _lng, cityName: _cityName, onDetectGps: _detectLocation),
      QuranKhatmahTab(prefs: widget.prefs),
      TasbihTab(prefs: widget.prefs),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.isDark ? const Color(0xFF13231B) : const Color(0xFF0F5132),
        foregroundColor: Colors.white,
        title: const Text('أذكار المسلم', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'تفعيل تذكير الأذكار اليومي',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () async {
              await NotificationService.scheduleDailyAdhkar();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تفعيل تنبيهات أذكار الصباح والمساء والنوم ✓')));
              }
            },
          ),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: widget.onToggleDark,
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_rounded), label: 'الأذكار'),
          NavigationDestination(icon: Icon(Icons.mosque_rounded), label: 'الصلاة والقبلة'),
          NavigationDestination(icon: Icon(Icons.auto_stories_rounded), label: 'الختمة'),
          NavigationDestination(icon: Icon(Icons.touch_app_rounded), label: 'المسبحة'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final SharedPreferences prefs;
  final double lat, lng, fontSize;
  final String cityName;
  final ValueChanged<double> onFontChanged;
  final VoidCallback onGoPrayers;
  const HomeTab({super.key, required this.prefs, required this.lat, required this.lng, required this.cityName, required this.fontSize, required this.onFontChanged, required this.onGoPrayers});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _query = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _hijriString() {
    const months = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
    final h = HijriCalendar.now();
    return '${h.hDay} ${months[h.hMonth - 1]} ${h.hYear} هـ';
  }

  @override
  Widget build(BuildContext context) {
    final coords = Coordinates(widget.lat, widget.lng);
    final params = CalculationMethod.egyptian.getParameters();
    final pt = PrayerTimes.today(coords, params);
    final nextP = pt.nextPrayer();
    final nextTime = nextP == Prayer.none
        ? PrayerTimes(coords, DateComponents.from(DateTime.now().add(const Duration(days: 1))), params).fajr
        : pt.timeForPrayer(nextP)!;
    final diff = nextTime.difference(DateTime.now());
    final cd = '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';

    final filtered = kCategories.where((c) => c.title.contains(_query) || c.items.any((i) => i.text.contains(_query))).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'ابحث في الأذكار...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: widget.onGoPrayers,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0B3F27), Color(0xFF198754)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_hijriString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(widget.cityName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾', style: GoogleFonts.amiri(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الصلاة القادمة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(cd, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.18),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final cat = filtered[i];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => cat.isAsma
                      ? const AsmaScreen()
                      : AdhkarReaderScreen(category: cat, prefs: widget.prefs, fontSize: widget.fontSize, onFontChanged: widget.onFontChanged),
                ),
              ),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cat.color.withAlpha(35), borderRadius: BorderRadius.circular(12)), child: Icon(cat.icon, color: cat.color)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(cat.isAsma ? '99 اسماً' : '${cat.items.length} أذكار', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class AdhkarReaderScreen extends StatefulWidget {
  final DhikrCategory category;
  final SharedPreferences prefs;
  final double fontSize;
  final ValueChanged<double> onFontChanged;
  const AdhkarReaderScreen({super.key, required this.category, required this.prefs, required this.fontSize, required this.onFontChanged});
  @override
  State<AdhkarReaderScreen> createState() => _AdhkarReaderScreenState();
}

class _AdhkarReaderScreenState extends State<AdhkarReaderScreen> {
  final _pageCtrl = PageController();
  late List<int> _rem;
  late double _font;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _font = widget.fontSize;
    _rem = widget.category.items.map((e) => e.count).toList();
  }

  void _tapCurrent() {
    if (_rem[_page] <= 0) return;
    setState(() => _rem[_page]--);
    if (_rem[_page] == 0) {
      HapticFeedback.mediumImpact();
      if (_page < widget.category.items.length - 1) {
        Future.delayed(const Duration(milliseconds: 260), () {
          if (mounted) _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        });
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.category.items.length;
    final doneCount = _rem.where((e) => e == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        actions: [
          IconButton(icon: const Icon(Icons.text_decrease), onPressed: () { setState(() => _font = (_font - 2).clamp(16, 32)); widget.onFontChanged(_font); }),
          IconButton(icon: const Icon(Icons.text_increase), onPressed: () { setState(() => _font = (_font + 2).clamp(16, 32)); widget.onFontChanged(_font); }),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _rem = widget.category.items.map((e) => e.count).toList())),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: doneCount / total, minHeight: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ذكر ${_page + 1} من $total', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('المكتمل: $doneCount', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: total,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, idx) {
                final item = widget.category.items[idx];
                final left = _rem[idx];
                final done = left == 0;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(item.text, textAlign: TextAlign.center, style: GoogleFonts.amiri(fontSize: _font + 3, height: 1.9)),
                                if (item.virtue.isNotEmpty) ...[const SizedBox(height: 16), Chip(label: Text(item.virtue, textAlign: TextAlign.center))],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: item.text));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الذكر')));
                            },
                          ),
                          GestureDetector(
                            onTap: _tapCurrent,
                            child: SizedBox(
                              width: 110,
                              height: 110,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(width: 110, height: 110, child: CircularProgressIndicator(value: (item.count - left) / item.count, strokeWidth: 8)),
                                  Text(done ? '✓' : '$left', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded), onPressed: () => _pageCtrl.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut)),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AsmaScreen extends StatelessWidget {
  const AsmaScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final list = _asmaData.split('|');
    return Scaffold(
      appBar: AppBar(title: const Text('أسماء الله الحسنى')),
      body: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.4),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final p = list[i].split(':');
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(p[0], style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(p[1], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PrayersAndQiblaTab extends StatelessWidget {
  final double lat, lng;
  final String cityName;
  final VoidCallback onDetectGps;
  const PrayersAndQiblaTab({super.key, required this.lat, required this.lng, required this.cityName, required this.onDetectGps});

  String _fmt(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? "م" : "ص"}';
  }

  @override
  Widget build(BuildContext context) {
    final coords = Coordinates(lat, lng);
    final pt = PrayerTimes.today(coords, CalculationMethod.egyptian.getParameters());
    final sunnah = SunnahTimes(pt);
    final qiblaAngle = Qibla(coords).direction;
    final rows = [('الفجر', pt.fajr), ('الشروق', pt.sunrise), ('الظهر', pt.dhuhr), ('العصر', pt.asr), ('المغرب', pt.maghrib), ('العشاء', pt.isha)];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('📍 $cityName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            FilledButton.icon(onPressed: onDetectGps, icon: const Icon(Icons.my_location, size: 18), label: const Text('GPS')),
          ],
        ),
        const SizedBox(height: 12),
        ...rows.map((r) => Card(child: ListTile(title: Text(r.$1, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text(_fmt(r.$2), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))))),
        Row(
          children: [
            Expanded(child: Card(child: ListTile(title: const Text('منتصف الليل', style: TextStyle(fontSize: 13)), subtitle: Text(_fmt(sunnah.middleOfTheNight))))),
            Expanded(child: Card(child: ListTile(title: const Text('الثلث الأخير', style: TextStyle(fontSize: 13)), subtitle: Text(_fmt(sunnah.lastThirdOfTheNight))))),
          ],
        ),
        const SizedBox(height: 20),
        Text('بوصلة القبلة الحية (${qiblaAngle.round()}°)', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (_, snap) {
            final heading = snap.data?.heading;
            if (heading == null) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('حرّك الهاتف على شكل 8 لتفعيل المستشعر المغناطيسي')));
            final diff = (qiblaAngle - heading + 540) % 360 - 180;
            final aligned = diff.abs() <= 5;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 220, height: 220,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: aligned ? Colors.green : Colors.grey.shade400, width: 6)),
                  child: Transform.rotate(
                    angle: (qiblaAngle - heading) * (math.pi / 180),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.navigation_rounded, size: 68, color: Color(0xFFC9A227)), Text('🕋', style: TextStyle(fontSize: 32))]),
                  ),
                ),
                const SizedBox(height: 10),
                Text(aligned ? '✓ أنت الآن باتجاه القبلة تماماً' : 'أدِر الهاتف ${diff.abs().round()}°', style: TextStyle(fontWeight: FontWeight.bold, color: aligned ? Colors.green : null)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class QuranKhatmahTab extends StatefulWidget {
  final SharedPreferences prefs;
  const QuranKhatmahTab({super.key, required this.prefs});
  @override
  State<QuranKhatmahTab> createState() => _QuranKhatmahTabState();
}

class _QuranKhatmahTabState extends State<QuranKhatmahTab> {
  late int _page;
  @override
  void initState() { super.initState(); _page = widget.prefs.getInt('qpage') ?? 0; }
  void _add(int d) { setState(() => _page = (_page + d).clamp(0, 604)); widget.prefs.setInt('qpage', _page); }

  @override
  Widget build(BuildContext context) {
    final pct = (_page / 604 * 100).round();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ختمة القرآن الكريم ($pct%)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('وصلتَ إلى صفحة $_page من 604', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _page / 604, minHeight: 10),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: [
                OutlinedButton(onPressed: () => _add(-1), child: const Text('-1')),
                FilledButton(onPressed: () => _add(1), child: const Text('+1 صفحة')),
                FilledButton(onPressed: () => _add(4), child: const Text('+4 صفحات')),
                FilledButton(onPressed: () => _add(20), child: const Text('+جزء (20)')),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class TasbihTab extends StatefulWidget {
  final SharedPreferences prefs;
  const TasbihTab({super.key, required this.prefs});
  @override
  State<TasbihTab> createState() => _TasbihTabState();
}

class _TasbihTabState extends State<TasbihTab> {
  final _phrases = ['سُبْحَانَ اللَّهِ', 'الْحَمْدُ لِلَّهِ', 'لَا إِلَهَ إِلَّا اللَّهُ', 'اللَّهُ أَكْبَرُ', 'أَسْتَغْفِرُ اللَّهَ'];
  int _idx = 0, _count = 0, _target = 33;
  late int _total;
  @override
  void initState() { super.initState(); _total = widget.prefs.getInt('tasbih_total') ?? 0; }
  void _tap() {
    setState(() { _count++; _total++; if (_target > 0 && _count > _target) _count = 1; });
    widget.prefs.setInt('tasbih_total', _total);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_phrases.length, (i) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(label: Text(_phrases[i]), selected: _idx == i, onSelected: (_) => setState(() { _idx = i; _count = 0; })),
              )),
            ),
          ),
          const Spacer(),
          Text(_phrases[_idx], style: GoogleFonts.amiri(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _tap,
            child: SizedBox(
              width: 210, height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 210, height: 210, child: CircularProgressIndicator(value: _target > 0 ? _count / _target : 1, strokeWidth: 12)),
                  Text('$_count', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Spacer(),
          Card(
            child: ListTile(
              title: Text('المجموع الكلي: $_total', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: TextButton(onPressed: () => setState(() => _count = 0), child: const Text('تصفير')),
            ),
          ),
        ],
      ),
    );
  }
}
