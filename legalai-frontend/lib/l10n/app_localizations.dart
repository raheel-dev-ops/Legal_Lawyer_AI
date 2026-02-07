import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @ageOptional.
  ///
  /// In en, this message translates to:
  /// **'Age (optional)'**
  String get ageOptional;

  /// No description provided for @aiLegalAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Legal Assistant'**
  String get aiLegalAssistant;

  /// No description provided for @alreadyHaveToken.
  ///
  /// In en, this message translates to:
  /// **'Already have a reset token?'**
  String get alreadyHaveToken;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal AI Lawyer'**
  String get appTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Language'**
  String get appearanceLanguage;

  /// No description provided for @askLegalQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a legal question'**
  String get askLegalQuestion;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @bookmarksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved items and documents'**
  String get bookmarksSubtitle;

  /// No description provided for @brothers.
  ///
  /// In en, this message translates to:
  /// **'Brothers'**
  String get brothers;

  /// No description provided for @browseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Browse Library'**
  String get browseLibrary;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @checklists.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get checklists;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @cityOptional.
  ///
  /// In en, this message translates to:
  /// **'City (optional)'**
  String get cityOptional;

  /// No description provided for @cnic.
  ///
  /// In en, this message translates to:
  /// **'CNIC'**
  String get cnic;

  /// No description provided for @cnicRequired.
  ///
  /// In en, this message translates to:
  /// **'CNIC is required'**
  String get cnicRequired;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required'**
  String get confirmPasswordRequired;

  /// No description provided for @conflictDetected.
  ///
  /// In en, this message translates to:
  /// **'Conflict detected'**
  String get conflictDetected;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @conversationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get conversationDeleted;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdLabel;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get deleteDraft;

  /// No description provided for @deleteDraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this draft?'**
  String get deleteDraftConfirm;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @draftsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate and manage drafts'**
  String get draftsSubtitle;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailPlaceholder;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailVerifiedFail.
  ///
  /// In en, this message translates to:
  /// **'Email verification failed'**
  String get emailVerifiedFail;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerifiedSuccess;

  /// No description provided for @emergencyExit.
  ///
  /// In en, this message translates to:
  /// **'Emergency Exit'**
  String get emergencyExit;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(Object message);

  /// No description provided for @exportCanceled.
  ///
  /// In en, this message translates to:
  /// **'Export canceled'**
  String get exportCanceled;

  /// No description provided for @exportDocx.
  ///
  /// In en, this message translates to:
  /// **'Export DOCX'**
  String get exportDocx;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportTxt.
  ///
  /// In en, this message translates to:
  /// **'Export TXT'**
  String get exportTxt;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @familyDetails.
  ///
  /// In en, this message translates to:
  /// **'Family Details'**
  String get familyDetails;

  /// No description provided for @fatherCnic.
  ///
  /// In en, this message translates to:
  /// **'Father\'s CNIC'**
  String get fatherCnic;

  /// No description provided for @fatherName.
  ///
  /// In en, this message translates to:
  /// **'Father\'s name'**
  String get fatherName;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted'**
  String get feedbackSubmitted;

  /// No description provided for @findLawyer.
  ///
  /// In en, this message translates to:
  /// **'Find a Lawyer'**
  String get findLawyer;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry! It happens. Please enter the email address associated with your account to receive a reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderOptional.
  ///
  /// In en, this message translates to:
  /// **'Gender (optional)'**
  String get genderOptional;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @generateDraft.
  ///
  /// In en, this message translates to:
  /// **'Generate Draft'**
  String get generateDraft;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @invalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request'**
  String get invalidRequest;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get languageUrdu;

  /// No description provided for @lawyerDetails.
  ///
  /// In en, this message translates to:
  /// **'Lawyer Details'**
  String get lawyerDetails;

  /// No description provided for @lawyers.
  ///
  /// In en, this message translates to:
  /// **'Lawyers'**
  String get lawyers;

  /// No description provided for @lawyersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find legal experts'**
  String get lawyersSubtitle;

  /// No description provided for @legalChecklists.
  ///
  /// In en, this message translates to:
  /// **'Legal Checklists'**
  String get legalChecklists;

  /// No description provided for @legalLibrary.
  ///
  /// In en, this message translates to:
  /// **'Legal Library'**
  String get legalLibrary;

  /// No description provided for @legalPathway.
  ///
  /// In en, this message translates to:
  /// **'Legal Pathway'**
  String get legalPathway;

  /// No description provided for @legalRight.
  ///
  /// In en, this message translates to:
  /// **'Legal Right'**
  String get legalRight;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @googleSignInNoPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is not required for Google sign-in.'**
  String get googleSignInNoPassword;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get messageSent;

  /// No description provided for @motherCnic.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s CNIC'**
  String get motherCnic;

  /// No description provided for @motherName.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s name'**
  String get motherName;

  /// No description provided for @myDrafts.
  ///
  /// In en, this message translates to:
  /// **'My Drafts'**
  String get myDrafts;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @newDraft.
  ///
  /// In en, this message translates to:
  /// **'New Draft'**
  String get newDraft;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different'**
  String get newPasswordDifferent;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get newReminder;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivity;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarks;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversations;

  /// No description provided for @noDateSelected.
  ///
  /// In en, this message translates to:
  /// **'No date selected'**
  String get noDateSelected;

  /// No description provided for @noDrafts.
  ///
  /// In en, this message translates to:
  /// **'No drafts yet'**
  String get noDrafts;

  /// No description provided for @noFieldsDetected.
  ///
  /// In en, this message translates to:
  /// **'No fields detected'**
  String get noFieldsDetected;

  /// No description provided for @noLawyersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lawyers available'**
  String get noLawyersAvailable;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders'**
  String get noReminders;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @onboardingCardRightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instantly access constitutional rights and legal protections designed for you.'**
  String get onboardingCardRightsSubtitle;

  /// No description provided for @onboardingCardRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Know Your Rights'**
  String get onboardingCardRightsTitle;

  /// No description provided for @onboardingFeatureChecklistsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step guides for procedures'**
  String get onboardingFeatureChecklistsSubtitle;

  /// No description provided for @onboardingFeatureChecklistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Checklists'**
  String get onboardingFeatureChecklistsTitle;

  /// No description provided for @onboardingFeatureLawyersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find verified legal experts near you'**
  String get onboardingFeatureLawyersSubtitle;

  /// No description provided for @onboardingFeatureLawyersTitle.
  ///
  /// In en, this message translates to:
  /// **'Lawyers Directory'**
  String get onboardingFeatureLawyersTitle;

  /// No description provided for @onboardingFeatureRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss a court date or consultation'**
  String get onboardingFeatureRemindersSubtitle;

  /// No description provided for @onboardingFeatureRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Reminders'**
  String get onboardingFeatureRemindersTitle;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Navigate the complexities of Pakistani law with ease. Ask questions in Urdu or English and get immediate, confidential guidance.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Empower your legal journey with the right tools and people beside you.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Navigate the legal system with confidence. Explore your rights, generate legal documents, and find clear pathways to justice.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Instant Legal Answers'**
  String get onboardingTitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Connect & Organize'**
  String get onboardingTitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Empower Your Rights'**
  String get onboardingTitle3;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful'**
  String get passwordResetSuccess;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'Use 8+ characters with a number and a symbol'**
  String get passwordRule;

  /// No description provided for @passwordRuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleNumber.
  ///
  /// In en, this message translates to:
  /// **'Contains a number'**
  String get passwordRuleNumber;

  /// No description provided for @passwordRuleSpecial.
  ///
  /// In en, this message translates to:
  /// **'Contains a special character'**
  String get passwordRuleSpecial;

  /// No description provided for @passwordStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get passwordStrengthLabel;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pathways.
  ///
  /// In en, this message translates to:
  /// **'Pathways'**
  String get pathways;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneRequired;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @pleaseLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Please log in again'**
  String get pleaseLoginAgain;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @preferencesNote.
  ///
  /// In en, this message translates to:
  /// **'Changes apply immediately'**
  String get preferencesNote;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @rememberPassword.
  ///
  /// In en, this message translates to:
  /// **'Remember your password?'**
  String get rememberPassword;

  /// No description provided for @reenterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reenterPasswordHint;

  /// No description provided for @profilePhotoUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile photo update failed'**
  String get profilePhotoUpdateFailed;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @provinceBalochistan.
  ///
  /// In en, this message translates to:
  /// **'Balochistan'**
  String get provinceBalochistan;

  /// No description provided for @provinceIct.
  ///
  /// In en, this message translates to:
  /// **'Islamabad Capital Territory'**
  String get provinceIct;

  /// No description provided for @provinceKp.
  ///
  /// In en, this message translates to:
  /// **'Khyber Pakhtunkhwa'**
  String get provinceKp;

  /// No description provided for @provincePunjab.
  ///
  /// In en, this message translates to:
  /// **'Punjab'**
  String get provincePunjab;

  /// No description provided for @provinceRequired.
  ///
  /// In en, this message translates to:
  /// **'Province is required'**
  String get provinceRequired;

  /// No description provided for @provinceSindh.
  ///
  /// In en, this message translates to:
  /// **'Sindh'**
  String get provinceSindh;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @rateExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateExperience;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of deadlines'**
  String get remindersSubtitle;

  /// No description provided for @renameConversation.
  ///
  /// In en, this message translates to:
  /// **'Rename conversation'**
  String get renameConversation;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent'**
  String get resetLinkSent;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordHeadline.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get resetPasswordHeadline;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please create a strong password to protect your legal data.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetToken.
  ///
  /// In en, this message translates to:
  /// **'Reset token'**
  String get resetToken;

  /// No description provided for @rights.
  ///
  /// In en, this message translates to:
  /// **'Rights'**
  String get rights;

  /// No description provided for @safeMode.
  ///
  /// In en, this message translates to:
  /// **'Safe Mode'**
  String get safeMode;

  /// No description provided for @safeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Hide sensitive content and enable quick exit'**
  String get safeModeDescription;

  /// No description provided for @safeModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Safe Mode enabled'**
  String get safeModeEnabled;

  /// No description provided for @safeModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Safe Mode disabled'**
  String get safeModeDisabled;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @savedFile.
  ///
  /// In en, this message translates to:
  /// **'Saved {filename}'**
  String savedFile(Object filename);

  /// No description provided for @savedItem.
  ///
  /// In en, this message translates to:
  /// **'Saved Item'**
  String get savedItem;

  /// No description provided for @voiceInputSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'LLM Settings'**
  String get voiceInputSettingsTitle;

  /// No description provided for @voiceInputSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure voice provider, chat model, and API keys.'**
  String get voiceInputSettingsSubtitle;

  /// No description provided for @llmVoiceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice provider'**
  String get llmVoiceSectionTitle;

  /// No description provided for @llmChatSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat LLM'**
  String get llmChatSectionTitle;

  /// No description provided for @voiceProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice provider'**
  String get voiceProviderLabel;

  /// No description provided for @voiceProviderAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (OpenAI -> OpenRouter -> Groq)'**
  String get voiceProviderAuto;

  /// No description provided for @voiceProviderOpenai.
  ///
  /// In en, this message translates to:
  /// **'OpenAI'**
  String get voiceProviderOpenai;

  /// No description provided for @voiceProviderOpenrouter.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter'**
  String get voiceProviderOpenrouter;

  /// No description provided for @voiceProviderGroq.
  ///
  /// In en, this message translates to:
  /// **'Groq Cloud'**
  String get voiceProviderGroq;

  /// No description provided for @voiceProviderAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Select a voice provider and model for transcription.'**
  String get voiceProviderAutoNote;

  /// No description provided for @voiceModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice model'**
  String get voiceModelLabel;

  /// No description provided for @chatProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat provider'**
  String get chatProviderLabel;

  /// No description provided for @chatModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat model'**
  String get chatModelLabel;

  /// No description provided for @showApiKeyField.
  ///
  /// In en, this message translates to:
  /// **'Show API key field'**
  String get showApiKeyField;

  /// No description provided for @hideApiKeyField.
  ///
  /// In en, this message translates to:
  /// **'Hide API key field'**
  String get hideApiKeyField;

  /// No description provided for @providerDeepseek.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek'**
  String get providerDeepseek;

  /// No description provided for @providerGrok.
  ///
  /// In en, this message translates to:
  /// **'Grok (xAI)'**
  String get providerGrok;

  /// No description provided for @providerAnthropic.
  ///
  /// In en, this message translates to:
  /// **'Anthropic'**
  String get providerAnthropic;

  /// No description provided for @openaiApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API key'**
  String get openaiApiKeyLabel;

  /// No description provided for @openrouterApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter API key'**
  String get openrouterApiKeyLabel;

  /// No description provided for @groqApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Groq API key'**
  String get groqApiKeyLabel;

  /// No description provided for @deepseekApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek API key'**
  String get deepseekApiKeyLabel;

  /// No description provided for @grokApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Grok API key'**
  String get grokApiKeyLabel;

  /// No description provided for @anthropicApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Anthropic API key'**
  String get anthropicApiKeyLabel;

  /// No description provided for @voiceApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your API key'**
  String get voiceApiKeyHint;

  /// No description provided for @voiceSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'LLM settings saved'**
  String get voiceSettingsSaved;

  /// No description provided for @voicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied.'**
  String get voicePermissionDenied;

  /// No description provided for @voiceRecordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to record audio. Please try again.'**
  String get voiceRecordingFailed;

  /// No description provided for @voiceNoSpeechDetected.
  ///
  /// In en, this message translates to:
  /// **'No speech detected. Please try again.'**
  String get voiceNoSpeechDetected;

  /// No description provided for @scheduleDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select date and time'**
  String get scheduleDateTime;

  /// No description provided for @securePrivate.
  ///
  /// In en, this message translates to:
  /// **'Secure and Private'**
  String get securePrivate;

  /// No description provided for @selectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select Template'**
  String get selectTemplate;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @sisters.
  ///
  /// In en, this message translates to:
  /// **'Sisters'**
  String get sisters;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your legal assistant for everyday needs'**
  String get splashSubtitle;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal AI Lawyer'**
  String get splashTitle;

  /// No description provided for @suggestedLawyers.
  ///
  /// In en, this message translates to:
  /// **'Suggested lawyers'**
  String get suggestedLawyers;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get startChat;

  /// No description provided for @stepWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Step {step}: {title}'**
  String stepWithTitle(Object step, Object title);

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit feedback'**
  String get submitFeedback;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportFeedback.
  ///
  /// In en, this message translates to:
  /// **'Support & Feedback'**
  String get supportFeedback;

  /// No description provided for @supportHintPrefix.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t receive an email within a few minutes, please check your spam folder or contact '**
  String get supportHintPrefix;

  /// No description provided for @supportHintSuffix.
  ///
  /// In en, this message translates to:
  /// **' for assistance.'**
  String get supportHintSuffix;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @tapToViewSteps.
  ///
  /// In en, this message translates to:
  /// **'Tap to view steps'**
  String get tapToViewSteps;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @tokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Reset token is required'**
  String get tokenRequired;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get tooManyRequests;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @totalSiblings.
  ///
  /// In en, this message translates to:
  /// **'Total siblings'**
  String get totalSiblings;

  /// No description provided for @typeYourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Type your question'**
  String get typeYourQuestion;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get unexpectedError;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @userInitialFallback.
  ///
  /// In en, this message translates to:
  /// **'U'**
  String get userInitialFallback;

  /// No description provided for @validNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get validNumber;

  /// No description provided for @verificationToken.
  ///
  /// In en, this message translates to:
  /// **'Verification token'**
  String get verificationToken;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Assalam-o-Alaikum,'**
  String get dashboardGreeting;

  /// No description provided for @dashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search laws or rights...'**
  String get dashboardSearchHint;

  /// No description provided for @sosLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosLabel;

  /// No description provided for @aiPoweredBadge.
  ///
  /// In en, this message translates to:
  /// **'AI POWERED ASSISTANT'**
  String get aiPoweredBadge;

  /// No description provided for @aiAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get instant professional guidance in Urdu & English.'**
  String get aiAssistantSubtitle;

  /// No description provided for @startNewChat.
  ///
  /// In en, this message translates to:
  /// **'Start New Chat'**
  String get startNewChat;

  /// No description provided for @legalToolboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Toolbox'**
  String get legalToolboxTitle;

  /// No description provided for @dashboardItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String dashboardItemsCount(Object count);

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get dashboardHistory;

  /// No description provided for @legalRights.
  ///
  /// In en, this message translates to:
  /// **'Legal Rights'**
  String get legalRights;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @activityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get activityHistory;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String timeMinutesAgo(Object count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String timeHoursAgo(Object count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String timeDaysAgo(Object count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search sections'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;

  /// No description provided for @emergencyServices.
  ///
  /// In en, this message translates to:
  /// **'Emergency Services'**
  String get emergencyServices;

  /// No description provided for @emergencyServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SOS and contacts'**
  String get emergencyServicesSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @emergencyServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Services'**
  String get emergencyServicesTitle;

  /// No description provided for @sendSosMessage.
  ///
  /// In en, this message translates to:
  /// **'Send SOS Message'**
  String get sendSosMessage;

  /// No description provided for @sendSosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens SMS to your emergency contacts'**
  String get sendSosSubtitle;

  /// No description provided for @policeService.
  ///
  /// In en, this message translates to:
  /// **'Police ({number})'**
  String policeService(Object number);

  /// No description provided for @womenHelplineService.
  ///
  /// In en, this message translates to:
  /// **'Women ({number})'**
  String womenHelplineService(Object number);

  /// No description provided for @cyberCrimeService.
  ///
  /// In en, this message translates to:
  /// **'Cyber Crime ({number})'**
  String cyberCrimeService(Object number);

  /// No description provided for @rescueService.
  ///
  /// In en, this message translates to:
  /// **'Rescue ({number})'**
  String rescueService(Object number);

  /// No description provided for @emergencyImmediateResponse.
  ///
  /// In en, this message translates to:
  /// **'Immediate Response'**
  String get emergencyImmediateResponse;

  /// No description provided for @emergencyProtectionServices.
  ///
  /// In en, this message translates to:
  /// **'Protection Services'**
  String get emergencyProtectionServices;

  /// No description provided for @emergencyDigitalSafety.
  ///
  /// In en, this message translates to:
  /// **'Digital Safety'**
  String get emergencyDigitalSafety;

  /// No description provided for @emergencyMedicalAssistance.
  ///
  /// In en, this message translates to:
  /// **'Medical Emergency'**
  String get emergencyMedicalAssistance;

  /// No description provided for @personalEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Personal Emergency Contacts'**
  String get personalEmergencyContacts;

  /// No description provided for @noContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get noContactsYet;

  /// No description provided for @emergencyTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Safety Tips'**
  String get emergencyTipsTitle;

  /// No description provided for @emergencyTip1.
  ///
  /// In en, this message translates to:
  /// **'Move to a well-lit area or a public place with people nearby.'**
  String get emergencyTip1;

  /// No description provided for @emergencyTip2.
  ///
  /// In en, this message translates to:
  /// **'Share your live location with a trusted group.'**
  String get emergencyTip2;

  /// No description provided for @emergencyTip3.
  ///
  /// In en, this message translates to:
  /// **'Keep your phone in hand but concealed if you feel followed.'**
  String get emergencyTip3;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @sosNoContacts.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contacts first'**
  String get sosNoContacts;

  /// No description provided for @primaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primaryLabel;

  /// No description provided for @relationLabel.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get relationLabel;

  /// No description provided for @countryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get countryCodeLabel;

  /// No description provided for @maxContactsReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 5 contacts'**
  String get maxContactsReached;

  /// No description provided for @newContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get newContactTitle;

  /// No description provided for @editContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact'**
  String get editContactTitle;

  /// No description provided for @saveContact.
  ///
  /// In en, this message translates to:
  /// **'Save Contact'**
  String get saveContact;

  /// No description provided for @invalidCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid country code'**
  String get invalidCountryCode;

  /// No description provided for @deleteContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get deleteContactTitle;

  /// No description provided for @deleteContactConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this contact?'**
  String get deleteContactConfirm;

  /// No description provided for @adminConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Console'**
  String get adminConsoleTitle;

  /// No description provided for @adminLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminLabel;

  /// No description provided for @adminNavOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminNavOverview;

  /// No description provided for @adminNavUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminNavUsers;

  /// No description provided for @adminNavLawyers.
  ///
  /// In en, this message translates to:
  /// **'Lawyers'**
  String get adminNavLawyers;

  /// No description provided for @adminNavKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get adminNavKnowledge;

  /// No description provided for @adminNavRights.
  ///
  /// In en, this message translates to:
  /// **'Rights'**
  String get adminNavRights;

  /// No description provided for @adminNavTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get adminNavTemplates;

  /// No description provided for @adminNavPathways.
  ///
  /// In en, this message translates to:
  /// **'Pathways'**
  String get adminNavPathways;

  /// No description provided for @adminNavChecklists.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get adminNavChecklists;

  /// No description provided for @adminNavContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get adminNavContact;

  /// No description provided for @adminNavFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get adminNavFeedback;

  /// No description provided for @adminNavRag.
  ///
  /// In en, this message translates to:
  /// **'RAG'**
  String get adminNavRag;

  /// No description provided for @adminNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminNavSettings;

  /// No description provided for @adminNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminNavDashboard;

  /// No description provided for @adminConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get adminConfiguration;

  /// No description provided for @adminRoleSeniorLegalAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Senior Legal Administrator'**
  String get adminRoleSeniorLegalAdministrator;

  /// No description provided for @adminRoleSystemAdministrator.
  ///
  /// In en, this message translates to:
  /// **'System Administrator'**
  String get adminRoleSystemAdministrator;

  /// No description provided for @adminUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control access and manage user accounts'**
  String get adminUsersSubtitle;

  /// No description provided for @adminNewUser.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get adminNewUser;

  /// No description provided for @adminNoUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'No users yet'**
  String get adminNoUsersTitle;

  /// No description provided for @adminNoUsersMessage.
  ///
  /// In en, this message translates to:
  /// **'Create the first user to get started.'**
  String get adminNoUsersMessage;

  /// No description provided for @adminUnnamedUser.
  ///
  /// In en, this message translates to:
  /// **'Unnamed User'**
  String get adminUnnamedUser;

  /// No description provided for @adminRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleAdmin;

  /// No description provided for @adminStatusDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get adminStatusDeleted;

  /// No description provided for @adminCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get adminCreateUser;

  /// No description provided for @adminEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get adminEditUser;

  /// No description provided for @adminNewPasswordOptional.
  ///
  /// In en, this message translates to:
  /// **'New Password (optional)'**
  String get adminNewPasswordOptional;

  /// No description provided for @adminAllFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get adminAllFieldsRequired;

  /// No description provided for @adminPasswordRuleStrict.
  ///
  /// In en, this message translates to:
  /// **'Password must be 8+ chars with uppercase, lowercase, and a special character'**
  String get adminPasswordRuleStrict;

  /// No description provided for @adminNamePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and phone are required'**
  String get adminNamePhoneRequired;

  /// No description provided for @adminDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get adminDeleteUserTitle;

  /// No description provided for @adminDeleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user?'**
  String get adminDeleteUserConfirm;

  /// No description provided for @adminLawyersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage verified lawyers and profiles'**
  String get adminLawyersSubtitle;

  /// No description provided for @adminNewLawyer.
  ///
  /// In en, this message translates to:
  /// **'New Lawyer'**
  String get adminNewLawyer;

  /// No description provided for @adminNoLawyersTitle.
  ///
  /// In en, this message translates to:
  /// **'No lawyers yet'**
  String get adminNoLawyersTitle;

  /// No description provided for @adminNoLawyersMessage.
  ///
  /// In en, this message translates to:
  /// **'Add lawyers to populate the directory.'**
  String get adminNoLawyersMessage;

  /// No description provided for @adminStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminStatusActive;

  /// No description provided for @adminStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminStatusInactive;

  /// No description provided for @adminDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get adminDeactivate;

  /// No description provided for @adminCreateLawyer.
  ///
  /// In en, this message translates to:
  /// **'Create Lawyer'**
  String get adminCreateLawyer;

  /// No description provided for @adminEditLawyer.
  ///
  /// In en, this message translates to:
  /// **'Edit Lawyer'**
  String get adminEditLawyer;

  /// No description provided for @adminSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get adminSelectImage;

  /// No description provided for @adminChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get adminChangeImage;

  /// No description provided for @adminProfilePictureRequired.
  ///
  /// In en, this message translates to:
  /// **'Profile picture is required'**
  String get adminProfilePictureRequired;

  /// No description provided for @adminDeactivateLawyerTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Lawyer'**
  String get adminDeactivateLawyerTitle;

  /// No description provided for @adminDeactivateLawyerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this lawyer?'**
  String get adminDeactivateLawyerConfirm;

  /// No description provided for @adminImageTypeNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only JPG and PNG images are allowed'**
  String get adminImageTypeNotAllowed;

  /// No description provided for @adminImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image too large (max 5MB)'**
  String get adminImageTooLarge;

  /// No description provided for @adminImageDataMissing.
  ///
  /// In en, this message translates to:
  /// **'Image data is missing'**
  String get adminImageDataMissing;

  /// No description provided for @adminKnowledgeBase.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Base'**
  String get adminKnowledgeBase;

  /// No description provided for @adminKnowledgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage RAG sources and ingestion pipeline'**
  String get adminKnowledgeSubtitle;

  /// No description provided for @adminAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add Source'**
  String get adminAddSource;

  /// No description provided for @adminNoSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'No sources yet'**
  String get adminNoSourcesTitle;

  /// No description provided for @adminNoSourcesMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a URL or upload a file to start ingestion.'**
  String get adminNoSourcesMessage;

  /// No description provided for @adminAddKnowledgeSource.
  ///
  /// In en, this message translates to:
  /// **'Add Knowledge Source'**
  String get adminAddKnowledgeSource;

  /// No description provided for @adminUrlSource.
  ///
  /// In en, this message translates to:
  /// **'URL Source'**
  String get adminUrlSource;

  /// No description provided for @adminFileUpload.
  ///
  /// In en, this message translates to:
  /// **'File Upload'**
  String get adminFileUpload;

  /// No description provided for @adminUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get adminUrl;

  /// No description provided for @adminSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get adminSelectFile;

  /// No description provided for @adminChangeFile.
  ///
  /// In en, this message translates to:
  /// **'Change File'**
  String get adminChangeFile;

  /// No description provided for @adminTitleUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and URL are required'**
  String get adminTitleUrlRequired;

  /// No description provided for @adminInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL'**
  String get adminInvalidUrl;

  /// No description provided for @adminFileRequired.
  ///
  /// In en, this message translates to:
  /// **'File is required'**
  String get adminFileRequired;

  /// No description provided for @adminIngest.
  ///
  /// In en, this message translates to:
  /// **'Ingest'**
  String get adminIngest;

  /// No description provided for @adminStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminStatusDone;

  /// No description provided for @adminStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get adminStatusFailed;

  /// No description provided for @adminStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get adminStatusProcessing;

  /// No description provided for @adminFileTypeNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'File type not allowed'**
  String get adminFileTypeNotAllowed;

  /// No description provided for @adminFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large (max 30MB)'**
  String get adminFileTooLarge;

  /// No description provided for @adminFileDataMissing.
  ///
  /// In en, this message translates to:
  /// **'File data is missing'**
  String get adminFileDataMissing;

  /// No description provided for @adminRightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage legal rights library'**
  String get adminRightsSubtitle;

  /// No description provided for @adminNewRight.
  ///
  /// In en, this message translates to:
  /// **'New Right'**
  String get adminNewRight;

  /// No description provided for @adminNoRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'No rights yet'**
  String get adminNoRightsTitle;

  /// No description provided for @adminNoRightsMessage.
  ///
  /// In en, this message translates to:
  /// **'Create the first right to populate the library.'**
  String get adminNoRightsMessage;

  /// No description provided for @adminCreateRight.
  ///
  /// In en, this message translates to:
  /// **'Create Right'**
  String get adminCreateRight;

  /// No description provided for @adminEditRight.
  ///
  /// In en, this message translates to:
  /// **'Edit Right'**
  String get adminEditRight;

  /// No description provided for @adminTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get adminTopic;

  /// No description provided for @adminBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get adminBody;

  /// No description provided for @adminTagsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get adminTagsCommaSeparated;

  /// No description provided for @adminTopicBodyRequired.
  ///
  /// In en, this message translates to:
  /// **'Topic and body are required'**
  String get adminTopicBodyRequired;

  /// No description provided for @adminDeleteRightTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Right'**
  String get adminDeleteRightTitle;

  /// No description provided for @adminDeleteRightConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this right?'**
  String get adminDeleteRightConfirm;

  /// No description provided for @adminTemplatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage document templates'**
  String get adminTemplatesSubtitle;

  /// No description provided for @adminNewTemplate.
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get adminNewTemplate;

  /// No description provided for @adminNoTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get adminNoTemplatesTitle;

  /// No description provided for @adminNoTemplatesMessage.
  ///
  /// In en, this message translates to:
  /// **'Create the first template for users.'**
  String get adminNoTemplatesMessage;

  /// No description provided for @adminCreateTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get adminCreateTemplate;

  /// No description provided for @adminEditTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get adminEditTemplate;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminDescription;

  /// No description provided for @adminTitleBodyRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and body are required'**
  String get adminTitleBodyRequired;

  /// No description provided for @adminDeleteTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get adminDeleteTemplateTitle;

  /// No description provided for @adminDeleteTemplateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this template?'**
  String get adminDeleteTemplateConfirm;

  /// No description provided for @adminPathwaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage step-by-step legal guidance'**
  String get adminPathwaysSubtitle;

  /// No description provided for @adminNewPathway.
  ///
  /// In en, this message translates to:
  /// **'New Pathway'**
  String get adminNewPathway;

  /// No description provided for @adminNoPathwaysTitle.
  ///
  /// In en, this message translates to:
  /// **'No pathways yet'**
  String get adminNoPathwaysTitle;

  /// No description provided for @adminNoPathwaysMessage.
  ///
  /// In en, this message translates to:
  /// **'Create structured guidance for users.'**
  String get adminNoPathwaysMessage;

  /// No description provided for @adminCreatePathway.
  ///
  /// In en, this message translates to:
  /// **'Create Pathway'**
  String get adminCreatePathway;

  /// No description provided for @adminEditPathway.
  ///
  /// In en, this message translates to:
  /// **'Edit Pathway'**
  String get adminEditPathway;

  /// No description provided for @adminSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get adminSummary;

  /// No description provided for @adminStepsJson.
  ///
  /// In en, this message translates to:
  /// **'Steps (JSON list)'**
  String get adminStepsJson;

  /// No description provided for @adminStepsMustBeList.
  ///
  /// In en, this message translates to:
  /// **'Steps must be a list'**
  String get adminStepsMustBeList;

  /// No description provided for @adminInvalidStepsJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid steps JSON'**
  String get adminInvalidStepsJson;

  /// No description provided for @adminDeletePathwayTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Pathway'**
  String get adminDeletePathwayTitle;

  /// No description provided for @adminDeletePathwayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this pathway?'**
  String get adminDeletePathwayConfirm;

  /// No description provided for @adminChecklistsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage checklist categories and items'**
  String get adminChecklistsSubtitle;

  /// No description provided for @adminNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get adminNewCategory;

  /// No description provided for @adminNoCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get adminNoCategoriesTitle;

  /// No description provided for @adminNoCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Create categories to group checklist items.'**
  String get adminNoCategoriesMessage;

  /// No description provided for @adminOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Order {order}'**
  String adminOrderValue(Object order);

  /// No description provided for @adminManageItems.
  ///
  /// In en, this message translates to:
  /// **'Manage Items'**
  String get adminManageItems;

  /// No description provided for @adminCreateCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get adminCreateCategory;

  /// No description provided for @adminEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get adminEditCategory;

  /// No description provided for @adminIconOptional.
  ///
  /// In en, this message translates to:
  /// **'Icon (optional)'**
  String get adminIconOptional;

  /// No description provided for @adminOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get adminOrderLabel;

  /// No description provided for @adminDeleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get adminDeleteCategoryTitle;

  /// No description provided for @adminDeleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get adminDeleteCategoryConfirm;

  /// No description provided for @adminChecklistItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist Items'**
  String get adminChecklistItemsTitle;

  /// No description provided for @adminInvalidCategory.
  ///
  /// In en, this message translates to:
  /// **'Invalid category'**
  String get adminInvalidCategory;

  /// No description provided for @adminMissingCategory.
  ///
  /// In en, this message translates to:
  /// **'Missing category'**
  String get adminMissingCategory;

  /// No description provided for @adminSelectCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a checklist category to view its items.'**
  String get adminSelectCategoryMessage;

  /// No description provided for @adminItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage item ordering and requirements'**
  String get adminItemsSubtitle;

  /// No description provided for @adminNewItem.
  ///
  /// In en, this message translates to:
  /// **'New Item'**
  String get adminNewItem;

  /// No description provided for @adminNoItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get adminNoItemsTitle;

  /// No description provided for @adminNoItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add checklist items for this category.'**
  String get adminNoItemsMessage;

  /// No description provided for @adminOrderRequiredValue.
  ///
  /// In en, this message translates to:
  /// **'Order {order} - Required {required}'**
  String adminOrderRequiredValue(Object order, Object required);

  /// No description provided for @adminCreateItem.
  ///
  /// In en, this message translates to:
  /// **'Create Item'**
  String get adminCreateItem;

  /// No description provided for @adminEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get adminEditItem;

  /// No description provided for @adminTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get adminTextLabel;

  /// No description provided for @adminTextRequired.
  ///
  /// In en, this message translates to:
  /// **'Text is required'**
  String get adminTextRequired;

  /// No description provided for @adminDeleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get adminDeleteItemTitle;

  /// No description provided for @adminDeleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get adminDeleteItemConfirm;

  /// No description provided for @adminContactMessages.
  ///
  /// In en, this message translates to:
  /// **'Contact Messages'**
  String get adminContactMessages;

  /// No description provided for @adminContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and respond to user inquiries'**
  String get adminContactSubtitle;

  /// No description provided for @adminNoMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get adminNoMessagesTitle;

  /// No description provided for @adminNoMessagesMessage.
  ///
  /// In en, this message translates to:
  /// **'Incoming support requests will appear here.'**
  String get adminNoMessagesMessage;

  /// No description provided for @adminNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get adminNotificationsTitle;

  /// No description provided for @adminNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest admin updates'**
  String get adminNotificationsSubtitle;

  /// No description provided for @adminNoNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get adminNoNotificationsTitle;

  /// No description provided for @adminNoNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'New contact and feedback alerts will appear here.'**
  String get adminNoNotificationsMessage;

  /// No description provided for @adminNoSubject.
  ///
  /// In en, this message translates to:
  /// **'No subject'**
  String get adminNoSubject;

  /// No description provided for @adminMessageDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Message Detail'**
  String get adminMessageDetailTitle;

  /// No description provided for @adminMessageDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the full support request'**
  String get adminMessageDetailSubtitle;

  /// No description provided for @adminFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor sentiment and user ratings'**
  String get adminFeedbackSubtitle;

  /// No description provided for @adminFeedbackManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback Management'**
  String get adminFeedbackManagementTitle;

  /// No description provided for @adminFeedbackManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and respond to user feedback'**
  String get adminFeedbackManagementSubtitle;

  /// No description provided for @adminUnableToLoadFeedback.
  ///
  /// In en, this message translates to:
  /// **'Unable to load feedback'**
  String get adminUnableToLoadFeedback;

  /// No description provided for @adminNoFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get adminNoFeedbackTitle;

  /// No description provided for @adminNoFeedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Ratings and comments will appear here.'**
  String get adminNoFeedbackMessage;

  /// No description provided for @adminSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort:'**
  String get adminSortLabel;

  /// No description provided for @adminNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get adminNewest;

  /// No description provided for @adminOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get adminOldest;

  /// No description provided for @adminRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating:'**
  String get adminRatingLabel;

  /// No description provided for @adminStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get adminStatusLabel;

  /// No description provided for @adminUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get adminUnread;

  /// No description provided for @adminRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get adminRead;

  /// No description provided for @adminAvgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg Rating'**
  String get adminAvgRating;

  /// No description provided for @adminTotalFeedback.
  ///
  /// In en, this message translates to:
  /// **'Total Feedback'**
  String get adminTotalFeedback;

  /// No description provided for @adminUpdatingSummary.
  ///
  /// In en, this message translates to:
  /// **'Updating summary...'**
  String get adminUpdatingSummary;

  /// No description provided for @adminUserNumber.
  ///
  /// In en, this message translates to:
  /// **'User #{id}'**
  String adminUserNumber(Object id);

  /// No description provided for @adminUserBadge.
  ///
  /// In en, this message translates to:
  /// **'U#'**
  String get adminUserBadge;

  /// No description provided for @adminNoCommentProvided.
  ///
  /// In en, this message translates to:
  /// **'No comment provided.'**
  String get adminNoCommentProvided;

  /// No description provided for @adminLoadMoreFeedback.
  ///
  /// In en, this message translates to:
  /// **'Load More Feedback'**
  String get adminLoadMoreFeedback;

  /// No description provided for @adminFeedbackDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback Detail'**
  String get adminFeedbackDetailTitle;

  /// No description provided for @adminFeedbackDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full response from the user'**
  String get adminFeedbackDetailSubtitle;

  /// No description provided for @adminUserIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get adminUserIdLabel;

  /// No description provided for @adminCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get adminCommentLabel;

  /// No description provided for @adminTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get adminTotalUsers;

  /// No description provided for @adminTotalLawyers.
  ///
  /// In en, this message translates to:
  /// **'Total Lawyers'**
  String get adminTotalLawyers;

  /// No description provided for @adminTotalFeedbacks.
  ///
  /// In en, this message translates to:
  /// **'Total Feedbacks'**
  String get adminTotalFeedbacks;

  /// No description provided for @adminManagementHub.
  ///
  /// In en, this message translates to:
  /// **'MANAGEMENT HUB'**
  String get adminManagementHub;

  /// No description provided for @adminRagQualityOverview.
  ///
  /// In en, this message translates to:
  /// **'RAG Quality Overview'**
  String get adminRagQualityOverview;

  /// No description provided for @adminRagEvaluationLog.
  ///
  /// In en, this message translates to:
  /// **'RAG EVALUATION LOG'**
  String get adminRagEvaluationLog;

  /// No description provided for @adminDecisionBreakdown.
  ///
  /// In en, this message translates to:
  /// **'DECISION BREAKDOWN'**
  String get adminDecisionBreakdown;

  /// No description provided for @adminDecisionAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get adminDecisionAnswer;

  /// No description provided for @adminDecisionDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get adminDecisionDomain;

  /// No description provided for @adminDecisionNoHits.
  ///
  /// In en, this message translates to:
  /// **'No Hits'**
  String get adminDecisionNoHits;

  /// No description provided for @adminDecisionOutOfDomain.
  ///
  /// In en, this message translates to:
  /// **'Out of Domain'**
  String get adminDecisionOutOfDomain;

  /// No description provided for @adminLatency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get adminLatency;

  /// No description provided for @adminAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get adminAccuracy;

  /// No description provided for @adminDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get adminDistance;

  /// No description provided for @adminTokenUsage.
  ///
  /// In en, this message translates to:
  /// **'TOKEN USAGE'**
  String get adminTokenUsage;

  /// No description provided for @adminLiveStats.
  ///
  /// In en, this message translates to:
  /// **'LIVE STATS'**
  String get adminLiveStats;

  /// No description provided for @adminTotalUsed.
  ///
  /// In en, this message translates to:
  /// **'Total Used'**
  String get adminTotalUsed;

  /// No description provided for @adminAvgQuery.
  ///
  /// In en, this message translates to:
  /// **'Avg Query'**
  String get adminAvgQuery;

  /// No description provided for @adminRagLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'RAG Evaluation Logs'**
  String get adminRagLogsTitle;

  /// No description provided for @adminRagLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect retrieval quality, latency, and outcomes'**
  String get adminRagLogsSubtitle;

  /// No description provided for @adminUnableToLoadLogs.
  ///
  /// In en, this message translates to:
  /// **'Unable to load logs'**
  String get adminUnableToLoadLogs;

  /// No description provided for @adminNoLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'No evaluation logs'**
  String get adminNoLogsTitle;

  /// No description provided for @adminNoLogsMessage.
  ///
  /// In en, this message translates to:
  /// **'No logs found for the selected filters.'**
  String get adminNoLogsMessage;

  /// No description provided for @adminDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get adminDaysLabel;

  /// No description provided for @adminDecisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get adminDecisionLabel;

  /// No description provided for @adminInDomainLabel.
  ///
  /// In en, this message translates to:
  /// **'In Domain'**
  String get adminInDomainLabel;

  /// No description provided for @adminOutOfDomainLabel.
  ///
  /// In en, this message translates to:
  /// **'Out of Domain'**
  String get adminOutOfDomainLabel;

  /// No description provided for @adminSafeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Safe Mode'**
  String get adminSafeModeLabel;

  /// No description provided for @adminErrorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get adminErrorsLabel;

  /// No description provided for @adminOnlyErrors.
  ///
  /// In en, this message translates to:
  /// **'Only Errors'**
  String get adminOnlyErrors;

  /// No description provided for @adminMinTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Time'**
  String get adminMinTimeLabel;

  /// No description provided for @adminOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get adminOn;

  /// No description provided for @adminOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get adminOff;

  /// No description provided for @adminNoQuestionText.
  ///
  /// In en, this message translates to:
  /// **'No question text'**
  String get adminNoQuestionText;

  /// No description provided for @adminSafeModeOn.
  ///
  /// In en, this message translates to:
  /// **'Safe Mode On'**
  String get adminSafeModeOn;

  /// No description provided for @adminSafeModeOff.
  ///
  /// In en, this message translates to:
  /// **'Safe Mode Off'**
  String get adminSafeModeOff;

  /// No description provided for @adminErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get adminErrorLabel;

  /// No description provided for @adminContextsLabel.
  ///
  /// In en, this message translates to:
  /// **'Contexts'**
  String get adminContextsLabel;

  /// No description provided for @adminTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get adminTokensLabel;

  /// No description provided for @adminLoadMoreLogs.
  ///
  /// In en, this message translates to:
  /// **'Load More Logs'**
  String get adminLoadMoreLogs;

  /// No description provided for @adminQueryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Query Detail'**
  String get adminQueryDetailTitle;

  /// No description provided for @adminQueryDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full trace of the selected request'**
  String get adminQueryDetailSubtitle;

  /// No description provided for @adminCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get adminCreatedAtLabel;

  /// No description provided for @adminConversationIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Conversation ID'**
  String get adminConversationIdLabel;

  /// No description provided for @adminNewConversationLabel.
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get adminNewConversationLabel;

  /// No description provided for @adminQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get adminQuestionLabel;

  /// No description provided for @adminLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get adminLengthLabel;

  /// No description provided for @adminAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get adminAnswerLabel;

  /// No description provided for @adminUsedFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Used Fallback'**
  String get adminUsedFallbackLabel;

  /// No description provided for @adminDisclaimerAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer Added'**
  String get adminDisclaimerAddedLabel;

  /// No description provided for @adminRetrievalLabel.
  ///
  /// In en, this message translates to:
  /// **'Retrieval'**
  String get adminRetrievalLabel;

  /// No description provided for @adminThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get adminThresholdLabel;

  /// No description provided for @adminBestDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Distance'**
  String get adminBestDistanceLabel;

  /// No description provided for @adminContextsFoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Contexts Found'**
  String get adminContextsFoundLabel;

  /// No description provided for @adminContextsUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Contexts Used'**
  String get adminContextsUsedLabel;

  /// No description provided for @adminChunkIdsLabel.
  ///
  /// In en, this message translates to:
  /// **'Chunk IDs'**
  String get adminChunkIdsLabel;

  /// No description provided for @adminSourcesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get adminSourcesLabel;

  /// No description provided for @adminPerformanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get adminPerformanceLabel;

  /// No description provided for @adminTotalTimeMsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Time (ms)'**
  String get adminTotalTimeMsLabel;

  /// No description provided for @adminEmbeddingTimeMsLabel.
  ///
  /// In en, this message translates to:
  /// **'Embedding Time (ms)'**
  String get adminEmbeddingTimeMsLabel;

  /// No description provided for @adminLlmTimeMsLabel.
  ///
  /// In en, this message translates to:
  /// **'LLM Time (ms)'**
  String get adminLlmTimeMsLabel;

  /// No description provided for @adminPromptTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Prompt Tokens'**
  String get adminPromptTokensLabel;

  /// No description provided for @adminCompletionTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Completion Tokens'**
  String get adminCompletionTokensLabel;

  /// No description provided for @adminTotalTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Tokens'**
  String get adminTotalTokensLabel;

  /// No description provided for @adminModelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get adminModelsLabel;

  /// No description provided for @adminEmbeddingModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Embedding Model'**
  String get adminEmbeddingModelLabel;

  /// No description provided for @adminEmbeddingDimensionLabel.
  ///
  /// In en, this message translates to:
  /// **'Embedding Dimension'**
  String get adminEmbeddingDimensionLabel;

  /// No description provided for @adminChatModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat Model'**
  String get adminChatModelLabel;

  /// No description provided for @adminTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminTypeLabel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @contentUpdates.
  ///
  /// In en, this message translates to:
  /// **'Content updates'**
  String get contentUpdates;

  /// No description provided for @refreshContent.
  ///
  /// In en, this message translates to:
  /// **'Refresh content'**
  String get refreshContent;

  /// No description provided for @refreshContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch the latest rights, templates, and pathways for offline use.'**
  String get refreshContentSubtitle;

  /// No description provided for @refreshContentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Content updated.'**
  String get refreshContentSuccess;

  /// No description provided for @refreshContentFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to refresh content.'**
  String get refreshContentFailed;

  /// No description provided for @refreshContentOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get refreshContentOffline;

  /// No description provided for @lawyerUpdates.
  ///
  /// In en, this message translates to:
  /// **'Lawyer updates'**
  String get lawyerUpdates;

  /// No description provided for @reminderNotifications.
  ///
  /// In en, this message translates to:
  /// **'Reminder notifications'**
  String get reminderNotifications;

  /// No description provided for @recentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Recent notifications'**
  String get recentNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
