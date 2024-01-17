const Web3 = require('web3');
const axios = require('axios');

// Infura API URL for BSC
const infuraUrl = 'https://bsc-dataseed.binance.org/';

// Initialize web3 instance
const web3 = new Web3(new Web3.providers.HttpProvider(infuraUrl));

// Contract address to monitor
const CONTRACT_ADDRESS = '0xba2ae424d960c26247dd6c32edc70b295c744c43';
const BSCSCAN_API_KEY = 'XMT6DCRYF3MP8389W7FAF5VZKMDGYQIBIQ';

// Function to check pending transactions
async function getLatestTransactions() {
    const endpoint = `https://api.bscscan.com/api`;
    const action = `txlist`;
    const startBlock = 0; // Adjust as needed
    const endBlock = 99999999; // Adjust as needed
    const sort = 'desc'; // Latest transactions first
    // console.log("LA")
    try {
        const response = await axios.get(`${endpoint}`, {
            params: {
                module: 'account',
                action: action,
                address: CONTRACT_ADDRESS,
                startblock: startBlock,
                endblock: endBlock,
                sort: sort,
                apikey: BSCSCAN_API_KEY
            }
        });
        // Check if response has data and result
        if (response.data && response.data.result) {
            const transactions = response.data.result;
            // Filter for pending transactions
            const pendingTransactions = transactions.filter(tx => tx.isError === '0' && tx.txreceipt_status === '');
            console.log(pendingTransactions)
            return pendingTransactions;
        } else {
            // Log the entire response for debugging
            console.error('Unexpected response structure:', response);
            return [];
        }
    } catch (error) {
        console.error('Error fetching transactions from BSCScan:', error);
        return [];
    }
}
// getLatestTransactions()
// Function to calculate slippage (you need to implement this based on contract specifics)
async function calculateSlippage(tx) {
  // Implement slippage calculation based on contract operations
  // You may need to decode input data or analyze contract state changes
  // Return the calculated slippage value
  return 0; // Placeholder, replace with actual logic
}

// Poll for pending transactions every X seconds
const pollInterval = 3000; // Adjust as needed
setInterval(getLatestTransactions, pollInterval);

// Initial check
// getLatestTransactions();
