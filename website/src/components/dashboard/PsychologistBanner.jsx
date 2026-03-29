import { Link } from "react-router-dom";
import { MessageCircleQuestion, ChevronRight } from "lucide-react";
import { motion } from "framer-motion";
import { useLanguage } from "@/lib/LanguageContext";

export default function PsychologistBanner() {
  const { t } = useLanguage();
  return (
    <Link to="/psychologist">
      <motion.div
        whileHover={{ scale: 1.01 }}
        whileTap={{ scale: 0.99 }}
        className="w-full rounded-2xl bg-gradient-to-r from-indigo-100 via-purple-50 to-indigo-100 dark:from-indigo-950 dark:via-purple-950 dark:to-indigo-950 border border-indigo-200 dark:border-indigo-800 px-6 py-5 flex items-center gap-5 cursor-pointer transition-shadow hover:shadow-md"
      >
        <div className="w-12 h-12 rounded-xl bg-indigo-100 dark:bg-indigo-900 flex items-center justify-center shrink-0">
          <MessageCircleQuestion className="w-6 h-6 text-indigo-600 dark:text-indigo-400" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-semibold text-base leading-tight">
            {t("askAPsychologist")}
          </p>
          <p className="text-sm text-muted-foreground mt-0.5">
            {t("askAPsychologistDesc")}
          </p>
        </div>
        <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0" />
      </motion.div>
    </Link>
  );
}
