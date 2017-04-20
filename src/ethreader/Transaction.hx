package ethreader;

typedef Transaction = {
	//from transaction (https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethgettransaction)
	hash : String,
	nonce : String,
	blockHash : String,
	blockNumber : String,
	transactionIndex : String,
	from : String,
	to : String,
	value : String, 
	gasPrice : String, 
	gas : String,
	input : String,
	
	//from transaction receipt (https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethgettransactionreceipt)
	cumulativeGasUsed : String,
	gasUsed : String,
	contractAddress : String,
	
	//from block (https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethgetblock)
	timeStamp : String,

	//to compute (provided by etherscan)
	isError : String
}