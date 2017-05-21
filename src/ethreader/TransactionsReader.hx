package ethreader;

using Lambda;


//caching
import js.node.Fs;


typedef TransactionsCache = {
	transactions : Array<DecodedTransaction>,
	timestamp : Float,
	lastBlock : Float
}

class TransactionsReader{
	
	var _address : String;
	var _ethReader : EthReader;
	var _networkId : String;

	static var _folder : String;
	static public function __init__(){
		_folder = untyped js.node.Os.homedir() + "/.ethreader";
		if (!Fs.existsSync(_folder)){
		    Fs.mkdirSync(_folder);
		}
	}

	public function new(address : String, ethReader : EthReader){
		_address = address.toLowerCase();
		_ethReader = ethReader;
		_networkId = null;
	}

	

	public function collect(callback : Error -> Array<DecodedTransaction> -> Void, startBlock : Int = 0, endBlock : Int = 2147483647){ //TODO 64bit or string ?
		if(_networkId == null){
			_ethReader.getNetworkId(function(error,networkId){
				if(error != null){
					callback(error,null);
				}else{
					_networkId = networkId;
					_collect_abi(startBlock,endBlock,callback);
				}
			});
		}else{
			_collect_abi(startBlock,endBlock,callback);
		}
	}

	function _get_abi_from_cache(callback : Error -> Void){

		getFromFile(_folder + "/" + _networkId  + "_" + _address+".abi",function(error,data){
			if(error != null){
				callback(error);
			}else if(data == ""){
				callback("nothing in cache");
			}else{
				TransactionDecoder.addABI(_address, data);
				callback(null);
			}
		});

		
	}

	function _save_abi_to_cache(data, callback : Error -> Void){
		saveToFile(_folder + "/" + _networkId  + "_" + _address+".abi",data, callback);
	}

	function _collect_abi(startBlock : Int, endBlock : Int, callback : Error -> Array<DecodedTransaction> -> Void){
		if(!TransactionDecoder.hasABI(_address)){
			trace("getting abi from cache...");
			_get_abi_from_cache(function(error){
				if(error != null){
					trace("getting abi from ethreader...");
					_fetch_abi(function(error){
						if(error != null){
							callback(error,null);
						}else{
							_collect(startBlock,endBlock,callback);
						}
					});
				}else{
					_collect(startBlock,endBlock,callback);
				}
			});
		}else{
			_collect(startBlock,endBlock,callback);
		}
	}

	function _fetch_abi(callback : Error -> Void){
		_ethReader.getAbi(_address, function(error, data){
			if(error != null){
				callback(error);
			}else{
				trace("converting abi to abimap");
				TransactionDecoder.addABI(_address, data);
				_save_abi_to_cache(data, function(error){
					callback(error);
				});
			}
		});		
	}

	function _get_transactions_from_cache(callback : Error -> TransactionsCache -> Void){
		getFromFile(_folder + "/" + _ethReader.type + "_" + _networkId  + "_"  + _address+".tx",function(error,data){
			if(error != null){
				callback(error,null);
			}else if(data == ""){
				callback("nothing in cache",null);
			}else{
				callback(null,haxe.Json.parse(data));//todo try catch
			}
		});
	}

	function _save_transactions_to_cache(transactions : Array<DecodedTransaction>, callback : Error -> Void){
		trace("saving " + transactions.length + " transactions");
		saveToFile(_folder + "/" + _ethReader.type + "_" + _networkId  + "_"  + _address+".tx",haxe.Json.stringify({
			transactions : transactions,
			timestamp : Std.int(haxe.Timer.stamp()),
			lastBlock : transactions[transactions.length-1].blockNumber //TODO check length
		}), callback);
	}

	function _collect(startBlock : Int, endBlock : Int, callback : Error -> Array<DecodedTransaction> -> Void){
		trace("getting transactions from cache...");
		_get_transactions_from_cache(function(error, transactionsCache){
			var cacheDuration = 5 * 60;
			if(error !=null || (haxe.Timer.stamp() - transactionsCache.timestamp > cacheDuration  && transactionsCache.lastBlock < endBlock)){
				var prevTransactions = [];
				var fetchStartBlock = 0;
				if(transactionsCache != null){
					prevTransactions = transactionsCache.transactions;
					fetchStartBlock = Std.int(transactionsCache.lastBlock + 1);
				}
				
				trace("getting transactions from ethreader (" + fetchStartBlock + " to " + endBlock + ")");
				_ethReader.getTransactions(_address, fetchStartBlock, endBlock, function(error, transactions){
					if(error != null){
						callback(error,null);
					}else{

						var extraTransactions = transactions.length > 0;

						#if debug
							for(transaction in prevTransactions){
								TransactionDecoder.decodeTransactionInPlace(transaction);
							}
							extraTransactions = true;
						#end

						if(extraTransactions){
							trace("decoding " +  transactions.length + " transactions ...");
							for(transaction in transactions){
								
								var decodedTransaction : DecodedTransaction = cast transaction; //TODO copy ?
								prevTransactions.push(decodedTransaction);

								TransactionDecoder.decodeTransactionInPlace(decodedTransaction);
							}
						}
						
						var transactionsToOutput = prevTransactions.filter(function(tx){
							return tx.blockNumber >= startBlock && tx.blockNumber <= endBlock;
						});
						

						if(extraTransactions){
							_save_transactions_to_cache(prevTransactions,function(error){
								callback(null,transactionsToOutput);
							});
						}else{
							callback(null,transactionsToOutput);
						}
						
						
					}
				});
			}else{
				trace("skip fetch..."); 
				var transactionsToOutput = transactionsCache.transactions.filter(function(tx){
						return tx.blockNumber >= startBlock  && tx.blockNumber <= endBlock;
					});

				#if debug
				for(transaction in transactionsCache.transactions){
					TransactionDecoder.decodeTransactionInPlace(transaction);
				}
				_save_transactions_to_cache(transactionsCache.transactions,function(error){
					callback(null,transactionsToOutput);
				});
				#else
				callback(null,transactionsToOutput);
				#end
			}
		});
		
	}















	function saveToFile(filename : String, data : String, callback : Error -> Void){
		Fs.writeFile(filename, data, function(err) {
		    callback(err);
		}); 
	}

	function getFromFile(filename : String, callback : Error -> String -> Void){
		Fs.readFile(filename,  function(err,result){
			if(err != null){
				callback(err, null);
			}else if(result.toString() == ""){
				callback("nothing", null);
			}else{
				callback(err, result.toString());
			}
		});
	}

}