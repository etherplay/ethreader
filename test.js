require('dotenv').config();

var ethreader = require('./ethreader').ethreader;

var etherscan = new ethreader.EtherscanReader(process.env["ETHERSCAN_API_KEY"]);

var reader = etherscan.newTransactionReader("0x3d42F7eb6B97Ab66d8d44C725651BEfE02a70e5E");

reader.collect(function(err, transactions){


	var players = {}
	transactions.forEach((tx) => {
	  if(tx.decoded_call && ( tx.decoded_call.name == "setName")){
	  	if(!players[tx.from]){
	  		players[tx.from] = [];
	  	}
	  	players[tx.from].push(tx);
	  }
	});

	var numPlayers = 0;
	for (var player in players) {
	    if (players.hasOwnProperty(player)) {
	    	numPlayers ++;
	    }
	}
	
	console.log(numPlayers);
	process.exit(0); //TODO fix our use of parity.js

});	