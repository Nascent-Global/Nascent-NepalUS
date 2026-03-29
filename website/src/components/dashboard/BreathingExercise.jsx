import { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Wind, X } from "lucide-react";
import { useLanguage } from "@/lib/LanguageContext";
const PHASE_DURATIONS = [4000, 4000, 4000];
const TOTAL_CYCLE = PHASE_DURATIONS.reduce((s, d) => s + d, 0);
const EXERCISE_DURATION = 60000; // 1 minute

export default function BreathingExercise() {
  const { t } = useLanguage();
  const PHASES = [
    { label: t("breatheIn"), duration: 4000 },
    { label: t("hold"), duration: 4000 },
    { label: t("breatheOut"), duration: 4000 },
  ];
  const [active, setActive] = useState(false);
  const [phase, setPhase] = useState(0);
  const [timeLeft, setTimeLeft] = useState(60);

  const start = useCallback(() => {
    setActive(true);
    setPhase(0);
    setTimeLeft(60);
  }, []);

  useEffect(() => {
    if (!active) return;

    const startTime = Date.now();

    const interval = setInterval(() => {
      const elapsed = Date.now() - startTime;
      const remaining = Math.max(
        0,
        Math.ceil((EXERCISE_DURATION - elapsed) / 1000),
      );
      setTimeLeft(remaining);

      if (elapsed >= EXERCISE_DURATION) {
        setActive(false);
        clearInterval(interval);
        return;
      }

      // Determine current phase
      const cycleElapsed = elapsed % TOTAL_CYCLE;
      let acc = 0;
      for (let i = 0; i < PHASES.length; i++) {
        acc += PHASES[i].duration;
        if (cycleElapsed < acc) {
          setPhase(i);
          break;
        }
      }
    }, 100);

    return () => clearInterval(interval);
  }, [active]);

  if (!active) {
    return (
      <Button
        onClick={start}
        variant="outline"
        className="w-full h-14 rounded-xl border-dashed border-2 text-muted-foreground hover:text-primary hover:border-primary/40 transition-all"
      >
        <Wind className="w-5 h-5 mr-2" />
        {t("startBreathing")}
      </Button>
    );
  }

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="relative rounded-2xl bg-secondary/5 border border-secondary/20 p-8 flex flex-col items-center"
      >
        <button
          onClick={() => setActive(false)}
          className="absolute top-3 right-3 p-1.5 rounded-lg hover:bg-muted transition-colors"
        >
          <X className="w-4 h-4 text-muted-foreground" />
        </button>

        {/* Breathing circle */}
        <div className="relative w-36 h-36 flex items-center justify-center">
          <motion.div
            className="absolute inset-0 rounded-full bg-[#60A5FA]/20"
            animate={{
              scale: phase === 0 ? 1.4 : phase === 1 ? 1.4 : 1,
            }}
            transition={{
              duration: PHASES[phase].duration / 1000,
              ease: "easeInOut",
            }}
          />
          <motion.div
            className="absolute inset-3 rounded-full bg-[#60A5FA]/30"
            animate={{
              scale: phase === 0 ? 1.3 : phase === 1 ? 1.3 : 1,
            }}
            transition={{
              duration: PHASES[phase].duration / 1000,
              ease: "easeInOut",
              delay: 0.1,
            }}
          />
          <motion.span
            key={phase}
            initial={{ opacity: 0, y: 5 }}
            animate={{ opacity: 1, y: 0 }}
            className="relative z-10 text-sm font-semibold text-[#60A5FA]"
          >
            {PHASES[phase].label}
          </motion.span>
        </div>

        <p className="mt-6 text-sm text-muted-foreground">
          {timeLeft}s {t("remaining")}
        </p>
      </motion.div>
    </AnimatePresence>
  );
}
