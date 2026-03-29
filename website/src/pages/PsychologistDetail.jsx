import { useQuery } from "@tanstack/react-query";
import { base44 } from "@/api/base44Client";
import { useParams, Link } from "react-router-dom";
import { motion } from "framer-motion";
import {
  ArrowLeft,
  CheckCircle2,
  Clock,
  ShieldCheck,
  MessageCircleQuestion,
} from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { formatDistanceToNow } from "date-fns";
import SimilarQuestions from "@/components/psychologist/SimilarQuestions";

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

export default function PsychologistDetail() {
  const { id } = useParams();

  const { data: question, isLoading } = useQuery({
    queryKey: ["question", id],
    queryFn: async () => {
      const all = await base44.entities.Question.list("-created_date", 200);
      return all.find((q) => q.id === id) || null;
    },
  });

  if (isLoading) {
    return (
      <div className="flex justify-center py-20">
        <div className="w-7 h-7 border-4 border-muted border-t-primary rounded-full animate-spin" />
      </div>
    );
  }

  if (!question) {
    return (
      <div className="text-center py-20 text-muted-foreground">
        Question not found.
      </div>
    );
  }

  const timeAgo = formatDistanceToNow(new Date(question.created_date), {
    addSuffix: true,
  });

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6 max-w-2xl mx-auto"
    >
      <Link
        to="/psychologist"
        className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition"
      >
        <ArrowLeft className="w-4 h-4" />
        Back to questions
      </Link>

      {/* Question */}
      <Card className="border-0 shadow-sm">
        <CardContent className="pt-6">
          <div className="flex items-start gap-3">
            <div className="w-9 h-9 rounded-xl bg-indigo-100 flex items-center justify-center shrink-0">
              <MessageCircleQuestion className="w-5 h-5 text-indigo-600" />
            </div>
            <div className="flex-1">
              <p className="font-medium text-base leading-relaxed">
                {question.question_text}
              </p>
              <div className="flex items-center gap-2 mt-2 flex-wrap">
                <span className="text-xs text-muted-foreground">
                  Asked {timeAgo} · Anonymous
                </span>
                {(question.tags || []).map((tag) => (
                  <span
                    key={tag}
                    className={`text-xs px-2 py-0.5 rounded-full font-medium ${TAG_COLORS[tag] || TAG_COLORS.default}`}
                  >
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Answer */}
      {question.is_answered ? (
        <Card className="border-0 shadow-sm bg-green-50 border border-green-100">
          <CardContent className="pt-6">
            <div className="flex items-center gap-2 mb-4">
              <CheckCircle2 className="w-4 h-4 text-green-600" />
              <span className="text-sm font-semibold text-green-700">
                Answer from a Mental Health Professional
                {question.is_verified && (
                  <span className="ml-2 inline-flex items-center gap-1 text-indigo-600">
                    <ShieldCheck className="w-3.5 h-3.5" /> Verified
                  </span>
                )}
              </span>
            </div>
            <p className="text-sm leading-relaxed text-gray-800 whitespace-pre-line">
              {question.answer_text}
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card className="border-0 shadow-sm">
          <CardContent className="pt-6 text-center py-10">
            <Clock className="w-10 h-10 text-muted-foreground mx-auto mb-3" />
            <p className="font-semibold text-base">Waiting for an answer</p>
            <p className="text-sm text-muted-foreground mt-1">
              A mental health professional will respond soon.
            </p>
          </CardContent>
        </Card>
      )}

      {/* Disclaimer */}
      <div className="flex items-start gap-3 rounded-xl bg-amber-50 border border-amber-200 px-5 py-4">
        <ShieldCheck className="w-4 h-4 text-amber-600 mt-0.5 shrink-0" />
        <p className="text-xs text-amber-800">
          This is not a substitute for professional medical advice, diagnosis,
          or treatment.
        </p>
      </div>

      {/* Similar */}
      {question.question_text && (
        <div>
          <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-3">
            Related Questions
          </h3>
          <SimilarQuestions queryText={question.question_text} />
        </div>
      )}
    </motion.div>
  );
}
