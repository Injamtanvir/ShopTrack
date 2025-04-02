from django.urls import path
from . import views

urlpatterns = [
    path('register-shop/', views.ShopRegistrationView.as_view(), name='register-shop'),
    path('login/', views.UserLoginView.as_view(), name='login'),
    path('register-sales-person/', views.SalesPersonRegistrationView.as_view(), name='register-sales-person'),
    path('register-admin/', views.AdminRegistrationView.as_view(), name='register-admin'),
    path('verify-token/', views.VerifyTokenView.as_view(), name='verify-token'),
    path('products/', views.ProductView.as_view(), name='products'),
    path('update-product-price/', views.UpdateProductPriceView.as_view(), name='update-product-price'),
    path('product-price-list/', views.ProductPriceListView.as_view(), name='product-price-list'),
]