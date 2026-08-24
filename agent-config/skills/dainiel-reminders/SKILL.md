---
name: dainiel-reminders
description: Set, list, and cancel one-time Slack reminders through the dainiel MCP server. Use when the user says "remind me ...", asks to set a reminder, list pending reminders, cancel one, or wants a Slack nudge at or after a specific time.
---

# Dainiel Reminders

Reminders are delivered as a Slack DM from Dainiel at the requested minute,
then the schedule is removed — they are strictly one-time.

## Tools (dainiel MCP)

| Tool                          | Purpose                                                                                                                    |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `mcp__dainiel__set_reminder`  | Create: `message` (required, ≤2000 chars) plus either `remind_at` (ISO 8601 **with UTC offset**) or `in_minutes` (>0, ≤527040 ≈ 1 year) |
| `mcp__dainiel__list_reminders`| Pending first, plus recent sent/cancelled; returns ids and fire times in UTC                                                 |
| `mcp__dainiel__cancel_reminder` | Cancel a pending reminder by `id` from `list_reminders`                                                                    |

In Claude Code the schemas are deferred — load them first with
ToolSearch `select:mcp__dainiel__set_reminder,mcp__dainiel__list_reminders,mcp__dainiel__cancel_reminder`.
If the `dainiel` server is missing entirely:
`claude mcp add --scope user --transport http dainiel https://dainiel.lovable.app/mcp`,
then authenticate via `/mcp`.

## Setting a reminder

1. Pick the time parameter:
   - Relative ("in 20 minutes", "in 2 hours") → `in_minutes`.
   - Absolute ("at 16:30", "tomorrow 9am", "Monday morning") → `remind_at`.
     Resolve the user's current local timezone first (`date +%z`) and send
     that offset explicitly — never assume UTC, never send a naive timestamp.
   - Minute granularity; seconds are ignored.
2. Write `message` as a self-contained imperative — it lands in Slack
   verbatim. Good: "Review the AGE-702 PR before standup".
   Bad: "reminder about that PR thing we discussed".
3. Call `set_reminder`, then confirm the resolved fire time back to the user
   in their local time.

Vague times: morning → 09:00, noon → 12:00, afternoon → 15:00,
evening → 18:00, end of day → 17:00 local. Say which time you picked.

## Listing and cancelling

- "what reminders do I have" → `list_reminders`; convert the UTC fire times
  to local time when presenting.
- To cancel or reschedule, call `list_reminders` first to get the `id` —
  never guess ids. Reschedule = cancel + set a new one (there is no update).

## Not this skill

Recurring asks ("every Monday", "daily at 9") are Dainiel **heartbeats** —
this MCP only reads them (`list_heartbeats`), it cannot create them. Point
the user to Dainiel itself (dainiel.lovable.app) to create or change one.
