const Web3 = require('web3');
// require('websockets');
// Replace with your Infura Project ID
const infuraProjectId = 'e18c974c31c34dc49008a4fc93829618';

// Use Infura WebSocket Provider
const web3 = new Web3(new Web3.providers.WebsocketProvider(`wss://mainnet.infura.io/ws/v3/${infuraProjectId}`));

const contractAddress = '0xba2ae424d960c26247dd6c32edc70b295c744c43'.toLowerCase();

function hasHighSlippage(transaction) {
    // Implement your logic to determine high slippage
    return true; // Placeholder
}

web3.eth.subscribe('pendingTransactions', (error, txHash) => {
    if (error) console.error('Subscription error:', error);
    // console.log(txHash)
    web3.eth.getTransaction(txHash, (err, tx) => {
        if (tx != null) {
            console.log(tx)
        }
        if (err) return;
        if (tx && tx.to && tx.to.toLowerCase() === contractAddress) {
            // Here, you can analyze the transaction
            if (hasHighSlippage(tx)) {
                console.log('High slippage transaction found:', tx);
            }
        }
    });
})
.on("error", console.error);
