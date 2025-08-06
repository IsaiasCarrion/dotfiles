#!/usr/bin/env python3
import os
import datetime
import requests
import json # Necesario para parsear JSON de ipapi.co y OpenWeatherMap

# --- CONFIGURACIÓN ---
# Tu clave de API de OpenWeatherMap (¡REEMPLAZA ESTO!)
OPENWEATHERMAP_API_KEY = "TU_CLAVE_API_OPENWEATHERMAP"
# Archivo de caché para el pronóstico (se mantiene igual)
FORECAST_CACHE_FILE = os.path.dirname(os.path.realpath(__file__)) + "/forecast_owm.json" # Cambiado a .json

# Emojis asociados con el clima (adaptados a las condiciones de OpenWeatherMap)
WEATHER_TYPES = {
    "Clear": ["☀️", "🌙"],
    "Clouds": ["☁️", "☁️"],
    "Rain": ["🌧️", "🌧️"],
    "Drizzle": ["🌧️", "🌧️"],
    "Thunderstorm": ["⛈️", "⛈️"],
    "Snow": ["🌨️", "🌨️"],
    "Mist": ["🌫️", "🌫️"],
    "Smoke": ["🌫️", "🌫️"],
    "Haze": ["🌫️", "🌫️"],
    "Dust": ["🌫️", "🌫️"],
    "Fog": ["🌫️", "🌫️"],
    "Sand": ["🌫️", "🌫️"],
    "Ash": ["🌫️", "🌫️"],
    "Squall": ["💨", "💨"],
    "Tornado": ["🌪️", "🌪️"]
}

# --- FUNCIONES ---

def get_current_city():
    """Obtiene el nombre de la ciudad actual usando la IP pública."""
    try:
        response = requests.get("https://ipapi.co/json/", timeout=5)
        response.raise_for_status() # Lanza un error para códigos de estado HTTP incorrectos
        data = response.json()
        return data.get("city", "Unknown")
    except requests.exceptions.RequestException:
        return "Unknown" # Retorna "Unknown" si hay un error de conexión o timeout

def get_weather_data(city_name):
    """Obtiene los datos del clima de OpenWeatherMap."""
    if city_name == "Unknown":
        # Si la ciudad no se pudo detectar, intenta con una ciudad por defecto
        city_name = "Buenos Aires" # Puedes cambiar esta ciudad por defecto
        
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city_name}&units=metric&appid={OPENWEATHERMAP_API_KEY}"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        weather_data = response.json()
        
        # Guarda la respuesta en caché (ahora es JSON)
        with open(FORECAST_CACHE_FILE, "w") as f:
            json.dump(weather_data, f)
            
        return weather_data
    except requests.exceptions.RequestException as e:
        # Si falla la conexión, intenta usar la caché
        if os.path.isfile(FORECAST_CACHE_FILE):
            print("(♻️)", end=" ") # Indica que se usa la caché
            with open(FORECAST_CACHE_FILE, "r") as f:
                return json.load(f)
        raise RuntimeError(f"No forecast data available: {e}")

def main():
    """Punto de entrada del programa."""
    city = get_current_city()
    
    try:
        weather_data = get_weather_data(city)
    except RuntimeError as e:
        print(f" {e}")
        print("")
        print("#FA1E44")
        return

    # Extraer información del JSON de OpenWeatherMap
    main_weather = weather_data['weather'][0]['main']
    description = weather_data['weather'][0]['description']
    temperature = weather_data['main']['temp']
    
    # Obtener tiempos de amanecer y atardecer (timestamps UNIX)
    sunrise_ts = weather_data['sys']['sunrise']
    sunset_ts = weather_data['sys']['sunset']
    
    # Convertir a objetos datetime
    sunrise_dt = datetime.datetime.fromtimestamp(sunrise_ts)
    sunset_dt = datetime.datetime.fromtimestamp(sunset_ts)

    # Determinar si es de noche
    now = datetime.datetime.now()
    is_night = 0
    if now.time() < sunrise_dt.time() or now.time() > sunset_dt.time():
        is_night = 1

    # Obtener el icono y el color
    icon = WEATHER_TYPES.get(main_weather, ["❓", "❓"])[is_night] # Icono por defecto si no se encuentra
    color = "#FFFFFF" # Color por defecto

    # Imprimir la salida para i3blocks
    # Línea 1: full_text
    print(f"{icon} {temperature:.0f}°C {description.capitalize()}")
    # Línea 2: short_text
    print(icon)
    # Línea 3: color
    print(color)

if __name__ == "__main__":
    main()
