package ethreader;

import web3.Web3;

import parity.Api;
import parity.api.Transport.Http;
import parity.Contract;
import parity.Abi;

using Lambda;

class TransactionDecoder{
	//TODO get rid of that by being able to acces parity.js util directly
	static var _api : Api;
	static public function __init__(){
		_api = new Api(new Http(""));
		untyped _api.transport._connectTimeout = -1;
	}

	static var abiMapMap : Map<String, Map<String,AbiFunction>> = new Map();

	static public function hasABI(address : String) : Bool{
		return abiMapMap[address] != null;
	}

	static public function addABI(address : String, abiString : String){
		if(abiString != null && abiString != ""){
			var abi : Abi = null;
			try{
				abi = haxe.Json.parse(abiString);
			}catch(e : Dynamic){
				return;
			}
			var methodAbiMap = new Map<String,AbiFunction>();
			for(methodAbi in abi){
				methodAbiMap[methodAbi.name] = methodAbi;
			}
			var contract = _api.newContract(abi);
			var abiMap = new Map<String,AbiFunction>();
			contract.functions.foreach(function(fn){
				if(fn != null && fn.signature != null){
					abiMap["0x" + fn.signature] = methodAbiMap[fn.name];
				}
				return true;
			});

			abiMapMap[address] = abiMap;
		}
	}

	public static function decodeTransaction(transaction : ExtendedTransaction) : DecodedTransaction{
		var decodedTransaction  = {
			hash : transaction.hash,
			nonce : transaction.nonce,
			blockHash : transaction.blockHash,
			blockNumber : transaction.blockNumber,
			transactionIndex : transaction.transactionIndex,
			from : transaction.from,
			to : transaction.to,
			value : transaction.value,
			gasPrice : transaction.gasPrice,
			gas : transaction.gas,
			input : transaction.input,

			blockTimestamp : transaction.blockTimestamp,
			isError : transaction.isError,
			cumulativeGasUsed : transaction.cumulativeGasUsed,
			gasUsed : transaction.gasUsed,
			contractAddress : transaction.contractAddress,
			logs : transaction.logs,

			decoded_call : null
		}

		decodeTransactionInPlace(decodedTransaction);

		return decodedTransaction;
	}


		//Does not make sense with caching
		// Reflect.deleteField(transaction,"confirmations"); //TODO etherscan reader
		

	public static function decodeTransactionInPlace(transaction : DecodedTransaction) : Void{

		if(transaction.to == null || transaction.to == "" || transaction.input == "0x" || transaction.input == "" || transaction.input == null){
			return;
		}

		var callData = _api.util.decodeCallData(transaction.input);
		var methodAbi = abiMapMap[transaction.to][callData.signature];
		if(methodAbi != null){
			var inputArray = [];
			try{
				inputArray = _api.util.decodeMethodInput(methodAbi,callData.paramdata);
			}catch(e : Dynamic){
				trace(e,methodAbi,callData.paramdata);
			}
			 
			var decoded_input : Dynamic = {};
			for(j in 0...inputArray.length){
				
				
				#if debug
				//trace(methodAbi.inputs[j].type + " : " + haxe.Json.stringify(inputArray[j]));
				#end
				
				var type = methodAbi.inputs[j].type;
				var value : Dynamic = if(type == "bytes32"){
					var s = "0x";
					for(v in cast(inputArray[j],Array<Dynamic>)){
						s += StringTools.hex(v,2);
					}					
					s;
				}else if(type.indexOf("[]") >= 0){
					var array = new Array<Dynamic>();
					for(v in cast(inputArray[j],Array<Dynamic>)){
						array.push(v._value);
					}
					array;
				}else{
					haxe.Json.parse(haxe.Json.stringify(inputArray[j]));
				}

				//TODO more
				if(type == "uint8" 
				|| type == "uint16"
				|| type == "uint32"
				|| type == "uint64"
				|| type == "int8"
				|| type == "int16"
				|| type == "int32"
				|| type == "int64"
				){
					value = Std.parseFloat(value);
				}

				trace(methodAbi.inputs[j].name,type,value);

				decoded_input[methodAbi.inputs[j].name] = value;
			}
			
			transaction.decoded_call = {"name":methodAbi.name, "input" : decoded_input};
			Reflect.deleteField(transaction,"input");
			
		}else{
			trace("no method with signature " + callData.signature);
		}
	}
}