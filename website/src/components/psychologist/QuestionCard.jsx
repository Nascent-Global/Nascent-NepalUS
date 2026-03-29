import { Link } from "react-router-dom";
import { useState, useEffect } from "react";
import { CheckCircle2, Clock, ChevronRight } from "lucide-react";
import { formatDistanceToNow } from "date-fns";
import { enUS } from "date-fns/locale";
import { useLanguage } from "@/lib/LanguageContext";
import { base44 } from "@/api/base44Client";

const TAG_COLORS = {
  stress: "bg-amber-100 text-amber-700",
  anxiety: "bg-red-100 text-red-700",
  sleep: "bg-blue-100 text-blue-700",
  burnout: "bg-orange-100 text-orange-700",
  work: "bg-slate-100 text-slate-600",
  overwhelmed: "bg-pink-100 text-pink-700",
  motivation: "bg-green-100 text-green-700",
  default: "bg-indigo-50 text-indigo-600",
};

const TAG_TRANSLATIONS = {
  stress: { en: "stress", ne: "तनाव" },
  anxiety: { en: "anxiety", ne: "चिन्ता" },
  sleep: { en: "sleep", ne: "निद्रा" },
  burnout: { en: "burnout", ne: "बर्नआउट" },
  work: { en: "work", ne: "काम" },
  overwhelmed: { en: "overwhelmed", ne: "अभिभूत" },
  motivation: { en: "motivation", ne: "प्रेरणा" },
  meditation: { en: "meditation", ne: "ध्यान" },
  fear: { en: "fear", ne: "डर" },
  relationship: { en: "relationship", ne: "सम्बन्ध" },
  depression: { en: "depression", ne: "अवसाद" },
  loneliness: { en: "loneliness", ne: "एक्लोपन" },
  anger: { en: "anger", ne: "रिस" },
  grief: { en: "grief", ne: "दुःख" },
  trauma: { en: "trauma", ne: "आघात" },
  family: { en: "family", ne: "परिवार" },
  self_esteem: { en: "self-esteem", ne: "आत्मसम्मान" },
  confidence: { en: "confidence", ne: "आत्मविश्वास" },
  focus: { en: "focus", ne: "एकाग्रता" },
  addiction: { en: "addiction", ne: "लत" },
  health: { en: "health", ne: "स्वास्थ्य" },
  tired: { en: "tired", ne: "थकान" },
  angry: { en: "angry", ne: "रिसाएको" },
  lonely: { en: "lonely", ne: "एक्लो" },
  panic: { en: "panic", ne: "आतंक" },
};

export default function QuestionCard({ question }) {
  const { t, lang } = useLanguage();
  const [translatedText, setTranslatedText] = useState(null);
  const [translating, setTranslating] = useState(false);
  const timeAgoEn = formatDistanceToNow(new Date(question.created_date), {
    addSuffix: true,
    locale: enUS,
  });

  const timeAgo =
    lang === "ne"
      ? (() => {
          const diffMs = Date.now() - new Date(question.created_date).getTime();
          const mins = Math.floor(diffMs / 60000);
          const hours = Math.floor(mins / 60);
          const days = Math.floor(hours / 24);
          const months = Math.floor(days / 30);
          const years = Math.floor(days / 365);
          if (mins < 1) return "अहिले";
          if (mins < 60) return `${mins} मिनेट अघि`;
          if (hours < 24) return `${hours} घण्टा अघि`;
          if (days < 30) return `${days} दिन अघि`;
          if (months < 12) return `${months} महिना अघि`;
          return `${years} वर्ष अघि`;
        })()
      : (() => {
          const diffMs = Date.now() - new Date(question.created_date).getTime();
          const mins = Math.floor(diffMs / 60000);
          if (mins < 1) return "just now";
          return formatDistanceToNow(new Date(question.created_date), {
            addSuffix: true,
            locale: enUS,
          });
        })();

  useEffect(() => {
    if (lang !== "ne") {
      setTranslatedText(null);
      return;
    }

    const timeout = setTimeout(() => {
      setTranslating(true);
      base44.integrations.Core.InvokeLLM({
        prompt: `Translate the following question to Nepali. Return only the translated text, nothing else.\n\n"${question.question_text}"`,
      })
        .then((res) => {
          setTranslatedText(
            typeof res === "string"
              ? res
              : res?.result || question.question_text,
          );
        })
        .catch(() => {
          setTranslatedText(question.question_text);
        })
        .finally(() => setTranslating(false));
    }, 300);

    return () => clearTimeout(timeout);
  }, [lang, question.question_text]);

  const displayText =
    lang === "ne"
      ? translating
        ? question.question_text
        : translatedText || question.question_text
      : question.question_text;

  const answerStatusText = question.is_answered
    ? t("answered")
    : t("awaitingAnswer");

  return (
    <Link to={`/psychologist/${question.id}`}>
      <div className="rounded-2xl bg-card border border-border/60 p-5 mb-4 hover:shadow-md hover:border-primary/20 transition-all duration-200 flex items-start gap-4">
        <div className="flex-1 min-w-0">
          <p
            className={`text-sm font-medium leading-relaxed line-clamp-2 mb-3 ${translating ? "opacity-50" : ""}`}
          >
            {displayText}
          </p>
          <div className="flex items-center gap-2 flex-wrap">
            <span
              className={
                question.is_answered
                  ? "flex items-center gap-1 text-xs text-green-600 font-medium"
                  : "flex items-center gap-1 text-xs text-muted-foreground"
              }
            >
              {question.is_answered ? (
                <CheckCircle2 className="w-3.5 h-3.5" />
              ) : (
                <Clock className="w-3.5 h-3.5" />
              )}
              {answerStatusText}
              {question.is_answered && question.is_verified && (
                <span className="ml-1 text-indigo-500">· {t("verified")}</span>
              )}
            </span>
            <span className="text-xs text-muted-foreground">· {timeAgo}</span>
            {(question.tags || []).slice(0, 3).map((tag) => (
              <span
                key={tag}
                className={`text-xs px-2 py-0.5 rounded-full font-medium ${TAG_COLORS[tag] || TAG_COLORS.default}`}
              >
                {TAG_TRANSLATIONS[tag]?.[lang] || tag}
              </span>
            ))}
          </div>
        </div>
        <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0 mt-0.5" />
      </div>
    </Link>
  );
}
