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
    path('delete-invoice/<str:invoice_id>/', views.DeleteInvoiceView.as_view(), name='delete-invoice'),
    path('delete-product/<str:product_id>/', views.DeleteProductView.as_view(), name='delete-product'),
    path('today-stats/<str:shop_id>/', views.TodayStatsView.as_view(), name='today-stats'),
    path('today-invoices/<str:shop_id>/', views.TodayInvoicesView.as_view(), name='today-invoices'),

    path('shop-users/<str:shop_id>/', views.ShopUsersView.as_view(), name='shop-users'),
    path('delete-user/<str:user_id>/', views.DeleteUserView.as_view(), name='delete-user'),
    path('public-invoice/', views.PublicInvoiceView.as_view(), name='public-invoice'),
    
    # Email verification
    path('verify-email/', views.VerifyEmailView.as_view(), name='verify-email'),
    
    # Premium shop features
    path('premium/status/<str:shop_id>/', views.PremiumStatusView.as_view(), name='premium-status'),
    path('premium/subscribe/', views.PremiumSubscribeView.as_view(), name='premium-subscribe'),
    path('premium/recharge-history/<str:shop_id>/', views.RechargeHistoryView.as_view(), name='recharge-history'),
    
    # Branch management
    path('branches/<str:shop_id>/', views.BranchesView.as_view(), name='branches'),
    path('branches/create/', views.CreateBranchView.as_view(), name='create-branch'),
    path('branches/<str:branch_id>/', views.BranchDetailView.as_view(), name='branch-detail'),
    path('branches/assign-user/', views.AssignUserToBranchView.as_view(), name='assign-user-to-branch'),
    
    # Returned products
    path('products/return/', views.ReturnProductView.as_view(), name='return-product'),
    path('products/returned/<str:shop_id>/', views.ReturnedProductsView.as_view(), name='returned-products'),
    
    # Premium analytics
    path('premium/analytics/sales/<str:shop_id>/', views.PremiumSalesAnalyticsView.as_view(), name='premium-sales-analytics'),
    path('premium/analytics/products/<str:shop_id>/', views.ProductProfitAnalyticsView.as_view(), name='product-profit-analytics'),
    
    # Shop settings & profile
    path('shop/settings/<str:shop_id>/', views.ShopSettingsView.as_view(), name='shop-settings'),
    path('shop/upload-logo/<str:shop_id>/', views.UploadShopLogoView.as_view(), name='upload-shop-logo'),
]