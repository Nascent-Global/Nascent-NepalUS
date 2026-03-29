This project contains everything you need to run your app locally.

**Edit the code in your local development environment**

Any change pushed to the repo will also be reflected in the Base44 Builder.

**Prerequisites:**

1. Clone the repository using the project's Git URL
2. Navigate to the project directory
3. Install dependencies: `npm install`
4. Create an `.env.local` file and set the right environment variables

```
VITE_BASE44_APP_ID=your_app_id
VITE_BASE44_APP_BASE_URL=your_backend_url

e.g.
VITE_BASE44_APP_ID=cbef744a8545c389ef439ea6
VITE_BASE44_APP_BASE_URL=https://burnout-radar.base44.app/
```

Run the app: `npm run dev`

---

## About This Project

**Burnout Radar** is a mental health and burnout management web application built with React and the Base44 low-code platform. It helps users track, monitor, and manage burnout through daily logging, analytics, and wellness tools.

### Key Features

- **Daily Burnout Logging** — Log mood, sleep quality, workload, and relationship satisfaction each day
- **Burnout Gauge & Trends** — Visual gauge and line charts showing burnout levels over time
- **Breathing Exercises** — Animated breathing exercise guide for relaxation
- **Pomodoro Timer** — Three timer modes (25-min work, 5-min short break, 15-min long break)
- **Relaxing Sounds** — Audio player for relaxation and meditation tracks
- **Psychologist Q&A** — Browse and read answers from licensed psychologists
- **Educational Resources** — Articles and radio program content on mental wellness
- **Multi-Language Support** — Full English and Nepali (नेपाली) language support

### Tech Stack

| Layer | Technology |
|---|---|
| Frontend Framework | React 18, React Router v6 |
| Build Tool | Vite |
| Styling | Tailwind CSS, Shadcn/Radix UI |
| Animations | Framer Motion |
| Data Fetching | TanStack React Query v5 |
| Forms & Validation | React Hook Form + Zod |
| Charts | Recharts |
| Icons | Lucide React |
| Backend | Base44 SDK (low-code platform) |

### Project Structure

```
website/
├── src/
│   ├── pages/            # Route-level page components
│   ├── components/       # Reusable UI components
│   │   ├── ui/           # Radix/Shadcn primitives
│   │   ├── dashboard/    # Dashboard widgets (gauge, chart, suggestions)
│   │   ├── education/    # Education page components
│   │   ├── psychologist/ # Psychologist Q&A components
│   │   └── layout/       # App layout and navigation
│   ├── api/              # Base44 API client setup
│   ├── lib/              # Context providers (Auth, Language) and burnout algorithm
│   ├── hooks/            # Custom React hooks
│   └── utils/            # Utility helpers (Nepali date, digit conversion)
├── entities/             # Base44 entity schemas (DailyLog, Question)
├── vite.config.js        # Vite + Base44 plugin config
└── tailwind.config.js    # Tailwind theme config
```

### How Burnout Is Calculated

The app uses a custom algorithm (`src/lib/burnout.js`) that takes four daily inputs — **mood**, **sleep quality**, **workload**, and **relationship satisfaction** — and produces a burnout score. This score drives the gauge, alerts, and wellness suggestions shown on the dashboard.