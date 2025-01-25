from celery import shared_task
import requests

@shared_task
def send_notification_to_flutter(laporan):
    # URL endpoint untuk aplikasi Flutter
    flutter_api_url = 'http://your-flutter-app-endpoint.com/notify'

    # Data yang ingin dikirim ke aplikasi Flutter
    data = {
        'message': f"Laporan dengan ID {laporan.id} telah divalidasi!",
        'laporan_id': laporan.id,
        'status': laporan.is_validated,
    }

    # Kirimkan permintaan POST ke aplikasi Flutter
    response = requests.post(flutter_api_url, json=data)
    if response.status_code == 200:
        print("Notifikasi berhasil dikirim ke aplikasi Flutter.")
    else:
        print(f"Gagal mengirim notifikasi. Status Code: {response.status_code}")
