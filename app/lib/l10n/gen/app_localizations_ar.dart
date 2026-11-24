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

  @override
  String get navOverview => 'نظرة عامة';

  @override
  String get navSites => 'المواقع';

  @override
  String get navUsers => 'المستخدمون';

  @override
  String get errorSessionExpired => 'انتهت الجلسة. سجّل الدخول مرة أخرى';

  @override
  String get errorDuplicate => 'هذه القيمة مستخدمة من قبل';

  @override
  String get errorForbidden => 'ليست لديك صلاحية لتنفيذ هذا الإجراء';

  @override
  String get errorBusinessRule => 'لا يمكن تنفيذ هذا الإجراء وفق قواعد النظام';

  @override
  String fieldTooLong(int max) {
    return 'يجب ألا يزيد عن $max حرفًا';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get sitesSearchHint => 'ابحث بالرمز أو الاسم';

  @override
  String get sitesFilterActive => 'النشطة';

  @override
  String get sitesFilterArchived => 'المؤرشفة';

  @override
  String get sitesFilterAll => 'الكل';

  @override
  String get sitesEmptyActive => 'لا توجد مواقع نشطة. أضف موقعًا جديدًا';

  @override
  String get sitesEmptyArchived => 'لا توجد مواقع مؤرشفة';

  @override
  String get sitesEmptyAll => 'لا توجد مواقع بعد. أضف موقعًا جديدًا';

  @override
  String get sitesEmptySearch => 'لا توجد مواقع مطابقة للبحث';

  @override
  String get siteActive => 'نشط';

  @override
  String get siteArchived => 'مؤرشف';

  @override
  String get siteAdd => 'إضافة موقع';

  @override
  String get siteAddTitle => 'إضافة موقع جديد';

  @override
  String get siteEditTitle => 'تعديل الموقع';

  @override
  String get siteCodeLabel => 'رمز الموقع';

  @override
  String get siteNameLabel => 'اسم الموقع';

  @override
  String get siteCodeDuplicate => 'رمز الموقع مستخدم لموقع آخر';

  @override
  String get siteCodeLocked => 'لا يمكن تغيير رمز الموقع بعد تسجيل شهادات عليه';

  @override
  String get siteActions => 'خيارات الموقع';

  @override
  String get siteEdit => 'تعديل';

  @override
  String get siteArchive => 'أرشفة';

  @override
  String get siteRestore => 'استعادة';

  @override
  String get siteArchiveConfirmTitle => 'أرشفة الموقع؟';

  @override
  String siteArchiveConfirmBody(String name) {
    return 'سينتقل الموقع «$name» إلى قائمة المواقع المؤرشفة. يمكنك استعادته لاحقًا.';
  }

  @override
  String get usersSearchHint => 'ابحث بالاسم أو البريد الإلكتروني';

  @override
  String get usersEmpty => 'لا يوجد مستخدمون بعد. ادعُ مستخدمًا جديدًا';

  @override
  String get usersEmptySearch => 'لا يوجد مستخدمون مطابقون للبحث';

  @override
  String get userInvite => 'دعوة مستخدم';

  @override
  String get userInviteTitle => 'دعوة مستخدم جديد';

  @override
  String get userEditTitle => 'تعديل المستخدم';

  @override
  String get userRoleLabel => 'الدور';

  @override
  String get userRoleAdmin => 'مسؤول';

  @override
  String get userRoleSiteUser => 'مستخدم موقع';

  @override
  String userSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موقع',
      many: '$count موقعًا',
      few: '$count مواقع',
      two: 'موقعان',
      one: 'موقع واحد',
      zero: 'لا مواقع',
    );
    return '$_temp0';
  }

  @override
  String get userActive => 'نشط';

  @override
  String get userInactive => 'غير نشط';

  @override
  String get userInvitePending => 'دعوة معلّقة';

  @override
  String get userFullNameLabel => 'الاسم الكامل';

  @override
  String get userSitesLabel => 'المواقع';

  @override
  String get userNoSites => 'لا مواقع مسندة';

  @override
  String get userActiveLabel => 'الحساب مفعّل';

  @override
  String get userSelfEditHint => 'لا يمكنك تغيير دورك أو تعطيل حسابك من هنا';

  @override
  String get userExists => 'هذا البريد الإلكتروني مسجّل من قبل';

  @override
  String get inviteInvalidSites => 'بعض المواقع المختارة غير صالحة. أعد المحاولة';

  @override
  String get inviteNotConfigured => 'خدمة الدعوات غير مهيأة. تواصل مع مسؤول النظام';

  @override
  String get lastAdminError => 'لا يمكن تعطيل آخر مسؤول أو تغيير دوره';

  @override
  String get certificateDate => 'تاريخ الشهادة';

  @override
  String get certificateAmount => 'المبلغ';

  @override
  String get certificateNotes => 'ملاحظات';

  @override
  String get certificateStatus => 'الحالة';

  @override
  String get certificateReturnedNote => 'ملاحظة الإرجاع';

  @override
  String get certificateSaveDraft => 'حفظ مسودة';

  @override
  String get certificateSubmit => 'إرسال';

  @override
  String get certificateSignedCopy => 'رفع النسخة الموقّعة';

  @override
  String get attachmentUpload => 'المرفقات';

  @override
  String get attachmentPickImage => 'صورة';

  @override
  String get attachmentPickFile => 'ملف';

  @override
  String get attachmentTooLarge => 'حجم الملف يتجاوز 2 ميجا';

  @override
  String get attachmentDuplicate => 'هذا الملف مرفوع من قبل';
}
