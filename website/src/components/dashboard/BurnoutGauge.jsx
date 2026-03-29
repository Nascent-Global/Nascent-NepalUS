import { motion } from "framer-motion";
import { getBurnoutColor, getBurnoutBgColor } from "@/lib/burnout";
import { useLanguage } from "@/lib/LanguageContext";

export default function BurnoutGauge({ score, level }) {
  const { t } = useLanguage();
  const rotation = (score / 100) * 180 - 90; // -90 to 90 degrees

  return (
    <div className="flex flex-col items-center">
      {/* Gauge */}
      <div className="relative w-48 h-24 overflow-hidden">
        {/* Background arc */}
        <div className="absolute inset-0 w-48 h-48 rounded-full border-[12px] border-muted" />
        {/* Colored arc overlay */}
        <motion.div
          className="absolute inset-0 w-48 h-48 rounded-full border-[12px] border-transparent"
          style={{
            borderTopColor:
              level === "high"
                ? "hsl(var(--destructive))"
                : level === "medium"
                  ? "hsl(var(--accent))"
                  : "hsl(var(--secondary))",
            borderRightColor:
              score > 50
                ? level === "high"
                  ? "hsl(var(--destructive))"
                  : level === "medium"
                    ? "hsl(var(--accent))"
                    : "hsl(var(--secondary))"
                : "transparent",
          }}
          initial={{ rotate: -90 }}
          animate={{ rotate: rotation - 90 }}
          transition={{ duration: 1, ease: "easeOut" }}
        />
        {/* Needle */}
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-1 origin-bottom">
          <motion.div
            className="w-1.5 h-20 bg-foreground rounded-full origin-bottom"
            style={{ transformOrigin: "bottom center" }}
            initial={{ rotate: -90 }}
            animate={{ rotate: rotation }}
            transition={{ duration: 1.2, ease: "easeOut" }}
          />
        </div>
      </div>

      {/* Score display */}
      <motion.div
        className="mt-4 text-center"
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
      >
        <span
          className={`text-5xl font-display font-bold ${getBurnoutColor(level)}`}
        >
          {score}
        </span>
        <span className="text-lg text-muted-foreground ml-1">/100</span>
      </motion.div>

      <motion.div
        className={`mt-2 px-4 py-1.5 rounded-full text-sm font-semibold capitalize ${getBurnoutBgColor(level)} ${getBurnoutColor(level)}`}
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.7 }}
      >
        {t(`burnoutLevel_${level}`)}
      </motion.div>
    </div>
  );
}
