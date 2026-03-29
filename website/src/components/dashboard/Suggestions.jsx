import { motion } from "framer-motion";
import { getBurnoutBgColor } from "@/lib/burnout";
import { useLanguage } from "@/lib/LanguageContext";
import {
  Pause,
  MessageCircle,
  Wind,
  Clock,
  Coffee,
  ThumbsUp,
  Heart,
  ListX,
  CalendarMinus,
} from "lucide-react";

const iconMap = {
  Pause,
  MessageCircle,
  Wind,
  Clock,
  Coffee,
  ThumbsUp,
  Heart,
  ListX,
  CalendarMinus,
  Stretch: Heart,
};

function getSuggestionsTranslated(level, t) {
  if (level === "high") {
    return [
      { icon: "Pause", text: t("suggHigh1") },
      { icon: "ListX", text: t("suggHigh2") },
      { icon: "MessageCircle", text: t("suggHigh3") },
      { icon: "Wind", text: t("suggHigh4") },
    ];
  }
  if (level === "medium") {
    return [
      { icon: "CalendarMinus", text: t("suggMed1") },
      { icon: "Clock", text: t("suggMed2") },
      { icon: "Coffee", text: t("suggMed3") },
    ];
  }
  return [
    { icon: "ThumbsUp", text: t("suggLow1") },
    { icon: "Stretch", text: t("suggLow2") },
  ];
}

export default function Suggestions({ level }) {
  const { t } = useLanguage();
  const suggestions = getSuggestionsTranslated(level, t);

  return (
    <div className="space-y-2.5">
      {suggestions.map((s, i) => {
        const Icon = iconMap[s.icon] || Heart;
        return (
          <motion.div
            key={i}
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.1 }}
            className={`flex items-center gap-3 px-4 py-3 rounded-xl ${getBurnoutBgColor(level)} transition-all`}
          >
            <Icon className="w-4 h-4 shrink-0 text-muted-foreground" />
            <span className="text-sm font-medium">{s.text}</span>
          </motion.div>
        );
      })}
    </div>
  );
}
