import 'package:quizistan_academy/models/question.dart';

/// Bundled sample questions — the app works fully offline with these
/// until Firebase (google-services.json) is configured. When Firebase
/// becomes ready, screens prefer Firestore and ignore this bank.
class LocalQuestionBank {
  LocalQuestionBank._();

  static final DateTime _now = DateTime.now();

  static Question _q(
    String id,
    String classLevel,
    String subject,
    String chapter,
    String text,
    List<String> options,
    int correctIndex,
    String explanation,
  ) =>
      Question(
        id: id,
        board: '', // empty board = matches every board filter
        classLevel: classLevel,
        subject: subject,
        chapter: chapter,
        text: text,
        options: options,
        correctIndex: correctIndex,
        explanation: explanation,
        createdBy: 'bundled',
        createdAt: _now,
      );

  static final List<Question> all = List.unmodifiable([
    // ---------------------------------------------------------- Urdu ----
    _q('l-ur-01', '9', 'Urdu', 'Hamd', 'Pakistan ka qaumi tarana kis ne likha?',
        ['Hafeez Jalandhri', 'Allama Iqbal', 'Faiz Ahmed Faiz', 'Ahmed Faraz'], 0,
        'Qaumi tarana Hafeez Jalandhri ne likha, dhun Ahmed G. Chagla ne banayi.'),
    _q('l-ur-02', '10', 'Urdu', 'Lughat', "'Khushboo' ka mutazad (opposite) kya hai?",
        ['Mehak', 'Badboo', 'Atar', 'Khushgawar'], 1,
        'Khushboo ka mutazad Badboo hai.'),
    _q('l-ur-03', '9', 'Urdu', 'Adab', 'Mirza Ghalib ka asal naam kya tha?',
        ['Mirza Asadullah Khan', 'Mirza Nosha', 'Asad Khan', 'Ghalib Mirza'], 0,
        'Mirza Ghalib ka asal naam Mirza Asadullah Khan tha.'),
    _q('l-ur-04', '10', 'Urdu', 'Qawaid', "'Kitab' ka jama (plural) kya hai?",
        ['Kitaben', 'Kutub', 'Katib', 'Maktab'], 1,
        "'Kitab' ka jama 'Kutub' hai."),
    _q('l-ur-05', '11', 'Urdu', 'Adab', "Allama Iqbal ki 'Bang-e-Dara' kis zuban me hai?",
        ['Farsi', 'Urdu', 'Arabic', 'Punjabi'], 1,
        "'Bang-e-Dara' Allama Iqbal ka Urdu majmua-e-kalam hai."),
    // -------------------------------------------------------- English ----
    _q('l-en-01', '9', 'English', 'Spelling', 'Choose the correct spelling:',
        ['Neccessary', 'Necessary', 'Necessery', 'Necesary'], 1,
        "Correct spelling 'Necessary' hai — ek C, do S."),
    _q('l-en-02', '10', 'English', 'Vocabulary', "What is the opposite of 'Brave'?",
        ['Bold', 'Coward', 'Hero', 'Strong'], 1,
        "'Brave' ka opposite 'Coward' hai."),
    _q('l-en-03', '9', 'English', 'Grammar', 'He ___ to school daily.',
        ['go', 'goes', 'going', 'gone'], 1,
        "Third person singular ke sath 'goes' lagta hai."),
    _q('l-en-04', '10', 'English', 'Vocabulary', "Synonym of 'Begin'?",
        ['End', 'Start', 'Close', 'Finish'], 1,
        "'Begin' ka synonym 'Start' hai."),
    _q('l-en-05', '11', 'English', 'Grammar', 'Which one is a proper noun?',
        ['city', 'Lahore', 'book', 'river'], 1,
        "'Lahore' proper noun hai — specific naam capital letter se."),
    // ---------------------------------------------------- Mathematics ----
    _q('l-ma-01', '9', 'Mathematics', 'Algebra', 'Agar 2x + 6 = 14, to x ki value?',
        ['2', '3', '4', '5'], 2,
        '2x = 14 - 6 = 8, is liye x = 4.'),
    _q('l-ma-02', '10', 'Mathematics', 'Percentage', '50 ka 10% kitna hota hai?',
        ['4', '5', '6', '10'], 1,
        '50 x 0.10 = 5.'),
    _q('l-ma-03', '9', 'Mathematics', 'Arithmetic', '7 x 8 = ?',
        ['54', '55', '56', '57'], 2,
        '7 x 8 = 56.'),
    _q('l-ma-04', '10', 'Mathematics', 'Geometry', 'Ek triangle ke do angles 60° aur 60° hon to teesra?',
        ['30°', '60°', '90°', '120°'], 1,
        "Triangle ke angles ka sum 180° hota hai: 180 - 120 = 60°."),
    _q('l-ma-05', '11', 'Mathematics', 'Roots', '√144 = ?',
        ['10', '11', '12', '14'], 2,
        '12 x 12 = 144, is liye √144 = 12.'),
    // -------------------------------------------------------- Physics ----
    _q('l-ph-01', '9', 'Physics', 'Units', 'Power ka SI unit kya hai?',
        ['Newton', 'Joule', 'Watt', 'Volt'], 2,
        "Power ka SI unit Watt hai — James Watt ke naam par."),
    _q('l-ph-02', '10', 'Physics', 'Waves', 'Hawa me awaz ki speed kitni hoti hai?',
        ['150 m/s', '343 m/s', '3x10^8 m/s', '500 m/s'], 1,
        'Kamre ke temperature par awaz ki speed taqreeban 343 m/s hoti hai.'),
    _q('l-ph-03', '9', 'Physics', 'Electricity', 'Electric current ka unit kya hai?',
        ['Volt', 'Ohm', 'Ampere', 'Watt'], 2,
        'Current Ampere me mapa jata hai.'),
    _q('l-ph-04', '11', 'Physics', 'Laws', "Newton ka pehla qanoon kis bare me hai?",
        ['Gravity', 'Inertia', 'Momentum', 'Energy'], 1,
        'Pehla qanoon inertia ka hai — cheez apni halat barqarar rakhti hai.'),
    _q('l-ph-05', '10', 'Physics', 'Work', 'Work ka formula kya hai?',
        ['Mass x Speed', 'Force x Distance', 'Power x Time', 'Energy x Mass'], 1,
        'Work = Force x Distance (Joule me).'),
    // ------------------------------------------------------ Chemistry ----
    _q('l-ch-01', '9', 'Chemistry', 'Compounds', 'NaCl ka aam naam kya hai?',
        ['Cheeni', 'Namak', 'Chuna', 'Soda'], 1,
        'NaCl aam khane wala namak (sodium chloride) hai.'),
    _q('l-ch-02', '10', 'Chemistry', 'Elements', 'Oxygen ka chemical symbol kya hai?',
        ['Ox', 'O2', 'O', 'Og'], 2,
        "Oxygen ka symbol 'O' hai."),
    _q('l-ch-03', '9', 'Chemistry', 'Atoms', 'Carbon ka atomic number kitna hai?',
        ['4', '6', '8', '12'], 1,
        'Carbon ka atomic number 6 hai — 6 protons.'),
    _q('l-ch-04', '11', 'Chemistry', 'pH', 'Neutral solution ki pH value kya hoti hai?',
        ['0', '1', '7', '14'], 2,
        'Neutral (jaise khalis pani) ki pH 7 hoti hai.'),
    _q('l-ch-05', '10', 'Chemistry', 'Gases', 'Carbon dioxide ka formula kya hai?',
        ['CO', 'CO2', 'C2O', 'O2C'], 1,
        "Carbon dioxide ka formula CO2 hai."),
    // -------------------------------------------------------- Biology ----
    _q('l-bi-01', '9', 'Biology', 'Human Body', 'Insani jism ki sab se lambi haddi konsi hai?',
        ['Tibia', 'Femur', 'Humerus', 'Radius'], 1,
        'Femur (raan ki haddi) jism ki sab se lambi aur mazboot haddi hai.'),
    _q('l-bi-02', '10', 'Biology', 'Blood', 'Red blood cells ka main kaam kya hai?',
        ['Infection se larna', 'Oxygen pahunchana', 'Khoon jamana', 'Hormone banana'], 1,
        'Red blood cells hemoglobin se oxygen tissues tak pahunchate hain.'),
    _q('l-bi-03', '11', 'Biology', 'Genetics', 'DNA ka full form kya hai?',
        ['Deoxyribonucleic Acid', 'Diribonucleic Acid', 'Dynamic Nucleic Acid', 'Double Nucleic Atom'], 0,
        'DNA = Deoxyribonucleic Acid — wirasat ki maloomat rakhta hai.'),
    _q('l-bi-04', '9', 'Biology', 'Human Body', 'Insani dil me kitne khane (chambers) hote hain?',
        ['2', '3', '4', '5'], 2,
        'Dil me 4 khane hote hain — 2 atria aur 2 ventricles.'),
    _q('l-bi-05', '12', 'Biology', 'Plants', 'Podon ke khana banane ke amal ko kya kehte hain?',
        ['Respiration', 'Transpiration', 'Photosynthesis', 'Germination'], 2,
        'Photosynthesis me poda sunlight se glucose banata hai.'),
    // ----------------------------------------------- Computer Science ----
    _q('l-cs-01', '9', 'Computer Science', 'Basics', 'CPU ka full form kya hai?',
        ['Central Process Unit', 'Central Processing Unit', 'Computer Personal Unit', 'Central Program Utility'], 1,
        'CPU = Central Processing Unit — computer ka dimagh.'),
    _q('l-cs-02', '10', 'Computer Science', 'Memory', '1 byte me kitne bits hote hain?',
        ['4', '8', '16', '32'], 1,
        '1 byte = 8 bits.'),
    _q('l-cs-03', '9', 'Computer Science', 'Hardware', 'In me se input device konsi hai?',
        ['Monitor', 'Printer', 'Keyboard', 'Speaker'], 2,
        'Keyboard input device hai — data andar bhejta hai.'),
    _q('l-cs-04', '11', 'Computer Science', 'Internet', 'WWW ka full form kya hai?',
        ['World Wide Web', 'World Web Wide', 'Wide World Web', 'Web World Wide'], 0,
        'WWW = World Wide Web.'),
    _q('l-cs-05', '10', 'Computer Science', 'Software', 'In me se software ki example konsi hai?',
        ['CPU', 'MS Word', 'Mouse', 'Printer'], 1,
        'MS Word application software hai; baqi hardware hain.'),
    // ------------------------------------------------------- Islamiat ----
    _q('l-is-01', '9', 'Islamiat', 'Seerat', 'Pehli wahi kahan nazil hui?',
        ['Ghar-e-Saur', 'Ghar-e-Hira', 'Masjid-e-Nabvi', 'Badr'], 1,
        "Pehli wahi Ghar-e-Hira me Surah Al-Alaq ki ibtedai ayaat thin."),
    _q('l-is-02', '10', 'Islamiat', 'Quran', 'Quran Pak me kitne pare hain?',
        ['25', '28', '30', '33'], 2,
        'Quran Pak 30 paron me taqseem hai.'),
    _q('l-is-03', '9', 'Islamiat', 'Ibadat', 'Roza kis mahine me farz hai?',
        ['Shaban', 'Ramzan', 'Shawwal', 'Zil Hajj'], 1,
        'Ramzan ke roze har baligh Musalman par farz hain.'),
    _q('l-is-04', '10', 'Islamiat', 'Ibadat', 'Din me kitni namazen farz hain?',
        ['3', '4', '5', '6'], 2,
        '5 waqt ki namaz farz hai: Fajr, Zuhr, Asr, Maghrib, Isha.'),
    _q('l-is-05', '11', 'Islamiat', 'Seerat', 'Huzoor ﷺ ki wiladat kahan hui?',
        ['Madinah', 'Taif', 'Makkah', 'Yaman'], 2,
        'Aap ﷺ 571 me Makkah me paida hue.'),
    // ---------------------------------------------------- Pak Studies ----
    _q('l-ps-01', '9', 'Pak Studies', 'History', 'Pakistan kab wajood me aaya?',
        ['14 August 1947', '15 August 1947', '23 March 1940', '26 January 1950'], 0,
        'Pakistan 14 August 1947 ko wajood me aaya.'),
    _q('l-ps-02', '10', 'Pak Studies', 'History', 'Pakistan ka pehla dar-ul-hakumat konsa tha?',
        ['Lahore', 'Karachi', 'Islamabad', 'Rawalpindi'], 1,
        'Karachi pehla dar-ul-hakumat tha; 1960s me Islamabad bana.'),
    _q('l-ps-03', '9', 'Pak Studies', 'Geography', 'Raqbe ke lehaz se Pakistan ka sab se bara suba?',
        ['Punjab', 'Sindh', 'KPK', 'Balochistan'], 3,
        'Balochistan raqbe me sab se bara suba hai.'),
    _q('l-ps-04', '10', 'Pak Studies', 'Places', 'Minar-e-Pakistan kahan waqe hai?',
        ['Karachi', 'Lahore', 'Islamabad', 'Multan'], 1,
        'Minar-e-Pakistan Lahore me Iqbal Park me hai.'),
    _q('l-ps-05', '11', 'Pak Studies', 'Symbols', 'Pakistan ka qaumi janwar konsa hai?',
        ['Sher', 'Markhor', 'Hiran', 'Cheeta'], 1,
        'Markhor Pakistan ka qaumi janwar hai.'),
    // ---------------------------------------------- Tarjuma-tul-Quran ----
    _q('l-tq-01', '9', 'Tarjuma-tul-Quran', 'Vocabulary', "'Iqra' ka tarjuma kya hai?",
        ['Likho', 'Parho', 'Suno', 'Dekho'], 1,
        "'Iqra' ka matlab 'Parho' hai — pehli wahi ka pehla lafz."),
    _q('l-tq-02', '10', 'Tarjuma-tul-Quran', 'Surahs', 'Surah Al-Fatiha me kitni ayaat hain?',
        ['5', '6', '7', '8'], 2,
        'Surah Al-Fatiha me 7 ayaat hain.'),
    _q('l-tq-03', '11', 'Tarjuma-tul-Quran', 'Vocabulary', "'Rabb' ka matlab kya hai?",
        ['Dost', 'Parwardigar', 'Badshah', 'Ustad'], 1,
        "'Rabb' ka matlab Parwardigar — palne wala."),
    _q('l-tq-04', '9', 'Tarjuma-tul-Quran', 'Surahs', 'Sab se pehle nazil hone wali surah?',
        ['Al-Fatiha', 'Al-Baqarah', 'Al-Alaq', 'Al-Ikhlas'], 2,
        'Surah Al-Alaq ki ibtedai 5 ayaat sab se pehle nazil huin.'),
    _q('l-tq-05', '12', 'Tarjuma-tul-Quran', 'Vocabulary', "'Noor' ka matlab kya hai?",
        ['Andhera', 'Roshni', 'Hidayat', 'Rahmat'], 1,
        "'Noor' ka matlab Roshni hai."),
  ]);

  /// Filtered fetch that mirrors FirestoreService.fetchQuestions.
  static Future<List<Question>> fetch({
    String? board,
    String? classLevel,
    String? subject,
    String? chapter,
    String? search,
    int limit = 60,
  }) async {
    final list = _filter(
      board: board,
      classLevel: classLevel,
      subject: subject,
      chapter: chapter,
      search: search,
    );
    return list.take(limit).toList();
  }

  /// Stream version for screens built on watchQuestions.
  static Stream<List<Question>> watch({
    String? board,
    String? classLevel,
    String? subject,
    String? chapter,
    String? search,
  }) {
    return Stream.value(_filter(
      board: board,
      classLevel: classLevel,
      subject: subject,
      chapter: chapter,
      search: search,
    ));
  }

  static List<Question> _filter({
    String? board,
    String? classLevel,
    String? subject,
    String? chapter,
    String? search,
  }) {
    final s = search?.trim().toLowerCase();
    return all.where((q) {
      // Empty board on bundled questions = matches every board.
      if (board != null &&
          board.isNotEmpty &&
          q.board.isNotEmpty &&
          q.board != board) return false;
      if (classLevel != null &&
          classLevel.isNotEmpty &&
          q.classLevel != classLevel) return false;
      if (subject != null && subject.isNotEmpty && q.subject != subject) {
        return false;
      }
      if (chapter != null &&
          chapter.isNotEmpty &&
          !q.chapter.toLowerCase().contains(chapter.toLowerCase())) {
        return false;
      }
      if (s != null && s.isNotEmpty) {
        final haystack = '${q.text} ${q.chapter}'.toLowerCase();
        if (!haystack.contains(s)) return false;
      }
      return true;
    }).toList();
  }
}
