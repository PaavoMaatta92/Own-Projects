import requests
import time
import math


x0 = float(25.472099)
y0 = float(65.013785)
radius = int(13)
state = False
previousCallSigns = []
previousPlaneAngle = []

while(True):
    url = "https://opensky-network.org/api/states/all"
    response = requests.get(url, timeout=15, headers={"User-Agent": "AirTraffic/1.0"})
    response.raise_for_status()
    data = response.json()
    kutsutunnus = None
    call_signs = []
    plane_angle = []
    for kone in data.get("states", []):
        if kone[2] == "Finland":
            icao, kutsutunnus, maa = kone[0], kone[1], kone[2]
            lon, lat, korkeus = kone[5], kone[6], kone[7]
            location = requests.get("https://nominatim.openstreetmap.org/reverse",
                params={
                    "lat": lat,
                    "lon": lon,
                    "format": "jsonv2",
                    "zoom": 10,          # noin kaupunki-/kuntataso
                    "accept-language": "fi"
                },
                headers={"User-Agent": "oma-lentoseuranta/1.0"},
                timeout=10)
            time.sleep(1.1)

            location_data = location.json()
            try:
                location_name = location_data["display_name"].split(",")[0]
            except:
                KeyError
                continue

            try:
                
                distanceFromOuluDegLon = pow((float(lon)-x0), 2)
                distanceFromOuluDegLat = pow((float(lat)-y0), 2)
                distanceFromOuluDegLatKm = math.sqrt(distanceFromOuluDegLat) * float(111)
                distanceFromOuluDegLonKm = math.sqrt(distanceFromOuluDegLon) * (float(111) * math.cos(math.radians(lat)))
                total_distance = math.sqrt(pow(distanceFromOuluDegLatKm, 2) + pow(distanceFromOuluDegLonKm, 2))
                
                if total_distance <= 600:

                    planeAngleToOulu = math.degrees(math.atan2(distanceFromOuluDegLatKm, distanceFromOuluDegLonKm))
                    print(planeAngleToOulu)
                    if kutsutunnus in call_signs:
                        continue
                    elif kutsutunnus not in call_signs:
                        call_signs.append(kutsutunnus)

                    if kutsutunnus in plane_angle:
                        continue
                    elif kutsutunnus not in plane_angle:
                        plane_angle.append({"kutsutunnus": kutsutunnus, "kulma": planeAngleToOulu})
                    print(f"Plane {kutsutunnus} in {location_name}, distance from Oulu {int(total_distance)} km, in height {korkeus}m")
                        
                else:
                    continue
                                            

                    #print(f"Plane {kutsutunnus} in {location_name}, distance from Oulu {int(total_distance)} km, in height {korkeus}m")
            except:
                TypeError
                continue

        else:
            continue
        #print(icao, kutsutunnus, maa, location_name, korkeus)
    if not previousCallSigns:
        previousCallSigns = call_signs
    else:
        if previousCallSigns != call_signs:
            left_signs = set(previousCallSigns) - set(call_signs)
            arrived_signs = set(call_signs) - set(previousCallSigns)
            if len(left_signs) > 0:
                print(f"Plane {left_signs} left the radius")
            if len(arrived_signs) > 0:
                print(f"Plane {arrived_signs} arrived in the radius")
        previousCallSigns = call_signs
    time.sleep(30)
