# from django.urls import path
# from . import views
# from .db import NextInvoiceNumberView  # Add this import

# urlpatterns = [
#     path('register-shop/', views.ShopRegistrationView.as_view(), name='register-shop'),
#     path('login/', views.UserLoginView.as_view(), name='login'),
#     path('register-sales-person/', views.SalesPersonRegistrationView.as_view(), name='register-sales-person'),
#     path('register-admin/', views.AdminRegistrationView.as_view(), name='register-admin'),
#     path('verify-token/', views.VerifyTokenView.as_view(), name='verify-token'),
#     path('products/', views.ProductView.as_view(), name='products'),
#     path('update-product-price/', views.UpdateProductPriceView.as_view(), name='update-product-price'),
#     path('product-price-list/', views.ProductPriceListView.as_view(), name='product-price-list'),
    
#     path('next-invoice-number/<str:shop_id>/', views.NextInvoiceNumberView.as_view(), name='next-invoice-number'),
#     path('invoices/', views.SaveInvoiceView.as_view(), name='save-invoice'),
#     path('generate-invoice/<str:invoice_id>/', views.GenerateInvoiceView.as_view(), name='generate-invoice'),
#     path('pending-invoices/<str:shop_id>/', views.PendingInvoicesView.as_view(), name='pending-invoices'),
#     path('invoice-history/<str:shop_id>/', views.InvoiceHistoryView.as_view(), name='invoice-history'),
#     path('invoice/<str:invoice_id>/', views.InvoiceDetailView.as_view(), name='invoice-detail'),
#     path('search-products/<str:shop_id>/', views.SearchProductsView.as_view(), name='search-products'),

#     path('next-invoice-number/<str:shop_id>/', NextInvoiceNumberView.as_view(), name='next-invoice-number'),
# ]





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
    path('register-shop/', views.ShopRegistrationView.as_view(), name='register-shop'),
    path('login/', views.UserLoginView.as_view(), name='login'),
    path('register-sales-person/', views.SalesPersonRegistrationView.as_view(), name='register-sales-person'),
    path('register-admin/', views.AdminRegistrationView.as_view(), name='register-admin'),
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
]