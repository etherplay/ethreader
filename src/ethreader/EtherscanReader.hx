package ethreader;

@:expose
class EtherscanReader implements EthReader{
	var _apiKey : String;

	public function new(apiKey : String){
		_apiKey = apiKey;
	}

	public function newTransactionReader(address : String) : ethreader.TransactionsReader{
		return new TransactionsReader(address, this);
	}


	public function getAbi(address : String, onData : Error -> Abi -> Void):Void{
		var options = {
		  host: 'api.etherscan.io',
		  path: '/api?module=contract&action=getabi&address='+address+'&apikey=' + _apiKey
		};

		var callback : Dynamic -> Void = null;

		callback = function(response) {
		  var str = '';

		  //another chunk of data has been recieved, so append it to `str`
		  response.on('data', function (chunk) {
		    str += chunk;
		  });

		  response.on('error', function(err) {
		        //console.log(err);
		        onData(err,null);
		  });	

		  //the whole response has been recieved, so we just print it out here
		  response.on('end', function (chunk) {
		  	var abi : Abi = null;
		  	var err : Error = null;
		  	try{
		  		var result : Dynamic = haxe.Json.parse(str);
		  		abi = haxe.Json.parse(result.result);
		  	}catch(e : Dynamic){
		  		abi = null;
		  		err = "no abi for " + address;
		  	}
		  	if(err != null){
		  		onData(err,null);
		  	}else{
		  		onData(null,abi);
		  	}
		    
		  });
		}

		trace("getting abi from etherscan...");
		js.node.Http.request(options, callback).end();
	}

	public function getTransactions(address : String, startBlock : Int, endBlock : Int, onData : Error -> Array<Transaction> -> Void):Void{
		var options = {
		  host: 'api.etherscan.io', //TODO testnet option
		  path: '/api?module=account&action=txlist&address='+address+'&startblock=' + startBlock + '&endblock='+endBlock+'&sort=asc&apikey=' + _apiKey
		};

		var callback : Dynamic -> Void = null;
		callback = function(response) {
		  var str = '';

		  //another chunk of data has been recieved, so append it to `str`
		  response.on('data', function (chunk) {
		    str += chunk;
		  });

		  response.on('error', function(err) {
		        // console.log(err);
		        onData(err,null);
		  });	

		  //the whole response has been recieved, so we just print it out here
		  response.on('end', function (chunk) {
		    var transactions : Array<Transaction> = null;
		  	var err : Error = null;
		  	try{
		  		var result : Dynamic = haxe.Json.parse(str);
		  		transactions = result.result;
		  	}catch(e : Dynamic){
		  		transactions = null;
		  		err = e;
		  	}
		  	if(err != null){
		  		onData(err,null);
		  	}else{
		  		onData(null,transactions);
		  	}
		  });
		}

		trace("getting transactions from etherscan...");
		var request = js.node.Http.request(options, callback);
		// var cache = [];
		// console.log(JSON.stringify(request,function(key, value) {
		// 	if (typeof value === 'object' && value !== null) {
		// 	    if (cache.indexOf(value) !== -1) {
		// 	        // Circular reference found, discard key
		// 	        return;
		// 	    }
		// 	    // Store value in our collection
		// 	    cache.push(value);
		// 	}
		// 	return value;
		// },4));
		// cache = null; 
		request.end();
	}

}
