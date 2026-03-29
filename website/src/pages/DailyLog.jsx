import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { useMutation, useQueryClient, useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { format } from "date-fns";
import { motion } from "framer-motion";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Slider } from "@/components/ui/slider";
import { Switch } from "@/components/ui/switch";
import { Input } from "@/components/ui/input";
import {
  Check,
  Moon,
  Briefcase,
  Smile,
  ListTodo,
  AlertCircle,
} from "lucide-react";
import { calculateBurnout } from "@/lib/burnout";
import { useLanguage } from "@/lib/LanguageContext";

const moodEmojis = ["😩", "😟", "😐", "🙂", "😊"];

export default function DailyLog() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { t, lang } = useLanguage();

  const nepaliDays = [
    "आइतबार",
    "सोमबार",
    "मंगलबार",
    "बुधबार",
    "बिहीबार",
    "शुक्रबार",
    "शनिबार",
  ];
  const nepaliMonths = [
    "जनवरी",
    "फेब्रुअरी",
    "मार्च",
    "अप्रिल",
    "मे",
    "जुन",
    "जुलाई",
    "अगस्त",
    "सेप्टेम्बर",
    "अक्टोबर",
    "नोभेम्बर",
    "डिसेम्बर",
  ];
  const now = new Date();
  const formattedDate =
    lang === "ne"
      ? `${nepaliDays[now.getDay()]}, ${nepaliMonths[now.getMonth()]} ${now.getDate()}`
      : format(now, "EEEE, MMMM d");
  const today = format(new Date(), "yyyy-MM-dd");

  const { data: todayLogs, isLoading: checkingToday } = useQuery({
    queryKey: ["dailyLogs", "today"],
    queryFn: () => base44.entities.DailyLog.filter({ date: today }),
  });

  const logCount = todayLogs ? todayLogs.length : 0;
  const alreadyLoggedToday = false; // always allow submission
  const sessions = ["morning", "afternoon", "night"];
  const currentSession = sessions[Math.min(logCount, 2)];
  // If already 3 logs, we'll update the last one instead of creating
  const lastLog =
    todayLogs && todayLogs.length > 0 ? todayLogs[todayLogs.length - 1] : null;
  const shouldUpdate = logCount >= 3;

  const [form, setForm] = useState({
    sleep_hours: 7,
    work_hours: 8,
    mood: 3,
    deadlines: 3,
    overwhelmed: false,
  });

  const mutation = useMutation({
    mutationFn: async (data) => {
      const { burnout_score, burnout_level } = calculateBurnout(data);
      const payload = {
        ...data,
        date: today,
        logged_at: new Date().toISOString(),
        session: currentSession,
        burnout_score,
        burnout_level,
      };
      if (shouldUpdate && lastLog) {
        return base44.entities.DailyLog.update(lastLog.id, payload);
      }
      return base44.entities.DailyLog.create(payload);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["dailyLogs"] });
      navigate("/");
    },
  });

  const update = (field, value) => setForm((p) => ({ ...p, [field]: value }));

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="max-w-lg mx-auto"
    >
      <div className="mb-8">
        <h1 className="font-display text-2xl sm:text-3xl font-bold">
          {t("howAreYou")}
        </h1>
        <p className="text-sm text-muted-foreground mt-1">
          {formattedDate}
          <span className="ml-2 px-2 py-0.5 rounded-full bg-primary/10 text-primary text-xs font-medium">
            {currentSession === "morning"
              ? `🌅 ${t("morning")}`
              : currentSession === "afternoon"
                ? `☀️ ${t("afternoon")}`
                : `🌙 ${t("night")}`}
            {shouldUpdate
              ? ` · ${t("updatingLastLog")}`
              : ` · ${t("logOf")} ${logCount + 1} ${t("of")} 3`}
          </span>
        </p>
      </div>

      <Card className="border-0 shadow-sm">
        <CardContent className="pt-6 space-y-8">
          {/* Sleep */}
          <FormField
            icon={Moon}
            label={t("sleepLastNight")}
            value={`${form.sleep_hours}h`}
          >
            <Slider
              value={[form.sleep_hours]}
              onValueChange={([v]) => update("sleep_hours", v)}
              min={0}
              max={12}
              step={0.5}
              className="mt-3"
            />
            <div className="flex justify-between text-xs text-muted-foreground mt-1">
              <span>0h</span>
              <span>12h</span>
            </div>
          </FormField>

          {/* Work hours */}
          <FormField
            icon={Briefcase}
            label={t("workStudyHours")}
            value={`${form.work_hours}h`}
          >
            <Slider
              value={[form.work_hours]}
              onValueChange={([v]) => update("work_hours", v)}
              min={0}
              max={16}
              step={0.5}
              className="mt-3"
            />
            <div className="flex justify-between text-xs text-muted-foreground mt-1">
              <span>0h</span>
              <span>16h</span>
            </div>
          </FormField>

          {/* Mood */}
          <FormField
            icon={Smile}
            label={t("mood")}
            value={moodEmojis[form.mood - 1]}
          >
            <div className="flex justify-between mt-3">
              {moodEmojis.map((emoji, i) => (
                <button
                  key={i}
                  onClick={() => update("mood", i + 1)}
                  className={`w-12 h-12 rounded-xl text-xl flex items-center justify-center transition-all ${
                    form.mood === i + 1
                      ? "bg-primary/10 ring-2 ring-primary scale-110"
                      : "bg-muted hover:bg-muted/80"
                  }`}
                >
                  {emoji}
                </button>
              ))}
            </div>
          </FormField>

          {/* Deadlines */}
          <FormField icon={ListTodo} label={t("deadlinesToday")}>
            <Input
              type="number"
              min={0}
              max={20}
              value={form.deadlines}
              onChange={(e) =>
                update("deadlines", parseInt(e.target.value) || 0)
              }
              className="mt-3 w-24"
            />
          </FormField>

          {/* Overwhelmed */}
          <div className="flex items-center justify-between py-2">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-muted flex items-center justify-center">
                <AlertCircle className="w-4 h-4 text-muted-foreground" />
              </div>
              <Label className="text-sm font-medium">
                {t("feelingOverwhelmed")}
              </Label>
            </div>
            <Switch
              checked={form.overwhelmed}
              onCheckedChange={(v) => update("overwhelmed", v)}
            />
          </div>

          {shouldUpdate && (
            <p className="text-xs text-center text-muted-foreground -mb-4">
              {t("reachedLimit")}
            </p>
          )}
          <Button
            onClick={() => mutation.mutate(form)}
            disabled={mutation.isPending || checkingToday}
            className="w-full h-12 rounded-xl text-base"
            size="lg"
          >
            {mutation.isPending ? (
              <div className="w-5 h-5 border-2 border-primary-foreground border-t-transparent rounded-full animate-spin" />
            ) : (
              <>
                <Check className="w-5 h-5 mr-2" />
                {t("submitLog")}
              </>
            )}
          </Button>
        </CardContent>
      </Card>
    </motion.div>
  );
}

function FormField({ icon: Icon, label, value, children }) {
  return (
    <div>
      <div className="flex items-center justify-between mb-1">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-muted flex items-center justify-center">
            <Icon className="w-4 h-4 text-muted-foreground" />
          </div>
          <Label className="text-sm font-medium">{label}</Label>
        </div>
        {value && <span className="text-sm font-semibold">{value}</span>}
      </div>
      {children}
    </div>
  );
}
