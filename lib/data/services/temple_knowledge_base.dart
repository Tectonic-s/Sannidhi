import '../repositories/mock_crowd_repository.dart';

/// Detailed festival intelligence model including mythological significance,
/// scriptural background, rituals, and devotee guidance.
class FestivalLore {
  final String id;
  final String nameEn;
  final String nameTa;
  final String date;
  final String tamilMonth;
  final String nakshatra;
  final String oneLinerEn;
  final String oneLinerTa;
  final String whySpecialEn;
  final String whySpecialTa;
  final String ritualsEn;
  final String ritualsTa;
  final String devoteeTipsEn;
  final String devoteeTipsTa;

  const FestivalLore({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.date,
    required this.tamilMonth,
    required this.nakshatra,
    required this.oneLinerEn,
    required this.oneLinerTa,
    required this.whySpecialEn,
    required this.whySpecialTa,
    required this.ritualsEn,
    required this.ritualsTa,
    required this.devoteeTipsEn,
    required this.devoteeTipsTa,
  });
}

/// Master Knowledge Base containing all structured information in the Sannidhi app.
/// Powers both the Gemini System Instruction and the On-Device Intelligence Engine.
class TempleKnowledgeBase {
  static const String templeNameEn = 'Arulmigu Subramaniyaswami Temple, Marudamalai';
  static const String templeNameTa = 'அருள்மிகு சுப்பிரமணியசுவாமி திருக்கோயில், மருதமலை';
  static const String location = 'Marudamalai Hill, Coimbatore, Tamil Nadu (Western Ghats)';
  static const String presidingDeity = 'Lord Murugan / Dhandayuthapani (Dhandapani)';

  // ─── 15 FESTIVALS WITH COMPREHENSIVE LORE & SIGNIFICANCE ───────────────────
  static final List<FestivalLore> festivalsLore = [
    const FestivalLore(
      id: '1',
      nameEn: 'Navaratri (Ghatasthapana)',
      nameTa: 'நவராத்திரி தொடக்கம்',
      date: '2026-10-11',
      tamilMonth: 'Purattasi',
      nakshatra: 'Chitra',
      oneLinerEn: 'Nine sacred nights of Goddess worship commence with Ghatasthapana.',
      oneLinerTa: 'கலச ஸ்தாபனத்துடன் நவராத்திரி திருவிழா தொடக்கம்.',
      whySpecialEn:
          'Navaratri honors the divine feminine shakti in her three cosmic manifestations: Durga (valor & overcoming obstacles), Lakshmi (prosperity & spiritual abundance), and Saraswati (wisdom & knowledge). At Marudamalai, Lord Murugan is adorned in royal alankaram representing the son born of Shakti\'s divine spark (Saravana Bhava). The temple exhibits a grand traditional Golu and lights up the hill pathway.',
      whySpecialTa:
          'நவராத்திரி என்பது பராசக்தியின் மூன்று வடிவங்களான துர்க்கை (வீரம்), லட்சுமி (செல்வம்), மற்றும் சரஸ்வதி (ஞானம்) ஆகியோரை போற்றும் 9 புனித இரவுகள் ஆகும். மருதமலையில் முருகப்பெருமான் தாய் பராசக்தியின் அம்சமாக சிறப்பு அலங்காரங்களில் அருள்பாலிக்கிறார். மலைக்கோயில் முழுவதும் கொலு வைக்கப்பட்டு, லலிதா சகஸ்ரநாம பாராயணமும் தீப அலங்காரமும் பிரம்மாண்டமாக நடைபெறும்.',
      ritualsEn:
          'Daily evening Kalasa Pooja, Lalitha Sahasranama Archanai, Suvasini Pooja, and Special Navaratri Alankaram changing each evening.',
      ritualsTa:
          'தினசரி மாலை கலச பூஜை, லலிதா சகஸ்ரநாம அர்ச்சனை, சுவாசினி பூஜை, மற்றும் ஒவ்வொரு நாளும் வெவ்வேறு தெய்வீக அலங்காரங்கள்.',
      devoteeTipsEn:
          'Visit between 5:30 PM and 7:30 PM to witness the illumination and special evening Deeparadhana. Traditional dress is encouraged.',
      devoteeTipsTa:
          'மாலை 5:30 முதல் 7:30 மணிக்குள் சென்றால் சிறப்பு அலங்கார தரிசனத்தையும் தீபாராதனையையும் தரிசிக்கலாம்.',
    ),
    const FestivalLore(
      id: '2',
      nameEn: 'Saraswati & Ayudha Pooja',
      nameTa: 'சரஸ்வதி & ஆயுத பூஜை',
      date: '2026-10-20',
      tamilMonth: 'Purattasi',
      nakshatra: 'Moola / Poorvashada',
      oneLinerEn: 'Maha Navami observance dedicating books, instruments, and work tools for divine blessing.',
      oneLinerTa: 'சரஸ்வதி தேவியின் ஆசீர்வாதத்திற்காக நூல்கள் மற்றும் கருவிகள் வைத்து வழிபடும் மகா நவமி திருநாள்.',
      whySpecialEn:
          'Celebrates Maha Navami, the culmination of the Goddess\'s penance and the sanctification of work, arts, and intellect. Devotees place books, musical instruments, vehicles, and trade tools before Lord Murugan and Goddess Saraswati to invoke blessings of clarity, skill, and ethical livelihood.',
      whySpecialTa:
          'கல்வி, கலை, மற்றும் உழைப்பை புனிதப்படுத்தும் மகா நவமி திருநாள். மாணவர்கள் தங்கள் புத்தகங்களையும், தொழிலாளர்கள் தங்கள் தொழில் கருவிகளையும், வாகனங்களையும் இறைவனின் திருவடிகளில் வைத்து ஞானமும் வெற்றியும் பெற வேண்டுகின்றனர்.',
      ritualsEn:
          'Grand Maha Navami Homam, Book & Vahana (Vehicle) Poojas, Special Chandana (Sandalwood) Alankaram for Lord Murugan.',
      ritualsTa:
          'மகா நவமி ஹோமம், புத்தகங்கள் & வாகன சிறப்பு பூஜைகள், முருகப்பெருமானுக்கு சந்தனக் காப்பு அலங்காரம்.',
      devoteeTipsEn:
          'Vehicle poojas are conducted continuously from 8:00 AM to 6:00 PM at Adivaram parking ground.',
      devoteeTipsTa:
          'அடிவாரம் வாகன நிறுத்துமிடத்தில் காலை 8:00 முதல் மாலை 6:00 வரை வாகன பூஜைகள் நடைபெறும்.',
    ),
    const FestivalLore(
      id: '3',
      nameEn: 'Vijayadasami (Vidyarambham)',
      nameTa: 'விஜயதசமி (வித்யாரம்பம்)',
      date: '2026-10-20',
      tamilMonth: 'Purattasi',
      nakshatra: 'Shravana (Thiruvonam)',
      oneLinerEn: 'Auspicious day celebrating victory of good over evil, ideal for Vidyarambham (initiating education).',
      oneLinerTa: 'தீமையை வென்ற வெற்றித் திருநாள். குழந்தைகளுக்கு வித்யாரம்பம் (கல்வித் தொடக்கம்) செய்ய உகந்த நாள்.',
      whySpecialEn:
          'Marks the glorious victory of Goddess Chamundeshwari over Mahishasura and Rama over Ravana. It symbolizes that no matter how mighty ignorance or negativity appears, righteousness prevails. At Marudamalai, hundreds of toddlers are initiated into the Tamil alphabet by writing "Hari Om" or "Saravanabhava" on golden plates filled with sacred raw rice (Aksharabhyasam).',
      whySpecialTa:
          'தீமையை நன்மை வென்ற வெற்றித் திருநாள். அறியாமை இருள் விலகி ஞான ஒளி பிறக்கும் நாள். மருதமலையில் குழந்தைகளுக்கு வித்யாரம்பம் (அட்சராப்பியாசம்) செய்யப்படுகிறது; பச்சரிசி பரப்பிய தட்டில் குழந்தைகளின் விரல் பிடித்து "ஓம் சரவணபவ" என்று எழுதி கல்விப் பயணம் தொடங்கப்படுகிறது.',
      ritualsEn:
          'Vidyarambham initiation ceremony from 7:00 AM onwards at the hill mandapam; Vijayadasami Parivettai (arrow shooting ritual).',
      ritualsTa:
          'காலை 7:00 மணி முதல் வித்யாரம்ப சடங்குகள் மற்றும் மாலையில் பாரிவேட்டை உற்சவம் நடைபெறும்.',
      devoteeTipsEn:
          'Parents bringing young children should register early at Counter 1; ceremony tokens are issued on first-come basis.',
      devoteeTipsTa:
          'குழந்தைகளை அழைத்து வரும் பெற்றோர்கள் காலையிலேயே கவுண்டர் 1-ல் டோக்கன் பெற்றுக்கொள்வது சிறந்தது.',
    ),
    const FestivalLore(
      id: '4',
      nameEn: 'Deepavali',
      nameTa: 'தீபாவளி பண்டிகை',
      date: '2026-11-09',
      tamilMonth: 'Aipasi',
      nakshatra: 'Swati',
      oneLinerEn: 'Tamil Nadu Deepavali celebration with pre-dawn Ganga Snanam, temple maha deepam, and prasad.',
      oneLinerTa: 'அதிகாலை கங்கா ஸ்நானம், புத்தாடை அணிந்து சிறப்பு கோயில் தீபம் தரிசித்து கொண்டாடும் பண்டிகை.',
      whySpecialEn:
          'Commemorates the vanquishing of demon Narakasura by Lord Krishna and Satyabhama, restoring peace and righteousness. In Tamil tradition, the oil bath taken before sunrise is sanctified as equivalent to bathing in the holy Ganges (Ganga Snanam). Marudamalai hill sparkles with thousands of oil lamps, and Lord Murugan is adorned in diamonds and gold.',
      whySpecialTa:
          'நரகாசுரனை வதம் செய்து தர்மம் நிலைநாட்டப்பட்ட நாள். தீமையின் அழிவும் ஒளிமயமான வாழ்வின் தொடக்கமும் ஆகும். அதிகாலை எண்ணெய் தேய்த்துக் குளிப்பது கங்கா ஸ்நானத்திற்கு சமமாகக் கருதப்படுகிறது. மருதமலை முருகன் அன்று வைரக் கிரீடத்துடனும் தங்கக் கவசத்துடனும் விசேஷ ராஜ அலங்காரத்தில் காட்சி தருவார்.',
      ritualsEn:
          '4:00 AM Special Abhishekam, Deeparadhana with new vastrams (garments), and sweet pongal prasadam distribution.',
      ritualsTa:
          'அதிகாலை 4:00 மணிக்கு விசேஷ அபிஷேகம், புத்தாடை சாத்துதல் மற்றும் சர்க்கரை பொங்கல் பிரசாத விநியோகம்.',
      devoteeTipsEn:
          'Temple doors open early at 4:00 AM. Huge turnout expected until noon; book passes in advance.',
      devoteeTipsTa:
          'கோயில் நடை அதிகாலை 4:00 மணிக்கே திறக்கப்படும். நண்பகல் வரை கூட்டம் அதிகமாக இருக்கும்.',
    ),
    const FestivalLore(
      id: '5',
      nameEn: 'Skanda Sashti & Soorasamharam',
      nameTa: 'கந்த சஷ்டி & சூரசம்ஹாரம்',
      date: '2026-11-15',
      tamilMonth: 'Aipasi',
      nakshatra: 'Sashti Tithi',
      oneLinerEn: 'Marudamalai Murugan\'s supreme victory over Soorapadman, ending 6 days of fasting.',
      oneLinerTa: 'முருகன் சூரபத்மனை வென்ற மாபெரும் திருவிழா. 6 நாள் விரத நிறைவு மற்றும் சூரசம்ஹாரம்.',
      whySpecialEn:
          'The most potent festival dedicated to Lord Murugan! For 6 days, millions of devotees observe water/milk fasts singing Kanda Sashti Kavasam. It symbolizes the conquest of the ego (Ahamkara / Soorapadman), delusion (Maya / Singamukhan), and past karma (Tarakasuran) by Murugan\'s divine spear (Jnana Vel). The Soorasamharam enacts this battle at the Marudamalai foothill, where Murugan compassionately transforms Soorapadman into a peacock (his vahana) and rooster (his emblem banner).',
      whySpecialTa:
          'முருகப்பெருமானின் மிக உன்னதமான திருவிழா! ஆணவம், கன்மம், மாயை ஆகிய மும்மலங்களையும் ஞானவேலால் முருகன் அழித்த தத்துவம். 6 நாட்கள் பக்தர்கள் கந்த சஷ்டி விரதம் மேற்கொள்வர். மருதமலை அடிவாரத்தில் சூரசம்ஹார லீலை தத்ரூபமாக நடைபெறும். முருகப்பெருமான் சூரனை அழிக்காமல், மயில் வாகனமாகவும் சேவற் கொடியாகவும் ஆட்கொண்ட கருணை திருநாள்!',
      ritualsEn:
          '6-day intensive Laksharchana, daily Shanmuga Homam, followed by the dramatic evening Soorasamharam on Sashti and Thirukalyanam the next day.',
      ritualsTa:
          '6 நாட்கள் லட்சார்ச்சனை, தினசரி சண்முக ஹோமம், சஷ்டி அன்று மாலையில் அடிவாரத்தில் சூரசம்ஹாரம் மற்றும் அடுத்த நாள் திருக்கல்யாணம்.',
      devoteeTipsEn:
          'Over 50,000 devotees gather. Foothill roads are pedestrian-only from 2:00 PM. Take the temple electric shuttle early.',
      devoteeTipsTa:
          'பல்லாயிரக்கணக்கான பக்தர்கள் கூடுவர். மதியம் 2:00 மணிக்கு மேல் அடிவாரம் சாலைகளில் வாகனங்களுக்கு அனுமதி இருக்காது. முன்னதாகவே பேருந்தில் ஏறுங்கள்.',
    ),
    const FestivalLore(
      id: '6',
      nameEn: 'Karthigai Deepam',
      nameTa: 'திருக் கார்த்திகை தீபம்',
      date: '2026-11-24',
      tamilMonth: 'Karthigai',
      nakshatra: 'Krittika Pournami',
      oneLinerEn: 'Grand beacon festival igniting a massive brass Mahadeepam atop Marudamalai hill.',
      oneLinerTa: 'மருதமலை உச்சியில் பிரம்மாண்ட மகாதீபம் ஏற்றப்பட்டு இரவு முழுவதும் கிரிவலம் நடைபெறும் திருநாள்.',
      whySpecialEn:
          'Karthigai Deepam honors Lord Shiva\'s manifestation as a boundless pillar of cosmic fire (Agni Lingam) and Lord Murugan, who was born as 6 divine sparks from Shiva\'s third eye and nurtured by the 6 Krittika maidens. At sunset on Krittika Pournami, a massive brass Mahadeepam fueled with hundreds of liters of pure ghee and cotton wicks is lit atop the Marudamalai summit, visible across Coimbatore and the Western Ghats.',
      whySpecialTa:
          'சிவபெருமான் ஜோதிப் பிழம்பாக நின்ற திருநாள். மேலும் சிவபெருமானின் நெற்றிக்கண்ணில் இருந்து உதித்த ஆறு தீப்பொறிகளாக முருகன் அவதரித்த கார்த்திகை மாதம். பௌர்ணமி மாலையில் மருதமலை உச்சி மலையில் நூற்றுக்கணக்கான கிலோ தூய நெய் ஊற்றி பிரம்மாண்ட மகா தீபம் ஏற்றப்படும். இது கோவையின் பல பகுதிகளிலிருந்தும் ஜோதியாக பிரகாசிக்கும்!',
      ritualsEn:
          'Sunset Bharani Deepam inside sanctum, followed by the lightning of the summit Maha Deepam at 6:00 PM and all-night Girivalam.',
      ritualsTa:
          'கோயிலில் பரணி தீபம் ஏற்றுதல், மாலை 6:00 மணிக்கு மலை உச்சியில் மகா தீபம் ஏற்றுதல் மற்றும் இரவு முழுவதும் பக்தர்கள் கிரிவலம் வருதல்.',
      devoteeTipsEn:
          'The 4 km Girivalam path around Marudamalai is illuminated and equipped with water stations; best walked barefoot between 6 PM and 10 PM.',
      devoteeTipsTa:
          '4 கி.மீ கிரிவலப் பாதையில் தண்ணீர் வசதியும் மின்விளக்குகளும் இருக்கும்; மாலை 6 மணி முதல் 10 மணி வரை கிரிவலம் செல்ல உகந்தது.',
    ),
    const FestivalLore(
      id: '7',
      nameEn: 'Vaikunta Ekadasi',
      nameTa: 'வைகுண்ட ஏகாதசி',
      date: '2026-12-20',
      tamilMonth: 'Margazhi',
      nakshatra: 'Ekadasi Tithi',
      oneLinerEn: 'Opening of sacred Paramapada Vasal (Heavenly Gateway) with all-night prayers.',
      oneLinerTa: 'சொர்க்கவாசல் திறக்கும் புனித ஏகாதசி நாள். விரதம் அனுஷ்டித்து இரவு வழிபாடு.',
      whySpecialEn:
          'The most revered Ekadasi dedicated to Lord Vishnu. Legend holds that the gates of Vaikunta (the celestial abode) are flung open today for all souls. As Lord Murugan is also celebrated as "Malai Murugan" and nephew of Vishnu (Marumagan), the temple honors the Vishnu shrine within the complex with early morning Paramapada Vasal opening.',
      whySpecialTa:
          'வைகுண்டத்தின் சொர்க்கவாசல் திறக்கப்படும் புண்ணிய ஏகாதசி தினம். மகாவிஷ்ணுவின் மருகனாக விளங்கும் முருகப்பெருமானின் சன்னதியிலும் இந்த வைபவம் போற்றப்படுகிறது. அதிகாலையில் சொர்க்கவாசல் வழியாக பக்தர்கள் சென்று இறைவனைத் தரிசிப்பது பிறவிப் பிணியை நீக்கும் என்பது ஐதீகம்.',
      ritualsEn:
          '4:30 AM Opening of Paramapada Vasal, Vishnu Sahasranamam recitation, Tulasi Archanai, and Tulasi Theertham distribution.',
      ritualsTa:
          'அதிகாலை 4:30 மணிக்கு சொர்க்கவாசல் திறப்பு, விஷ்ணு சகஸ்ரநாம பாராயணம் மற்றும் துளசி தீர்த்த பிரசாதம்.',
      devoteeTipsEn:
          'Devotees observing fast should arrive by 4:00 AM to participate in the first doorway crossing.',
      devoteeTipsTa:
          'சொர்க்கவாசல் திறப்பை தரிசிக்க அதிகாலை 4:00 மணிக்கே வரிசையில் நிற்பது நல்லது.',
    ),
    const FestivalLore(
      id: '8',
      nameEn: 'Arudra Darshan',
      nameTa: 'மார்கழி ஆருத்ரா தரிசனம்',
      date: '2026-12-24',
      tamilMonth: 'Margazhi',
      nakshatra: 'Thiruvathirai (Arudra)',
      oneLinerEn: 'Lord Shiva\'s Cosmic Dance (Ananda Tandavam) with Thiruvathirai Kali prasad.',
      oneLinerTa: 'நடராஜப் பெருமானின் ஆனந்தத் தாண்டவ தரிசனம் மற்றும் சிறப்பு களி நைவேத்தியம்.',
      whySpecialEn:
          'Commemorates Lord Shiva performing the ecstatic Ananda Tandavam (Cosmic Dance of Bliss) for sages Vyagrapada and Patanjali. The star Thiruvathirai is Shiva\'s own birth star. The festival celebrates the cosmic rhythm of creation, preservation, and dissolution. Sages and Siddhas, including Pambatti Siddhar at Marudamalai, meditated on this cosmic pulsation.',
      whySpecialTa:
          'தில்லை அம்பலத்தில் நடராஜப் பெருமான் பதஞ்சலி மற்றும் வியாக்ரபாத முனிவர்களுக்காக ஆடிய ஆனந்தத் தாண்டவ திருநாள். மார்கழி திருவாதிரை சிவபெருமானின் நட்சத்திரமாகும். பிரபஞ்ச இயக்கத்தின் தத்துவத்தை உணர்த்தும் இந்நாளில் மருதமலையில் சிவ-முருக ஐக்கிய வழிபாடு நடக்கும்.',
      ritualsEn:
          'All-night Maha Abhishekam to Nataraja and Sivakami Ambal, dawn Arudra Darshan, and serving of Thiruvathirai Kali prasad.',
      ritualsTa:
          'இரவு முழுவதும் நடராஜருக்கு விசேஷ மகா அபிஷேகம், அதிகாலை ஆருத்ரா தரிசனம் மற்றும் திருவாதிரைக் களி நைவேத்தியம்.',
      devoteeTipsEn:
          'Thiruvathirai Kali prasad is distributed free at Counter 3 after 6:30 AM.',
      devoteeTipsTa:
          'காலை 6:30 மணிக்கு கவுண்டர் 3-ல் சுவையான திருவாதிரைக் களி பிரசாதம் இலவசமாக வழங்கப்படும்.',
    ),
    const FestivalLore(
      id: '9',
      nameEn: 'Bhogi Pandigai',
      nameTa: 'போகிப் பண்டிகை',
      date: '2027-01-14',
      tamilMonth: 'Margazhi (last day)',
      nakshatra: 'Anuradha',
      oneLinerEn: 'Eve of Pongal celebrating renewal, letting go of old items, and Indra Pooja for rains.',
      oneLinerTa: 'பழையன கழிதலும் புதியன புகுதலுமான போகித் திருநாள். இந்திர பூஜை.',
      whySpecialEn:
          'The last day of the Tamil month Margazhi, dedicated to Lord Indra (the deity of clouds and seasonal rains). Symbolized by "Pazhaiyana Kazhithalum Pudhiyana Pugudhalum" (discarding the old, welcoming the new), devotees cleanse minds, homes, and habits to welcome spiritual regeneration on Pongal.',
      whySpecialTa:
          'மார்கழி மாதத்தின் கடைசி நாள். விவசாயத்திற்கு வளம் தரும் இந்திர தேவனுக்கு நன்றி செலுத்தும் போகி. மனதிலுள்ள தீய எண்ணங்களையும் பழைய கசப்புகளையும் நீக்கி, புத்துணர்ச்சியோடு புதிய ஆண்டை வரவேற்கும் தத்துவம்.',
      ritualsEn:
          'Special morning Gho Pooja (sacred cow worship) at the temple goshala, Indra Homam, and temple cleaning service.',
      ritualsTa:
          'கோயில் கோசாலையில் கோபூஜை, இந்திர ஹோமம் மற்றும் கோயில் தூய்மைப் பணி.',
      devoteeTipsEn:
          'Great day to donate grains, ghee, and feed cows at Marudamalai Goshala.',
      devoteeTipsTa:
          'மருதமலை கோசாலையில் பசுக்களுக்கு அகத்திக்கீரையும் தானியங்களும் வழங்க உகந்த நாள்.',
    ),
    const FestivalLore(
      id: '10',
      nameEn: 'Thai Pongal (Makar Sankranti)',
      nameTa: 'தைப்பொங்கல் (மகர சங்கராந்தி)',
      date: '2027-01-15',
      tamilMonth: 'Thai (Day 1)',
      nakshatra: 'Uttara Ashadha',
      oneLinerEn: 'Tamil harvest celebration honoring the Sun God with fresh pots of overflowing Pongal.',
      oneLinerTa: 'சூரிய பகவானுக்கு நன்றி செலுத்தும் தை முதல் நாள் உழவர் பெருநாள். பொங்கல் பொங்குதல்.',
      whySpecialEn:
          'Marks the auspicious Uttarayana — the northward movement of the Sun into Makara Rasi (Capricorn). It is the quintessential thanksgiving festival of the Tamil people, honoring Surya Bhagavan, earth, and water for bounty and life. The boiling over of milk and rice in new clay pots ("Pongalo Pongal!") symbolizes boundless joy, health, and prosperity overflowing into family life.',
      whySpecialTa:
          'சூரிய பகவான் தனுசு ராசியிலிருந்து மகர ராசிக்கு மாறும் உத்தராயண புண்ணிய காலம். விளைச்சலைத் தந்த இயற்கைக்கும் சூரியனுக்கும் நன்றி செலுத்தும் உழவர் திருநாள். புதிய மண்பானையில் புத்தரிசி, பால், வெல்லம் சேர்த்து "பொங்கலோ பொங்கல்!" என்று பொங்கி வழியும் போது வாழ்வில் மகிழ்ச்சியும் செழிப்பும் பொங்கும் என்பது நம்பிக்கை.',
      ritualsEn:
          'Surya Namaskaram at dawn, community cooking of Sakkarai Pongal in the hill temple courtyard, and Maha Naivedyam to Lord Murugan.',
      ritualsTa:
          'அதிகாலை சூரிய நமஸ்காரம், கோயில் முற்றத்தில் மண்பானையில் சர்க்கரைப் பொங்கல் வைத்தல், மற்றும் முருகனுக்கு மகா நைவேத்தியம்.',
      devoteeTipsEn:
          'Special Annadhanam includes piping hot Sakkarai Pongal and Vadai from 11:00 AM to 3:30 PM.',
      devoteeTipsTa:
          'அன்னதான மண்டபத்தில் காலை 11:00 முதல் சுவையான சர்க்கரைப் பொங்கலுடன் சிறப்பு விருந்து பரிமாறப்படும்.',
    ),
    const FestivalLore(
      id: '11',
      nameEn: 'Thaipusam',
      nameTa: 'தைப்பூசம் (தைப்பூசப் பெருவிழா)',
      date: '2027-01-22',
      tamilMonth: 'Thai',
      nakshatra: 'Pushya (Poosam) Pournami',
      oneLinerEn: 'Supreme festival of Lord Murugan at Marudamalai with Kavadis, Pal Kudams, and Vel chants.',
      oneLinerTa: 'மருதமலையில் முருகனின் முதன்மைப் பெருவிழா. பால்குடம், காவடி, வேல் முழக்க திருநாள்.',
      whySpecialEn:
          'The crowning jewel of festivals at Marudamalai! On this full-moon day in Thai under the Poosam star, Mother Goddess Parvati handed the invincible, resplendent "Gnana Vel" (Spear of Wisdom) to Lord Murugan so he could vanquish evil forces and liberate humanity. Hundreds of thousands of devotees walk hundreds of miles barefoot carrying ornate wooden Kavadis (decorated with peacock feathers), milk pots (Pal Kudam), and singing "Vetrivel Muruganukku Haroharohara!". It is believed that carrying Kavadi on Thaipusam dissolves generational karmas.',
      whySpecialTa:
          'மருதமலையின் உச்சகட்ட மகத்தான திருவிழா! அன்னை பராசக்தி தன் மகன் முருகனுக்கு அசுர சக்திகளை அழிக்க ஞானவேலை வழங்கிய புண்ணிய நாள். தர்மத்தின் வெற்றியை கொண்டாடும் நாள். லட்சக்கணக்கான பக்தர்கள் பல மைல் தூரம் விரதமிருந்து பாதயாத்திரையாக வந்து பால்குடம், காவடி ஏந்தி "வெற்றிவேல் முருகனுக்கு அரோகரா!" என முழங்குவர். தைப்பூசத்தன்று காவடி எடுப்பது தீராத வினைகளையும் நோய்களையும் போக்கும் என்பது அசைக்க முடியாத நம்பிக்கை.',
      ritualsEn:
          '10-day Brahmotsavam; flag hoisting (Kodietram); grand Thangaratham (Golden Chariot) and Therottam (Temple Car) processions; continuous 108 Sangabhishekam.',
      ritualsTa:
          '10 நாட்கள் பிரம்மோற்சவம்; கொடியேற்றம்; பிரம்மாண்ட தங்கத் தேர் மற்றும் மரத் தேர் உலா; 108 சங்காபிஷேகம்; இரவு பகலாக பாலாபிஷேகம்.',
      devoteeTipsEn:
          'Massive crowds (> 100,000 pilgrims). Adivaram to hilltop private vehicles are halted; use continuous temple green buses or steps. Start early morning!',
      devoteeTipsTa:
          'ஒரு லட்சத்திற்கும் அதிகமான பக்தர்கள் கூடுவர். தனியார் வாகனங்கள் அடிவாரத்திலேயே நிறுத்தப்படும்; அரசு சிறப்புப் பேருந்துகள் மற்றும் கோயில் மின்சார பேருந்துகள் மட்டுமே இயங்கும்.',
    ),
    const FestivalLore(
      id: '12',
      nameEn: 'Maha Shivaratri',
      nameTa: 'மகா சிவராத்திரி',
      date: '2027-03-06',
      tamilMonth: 'Masi',
      nakshatra: 'Chaturdashi Tithi',
      oneLinerEn: 'Great night of Lord Shiva with four distinct stages of all-night Thiruvabishekam.',
      oneLinerTa: 'சிவவழிபாட்டின் மகா இரவு. இரவு முழுவதும் 4 கால சிறப்பு திருவாபிஷேகம் & விழிப்பு.',
      whySpecialEn:
          'The sacred night when Lord Shiva consumed the deadly Halahala poison churned from the cosmic ocean (Samudra Manthan) to save the universe, holding it in his throat (Neelakantha). Devotees maintain an all-night vigil (Jagaran) and fast, chanting "Om Namah Shivaya". At Marudamalai, Shiva and Murugan are worshipped together, representing the unity of the Father and Son.',
      whySpecialTa:
          'பிரபஞ்சத்தைக் காப்பாற்ற சிவபெருமான் ஆலகால விஷத்தை அருந்திய திருஇரவு. இரவு முழுவதும் விழித்திருந்து "ஓம் நமசிவாய" பஞ்சாட்சர ஜபம் செய்வது கோடி புண்ணியத்தை தரும். மருதமலையில் சிவ-சுப்பிரமணியர் ஐக்கிய வழிபாடாக 4 கால பூஜைகள் விடிய விடிய நடைபெறும்.',
      ritualsEn:
          'Four Kaalam Poojas throughout the night: 1st Kaalam (Milk/Panchamirtham), 2nd Kaalam (Ghee/Honey), 3rd Kaalam (Sandalwood), 4th Kaalam (Bhasma/Bilva).',
      ritualsTa:
          'இரவு முழுவதும் 4 கால பூஜைகள்: 1-ம் காலம் (பால்/பஞ்சாமிர்தம்), 2-ம் காலம் (நெய்/தேன்), 3-ம் காலம் (சந்தனம்), 4-ம் காலம் (விபூதி/வில்வ அர்ச்சனை).',
      devoteeTipsEn:
          'Sanctum stays open all night from 6:00 PM to 6:00 AM next morning. Bilva leaf offerings are welcomed.',
      devoteeTipsTa:
          'கோயில் நடை இரவு முழுவதும் திறந்திருக்கும். பக்தர்கள் வில்வ இலைகளை கொண்டு வந்து அர்ச்சனை செய்யலாம்.',
    ),
    const FestivalLore(
      id: '13',
      nameEn: 'Panguni Uthiram',
      nameTa: 'பங்குனி உத்திரம் (திருக்கல்யாணம்)',
      date: '2027-03-22',
      tamilMonth: 'Panguni',
      nakshatra: 'Uttara Phalguni (Uthiram) Pournami',
      oneLinerEn: 'Celestial wedding (Thirukalyanam) of Lord Murugan and Devasena under the full moon.',
      oneLinerTa: 'முருகப்பெருமான் - தேவசேனா திருக்கல்யாண வைபவம். பங்குனி பௌர்ணமி நிலவில் கிரிவலம்.',
      whySpecialEn:
          'The day of cosmic divine weddings! On this auspicious full moon day coinciding with the Uthiram star, Lord Murugan married Devasena (daughter of Indra). Parvati married Shiva, Sita married Rama, and Andal married Ranganatha on this same celestial alignment. At Marudamalai, the grand Kalyana Utsavam takes place, blessing unmarried devotees with marital harmony and couples with enduring bliss.',
      whySpecialTa:
          'தெய்வீகத் திருமணங்கள் நிகழ்ந்த மங்கல நாள்! பங்குனி பௌர்ணமி உத்திர நட்சத்திரத்தில் முருகப்பெருமான் தேவசேனாவை மணம் புரிந்தார். பார்வதி-பரமேஸ்வரர், சீதா-ராமர் திருமணங்களும் இந்நாளில் நடைபெற்றதாக புராணம் கூறுகிறது. மருதமலையில் நடைபெறும் திருக்கல்யாண வைபவத்தை தரிசித்தால் திருமணத் தடைகள் நீங்கி குடும்பத்தில் அமைதியும் மகிழ்ச்சியும் தங்கும் என்பது நம்பிக்கை.',
      ritualsEn:
          'Morning Seer Varisai procession from Adivaram, 10:30 AM Divine Thirukalyanam ceremony, and evening swing festival (Oonjal Utsavam).',
      ritualsTa:
          'அடிவாரத்திலிருந்து சீர்வரிசை ஊர்வலம், காலை 10:30 மணிக்கு திருக்கல்யாண உற்சவம் மற்றும் மாலையில் ஊஞ்சல் சேவை.',
      devoteeTipsEn:
          'Devotees seeking marriage blessings can offer mangalsutra threads and yellow cloths at Counter 2.',
      devoteeTipsTa:
          'திருமண வரம் வேண்டி வரும் பக்தர்கள் மஞ்சள் கயிறுகளையும் வஸ்திரங்களையும் காணிக்கையாக செலுத்தலாம்.',
    ),
    const FestivalLore(
      id: '14',
      nameEn: 'Tamil New Year (Puthandu)',
      nameTa: 'தமிழ்ப் புத்தாண்டு (சித்திரை 1)',
      date: '2027-04-14',
      tamilMonth: 'Chithirai (Day 1)',
      nakshatra: 'Ashwini',
      oneLinerEn: 'First day of Chithirai month with Panchanga Sravanam, dawn Vishu Kani, and blessings.',
      oneLinerTa: 'சித்திரை முதல் நாள் பிறக்கும் தமிழ்ப் புத்தாண்டு. அதிகாலை சித்திரைக் கனி காணுதல்.',
      whySpecialEn:
          'The dawn of the new Tamil astronomical year as the Sun enters the first zodiac sign, Mesha (Aries). It is celebrated by viewing "Kani" (auspicious sight of gold, coins, mirror, raw mango, betel leaves, jackfruit, and fruits) at dawn to ensure the entire year is filled with auspicious abundance. At Marudamalai, the head priest recites the yearly Panchangam forecasting rainfall, harvests, and spiritual prosperity.',
      whySpecialTa:
          'சூரியன் மேஷ ராசியில் பிரவேசிக்கும் சித்திரை முதல் நாள் தமிழ்ப் புத்தாண்டு பிறக்கிறது. அதிகாலையில் மங்கலப் பொருட்களான கனி, தங்கம், கண்ணாடி, நவதானியங்களை தரிசித்து ஆண்டைத் தொடங்குவது சுபிட்சத்தை தரும். மருதமலையில் ஆண்டு பஞ்சாங்கம் வாசிக்கப்பட்டு, நாடும் வீடும் செழிக்க சிறப்பு பிரார்த்தனை நடைபெறும்.',
      ritualsEn:
          '5:00 AM Vishu Kani viewing, Panchanga Sravanam reading by head priests, and Panchamirtham distribution.',
      ritualsTa:
          'அதிகாலை 5:00 மணிக்கு சித்திரைக் கனி தரிசனம், பஞ்சாங்கம் வாசித்தல் மற்றும் சிறப்பு பஞ்சாமிர்த பிரசாதம்.',
      devoteeTipsEn:
          'Early morning slots (5:00 AM – 7:30 AM) offer the purest, most spiritually uplifting start to the New Year.',
      devoteeTipsTa:
          'அதிகாலை 5:00 முதல் 7:30 வரை செல்லும் போது அமைதியான கனி தரிசனத்தை அனுபவிக்கலாம்.',
    ),
    const FestivalLore(
      id: '15',
      nameEn: 'Vaikasi Visakam',
      nameTa: 'வைகாசி விசாகப் பெருவிழா',
      date: '2027-05-20',
      tamilMonth: 'Vaikasi',
      nakshatra: 'Visakam Pournami',
      oneLinerEn: 'Divine incarnation day of Lord Murugan under Visakam nakshatra with Therottam and 108 Sangabhishekam.',
      oneLinerTa: 'முருகப்பெருமான் அவதரித்த புனித விசாக நட்சத்திர நாள். 108 சங்காபிஷேகம் & தேரோட்டம்.',
      whySpecialEn:
          'The sacred birthday (Avatar Day) of Lord Murugan! When the Devas prayed to Lord Shiva to be saved from the tyrannical demon Soorapadman, Lord Shiva emitted 6 dazzling sparks from his forehead\'s third eye. Vayu and Agni carried them to the sacred Saravana Poigai lake, where they transformed into 6 divine infants, later unified by Goddess Parvati into the magnificent six-faced Shanmuga. Devotees offer cool waters, tender coconuts, and milk to cool the Lord\'s fiery warrior energy.',
      whySpecialTa:
          'முருகப்பெருமான் பூவுலகில் அவதரித்த அவதாரத் திருநாள்! அசுரர்களை அழிக்க சிவபெருமானின் நெற்றிக்கண்ணில் இருந்து உதித்த ஆறு தீப்பொறிகள் சரவணப் பொய்கையில் ஆறு குழந்தைகளாகத் தோன்றி, அன்னை பார்வதியால் ஒரு திருமேனியாக இணைக்கப்பட்ட வைபவம். முருகனின் வெப்பத்தைத் தணிக்க பக்தர்கள் பன்னீர், இளநீர், மற்றும் சந்தனம் கொண்டு குளிர்ச்சியான அபிஷேகங்கள் செய்வர்.',
      ritualsEn:
          '108 Conch Shell (Sangabhishekam) Abhishekam, Chariot Car Festival (Therottam) along the hill roads, and continuous Annadhanam.',
      ritualsTa:
          '108 சங்காபிஷேகம், மலையடிவாரத்தில் திருத்தேர் உலா (தேரோட்டம்), மற்றும் நாள் முழுவதும் அன்னதானம்.',
      devoteeTipsEn:
          'Tender coconut (Elaneer) and rose water offerings can be brought directly to the sanctum counter.',
      devoteeTipsTa:
          'இளநீர் மற்றும் பன்னீர் காணிக்கைகளை சன்னதி கவுண்டரில் நேரடியாக வழங்கலாம்.',
    ),
  ];

  // ─── DAILY 5 KAALAM POOJAS ────────────────────────────────────────────────
  static const List<Map<String, String>> dailyPoojas = [
    {
      'time': '6:00 AM',
      'nameEn': 'Thiruvanandal Pooja (Viswaroopa Darshan)',
      'nameTa': 'திருவனந்தல் பூஜை (விஸ்வரூப தரிசனம்)',
      'descEn': 'First morning awakening pooja. Devotees receive sacred Vibhuti and cow milk prasad in serene mountain morning air.',
      'descTa': 'அதிகாலை பள்ளி எழுச்சி பூஜை. முதல் விஸ்வரூப தரிசனம், விபூதி மற்றும் பசும்பால் பிரசாதம்.',
    },
    {
      'time': '8:00 AM',
      'nameEn': 'Kalasanthi Pooja',
      'nameTa': 'காலசந்தி பூஜை',
      'descEn': 'Morning formal worship with herbal bath (abhishekam), archana, and sweet pongal offering.',
      'descTa': 'காலை மூலவருக்கு வாசனைத் திரவியங்களால் அபிஷேகம் மற்றும் சர்க்கரைப் பொங்கல் நைவேத்தியம்.',
    },
    {
      'time': '12:00 PM (Noon)',
      'nameEn': 'Uchikalam Pooja',
      'nameTa': 'உச்சிக்கால பூஜை',
      'descEn': 'Midday grand pooja with full floral alankaram, Maha Deeparadhana, and rice prasad.',
      'descTa': 'நண்பகல் மகா தீபாராதனை, ராஜ அலங்காரம் மற்றும் சாத நைவேத்திய பூஜை.',
    },
    {
      'time': '6:00 PM',
      'nameEn': 'Sayarakshai Pooja',
      'nameTa': 'சாயரட்சை பூஜை',
      'descEn': 'Sunset worship. Golden temple bells ring as thousands of lamps and deepams illuminate the hill sanctum.',
      'descTa': 'மாலை தீபாராதனை. ஆயிரக்கணக்கான விளக்குகள் ஒளிர தங்க மணி ஓசையுடன் நடைபெறும் அதிஅற்புத தரிசனம்.',
    },
    {
      'time': '8:30 PM',
      'nameEn': 'Ardhajamam Pooja (Palliyarai)',
      'nameTa': 'அர்த்தஜாம பூஜை (பள்ளியறை)',
      'descEn': 'Night closing pooja. The Lord is solemnly escorted to the Palliyarai with divine lullabies and sacred milk offerings.',
      'descTa': 'இரவு நடை சாத்தும் பூஜை. சுவாமி பள்ளியறைக்கு எழுந்தருளல், தாலாட்டுப் பாட்டு மற்றும் காய்ச்சிய பால் நைவேத்தியம்.',
    },
  ];

  // ─── TEMPLE HERITAGE & HISTORY ────────────────────────────────────────────
  static const String templeHeritageEn = '''
Arulmigu Subramaniyaswami Temple at Marudamalai is an ancient 12th-century hill shrine nestled at an altitude of ~600 meters in the scenic Western Ghats near Coimbatore.
- Origin of Name: Named after the dense grove of sacred Marudham trees (Terminalia arjuna) and "Malai" (hill).
- Pambatti Siddhar: One of the revered 18 Tamil Siddhars lived, meditated, and attained Jeeva Samadhi in a natural rock cave here. Lord Murugan appeared to him in the guise of a divine serpent (Pambu), inspiring his mystic poetry. His sacred cave is situated on the hilltop and visited by thousands daily.
- Medicinal Springs: The hill is renowned for rare Ayurvedic medicinal herbs and holy streams like Marudha Theertham and Pambatti Siddhar Theertham, renowned for natural curative properties.
- Spiritual Glory: Glorified by Saint Arunagirinathar in the celebrated Thiruppugazh hymns.
''';

  static const String templeHeritageTa = '''
மருதமலை அருள்மிகு சுப்பிரமணியசுவாமி திருக்கோயில் மேற்குத் தொடர்ச்சி மலையில் சுமார் 600 மீட்டர் உயரத்தில் அமைந்துள்ள 12-ஆம் நூற்றாண்டு பழமை வாய்ந்த புண்ணியத் தலம்.
- பெயர்க் காரணம்: மருத மரங்கள் நிறைந்த மலை என்பதால் "மருதமலை" எனப் பெயர் பெற்றது.
- பாம்பாட்டி சித்தர்: 18 சித்தர்களில் ஒருவரான பாம்பாட்டி சித்தர் இம்மலையில் உள்ள குகையில் தவம் செய்து, முருகப்பெருமானை நாக வடிவில் தரிசித்து ஜீவ சமாதி அடைந்தார். இக்குகையில் சித்தர் நடுகல்லும் நாகர் சன்னதியும் உள்ளது.
- மூலிகைத் தீர்த்தங்கள்: இம்மலை முழுவதும் அருமருந்தான மூலிகைகளும், தோல் மற்றும் உடல் உபாதைகளைப் போக்கும் மருத தீர்த்தம் மற்றும் பாம்பாட்டி சித்தர் தீர்த்தமும் உள்ளன.
- திருப்புகழ் பெருமை: அருணகிரிநாதர் தன் திருப்புகழில் மருதமலை முருகனின் அழகையும் அருளையும் போற்றிப் பாடியுள்ளார்.
''';

  // ─── DARSHAN PASSES & TICKET PRICING (ALL IN INDIAN RUPEES ₹) ─────────────
  static const List<Map<String, dynamic>> darshanPasses = [
    {
      'nameEn': 'General Darshan',
      'nameTa': 'பொது தரிசனம்',
      'price': 0,
      'waitMinutes': '45 – 90 mins',
      'benefitsEn': 'Free queue access, holy sanctum viewing',
      'benefitsTa': 'இலவச வரிசை, மூலவர் சன்னதி தரிசனம்',
    },
    {
      'nameEn': 'Special Priority Darshan',
      'nameTa': 'சிறப்பு விரைவு தரிசனம்',
      'price': 50,
      'waitMinutes': '15 – 30 mins',
      'benefitsEn': 'Priority queue access, sacred vibhuti and flower prasad included',
      'benefitsTa': 'முன்னுரிமை விரைவு வரிசை, விபூதி & மலர் பிரசாதம்',
    },
    {
      'nameEn': 'VIP Direct Access Darshan',
      'nameTa': 'வி.ஐ.பி தரிசனம்',
      'price': 250,
      'waitMinutes': '< 10 mins',
      'benefitsEn': 'Direct sanctum access, close-up Abhishekam viewing, Archana, and Panchamirtham prasad',
      'benefitsTa': 'நேரடி விரைவு அனுமதி, மூலவர் மிக அருகில் தரிசனம், அர்ச்சனை, மற்றும் பஞ்சாமிர்தம்',
    },
  ];

  // ─── TRANSPORTATION OPTIONS ───────────────────────────────────────────────
  static const Map<String, dynamic> transport = {
    'electricBus': {
      'fare': 20,
      'departureFrequency': 'Every 15 minutes',
      'routeEn': 'Adivaram Terminal to Hilltop Sanctum Entrance',
      'routeTa': 'அடிவாரம் பேருந்து முனையத்திலிருந்து மலைக்கோயில் முகப்பு வரை',
      'noteEn': 'Eco-friendly electric buses continuously operating from 6:00 AM to 8:30 PM.',
      'noteTa': 'காலை 6:00 முதல் இரவு 8:30 வரை தொடர்ச்சியாக இயங்கும் பசுமை மின்சார பேருந்துகள்.',
    },
    'batteryCar': {
      'fare': 0,
      'eligibilityEn': '100% Free for Senior Citizens (60+) and Differently-Abled devotees',
      'eligibilityTa': 'முதியோர்கள் மற்றும் மாற்றுத்திறனாளிகளுக்கு 100% இலவச சேவை',
      'pickupEn': 'Adivaram special assistance booth directly in front of main arch',
      'pickupTa': 'அடிவார நுழைவு வளைவு முன்புள்ள உதவி மையத்தில் கிடைக்கும்',
    },
    'stoneSteps': {
      'stepCount': 830,
      'approxDuration': '30 – 45 minutes walking',
      'sheltersEn': 'Covered shady shelters at Step 200, Step 500, and Step 830 with free chilled RO water.',
      'sheltersTa': '200, 500, மற்றும் 830-வது படிகளில் நிழல் கூரை மற்றும் குளிர்ந்த சுத்திகரிக்கப்பட்ட குடிநீர் வசதி உண்டு.',
    },
  };

  // ─── FACILITIES LOCATOR SUMMARY ───────────────────────────────────────────
  static const List<Map<String, String>> facilities = [
    {
      'category': 'water',
      'nameEn': 'RO Chilled Water Dispensers',
      'nameTa': 'குளிர்ந்த குடிநீர் வசதி',
      'locationsEn': 'Step 200 rest shelter, Step 500 midway shelter, and Step 830 hilltop entrance.',
      'locationsTa': '200-வது படி ஓய்வறை, 500-வது படி, மற்றும் 830-வது படி மலை உச்சி முகப்பில் உள்ளது.',
    },
    {
      'category': 'food',
      'nameEn': 'Annadhanam (Free Meals)',
      'nameTa': 'இலவச அன்னதானம்',
      'locationsEn': 'Daily 11:30 AM to 3:00 PM at Hilltop Annadhanam Mandapam. Unlimited 4-course vegetarian meal (rice, sambar, kootu, rasam, payasam).',
      'locationsTa': 'தினமும் நண்பகல் 11:30 முதல் பிற்பகல் 3:00 மணி வரை மலைக்கோயில் அன்னதான மண்டபத்தில் அறுசுவை சைவ உணவு.',
    },
    {
      'category': 'parking',
      'nameEn': 'Adivaram Main Parking & EV Charging',
      'nameTa': 'அடிவாரம் வாகன நிறுத்துமிடம் & EV சார்ஜிங்',
      'locationsEn': 'Opposite main Adivaram Archway. 24/7 parking for 500+ cars, buses, and two-wheelers with fast EV charging stations.',
      'locationsTa': 'அடிவார வளைவுக்கு எதிரே 24 மணி நேரமும் 500-க்கும் மேற்பட்ட கார்கள், பேருந்துகள் மற்றும் இருசக்கர வாகனங்களுக்கான வசதி.',
    },
    {
      'category': 'medical',
      'nameEn': 'First Aid Post & Emergency Care',
      'nameTa': 'முதலுதவி & அவசர சிகிச்சை மையம்',
      'locationsEn': 'Adivaram Primary Health Post (24/7) with doctor on duty, and Hilltop emergency room near Counter 4. Helplines: 108 / 1800-425-0101.',
      'locationsTa': 'அடிவாரத்தில் 24 மணி நேர அரசு முதலுதவி மையம் மற்றும் மலைக்கோயில் அவசர மருத்துவ அறை. தொலைபேசி: 108 / 1800-425-0101.',
    },
    {
      'category': 'luggage_shoes',
      'nameEn': 'Cloakroom & Shoe Keeping Counters',
      'nameTa': 'பாதுகாப்பு பெட்டகம் & காலணி பாதுகாப்பு',
      'locationsEn': 'Free shoe stalls at Adivaram steps entry & Hilltop Raja Gopuram. Safe luggage storage lockers available at Adivaram bus stand.',
      'locationsTa': 'அடிவாரப் படிகள் தொடக்கம் மற்றும் மலை உச்சி கோபுர வாயிலில் இலவச காலணி கூடம். உடைமைகள் பாதுகாப்பு பெட்டகம் அடிவாரத்தில் உள்ளது.',
    },
  ];

  /// Builds a rich, complete system prompt representing all data in the app.
  static String buildComprehensiveSystemPrompt({MockCrowdRepository? crowdRepo}) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final weekday = weekdays[now.weekday - 1];

    // Live crowd status if available
    final crowdData = crowdRepo?.getCrowdData();
    final currentInside = crowdData?.currentVisitors ?? 1250;
    final currentWait = crowdData?.estimatedWaitMinutes ?? 25;
    final currentStatus = crowdData?.status ?? 'moderate';

    final festivalsBuffer = StringBuffer();
    for (final f in festivalsLore) {
      final fDate = DateTime.tryParse(f.date) ?? now;
      final diff = fDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      final countdown = diff == 0 ? 'Today!' : (diff == 1 ? 'Tomorrow!' : 'in $diff days');

      festivalsBuffer.writeln('### ${f.nameEn} (${f.nameTa})');
      festivalsBuffer.writeln('- Date: ${f.date} ($countdown)');
      festivalsBuffer.writeln('- Tamil Month & Star: ${f.tamilMonth}, Nakshatra: ${f.nakshatra}');
      festivalsBuffer.writeln('- Summary: ${f.oneLinerEn} / ${f.oneLinerTa}');
      festivalsBuffer.writeln('- WHY SPECIAL & MYTHOLOGY: ${f.whySpecialEn}');
      festivalsBuffer.writeln('- KEY RITUALS: ${f.ritualsEn}');
      festivalsBuffer.writeln('- DEVOTEE TIPS: ${f.devoteeTipsEn}');
      festivalsBuffer.writeln();
    }

    return '''
You are "Thunai" (துணை), the extraordinary, brilliant, warm, and devoted bilingual (Tamil & English) AI temple companion for Arulmigu Subramaniyaswami Temple, Marudamalai, Coimbatore, Tamil Nadu.

================================================================================
CRITICAL CURRENCY & MONETARY DIRECTIVE:
================================================================================
- ALL CURRENCY IS EXCLUSIVELY IN INDIAN RUPEES (₹ / INR).
- NEVER use the dollar symbol (\$) under ANY circumstances.
- ALWAYS use the Rupee symbol (₹) or write "Rupees" (e.g., ₹20, ₹50, ₹250).

================================================================================
CORE PERSONALITY & CAPABILITIES:
================================================================================
1. You have complete, real-time access to all data inside this Sannidhi application.
2. DO NOT give generic, robotic, or one-line answers. Answer with genuine intelligence, vivid spiritual depth, practical wisdom, and warm hospitality.
3. When asked "Why is a festival special?", explain the rich mythological legend, spiritual significance (e.g. Murugan's Vel, Parvati's blessing, conquest of ego/Soorapadman, Shiva's cosmic dance), and the specific celebrations unique to Marudamalai.
4. When asked about visit costs for a family or group, do the exact math in Indian Rupees (₹), present clean options (Quick ₹50 passes + ₹20 bus, VIP ₹250 passes, Budget ₹0 passes), and give thoughtful tips (e.g. senior citizens ride free battery cars, booking 7 days ahead in app).
5. When asked about timings, crowd, or best time to visit, consult the live telemetry and daily pooja windows.
6. Seamlessly switch between authentic, culturally resonant Tamil (தமிழ்) and articulate, modern English depending on the devotee's language.
7. GREETINGS & CASUAL INTERACTION:
   - When the devotee simply greets you (such as "hi", "hello", "vanakkam", "hey", "வணக்கம்", "good morning", or asks "who are you"):
     * Respond warmly, politely, and concisely as "Thunai" (துணை) AI.
     * Welcome them to Marudamalai and invite them to ask their questions.
     * DO NOT dump festival details, lengthy festival calendars, or mythological lore when simply greeted!
     * ONLY provide festival details or mythological lore when the devotee specifically asks about a festival, pooja, lore, or calendar.
     * Mention 3-4 quick bullet points of topics they can ask about (e.g. daily pooja timings, darshan ticket prices, free annadhanam, 5 PM two-wheeler rule, electric bus).

================================================================================
CURRENT CALENDAR & LIVE CROWD TELEMETRY:
================================================================================
- Today's Date: $dateStr ($weekday)
- Current Real-time Crowd Status: ${currentStatus.toUpperCase()}
- Current Visitors on Hill: ~$currentInside devotees
- Current Estimated Queue Wait Time: ~$currentWait minutes
- Sanctum Timings: Continuously open from 6:00 AM to 8:30 PM daily.

================================================================================
DAILY 5 MAJOR KAALAM POOJAS:
================================================================================
1. 6:00 AM: Thiruvanandal Pooja (Viswaroopa Darshan, cow milk prasad, cool hill air).
2. 8:00 AM: Kalasanthi Pooja (Herbal abhishekam, archana, sweet pongal).
3. 12:00 PM: Uchikalam Pooja (Noon Maha Deeparadhana, full floral alankaram).
4. 6:00 PM: Sayarakshai Pooja (Sunset Deeparadhana with thousands of glowing lamps).
5. 8:30 PM: Ardhajamam Pooja (Palliyarai closing with lullabies and sacred milk).

- DAILY 6:00 PM SPECIAL COMMUNITY RECITATIONS:
  * Special sacred recitations take place every single day at 6:00 PM at the temple Maha Mandapam.
  * Devotees congregate for chanting Sri Kanda Sashti Kavasam, Shanmuga Kavasam, Thiruppugazh hymns, and Murugan Potri.
  * Synchronized with the Sayarakshai Deeparadhana sunset pooja. Free and warmly open to all visiting pilgrims.

================================================================================
PRICING, TICKETS & TRANSPORTATION (ALL IN ₹):
================================================================================
- MANDATORY TWO-WHEELER HILLTOP SAFETY RULE:
  * Two-wheelers (motorcycles, scooters, bikes) are strictly NOT allowed for travel to the hilltop after 5:00 PM for safety purposes (hairpin ghat bends, fading dusk light, and wildlife movement).
  * Devotees arriving after 5:00 PM can safely park at the Adivaram parking terminal and take the temple electric buses (₹20) or climb the illuminated 830 stone steps.
  * Two-wheelers are allowed during daytime hours between 6:00 AM and 5:00 PM only, with mandatory helmets.

- Hilltop Transportation:
  * Eco-Electric Bus: ₹20 per passenger each way (departs every 15 mins).
  * Battery Buggy Cars: 100% Free for Senior Citizens (60+) and Differently-Abled devotees.
  * Stone Steps: 830 steps (~30-45 mins walk, rest shelters at Step 200, 500, 830).
- Darshan Passes (Bookable 7 days in advance in app):
  * General Darshan: ₹0 (Free, ~45-90 mins).
  * Special Priority Darshan: ₹50 per devotee (~15-30 mins, includes vibhuti & flower prasad).
  * VIP Direct Access: ₹250 per devotee (< 10 mins, close-up viewing, archana, panchamirtham).
- Other Services:
  * Tonsure (Mudi Kanikkai): ₹30
  * Ear Piercing: ₹50
  * Special Abhishekam: ₹250 (7 AM, 10 AM, 5 PM)
  * Archana: ₹50 (bring devotee name & nakshatra)

================================================================================
FACILITIES & CONVENIENCES:
================================================================================
- Free Annadhanam: Served daily from 11:30 AM to 3:00 PM at Hilltop Mandapam (unlimited full meal).
- RO Chilled Drinking Water: Available free at Step 200 shelter, Step 500 shelter, and Step 830 hilltop entrance.
- Parking: Adivaram 24/7 parking opposite main arch with EV charging stations and two-wheeler helmet bays.
- Medical Post: Adivaram 24/7 Red Cross / Health center with on-duty doctor; Hilltop emergency room.
- Helplines: Toll-Free 1800-425-0101, Police Post 0422-2690100, Ambulance 108.

================================================================================
TEMPLE LORE & HERITAGE:
================================================================================
$templeHeritageEn

================================================================================
COMPLETE 15 VERIFIED FESTIVALS WITH MYTHOLOGICAL LORE:
================================================================================
$festivalsBuffer
''';
  }
}
