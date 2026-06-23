from django.urls import path
from .all_views import IslamicCalendarView
from .views import DashboardDataView

urlpatterns = [
    path('dashboard/', DashboardDataView.as_view(), name='dashboard-data'),
    path('calendar/', IslamicCalendarView.as_view(), name='calendar-data'), # New route
]