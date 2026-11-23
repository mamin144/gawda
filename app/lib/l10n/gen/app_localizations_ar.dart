// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام متابعة الجودة المالية للمواقع';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get loginButton => 'دخول';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get invalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get errorInvalidCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get errorNetwork => 'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت';

  @override
  String get errorServer => 'حدث خطأ في الخادم. حاول مرة أخرى لاحقًا';

  @override
  String get errorUnexpected => 'حدث خطأ غير متوقع';

  @override
  String get errorAccountInactive => 'هذا الحساب غير مفعّل. تواصل مع المسؤول';

  @override
  String get errorConfig => 'إعدادات التطبيق غير مكتملة. تواصل مع المسؤول';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get emptyDefault => 'لا توجد بيانات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get adminHomeTitle => 'لوحة المسؤول';

  @override
  String get siteHomeTitle => 'لوحة الموقع';

  @override
  String welcomeUser(String name) {
    return 'مرحبًا، $name';
  }
}
