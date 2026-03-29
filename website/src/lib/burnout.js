export function calculateBurnout(data) {
  let score = 0;
  if (data.sleep_hours < 6) score += 20;
  if (data.work_hours > 8) score += 20;
  if (data.mood <= 2) score += 20;
  if (data.deadlines > 5) score += 20;
  if (data.overwhelmed) score += 20;
  score = Math.min(score, 100);

  let level = "low";
  if (score >= 67) level = "high";
  else if (score >= 34) level = "medium";

  return { burnout_score: score, burnout_level: level };
}

export function getBurnoutColor(level) {
  if (level === "high") return "text-destructive";
  if (level === "medium") return "text-amber-600";
  return "text-secondary";
}

export function getBurnoutBgColor(level) {
  if (level === "high") return "bg-destructive/10";
  if (level === "medium") return "bg-accent/20";
  return "bg-secondary/10";
}

export function getSuggestions(level) {
  if (level === "high") {
    return [
      { icon: "Pause", text: "Take a break today" },
      { icon: "ListX", text: "Pause non-critical tasks" },
      { icon: "MessageCircle", text: "Talk to someone you trust" },
      { icon: "Wind", text: "Try a breathing exercise" },
    ];
  }
  if (level === "medium") {
    return [
      { icon: "CalendarMinus", text: "Reduce your workload today" },
      { icon: "Clock", text: "Schedule dedicated rest time" },
      { icon: "Coffee", text: "Take regular short breaks" },
    ];
  }
  return [
    { icon: "ThumbsUp", text: "Great job — maintain your routine" },
    { icon: "Stretch", text: "Take short breaks between tasks" },
  ];
}
