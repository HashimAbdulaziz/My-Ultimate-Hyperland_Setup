#!/usr/bin/env python3
import urllib.request
import json
import datetime
import os

# Configuration
CITY = "Cairo"
COUNTRY = "Egypt"
METHOD = 5  # Egyptian General Authority of Survey

# Prayer times change only once per day, so we fetch them at most once per day and
# cache the result. Every other Waybar tick (interval=60) just recomputes the local
# countdown from the cache — no network round-trip, and it keeps working offline.
CACHE = os.path.expanduser("~/.cache/waybar-salah.json")

# Blink the widget red when this many minutes (or fewer) remain before the prayer
URGENT_MINUTES = 30


def to12(hhmm):
    """'19:58' -> '7:58 PM' (12-hour, no leading zero)."""
    h, m = map(int, hhmm.split(':'))
    return datetime.time(h, m).strftime("%I:%M %p").lstrip("0")


def fetch_timings():
    url = f"http://api.aladhan.com/v1/timingsByCity?city={CITY}&country={COUNTRY}&method={METHOD}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    # timeout prevents a stalled network from freezing the Waybar module
    with urllib.request.urlopen(req, timeout=5) as response:
        data = json.loads(response.read().decode())
    return data['data']['timings']


def get_timings():
    today = datetime.date.today().isoformat()

    # 1. Try today's cache first
    try:
        with open(CACHE) as f:
            cached = json.load(f)
        if cached.get("date") == today:
            return cached["timings"]
    except (OSError, ValueError, KeyError):
        pass

    # 2. Cache missing/stale → fetch once and persist
    timings = fetch_timings()
    try:
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        with open(CACHE, "w") as f:
            json.dump({"date": today, "timings": timings}, f)
    except OSError:
        pass
    return timings


try:
    timings = get_timings()

    # We only want the 5 obligatory prayers
    prayers = {
        'Fajr': timings['Fajr'],
        'Dhuhr': timings['Dhuhr'],
        'Asr': timings['Asr'],
        'Maghrib': timings['Maghrib'],
        'Isha': timings['Isha'],
    }

    now = datetime.datetime.now()
    next_prayer = None
    min_diff = None
    next_prayer_time_str = ""

    # Find the next upcoming prayer today
    for name, time_str in prayers.items():
        clean_time = time_str.split(' ')[0]
        hour, minute = map(int, clean_time.split(':'))
        prayer_time = now.replace(hour=hour, minute=minute, second=0, microsecond=0)

        if prayer_time > now:
            diff = prayer_time - now
            if min_diff is None or diff < min_diff:
                min_diff = diff
                next_prayer = name
                next_prayer_time_str = clean_time

    # If no prayers left today, the next is Fajr tomorrow
    if next_prayer is None:
        clean_time = prayers['Fajr'].split(' ')[0]
        hour, minute = map(int, clean_time.split(':'))
        prayer_time = now.replace(hour=hour, minute=minute, second=0, microsecond=0) + datetime.timedelta(days=1)
        min_diff = prayer_time - now
        next_prayer = 'Fajr'
        next_prayer_time_str = clean_time

    # Format the remaining time (uses min_diff = the actual *next* prayer, not the
    # last one seen in the loop — that was the original bug)
    total_seconds = int(min_diff.total_seconds())
    hours, remainder = divmod(total_seconds, 3600)
    minutes, _ = divmod(remainder, 60)

    # Create the output for Waybar (12-hour time + countdown)
    text = f"🕌 {next_prayer} {to12(next_prayer_time_str)} ({hours}h {minutes}m)"

    # Create a nice tooltip showing all prayer times for the day (12-hour)
    tooltip = "Daily Salah Times:\n" + "\n".join(
        [f"{k}: {to12(v.split(' ')[0])}" for k, v in prayers.items()]
    )

    # Add the "urgent" class when the prayer is <= URGENT_MINUTES away → CSS blinks
    # the widget red until the prayer time passes (next tick picks the next prayer).
    classes = [next_prayer.lower()]
    if total_seconds <= URGENT_MINUTES * 60:
        classes.append("urgent")

    print(json.dumps({"text": text, "tooltip": tooltip, "class": classes}))

except Exception as e:
    print(json.dumps({"text": "🕌 API Error", "tooltip": str(e)}))
