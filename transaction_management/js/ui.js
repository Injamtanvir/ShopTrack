// UI Management Functions

// Load transactions into the transactions table
function loadTransactions() {
    const transactions = getTransactions();
    window.appState.transactions = transactions;
    window.appState.filteredTransactions = transactions;
    
    // Update to the transactions table
    updateTransactionsTable();
    
    // Also update recent transactions on dashboard
    updateRecentTransactionsTable();
}

// Update the transactions table with current filtered data
function updateTransactionsTable() {
    const tableBody = document.querySelector('#transactions-table tbody');
    if (!tableBody) return;
    
    // Clear the table
    tableBody.innerHTML = '';
    
    // Get current page data
    const startIndex = (window.appState.currentPage - 1) * window.appState.itemsPerPage;
    const endIndex = startIndex + window.appState.itemsPerPage;
    const pageData = window.appState.filteredTransactions.slice(startIndex, endIndex);
    
    if (pageData.length === 0) {
        // No transactions to display
        const emptyRow = document.createElement('tr');
        emptyRow.innerHTML = `<td colspan="6" class="text-center">No transactions found</td>`;
        tableBody.appendChild(emptyRow);
    } else {
        // Add each transaction to the table
        pageData.forEach(transaction => {
            const row = document.createElement('tr');
            
            // Format date
            const date = new Date(transaction.date);
            const formattedDate = date.toLocaleDateString();
            
            // Format amount with appropriate class
            const amountClass = transaction.type === 'income' ? 'income' : 'expense';
            const formattedAmount = transaction.type === 'income' ?
                formatCurrency(transaction.amount) :
                `- ${formatCurrency(transaction.amount)}`;
            
            row.innerHTML = `
                <td>${formattedDate}</td>
                <td>${transaction.description}</td>
                <td>${transaction.category}</td>
                <td class="amount ${amountClass}">${formattedAmount}</td>
                <td><span class="status ${transaction.status}">${transaction.status}</span></td>
                <td class="actions">
                    <button class="action-btn view" data-id="${transaction.id}" title="View Details"><i class="fas fa-eye"></i></button>
                    <button class="action-btn edit" data-id="${transaction.id}" title="Edit"><i class="fas fa-edit"></i></button>
                    <button class="action-btn delete" data-id="${transaction.id}" title="Delete"><i class="fas fa-trash"></i></button>
                </td>
            `;
            
            tableBody.appendChild(row);
        });
    }
    
    // Update pagination controls
    updatePagination();
    
    // Add event listeners to action buttons
    addActionButtonListeners();
}

// Update the recent transactions table on dashboard
function updateRecentTransactionsTable() {
    const tableBody = document.querySelector('#recent-transactions-table tbody');
    if (!tableBody) return;
    
    // Clear the table
    tableBody.innerHTML = '';
    
    // Get 5 most recent transactions
    const recentTransactions = [...window.appState.transactions]
        .sort((a, b) => new Date(b.date) - new Date(a.date))
        .slice(0, 5);
    
    if (recentTransactions.length === 0) {
        // No transactions to display
        const emptyRow = document.createElement('tr');
        emptyRow.innerHTML = `<td colspan="5" class="text-center">No recent transactions</td>`;
        tableBody.appendChild(emptyRow);
    } else {
        // Add each transaction to the table
        recentTransactions.forEach(transaction => {
            const row = document.createElement('tr');
            
            // Format date
            const date = new Date(transaction.date);
            const formattedDate = date.toLocaleDateString();
            
            // Format amount with appropriate class
            const amountClass = transaction.type === 'income' ? 'income' : 'expense';
            const formattedAmount = transaction.type === 'income' ?
                formatCurrency(transaction.amount) :
                `- ${formatCurrency(transaction.amount)}`;
            
            row.innerHTML = `
                <td>${formattedDate}</td>
                <td>${transaction.description}</td>
                <td>${transaction.category}</td>
                <td class="amount ${amountClass}">${formattedAmount}</td>
                <td><span class="status ${transaction.status}">${transaction.status}</span></td>
            `;
            
            tableBody.appendChild(row);
        });
    }
}

// Update pagination controls
function updatePagination() {
    const totalItems = window.appState.filteredTransactions.length;
    const totalPages = Math.ceil(totalItems / window.appState.itemsPerPage);
    
    // Update page info
    document.getElementById('page-info').textContent = `Page ${window.appState.currentPage} of ${totalPages || 1}`;
    
    // Enable/disable previous button
    document.getElementById('prev-page').disabled = window.appState.currentPage <= 1;
    
    // Enable/disable next button
    document.getElementById('next-page').disabled = window.appState.currentPage >= totalPages;
}

// Change page
function changePage(direction) {
    const totalItems = window.appState.filteredTransactions.length;
    const totalPages = Math.ceil(totalItems / window.appState.itemsPerPage);
    
    const newPage = window.appState.currentPage + direction;
    
    if (newPage >= 1 && newPage <= totalPages) {
        window.appState.currentPage = newPage;
        updateTransactionsTable();
    }
}

// Add event listeners to action buttons in the transactions table
function addActionButtonListeners() {
    // View buttons
    document.querySelectorAll('.action-btn.view').forEach(button => {
        button.addEventListener('click', () => {
            const transactionId = button.getAttribute('data-id');
            viewTransactionDetails(transactionId);
        });
    });
    
    // Edit buttons
    document.querySelectorAll('.action-btn.edit').forEach(button => {
        button.addEventListener('click', () => {
            const transactionId = button.getAttribute('data-id');
            editTransaction(transactionId);
        });
    });
    
    // Delete buttons
    document.querySelectorAll('.action-btn.delete').forEach(button => {
        button.addEventListener('click', () => {
            const transactionId = button.getAttribute('data-id');
            if (confirm('Are you sure you want to delete this transaction?')) {
                deleteTransaction(transactionId);
                loadTransactions();
                refreshDashboard();
            }
        });
    });
}

// View transaction details
function viewTransactionDetails(transactionId) {
    const transaction = getTransactionById(transactionId);
    
    if (!transaction) {
        return;
    }
    
    // Format date
    const date = new Date(transaction.date);
    const formattedDate = date.toLocaleDateString();
    
    // Format amount
    const formattedAmount = formatCurrency(transaction.amount);
    
    // Create modal content
    const content = `
        <div class="transaction-details">
            <div class="detail-row">
                <span class="detail-label">Date:</span>
                <span class="detail-value">${formattedDate}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Type:</span>
                <span class="detail-value">${transaction.type === 'income' ? 'Income' : 'Expense'}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Amount:</span>
                <span class="detail-value ${transaction.type}">${formattedAmount}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Description:</span>
                <span class="detail-value">${transaction.description}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Category:</span>
                <span class="detail-value">${transaction.category}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Status:</span>
                <span class="detail-value"><span class="status ${transaction.status}">${transaction.status}</span></span>
            </div>
            ${transaction.notes ? `
            <div class="detail-row">
                <span class="detail-label">Notes:</span>
                <span class="detail-value">${transaction.notes}</span>
            </div>
            ` : ''}
            ${transaction.attachment ? `
            <div class="detail-row">
                <span class="detail-label">Attachment:</span>
                <span class="detail-value"><a href="${transaction.attachment}" target="_blank">View Attachment</a></span>
            </div>
            ` : ''}
            <div class="detail-actions">
                <button class="btn-primary edit-btn" data-id="${transaction.id}">Edit</button>
                <button class="btn-danger delete-btn" data-id="${transaction.id}">Delete</button>
            </div>
        </div>
    `;
    
    // Show the modal
    showModal('Transaction Details', content);
    
    // Add event listeners to buttons in the modal
    document.querySelector('.edit-btn').addEventListener('click', () => {
        closeModal();
        editTransaction(transactionId);
    });
    
    document.querySelector('.delete-btn').addEventListener('click', () => {
        if (confirm('Are you sure you want to delete this transaction?')) {
            deleteTransaction(transactionId);
            closeModal();
            loadTransactions();
            refreshDashboard();
        }
    });
}

// Edit transaction
function editTransaction(transactionId) {
    const transaction = getTransactionById(transactionId);
    
    if (!transaction) {
        return;
    }
    
    // Navigate to the add transaction page
    document.querySelector('nav a[data-page="add-transaction"]').click();
    
    // Fill the form with transaction data
    document.getElementById(transaction.type).checked = true;
    document.getElementById('transaction-date').value = transaction.date;
    document.getElementById('transaction-amount').value = transaction.amount;
    document.getElementById('transaction-description').value = transaction.description;
    document.getElementById('transaction-category').value = transaction.category;
    document.getElementById('transaction-status').value = transaction.status;
    
    if (transaction.notes) {
        document.getElementById('transaction-notes').value = transaction.notes;
    }
    
    // Add transaction ID to the form as a data attribute
    document.getElementById('transaction-form').setAttribute('data-edit-id', transactionId);
    
    // Change the submit button text
    document.querySelector('#transaction-form button[type="submit"]').textContent = 'Update Transaction';
}

// Handle transaction form submission
function handleTransactionFormSubmit(e) {
    e.preventDefault();
    
    // Get form data
    const type = document.querySelector('input[name="transaction-type"]:checked').value;
    const date = document.getElementById('transaction-date').value;
    const amount = document.getElementById('transaction-amount').value;
    const description = document.getElementById('transaction-description').value;
    const category = document.getElementById('transaction-category').value;
    const status = document.getElementById('transaction-status').value;
    const notes = document.getElementById('transaction-notes').value;
    
    // Create transaction object
    const transaction = {
        type,
        date,
        amount: parseFloat(amount),
        description,
        category,
        status,
        notes
    };
    
    // Check if this is an edit or a new transaction
    const transactionId = document.getElementById('transaction-form').getAttribute('data-edit-id');
    
    if (transactionId) {
        // Update existing transaction
        transaction.id = transactionId;
        updateTransaction(transaction);
        
        // Reset form
        document.getElementById('transaction-form').removeAttribute('data-edit-id');
        document.querySelector('#transaction-form button[type="submit"]').textContent = 'Save Transaction';
    } else {
        // Save new transaction
        saveTransaction(transaction);
    }
    
    // Reset form
    document.getElementById('transaction-form').reset();
    
    // Set today's date as default
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('transaction-date').value = today;
    
    // Show success message
    showToast(transactionId ? 'Transaction updated successfully!' : 'Transaction added successfully!');
    
    // Refresh the dashboard
    refreshDashboard();
    
    // Go back to the transactions page
    document.querySelector('nav a[data-page="transactions"]').click();
}

// Handle transaction type change
function handleTransactionTypeChange() {
    const type = document.querySelector('input[name="transaction-type"]:checked').value;
    
    // Show/hide category options based on type
    const incomeCategories = document.getElementById('income-categories');
    const expenseCategories = document.getElementById('expense-categories');
    
    if (type === 'income') {
        incomeCategories.style.display = 'block';
        expenseCategories.style.display = 'none';
    } else {
        incomeCategories.style.display = 'none';
        expenseCategories.style.display = 'block';
    }
}

// Handle filter date change
function handleFilterDateChange() {
    const filterDate = document.getElementById('filter-date').value;
    const customDateRange = document.getElementById('custom-date-range');
    
    if (filterDate === 'custom') {
        customDateRange.classList.remove('hidden');
    } else {
        customDateRange.classList.add('hidden');
        
        // Apply the selected date filter
        applyDateFilter(filterDate);
    }
}

// Apply date filter
function applyDateFilter(filterType) {
    let startDate, endDate;
    const now = new Date();
    
    switch (filterType) {
        case 'today':
            startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
            break;
        case 'this-week':
            const dayOfWeek = now.getDay();
            const diff = now.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1); // Adjust for Sunday
            startDate = new Date(now.setDate(diff));
            startDate.setHours(0, 0, 0, 0);
            endDate = new Date(startDate);
            endDate.setDate(startDate.getDate() + 6);
            endDate.setHours(23, 59, 59, 999);
            break;
        case 'this-month':
            startDate = new Date(now.getFullYear(), now.getMonth(), 1);
            endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
            break;
        case 'this-year':
            startDate = new Date(now.getFullYear(), 0, 1);
            endDate = new Date(now.getFullYear(), 11, 31, 23, 59, 59);
            break;
        case 'all':
        default:
            startDate = null;
            endDate = null;
            break;
    }
    
    // Get filter options
    const filterOptions = getFilterOptions();
    
    // Apply date filter
    if (startDate) filterOptions.startDate = startDate.toISOString().split('T')[0];
    if (endDate) filterOptions.endDate = endDate.toISOString().split('T')[0];
    
    // Filter transactions
    window.appState.filteredTransactions = filterTransactions(filterOptions);
    window.appState.currentPage = 1; // Reset to first page
    
    // Update the table
    updateTransactionsTable();
}

// Apply custom date filter
function applyCustomDateFilter() {
    const startDate = document.getElementById('date-from').value;
    const endDate = document.getElementById('date-to').value;
    
    // Get filter options
    const filterOptions = getFilterOptions();
    
    // Apply date filter
    if (startDate) filterOptions.startDate = startDate;
    if (endDate) filterOptions.endDate = endDate;
    
    // Filter transactions
    window.appState.filteredTransactions = filterTransactions(filterOptions);
    window.appState.currentPage = 1; // Reset to first page
    
    // Update the table
    updateTransactionsTable();
}

// Get current filter options
function getFilterOptions() {
    return {
        type: document.getElementById('filter-type').value,
        category: document.getElementById('filter-category').value,
        searchTerm: document.getElementById('transaction-search').value
    };
}

// Handle transaction search
function handleTransactionSearch() {
    const searchTerm = document.getElementById('transaction-search').value;
    
    // Get filter options
    const filterOptions = getFilterOptions();
    
    // Filter transactions
    window.appState.filteredTransactions = filterTransactions(filterOptions);
    window.appState.currentPage = 1; // Reset to first page
    
    // Update the table
    updateTransactionsTable();
}

// Load categories into the UI
function loadCategories() {
    const categories = getCategories();
    
    // Update income categories list in settings
    const incomeList = document.getElementById('income-categories-list');
    if (incomeList) {
        incomeList.innerHTML = '';
        categories.income.forEach(category => {
            const li = document.createElement('li');
            li.innerHTML = `
                ${category}
                <button class="delete-category" data-type="income" data-category="${category}">
                    <i class="fas fa-times"></i>
                </button>
            `;
            incomeList.appendChild(li);
        });
        
        // Add event listeners to delete buttons
        incomeList.querySelectorAll('.delete-category').forEach(button => {
            button.addEventListener('click', () => {
                const type = button.getAttribute('data-type');
                const category = button.getAttribute('data-category');
                deleteCategory(type, category);
            });
        });
    }
    
    // Update expense categories list in settings
    const expenseList = document.getElementById('expense-categories-list');
    if (expenseList) {
        expenseList.innerHTML = '';
        categories.expense.forEach(category => {
            const li = document.createElement('li');
            li.innerHTML = `
                ${category}
                <button class="delete-category" data-type="expense" data-category="${category}">
                    <i class="fas fa-times"></i>
                </button>
            `;
            expenseList.appendChild(li);
        });
        
        // Add event listeners to delete buttons
        expenseList.querySelectorAll('.delete-category').forEach(button => {
            button.addEventListener('click', () => {
                const type = button.getAttribute('data-type');
                const category = button.getAttribute('data-category');
                deleteCategory(type, category);
            });
        });
    }
    
    // Update category selects in forms
    const incomeCategories = document.getElementById('income-categories');
    if (incomeCategories) {
        incomeCategories.innerHTML = '';
        categories.income.forEach(category => {
            const option = document.createElement('option');
            option.value = category;
            option.textContent = category;
            incomeCategories.appendChild(option);
        });
    }
    
    const expenseCategories = document.getElementById('expense-categories');
    if (expenseCategories) {
        expenseCategories.innerHTML = '';
        categories.expense.forEach(category => {
            const option = document.createElement('option');
            option.value = category;
            option.textContent = category;
            expenseCategories.appendChild(option);
        });
    }
    
    // Update filter categories
    const filterCategory = document.getElementById('filter-category');
    if (filterCategory) {
        // Save current selection
        const currentValue = filterCategory.value;
        
        // Clear options except the first "All Categories" option
        while (filterCategory.options.length > 1) {
            filterCategory.remove(1);
        }
        
        // Add income categories
        const incomeOptgroup = document.createElement('optgroup');
        incomeOptgroup.label = 'Income';
        categories.income.forEach(category => {
            const option = document.createElement('option');
            option.value = category;
            option.textContent = category;
            incomeOptgroup.appendChild(option);
        });
        filterCategory.appendChild(incomeOptgroup);
        
        // Add expense categories
        const expenseOptgroup = document.createElement('optgroup');
        expenseOptgroup.label = 'Expense';
        categories.expense.forEach(category => {
            const option = document.createElement('option');
            option.value = category;
            option.textContent = category;
            expenseOptgroup.appendChild(option);
        });
        filterCategory.appendChild(expenseOptgroup);
        
        // Restore selection if possible
        if (currentValue) {
            filterCategory.value = currentValue;
        }
    }
}

// Refresh dashboard data
function refreshDashboard() {
    // Get current month transactions
    const transactions = getTransactionsForCurrentMonth();
    
    // Calculate totals
    const income = calculateTotalIncome(transactions);
    const expenses = calculateTotalExpenses(transactions);
    const balance = calculateNetBalance(transactions);
    const count = getTransactionCount(transactions);
    
    // Update dashboard stats
    document.getElementById('total-revenue').textContent = formatCurrency(income);
    document.getElementById('total-expenses').textContent = formatCurrency(expenses);
    document.getElementById('total-transactions').textContent = count;
    document.getElementById('net-balance').textContent = formatCurrency(balance);
    
    // Update charts
    updateDashboardCharts(transactions);
    
    // Update recent transactions
    updateRecentTransactionsTable();
}

// Load settings
function loadSettings() {
    // Load categories
    loadCategories();
}

// Handle report period change
function handleReportPeriodChange() {
    const period = document.getElementById('report-period').value;
    const customRange = document.getElementById('report-custom-range');
    
    if (period === 'custom') {
        customRange.classList.remove('hidden');
    } else {
        customRange.classList.add('hidden');
    }
}

// Handle generate report
function handleGenerateReport() {
    const reportType = document.getElementById('report-type').value;
    const period = document.getElementById('report-period').value;
    
    // If custom range is selected, get date range
    let startDate, endDate;
    if (period === 'custom') {
        startDate = document.getElementById('report-date-from').value;
        endDate = document.getElementById('report-date-to').value;
        
        if (!startDate || !endDate) {
            alert('Please select both start and end dates for the custom range');
            return;
        }
    }
    
    // Generate the report
    generateReport(reportType, period, startDate, endDate);
}

// Generate a report
function generateReport(reportType, period, startDate, endDate) {
    // Save current report settings
    window.appState.currentReportType = reportType;
    window.appState.currentReportPeriod = period;
    
    // Get date range based on period
    if (!startDate || !endDate) {
        const range = getDateRangeForPeriod(period);
        startDate = range.startDate;
        endDate = range.endDate;
    }
    
    // Get transactions for the date range
    const transactions = getTransactionsForDateRange(startDate, endDate);
    
    // Generate report based on type
    let reportData;
    let reportTitle;
    
    switch (reportType) {
        case 'income-expense':
            reportTitle = 'Income vs. Expense Report';
            reportData = generateIncomeExpenseReport(transactions, startDate, endDate);
            break;
        case 'category':
            reportTitle = 'Category Analysis Report';
            reportData = generateCategoryReport(transactions, startDate, endDate);
            break;
        case 'monthly-trend':
            reportTitle = 'Monthly Trend Report';
            reportData = generateMonthlyTrendReport(transactions, startDate, endDate);
            break;
        case 'daily-trend':
            reportTitle = 'Daily Trend Report';
            reportData = generateDailyTrendReport(transactions, startDate, endDate);
            break;
    }
    
    // Save report data for export functions
    window.appState.currentReportData = reportData;
    
    // Update report title
    document.getElementById('report-title').textContent = reportTitle;
    
    // Update report summary
    document.getElementById('report-income').textContent = formatCurrency(reportData.income);
    document.getElementById('report-expenses').textContent = formatCurrency(reportData.expenses);
    document.getElementById('report-profit').textContent = formatCurrency(reportData.profit);
    document.getElementById('report-count').textContent = reportData.count;
    
    // Update report chart
    updateReportChart(reportType, reportData);
    
    // Update report table
    updateReportTable(reportType, reportData);
}

// Get date range for a given period
function getDateRangeForPeriod(period) {
    const now = new Date();
    let startDate, endDate;
    
    switch (period) {
        case 'this-month':
            startDate = new Date(now.getFullYear(), now.getMonth(), 1);
            endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
            break;
        case 'last-month':
            startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
            endDate = new Date(now.getFullYear(), now.getMonth(), 0);
            break;
        case 'this-quarter':
            const quarter = Math.floor(now.getMonth() / 3);
            startDate = new Date(now.getFullYear(), quarter * 3, 1);
            endDate = new Date(now.getFullYear(), (quarter + 1) * 3, 0);
            break;
        case 'this-year':
            startDate = new Date(now.getFullYear(), 0, 1);
            endDate = new Date(now.getFullYear(), 11, 31);
            break;
        case 'last-year':
            startDate = new Date(now.getFullYear() - 1, 0, 1);
            endDate = new Date(now.getFullYear() - 1, 11, 31);
            break;
    }
    
    return {
        startDate: startDate ? startDate.toISOString().split('T')[0] : null,
        endDate: endDate ? endDate.toISOString().split('T')[0] : null
    };
}

// Download report
function downloadReport(format) {
    const reportTitle = document.getElementById('report-title').textContent;
    const reportData = window.appState.currentReportData;
    
    if (!reportData) {
        alert('No report data available');
        return;
    }
    
    if (format === 'csv') {
        // Convert report data to CSV
        downloadReportAsCsv(reportTitle, reportData);
    } else if (format === 'pdf') {
        // Not implemented - would require a PDF library
        alert('PDF export is not implemented in this demo version');
    }
}

// Download report as CSV
function downloadReportAsCsv(reportTitle, reportData) {
    let csvContent = 'data:text/csv;charset=utf-8,';
    
    // Add report title
    csvContent += reportTitle + '\r\n\r\n';
    
    // Add summary
    csvContent += 'Summary\r\n';
    csvContent += 'Total Income,' + formatCurrency(reportData.income) + '\r\n';
    csvContent += 'Total Expenses,' + formatCurrency(reportData.expenses) + '\r\n';
    csvContent += 'Net Profit/Loss,' + formatCurrency(reportData.profit) + '\r\n';
    csvContent += 'Transaction Count,' + reportData.count + '\r\n\r\n';
    
    // Add detailed data based on report type
    const reportType = window.appState.currentReportType;
    
    switch (reportType) {
        case 'income-expense':
            csvContent += 'Date,Income,Expense,Net\r\n';
            reportData.details.forEach(item => {
                csvContent += `${item.date},${item.income},${item.expense},${item.net}\r\n`;
            });
            break;
        case 'category':
            csvContent += 'Category,Type,Amount,Percentage\r\n';
            reportData.details.forEach(item => {
                csvContent += `${item.category},${item.type},${item.amount},${item.percentage}%\r\n`;
            });
            break;
        case 'monthly-trend':
        case 'daily-trend':
            csvContent += 'Period,Income,Expense,Net\r\n';
            reportData.details.forEach(item => {
                csvContent += `${item.period},${item.income},${item.expense},${item.net}\r\n`;
            });
            break;
    }
    
    // Create a download link
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', reportTitle.replace(/\s+/g, '_') + '.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

// Print current report
function printCurrentReport() {
    window.print();
} 