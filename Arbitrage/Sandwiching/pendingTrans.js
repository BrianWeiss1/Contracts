const Web3 = require('web3');
const axios = require('axios');

// Infura API URL for BSC
const infuraUrl = 'https://bsc-dataseed.binance.org/';

// Initialize web3 instance
const web3 = new Web3(new Web3.providers.HttpProvider(infuraUrl));

// Contract address to monitor
const contractAddress = '0xba2ae424d960c26247dd6c32edc70b295c744c43';

// Function to check pending transactions
async function checkPendingTransactions() {
  try {
    const latestBlock = await web3.eth.getBlock('latest');
    const pendingBlockNumber = latestBlock.number;
    
    const pendingTransactions = await web3.eth.getBlock('pending', true).transactions;
    
    for (const tx of pendingTransactions) {
      if (tx.to && tx.to.toLowerCase() === contractAddress.toLowerCase()) {
        // Analyze transactions for slippage (add your slippage logic here)
        const slippage = await calculateSlippage(tx); // Implement this function
        if (slippage > 0.05) { // Adjust this threshold as needed
          console.log('Transaction with high slippage detected:');
          console.log(`Tx Hash: ${tx.hash}`);
          console.log(`Slippage: ${slippage}`);
          // Print additional transaction details as needed
        }
      }
    }
  } catch (error) {
    console.error('Error checking pending transactions:', error);
  }
}

// Function to calculate slippage (you need to implement this based on contract specifics)
async function calculateSlippage(tx) {
  // Implement slippage calculation based on contract operations
  // You may need to decode input data or analyze contract state changes
  // Return the calculated slippage value
  return 0; // Placeholder, replace with actual logic
}

// Poll for pending transactions every X seconds
const pollInterval = 3000; // Adjust as needed
setInterval(checkPendingTransactions, pollInterval);

// Initial check
checkPendingTransactions();
