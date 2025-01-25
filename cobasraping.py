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
    # Buka halaman BMKG
    driver.get("https://www.bmkg.go.id/gempabumi/gempabumi-terkini.bmkg")

    # Tunggu hingga tag <script> dengan ID __NUXT_DATA__ muncul
    wait = WebDriverWait(driver, 10)
    script_element = wait.until(EC.presence_of_element_located((By.XPATH, '//script[@id="__NUXT_DATA__"]')))

    # Ambil konten JSON dari tag <script>
    json_data = script_element.get_attribute("textContent")

    # Parse JSON
    data = json.loads(json_data)

    # Mengekstrak informasi gempa
    try:
        # Tanggal dan Waktu
        tanggal_waktu = data[6]
        print(f"Tanggal dan Waktu: {tanggal_waktu}")

        # Lokasi
        lokasi = data[25]
        print(f"Lokasi: {lokasi}")

        # Magnitudo
        magnitudo = data[26]
        print(f"Magnitudo: {magnitudo}")

        # Kedalaman
        kedalaman = data[27]
        print(f"Kedalaman: {kedalaman}")

        # Koordinat
        koordinat_lintang = data[23]
        koordinat_bujur = data[24]
        print(f"Koordinat: {koordinat_lintang}, {koordinat_bujur}")

        # Deskripsi
        deskripsi = data[28]
        print(f"Deskripsi: {deskripsi}")

        # Instruksi
        instruksi = data[30]
        print(f"Instruksi: {instruksi}")

    except Exception as e:
        print(f"Terjadi kesalahan saat mengekstrak data: {e}")

except Exception as e:
    print(f"Terjadi kesalahan: {e}")

finally:
    # Tutup browser
    driver.quit()