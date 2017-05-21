package ethreader;

import web3.Web3;

typedef DecodedTransaction = { 
	> ExtendedTransaction,

	decoded_call : {
		name: String,
		input : haxe.DynamicAccess<Dynamic>
	}
}