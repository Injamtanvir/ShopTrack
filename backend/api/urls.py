from django.urls import path
from . import views
from .db import (
    NextInvoiceNumberView,
    SaveInvoiceView,
    GenerateInvoiceView,
    PendingInvoicesView,
    InvoiceHistoryView,
    InvoiceDetailView,
    SearchProductsView
)


urlpatterns = [
    path('test/', views.test_api_view, name='test_api'),  # Note the corrected function name
    path('register-shop/', views.ShopRegistrationView.as_view(), name='register-shop'),
    path('login/', views.UserLoginView.as_view(), name='login'),
    path('register-sales-person/', views.SalesPersonRegistrationView.as_view(), name='register-sales-person'),
    path('register-manager/', views.AdminRegistrationView.as_view(), name='register-manager'),
    path('verify-token/', views.VerifyTokenView.as_view(), name='verify-token'),
    path('products/', views.ProductView.as_view(), name='products'),
    path('update-product-price/', views.UpdateProductPriceView.as_view(), name='update-product-price'),
    path('product-price-list/', views.ProductPriceListView.as_view(), name='product-price-list'),
    path('next-invoice-number/<str:shop_id>/', NextInvoiceNumberView.as_view(), name='next-invoice-number'),
    path('invoices/', SaveInvoiceView.as_view(), name='save-invoice'),
    path('generate-invoice/<str:invoice_id>/', GenerateInvoiceView.as_view(), name='generate-invoice'),
    path('pending-invoices/<str:shop_id>/', PendingInvoicesView.as_view(), name='pending-invoices'),
    path('invoice-history/<str:shop_id>/', InvoiceHistoryView.as_view(), name='invoice-history'),
    path('invoice/<str:invoice_id>/', InvoiceDetailView.as_view(), name='invoice-detail'),
    path('search-products/<str:shop_id>/', SearchProductsView.as_view(), name='search-products'),
    path('delete-invoice/<str:invoice_id>/', views.DeleteInvoiceView.as_view(), name='delete-invoice'),
    path('delete-product/<str:product_id>/', views.DeleteProductView.as_view(), name='delete-product'),
    path('today-stats/<str:shop_id>/', views.TodayStatsView.as_view(), name='today-stats'),
    path('today-invoices/<str:shop_id>/', views.TodayInvoicesView.as_view(), name='today-invoices'),
    path('shop-users/', views.ShopUsersView.as_view(), name='shop-users'),
    path('delete-user/<str:user_id>/', views.DeleteUserView.as_view(), name='delete-user'),
    path('users/<str:user_id>/info/', views.UserInfoView.as_view(), name='user-info'),
    path('shops/<str:shop_id>/', views.ShopInfoView.as_view(), name='shop-info'),
    path('upload-image/', views.ImageUploadView.as_view(), name='upload-image'),
    
    # New batch management endpoints
    path('batches/', views.BatchView.as_view(), name='batches'),
    path('batches/<str:product_id>/', views.BatchView.as_view(), name='product-batches'),
    path('price-history/<str:product_id>/', views.PriceHistoryView.as_view(), name='price-history'),
    path('profit-report/<str:shop_id>/', views.ProfitReportView.as_view(), name='profit-report'),
]