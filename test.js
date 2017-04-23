require('dotenv').config();

if(process.argv.length < 3){
	console.log("give a name to lookup your identity in the original devcon2 token contract");
	process.exit(1);
}
var name = process.argv[2];

var ethreader = require('./ethreader').ethreader;

var etherscan = new ethreader.EtherscanReader(process.env["ETHERSCAN_API_KEY"]);

var reader = etherscan.newTransactionReader("0x0a43edfe106d295e7c1e591a4b04b5598af9474c");

reader.collect(function(err, transactions){

	transactions.forEach((tx) => {
	  if(tx.decoded_call && ( tx.decoded_call.name == "mint")){
	  	var identity = tx.decoded_call.input._identity
	  	if(identity && identity.indexOf(name) >= 0){
	  		console.log(tx);
	  	}
	  }
	});

	
	
});	