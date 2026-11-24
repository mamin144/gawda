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

  /// No description provided for @errorHasSites.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن ترقية مستخدم مرتبط بمواقع إلى مسؤول. أزل ربط المواقع أولًا'**
  String get errorHasSites;

  /// No description provided for @errorAlreadyDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف هذا العنصر من قبل'**
  String get errorAlreadyDeleted;

  /// No description provided for @errorInvalidTransition.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تنفيذ هذا الإجراء في الحالة الحالية للشهادة'**
  String get errorInvalidTransition;

  /// No description provided for @errorNotFound.
  ///
  /// In ar, this message translates to:
  /// **'العنصر غير موجود'**
  String get errorNotFound;

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

  /// No description provided for @usersSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو البريد الإلكتروني'**
  String get usersSearchHint;

  /// No description provided for @usersEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مستخدمون بعد. ادعُ مستخدمًا جديدًا'**
  String get usersEmpty;

  /// No description provided for @usersEmptySearch.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مستخدمون مطابقون للبحث'**
  String get usersEmptySearch;

  /// No description provided for @userInvite.
  ///
  /// In ar, this message translates to:
  /// **'دعوة مستخدم'**
  String get userInvite;

  /// No description provided for @userInviteTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعوة مستخدم جديد'**
  String get userInviteTitle;

  /// No description provided for @userEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المستخدم'**
  String get userEditTitle;

  /// No description provided for @userRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get userRoleLabel;

  /// No description provided for @userRoleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول'**
  String get userRoleAdmin;

  /// No description provided for @userRoleSiteUser.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم موقع'**
  String get userRoleSiteUser;

  /// No description provided for @userSiteCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{لا مواقع} one{موقع واحد} two{موقعان} few{{count} مواقع} many{{count} موقعًا} other{{count} موقع}}'**
  String userSiteCount(int count);

  /// No description provided for @userActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get userActive;

  /// No description provided for @userInactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get userInactive;

  /// No description provided for @userInvitePending.
  ///
  /// In ar, this message translates to:
  /// **'دعوة معلّقة'**
  String get userInvitePending;

  /// No description provided for @userFullNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get userFullNameLabel;

  /// No description provided for @userSitesLabel.
  ///
  /// In ar, this message translates to:
  /// **'المواقع'**
  String get userSitesLabel;

  /// No description provided for @userNoSites.
  ///
  /// In ar, this message translates to:
  /// **'لا مواقع مسندة'**
  String get userNoSites;

  /// No description provided for @userActiveLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحساب مفعّل'**
  String get userActiveLabel;

  /// No description provided for @userSelfEditHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكنك تغيير دورك أو تعطيل حسابك من هنا'**
  String get userSelfEditHint;

  /// No description provided for @userExists.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد الإلكتروني مسجّل من قبل'**
  String get userExists;

  /// No description provided for @inviteInvalidSites.
  ///
  /// In ar, this message translates to:
  /// **'بعض المواقع المختارة غير صالحة. أعد المحاولة'**
  String get inviteInvalidSites;

  /// No description provided for @inviteNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الدعوات غير مهيأة. تواصل مع مسؤول النظام'**
  String get inviteNotConfigured;

  /// No description provided for @lastAdminError.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تعطيل آخر مسؤول أو تغيير دوره'**
  String get lastAdminError;

  /// No description provided for @certificateDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الشهادة'**
  String get certificateDate;

  /// No description provided for @certificateAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get certificateAmount;

  /// No description provided for @certificateNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get certificateNotes;

  /// No description provided for @certificateStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get certificateStatus;

  /// No description provided for @certificateReturnedNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة الإرجاع'**
  String get certificateReturnedNote;

  /// No description provided for @certificateSaveDraft.
  ///
  /// In ar, this message translates to:
  /// **'حفظ مسودة'**
  String get certificateSaveDraft;

  /// No description provided for @certificateSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get certificateSubmit;

  /// No description provided for @certificateSignedCopy.
  ///
  /// In ar, this message translates to:
  /// **'رفع النسخة الموقّعة'**
  String get certificateSignedCopy;

  /// No description provided for @attachmentUpload.
  ///
  /// In ar, this message translates to:
  /// **'المرفقات'**
  String get attachmentUpload;

  /// No description provided for @attachmentPickImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get attachmentPickImage;

  /// No description provided for @attachmentPickFile.
  ///
  /// In ar, this message translates to:
  /// **'ملف'**
  String get attachmentPickFile;

  /// No description provided for @attachmentTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'حجم الملف يتجاوز 2 ميجا'**
  String get attachmentTooLarge;

  /// No description provided for @attachmentDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'هذا الملف مرفوع من قبل'**
  String get attachmentDuplicate;

  /// No description provided for @siteTabDashboard.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get siteTabDashboard;

  /// No description provided for @siteTabEntry.
  ///
  /// In ar, this message translates to:
  /// **'إدخال'**
  String get siteTabEntry;

  /// No description provided for @siteTabRecords.
  ///
  /// In ar, this message translates to:
  /// **'السجلات'**
  String get siteTabRecords;

  /// No description provided for @siteTabAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get siteTabAccount;

  /// No description provided for @certificatePeriod.
  ///
  /// In ar, this message translates to:
  /// **'فترة الشهادة'**
  String get certificatePeriod;

  /// No description provided for @noCertificates.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد شهادات بعد'**
  String get noCertificates;

  /// No description provided for @certificateRecords.
  ///
  /// In ar, this message translates to:
  /// **'سجل الشهادات'**
  String get certificateRecords;

  /// No description provided for @statusDraft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get statusDraft;

  /// No description provided for @statusInReview.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get statusInReview;

  /// No description provided for @statusReturned.
  ///
  /// In ar, this message translates to:
  /// **'مُعادة للتعديل'**
  String get statusReturned;

  /// No description provided for @statusAwaitingSignature.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار التوقيع'**
  String get statusAwaitingSignature;

  /// No description provided for @statusApproved.
  ///
  /// In ar, this message translates to:
  /// **'معتمدة'**
  String get statusApproved;

  /// No description provided for @periodLabel.
  ///
  /// In ar, this message translates to:
  /// **'{year}-{month} (النصف {half})'**
  String periodLabel(int year, String month, int half);

  /// No description provided for @attachmentPickCamera.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا'**
  String get attachmentPickCamera;

  /// No description provided for @attachmentPickGallery.
  ///
  /// In ar, this message translates to:
  /// **'المعرض'**
  String get attachmentPickGallery;

  /// No description provided for @attachmentKindInitial.
  ///
  /// In ar, this message translates to:
  /// **'مرفق أولي'**
  String get attachmentKindInitial;

  /// No description provided for @attachmentKindSigned.
  ///
  /// In ar, this message translates to:
  /// **'نسخة موقّعة'**
  String get attachmentKindSigned;

  /// No description provided for @attachmentTypeNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'نوع الملف غير مسموح. المسموح: PDF أو JPG أو PNG'**
  String get attachmentTypeNotAllowed;

  /// No description provided for @attachmentUploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ رفع الملف...'**
  String get attachmentUploading;

  /// No description provided for @attachmentRemove.
  ///
  /// In ar, this message translates to:
  /// **'حذف المرفق'**
  String get attachmentRemove;

  /// No description provided for @attachmentRemoveConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف المرفق؟'**
  String get attachmentRemoveConfirmTitle;

  /// No description provided for @attachmentRemoveConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف «{name}» من هذه الشهادة.'**
  String attachmentRemoveConfirmBody(String name);

  /// No description provided for @certificateDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف الشهادة'**
  String get certificateDelete;

  /// No description provided for @certificateDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الشهادة؟'**
  String get certificateDeleteConfirmTitle;

  /// No description provided for @certificateDeleteConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف هذه المسودة ومرفقاتها.'**
  String get certificateDeleteConfirmBody;

  /// No description provided for @certificateDraftSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ المسودة'**
  String get certificateDraftSaved;

  /// No description provided for @certificateAmountInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغًا صحيحًا بحد أقصى منزلتين عشريتين'**
  String get certificateAmountInvalid;

  /// No description provided for @deleteButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteButton;
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
