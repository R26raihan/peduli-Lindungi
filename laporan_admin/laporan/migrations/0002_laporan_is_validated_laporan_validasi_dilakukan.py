# Generated by Django 5.1.3 on 2025-01-20 08:01

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("laporan", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="laporan",
            name="is_validated",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="laporan",
            name="validasi_dilakukan",
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
