/// App-wide constants: boards, classes, subjects.
class AppConstants {
  static const String appName = 'Quizistan Academy';
  static const String tagline = 'Board ki Tayyari';

  static const List<String> boards = [
    'Lahore',
    'Gujranwala',
    'Rawalpindi',
    'Multan',
    'Faisalabad',
    'Sargodha',
    'Sahiwal',
    'Dera Ghazi Khan',
    'Bahawalpur',
  ];

  static const List<String> classLevels = ['9', '10', '11', '12'];

  static const List<String> subjects = [
    'Urdu',
    'English',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Islamiat',
    'Pak Studies',
    'Tarjuma-tul-Quran',
  ];

  static const int defaultQuestionCount = 10;
  static const int defaultSecondsPerQuestion = 30;
  static const int freeDailyQuizLimit = 5;

  /// 6-character room codes use unambiguous characters only.
  static const String roomCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
}
