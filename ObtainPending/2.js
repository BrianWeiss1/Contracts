const axios = require('axios');
const process = require('process');

// Replace this with your Etherscan API key
const etherscanApiKey = 'FTWM4WXF5VX9IMABRF25WG7QC6UNZKVGQD';
const addressToCheck = '0x6577ecf1a0d82659d5d892b76d2a8e902fb1f31b';

async function getPendingTransactions() {
    try {
        const response = await axios.get(`https://api.etherscan.io/api?module=account&action=txlist&address=${addressToCheck}&startblock=0&endblock=99999999&sort=asc&apikey=${etherscanApiKey}`);
        const transactions = response.data.result;
        for (let transaction of transactions) {
            console.log(transaction)
            if (!transaction.isError && transaction.txreceipt_status === "") {
                console.log(`Pending Transaction Hash: ${transaction.hash}`);
            }
        }
    } catch (error) {
        console.error('Error fetching transactions:', error);
    }
}

setInterval(getPendingTransactions, 1000); // Poll every 0.25 seconds # max 5 per second
