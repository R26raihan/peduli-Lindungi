# Generated by Django 5.1.3 on 2025-01-20 08:11

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("laporan", "0002_laporan_is_validated_laporan_validasi_dilakukan"),
    ]

    operations = [
        migrations.AddField(
            model_name="laporan",
            name="nomor_wa",
            field=models.CharField(blank=True, max_length=15, null=True),
        ),
    ]
