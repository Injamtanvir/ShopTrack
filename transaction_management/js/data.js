// Data Management Functions

// Save transaction to local storage
function saveTransaction(transaction) {
    // Generate a unique ID for the transaction
    transaction.id = generateTransactionId();
    
    // Add timestamp for sorting
    transaction.timestamp = new Date().getTime();
    
    // Get existing transactions
    const transactions = getTransactions();
    
    // Add new transaction
    transactions.push(transaction);
    
    // Save back to localStorage
    localStorage.setItem('transactions', JSON.stringify(transactions));
    
    // Update the app state
    window.appState.transactions = transactions;
    
    return transaction;
}

// Get all transactions from localStorage
function getTransactions() {
    const transactionsJSON = localStorage.getItem('transactions');
    if (transactionsJSON) {
        return JSON.parse(transactionsJSON);
    }
    return [];
}

// Delete a transaction
function deleteTransaction(transactionId) {
    let transactions = getTransactions();
    
    // Filter out the transaction to delete
    transactions = transactions.filter(t => t.id !== transactionId);
    
    // Save back to localStorage
    localStorage.setItem('transactions', JSON.stringify(transactions));
    
    // Update the app state
    window.appState.transactions = transactions;
    
    return true;
}

// Update a transaction
function updateTransaction(updatedTransaction) {
    let transactions = getTransactions();
    
    // Find the transaction to update
    const index = transactions.findIndex(t => t.id === updatedTransaction.id);
    
    if (index !== -1) {
        // Replace the transaction with the updated one
        transactions[index] = updatedTransaction;
        
        // Save back to localStorage
        localStorage.setItem('transactions', JSON.stringify(transactions));
        
        // Update the app state
        window.appState.transactions = transactions;
        
        return true;
    }
    
    return false;
}

// Get a transaction by ID
function getTransactionById(transactionId) {
    const transactions = getTransactions();
    return transactions.find(t => t.id === transactionId);
}

// Generate a unique transaction ID
function generateTransactionId() {
    return 'txn_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
}

// Filter transactions by various criteria
function filterTransactions(options = {}) {
    let transactions = getTransactions();
    
    // Filter by transaction type (income/expense)
    if (options.type && options.type !== 'all') {
        transactions = transactions.filter(t => t.type === options.type);
    }
    
    // Filter by category
    if (options.category && options.category !== 'all') {
        transactions = transactions.filter(t => t.category === options.category);
    }
    
    // Filter by status
    if (options.status && options.status !== 'all') {
        transactions = transactions.filter(t => t.status === options.status);
    }
    
    // Filter by date range
    if (options.startDate) {
        const startDate = new Date(options.startDate);
        startDate.setHours(0, 0, 0, 0);
        transactions = transactions.filter(t => new Date(t.date) >= startDate);
    }
    
    if (options.endDate) {
        const endDate = new Date(options.endDate);
        endDate.setHours(23, 59, 59, 999);
        transactions = transactions.filter(t => new Date(t.date) <= endDate);
    }
    
    // Filter by search term (searches in description)
    if (options.searchTerm) {
        const term = options.searchTerm.toLowerCase();
        transactions = transactions.filter(t => 
            t.description.toLowerCase().includes(term) || 
            t.category.toLowerCase().includes(term) ||
            (t.notes && t.notes.toLowerCase().includes(term))
        );
    }
    
    // Sort transactions by date (newest first)
    transactions.sort((a, b) => new Date(b.date) - new Date(a.date));
    
    return transactions;
}

// Get transactions for a specific date range
function getTransactionsForDateRange(startDate, endDate) {
    return filterTransactions({ startDate, endDate });
}

// Get transactions for the current month
function getTransactionsForCurrentMonth() {
    const now = new Date();
    const startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    const endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    
    return getTransactionsForDateRange(startDate, endDate);
}

// Calculate total income for a set of transactions
function calculateTotalIncome(transactions) {
    return transactions
        .filter(t => t.type === 'income' && t.status === 'completed')
        .reduce((total, t) => total + parseFloat(t.amount), 0);
}

// Calculate total expenses for a set of transactions
function calculateTotalExpenses(transactions) {
    return transactions
        .filter(t => t.type === 'expense' && t.status === 'completed')
        .reduce((total, t) => total + parseFloat(t.amount), 0);
}

// Calculate net balance (income - expenses)
function calculateNetBalance(transactions) {
    const income = calculateTotalIncome(transactions);
    const expenses = calculateTotalExpenses(transactions);
    return income - expenses;
}

// Get transaction count
function getTransactionCount(transactions) {
    return transactions.length;
}

// Category Management

// Save categories to localStorage
function saveCategories(categories) {
    localStorage.setItem('categories', JSON.stringify(categories));
    window.appState.categories = categories;
}

// Get categories from localStorage
function getCategories() {
    const categoriesJSON = localStorage.getItem('categories');
    if (categoriesJSON) {
        return JSON.parse(categoriesJSON);
    }
    return {
        income: ['Sales', 'Investments', 'Other Income'],
        expense: ['Inventory', 'Utilities', 'Rent', 'Salaries', 'Marketing', 'Supplies', 'Other Expense']
    };
}

// Add a new category
function addCategory(type, categoryName) {
    if (!categoryName) {
        if (type === 'income') {
            categoryName = document.getElementById('new-income-category').value.trim();
        } else {
            categoryName = document.getElementById('new-expense-category').value.trim();
        }
    }
    
    if (!categoryName) {
        alert('Please enter a category name');
        return false;
    }
    
    const categories = getCategories();
    
    // Check if category already exists
    if (categories[type].includes(categoryName)) {
        alert('This category already exists');
        return false;
    }
    
    // Add new category
    categories[type].push(categoryName);
    
    // Save categories
    saveCategories(categories);
    
    // Clear the input
    if (type === 'income') {
        document.getElementById('new-income-category').value = '';
    } else {
        document.getElementById('new-expense-category').value = '';
    }
    
    // Refresh the category lists
    loadCategories();
    
    return true;
}

// Delete a category
function deleteCategory(type, categoryName) {
    const categories = getCategories();
    
    // Filter out the category to delete
    categories[type] = categories[type].filter(c => c !== categoryName);
    
    // Save categories
    saveCategories(categories);
    
    // Refresh the category lists
    loadCategories();
    
    return true;
}

// Settings Management

// Save user settings
function saveUserSettings() {
    const settings = {
        theme: document.body.classList.contains('dark-theme') ? 'dark' : 
               document.body.classList.contains('blue-theme') ? 'blue' : 'light',
        currency: document.getElementById('currency-symbol').value,
        decimalPlaces: document.getElementById('decimal-places').value
    };
    
    localStorage.setItem('userSettings', JSON.stringify(settings));
    
    showToast('Settings saved successfully!');
    
    return true;
}

// Reset user settings to default
function resetUserSettings() {
    // Default settings
    const defaultSettings = {
        theme: 'light',
        currency: '৳',
        decimalPlaces: '2'
    };
    
    // Apply default settings
    document.getElementById('currency-symbol').value = defaultSettings.currency;
    document.getElementById('decimal-places').value = defaultSettings.decimalPlaces;
    applyTheme(defaultSettings.theme);
    
    // Save default settings
    localStorage.setItem('userSettings', JSON.stringify(defaultSettings));
    
    showToast('Settings reset to default!');
    
    return true;
}

// Data Export/Import

// Export all data to a JSON file
function exportAllData() {
    const exportData = {
        transactions: getTransactions(),
        categories: getCategories(),
        settings: JSON.parse(localStorage.getItem('userSettings') || '{}'),
        exportDate: new Date().toISOString()
    };
    
    const dataStr = JSON.stringify(exportData, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(dataStr);
    
    const exportFileName = `shoptrack_export_${new Date().toISOString().slice(0, 10)}.json`;
    
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', exportFileName);
    linkElement.click();
    
    showToast('Data exported successfully!');
    
    return true;
}

// Import data from a JSON file
function importDataFromFile(event) {
    const file = event.target.files[0];
    
    if (!file) {
        return false;
    }
    
    const reader = new FileReader();
    
    reader.onload = function(e) {
        try {
            const importedData = JSON.parse(e.target.result);
            
            // Confirm import
            if (confirm('This will replace all your current data. Are you sure you want to continue?')) {
                // Import transactions
                if (importedData.transactions) {
                    localStorage.setItem('transactions', JSON.stringify(importedData.transactions));
                    window.appState.transactions = importedData.transactions;
                }
                
                // Import categories
                if (importedData.categories) {
                    localStorage.setItem('categories', JSON.stringify(importedData.categories));
                    window.appState.categories = importedData.categories;
                }
                
                // Import settings
                if (importedData.settings) {
                    localStorage.setItem('userSettings', JSON.stringify(importedData.settings));
                    
                    // Apply imported settings
                    if (importedData.settings.theme) {
                        applyTheme(importedData.settings.theme);
                    }
                    if (importedData.settings.currency) {
                        document.getElementById('currency-symbol').value = importedData.settings.currency;
                    }
                    if (importedData.settings.decimalPlaces) {
                        document.getElementById('decimal-places').value = importedData.settings.decimalPlaces;
                    }
                }
                
                // Refresh the UI
                refreshDashboard();
                loadTransactions();
                loadCategories();
                
                showToast('Data imported successfully!');
            }
        } catch (error) {
            alert('Error importing data: ' + error.message);
        }
    };
    
    reader.readAsText(file);
    
    // Reset the file input
    event.target.value = '';
    
    return true;
}

// Clear all data
function clearAllData() {
    if (confirm('This will permanently delete all your data. This action cannot be undone. Are you sure you want to continue?')) {
        localStorage.removeItem('transactions');
        localStorage.removeItem('categories');
        localStorage.removeItem('userSettings');
        
        // Reset app state
        window.appState.transactions = [];
        window.appState.categories = {
            income: ['Sales', 'Investments', 'Other Income'],
            expense: ['Inventory', 'Utilities', 'Rent', 'Salaries', 'Marketing', 'Supplies', 'Other Expense']
        };
        
        // Refresh the UI
        refreshDashboard();
        loadTransactions();
        loadCategories();
        
        // Reset settings
        resetUserSettings();
        
        showToast('All data has been cleared!');
        
        return true;
    }
    
    return false;
}

// Helper function to show toast messages
function showToast(message) {
    // Create toast element if it doesn't exist
    let toast = document.getElementById('toast');
    
    if (!toast) {
        toast = document.createElement('div');
        toast.id = 'toast';
        toast.style.position = 'fixed';
        toast.style.bottom = '20px';
        toast.style.right = '20px';
        toast.style.backgroundColor = 'rgba(0, 0, 0, 0.8)';
        toast.style.color = 'white';
        toast.style.padding = '10px 20px';
        toast.style.borderRadius = '4px';
        toast.style.zIndex = '1000';
        toast.style.transition = 'opacity 0.3s ease';
        document.body.appendChild(toast);
    }
    
    // Set toast message
    toast.textContent = message;
    toast.style.opacity = '1';
    
    // Hide toast after 3 seconds
    setTimeout(() => {
        toast.style.opacity = '0';
    }, 3000);
} 