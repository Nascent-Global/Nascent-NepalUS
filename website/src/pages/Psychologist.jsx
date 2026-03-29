import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { base44 } from "@/api/base44Client";
import { motion, AnimatePresence } from "framer-motion";
import { MessageCircleQuestion, ShieldCheck, X, Heart } from "lucide-react";
import { useLanguage } from "@/lib/LanguageContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import AskForm from "@/components/psychologist/AskForm";
import QuestionCard from "@/components/psychologist/QuestionCard";

export default function Psychologist() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [showModal, setShowModal] = useState(false);
  const { t } = useLanguage();

  useEffect(() => {
    const timer = setTimeout(() => setShowModal(true), 5000);
    return () => clearTimeout(timer);
  }, []);

  const { data: questions = [], isLoading } = useQuery({
    queryKey: ["questions-all", refreshKey],
    queryFn: () => base44.entities.Question.list("-created_date", 50),
  });

  return (
    <>
      {/* Crisis Support Modal */}
      <AnimatePresence>
        {showModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4"
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-card rounded-2xl shadow-xl max-w-md w-full p-7 relative"
            >
              <button
                onClick={() => setShowModal(false)}
                className="absolute top-4 right-4 text-muted-foreground hover:text-foreground"
              >
                <X className="w-5 h-5" />
              </button>

              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 rounded-xl bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
                  <Heart className="w-5 h-5 text-blue-500 dark:text-blue-400" />
                </div>
                <h2 className="font-display text-xl font-bold">
                  {t("crisisTitle")}
                </h2>
              </div>

              <p className="text-sm text-muted-foreground mb-5 leading-relaxed">
                {t("crisisDesc")}
              </p>

              <ul className="space-y-3 mb-6">
                <li className="flex items-start gap-2 text-sm">
                  <span className="mt-0.5 w-2 h-2 rounded-full bg-blue-400 shrink-0 mt-1.5" />
                  <span
                    dangerouslySetInnerHTML={{ __html: t("crisisLine1") }}
                  />
                </li>
                <li className="flex items-start gap-2 text-sm">
                  <span className="mt-0.5 w-2 h-2 rounded-full bg-blue-400 shrink-0 mt-1.5" />
                  <span
                    dangerouslySetInnerHTML={{ __html: t("crisisLine2") }}
                  />
                </li>
              </ul>

              <p className="text-xs text-muted-foreground mb-5">
                {t("crisisFooter")}
              </p>

              <Button
                className="w-full rounded-xl"
                onClick={() => setShowModal(false)}
              >
                {t("crisisButton")}
              </Button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        className="space-y-8 max-w-2xl mx-auto"
      >
        {/* Header */}
        <div>
          <div className="flex items-center gap-3 mb-1">
            <div className="w-10 h-10 rounded-xl bg-indigo-100 dark:bg-indigo-900 flex items-center justify-center">
              <MessageCircleQuestion className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
            </div>
            <h1 className="font-display text-2xl sm:text-3xl font-bold">
              {t("askPsychologistTitle")}
            </h1>
          </div>
          <p className="text-muted-foreground text-sm mt-1 ml-13">
            {t("askPsychologistDesc")}
          </p>
        </div>

        {/* Disclaimer */}
        <div className="flex items-start gap-3 rounded-xl bg-red-50 dark:bg-red-950 border border-red-200 dark:border-red-800 px-5 py-4">
          <ShieldCheck className="w-5 h-5 text-red-600 dark:text-red-400 mt-0.5 shrink-0" />
          <p className="text-sm text-red-700 dark:text-red-300">
            <span className="font-semibold">{t("disclaimer")}:</span>{" "}
            {t("disclaimerText")}
          </p>
        </div>

        {/* Ask Form */}
        <Card className="border-0 shadow-sm">
          <CardHeader className="pb-3">
            <CardTitle className="text-base font-semibold">
              {t("whatsOnMind")}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <AskForm onSubmitted={() => setRefreshKey((k) => k + 1)} />
          </CardContent>
        </Card>

        {/* Question List */}
        <div>
          <h2 className="text-base font-semibold mb-4 text-muted-foreground uppercase tracking-wide text-xs">
            {t("communityQuestions")}
          </h2>
          {isLoading ? (
            <div className="flex justify-center py-10">
              <div className="w-7 h-7 border-4 border-muted border-t-primary rounded-full animate-spin" />
            </div>
          ) : questions.length === 0 ? (
            <div className="text-center py-10 text-muted-foreground text-sm">
              {t("noQuestionsYet")}
            </div>
          ) : (
            <div className="space-y-4">
              {questions.map((q) => (
                <QuestionCard key={q.id} question={q} />
              ))}
            </div>
          )}
        </div>
      </motion.div>
    </>
  );
}
