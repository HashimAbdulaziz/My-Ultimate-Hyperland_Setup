#!/usr/bin/env python3
import urllib.request
import json
import datetime

# Configuration
CITY = "Cairo"
COUNTRY = "Egypt"
METHOD = 5 # Egyptian General Authority of Survey

url = f"http://api.aladhan.com/v1/timingsByCity?city={CITY}&country={COUNTRY}&method={METHOD}"

try:
    # Fetch data from the API
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
    
    timings = data['data']['timings']
    
    # We only want the 5 obligatory prayers
    prayers = {
        'Fajr': timings['Fajr'], 
        'Dhuhr': timings['Dhuhr'], 
        'Asr': timings['Asr'], 
        'Maghrib': timings['Maghrib'], 
        'Isha': timings['Isha']
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
        diff = prayer_time - now
        next_prayer = 'Fajr'
        next_prayer_time_str = clean_time
        
    # Format the remaining time
    hours, remainder = divmod(int(diff.total_seconds()), 3600)
    minutes, _ = divmod(remainder, 60)
    
    # Create the output for Waybar (Now includes the actual time!)
    text = f"🕌 {next_prayer} {next_prayer_time_str} ({hours}h {minutes}m)"
    
    # Create a nice tooltip showing all prayer times for the day
    tooltip = "Daily Salah Times:\n" + "\n".join([f"{k}: {v.split(' ')[0]}" for k, v in prayers.items()])
    
    print(json.dumps({"text": text, "tooltip": tooltip, "class": next_prayer.lower()}))
    
except Exception as e:
    print(json.dumps({"text": "🕌 API Error", "tooltip": str(e)}))
