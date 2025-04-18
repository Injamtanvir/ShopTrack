// Transaction Management Service

// API endpoint base URL
const API_BASE_URL = 'https://shoptrack-w8wu.onrender.com/api';

// Process a premium subscription payment
async function processPayment(transactionId, amount) {
    // Show loader
    showLoader();
    
    try {
        // Step 1: Check if transaction ID has already been used
        const transactionExists = await checkTransactionExists(transactionId);
        
        if (transactionExists) {
            return {
                success: false,
                message: 'This transaction ID has already been processed.'
            };
        }
        
        // Step 2: Process payment with just transaction ID and amount
        const paymentResult = await addPaymentToSubscription(transactionId, amount);
        
        if (!paymentResult.success) {
            return {
                success: false,
                message: 'Failed to process payment: ' + paymentResult.message
            };
        }
        
        // Step 3: Record transaction to prevent reuse
        await recordTransaction(transactionId, amount);
        
        return {
            success: true,
            message: 'Payment processed successfully.',
            details: {
                transactionId: transactionId,
                amount: amount,
                timestamp: new Date().toISOString(),
                newBalance: paymentResult.newBalance
            }
        };
        
    } catch (error) {
        console.error('Payment processing error:', error);
        return {
            success: false,
            message: 'An error occurred while processing payment: ' + error.message
        };
    } finally {
        // Hide loader
        hideLoader();
    }
}

// Check if transaction ID has already been used
async function checkTransactionExists(transactionId) {
    try {
        const response = await fetch(`${API_BASE_URL}/premium/transaction/${transactionId}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        if (response.status === 404) {
            // Transaction doesn't exist (which is good, we want a new transaction)
            return false;
        }
        
        const data = await response.json();
        return data.exists; // True if transaction exists
        
    } catch (error) {
        console.error('Error checking transaction:', error);
        // If we can't verify, assume it's new to prevent double processing
        return false;
    }
}

// Add payment to subscription (directly from app user's dashboard)
async function addPaymentToSubscription(transactionId, amount) {
    try {
        const response = await fetch(`${API_BASE_URL}/premium/addrecharge`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                transactionId: transactionId,
                amount: amount
            })
        });
        
        if (!response.ok) {
            const errorData = await response.json();
            return {
                success: false,
                message: errorData.message || 'Failed to add payment'
            };
        }
        
        const data = await response.json();
        return {
            success: true,
            newBalance: data.newBalance
        };
        
    } catch (error) {
        console.error('Error adding payment:', error);
        return {
            success: false,
            message: error.message
        };
    }
}

// Record transaction to prevent reuse
async function recordTransaction(transactionId, amount) {
    try {
        const response = await fetch(`${API_BASE_URL}/premium/transaction`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                transactionId: transactionId,
                amount: amount,
                timestamp: new Date().toISOString()
            })
        });
        
        if (!response.ok) {
            console.error('Failed to record transaction:', await response.text());
        }
        
        return response.ok;
        
    } catch (error) {
        console.error('Error recording transaction:', error);
        return false;
    }
}

// UI Helper Functions
function showLoader() {
    document.getElementById('loader').classList.remove('hidden');
}

function hideLoader() {
    document.getElementById('loader').classList.add('hidden');
}

function showResult(success, message, details = null) {
    const resultContainer = document.getElementById('result-container');
    const transactionStatus = document.getElementById('transaction-status');
    
    let html = `<div class="${success ? 'success-message' : 'error-message'}">
        ${message}
    </div>`;
    
    if (details && success) {
        html += `<div class="transaction-details">
            <p><strong>Transaction ID:</strong> ${details.transactionId}</p>
            <p><strong>Amount:</strong> ৳${details.amount}</p>
            <p><strong>New Balance:</strong> ৳${details.newBalance}</p>
            <p><strong>Timestamp:</strong> ${new Date(details.timestamp).toLocaleString()}</p>
        </div>`;
    }
    
    transactionStatus.innerHTML = html;
    resultContainer.classList.add('active');
    
    // Scroll to result
    resultContainer.scrollIntoView({ behavior: 'smooth' });
} 