import { base44 } from "@/api/base44Client";
import { useQuery } from "@tanstack/react-query";
import { format } from "date-fns";

import { motion } from "framer-motion";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Moon, Briefcase, Smile, ListTodo, AlertCircle } from "lucide-react";
import { getBurnoutColor, getBurnoutBgColor } from "@/lib/burnout";
import TrendChart from "@/components/dashboard/TrendChart";
import { useLanguage } from "@/lib/LanguageContext";

const NE_DAYS = [
  "आइतबार",
  "सोमबार",
  "मङ्गलबार",
  "बुधबार",
  "बिहीबार",
  "शुक्रबार",
  "शनिबार",
];
const NE_MONTHS = [
  "जनवरी",
  "फेब्रुअरी",
  "मार्च",
  "अप्रिल",
  "मे",
  "जुन",
  "जुलाई",
  "अगस्ट",
  "सेप्टेम्बर",
  "अक्टोबर",
  "नोभेम्बर",
  "डिसेम्बर",
];

function formatDateNe(date) {
  return `${NE_DAYS[date.getDay()]}, ${NE_MONTHS[date.getMonth()]} ${date.getDate()}`;
}

export default function History() {
  const { t, lang } = useLanguage();
  const { data: logs = [], isLoading } = useQuery({
    queryKey: ["dailyLogs"],
    queryFn: () => base44.entities.DailyLog.list("-date", 50),
  });

  const sorted = [...logs].sort((a, b) => new Date(a.date) - new Date(b.date));

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-4 border-muted border-t-primary rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="space-y-6"
    >
      <div>
        <h1 className="font-display text-2xl sm:text-3xl font-bold">
          {t("historyTitle")}
        </h1>
        <p className="text-sm text-muted-foreground mt-1">{t("historyDesc")}</p>
      </div>

      {/* Trend chart */}
      <Card className="border-0 shadow-sm">
        <CardHeader className="pb-2">
          <CardTitle className="text-base font-semibold">
            {t("burnoutTrend")}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <TrendChart logs={sorted} />
        </CardContent>
      </Card>

      {/* Entry list */}
      <div className="space-y-3">
        {logs.map((log, i) => (
          <motion.div
            key={log.id}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.03 }}
          >
            <Card className="border-0 shadow-sm">
              <CardContent className="py-4 px-5">
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <span className="text-sm font-medium">
                      {lang === "ne"
                        ? formatDateNe(new Date(log.date + "T00:00:00"))
                        : format(
                            new Date(log.date + "T00:00:00"),
                            "EEEE, MMM d",
                          )}
                    </span>
                    <div className="text-xs text-muted-foreground mt-0.5">
                      {log.session
                        ? log.session === "morning"
                          ? `🌅 ${t("morning")}`
                          : log.session === "afternoon"
                            ? `☀️ ${t("afternoon")}`
                            : `🌙 ${t("night")}`
                        : log.logged_at
                          ? format(new Date(log.logged_at), "h:mm a")
                          : null}
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <span
                      className={`text-lg font-bold ${getBurnoutColor(log.burnout_level)}`}
                    >
                      {log.burnout_score}
                    </span>
                    <Badge
                      className={`capitalize text-xs ${getBurnoutBgColor(log.burnout_level)} ${getBurnoutColor(log.burnout_level)} border-0`}
                    >
                      {log.burnout_level}
                    </Badge>
                  </div>
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
                  <StatPill
                    icon={Moon}
                    label={t("sleep")}
                    value={`${log.sleep_hours}h`}
                  />
                  <StatPill
                    icon={Briefcase}
                    label={t("work")}
                    value={`${log.work_hours}h`}
                  />
                  <StatPill
                    icon={Smile}
                    label={t("mood")}
                    value={`${log.mood}/5`}
                  />
                  <StatPill
                    icon={ListTodo}
                    label={t("tasks")}
                    value={log.deadlines}
                  />
                </div>
                {log.overwhelmed && (
                  <div className="mt-2 flex items-center gap-1.5 text-xs text-destructive">
                    <AlertCircle className="w-3 h-3" />
                    {t("feelingOverwhelmedAlert")}
                  </div>
                )}
              </CardContent>
            </Card>
          </motion.div>
        ))}

        {logs.length === 0 && (
          <div className="text-center py-16 text-muted-foreground">
            {t("noEntriesYet")}
          </div>
        )}
      </div>
    </motion.div>
  );
}

function StatPill({ icon: Icon, label, value }) {
  return (
    <div className="flex items-center gap-2 bg-muted/50 rounded-lg px-3 py-1.5">
      <Icon className="w-3.5 h-3.5 text-muted-foreground" />
      <span className="text-muted-foreground">{label}</span>
      <span className="font-medium ml-auto">{value}</span>
    </div>
  );
}
