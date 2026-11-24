import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'نظام متابعة الجودة المالية للمواقع'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginButton;

  /// No description provided for @logoutButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutButton;

  /// No description provided for @fieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدًا إلكترونيًا صحيحًا'**
  String get invalidEmail;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get errorInvalidCredentials;

  /// No description provided for @errorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في الخادم. حاول مرة أخرى لاحقًا'**
  String get errorServer;

  /// No description provided for @errorUnexpected.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get errorUnexpected;

  /// No description provided for @errorAccountInactive.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب غير مفعّل. تواصل مع المسؤول'**
  String get errorAccountInactive;

  /// No description provided for @errorConfig.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التطبيق غير مكتملة. تواصل مع المسؤول'**
  String get errorConfig;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get loading;

  /// No description provided for @emptyDefault.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get emptyDefault;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @adminHomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المسؤول'**
  String get adminHomeTitle;

  /// No description provided for @siteHomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الموقع'**
  String get siteHomeTitle;

  /// No description provided for @welcomeUser.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا، {name}'**
  String welcomeUser(String name);

  /// No description provided for @navOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة'**
  String get navOverview;

  /// No description provided for @navSites.
  ///
  /// In ar, this message translates to:
  /// **'المواقع'**
  String get navSites;

  /// No description provided for @navUsers.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get navUsers;

  /// No description provided for @errorSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة. سجّل الدخول مرة أخرى'**
  String get errorSessionExpired;

  /// No description provided for @errorDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'هذه القيمة مستخدمة من قبل'**
  String get errorDuplicate;

  /// No description provided for @errorForbidden.
  ///
  /// In ar, this message translates to:
  /// **'ليست لديك صلاحية لتنفيذ هذا الإجراء'**
  String get errorForbidden;

  /// No description provided for @errorBusinessRule.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تنفيذ هذا الإجراء وفق قواعد النظام'**
  String get errorBusinessRule;

  /// No description provided for @fieldTooLong.
  ///
  /// In ar, this message translates to:
  /// **'يجب ألا يزيد عن {max} حرفًا'**
  String fieldTooLong(int max);

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @sitesSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالرمز أو الاسم'**
  String get sitesSearchHint;

  /// No description provided for @sitesFilterActive.
  ///
  /// In ar, this message translates to:
  /// **'النشطة'**
  String get sitesFilterActive;

  /// No description provided for @sitesFilterArchived.
  ///
  /// In ar, this message translates to:
  /// **'المؤرشفة'**
  String get sitesFilterArchived;

  /// No description provided for @sitesFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get sitesFilterAll;

  /// No description provided for @sitesEmptyActive.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواقع نشطة. أضف موقعًا جديدًا'**
  String get sitesEmptyActive;

  /// No description provided for @sitesEmptyArchived.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواقع مؤرشفة'**
  String get sitesEmptyArchived;

  /// No description provided for @sitesEmptyAll.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواقع بعد. أضف موقعًا جديدًا'**
  String get sitesEmptyAll;

  /// No description provided for @sitesEmptySearch.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواقع مطابقة للبحث'**
  String get sitesEmptySearch;

  /// No description provided for @siteActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get siteActive;

  /// No description provided for @siteArchived.
  ///
  /// In ar, this message translates to:
  /// **'مؤرشف'**
  String get siteArchived;

  /// No description provided for @siteAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موقع'**
  String get siteAdd;

  /// No description provided for @siteAddTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موقع جديد'**
  String get siteAddTitle;

  /// No description provided for @siteEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الموقع'**
  String get siteEditTitle;

  /// No description provided for @siteCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز الموقع'**
  String get siteCodeLabel;

  /// No description provided for @siteNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الموقع'**
  String get siteNameLabel;

  /// No description provided for @siteCodeDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'رمز الموقع مستخدم لموقع آخر'**
  String get siteCodeDuplicate;

  /// No description provided for @siteCodeLocked.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تغيير رمز الموقع بعد تسجيل شهادات عليه'**
  String get siteCodeLocked;

  /// No description provided for @siteActions.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الموقع'**
  String get siteActions;

  /// No description provided for @siteEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get siteEdit;

  /// No description provided for @siteArchive.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة'**
  String get siteArchive;

  /// No description provided for @siteRestore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get siteRestore;

  /// No description provided for @siteArchiveConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة الموقع؟'**
  String get siteArchiveConfirmTitle;

  /// No description provided for @siteArchiveConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'سينتقل الموقع «{name}» إلى قائمة المواقع المؤرشفة. يمكنك استعادته لاحقًا.'**
  String siteArchiveConfirmBody(String name);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
