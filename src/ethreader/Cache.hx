package ethreader;


typedef TransactionsCache = {
	transactions : Array<DecodedTransaction>,
	timestamp : Float,
	lastBlock : Float
}

class Cache{

	static var _folder : String;
	static public function __init__(){
		_folder = untyped js.node.Os.homedir() + "/.ethreader";
		Util.ensureFolderExists(_folder);
	}

	static public function get_abi_from_cache(networkId : String, address : String, callback : Error -> String -> Void){

		Util.getFromFile(_folder + "/" + networkId  + "_" + address+".abi",function(error,data){
			if(error != null){
				callback(error,null);
			}else if(data == ""){
				callback("nothing in cache",null);
			}else{
				
				callback(null, data);
			}
		});

		
	}

	static public function save_abi_to_cache(networkId : String, address : String, data : String, callback : Error -> Void){
		Util.saveToFile(_folder + "/" + networkId  + "_" + address+".abi",data, callback);
	}


	static public function get_transactions_from_cache(networkId : String, address : String, type : String, callback : Error -> TransactionsCache -> Void){
		Util.getFromFile(_folder + "/" + type + "_" + networkId  + "_"  + address+".tx",function(error,data){
			if(error != null){
				callback(error,null);
			}else if(data == ""){
				callback("nothing in cache",null);
			}else{
				callback(null,haxe.Json.parse(data));//todo try catch
			}
		});
	}

	static public function save_transactions_to_cache(networkId : String, address : String, type : String, transactions : Array<DecodedTransaction>, callback : Error -> Void){
		trace("saving " + transactions.length + " transactions");
		Util.saveToFile(_folder + "/" + type + "_" + networkId  + "_"  + address+".tx",haxe.Json.stringify({
			transactions : transactions,
			timestamp : Std.int(haxe.Timer.stamp()),
			lastBlock : transactions[transactions.length-1].blockNumber //TODO check length
		}), callback);
	}
}