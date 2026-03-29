import { useQuery } from "@tanstack/react-query";
import { base44 } from "@/api/base44Client";
import { Link } from "react-router-dom";
import { Lightbulb } from "lucide-react";

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

function scoreMatch(questionText, queryText) {
  const lower = queryText.toLowerCase();
  const qLower = questionText.toLowerCase();
  let score = 0;
  KEYWORDS.forEach((kw) => {
    if (lower.includes(kw) && qLower.includes(kw)) score += 2;
  });
  // Word overlap
  const queryWords = lower.split(/\s+/).filter((w) => w.length > 3);
  queryWords.forEach((word) => {
    if (qLower.includes(word)) score += 1;
  });
  return score;
}

export default function SimilarQuestions({ queryText, compact = false }) {
  const { data: questions = [] } = useQuery({
    queryKey: ["questions-all"],
    queryFn: () => base44.entities.Question.list("-created_date", 100),
  });

  const answered = questions.filter((q) => q.is_answered && q.is_seeded);
  const scored = answered
    .map((q) => ({ ...q, score: scoreMatch(q.question_text, queryText) }))
    .filter((q) => q.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, compact ? 3 : 5);

  if (scored.length === 0) return null;

  return (
    <div
      className={
        compact ? "rounded-xl bg-indigo-50 border border-indigo-100 p-4" : ""
      }
    >
      <div className="flex items-center gap-2 mb-3">
        <Lightbulb className="w-4 h-4 text-indigo-500" />
        <p className="text-sm font-semibold text-indigo-700">
          {compact ? "Similar questions others asked:" : "Related Questions"}
        </p>
      </div>
      <ul className="space-y-2">
        {scored.map((q) => (
          <li key={q.id}>
            <Link
              to={`/psychologist/${q.id}`}
              className="text-sm text-indigo-600 hover:text-indigo-800 hover:underline line-clamp-2 block"
            >
              → {q.question_text}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
