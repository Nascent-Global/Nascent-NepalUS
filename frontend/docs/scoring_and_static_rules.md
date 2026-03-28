# Scoring and Static Rules

## Burnout Classification
- Low: `0-30`
- Medium: `31-70`
- High: `71-100`

## Alert Rules
- High-risk alert when score `>= 70`
- Rising-trend alert when today's latest score is at least `+5` above yesterday's latest score

## Fixed Weight Model (v1)
- Sleep penalty max: `25`
- Workload penalty max: `25`
- Mood penalty max: `28`
- Self-check penalty max: `10`
- Deadline pressure max: `30`

## Recovery Task Limits
- Generate up to `2-3` recovery tasks per day
- Avoid duplicate recovery task titles for the same day

## Recovery Impact Keys
- `sleep_recovery`: 8
- `workload_trim`: 10
- `break`: 5
- `focus_reset`: 4
- `breathing`: 6
- `general_recovery`: 3

## Notes
All static constants are centralized in `lib/core/constants.dart` so they can be tuned without changing DB shape or UI contracts.
