import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  String get currentLocale => locale.languageCode;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appTitle': 'Sannidhi',
      'bookings': 'Bookings',
      'festivals': 'Festivals',
      'home': 'Home',
      'services': 'Services',
      'donation': 'Donation',
      'languageTamil': 'தமிழ்',
      'languageEnglish': 'Eng',
      'lowCrowd': 'Low Crowd',
      'moderateCrowd': 'Moderate Crowd',
      'highCrowd': 'High Crowd',
      'veryHighCrowd': 'Very High Crowd',
      'quickBooking': 'Quick Booking',
      'darshan': 'Darshan',
      'donations': 'Donations',
      'upcomingEvents': 'Upcoming Events',
      'shuttleBus': 'Shuttle Bus',
      'specialPooja': 'Special Pooja',
      'prasadam': 'Prasadam',
      'account': 'Account',
      'crowdStatus': 'Crowd Status',
      'estWait': 'Est. Wait',
      'mins': 'Mins',
      'special': 'Special',
      'viewAll': 'View All',
      'confirmed': 'Confirmed',
      'available': 'Available',
      'bookShuttle': 'Book Shuttle',
      'darshanSlots': 'Darshan Slots',
      'bookDarshan': 'Book your darshan slot',
      'archanai': 'Archanai',
      'archanaiDesc': 'Personalized deity worship',
      'prasadamDesc': 'Order prasadam for delivery',
      'seva': 'Seva',
      'sevaDesc': 'Volunteer services and donations',
      'trustDonation': 'Trust Donation',
      'prasadamDonation': 'Prasadam Donation',
      'deepamDonation': 'Deepam Donation',
      'sevaDonation': 'Seva Donation',
      'donate': 'Donate',
      'donationAmount': 'Donation Amount',
      'amount': 'Amount',
      'donationNote': 'Your generous donation will help us serve humanity',
      'cancel': 'Cancel',
      'donationSuccess': 'Donation successful!',
      'quickActions': 'Quick Actions',
      // Shuttle booking
      'selectSlot': 'Select Time Slot',
      'passengers': 'Passengers',
      'confirmBooking': 'Confirm Booking',
      'boardingPass': 'Boarding Pass',
      'ticketId': 'Ticket ID',
      'seats': 'Seats',
      'route': 'Route',
      'date': 'Date',
      'time': 'Time',
      'price': 'Price',
      'done': 'Done',
      'bookingConfirmed': 'Booking Confirmed!',
      // Donation
      'selectCause': 'Select Cause',
      'annadhanam': 'Annadhanam',
      'renovation': 'Renovation',
      'ghoShala': 'Gho Shala',
      'archana': 'Archana',
      'customAmount': 'Custom Amount',
      'proceedToPay': 'Proceed to Pay',
      'contributionReceipt': 'Contribution Receipt',
      'donorName': 'Donor',
      'cause': 'Cause',
      'transactionId': 'Transaction ID',
      'thankYou': 'Thank you for your contribution 🙏',
      // Footfall
      'footfallDensity': 'Footfall Density',
      'liveEstimate': 'Live Estimate',
      // Bookings tabs
      'bookServices': 'Book Services',
      'myPasses': 'My Active Passes',
      'freeQueue': 'Free Queue',
      'specialDarshan': 'Special Darshan',
      'vipAbhishekam': 'VIP Abhishekam',
      // Services
      'caveVisit': 'Pambatti Siddhar Cave',
      'caveVisitDesc': 'Sacred cave visit on the hilltop',
      'specialAbhishekam': 'Special Abhishekam',
      'specialAbhishekamDesc': 'Priority abhishekam with priest',
      'thangaratham': 'Thanga Ther (Golden Chariot)',
      'thangarathamDesc': 'Festival procession of the golden chariot',
      'annadhanamDesc': 'Free vegetarian meals for all pilgrims',
    },
    'ta': {
      'appTitle': 'சந்நிதி',
      'bookings': 'புக்கிங்குகள்',
      'festivals': 'விழாக்கள்',
      'home': 'முகப்பு',
      'services': 'சேவைகள்',
      'donation': 'தானம்',
      'languageTamil': 'தமிழ்',
      'languageEnglish': 'Eng',
      'lowCrowd': 'குறைந்த போக்குவரத்து',
      'moderateCrowd': 'சராசரி போக்குவரத்து',
      'highCrowd': 'அதிக போக்குவரத்து',
      'veryHighCrowd': 'மிக அதிக போக்குவரத்து',
      'quickBooking': 'விரைவு புக்கிங்',
      'darshan': 'தரிசனம்',
      'donations': 'தானங்கள்',
      'upcomingEvents': 'அருகில் நடக்கும் நிகழ்வுகள்',
      'shuttleBus': 'சட்டெல்லி பஸ்',
      'specialPooja': 'சிறப்பு பூஜை',
      'prasadam': 'பிரசாதம்',
      'account': 'கணக்கு',
      'crowdStatus': 'கூட்டத்தின் நிலைமை',
      'estWait': 'தோராயமான காத்திருப்பு',
      'mins': 'நிமிடங்கள்',
      'special': 'சிறப்பு',
      'viewAll': 'அனைத்தும் காண்க',
      'confirmed': 'உறுதிப்படுத்தப்பட்டது',
      'available': 'கிடைக்கிறது',
      'bookShuttle': 'சட்டெல்லி பஸ் புக்கிங்',
      'darshanSlots': 'தரிசன இடங்கள்',
      'bookDarshan': 'உங்கள் தரிசன இடத்தை புக்கிங் செய்யுங்கள்',
      'archanai': 'அர்ச்சனை',
      'archanaiDesc': 'தனிப்பட்ட தெய்வ வழிபாடு',
      'prasadamDesc': 'டெலிவரி செய்ய பிரசாதம் ஆர்டர் செய்யுங்கள்',
      'seva': 'சேவை',
      'sevaDesc': 'தொண்டு சேவைகள் மற்றும் தானங்கள்',
      'trustDonation': 'நம்பிக்கை தானம்',
      'prasadamDonation': 'பிரசாதம் தானம்',
      'deepamDonation': 'தீப தானம்',
      'sevaDonation': 'சேவை தானம்',
      'donate': 'தானம் செய்ய',
      'donationAmount': 'தான தொகை',
      'amount': 'தொகை',
      'donationNote': 'உங்கள் அருளான தானம் மனிதர்களுக்கு சேவை செய்ய எம்மை உதவும்',
      'cancel': 'ரத்து',
      'donationSuccess': 'தானம் வெற்றிகரமாக!',
      'quickActions': 'விரைவு செயல்கள்',
      // Shuttle booking
      'selectSlot': 'நேர இடம் தேர்ந்தெடுக்கவும்',
      'passengers': 'பயணிகள்',
      'confirmBooking': 'புக்கிங் உறுதிப்படுத்து',
      'boardingPass': 'பயண அனுமதி',
      'ticketId': 'டிக்கெட் எண்',
      'seats': 'இருக்கைகள்',
      'route': 'பாதை',
      'date': 'தேதி',
      'time': 'நேரம்',
      'price': 'விலை',
      'done': 'முடிந்தது',
      'bookingConfirmed': 'புக்கிங் உறுதிப்படுத்தப்பட்டது!',
      // Donation
      'selectCause': 'காரணம் தேர்ந்தெடுக்கவும்',
      'annadhanam': 'அன்னதானம்',
      'renovation': 'புனரமைப்பு',
      'ghoShala': 'கோ சாலை',
      'archana': 'அர்ச்சனை',
      'customAmount': 'தனிப்பயன் தொகை',
      'proceedToPay': 'பணம் செலுத்த தொடரவும்',
      'contributionReceipt': 'பங்களிப்பு ரசீது',
      'donorName': 'நன்கொடையாளர்',
      'cause': 'காரணம்',
      'transactionId': 'பரிவர்த்தனை எண்',
      'thankYou': 'உங்கள் பங்களிப்புக்கு நன்றி 🙏',
      // Footfall
      'footfallDensity': 'கூட்ட அடர்த்தி',
      'liveEstimate': 'நேரடி மதிப்பீடு',
      // Bookings tabs
      'bookServices': 'சேவைகள் புக்கிங்',
      'myPasses': 'என் செயலில் உள்ள பாஸ்கள்',
      'freeQueue': 'இலவச வரிசை',
      'specialDarshan': 'சிறப்பு தரிசனம்',
      'vipAbhishekam': 'VIP அபிஷேகம்',
      // Services
      'caveVisit': 'பம்பட்டி சித்தர் குகை',
      'caveVisitDesc': 'மலை உச்சியில் புனித குகை வருகை',
      'specialAbhishekam': 'சிறப்பு அபிஷேகம்',
      'specialAbhishekamDesc': 'குருக்களுடன் முன்னுரிமை அபிஷேகம்',
      'thangaratham': 'தங்க தேர்',
      'thangarathamDesc': 'தங்க ரதம் திருவிழா ஊர்வலம்',
      'annadhanamDesc': 'அனைத்து யாத்ரீகர்களுக்கும் இலவச சைவ உணவு',
    },
  };

  String? translate(String key) => _strings[locale.languageCode]?[key];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
