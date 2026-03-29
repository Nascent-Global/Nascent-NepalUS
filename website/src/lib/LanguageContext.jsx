import { createContext, useContext, useState, useEffect } from "react";

const translations = {
  en: {
    // Nav
    dashboard: "Dashboard",
    dailyLog: "Daily Log",
    history: "History",
    askPsychologist: "Ask Psychologist",
    education: "Education",
    // Dashboard
    welcomeTitle: "Welcome to Burnout Tracker",
    welcomeDesc:
      "Start by logging how you feel today. We'll track your burnout levels and help you stay balanced.",
    logFirstDay: "Log Your First Day",
    logToday: "Log Today",
    burnoutOverview: "Your burnout overview",
    sevenDayTrend: "7-Day Trend",
    suggestions: "Suggestions",
    quickRecovery: "Quick Recovery",
    sleep: "Sleep",
    work: "Work",
    mood: "Mood",
    // Daily Log
    howAreYou: "How are you today?",
    sleepLastNight: "Sleep last night",
    workStudyHours: "Work / study hours",
    deadlinesToday: "Deadlines / tasks today",
    feelingOverwhelmed: "Feeling overwhelmed?",
    submitLog: "Submit Today's Log",
    updatingLastLog: "Updating last log",
    logOf: "Log",
    of: "of",
    reachedLimit:
      "You've reached today's limit — this will update your last log.",
    morning: "Morning",
    afternoon: "Afternoon",
    night: "Night",
    // Psychologist
    askPsychologistTitle: "Ask a Psychologist",
    askPsychologistDesc:
      "Ask anything about mental health — anonymously, no judgment.",
    disclaimer: "Disclaimer",
    disclaimerText:
      "This is not a substitute for professional medical advice, diagnosis, or treatment. If you are in crisis, please contact a local emergency service.",
    whatsOnMind: "What's on your mind?",
    communityQuestions: "Community Questions",
    noQuestionsYet: "No questions yet. Be the first to ask!",
    questionSubmitted: "Your question has been submitted",
    questionSubmittedDesc: "A mental health professional will respond soon.",
    askAnother: "Ask another question",
    questionPlaceholder: "What's on your mind? Share anonymously…",
    questionAnonymous:
      "Your question is 100% anonymous. No personal data is collected.",
    submitting: "Submitting…",
    submitQuestion: "Submit Question",
    alertHighTitle: "High Burnout Alert",
    alertHighDesc:
      "Your burnout score is in the high zone. Consider taking a break and reviewing the suggestions below.",
    alertTrendingTitle: "Burnout Trending Up",
    alertTrendingDesc:
      "Your burnout score has been increasing for the past 3 days. Take action before it gets worse.",
    burnoutLevel_low: "Low Burnout",
    burnoutLevel_medium: "Medium Burnout",
    burnoutLevel_high: "High Burnout",
    answered: "Answered",
    verified: "Verified",
    awaitingAnswer: "Awaiting answer",
    // Education
    educationTitle: "Education",
    educationDesc:
      "Explore resources to learn about mental health and well-being.",
    eduRes1Title: "Mental Health Awareness Radio Program",
    eduRes1Desc:
      "Learn about mental health, reduce stigma, and understand when and how to seek support through this educational radio program.",
    eduRes2Title: "Doing What Matters in Times of Stress (WHO)",
    eduRes2Desc:
      "A practical, evidence-based guide from the World Health Organization that teaches simple techniques to manage stress and cope with difficult situations—just a few minutes a day.",
    downloadInNepali: "Download in Nepali",
    manoSambaad: "Mano Sambaad",
    niomhSeries: "NIOMH Radio Series",
    backToEducation: "Back to Education",
    radioProgramDesc:
      "A 10 episode radio series on common mental health topics were broadcasted via radio stations covering all provinces of Nepal in the year 2024, reaching out to an approximately <strong>10 lakh</strong> active and passive listeners. The program also had a direct active intervention component, that used radio listener's group (RLG) for a deeper learning about each of the mental health topics utilizing the radio material.",
    episodes: "Episodes",
    episode: "Episode",
    ep1Title: "Common Mental Health Disorders",
    ep2Title: "Depression and Loneliness",
    ep3Title: "Anxiety Disorder",
    ep4Title: "Alcohol Use Disorder",
    ep5Title: "Psychosis",
    ep6Title: "Suicide and Self Harm",
    ep7Title: "Bipolar Disorder",
    ep8Title: "Psychosocial Aspect of Health",
    ep9Title: "ADHD and Autism",
    ep10Title: "Perinatal Mental Health",
    // Breathing
    startBreathing: "Start 1-Minute Breathing Exercise",
    breatheIn: "Breathe In",
    hold: "Hold",
    breatheOut: "Breathe Out",
    remaining: "remaining",
    // Suggestions
    suggHigh1: "Take a break today",
    suggHigh2: "Pause non-critical tasks",
    suggHigh3: "Talk to someone you trust",
    suggHigh4: "Try a breathing exercise",
    suggMed1: "Reduce your workload today",
    suggMed2: "Schedule dedicated rest time",
    suggMed3: "Take regular short breaks",
    suggLow1: "Great job — maintain your routine",
    suggLow2: "Take short breaks between tasks",
    // Banners
    relaxingSounds: "Relaxing Sounds",
    relaxingSoundsDesc: "Take a break and unwind with soothing sounds!",
    pomodoroTimer: "Pomodoro Timer",
    pomodoroDesc: "Stay focused with 25-min sessions and planned breaks!",
    askAPsychologist: "Ask a Psychologist",
    askAPsychologistDesc:
      "Ask mental health questions anonymously — no judgment, no identity.",
    // History
    historyTitle: "History",
    historyDesc: "Your past entries",
    burnoutTrend: "Burnout Trend",
    tasks: "Tasks",
    feelingOverwhelmedAlert: "Feeling overwhelmed",
    noEntriesYet: "No entries yet. Start by logging your day.",
    // Pomodoro
    pomodoroTitle: "Pomodoro Timer",
    pomodoroSubtitle: "Focus deeply, then rest. Repeat.",
    pomodoroMode: "Pomodoro",
    shortBreak: "Short Break",
    longBreak: "Long Break",
    minutes: "minutes",
    timeToFocus: "Time to focus!",
    takeABreak: "Take a break!",
    sessionComplete: "Session complete!",
    readyToStart: "Ready to start?",
    // Crisis Modal
    crisisTitle: "You're not alone 💙",
    crisisDesc:
      "If you're having suicidal thoughts, support is available right now.",
    crisisLine1:
      "Call or text <strong>988</strong> — the Suicide & Crisis Lifeline in <strong>the U.S.</strong>",
    crisisLine2:
      "Call <strong>1166</strong> — the Suicide Prevention Helpline in <strong>Nepal</strong>.",
    crisisFooter: "It's free, confidential, and available 24/7.",
    crisisButton: "I understand",
    // Relaxing Sounds
    relaxingSoundsTitle: "Relaxing Sounds",
    relaxingSoundsSubtitle:
      "Pick a sound and let it play in the background while you relax.",
    stopSound: "Stop Sound",
    // Categories
    catNature: "Nature",
    catSoothing: "Soothing Things",
    catPlaces: "Places",
    catTransport: "Transport",
    // Nature sounds
    sndLightRain: "Light Rain",
    sndHeavyRain: "Heavy Rain",
    sndRainWindow: "Rain on Window",
    sndThunder: "Thunderstorm",
    sndWaves: "Ocean Waves",
    sndRiver: "River",
    sndWaterfall: "Waterfall",
    sndCampfire: "Campfire",
    sndWindTrees: "Wind in Trees",
    sndHowlingWind: "Howling Wind",
    // Soothing Things
    sndSingingBowl: "Singing Bowl",
    sndWindChimes: "Wind Chimes",
    sndVinyl: "Vinyl Crackle",
    sndClock: "Ticking Clock",
    sndKeyboard: "Keyboard",
    // Places
    sndCafe: "Coffee Shop",
    sndLibrary: "Library",
    sndOffice: "Office",
    sndRestaurant: "Restaurant",
    sndNightVillage: "Night Village",
    // Transport
    sndAirplane: "Airplane",
    sndTrain: "Train",
    sndSailboat: "Sailboat",
    sndRowingBoat: "Rowing Boat",
    sndSubmarine: "Submarine",
    // Education
    educationTitle: "Education",
  },
  ne: {
    // Nav
    dashboard: "ड्यासबोर्ड",
    dailyLog: "दैनिक लग",
    history: "इतिहास",
    askPsychologist: "मनोवैज्ञानिकलाई सोध्नुस्",
    education: "शिक्षा",
    // Dashboard
    welcomeTitle: "Burnout Tracker मा स्वागत छ",
    welcomeDesc:
      "आज तपाईंलाई कस्तो लागिरहेको छ भनेर लग गर्नुहोस्। हामी तपाईंको बर्नआउट स्तर ट्र्याक गर्छौं।",
    logFirstDay: "पहिलो दिन लग गर्नुहोस्",
    logToday: "आज लग गर्नुहोस्",
    burnoutOverview: "तपाईंको बर्नआउट सिंहावलोकन",
    sevenDayTrend: "७-दिनको प्रवृत्ति",
    suggestions: "सुझावहरू",
    quickRecovery: "द्रुत पुनर्प्राप्ति",
    sleep: "निद्रा",
    work: "काम",
    mood: "मनस्थिति",
    // Daily Log
    howAreYou: "आज तपाईंलाई कस्तो छ?",
    sleepLastNight: "गत रातको निद्रा",
    workStudyHours: "काम / अध्ययनको घण्टा",
    deadlinesToday: "आजको समयसीमा / कार्यहरू",
    feelingOverwhelmed: "अभिभूत महसुस गर्दैहुनुहुन्छ?",
    submitLog: "आजको लग सबमिट गर्नुहोस्",
    updatingLastLog: "अन्तिम लग अपडेट गर्दै",
    logOf: "लग",
    of: "मध्ये",
    reachedLimit:
      "तपाईंले आजको सीमा पुग्नुभयो — यसले तपाईंको अन्तिम लग अपडेट गर्नेछ।",
    morning: "बिहान",
    afternoon: "दिउँसो",
    night: "रात",
    // Psychologist
    askPsychologistTitle: "मनोवैज्ञानिकलाई सोध्नुस्",
    askPsychologistDesc:
      "मानसिक स्वास्थ्यबारे कुनै पनि कुरा सोध्नुहोस् — गुमनाम रूपमा, कुनै निर्णय छैन।",
    disclaimer: "अस्वीकरण",
    disclaimerText:
      "यो पेशेवर चिकित्सा सल्लाह, निदान वा उपचारको विकल्प होइन। यदि तपाईं संकटमा हुनुहुन्छ भने, कृपया स्थानीय आपतकालीन सेवालाई सम्पर्क गर्नुहोस्।",
    whatsOnMind: "तपाईंको मनमा के छ?",
    communityQuestions: "सामुदायिक प्रश्नहरू",
    noQuestionsYet: "अझै कुनै प्रश्न छैन। पहिलो भएर सोध्नुहोस्!",
    questionSubmitted: "तपाईंको प्रश्न पेश गरिएको छ",
    questionSubmittedDesc: "एक मानसिक स्वास्थ्य पेशेवरले चाँडै जवाफ दिनेछन्।",
    askAnother: "अर्को प्रश्न सोध्नुहोस्",
    questionPlaceholder: "तपाईंको मनमा के छ? गुमनाम रूपमा साझा गर्नुहोस्…",
    questionAnonymous:
      "तपाईंको प्रश्न १००% गुमनाम छ। कुनै व्यक्तिगत डेटा संकलन गरिँदैन।",
    submitting: "पेश गर्दै…",
    submitQuestion: "प्रश्न पेश गर्नुहोस्",
    alertHighTitle: "उच्च बर्नआउट चेतावनी",
    alertHighDesc:
      "तपाईंको बर्नआउट स्कोर उच्च क्षेत्रमा छ। विश्राम लिनुहोस् र तलका सुझावहरू हेर्नुहोस्।",
    alertTrendingTitle: "बर्नआउट बढ्दै छ",
    alertTrendingDesc:
      "तपाईंको बर्नआउट स्कोर पछिल्ला ३ दिनदेखि बढिरहेको छ। झन् नराम्रो हुनु अघि कदम चाल्नुहोस्।",
    burnoutLevel_low: "कम बर्नआउट",
    burnoutLevel_medium: "मध्यम बर्नआउट",
    burnoutLevel_high: "उच्च बर्नआउट",
    answered: "उत्तर दिइयो",
    verified: "प्रमाणित",
    awaitingAnswer: "उत्तरको प्रतीक्षामा",
    // Education
    educationTitle: "शिक्षा",
    educationDesc:
      "मानसिक स्वास्थ्य र कल्याणको बारेमा जान्न स्रोतहरू अन्वेषण गर्नुहोस्।",
    eduRes1Title: "मानसिक स्वास्थ्य जागरूकता रेडियो कार्यक्रम",
    eduRes1Desc:
      "यस शैक्षिक रेडियो कार्यक्रम मार्फत मानसिक स्वास्थ्यको बारेमा जान्नुहोस्, कलंक घटाउनुहोस्, र कहिले र कसरी सहयोग खोज्ने भनेर बुझ्नुहोस्।",
    eduRes2Title: "तनावको समयमा महत्त्वपूर्ण कुराहरू गर्दै (WHO)",
    eduRes2Desc:
      "विश्व स्वास्थ्य संगठनको एक व्यावहारिक, प्रमाण-आधारित गाइड जसले तनाव व्यवस्थापन र कठिन परिस्थितिहरूसँग सामना गर्न सरल प्रविधिहरू सिकाउँछ — दिनमा केही मिनेट मात्र।",
    downloadInNepali: "नेपालीमा डाउनलोड गर्नुहोस्",
    manoSambaad: "मनो सम्बाद",
    niomhSeries: "NIOMH रेडियो श्रृंखला",
    backToEducation: "शिक्षामा फर्कनुहोस्",
    radioProgramDesc:
      "२०२४ मा नेपालका सबै प्रदेशका रेडियो स्टेशनहरू मार्फत सामान्य मानसिक स्वास्थ्य विषयहरूमा १० भागको रेडियो श्रृंखला प्रसारण गरिएको थियो, जसले लगभग <strong>१० लाख</strong> सक्रिय र निष्क्रिय श्रोताहरूसम्म पुग्यो। यस कार्यक्रममा प्रत्यक्ष सक्रिय हस्तक्षेप घटक पनि थियो, जसले रेडियो सामग्री प्रयोग गरेर प्रत्येक मानसिक स्वास्थ्य विषयको गहन शिक्षाका लागि रेडियो श्रोता समूह (RLG) को उपयोग गर्‍यो।",
    episodes: "भागहरू",
    episode: "भाग",
    ep1Title: "सामान्य मानसिक स्वास्थ्य विकारहरू",
    ep2Title: "अवसाद र एक्लोपन",
    ep3Title: "चिन्ता विकार",
    ep4Title: "मदिरा सेवन विकार",
    ep5Title: "मनोविकृति",
    ep6Title: "आत्महत्या र आत्म-हानि",
    ep7Title: "द्विध्रुवी विकार",
    ep8Title: "स्वास्थ्यको मनोसामाजिक पक्ष",
    ep9Title: "ADHD र अटिजम",
    ep10Title: "प्रसवकालीन मानसिक स्वास्थ्य",
    // Breathing
    startBreathing: "१ मिनेट सास फेर्ने व्यायाम सुरु गर्नुहोस्",
    breatheIn: "सास लिनुहोस्",
    hold: "रोक्नुहोस्",
    breatheOut: "सास छोड्नुहोस्",
    remaining: "बाँकी",
    // Suggestions
    suggHigh1: "आज विश्राम लिनुहोस्",
    suggHigh2: "गैर-महत्वपूर्ण कार्यहरू रोक्नुहोस्",
    suggHigh3: "विश्वासपात्र व्यक्तिसँग कुरा गर्नुहोस्",
    suggHigh4: "सास फेर्ने व्यायाम प्रयास गर्नुहोस्",
    suggMed1: "आज काम घटाउनुहोस्",
    suggMed2: "आराम समय तालिका बनाउनुहोस्",
    suggMed3: "नियमित छोटो विरामहरू लिनुहोस्",
    suggLow1: "राम्रो काम — आफ्नो दिनचर्या कायम राख्नुहोस्",
    suggLow2: "कार्यहरू बीच छोटो विराम लिनुहोस्",
    // Banners
    relaxingSounds: "आरामदायक ध्वनिहरू",
    relaxingSoundsDesc: "सुखद ध्वनिहरूसँग आराम गर्नुहोस्!",
    pomodoroTimer: "पोमोडोरो टाइमर",
    pomodoroDesc: "२५ मिनेटको सत्र र योजनाबद्ध विरामसँग केन्द्रित रहनुहोस्!",
    askAPsychologist: "मनोवैज्ञानिकलाई सोध्नुस्",
    askAPsychologistDesc:
      "मानसिक स्वास्थ्यका प्रश्नहरू गुमनाम रूपमा सोध्नुहोस् — कुनै निर्णय छैन।",
    // History
    historyTitle: "इतिहास",
    historyDesc: "तपाईंका पुराना प्रविष्टिहरू",
    burnoutTrend: "बर्नआउट प्रवृत्ति",
    tasks: "कार्यहरू",
    feelingOverwhelmedAlert: "अभिभूत महसुस गर्दैहुनुहुन्छ",
    noEntriesYet: "अझै कुनै प्रविष्टि छैन। आफ्नो दिन लग गरेर सुरु गर्नुहोस्।",
    // Pomodoro
    pomodoroTitle: "पोमोडोरो टाइमर",
    pomodoroSubtitle: "गहिरो एकाग्रता, त्यसपछि आराम। दोहोर्याउनुहोस्।",
    pomodoroMode: "पोमोडोरो",
    shortBreak: "छोटो विराम",
    longBreak: "लामो विराम",
    minutes: "मिनेट",
    timeToFocus: "ध्यान दिने समय!",
    takeABreak: "विश्राम लिनुहोस्!",
    sessionComplete: "सत्र सम्पन्न!",
    readyToStart: "सुरु गर्न तयार?",
    // Crisis Modal
    crisisTitle: "तपाईं एक्लो हुनुहुन्न 💙",
    crisisDesc:
      "यदि तपाईंलाई आत्महत्याका विचार आइरहेका छन् भने, अहिले नै सहयोग उपलब्ध छ।",
    crisisLine1:
      "<strong>१९०</strong> मा कल गर्नुहोस् — नेपाल प्रहरीको आपतकालीन सेवा।",
    crisisLine2:
      "<strong>११६६</strong> मा कल गर्नुहोस् — नेपालको आत्महत्या रोकथाम हेल्पलाइन।",
    crisisFooter: "यो निःशुल्क, गोप्य र २४/७ उपलब्ध छ।",
    crisisButton: "मैले बुझें",
    // Relaxing Sounds
    relaxingSoundsTitle: "आरामदायक ध्वनिहरू",
    relaxingSoundsSubtitle:
      "एउटा ध्वनि छान्नुहोस् र आराम गर्दा पृष्ठभूमिमा बजाउनुहोस्।",
    stopSound: "ध्वनि रोक्नुहोस्",
    // Categories
    catNature: "प्रकृति",
    catSoothing: "शान्त ध्वनिहरू",
    catPlaces: "स्थानहरू",
    catTransport: "यातायात",
    // Nature sounds
    sndLightRain: "हल्का वर्षा",
    sndHeavyRain: "भारी वर्षा",
    sndRainWindow: "झ्यालमा वर्षा",
    sndThunder: "चट्याङ",
    sndWaves: "समुद्री छाल",
    sndRiver: "नदी",
    sndWaterfall: "झरना",
    sndCampfire: "अलाव",
    sndWindTrees: "रूखमा हावा",
    sndHowlingWind: "सुसाउने हावा",
    // Soothing Things
    sndSingingBowl: "गाउने कचौरा",
    sndWindChimes: "हावा घण्टी",
    sndVinyl: "भिनाइल क्र्याकल",
    sndClock: "घडीको टिक-टिक",
    sndKeyboard: "किबोर्ड",
    // Places
    sndCafe: "कफी शप",
    sndLibrary: "पुस्तकालय",
    sndOffice: "कार्यालय",
    sndRestaurant: "रेस्टुरेन्ट",
    sndNightVillage: "रातको गाउँ",
    // Transport
    sndAirplane: "हवाईजहाज",
    sndTrain: "रेलगाडी",
    sndSailboat: "पालकिस्ती",
    sndRowingBoat: "डुङ्गा",
    sndSubmarine: "पानीमुनि जहाज",
    // Education
    educationTitle: "शिक्षा",
  },
};

const LanguageContext = createContext(null);

export function LanguageProvider({ children }) {
  const [lang, setLang] = useState(() => localStorage.getItem("lang") || "ne");

  useEffect(() => {
    localStorage.setItem("lang", lang);
  }, [lang]);

  const t = (key) => translations[lang]?.[key] || translations.en[key] || key;

  return (
    <LanguageContext.Provider value={{ lang, setLang, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  return useContext(LanguageContext);
}
