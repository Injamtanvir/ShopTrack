// Main Application Entry Point
document.addEventListener('DOMContentLoaded', () => {
    // Initialize the app
    initApp();

    // Set up navigation
    setupNavigation();

    // Set up event listeners
    setupEventListeners();

    // Load initial data
    loadInitialData();
});

// App initialization
function initApp() {
    console.log('Initializing ShopTrack Payment Processor...');
    
    // Set up event listeners
    setupEventListeners();
}

// Navigation setup
function setupNavigation() {
    const navLinks = document.querySelectorAll('nav a');
    
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            
            // Get the target page from data attribute
            const targetPage = link.getAttribute('data-page');
            
            // Remove active class from all nav items
            document.querySelectorAll('nav li').forEach(item => {
                item.classList.remove('active');
            });
            
            // Add active class to clicked nav item
            link.parentElement.classList.add('active');
            
            // Hide all pages
            document.querySelectorAll('.page').forEach(page => {
                page.classList.remove('active');
            });
            
            // Show the target page
            document.getElementById(targetPage).classList.add('active');
            
            // Additional actions for specific pages
            if (targetPage === 'dashboard') {
                refreshDashboard();
            } else if (targetPage === 'transactions') {
                loadTransactions();
            } else if (targetPage === 'reports') {
                // Default report when opening the reports page
                generateReport('income-expense', 'this-month');
            } else if (targetPage === 'settings') {
                loadSettings();
            }
        });
    });
    
    // Handle "View All" links
    document.querySelectorAll('.view-all').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetPage = link.getAttribute('data-page');
            
            // Trigger click on the corresponding nav link
            document.querySelector(`nav a[data-page="${targetPage}"]`).click();
        });
    });
}

// Set up event listeners for various elements
function setupEventListeners() {
    // Transaction form submission
    const transactionForm = document.getElementById('transaction-form');
    if (transactionForm) {
        transactionForm.addEventListener('submit', handleTransactionFormSubmit);
    }
    
    // Transaction type toggle (income/expense)
    const transactionTypeInputs = document.querySelectorAll('input[name="transaction-type"]');
    transactionTypeInputs.forEach(input => {
        input.addEventListener('change', handleTransactionTypeChange);
    });
    
    // Filter date range toggle
    const filterDate = document.getElementById('filter-date');
    if (filterDate) {
        filterDate.addEventListener('change', handleFilterDateChange);
    }
    
    // Apply custom date filter
    const applyDateFilter = document.getElementById('apply-date-filter');
    if (applyDateFilter) {
        applyDateFilter.addEventListener('click', applyCustomDateFilter);
    }
    
    // Search transactions
    const transactionSearch = document.getElementById('transaction-search');
    if (transactionSearch) {
        transactionSearch.addEventListener('input', handleTransactionSearch);
    }
    
    // Generate report button
    const generateReportBtn = document.getElementById('generate-report');
    if (generateReportBtn) {
        generateReportBtn.addEventListener('click', handleGenerateReport);
    }
    
    // Report period change
    const reportPeriod = document.getElementById('report-period');
    if (reportPeriod) {
        reportPeriod.addEventListener('change', handleReportPeriodChange);
    }
    
    // Save settings button
    const saveSettings = document.getElementById('save-settings');
    if (saveSettings) {
        saveSettings.addEventListener('click', saveUserSettings);
    }
    
    // Reset settings button
    const resetSettings = document.getElementById('reset-settings');
    if (resetSettings) {
        resetSettings.addEventListener('click', resetUserSettings);
    }
    
    // Theme options
    const themeOptions = document.querySelectorAll('.theme-option');
    themeOptions.forEach(option => {
        option.addEventListener('click', () => {
            const theme = option.getAttribute('data-theme');
            applyTheme(theme);
        });
    });
    
    // Add income category
    const addIncomeCategory = document.getElementById('add-income-category');
    if (addIncomeCategory) {
        addIncomeCategory.addEventListener('click', () => addCategory('income'));
    }
    
    // Add expense category
    const addExpenseCategory = document.getElementById('add-expense-category');
    if (addExpenseCategory) {
        addExpenseCategory.addEventListener('click', () => addCategory('expense'));
    }
    
    // Export data button
    const exportData = document.getElementById('export-data');
    if (exportData) {
        exportData.addEventListener('click', exportAllData);
    }
    
    // Import data input
    const importData = document.getElementById('import-data');
    if (importData) {
        importData.addEventListener('change', importDataFromFile);
    }
    
    // Clear data button
    const clearData = document.getElementById('clear-data');
    if (clearData) {
        clearData.addEventListener('click', clearAllData);
    }
    
    // Modal close button
    const closeModalBtn = document.querySelector('.close-modal');
    if (closeModalBtn) {
        closeModalBtn.addEventListener('click', closeModal);
    }
    
    // Close modal when clicking outside
    const modalContainer = document.getElementById('modal-container');
    if (modalContainer) {
        modalContainer.addEventListener('click', (e) => {
            if (e.target === modalContainer) {
                closeModal();
            }
        });
    }
    
    // Report download buttons
    const downloadPdf = document.getElementById('download-pdf');
    if (downloadPdf) {
        downloadPdf.addEventListener('click', () => downloadReport('pdf'));
    }
    
    const downloadCsv = document.getElementById('download-csv');
    if (downloadCsv) {
        downloadCsv.addEventListener('click', () => downloadReport('csv'));
    }
    
    const printReport = document.getElementById('print-report');
    if (printReport) {
        printReport.addEventListener('click', printCurrentReport);
    }
    
    // Pagination buttons
    const prevPage = document.getElementById('prev-page');
    if (prevPage) {
        prevPage.addEventListener('click', () => changePage(-1));
    }
    
    const nextPage = document.getElementById('next-page');
    if (nextPage) {
        nextPage.addEventListener('click', () => changePage(1));
    }
}

// Load initial data
function loadInitialData() {
    // Load transactions from localStorage
    loadTransactions();
    
    // Load categories
    loadCategories();
    
    // Refresh dashboard data
    refreshDashboard();
}

// Function to apply theme
function applyTheme(theme) {
    // Remove all theme classes
    document.body.classList.remove('light-theme', 'dark-theme', 'blue-theme');
    
    // Add selected theme class
    document.body.classList.add(`${theme}-theme`);
    
    // Update active state in theme options
    document.querySelectorAll('.theme-option').forEach(option => {
        option.classList.remove('active');
        if (option.getAttribute('data-theme') === theme) {
            option.classList.add('active');
        }
    });
}

// Function to close modals
function closeModal() {
    const modalContainer = document.getElementById('modal-container');
    modalContainer.classList.add('hidden');
}

// Helper function to show a modal with content
function showModal(title, content) {
    const modalTitle = document.getElementById('modal-title');
    const modalContent = document.getElementById('modal-content');
    const modalContainer = document.getElementById('modal-container');
    
    modalTitle.textContent = title;
    modalContent.innerHTML = content;
    modalContainer.classList.remove('hidden');
}

// Handle transaction form submission
async function handleTransactionFormSubmit(e) {
    e.preventDefault();
    
    // Reset any previous results
    document.getElementById('result-container').classList.remove('active');
    
    // Get form values
    const transactionId = document.getElementById('transaction-id').value.trim();
    const amount = parseFloat(document.getElementById('amount').value);
    
    // Basic validation
    if (!transactionId) {
        showResult(false, 'Transaction ID is required.');
        return;
    }
    
    if (isNaN(amount) || amount <= 0) {
        showResult(false, 'Please enter a valid amount greater than zero.');
        return;
    }
    
    // Process the payment
    const result = await processPayment(transactionId, amount);
    
    // Show the result
    showResult(result.success, result.message, result.details);
    
    // Clear form on success
    if (result.success) {
        transactionForm.reset();
    }
}

// Format currency with Bangladeshi Taka symbol
function formatCurrency(amount) {
    return '৳' + parseFloat(amount).toFixed(2);
}

// Add any global variables or objects that will be needed across files
window.appState = {
    currentPage: 1,
    itemsPerPage: 10,
    transactions: [],
    filteredTransactions: [],
    categories: {
        income: ['Sales', 'Investments', 'Other Income'],
        expense: ['Inventory', 'Utilities', 'Rent', 'Salaries', 'Marketing', 'Supplies', 'Other Expense']
    },
    currentReportData: null,
    currentReportType: 'income-expense',
    currentReportPeriod: 'this-month'
}; 