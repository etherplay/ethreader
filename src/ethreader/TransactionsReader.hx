package ethreader;

import ethreader.DecodedTransaction;
import parity.Api;
import parity.api.Transport.Http;
import parity.Contract;
import parity.Abi;

using Lambda;


//caching
import js.node.Fs;


//TODO get rid of that by being able to acces parity.js util directly
class FakeTransport extends parity.api.Transport{
	public function new(){}

	@:keep
	public function execute(){

	}

	@:keep
	public function addMiddleware(d : Dynamic){
		
	}
}


typedef TransactionsCache = {
	transactions : Array<DecodedTransaction>,
	timestamp : Float,
	lastBlock : Float
}

class TransactionsReader{
	
	var _abiMap : AbiMap;
	var _address : String;
	var _ethReader : EthReader;
	var _networkId : String;

	static var _folder : String;

	//TODO get rid of that by being able to acces parity.js util directly
	static var _api : Api;
	static public function __init__(){
		var transport = new FakeTransport();
		_api = new Api(transport);

		_folder = untyped js.node.Os.homedir() + "/.ethreader";
		if (!Fs.existsSync(_folder)){
		    Fs.mkdirSync(_folder);
		}
	}

	public function new(address : String, ethReader : EthReader){
		_abiMap = null;
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
				try{
					var dynamicAccess : haxe.DynamicAccess<AbiFunction> = haxe.Json.parse(data);
					_abiMap = new Map();
					for(key in dynamicAccess.keys()){
						_abiMap[key] = dynamicAccess[key];
					}
					callback(null);
				}catch(e : Dynamic){
					callback("error parsing data");
				}
			}
		});

		
	}

	function _save_abi_to_cache(callback : Error -> Void){
		var dynamicAccess : haxe.DynamicAccess<AbiFunction> = {};
		for(key in _abiMap.keys()){
			dynamicAccess[key] = _abiMap[key];
		}
		saveToFile(_folder + "/" + _networkId  + "_" + _address+".abi",haxe.Json.stringify(dynamicAccess), callback);
	}

	function _collect_abi(startBlock : Int, endBlock : Int, callback : Error -> Array<DecodedTransaction> -> Void){
		if(_abiMap == null){
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
		_ethReader.getAbi(_address, function(error, abi){
			if(error != null){
				callback(error);
			}else{
				trace("converting abi to abimap");
				var methodAbiMap = new Map<String,AbiFunction>();
				for(methodAbi in abi){
					methodAbiMap[methodAbi.name] = methodAbi;
				}
				var contract = _api.newContract(abi);
				_abiMap = new AbiMap();
				contract.functions.foreach(function(fn){
					if(fn != null && fn.signature != null){
						_abiMap["0x" + fn.signature] = methodAbiMap[fn.name];
					}
					return true;
				});

				_save_abi_to_cache(function(error){
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
			var cacheDuration = 60 * 5; //TODO
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
						trace("decoding " +  transactions.length + " transactions ...");
						for(transaction in transactions){
							if(transaction.input == "0x"){
								continue;
							}
							var callData = _api.util.decodeCallData(transaction.input);
							var methodAbi = _abiMap[callData.signature];
							if(methodAbi != null){
								var inputArray = _api.util.decodeMethodInput(methodAbi,callData.paramdata);
								var decoded_input : Dynamic = {};
								for(j in 0...inputArray.length){
									decoded_input[methodAbi.inputs[j].name] = inputArray[j]; //TODO check array of uint32 and bytes32
								}
								// transaction.input_array = inputArray;
								transaction.decoded_call = {"name":methodAbi.name, "input" : decoded_input};
							}else{
								trace("no method with signature " + callData.signature);
							}
						}

						var extraTransactions = false;
						for(transaction in transactions){
							extraTransactions = true;
							prevTransactions.push(transaction);
						}

						transactions = prevTransactions.filter(function(tx){
							return tx.blockNumber >= startBlock;
						});
						

						if(extraTransactions){
							_save_transactions_to_cache(prevTransactions,function(error){
								callback(null,transactions);
							});
						}else{
							callback(null,transactions);
						}
						
						
					}
				});
			}else{
				var transactions = transactionsCache.transactions.filter(function(tx){
						return tx.blockNumber >= startBlock;
					});
				callback(null,transactions);
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