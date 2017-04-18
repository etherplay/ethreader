import ethreader.EtherscanReader;

class TestAll{
	public static function main(){
		untyped __js__("require('dotenv').config()");
		var ethReader = new EtherscanReader(js.Node.process.env["ETHERSCAN_API_KEY"]);
		var txReader = ethReader.newTransactionReader("0x5f742383b6d1298980030d6af943b76cdd902143");
		txReader.collect(function(error, transactions){
			if(error != null){
				trace("error", error);
			}else{
				trace(transactions);
			}

			js.Node.process.exit(0); //TODO fix our use of parity.js
			
		},3552258);
	}
}