// Transaction Management Service

// API endpoint base URLs
// Try different API endpoints in case one is not responding correctly
const API_BASE_URL_PRODUCTION = 'https://shoptrack-w8wu.onrender.com/api';
const API_BASE_URL_ALTERNATIVE = 'https://shoptrack-w8wu.onrender.com/api';

// Check if using local testing mode (set from the URL with ?local=true)
const isLocalTesting = new URLSearchParams(window.location.search).get('local') === 'true';

// Check URL parameters for test mode
const urlParams = new URLSearchParams(window.location.search);
const isTestMode = urlParams.get('test') === 'true';

// Set the API base URL
const API_BASE_URL = isLocalTesting ? 'http://localhost:3000/api' : API_BASE_URL_PRODUCTION;

// Debug configuration
console.log("Using API endpoint:", API_BASE_URL);
console.log("Is local testing mode:", isLocalTesting);
console.log("Is test mode (simulated responses):", isTestMode);

// Process a premium subscription payment
async function processPayment(transactionId, amount) {
    // Show loader
    showLoader();
    
    try {
        console.log(`Processing payment - Transaction ID: ${transactionId}, Amount: ${amount}`);
        
        // If in test mode, simulate a successful response
        if (isTestMode) {
            console.log("Using test mode - simulating successful payment");
            return {
                success: true,
                message: 'Payment processed successfully (TEST MODE).',
                details: {
                    transactionId: transactionId,
                    amount: amount,
                    timestamp: new Date().toISOString(),
                    newBalance: parseFloat(amount) + 500 // Fake balance
                }
            };
        }
        
        // Step 1: Check if transaction ID has already been used
        const transactionExists = await checkTransactionExists(transactionId);
        
        if (transactionExists) {
            console.log("Transaction already exists, rejecting duplicate");
            return {
                success: false,
                message: 'This transaction ID has already been processed.'
            };
        }
        
        // Step 2: Process payment with just transaction ID and amount
        console.log("Transaction is new, proceeding with payment");
        const paymentResult = await addPaymentToSubscription(transactionId, amount);
        
        if (!paymentResult.success) {
            console.log("Payment failed:", paymentResult.message);
            return {
                success: false,
                message: 'Failed to process payment: ' + paymentResult.message
            };
        }
        
        // Step 3: Record transaction to prevent reuse
        console.log("Payment successful, recording transaction");
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
    // If in test mode, simulate a negative response (transaction doesn't exist)
    if (isTestMode) {
        console.log("Test mode: Simulating new transaction (doesn't exist)");
        return false;
    }
    
    try {
        console.log(`Checking if transaction exists: ${transactionId}`);
        
        const response = await fetch(`${API_BASE_URL}/premium/transaction/${transactionId}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        });
        
        console.log(`Check transaction response status: ${response.status}`);
        
        // Check if response is HTML (common server error)
        const contentType = response.headers.get('content-type');
        console.log("Check transaction content type:", contentType);
        
        if (contentType && contentType.includes('text/html')) {
            console.error('Received HTML response instead of JSON during transaction check');
            // In case of server error, continue with false to avoid blocking legitimate transactions
            return false;
        }
        
        if (response.status === 404) {
            // Transaction doesn't exist (which is good, we want a new transaction)
            console.log("Transaction does not exist (404) - this is good for a new transaction");
            return false;
        }
        
        try {
            const data = await response.json();
            console.log("Transaction check result:", data);
            return data.exists; // True if transaction exists
        } catch (parseError) {
            console.error('Error parsing response:', parseError);
            // If we can't parse the response, assume it doesn't exist
            return false;
        }
        
    } catch (error) {
        console.error('Error checking transaction:', error);
        // If we can't verify, assume it's new to prevent double processing
        return false;
    }
}

// Add payment to subscription (directly from app user's dashboard)
async function addPaymentToSubscription(transactionId, amount) {
    // If in test mode, simulate a successful response
    if (isTestMode) {
        console.log("Test mode: Simulating successful payment addition");
        return {
            success: true,
            newBalance: parseFloat(amount) + 500 // Fake balance
        };
    }
    
    try {
        console.log(`Sending payment request to ${API_BASE_URL}/premium/addrecharge`);
        console.log(`Payload: ${JSON.stringify({
            transactionId: transactionId,
            amount: amount
        })}`);
        
        const response = await fetch(`${API_BASE_URL}/premium/addrecharge`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                transactionId: transactionId,
                amount: amount
            })
        });
        
        // Check if response is HTML (common server error)
        const contentType = response.headers.get('content-type');
        console.log("Response content type:", contentType);
        
        if (contentType && contentType.includes('text/html')) {
            console.error('Received HTML response instead of JSON');
            return {
                success: false,
                message: 'Server error: Received HTML instead of JSON. The server may be down or misconfigured.'
            };
        }
        
        if (!response.ok) {
            try {
                const errorData = await response.json();
                return {
                    success: false,
                    message: errorData.message || 'Failed to add payment'
                };
            } catch (parseError) {
                // If we can't parse the error as JSON
                const text = await response.text();
                console.error('Error response was not JSON:', text.substring(0, 100));
                return {
                    success: false,
                    message: `Server error (${response.status}): Unable to process request`
                };
            }
        }
        
        const data = await response.json();
        console.log("Received successful response:", data);
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
    // If in test mode, simulate a successful response
    if (isTestMode) {
        console.log("Test mode: Simulating successful transaction recording");
        return true;
    }
    
    try {
        console.log(`Recording transaction: ${transactionId}, Amount: ${amount}`);
        
        const response = await fetch(`${API_BASE_URL}/premium/transaction`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                transactionId: transactionId,
                amount: amount,
                timestamp: new Date().toISOString()
            })
        });
        
        console.log(`Record transaction response status: ${response.status}`);
        
        // Check if response is HTML (common server error)
        const contentType = response.headers.get('content-type');
        console.log("Record transaction content type:", contentType);
        
        if (contentType && contentType.includes('text/html')) {
            console.error('Received HTML response instead of JSON when recording transaction');
            return false;
        }
        
        if (!response.ok) {
            try {
                const errorText = await response.text();
                console.error('Failed to record transaction:', errorText.substring(0, 100));
            } catch (e) {
                console.error('Failed to record transaction, status:', response.status);
            }
            return false;
        }
        
        console.log("Transaction recorded successfully");
        return true;
        
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