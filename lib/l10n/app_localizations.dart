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
    Locale('ur')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'RaastKar'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Smart Farming Solutions'**
  String get tagline;

  /// No description provided for @cropPlanner.
  ///
  /// In en, this message translates to:
  /// **'Crop Planner'**
  String get cropPlanner;

  /// No description provided for @cropPlannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover best crops for your soil'**
  String get cropPlannerDesc;

  /// No description provided for @drCrop.
  ///
  /// In en, this message translates to:
  /// **'Dr Crop'**
  String get drCrop;

  /// No description provided for @drCropDesc.
  ///
  /// In en, this message translates to:
  /// **'AI-powered crop disease diagnosis'**
  String get drCropDesc;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @weatherDesc.
  ///
  /// In en, this message translates to:
  /// **'Real-time alerts and crop recommendations'**
  String get weatherDesc;

  /// No description provided for @mandiPrices.
  ///
  /// In en, this message translates to:
  /// **'Mandi Prices'**
  String get mandiPrices;

  /// No description provided for @mandiDesc.
  ///
  /// In en, this message translates to:
  /// **'Live market prices across Pakistan'**
  String get mandiDesc;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @marketplaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell directly with farmers'**
  String get marketplaceDesc;

  /// No description provided for @carbonCredit.
  ///
  /// In en, this message translates to:
  /// **'Carbon Credits'**
  String get carbonCredit;

  /// No description provided for @carbonDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn money for sustainable farming'**
  String get carbonDesc;

  /// No description provided for @esg.
  ///
  /// In en, this message translates to:
  /// **'ESG Compliance'**
  String get esg;

  /// No description provided for @esgDesc.
  ///
  /// In en, this message translates to:
  /// **'Environmental Social Governance score'**
  String get esgDesc;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Karachi, Lahore'**
  String get locationHint;

  /// No description provided for @soilPh.
  ///
  /// In en, this message translates to:
  /// **'Soil pH'**
  String get soilPh;

  /// No description provided for @tds.
  ///
  /// In en, this message translates to:
  /// **'TDS (ppm)'**
  String get tds;

  /// No description provided for @salinity.
  ///
  /// In en, this message translates to:
  /// **'Salinity (dS/m)'**
  String get salinity;

  /// No description provided for @analyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze & Get AI Recommendations'**
  String get analyze;

  /// No description provided for @soilScore.
  ///
  /// In en, this message translates to:
  /// **'Soil Suitability Score'**
  String get soilScore;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @topRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Top Recommendations'**
  String get topRecommendations;

  /// No description provided for @selectCrop.
  ///
  /// In en, this message translates to:
  /// **'Select Crop'**
  String get selectCrop;

  /// No description provided for @selectSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Select Symptoms'**
  String get selectSymptoms;

  /// No description provided for @diagnose.
  ///
  /// In en, this message translates to:
  /// **'Diagnose'**
  String get diagnose;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @diagnosing.
  ///
  /// In en, this message translates to:
  /// **'Diagnosing...'**
  String get diagnosing;

  /// No description provided for @farmDetails.
  ///
  /// In en, this message translates to:
  /// **'Farm Details'**
  String get farmDetails;

  /// No description provided for @farmLocation.
  ///
  /// In en, this message translates to:
  /// **'Farm Location'**
  String get farmLocation;

  /// No description provided for @farmSize.
  ///
  /// In en, this message translates to:
  /// **'Farm Size (Acres)'**
  String get farmSize;

  /// No description provided for @plantsPerAcre.
  ///
  /// In en, this message translates to:
  /// **'Plants per Acre'**
  String get plantsPerAcre;

  /// No description provided for @registerFarm.
  ///
  /// In en, this message translates to:
  /// **'Register Farm & Calculate Credits'**
  String get registerFarm;

  /// No description provided for @greenPractices.
  ///
  /// In en, this message translates to:
  /// **'Green Practices'**
  String get greenPractices;

  /// No description provided for @myCredits.
  ///
  /// In en, this message translates to:
  /// **'My Credits'**
  String get myCredits;

  /// No description provided for @totalCredits.
  ///
  /// In en, this message translates to:
  /// **'Total Carbon Credits'**
  String get totalCredits;

  /// No description provided for @creditsEarned.
  ///
  /// In en, this message translates to:
  /// **'credits earned'**
  String get creditsEarned;

  /// No description provided for @downloadCertificate.
  ///
  /// In en, this message translates to:
  /// **'Download Certificate'**
  String get downloadCertificate;

  /// No description provided for @overallEsgScore.
  ///
  /// In en, this message translates to:
  /// **'Overall ESG Score'**
  String get overallEsgScore;

  /// No description provided for @environmental.
  ///
  /// In en, this message translates to:
  /// **'Environmental'**
  String get environmental;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @governance.
  ///
  /// In en, this message translates to:
  /// **'Governance'**
  String get governance;

  /// No description provided for @improvementTips.
  ///
  /// In en, this message translates to:
  /// **'Improvement Tips'**
  String get improvementTips;

  /// No description provided for @profitCalculator.
  ///
  /// In en, this message translates to:
  /// **'Profit Calculator'**
  String get profitCalculator;

  /// No description provided for @contactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get contactSeller;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @drCropShort.
  ///
  /// In en, this message translates to:
  /// **'Dr Crop'**
  String get drCropShort;

  /// No description provided for @weatherShort.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherShort;

  /// No description provided for @mandi.
  ///
  /// In en, this message translates to:
  /// **'Mandi'**
  String get mandi;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @carbon.
  ///
  /// In en, this message translates to:
  /// **'Carbon'**
  String get carbon;

  /// No description provided for @pleaseEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your location'**
  String get pleaseEnterLocation;

  /// No description provided for @pleaseFillAllValues.
  ///
  /// In en, this message translates to:
  /// **'Please fill all soil values'**
  String get pleaseFillAllValues;

  /// No description provided for @pleaseSelectSymptom.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one symptom'**
  String get pleaseSelectSymptom;

  /// No description provided for @couldNotGetRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Could not get recommendations'**
  String get couldNotGetRecommendations;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Make sure backend is running.'**
  String get connectionError;

  /// No description provided for @waterNeeds.
  ///
  /// In en, this message translates to:
  /// **'Water need'**
  String get waterNeeds;

  /// No description provided for @yield.
  ///
  /// In en, this message translates to:
  /// **'Yield'**
  String get yield;

  /// No description provided for @marketPrice.
  ///
  /// In en, this message translates to:
  /// **'Market price'**
  String get marketPrice;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @liveCalculation.
  ///
  /// In en, this message translates to:
  /// **'Live Credit Calculation'**
  String get liveCalculation;

  /// No description provided for @totalPlants.
  ///
  /// In en, this message translates to:
  /// **'Total plants'**
  String get totalPlants;

  /// No description provided for @co2Sequestered.
  ///
  /// In en, this message translates to:
  /// **'CO2 sequestered'**
  String get co2Sequestered;

  /// No description provided for @baseCredits.
  ///
  /// In en, this message translates to:
  /// **'Base credits'**
  String get baseCredits;

  /// No description provided for @bonusCredits.
  ///
  /// In en, this message translates to:
  /// **'Bonus credits'**
  String get bonusCredits;

  /// No description provided for @totalCreditsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total credits'**
  String get totalCreditsLabel;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated value'**
  String get estimatedValue;

  /// No description provided for @grossRevenue.
  ///
  /// In en, this message translates to:
  /// **'Gross Revenue'**
  String get grossRevenue;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'Profit Margin'**
  String get profitMargin;

  /// No description provided for @breakEven.
  ///
  /// In en, this message translates to:
  /// **'Break-even Price'**
  String get breakEven;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate feature coming soon!'**
  String get certificate;
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
      'that was used.');
}
