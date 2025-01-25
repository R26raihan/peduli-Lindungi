from django.apps import AppConfig


class LaporanConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "laporan"


class LaporanAdminConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'laporan_admin'

    def ready(self):
        import signals