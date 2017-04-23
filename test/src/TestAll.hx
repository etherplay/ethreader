import ethreader.EtherscanReader;

class TestAll{
	public static function main(){
		untyped __js__("require('dotenv').config()");

		if(js.Node.process.argv.length < 3){
			trace("give a name to lookup your identity in the original devcon2 token contract");
			js.Node.process.exit(1);
		}
		var name = js.Node.process.argv[2];
		
		var apiKey = js.Node.process.env["ETHERSCAN_API_KEY"];

		
		var ethReader = new EtherscanReader(apiKey);
		var reader = ethReader.newTransactionReader("0x0a43edfe106d295e7c1e591a4b04b5598af9474c");

		reader.collect(function(err, transactions){

			for(tx in transactions){
			  if(tx.decoded_call != null && ( tx.decoded_call.name == "mint")){
			  	var identity = tx.decoded_call.input["_identity"];
			  	if(identity != null && identity.indexOf(name) >= 0){
			  		trace(tx);
			  	}
			  }
			}

			
			
		});	
	}
}