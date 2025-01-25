import requests

# URL data JSON
url = "https://poskobanjir.dsdadki.web.id/datatmalaststatus.json"

# Mengambil data JSON dari URL
response = requests.get(url)
data = response.json()

# Menyaring data yang penting
filtered_data = []
for item in data:
    filtered_item = {
        "NAMA_PINTU_AIR": item.get("NAMA_PINTU_AIR"),
        "LATITUDE": item.get("LATITUDE"),
        "LONGITUDE": item.get("LONGITUDE"),
        "RECORD_STATUS": item.get("RECORD_STATUS"),
        "TINGGI_AIR": item.get("TINGGI_AIR"),
        "TINGGI_AIR_SEBELUMNYA": item.get("TINGGI_AIR_SEBELUMNYA"),
        "TANGGAL": item.get("TANGGAL"),
        "STATUS_SIAGA": item.get("STATUS_SIAGA")
    }
    filtered_data.append(filtered_item)

# Menampilkan hasil
for item in filtered_data:
    print(item)