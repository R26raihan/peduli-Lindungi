from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import json
import os

# Path ke ChromeDriver
chrome_driver_path = os.path.join("E:\Flutter_project\guardianeye\chromedriver-win64\chromedriver.exe")

# Setup Selenium WebDriver
service = Service(chrome_driver_path)
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(service=service, options=chrome_options)

try:
    # Buka halaman BMKG Gempa Bumi Real-Time
    driver.get("https://www.bmkg.go.id/gempabumi/gempabumi-realtime.bmkg")

    # Tunggu hingga tag <script> dengan ID __NUXT_DATA__ muncul
    wait = WebDriverWait(driver, 10)
    script_element = wait.until(EC.presence_of_element_located((By.XPATH, '//script[@id="__NUXT_DATA__"]')))

    # Ambil konten JSON dari tag <script>
    json_data = script_element.get_attribute("textContent")

    # Parse JSON
    data = json.loads(json_data)

    # Cetak seluruh JSON untuk analisis
    print(json.dumps(data, indent=4))  # Cetak JSON dengan format yang rapi

    # Mengekstrak informasi gempa
    try:
        # Cari data gempa dalam struktur JSON
        gempa_data = data.get("data", {}).get("gempa", [])

        if isinstance(gempa_data, list) and len(gempa_data) > 0:
            for gempa in gempa_data:
                if isinstance(gempa, dict):  # Pastikan setiap item adalah dictionary
                    eventid = gempa.get("eventid")
                    waktu = gempa.get("waktu")
                    lintang = gempa.get("lintang")
                    bujur = gempa.get("bujur")
                    mag = gempa.get("mag")
                    dalam = gempa.get("dalam")
                    area = gempa.get("area", "Lokasi tidak diketahui")  # Ambil nama lokasi langsung

                    print(f"Event ID: {eventid}")
                    print(f"Waktu: {waktu}")
                    print(f"Lintang: {lintang}")
                    print(f"Bujur: {bujur}")
                    print(f"Magnitudo: {mag}")
                    print(f"Kedalaman: {dalam}")
                    print(f"Lokasi: {area}")
                    print("-" * 40)
        else:
            print("Data gempa tidak ditemukan dalam JSON.")

    except Exception as e:
        print(f"Terjadi kesalahan saat mengekstrak data: {e}")

except Exception as e:
    print(f"Terjadi kesalahan: {e}")

finally:
    # Tutup browser
    driver.quit()