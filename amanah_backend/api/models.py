from mongoengine import Document, StringField, BooleanField, DateTimeField
import datetime

class UserDashboard(Document):
    user_id = StringField(required=True)
    mood = StringField(default="Neutral")
    fajr_done = BooleanField(default=False)
    dhuhr_done = BooleanField(default=False)
    asr_done = BooleanField(default=False)
    maghrib_done = BooleanField(default=False)
    isha_done = BooleanField(default=False)
    last_updated = DateTimeField(default=datetime.datetime.utcnow)