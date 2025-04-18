// Charts Management Functions

// Initialize charts
function initializeCharts() {
    // Create empty charts initially
    createEmptyMonthlyChart();
    createEmptyCategoryChart();
}

// Create an empty monthly chart
function createEmptyMonthlyChart() {
    const ctx = document.getElementById('monthly-chart');
    if (!ctx) return;
    
    window.monthlyChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: [],
            datasets: [
                {
                    label: 'Income',
                    backgroundColor: 'rgba(40, 167, 69, 0.6)',
                    borderColor: 'rgba(40, 167, 69, 1)',
                    borderWidth: 1,
                    data: []
                },
                {
                    label: 'Expenses',
                    backgroundColor: 'rgba(220, 53, 69, 0.6)',
                    borderColor: 'rgba(220, 53, 69, 1)',
                    borderWidth: 1,
                    data: []
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return formatCurrency(value);
                        }
                    }
                }
            },
            plugins: {
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return context.dataset.label + ': ' + formatCurrency(context.raw);
                        }
                    }
                }
            }
        }
    });
}

// Create an empty category chart
function createEmptyCategoryChart() {
    const ctx = document.getElementById('category-chart');
    if (!ctx) return;
    
    window.categoryChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: [],
            datasets: [{
                data: [],
                backgroundColor: [
                    '#4a6fdc', '#28a745', '#dc3545', '#ffc107', 
                    '#17a2b8', '#6610f2', '#fd7e14', '#20c997',
                    '#e83e8c', '#6c757d', '#007bff', '#6f42c1'
                ],
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            const label = context.label || '';
                            const value = formatCurrency(context.raw);
                            const percentage = Math.round(context.parsed * 10) / 10 + '%';
                            return label + ': ' + value + ' (' + percentage + ')';
                        }
                    }
                }
            }
        }
    });
}

// Update dashboard charts
function updateDashboardCharts(transactions) {
    updateMonthlyChart(transactions);
    updateCategoryChart(transactions);
}

// Update monthly chart
function updateMonthlyChart(transactions) {
    if (!window.monthlyChart) {
        createEmptyMonthlyChart();
    }
    
    // Get last 6 months
    const months = [];
    const now = new Date();
    for (let i = 5; i >= 0; i--) {
        const month = new Date(now.getFullYear(), now.getMonth() - i, 1);
        months.push(month);
    }
    
    // Calculate monthly income and expenses
    const incomeData = [];
    const expenseData = [];
    const labels = [];
    
    months.forEach(month => {
        const monthName = month.toLocaleString('default', { month: 'short' });
        const year = month.getFullYear();
        labels.push(`${monthName} ${year}`);
        
        const monthStart = new Date(year, month.getMonth(), 1);
        const monthEnd = new Date(year, month.getMonth() + 1, 0);
        
        const monthTransactions = transactions.filter(t => {
            const date = new Date(t.date);
            return date >= monthStart && date <= monthEnd;
        });
        
        const income = calculateTotalIncome(monthTransactions);
        const expense = calculateTotalExpenses(monthTransactions);
        
        incomeData.push(income);
        expenseData.push(expense);
    });
    
    // Update chart data
    window.monthlyChart.data.labels = labels;
    window.monthlyChart.data.datasets[0].data = incomeData;
    window.monthlyChart.data.datasets[1].data = expenseData;
    window.monthlyChart.update();
}

// Update category chart
function updateCategoryChart(transactions) {
    if (!window.categoryChart) {
        createEmptyCategoryChart();
    }
    
    // Get expense categories and their totals
    const categories = {};
    
    transactions.forEach(transaction => {
        if (transaction.type === 'expense' && transaction.status === 'completed') {
            if (!categories[transaction.category]) {
                categories[transaction.category] = 0;
            }
            categories[transaction.category] += parseFloat(transaction.amount);
        }
    });
    
    // Convert to arrays for chart
    const labels = [];
    const data = [];
    
    // Sort categories by amount (highest first)
    const sortedCategories = Object.entries(categories)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 8); // Limit to top 8 categories
    
    sortedCategories.forEach(([category, amount]) => {
        labels.push(category);
        data.push(amount);
    });
    
    // Update chart data
    window.categoryChart.data.labels = labels;
    window.categoryChart.data.datasets[0].data = data;
    window.categoryChart.update();
}

// Update report chart
function updateReportChart(reportType, reportData) {
    // Get chart context
    const ctx = document.getElementById('report-chart');
    if (!ctx) return;
    
    // Destroy existing chart if it exists
    if (window.reportChart) {
        window.reportChart.destroy();
    }
    
    let chartConfig;
    
    switch (reportType) {
        case 'income-expense':
            chartConfig = createIncomeExpenseChartConfig(reportData);
            break;
        case 'category':
            chartConfig = createCategoryChartConfig(reportData);
            break;
        case 'monthly-trend':
        case 'daily-trend':
            chartConfig = createTrendChartConfig(reportData);
            break;
    }
    
    // Create new chart
    window.reportChart = new Chart(ctx, chartConfig);
}

// Create income vs expense chart config
function createIncomeExpenseChartConfig(reportData) {
    const labels = reportData.details.map(item => item.date);
    const incomeData = reportData.details.map(item => item.income);
    const expenseData = reportData.details.map(item => item.expense);
    const netData = reportData.details.map(item => item.net);
    
    return {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Income',
                    backgroundColor: 'rgba(40, 167, 69, 0.6)',
                    borderColor: 'rgba(40, 167, 69, 1)',
                    borderWidth: 1,
                    data: incomeData
                },
                {
                    label: 'Expenses',
                    backgroundColor: 'rgba(220, 53, 69, 0.6)',
                    borderColor: 'rgba(220, 53, 69, 1)',
                    borderWidth: 1,
                    data: expenseData
                },
                {
                    label: 'Net',
                    type: 'line',
                    backgroundColor: 'rgba(0, 123, 255, 0.5)',
                    borderColor: 'rgba(0, 123, 255, 1)',
                    borderWidth: 2,
                    pointBackgroundColor: 'rgba(0, 123, 255, 1)',
                    fill: false,
                    data: netData
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return formatCurrency(value);
                        }
                    }
                }
            },
            plugins: {
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return context.dataset.label + ': ' + formatCurrency(context.raw);
                        }
                    }
                }
            }
        }
    };
}

// Create category chart config
function createCategoryChartConfig(reportData) {
    const labels = reportData.details.map(item => item.category);
    const data = reportData.details.map(item => item.amount);
    const backgroundColors = reportData.details.map(item => 
        item.type === 'income' ? 'rgba(40, 167, 69, 0.6)' : 'rgba(220, 53, 69, 0.6)'
    );
    
    return {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: data,
                backgroundColor: backgroundColors,
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            const label = context.label || '';
                            const value = formatCurrency(context.raw);
                            const percentage = context.parsed + '%';
                            return label + ': ' + value + ' (' + percentage + ')';
                        }
                    }
                }
            }
        }
    };
}

// Create trend chart config
function createTrendChartConfig(reportData) {
    const labels = reportData.details.map(item => item.period);
    const incomeData = reportData.details.map(item => item.income);
    const expenseData = reportData.details.map(item => item.expense);
    const netData = reportData.details.map(item => item.net);
    
    return {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Income',
                    backgroundColor: 'rgba(40, 167, 69, 0.1)',
                    borderColor: 'rgba(40, 167, 69, 1)',
                    borderWidth: 2,
                    pointBackgroundColor: 'rgba(40, 167, 69, 1)',
                    fill: true,
                    data: incomeData
                },
                {
                    label: 'Expenses',
                    backgroundColor: 'rgba(220, 53, 69, 0.1)',
                    borderColor: 'rgba(220, 53, 69, 1)',
                    borderWidth: 2,
                    pointBackgroundColor: 'rgba(220, 53, 69, 1)',
                    fill: true,
                    data: expenseData
                },
                {
                    label: 'Net',
                    backgroundColor: 'rgba(0, 123, 255, 0.1)',
                    borderColor: 'rgba(0, 123, 255, 1)',
                    borderWidth: 2,
                    pointBackgroundColor: 'rgba(0, 123, 255, 1)',
                    fill: true,
                    data: netData
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return formatCurrency(value);
                        }
                    }
                }
            },
            plugins: {
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return context.dataset.label + ': ' + formatCurrency(context.raw);
                        }
                    }
                }
            }
        }
    };
}

// Update report table
function updateReportTable(reportType, reportData) {
    const tableHead = document.getElementById('report-table-head');
    const tableBody = document.getElementById('report-table-body');
    
    if (!tableHead || !tableBody) return;
    
    // Clear tables
    tableHead.innerHTML = '';
    tableBody.innerHTML = '';
    
    // Create table header and body based on report type
    let headerRow = document.createElement('tr');
    
    switch (reportType) {
        case 'income-expense':
            headerRow.innerHTML = `
                <th>Date</th>
                <th>Income</th>
                <th>Expenses</th>
                <th>Net</th>
            `;
            tableHead.appendChild(headerRow);
            
            reportData.details.forEach(item => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${item.date}</td>
                    <td class="amount income">${formatCurrency(item.income)}</td>
                    <td class="amount expense">${formatCurrency(item.expense)}</td>
                    <td class="amount ${item.net >= 0 ? 'income' : 'expense'}">${formatCurrency(item.net)}</td>
                `;
                tableBody.appendChild(row);
            });
            break;
            
        case 'category':
            headerRow.innerHTML = `
                <th>Category</th>
                <th>Type</th>
                <th>Amount</th>
                <th>Percentage</th>
            `;
            tableHead.appendChild(headerRow);
            
            reportData.details.forEach(item => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${item.category}</td>
                    <td>${item.type === 'income' ? 'Income' : 'Expense'}</td>
                    <td class="amount ${item.type}">${formatCurrency(item.amount)}</td>
                    <td>${item.percentage}%</td>
                `;
                tableBody.appendChild(row);
            });
            break;
            
        case 'monthly-trend':
        case 'daily-trend':
            headerRow.innerHTML = `
                <th>Period</th>
                <th>Income</th>
                <th>Expenses</th>
                <th>Net</th>
            `;
            tableHead.appendChild(headerRow);
            
            reportData.details.forEach(item => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${item.period}</td>
                    <td class="amount income">${formatCurrency(item.income)}</td>
                    <td class="amount expense">${formatCurrency(item.expense)}</td>
                    <td class="amount ${item.net >= 0 ? 'income' : 'expense'}">${formatCurrency(item.net)}</td>
                `;
                tableBody.appendChild(row);
            });
            break;
    }
}

// Generate income vs expense report
function generateIncomeExpenseReport(transactions, startDate, endDate) {
    // Calculate overall totals
    const income = calculateTotalIncome(transactions);
    const expenses = calculateTotalExpenses(transactions);
    const profit = income - expenses;
    const count = transactions.length;
    
    // Group by week
    const weeklyData = {};
    
    transactions.forEach(transaction => {
        const date = new Date(transaction.date);
        const weekStart = new Date(date);
        weekStart.setDate(date.getDate() - date.getDay()); // Start of week (Sunday)
        
        const weekKey = weekStart.toISOString().split('T')[0];
        
        if (!weeklyData[weekKey]) {
            weeklyData[weekKey] = {
                date: `Week of ${weekStart.toLocaleDateString()}`,
                income: 0,
                expense: 0
            };
        }
        
        if (transaction.type === 'income' && transaction.status === 'completed') {
            weeklyData[weekKey].income += parseFloat(transaction.amount);
        } else if (transaction.type === 'expense' && transaction.status === 'completed') {
            weeklyData[weekKey].expense += parseFloat(transaction.amount);
        }
    });
    
    // Convert to array and sort by date
    const details = Object.values(weeklyData);
    
    // Sort by date
    details.sort((a, b) => new Date(a.date) - new Date(b.date));
    
    // Calculate net for each week
    details.forEach(week => {
        week.net = week.income - week.expense;
    });
    
    return {
        income,
        expenses,
        profit,
        count,
        details
    };
}

// Generate category report
function generateCategoryReport(transactions, startDate, endDate) {
    // Calculate overall totals
    const income = calculateTotalIncome(transactions);
    const expenses = calculateTotalExpenses(transactions);
    const profit = income - expenses;
    const count = transactions.length;
    
    // Group by category
    const categoryData = {};
    
    transactions.forEach(transaction => {
        if (transaction.status !== 'completed') return;
        
        const category = transaction.category;
        const type = transaction.type;
        const amount = parseFloat(transaction.amount);
        
        if (!categoryData[category]) {
            categoryData[category] = {
                category,
                type,
                amount: 0
            };
        }
        
        categoryData[category].amount += amount;
    });
    
    // Convert to array
    let details = Object.values(categoryData);
    
    // Sort by amount (highest first)
    details = details.sort((a, b) => b.amount - a.amount);
    
    // Calculate percentage
    const total = income + expenses;
    details.forEach(item => {
        item.percentage = Math.round((item.amount / total) * 100 * 10) / 10; // Round to 1 decimal place
    });
    
    return {
        income,
        expenses,
        profit,
        count,
        details
    };
}

// Generate monthly trend report
function generateMonthlyTrendReport(transactions, startDate, endDate) {
    // Calculate overall totals
    const income = calculateTotalIncome(transactions);
    const expenses = calculateTotalExpenses(transactions);
    const profit = income - expenses;
    const count = transactions.length;
    
    // Determine date range
    const start = new Date(startDate);
    const end = new Date(endDate);
    
    // Generate months in the range
    const months = [];
    let currentMonth = new Date(start.getFullYear(), start.getMonth(), 1);
    
    while (currentMonth <= end) {
        months.push(new Date(currentMonth));
        currentMonth.setMonth(currentMonth.getMonth() + 1);
    }
    
    // Group by month
    const details = months.map(month => {
        const monthName = month.toLocaleString('default', { month: 'long' });
        const year = month.getFullYear();
        const period = `${monthName} ${year}`;
        
        const monthStart = new Date(year, month.getMonth(), 1);
        const monthEnd = new Date(year, month.getMonth() + 1, 0);
        
        const monthTransactions = transactions.filter(t => {
            const date = new Date(t.date);
            return date >= monthStart && date <= monthEnd;
        });
        
        const income = calculateTotalIncome(monthTransactions);
        const expense = calculateTotalExpenses(monthTransactions);
        const net = income - expense;
        
        return {
            period,
            income,
            expense,
            net
        };
    });
    
    return {
        income,
        expenses,
        profit,
        count,
        details
    };
}

// Generate daily trend report
function generateDailyTrendReport(transactions, startDate, endDate) {
    // Calculate overall totals
    const income = calculateTotalIncome(transactions);
    const expenses = calculateTotalExpenses(transactions);
    const profit = income - expenses;
    const count = transactions.length;
    
    // Group by day of week
    const daysOfWeek = {
        0: { period: 'Sunday', income: 0, expense: 0 },
        1: { period: 'Monday', income: 0, expense: 0 },
        2: { period: 'Tuesday', income: 0, expense: 0 },
        3: { period: 'Wednesday', income: 0, expense: 0 },
        4: { period: 'Thursday', income: 0, expense: 0 },
        5: { period: 'Friday', income: 0, expense: 0 },
        6: { period: 'Saturday', income: 0, expense: 0 }
    };
    
    transactions.forEach(transaction => {
        if (transaction.status !== 'completed') return;
        
        const date = new Date(transaction.date);
        const dayOfWeek = date.getDay();
        const amount = parseFloat(transaction.amount);
        
        if (transaction.type === 'income') {
            daysOfWeek[dayOfWeek].income += amount;
        } else if (transaction.type === 'expense') {
            daysOfWeek[dayOfWeek].expense += amount;
        }
    });
    
    // Convert to array and calculate net
    const details = Object.values(daysOfWeek);
    details.forEach(day => {
        day.net = day.income - day.expense;
    });
    
    return {
        income,
        expenses,
        profit,
        count,
        details
    };
} 