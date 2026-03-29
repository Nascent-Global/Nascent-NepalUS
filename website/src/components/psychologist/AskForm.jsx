import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Button } from "@/components/ui/button";
import { Send, Loader2 } from "lucide-react";
import SimilarQuestions from "./SimilarQuestions";
import { useLanguage } from "@/lib/LanguageContext";

const KEYWORDS = [
  "stress",
  "anxiety",
  "sleep",
  "burnout",
  "work",
  "overwhelmed",
  "sad",
  "depressed",
  "angry",
  "focus",
  "tired",
  "panic",
  "motivation",
  "relationship",
  "lonely",
  "fear",
  "grief",
  "trauma",
  "meditation",
  "breathe",
];

function extractTags(text) {
  const lower = text.toLowerCase();
  return KEYWORDS.filter((kw) => lower.includes(kw));
}

export default function AskForm({ onSubmitted }) {
  const { t } = useLanguage();
  const [text, setText] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!text.trim()) return;
    setSubmitting(true);
    const tags = extractTags(text);
    await base44.entities.Question.create({
      question_text: text.trim(),
      tags,
      is_answered: false,
      is_verified: false,
      is_seeded: false,
    });
    setSubmitting(false);
    setSubmitted(true);
    setText("");
    onSubmitted?.();
  };

  if (submitted) {
    return (
      <div className="rounded-2xl bg-green-50 border border-green-200 px-6 py-8 text-center">
        <div className="text-3xl mb-3">🌿</div>
        <p className="font-semibold text-green-800">{t("questionSubmitted")}</p>
        <p className="text-sm text-green-700 mt-1">
          {t("questionSubmittedDesc")}
        </p>
        <Button
          variant="outline"
          className="mt-4"
          onClick={() => setSubmitted(false)}
        >
          {t("askAnother")}
        </Button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder={t("questionPlaceholder")}
          rows={4}
          className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-primary/30 placeholder:text-muted-foreground transition"
        />
        <p className="text-xs text-muted-foreground mt-1.5 ml-1">
          {t("questionAnonymous")}
        </p>
      </div>

      {/* Live similar suggestions while typing */}
      {text.trim().length > 10 && <SimilarQuestions queryText={text} compact />}

      <Button
        type="submit"
        disabled={!text.trim() || submitting}
        className="w-full rounded-xl h-11"
      >
        {submitting ? (
          <>
            <Loader2 className="w-4 h-4 mr-2 animate-spin" /> {t("submitting")}
          </>
        ) : (
          <>
            <Send className="w-4 h-4 mr-2" /> {t("submitQuestion")}
          </>
        )}
      </Button>
    </form>
  );
}
