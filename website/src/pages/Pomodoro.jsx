import { useState, useEffect, useRef, useCallback } from "react";
import { motion } from "framer-motion";
import { Play, Pause, RotateCcw } from "lucide-react";
import { useLanguage } from "@/lib/LanguageContext";

const MODES = [
  {
    id: "pomodoro",
    labelKey: "pomodoroMode",
    minutes: 25,
    color: "#EF4444",
    bg: "from-[#EF4444] to-[#DC2626]",
  },
  {
    id: "short-break",
    labelKey: "shortBreak",
    minutes: 5,
    color: "#10B981",
    bg: "from-[#10B981] to-[#059669]",
  },
  {
    id: "long-break",
    labelKey: "longBreak",
    minutes: 15,
    color: "#4F46E5",
    bg: "from-[#4F46E5] to-[#4338CA]",
  },
];

function pad(n) {
  return String(n).padStart(2, "0");
}

function padNe(n) {
  return toNepali(String(n).padStart(2, "0"));
}

const nepaliDigits = ["०", "१", "२", "३", "४", "५", "६", "७", "८", "९"];
function toNepali(n) {
  return String(n).replace(/[0-9]/g, (d) => nepaliDigits[d]);
}

export default function Pomodoro() {
  const { t, lang } = useLanguage();
  const [modeIdx, setModeIdx] = useState(0);
  const [secondsLeft, setSecondsLeft] = useState(MODES[0].minutes * 60);
  const [running, setRunning] = useState(false);
  const intervalRef = useRef(null);
  const mode = MODES[modeIdx];

  const reset = useCallback(
    (idx = modeIdx) => {
      clearInterval(intervalRef.current);
      setRunning(false);
      setSecondsLeft(MODES[idx].minutes * 60);
    },
    [modeIdx],
  );

  useEffect(() => {
    if (running) {
      intervalRef.current = setInterval(() => {
        setSecondsLeft((s) => {
          if (s <= 1) {
            clearInterval(intervalRef.current);
            setRunning(false);
            return 0;
          }
          return s - 1;
        });
      }, 1000);
    } else {
      clearInterval(intervalRef.current);
    }
    return () => clearInterval(intervalRef.current);
  }, [running]);

  const handleModeChange = (idx) => {
    setModeIdx(idx);
    reset(idx);
    setSecondsLeft(MODES[idx].minutes * 60);
  };

  const mins = Math.floor(secondsLeft / 60);
  const secs = secondsLeft % 60;
  const total = mode.minutes * 60;
  const progress = (total - secondsLeft) / total;
  const circumference = 2 * Math.PI * 120;
  const strokeDash = circumference * progress;

  const statusLabel = running
    ? mode.id === "pomodoro"
      ? t("timeToFocus")
      : t("takeABreak")
    : secondsLeft === 0
      ? t("sessionComplete")
      : t("readyToStart");

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-8 max-w-lg mx-auto"
    >
      {/* Header */}
      <div>
        <h1 className="font-display text-2xl sm:text-3xl font-bold">
          {t("pomodoroTitle")}
        </h1>
        <p className="text-muted-foreground mt-1 text-sm">
          {t("pomodoroSubtitle")}
        </p>
      </div>

      {/* Timer card */}
      <div
        className={`rounded-3xl bg-gradient-to-br ${mode.bg} p-8 flex flex-col items-center gap-6 shadow-xl`}
      >
        {/* Mode tabs */}
        <div className="flex items-center gap-1 bg-white/20 rounded-xl p-1">
          {MODES.map((m, i) => (
            <button
              key={m.id}
              onClick={() => handleModeChange(i)}
              className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all duration-200 ${
                modeIdx === i
                  ? "bg-white text-gray-800 shadow"
                  : "text-white/80 hover:text-white"
              }`}
            >
              {t(m.labelKey)}
            </button>
          ))}
        </div>

        {/* Circular progress */}
        <div className="relative flex items-center justify-center">
          <svg width="280" height="280" className="-rotate-90">
            {/* Track */}
            <circle
              cx="140"
              cy="140"
              r="120"
              fill="none"
              stroke="rgba(255,255,255,0.2)"
              strokeWidth="8"
            />
            {/* Progress */}
            <circle
              cx="140"
              cy="140"
              r="120"
              fill="none"
              stroke="white"
              strokeWidth="8"
              strokeLinecap="round"
              strokeDasharray={`${strokeDash} ${circumference}`}
              style={{ transition: "stroke-dasharray 0.5s ease" }}
            />
          </svg>

          {/* Time display */}
          <div className="absolute flex flex-col items-center">
            <span className="text-7xl font-bold text-white tabular-nums tracking-tight">
              {lang === "ne"
                ? `${padNe(mins)}:${padNe(secs)}`
                : `${pad(mins)}:${pad(secs)}`}
            </span>
            <span className="text-white/70 text-sm mt-1">{statusLabel}</span>
          </div>
        </div>

        {/* Controls */}
        <div className="flex items-center gap-4">
          <button
            onClick={() => reset()}
            className="w-12 h-12 rounded-full bg-white/20 hover:bg-white/30 transition flex items-center justify-center text-white"
          >
            <RotateCcw className="w-5 h-5" />
          </button>
          <button
            onClick={() => setRunning((r) => !r)}
            className="w-20 h-20 rounded-full bg-white hover:scale-105 transition-transform shadow-lg flex items-center justify-center"
            style={{ color: mode.color }}
          >
            {running ? (
              <Pause className="w-8 h-8" />
            ) : (
              <Play className="w-8 h-8 ml-1" />
            )}
          </button>
          <div className="w-12 h-12" /> {/* spacer */}
        </div>
      </div>

      {/* Info cards */}
      <div className="grid grid-cols-3 gap-3">
        {MODES.map((m, i) => (
          <button
            key={m.id}
            onClick={() => handleModeChange(i)}
            className={`rounded-xl border p-4 flex flex-col items-center gap-1 transition-all ${
              modeIdx === i
                ? "border-transparent shadow-md"
                : "border-border bg-card hover:bg-muted"
            }`}
            style={
              modeIdx === i
                ? {
                    backgroundColor: m.color + "18",
                    borderColor: m.color + "44",
                  }
                : {}
            }
          >
            <span
              className="text-2xl font-bold"
              style={modeIdx === i ? { color: m.color } : {}}
            >
              {lang === "ne" ? toNepali(m.minutes) : m.minutes}
            </span>
            <span className="text-xs text-muted-foreground text-center leading-tight">
              {t(m.labelKey)}
            </span>
            <span className="text-xs text-muted-foreground">
              {t("minutes")}
            </span>
          </button>
        ))}
      </div>
    </motion.div>
  );
}
