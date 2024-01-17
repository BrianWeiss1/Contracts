const Web3 = require('web3');
const process = require('process');

// Replace this with your Alchemy WebSocket endpoint
const wssNodeEndpoint = 'wss://eth-mainnet.alchemyapi.io/v2/KHSHYxl5GbYXo389R8rac5BKz0E48n27';
const addressToCheck = '0x6577ecf1a0d82659d5d892b76d2a8e902fb1f31b';

if (!wssNodeEndpoint) {
    console.error('Alchemy WSS_NODE_ENDPOINT environment variable not set');
    process.exit(1);
}

async function main() {
    const web3 = new Web3(new Web3.providers.WebsocketProvider(wssNodeEndpoint));

    try {
        web3.eth.subscribe('pendingTransactions', (error, result) => {
            if (error) console.error(error);
        }).on("data", async (transactionHash) => {
            try {
                const transaction = await web3.eth.getTransaction(transactionHash);
                if (transaction && transaction.to === addressToCheck) {
                    console.log(transaction.hash);
                }
            } catch (error) {
                console.error(error);
            }
        });
    } catch (error) {
        console.error(error);
    }
}

main();
