# laporan_admin/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Laporan
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

@receiver(post_save, sender=Laporan)
def send_laporan_validation_notification(sender, instance, created, **kwargs):
    # Kirim pesan ke WebSocket jika laporan sudah divalidasi
    if not created and instance.is_validated:
        channel_layer = get_channel_layer()
        message = f"Laporan dengan ID {instance.id} telah divalidasi."
        async_to_sync(channel_layer.group_send)(
            'laporan_notifications',
            {
                'type': 'laporan_message',
                'message': message
            }
        )
