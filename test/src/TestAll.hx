import ethreader.EtherscanReader;

class TestAll{
	public static function main(){
		
		untyped __js__("require('dotenv').config()");
		var apiKey = js.Node.process.env["ETHERSCAN_API_KEY"];

		
		var ethReader = new EtherscanReader(apiKey);
		var txReader = ethReader.newTransactionReader("0x5f742383b6d1298980030d6af943b76cdd902143");
		// var txReader = ethReader.newTransactionReader("0x3d42F7eb6B97Ab66d8d44C725651BEfE02a70e5E");

		txReader.collect(function(error, transactions){
			if(error != null){
				trace("error", error);
			}else{
				trace(haxe.Json.stringify(transactions, null, "  "));
			}
			trace(transactions.length);
		},2966683,2966683);
	}
}