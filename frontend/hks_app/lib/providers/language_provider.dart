import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages
enum AppLanguage { english, malayalam }

class AppStrings {
  final AppLanguage lang;
  const AppStrings._(this.lang);

  factory AppStrings.of(AppLanguage lang) => AppStrings._(lang);

  bool get isMl => lang == AppLanguage.malayalam;

  // --- General ---
  String get appName => isMl ? 'ഹരിത കർമ്മ സേന' : 'Haritha Karma Sena';
  String get appSubtitle => isMl ? 'മാലിന്യ ശേഖരണ മാനേജ്‌മെന്റ് സിസ്റ്റം' : 'Waste Collection Management System';
  String get logout => isMl ? 'പുറത്ത് കടക്കുക' : 'Logout';
  String get loading => isMl ? 'ലോഡ് ചെയ്യുന്നു...' : 'Loading...';
  String get retry => isMl ? 'വീണ്ടും ശ്രമിക്കുക' : 'Retry';
  String get submit => isMl ? 'സമർപ്പിക്കുക' : 'Submit';
  String get cancel => isMl ? 'റദ്ദാക്കുക' : 'Cancel';
  String get save => isMl ? 'സേവ് ചെയ്യുക' : 'Save';
  String get refresh => isMl ? 'പുതുക്കുക' : 'Refresh';
  String get done => isMl ? 'പൂർത്തിയായി' : 'Done';
  String get noData => isMl ? 'ഡാറ്റ ഇല്ല' : 'No data';
  String get error => isMl ? 'പിശക്' : 'Error';
  String get success => isMl ? 'വിജയം' : 'Success';
  String get seeAll => isMl ? 'എല്ലാം കാണുക' : 'See all';
  String get selectRole => isMl ? 'തുടരാൻ നിങ്ങളുടെ പങ്ക് തിരഞ്ഞെടുക്കുക' : 'Select your role to continue';
  String get keralaMunicipality => isMl ? 'കേരള തദ്ദേശ സ്വയംഭരണം' : 'Kerala Local Self Government';
  String get delete => isMl ? 'ഇല്ലാതാക്കുക' : 'Delete';
  String get add => isMl ? 'ചേർക്കുക' : 'Add';
  String get edit => isMl ? 'തിരുത്തുക' : 'Edit';
  String get close => isMl ? 'അടക്കുക' : 'Close';
  String get confirm => isMl ? 'ഉറപ്പിക്കുക' : 'Confirm';
  String get search => isMl ? 'തിരയുക' : 'Search';
  String get filter => isMl ? 'ഫിൽട്ടർ' : 'Filter';
  String get all => isMl ? 'എല്ലാം' : 'All';
  String get today => isMl ? 'ഇന്ന്' : 'Today';
  String get week => isMl ? 'ആഴ്ച' : 'Week';
  String get month => isMl ? 'മാസം' : 'Month';
  String get year => isMl ? 'വർഷം' : 'Year';
  String get amount => isMl ? 'തുക' : 'Amount';
  String get date => isMl ? 'തീയതി' : 'Date';
  String get status => isMl ? 'നില' : 'Status';
  String get name => isMl ? 'പേര്' : 'Name';
  String get phone => isMl ? 'ഫോൺ നമ്പർ' : 'Phone Number';
  String get address => isMl ? 'വിലാസം' : 'Address';
  String get ward => isMl ? 'വാർഡ്' : 'Ward';
  String get back => isMl ? 'തിരിച്ച്' : 'Back';

  // --- Auth / Login ---
  String get login => isMl ? 'ലോഗിൻ' : 'Login';
  String get username => isMl ? 'ഉപയോക്തൃ നാമം' : 'Username';
  String get password => isMl ? 'പാസ്‌വേഡ്' : 'Password';
  String get workerId => isMl ? 'വർക്കർ ഐഡി' : 'Worker ID';
  String get otp => 'OTP';
  String get sendOtp => isMl ? 'OTP അയയ്ക്കുക' : 'Send OTP';
  String get verifyOtp => isMl ? 'OTP സ്ഥിരീകരിക്കുക' : 'Verify OTP';
  String get enterOtp => isMl ? '6 അക്ക OTP നൽകുക' : 'Enter 6-digit OTP';
  String get otpSentTo => isMl ? 'OTP അയച്ചു:' : 'OTP sent to:';
  String get changePhone => isMl ? 'ഫോൺ നമ്പർ മാറ്റുക' : 'Change phone number';
  String get verifyOtpLogin => isMl ? 'OTP സ്ഥിരീകരിച്ച് ലോഗിൻ' : 'Verify OTP & Login';
  String get backToRoleSelect => isMl ? 'പങ്ക് തിരഞ്ഞെടുക്കൽ' : 'Back to Role Selection';
  String get householdLogin => isMl ? 'ഗൃഹ ലോഗിൻ' : 'Household Login';
  String get enterRegPhone => isMl ? 'നിങ്ങളുടെ രജിസ്ട്രേഡ് ഫോൺ നമ്പർ നൽകുക' : 'Enter your registered phone number';
  String get workerLogin => isMl ? 'വർക്കർ ലോഗിൻ' : 'Worker Login';
  String get adminLogin => isMl ? 'അഡ്മിൻ ലോഗിൻ' : 'Admin Login';
  String get enterCreds => isMl ? 'ലോഗിൻ ചെയ്യാൻ ക്രെഡൻഷ്യൽ നൽകുക' : 'Enter your credentials to login';

  // --- Roles ---
  String get roleAdmin => isMl ? 'അഡ്മിൻ' : 'Admin';
  String get roleAdminSub => isMl ? 'സിസ്റ്റം മാനേജ്‌മെന്റ് & റിപ്പോർട്ടുകൾ' : 'System management & reports';
  String get roleWorker => isMl ? 'വർക്കർ' : 'Worker';
  String get roleWorkerSub => isMl ? 'മാലിന്യ ശേഖരണം & പേയ്‌മെന്റ്' : 'Waste collection & payments';
  String get roleHousehold => isMl ? 'ഗൃഹം' : 'Household';
  String get roleHouseholdSub => isMl ? 'ചരിത്രം & അറിയിപ്പുകൾ' : 'View history & notifications';

  // --- Admin Tabs ---
  String get tabDashboard => isMl ? 'ഡാഷ്‌ബോർഡ്' : 'Dashboard';
  String get tabWorkers => isMl ? 'വർക്കർമാർ' : 'Workers';
  String get tabHouses => isMl ? 'ഗൃഹങ്ങൾ' : 'Houses';
  String get tabWards => isMl ? 'വാർഡുകൾ' : 'Wards';
  String get tabReports => isMl ? 'റിപ്പോർട്ടുകൾ' : 'Reports';
  String get tabBroadcast => isMl ? 'പ്രക്ഷേപണം' : 'Broadcast';

  // --- Admin Dashboard ---
  String get adminDashboard => isMl ? 'അഡ്മിൻ ഡാഷ്‌ബോർഡ്' : 'Admin Dashboard';
  String get totalWorkers => isMl ? 'ആകെ വർക്കർമാർ' : 'Total Workers';
  String get totalHouseholds => isMl ? 'ആകെ ഗൃഹങ്ങൾ' : 'Total Households';
  String get totalWasteKg => isMl ? 'ആകെ മാലിന്യം (കി.ഗ്രാ)' : 'Total Waste (kg)';
  String get totalRevenue => isMl ? 'ആകെ വരുമാനം' : 'Total Revenue';
  String get monthlyCollections => isMl ? 'മാസ ശേഖരണങ്ങൾ' : 'Monthly Collections';

  // --- Admin Workers ---
  String get workerManagement => isMl ? 'വർക്കർ മാനേജ്‌മെന്റ്' : 'Worker Management';
  String get addWorker => isMl ? 'വർക്കർ ചേർക്കുക' : 'Add Worker';
  String get noWorkers => isMl ? 'വർക്കർമാരെ കണ്ടെത്തിയില്ല' : 'No workers found';
  String get assignedWard => isMl ? 'നിയോഗിക്കപ്പെട്ട വാർഡ്' : 'Assigned Ward';
  String get deleteWorker => isMl ? 'വർക്കറെ ഇല്ലാതാക്കണോ?' : 'Delete this worker?';

  // --- Admin Households ---
  String get householdManagement => isMl ? 'ഗൃഹ മാനേജ്‌മെന്റ്' : 'Household Management';
  String get addHousehold => isMl ? 'ഗൃഹം ചേർക്കുക' : 'Add Household';
  String get noHouseholds => isMl ? 'ഗൃഹങ്ങൾ കണ്ടെത്തിയില്ല' : 'No households found';
  String get qrCode => isMl ? 'QR കോഡ്' : 'QR Code';
  String get showQr => isMl ? 'QR കാണുക' : 'Show QR';

  // --- Admin Wards ---
  String get wardManagement => isMl ? 'വാർഡ് മാനേജ്‌മെന്റ്' : 'Ward Management';
  String get addWard => isMl ? 'വാർഡ് ചേർക്കുക' : 'Add Ward';
  String get wardName => isMl ? 'വാർഡ് പേര്' : 'Ward Name';
  String get wardNumber => isMl ? 'വാർഡ് നമ്പർ' : 'Ward Number';

  // --- Admin Reports ---
  String get reports => isMl ? 'ശേഖരണ റിപ്പോർട്ടുകൾ' : 'Collection Reports';
  String get allCollections => isMl ? 'എല്ലാ ശേഖരണങ്ങളും' : 'All Collections';

  // --- Admin Broadcast ---
  String get broadcast => isMl ? 'അറിയിപ്പ് അയയ്ക്കുക' : 'Send Notification';
  String get broadcastTitle => isMl ? 'തലക്കെട്ട്' : 'Title';
  String get broadcastMessage => isMl ? 'സന്ദേശം' : 'Message';
  String get broadcastTarget => isMl ? 'ലക്ഷ്യം' : 'Target';

  // --- Household Dashboard ---
  String get myDashboard => isMl ? 'എന്റെ ഡാഷ്‌ബോർഡ്' : 'My Dashboard';
  String get collectionHistory => isMl ? 'ശേഖരണ ചരിത്രം' : 'Collection History';
  String get paymentHistory => isMl ? 'പേയ്‌മെന്റ് ചരിത്രം' : 'Payment History';
  String get wasteInsights => isMl ? 'മാലിന്യ വിശകലനം' : 'Waste Insights';
  String get notifications => isMl ? 'അറിയിപ്പുകൾ' : 'Notifications';
  String get wasteGuidelines => isMl ? 'മാലിന്യ മാർഗ്ഗനിർദ്ദേശങ്ങൾ' : 'Waste Guidelines';
  String get contactWorker => isMl ? 'വർക്കർ ബന്ധപ്പെടുക' : 'Contact Worker';
  String get skipCollection => isMl ? 'ശേഖരണം ഒഴിവാക്കുക' : 'Skip Collection';
  String get quickAccess => isMl ? 'ദ്രുത ആക്‌സസ്' : 'Quick Access';
  String get recentCollections => isMl ? 'സമീപ ശേഖരണങ്ങൾ' : 'Recent Collections';
  String get lastCollection => isMl ? 'അവസാന ശേഖരണം' : 'Last Collection';
  String get pending => isMl ? 'കുടിശ്ശിക' : 'Pending';
  String get yourWard => isMl ? 'നിങ്ങളുടെ വാർഡ്' : 'Your Ward';
  String get rate => isMl ? 'റേറ്റ് ചെയ്യുക' : 'Rate';

  // --- Worker Tabs ---
  String get tabCollection => isMl ? 'ശേഖരണം' : 'Collection';
  String get tabScanQr => isMl ? 'QR സ്കാൻ' : 'Scan QR';
  String get tabMyStats => isMl ? 'എന്റെ സ്കോർ' : 'My Stats';
  String get tabAlerts => isMl ? 'അറിയിപ്പ്' : 'Alerts';

  // --- Household Tabs ---
  String get tabHome => isMl ? 'ഹോം' : 'Home';
  String get tabHistory => isMl ? 'ചരിത്രം' : 'History';
  String get tabPayments => isMl ? 'പേയ്‌മെന്റ്' : 'Payments';
  String get tabInsights => isMl ? 'വിശകലനം' : 'Insights';

  // --- Worker Dashboard ---
  String get wardCollection => isMl ? 'വാർഡ് ശേഖരണം' : 'Ward Collection';
  String get selectWard => isMl ? 'ഇന്നത്തെ വാർഡ് തിരഞ്ഞെടുക്കുക' : 'Select Ward for Today';
  String get chooseWard => isMl ? 'ഒരു വാർഡ് തിരഞ്ഞെടുക്കുക' : 'Choose a ward to work in today';
  String get todayProgress => isMl ? 'ഇന്നത്തെ പുരോഗതി' : "Today's Progress";
  String get totalHouses => isMl ? 'ആകെ വീടുകൾ' : 'Total Houses';
  String get visited => isMl ? 'സന്ദർശിച്ചത്' : 'Visited';
  String get remaining => isMl ? 'ശേഷിക്കുന്നു' : 'Remaining';
  String get expectedCollection => isMl ? 'പ്രതീക്ഷിത ശേഖരണം' : 'Expected Collection';
  String get collectionProgress => isMl ? 'ശേഖരണ പുരോഗതി' : 'Collection Progress';
  String get scheduleNotification => isMl ? 'ശേഖരണ അറിയിപ്പ് ഷെഡ്യൂൾ' : 'Schedule Collection Notification';
  String get minThreeDays => isMl ? 'കുറഞ്ഞത് 3 ദിവസം മുൻകൂട്ടി' : 'At least 3 days in advance';
  String get scanHouseholdQr => isMl ? 'ഗൃഹ QR സ്കാൻ ചെയ്യുക' : 'Scan Household QR & Collect';
  String get selectWardFirst => isMl ? 'ആദ്യം ഒരു വാർഡ് തിരഞ്ഞെടുക്കുക' : 'Please select a ward before scanning.';
  String get notifyingDone => isMl ? 'അറിയിപ്പ് അയച്ചു' : 'Households notified';

  // --- Collection Form ---
  String get recordCollection => isMl ? 'ശേഖരണം രേഖപ്പെടുത്തുക' : 'Record Collection';
  String get householdDetails => isMl ? 'ഗൃഹ വിവരങ്ങൾ' : 'Household Details';
  String get wasteDetails => isMl ? 'മാലിന്യ വിവരങ്ങൾ' : 'Waste Details';
  String get weight => isMl ? 'ഭാരം (കി.ഗ്രാ)' : 'Weight (kg)';
  String get rate2 => isMl ? 'നിരക്ക് (₹/കി.ഗ്രാ)' : 'Rate (Rs/kg)';
  String get totalAmount => isMl ? 'ആകെ തുക' : 'Total Amount';
  String get cleanlinessRating => isMl ? 'വൃത്തി നിലവാരം' : 'Cleanliness Rating';
  String get paymentMethod => isMl ? 'പേയ്‌മെന്റ് രീതി' : 'Payment Method';
  String get cash => isMl ? 'പണം' : 'Cash';
  String get upi => 'UPI';
  String get householdUpiId => isMl ? 'ഗൃഹ UPI ഐഡി' : 'Household UPI ID';
  String get notes => isMl ? 'കുറിപ്പുകൾ (ഐച്ഛികം)' : 'Notes (optional)';
  String get submitCollection => isMl ? 'ശേഖരണം സമർപ്പിക്കുക' : 'Submit Collection';
  String get wasteType => isMl ? 'മാലിന്യ തരം' : 'Waste Type';

  // --- Payment ---
  String get paid => isMl ? 'അടച്ചു' : 'Paid';
  String get unpaid => isMl ? 'കുടിശ്ശിക' : 'Pending';
  String get totalPaid => isMl ? 'ആകെ അടച്ചത്' : 'Total Paid';
  String get totalPending => isMl ? 'ആകെ കുടിശ്ശിക' : 'Total Pending';

  // --- Worker Stats ---
  String get performance => isMl ? 'പ്രകടന ഡാഷ്‌ബോർഡ്' : 'Performance Dashboard';
  String get collectionsCount => isMl ? 'ശേഖരണങ്ങൾ' : 'Collections';
  String get wasteCollected => isMl ? 'ശേഖരിച്ച മാലിന്യം' : 'Waste Collected';
  String get revenueGenerated => isMl ? 'ഉൽപ്പാദിപ്പിച്ച വരുമാനം' : 'Revenue Generated';
  String get avgRating => isMl ? 'ശരാശരി റേറ്റിംഗ്' : 'Avg. Rating';
  String get wasteBreakdown => isMl ? 'മാലിന്യ വിശദാംശങ്ങൾ' : 'Waste Breakdown';

  // --- QR Scanner ---
  String get scanQr => isMl ? 'QR കോഡ് സ്കാൻ ചെയ്യുക' : 'Scan QR Code';
  String get pointCamera => isMl ? 'ഗൃഹ QR കോഡിൽ ക്യാമറ ചൂണ്ടുക' : 'Point camera at household QR code';
  String get manualEntry => isMl ? 'QR കോഡ് കൈ-നൽകൽ' : 'Enter QR Code Manually';
  String get enterQrCode => isMl ? 'QR കോഡ് ടൈപ്പ് ചെയ്യുക' : 'Type QR Code';
  String get submit2 => isMl ? 'സബ്മിറ്റ്' : 'Submit';

  // --- Skip Collection ---
  String get skipTitle => isMl ? 'ശേഖരണം ഒഴിവാക്കുക' : 'Skip Collection';
  String get selectDate => isMl ? 'തീയതി തിരഞ്ഞെടുക്കുക' : 'Select Date';
  String get reason => isMl ? 'കാരണം (ഐച്ഛികം)' : 'Reason (optional)';
  String get deferPayment => isMl ? 'അടുത്ത മാസം മാറ്റിവയ്ക്കുക' : 'Defer to Next Month';
  String get waivePayment => isMl ? 'ഒഴിവാക്കുക' : 'Waive';
  String get sendSkipRequest => isMl ? 'ഒഴിവ് അഭ്യർഥന അയയ്ക്കുക' : 'Send Skip Request';
  String get previousRequests => isMl ? 'മുൻ അഭ്യർഥനകൾ' : 'Previous Requests';
  String get acknowledged => isMl ? 'സ്വീകരിച്ചു' : 'Acknowledged';

  // --- Rate Worker ---
  String get rateWorker => isMl ? 'വർക്കറെ വിലയിരുത്തുക' : 'Rate Worker';
  String get howWasService => isMl ? 'സേവനം എങ്ങനെ ആയിരുന്നു?' : 'How was the service?';
  String get additionalFeedback => isMl ? 'അധിക അഭിപ്രായം (ഐഛികം)' : 'Additional feedback (optional)';
  String get submitRating => isMl ? 'റേറ്റിംഗ് സമർപ്പിക്കുക' : 'Submit Rating';
  String get thankYouFeedback => isMl ? 'നന്ദി! നിങ്ങളുടെ അഭിപ്രായം ലഭിച്ചു.' : 'Thank you for your feedback!';

  // --- Guidelines ---
  String get guidelinesTitle => isMl ? 'മാലിന്യ തരംതിരിക്കൽ മാർഗ്ഗനിർദ്ദേശങ്ങൾ' : 'Waste Sorting Guidelines';
  String get sortBeforeCollection => isMl ? 'ശേഖരണത്തിന് മുൻപ് തരംതിരിക്കുക' : 'Sort Before Collection';
  String get guidelinesSubtitle => isMl
      ? 'ശരിയായ തരംതിരിക്കൽ പുനരുപയോഗത്തെ സഹായിക്കുന്നു. ഓരോ വിഭാഗത്തിലും ടാപ്പ് ചെയ്യുക.'
      : 'Proper segregation helps recycling. Tap each category for guidelines.';
  String get howToStore => isMl ? 'എങ്ങനെ സൂക്ഷിക്കാം' : 'How to store';
  String get specialHandling => isMl ? 'പ്രത്യേക ശ്രദ്ധ ആവശ്യം' : 'Special handling required';
  String get doTitle => isMl ? 'ചെയ്യേണ്ടവ:' : 'Do:';
  String get dontTitle => isMl ? 'ചെയ്യരുതാത്തവ:' : "Don't:";

  // --- Contact Worker ---
  String get yourWardWorkers => isMl ? 'നിങ്ങളുടെ വാർഡ് വർക്കർമാർ' : 'Your Ward Workers';
  String get noWorkersAssigned => isMl ? 'ഇതുവരെ വർക്കർ നിയോഗിക്കപ്പെട്ടിട്ടില്ല.' : 'No workers assigned to your ward yet.';
  String get assignedWorkers => isMl ? 'നിയോഗിക്കപ്പെട്ട വർക്കർമാർ' : 'Assigned Workers';
  String get copyNumber => isMl ? 'ഫോൺ നമ്പർ കോപ്പി ചെയ്തു' : 'Phone number copied';

  // --- Notifications ---
  String get markAllRead => isMl ? 'എല്ലാം വായിച്ചതായി അടയാളപ്പെടുത്തുക' : 'Mark all read';
  String get noNotifications => isMl ? 'അറിയിപ്പുകൾ ഇല്ല' : 'No notifications';

  // --- Waste category names ---
  String get organic => isMl ? 'ജൈവ മാലിന്യം' : 'Organic Waste';
  String get plastic => isMl ? 'പ്ലാസ്റ്റിക് മാലിന്യം' : 'Plastic Waste';
  String get paper => isMl ? 'കടലാസ് & കാർഡ്ബോർഡ്' : 'Paper & Cardboard';
  String get ewaste => isMl ? 'ഇ-മാലിന്യം' : 'E-Waste';
  String get glass => isMl ? 'ഗ്ലാസ്' : 'Glass';
  String get hazardous => isMl ? 'അപകടകരമായ മാലിന്യം' : 'Hazardous Waste';

  // --- Feedback (structured 4-question) ---
  String get feedbackHelps => isMl ? 'നിങ്ങളുടെ അഭിപ്രായം ഗുണമേന്മ മെച്ചപ്പെടുത്താൻ സഹായിക്കുന്നു.' : 'Your feedback helps improve waste collection quality.';
  String get feedbackPunctuality => isMl ? 'കൃത്യനിഷ്ഠ' : 'Punctuality';
  String get feedbackCleanliness => isMl ? 'വൃത്തി' : 'Cleanliness';
  String get feedbackAttitude => isMl ? 'മനോഭാവം' : 'Attitude';
  String get feedbackOverall => isMl ? 'മൊത്തം അനുഭവം' : 'Overall Experience';
  String get feedbackComment => isMl ? 'അധിക അഭിപ്രായം (ഐഛികം)' : 'Additional feedback (optional)';
  String get feedbackThankYou => isMl ? 'നന്ദി!' : 'Thank you!';
  String get feedbackSent => isMl ? 'നിങ്ങളുടെ റേറ്റിംഗ് അയച്ചു.' : 'Your rating has been sent.';
  String get alreadyRated => isMl ? 'ഈ ശേഖരണം ഇതിനകം റേറ്റ് ചെയ്‌തു' : 'You already rated this collection';
  String get ratingPoor => isMl ? 'മോശം' : 'Poor';
  String get ratingAverage => isMl ? 'ശരാശരി' : 'Average';
  String get ratingGood => isMl ? 'നല്ലത്' : 'Good';
  String get ratingExcellent => isMl ? 'മികച്ചത്' : 'Excellent';
  List<String> get ratingLabels => [ratingPoor, ratingAverage, ratingGood, ratingExcellent];
  static const ratingColors = [Colors.red, Colors.orange, Color(0xFF8BC34A), Colors.green];

  // --- Extra Pickup Request ---
  String get extraPickup => isMl ? 'അധിക ശേഖരണം' : 'Extra Pickup';
  String get requestExtraPickup => isMl ? 'അധിക ശേഖരണം അഭ്യർത്ഥിക്കുക' : 'Request Extra Pickup';
  String get extraPickupSubtitle => isMl ? 'ഇന്ന് ഒരു അധിക തരം മാലിന്യം ശേഖരിക്കാൻ അഭ്യർത്ഥിക്കുക' : 'Request an extra waste type to be collected today';
  String get selectWasteType => isMl ? 'മാലിന്യ തരം തിരഞ്ഞെടുക്കുക' : 'Select Waste Type';
  String get additionalNotes => isMl ? 'കൂടുതൽ കുറിപ്പുകൾ (ഐഛികം)' : 'Additional Notes (optional)';
  String get requestSent => isMl ? 'അഭ്യർത്ഥന അയച്ചു!' : 'Request Sent!';
  String get requestSentDesc => isMl ? 'തൊഴിലാളിക്ക് അറിയിപ്പ് ലഭിക്കും. ഉടൻ ഉത്തരം ലഭിക്കും.' : 'The worker has been notified. You will receive a response shortly.';
  String get pendingRequests => isMl ? 'കാത്തിരിക്കുന്ന അഭ്യർത്ഥനകൾ' : 'Pending Requests';
  String get approve => isMl ? 'അനുവദിക്കുക' : 'Approve';
  String get rejectReq => isMl ? 'നിരസിക്കുക' : 'Reject';
  String get approvedLabel => isMl ? 'അനുവദിച്ചു' : 'Approved';
  String get rejectedLabel => isMl ? 'നിരസിച്ചു' : 'Rejected';
  String get extraPickupRequests => isMl ? 'അധിക ശേഖരണ അഭ്യർത്ഥനകൾ' : 'Extra Pickup Requests';
  String get noExtraRequests => isMl ? 'ഇന്ന് അധിക ശേഖരണ അഭ്യർത്ഥനകൾ ഇല്ല' : 'No extra pickup requests today';
  String get rejectionReason => isMl ? 'നിരസിക്കുന്നതിന്റെ കാരണം' : 'Reason for rejection';

  // --- Dark / Light Mode ---
  String get darkMode => isMl ? 'ഡാർക്ക് മോഡ്' : 'Dark Mode';
  String get lightMode => isMl ? 'ലൈറ്റ് മോഡ്' : 'Light Mode';

  // --- Notifications title ---
  String get notificationsTitle => isMl ? 'അറിയിപ്പുകൾ' : 'Notifications';
}

// ────────────────────────────────────────────────────────────────
// LanguageProvider — persists choice, notifies listeners on toggle
// ────────────────────────────────────────────────────────────────
class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;
  AppStrings get strings => AppStrings.of(_language);
  AppLanguage get language => _language;
  bool get isMalayalam => _language == AppLanguage.malayalam;

  LanguageProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language');
    if (saved == 'malayalam') {
      _language = AppLanguage.malayalam;
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'app_language', lang == AppLanguage.malayalam ? 'malayalam' : 'english');
  }

  void toggle() =>
      setLanguage(isMalayalam ? AppLanguage.english : AppLanguage.malayalam);
}

// ────────────────────────────────────────────────────────────────
// LangToggleButton — reusable AppBar widget
// ────────────────────────────────────────────────────────────────
class LangToggleButton extends StatelessWidget {
  const LangToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return TextButton(
      onPressed: lp.toggle,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        lp.isMalayalam ? 'EN' : 'ML',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}

// Global singleton — accessed by main.dart and screens
final _globalLangProvider = LanguageProvider();
LanguageProvider get globalLang => _globalLangProvider;
