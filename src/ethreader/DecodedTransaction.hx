package ethreader;

import web3.Web3;

typedef DecodedTransaction = { 
	> Transaction,

	timeStamp : Float,
	
	isError : Bool,
	
	cumulativeGasUsed : Float,
	gasUsed : Float,
	contractAddress : String,
	logs : Array<Dynamic>,

	decoded_call : {
		name: String,
		input : haxe.DynamicAccess<Dynamic>
	}
}