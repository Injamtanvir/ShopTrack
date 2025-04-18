# ShopTrack Transaction Management

A simple, browser-based transaction management application for tracking your business income and expenses. This application runs entirely in your browser and uses local storage to save your data, meaning:

- No server setup required
- No database configuration
- Your data stays on your computer
- Works offline once loaded

## Features

- **Dashboard**: Get a quick overview of your financial situation with charts and summary statistics
- **Transaction Management**: Add, edit, and delete income and expense transactions
- **Reporting**: Generate comprehensive reports with charts and tables
- **Data Export/Import**: Backup and restore your data with JSON exports
- **Customization**: Add custom categories, change the currency symbol, and select different themes

## Setup Instructions

### Local Development

1. Clone or download this repository to your computer
2. Navigate to the download location and open the `index.html` file in your web browser
3. That's it! The application will load and you can start using it immediately

### Web Server Deployment

If you want to host this application on a web server:

1. Upload all files to your web server
2. Ensure the directory structure is maintained
3. Access the application through your domain (e.g., `https://yourdomain.com/shoptrack/transaction_management/`)

## Data Storage

This application uses your browser's local storage to save all data. This means:

- Your data is stored only on the device you're using
- Clearing browser data will erase your transaction history
- Different browsers/devices will have separate data stores

**Important**: To avoid data loss, regularly export your data using the "Export All Data" feature in the Settings page.

## Directory Structure

```
transaction_management/
├── css/
│   └── styles.css       # All application styles
├── js/
│   ├── app.js           # Main application logic and initialization
│   ├── data.js          # Data management functions
│   ├── ui.js            # UI rendering and event handlers
│   └── charts.js        # Chart generation and configuration
├── index.html           # Main application HTML
└── README.md            # This file
```

## Usage Guide

### Adding Transactions

1. Click on "Add Transaction" in the navigation menu
2. Select transaction type (Income or Expense)
3. Fill in the required details (date, amount, description, category, and status)
4. Add any optional notes or attachments
5. Click "Save Transaction"

### Viewing and Managing Transactions

1. Click on "Transactions" in the navigation menu
2. Use the search box and filters to find specific transactions
3. Click the eye icon to view details, the pencil icon to edit, or the trash icon to delete

### Generating Reports

1. Click on "Reports" in the navigation menu
2. Select the report type and time period
3. Click "Generate Report"
4. View the report data and charts
5. Use the export buttons to download the report as CSV or print it

### Customizing Settings

1. Click on "Settings" in the navigation menu
2. Add or remove categories
3. Change the currency symbol and decimal places
4. Export or import your data
5. Select a different theme
6. Click "Save Settings" to apply changes

## Browser Compatibility

This application is compatible with modern browsers including:

- Google Chrome (recommended)
- Mozilla Firefox
- Microsoft Edge
- Safari

For best performance and features, please use the latest version of your browser.

## Privacy

Since all data is stored locally on your device, you have complete control over your information. No data is sent to external servers unless you explicitly export and share it.

## License

This project is available for free use in your business. You may modify it to suit your needs.

## Support

For questions or issues, please contact the development team or create an issue in the GitHub repository.
