import requests
import json
import xml.etree.ElementTree as ET
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import numpy as np
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

cities = ["Oulu", "Helsinki", "Tampere", "Turku", "Jyväskylä", "Kuopio", "Rovaniemi", "Sanginkylä"]
city_number = 1
for number in cities:
    print(f"{city_number}. " + f"{number}")
    city_number = city_number + 1
finnish_time = ZoneInfo("Europe/Helsinki")
input_city = input("Choose city from list with number or press enter to give city name: ")
if not input_city:
    input_city = input("Enter city name: ")
else:
    input_city = cities[int(input_city ) - 1]
input_mode = input("Press 1 if you want history data, enter if you want forecast: ")
input_date_cnt = input("Enter the amount of days(max 3 in forecast and 7 in history):")
if input_mode == "1":
    input_date = input("Enter the startdate (YYYY-MM-DD): ")
    start_day = datetime.strptime(input_date, "%Y-%m-%d")
    starttime = start_day.strftime("%Y-%m-%dT00:00:00Z")
else:
    input_date = datetime.now().strftime("%Y-%m-%d-%H-%M")
    start_day = datetime.strptime(input_date, "%Y-%m-%d-%H-%M")
    starttime = start_day.strftime("%Y-%m-%dT%H:%M:00Z")
day_cnt = int(input_date_cnt)
end_day = start_day + timedelta(days=day_cnt -1)
#print(start_day)
#print(end_day)
endtime = end_day.strftime("%Y-%m-%dT23:50:00Z")
url_obs = f"http://opendata.fmi.fi/wfs/fin?service=WFS&version=2.0.0&request=getFeature&storedquery_id=fmi::observations::weather::timevaluepair&place={input_city}&parameters=t2m&starttime={starttime}&endtime={endtime}"
url_forecast = f"https://opendata.fmi.fi/wfs/fin?service=WFS&version=2.0.0&request=getFeature&storedquery_id=fmi::forecast::harmonie::surface::point::timevaluepair&place={input_city}&parameters=Temperature&starttime={starttime}&endtime={endtime}"

if input_mode == "1":    
    response = requests.get(url_obs)
else:
    response = requests.get(url_forecast)

root = ET.fromstring(response.text)
namespace = {"wml2": "http://www.opengis.net/waterml/2.0"}

x_hours = []
y_temp_values = []
y_temp_values_last = []

for member in root.findall(".//wml2:value", namespace):
    if member.text == "NaN":
        pass
    else:
        print("Value:", member.text)
        y_temp_values.append(float(member.text))
for member in root.findall(".//wml2:time", namespace):
    print("Time:", member.text)
    x_hours.append(datetime.fromisoformat(member.text.replace("Z", "+00:00")))

x_hours_finland = [time_h.astimezone(finnish_time)
                   for time_h in x_hours]

#y_temp_values_last = y_temp_values[-144:]
#print(x_hours[0])
plt.plot(x_hours_finland, y_temp_values)
plt.xlabel("Time")
plt.ylabel("Temperature (°C)")
plt.title(f"Weather Data for {input_city} on {start_day.strftime("%Y-%m-%d")} - {end_day.strftime("%Y-%m-%d")}")
ax = plt.gca()
ax.xaxis.set_major_locator(mdates.HourLocator(interval=3, tz=finnish_time))
ax.xaxis.set_major_formatter(mdates.DateFormatter("%H:%M"))
ax.set_xlim(x_hours_finland[0], x_hours_finland[0] + timedelta(days=day_cnt))
ax.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
