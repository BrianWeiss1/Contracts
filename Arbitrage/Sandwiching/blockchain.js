const Web3 = require('web3');
const WebSocket = require('ws');
const process = require('process');
//WSS_NODE_ENDPOINT=wss://mainnet.infura.io/ws/v3/e18c974c31c34dc49008a4fc93829618
addressToCheck = '0x6577ecf1a0d82659d5d892b76d2a8e902fb1f31b'
api_key1 = 'e18c974c31c34dc49008a4fc93829618'
api_key2 = '2c793a97cb0f4c7c8bdb41140d726b03'
async function main() {
    const wssNodeEndpoint = 'wss://mainnet.infura.io/ws/v3/' + api_key2;
    if (!wssNodeEndpoint) {
        console.error('WSS_NODE_ENDPOINT environment variable not set');
        process.exit(1);
    }

    const web3 = new Web3(new Web3.providers.WebsocketProvider(wssNodeEndpoint));

    try {
        web3.eth.subscribe('pendingTransactions', (error, result) => {
            if (error) console.error(error);
        }).on("data", async (transactionHash) => {
            try {
                console.log(transactionHash)
                const transaction = await web3.eth.getTransaction(transactionHash);
                if (transaction) {
                    // if transaction['']
                    if (transaction['to'] == addressToCheck) {
                        console.log(transaction['hash']);
                    }                  
                } else {
                    // console.warn("could not find transaction for now");
                }
            } catch (error) {
                console.error(error);
            }
        });
    } catch (error) {
        console.error(error);
    }
}

main()