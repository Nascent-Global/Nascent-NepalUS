## MVP Description — Burnout Reduction App 
---

# 1. Product Overview

A **mobile application for managing burnout during high-intensity work cycles (e.g., hackathons)** by combining:

* Focus tracking
* Sleep monitoring
* Task planning (day/week/month)
* Burnout scoring (multi-factor)

Positioning:

> A **data-driven burnout management system** with real-time intervention — extending beyond passive apps like Headspace.

---

# 2. Core MVP Goal

Build a **functional system that correlates productivity, sleep, and focus → burnout score → intervention**.

---

# 3. Key Concept: Burnout Feedback Loop

```id="burnout-loop"
Input → Analysis → Score → Intervention → Recovery
```

### Inputs:

* Tasks completed
* Focus time
* Screen time (approx.)
* Sleep duration

### Output:

* Burnout score (0–100)
* Suggested action (rest / continue / reset)

---

# 4. New Feature Additions (Extended MVP)

---

## 4.1 Sleep Tracking (Simple Version)

### Input Methods:

* Manual entry:

  * “Hours slept last night”
* Optional:

  * Basic phone usage inference (if accessible)

### Output:

* Sleep quality indicator:

  * Poor (<5h)
  * Moderate (5–7h)
  * Good (>7h)

---

## 4.2 Task Divisor Tool (Planner)

### Core Idea:

Break large goals → manageable chunks

### Modes:

* Daily tasks
* Weekly tasks
* Monthly goals

---

### Example Flow:

User inputs:

> “Build hackathon project”

System divides into:

* Day 1: Setup + idea validation
* Day 2: Core feature
* Day 3: Polish + demo

---

### MVP Implementation:

* No AI required
* Simple checklist system:

  * Add task
  * Mark complete

---

## 4.3 Task Completion Tracking

Store:

* Total tasks created
* Tasks completed

Derive:

* Completion ratio

---

## 4.4 Screen Time Approximation

### MVP Approach:

* Track:

  * Time spent inside app
* Optional:

  * Manual input: “Hours worked today”

---

# 5. Burnout Score System (Core Innovation)

---

## 5.1 Burnout Score Formula (MVP Logic)

```id="burnout-formula"
Burnout Score = w1·(Low Sleep) + w2·(High Screen Time) + w3·(Low Task Completion) + w4·(Low Focus Efficiency)
```

---

## 5.2 Simplified Implementation

### Normalize Inputs (0–1):

| Factor           | Condition                   | Score |
| ---------------- | --------------------------- | ----- |
| Sleep            | <5h → high burnout          | 1     |
| Screen Time      | >8h → high burnout          | 1     |
| Task Completion  | <50% → high burnout         | 1     |
| Focus Efficiency | low sessions → high burnout | 1     |

---

### Example Weights:

| Factor          | Weight |
| --------------- | ------ |
| Sleep           | 0.35   |
| Screen time     | 0.25   |
| Task completion | 0.2    |
| Focus time      | 0.2    |

---

### Output:

| Score Range | Meaning      |
| ----------- | ------------ |
| 0–30        | Healthy      |
| 31–60       | Moderate     |
| 61–100      | High burnout |

---

## 5.3 Intervention Mapping

| Burnout Level | Action                          |
| ------------- | ------------------------------- |
| Low           | Continue working                |
| Medium        | Suggest short reset             |
| High          | Force break + breathing session |

---

# 6. Updated Feature List (Final MVP Scope)

## Core

* Focus timer (Pomodoro)
* Reset session (breathing)
* Session tracking

## New Additions

* Sleep input + tracking
* Task planner (day/week/month)
* Task completion tracking
* Burnout score calculation
* Smart intervention suggestions

---

# 7. Updated Data Model

## User

* id

## Session

* duration
* timestamp

## SleepEntry

* hours
* date

## Task

* title
* type (daily/weekly/monthly)
* completed (boolean)

## BurnoutScore

* score
* timestamp

---

# 8. Updated System Architecture

```id="arch-v2"
[React Native App]
       ↓
   REST API
       ↓
   [Django Backend]
       ↓
   [Database]
```

---

## Responsibilities

### React Native

* UI (tasks, sleep input, dashboard)
* Timer
* Local calculations (optional)

### Django Backend

* Store:

  * tasks
  * sessions
  * sleep
* Compute burnout score (recommended)

---

# 9. UI Screens (Updated)

* Home Dashboard:

  * Burnout score
  * Quick actions

* Focus Screen:

  * Timer

* Reset Screen:

  * Breathing

* Task Planner:

  * Add / complete tasks

* Sleep Input Screen:

  * Enter hours

* Stats Screen:

  * Trends + score history

---

# 10. Demo Flow (Important)

1. User adds tasks
2. Starts focus session
3. Logs sleep
4. Completes some tasks
5. System calculates burnout score
6. App suggests:

   * “Take a break” or “Continue”
7. User triggers reset session

---

# 11. Key Differentiator

| Feature                | Typical Apps | Your App |
| ---------------------- | ------------ | -------- |
| Meditation             | Yes          | Yes      |
| Task tracking          | No           | Yes      |
| Sleep tracking         | Limited      | Yes      |
| Burnout scoring        | No           | Core     |
| Real-time intervention | Weak         | Strong   |

---

# 12. Constraints (Important)

Keep MVP:

* Rule-based (no ML)
* Simple UI
* Minimal backend logic
* Hardcoded thresholds

---

# 13. One-Line Pitch (Updated)

> “An intelligent burnout tracker that combines sleep, tasks, and focus data to give real-time recovery interventions during intense work sessions.”

---

# 14. Next Step (If needed)

* Burnout score code (Django logic)
* API schema + serializers
* React Native screen/component structure
* UI wireframe for dashboard with score visualization
