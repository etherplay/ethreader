package ethreader;

import web3.Web3;

typedef ExtendedTransaction = {
	> Transaction,

	blockTimestamp : Float,
	
	isError : Bool,
	
	cumulativeGasUsed : Float,
	gasUsed : Float,
	contractAddress : String,
	logs : Array<Dynamic>
}