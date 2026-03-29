import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
} from "recharts";
import { format } from "date-fns";

const CustomTooltip = ({ active, payload }) => {
  if (!active || !payload?.length) return null;
  const data = payload[0].payload;
  return (
    <div className="bg-card border border-border rounded-lg px-3 py-2 shadow-lg">
      <p className="text-xs text-muted-foreground">{data.label}</p>
      <p className="text-sm font-semibold">Avg Score: {data.score}</p>
      <p className="text-xs capitalize text-muted-foreground">{data.level}</p>
      {data.count > 1 && (
        <p className="text-xs text-muted-foreground">({data.count} logs)</p>
      )}
    </div>
  );
};

export default function TrendChart({ logs }) {
  // Group logs by date and average the burnout scores
  const byDate = {};
  logs.forEach((log) => {
    if (!byDate[log.date]) byDate[log.date] = [];
    byDate[log.date].push(log);
  });

  // Generate last 7 days including missing dates
  const last7Days = [];
  const today = new Date();
  for (let i = 6; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    const dateStr = format(date, "yyyy-MM-dd");
    last7Days.push(dateStr);
  }

  const chartData = last7Days.map((date) => {
    const entries = byDate[date];
    if (!entries || entries.length === 0) {
      return {
        label: format(new Date(date), "MMM d"),
        score: 0,
        level: "low",
        count: 0,
      };
    }
    const avgScore = Math.round(
      entries.reduce((s, l) => s + l.burnout_score, 0) / entries.length,
    );
    const level = avgScore >= 67 ? "high" : avgScore >= 33 ? "medium" : "low";
    return {
      label: format(new Date(date), "MMM d"),
      score: avgScore,
      level,
      count: entries.length,
    };
  });

  if (chartData.length === 0) {
    return (
      <div className="h-48 flex items-center justify-center text-muted-foreground text-sm">
        No data yet — log your first day to see trends
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={200}>
      <AreaChart
        data={chartData}
        margin={{ top: 5, right: 5, bottom: 5, left: -20 }}
      >
        <defs>
          <linearGradient id="burnoutGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#4F46E5" stopOpacity={0.25} />
            <stop offset="100%" stopColor="#4F46E5" stopOpacity={0} />
          </linearGradient>
        </defs>
        <XAxis
          dataKey="label"
          tick={{ fontSize: 12, fill: "hsl(var(--muted-foreground))" }}
          axisLine={false}
          tickLine={false}
        />
        <YAxis
          domain={[0, 100]}
          tick={{ fontSize: 12, fill: "hsl(var(--muted-foreground))" }}
          axisLine={false}
          tickLine={false}
        />
        <Tooltip content={<CustomTooltip />} />
        <ReferenceLine
          y={33}
          stroke="hsl(var(--border))"
          strokeDasharray="3 3"
        />
        <ReferenceLine
          y={67}
          stroke="hsl(var(--border))"
          strokeDasharray="3 3"
        />
        <Area
          type="monotone"
          dataKey="score"
          stroke="#4F46E5"
          strokeWidth={2.5}
          fill="url(#burnoutGrad)"
          dot={(props) => {
            const { cx, cy, payload } = props;
            const color =
              payload.level === "high"
                ? "#F87171"
                : payload.level === "medium"
                  ? "#FBBF24"
                  : "#34D399";
            return (
              <circle
                key={props.index}
                cx={cx}
                cy={cy}
                r={5}
                fill={color}
                stroke="#fff"
                strokeWidth={2}
              />
            );
          }}
          activeDot={{ r: 6, fill: "#4F46E5", strokeWidth: 2, stroke: "#fff" }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
