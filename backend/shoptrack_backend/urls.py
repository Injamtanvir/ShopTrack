from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    # path('test/', test_api, name='test_api'),
]

# Serve uploaded files in development
if settings.DEBUG:
    urlpatterns += static('/uploads/', document_root=settings.BASE_DIR / 'uploads')