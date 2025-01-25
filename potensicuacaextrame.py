import json
from bs4 import BeautifulSoup
import requests

# URL halaman web
url = "https://www.bmkg.go.id/cuaca/potensi-cuaca-ekstrem"

# Mengambil konten HTML dari halaman web
response = requests.get(url)
html_content = response.text

# Parsing HTML menggunakan BeautifulSoup
soup = BeautifulSoup(html_content, 'html.parser')

# Mencari script dengan id "__NUXT_DATA__"
script_tag = soup.find('script', {'id': '__NUXT_DATA__'})

# Mengekstrak data JSON dari script
if script_tag:
    json_data = script_tag.string
    data = json.loads(json_data)

    # Menampilkan data yang telah diekstrak
    print("Data JSON yang diekstrak:")
    print(json.dumps(data, indent=4))

    # Mengekstrak judul peringatan dini
    try:
        judul = data[5]  # Judul berada di indeks 5
        print(f"\nJudul Peringatan Dini: {judul}")
    except IndexError as e:
        print(f"\nError: Judul tidak ditemukan dalam data JSON. {e}")

    # Mengekstrak tanggal peringatan dini
    try:
        tanggal_d1 = data[6]  # Tanggal D1 berada di indeks 6
        print(f"\nTanggal D1: {tanggal_d1}")
    except IndexError as e:
        print(f"\nError: Tanggal D1 tidak ditemukan dalam data JSON. {e}")

    # Mengekstrak daftar nama daerah potensi
    try:
        lokasi_potensi = data[7:28]  # Lokasi potensi berada di indeks 7 hingga 27
        print("\nNama Daerah Potensi:")
        for lokasi in lokasi_potensi:
            if isinstance(lokasi, str):  # Pastikan hanya menampilkan string (nama daerah)
                print(lokasi)
    except IndexError as e:
        print(f"\nError: Daftar lokasi potensi tidak ditemukan dalam data JSON. {e}")
else:
    print("Script tag tidak ditemukan.")