from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from datetime import datetime
import requests

class DashboardDataView(APIView):
    def get(self, request):
        # 1. Choose city/country (e.g., London, UK as in your layout screen)
        # For Lahore: city="Lahore", country="Pakistan"
        city = "Lahore"
        country = "Pakistan"
        
        # 2. Fetch live astronomical data from free AlAdhan API
        api_url = f"https://api.aladhan.com/v1/timingsByCity?city={city}&country={country}&method=3"
        
        try:
            response = requests.get(api_url).json()
            timings = response['data']['timings']
            hijri = response['data']['date']['hijri']
            hijri_date_str = f"{hijri['day']} {hijri['month']['en']} {hijri['year']} AH"
        except Exception:
            # Fallback if external network request drops during development
            timings = {"Fajr": "04:42", "Dhuhr": "12:15", "Asr": "15:30", "Maghrib": "18:20", "Isha": "19:45"}
            hijri_date_str = "16 Ramadan 1447"

        # 3. Clean up times (API returns "HH:MM", we map it to 12-hour strings)
        def to_12h(time_str):
            return datetime.strptime(time_str.split()[0], "%H:%M").strftime("%I:%M %p")

        prayer_keys = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
        now = datetime.now()
        current_time_str = now.strftime("%I:%M %p")
        
        # 4. Compare current system time against calculated slots
        prayers_status = {}
        next_prayer_name = "Fajr"
        next_prayer_time = to_12h(timings["Fajr"])
        found_next = False

        for key in prayer_keys:
            p_time = datetime.strptime(timings[key].split()[0], "%H:%M").replace(year=now.year, month=now.month, day=now.day)
            is_past = now > p_time
            prayers_status[key.lower()] = is_past
            
            if not is_past and not found_next:
                next_prayer_name = key
                next_prayer_time = to_12h(timings[key])
                found_next = True

        # 5. Package clean payload data back to Flutter
        data = {
            "username": "Sarah Ahmed",
            "hijri_date": hijri_date_str,
            "current_time": current_time_str,
            "next_prayer": next_prayer_name,
            "prayer_time": next_prayer_time,
            "prayers_status": prayers_status,
            "prayer_list_times": {k.lower(): to_12h(timings[k]) for k in prayer_keys},
            "dhikr_streak": 14
        }
        return Response(data, status=status.HTTP_200_OK)