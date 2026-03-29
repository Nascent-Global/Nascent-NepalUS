import { base44 } from "@/api/base44Client";
import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { PenLine, Moon, Briefcase, Smile } from "lucide-react";
import { useLanguage } from "@/lib/LanguageContext";
import { motion } from "framer-motion";

import BurnoutGauge from "@/components/dashboard/BurnoutGauge";
import TrendChart from "@/components/dashboard/TrendChart";
import AlertBanner from "@/components/dashboard/AlertBanner";
import Suggestions from "@/components/dashboard/Suggestions";
import BreathingExercise from "@/components/dashboard/BreathingExercise";
import RelaxingSoundsBanner from "@/components/dashboard/RelaxingSoundsBanner";
import PomodoroBanner from "@/components/dashboard/PomodoroBanner";
import PsychologistBanner from "@/components/dashboard/PsychologistBanner";

export default function Dashboard() {
  const { t } = useLanguage();
  const { data: logs = [], isLoading } = useQuery({
    queryKey: ["dailyLogs"],
    queryFn: () => base44.entities.DailyLog.list("-date", 30),
  });

  const sorted = [...logs].sort((a, b) => new Date(a.date) - new Date(b.date));
  const latest = sorted[sorted.length - 1];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-4 border-muted border-t-primary rounded-full animate-spin" />
      </div>
    );
  }

  if (!latest) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center py-24"
      >
        <div className="w-20 h-20 rounded-2xl bg-primary/10 flex items-center justify-center mx-auto mb-6">
          <PenLine className="w-9 h-9 text-primary" />
        </div>
        <h1 className="font-display text-3xl font-bold mb-3">
          {t("welcomeTitle")}
        </h1>
        <p className="text-muted-foreground max-w-md mx-auto mb-8">
          {t("welcomeDesc")}
        </p>
        <Link to="/log">
          <Button size="lg" className="rounded-xl px-8">
            {t("logFirstDay")}
          </Button>
        </Link>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="space-y-6"
    >
      {/* Psychologist Banner */}
      <PsychologistBanner />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-2xl sm:text-3xl font-bold">
            {t("dashboard")}
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            {t("burnoutOverview")}
          </p>
        </div>
        <Link to="/log">
          <Button className="rounded-xl">
            <PenLine className="w-4 h-4 mr-2" />
            {t("logToday")}
          </Button>
        </Link>
      </div>

      {/* Alert */}
      <AlertBanner logs={sorted} />

      {/* Top row: Gauge + Quick stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <Card className="md:col-span-1 border-0 shadow-sm">
          <CardContent className="pt-8 pb-6 flex justify-center">
            <BurnoutGauge
              score={latest.burnout_score}
              level={latest.burnout_level}
            />
          </CardContent>
        </Card>

        <Card className="md:col-span-2 border-0 shadow-sm">
          <CardHeader className="pb-2">
            <CardTitle className="text-base font-semibold">
              {t("sevenDayTrend")}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <TrendChart logs={sorted} />
          </CardContent>
        </Card>
      </div>

      {/* Quick stats from latest entry */}
      <div className="grid grid-cols-3 gap-4">
        <QuickStat
          icon={Moon}
          label={t("sleep")}
          value={`${latest.sleep_hours}h`}
        />
        <QuickStat
          icon={Briefcase}
          label={t("work")}
          value={`${latest.work_hours}h`}
        />
        <QuickStat icon={Smile} label={t("mood")} value={`${latest.mood}/5`} />
      </div>

      {/* Bottom row: Suggestions + Breathing */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        <Card className="border-0 shadow-sm">
          <CardHeader className="pb-3">
            <CardTitle className="text-base font-semibold">
              {t("suggestions")}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <Suggestions level={latest.burnout_level} />
          </CardContent>
        </Card>

        <Card className="border-0 shadow-sm">
          <CardHeader className="pb-3">
            <CardTitle className="text-base font-semibold">
              {t("quickRecovery")}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <BreathingExercise />
          </CardContent>
        </Card>
      </div>

      {/* Relaxing Sounds Banner */}
      <div className="mt-8">
        <RelaxingSoundsBanner />
      </div>

      <div className="mt-2" />

      {/* Pomodoro Banner */}
      <PomodoroBanner />
    </motion.div>
  );
}

function QuickStat({ icon: Icon, label, value }) {
  return (
    <div className="rounded-xl bg-card border border-border/50 shadow-sm px-4 py-3 flex items-center gap-3">
      <div className="w-9 h-9 rounded-lg bg-muted flex items-center justify-center shrink-0">
        <Icon className="w-4 h-4 text-muted-foreground" />
      </div>
      <div>
        <p className="text-xs text-muted-foreground">{label}</p>
        <p className="text-lg font-semibold leading-tight">{value}</p>
      </div>
    </div>
  );
}
