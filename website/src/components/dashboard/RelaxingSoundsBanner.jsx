import { Link } from "react-router-dom";
import { Headphones, ChevronRight } from "lucide-react";
import { motion } from "framer-motion";
import { useLanguage } from "@/lib/LanguageContext";

export default function RelaxingSoundsBanner() {
  const { t } = useLanguage();
  return (
    <Link to="/sounds">
      <motion.div
        whileHover={{ scale: 1.01 }}
        whileTap={{ scale: 0.99 }}
        className="w-full rounded-2xl bg-gradient-to-r from-[#60A5FA]/20 via-[#4F46E5]/10 to-[#60A5FA]/20 border border-[#60A5FA]/30 px-6 py-5 flex items-center gap-5 cursor-pointer transition-shadow hover:shadow-md"
      >
        <div className="w-12 h-12 rounded-xl bg-[#60A5FA]/20 flex items-center justify-center shrink-0">
          <Headphones className="w-6 h-6 text-[#60A5FA]" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-semibold text-base leading-tight">
            {t("relaxingSounds")}
          </p>
          <p className="text-sm text-muted-foreground mt-0.5">
            {t("relaxingSoundsDesc")}
          </p>
        </div>
        <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0" />
      </motion.div>
    </Link>
  );
}
