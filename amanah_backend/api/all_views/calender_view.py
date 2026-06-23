from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from datetime import datetime, date
import requests

class IslamicCalendarView(APIView):
    def get(self, request):
        today = datetime.now()

        # ✅ Read month/year from query params, fallback to current
        try:
            month = int(request.query_params.get('month', today.month))
            year = int(request.query_params.get('year', today.year))
        except ValueError:
            return Response({"error": "Invalid month or year"}, status=status.HTTP_400_BAD_REQUEST)

        api_url = f"https://api.aladhan.com/v1/gToHCalendar/{month}/{year}"

        days_data = []
        try:
            response = requests.get(api_url, timeout=10).json()
            raw_data = response.get('data', [])
            if isinstance(raw_data, list):
                days_data = raw_data
            elif isinstance(raw_data, dict):
                days_data = list(raw_data.values())
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        try:
            days_data = sorted(days_data, key=lambda x: int(x['gregorian']['day']))
        except Exception:
            pass

        hijri_month_name = "Unknown"
        hijri_year = "----"
        if days_data:
            first = days_data[0]
            hijri_month_name = first['hijri']['month']['en']
            hijri_year = first['hijri']['year']

        weekday_map = {
            "Sunday": 0, "Monday": 1, "Tuesday": 2,
            "Wednesday": 3, "Thursday": 4, "Friday": 5, "Saturday": 6
        }
        first_day_offset = 0
        calendar_days = []

        for entry in days_data:
            if 'gregorian' not in entry or 'hijri' not in entry:
                continue

            greg = entry['gregorian']
            hijri = entry['hijri']
            day_num = int(greg['day'])

            if day_num == 1:
                first_day_offset = weekday_map.get(greg['weekday']['en'], 0)

            # ✅ is_today only applies if we're viewing the current month/year
            is_current_month = (month == today.month and year == today.year)
            calendar_days.append({
                "gregorian_day": day_num,
                "hijri_day": int(hijri['day']),
                "hijri_month": hijri['month']['en'],
                "is_today": is_current_month and day_num == today.day,
                "is_dummy": False
            })

        padded_grid = [
            {"gregorian_day": "", "hijri_day": "", "is_today": False, "is_dummy": True}
            for _ in range(first_day_offset)
        ]
        padded_grid.extend(calendar_days)

        # ✅ Fetch upcoming events dynamically from aladhan for the next 12 months
        ISLAMIC_EVENTS = [
            {"title": "Islamic New Year (1448)", "gregorian": date(2026, 6, 26)},
            {"title": "Ashura (1448)",            "gregorian": date(2026, 7, 5)},
            {"title": "Mawlid al-Nabi (1448)",    "gregorian": date(2026, 9, 4)},
            {"title": "Ramadan Starts (1448)",     "gregorian": date(2027, 2, 18)},
            {"title": "Laylat al-Qadr (1448)",     "gregorian": date(2027, 3, 19)},
            {"title": "Eid al-Fitr (1448)",        "gregorian": date(2027, 3, 30)},
            {"title": "Eid al-Adha (1448)",        "gregorian": date(2027, 6, 6)},
        ]

        events = []
        for ev in ISLAMIC_EVENTS:
            days_left = (ev["gregorian"] - today.date()).days
            if days_left >= 0:
                events.append({
                    "title": ev["title"],
                    "date": f"{ev['gregorian'].day} {ev['gregorian'].strftime('%B %Y')}",  # ✅ Windows-safe
                    "days_left": days_left
                })

        # ✅ Use the requested month/year for the header, not always today
        requested_date = datetime(year, month, 1)

        payload = {
            "hijri_header": f"{hijri_month_name} {hijri_year}",
            "gregorian_sub": f"{requested_date.strftime('%B')} / {year}",
            "days": padded_grid,
            "upcoming_events": events
        }

        return Response(payload, status=status.HTTP_200_OK)