# laporan_admin/consumers.py
import json
from channels.generic.websocket import AsyncWebsocketConsumer

class LaporanConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # Terhubung ke WebSocket
        self.room_group_name = 'laporan_notifications'

        # Bergabung dengan grup
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, close_code):
        # Meninggalkan grup saat koneksi WebSocket terputus
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        # Terima pesan dari WebSocket
        text_data_json = json.loads(text_data)
        message = text_data_json['message']

        # Kirim pesan ke grup
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'laporan_message',
                'message': message
            }
        )

    async def laporan_message(self, event):
        # Kirim pesan ke WebSocket
        message = event['message']
        await self.send(text_data=json.dumps({
            'message': message
        }))
