import { Link } from "react-router-dom";
import { Timer, ChevronRight } from "lucide-react";
import { motion } from "framer-motion";
import { useLanguage } from "@/lib/LanguageContext";

export default function PomodoroBanner() {
  const { t } = useLanguage();
  return (
    <Link to="/pomodoro">
      <motion.div
        whileHover={{ scale: 1.01 }}
        whileTap={{ scale: 0.99 }}
        className="w-full rounded-2xl bg-gradient-to-r from-[#EF4444]/20 via-[#F59E0B]/10 to-[#EF4444]/20 border border-[#EF4444]/30 px-6 py-5 flex items-center gap-5 cursor-pointer transition-shadow hover:shadow-md"
      >
        <div className="w-12 h-12 rounded-xl bg-[#EF4444]/20 flex items-center justify-center shrink-0">
          <Timer className="w-6 h-6 text-[#EF4444]" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-semibold text-base leading-tight">
            {t("pomodoroTimer")}
          </p>
          <p className="text-sm text-muted-foreground mt-0.5">
            {t("pomodoroDesc")}
          </p>
        </div>
        <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0" />
      </motion.div>
    </Link>
  );
}
