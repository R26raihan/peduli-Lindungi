from rest_framework import serializers
from .models import Laporan

class LaporanSerializer(serializers.ModelSerializer):
    class Meta:
        model = Laporan
        fields = '__all__'