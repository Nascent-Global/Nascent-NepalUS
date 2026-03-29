import { motion, AnimatePresence } from "framer-motion";
import { AlertTriangle, TrendingUp } from "lucide-react";
import { useLanguage } from "@/lib/LanguageContext";

export default function AlertBanner({ logs }) {
  const { t } = useLanguage();
  const recent = logs.slice(-3);
  const latest = recent[recent.length - 1];

  if (!latest) return null;

  const isHigh = latest.burnout_level === "high";
  const isIncreasing =
    recent.length >= 3 &&
    recent.every((_, i) =>
      i === 0 ? true : recent[i].burnout_score > recent[i - 1].burnout_score,
    );

  if (!isHigh && !isIncreasing) return null;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0, y: -10, height: 0 }}
        animate={{ opacity: 1, y: 0, height: "auto" }}
        exit={{ opacity: 0, y: -10, height: 0 }}
        className="rounded-xl border border-destructive/30 bg-destructive/5 px-5 py-4 flex items-start gap-3"
      >
        {isHigh ? (
          <AlertTriangle className="w-5 h-5 text-destructive mt-0.5 shrink-0" />
        ) : (
          <TrendingUp className="w-5 h-5 text-destructive mt-0.5 shrink-0" />
        )}
        <div>
          <p className="font-semibold text-destructive text-sm">
            {isHigh ? t("alertHighTitle") : t("alertTrendingTitle")}
          </p>
          <p className="text-sm text-muted-foreground mt-0.5">
            {isHigh ? t("alertHighDesc") : t("alertTrendingDesc")}
          </p>
        </div>
      </motion.div>
    </AnimatePresence>
  );
}
