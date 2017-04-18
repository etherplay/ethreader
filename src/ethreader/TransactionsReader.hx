package ethreader;

import parity.Api;
import parity.api.Transport.Http;
import parity.Contract;
import parity.Abi;

using Lambda;


//caching
import js.node.Fs;

class TransactionsReader{
	
	var _abiMap : AbiMap;
	var _address : String;
	var _ethReader : EthReader;

	//TODO get rid of that by being able to acces parity.js util directly
	static var _api : Api;
	static public function __init__(){
		var transport = new Http('localhost:8545');
		_api = new Api(transport);
	}

	public function new(address : String, ethReader : EthReader){
		_abiMap = null;
		_address = address;
		_ethReader = ethReader;
	}

	public function collect(callback : Error -> Array<DecodedTransaction> -> Void, startBlock : Int = 0, endBlock : Int = 2147483647){ //TODO 64bit or string ?
		if(_abiMap == null){
			trace("getting abi from ethreader...");
			_ethReader.getAbi(_address, function(error, abi){
				if(error != null){
					callback(error,null);
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
					_collect(startBlock,endBlock,callback);
				}
			});		
		}else{
			_collect(startBlock,endBlock,callback);
		}
	}

	function _collect(startBlock : Int, endBlock : Int, callback : Error -> Array<DecodedTransaction> -> Void){
		trace("getting transactions from ethreader...");
		_ethReader.getTransactions(_address, startBlock, endBlock, function(error, transactions){
			if(error != null){
				callback(error,null);
			}else{
				trace("decoding...");
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
				callback(null,transactions);
			}
		});
	}


















	function getFromFile(filename : String, callback : Dynamic -> String -> Void){
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