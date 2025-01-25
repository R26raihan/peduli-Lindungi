import requests

# URL API
api_url = "https://dibi.bnpb.go.id/baru/get_markers"

# Parameter request
params = {
    "pr": "",
    "kb": "",
    "th": "2025",  # Tahun
    "bl": "",
    "jn": "",
    "lm": "c",     # Parameter filter
    "tg1": "2025-23-01",  # Tanggal mulai
    "tg2": "2025-01-23"   # Tanggal akhir
}

# Ambil data dari API
response = requests.get(api_url, params=params)

# Periksa status response
if response.status_code == 200:
    data = response.json()  # Konversi response ke format JSON
    print("Data berhasil diambil!")
else:
    print(f"Gagal mengambil data. Status code: {response.status_code}")
    exit()

# Tampilkan data bencana
for bencana in data:
    print(f"ID Bencana: {bencana.get('id', 'N/A')}")
    print(f"Jenis Bencana: {bencana.get('jenis_bencana', 'N/A')}")
    print(f"Lokasi: {bencana.get('lokasi', 'N/A')}")
    print(f"Tanggal: {bencana.get('tanggal', 'N/A')}")
    print(f"Deskripsi: {bencana.get('deskripsi', 'N/A')}")
    print("-" * 50)