package ethreader;


interface EthReader{
	public var type : String;
	public function getNetworkId(callback : Error -> String -> Void):Void;
	public function getAbi(address : String, callback : Error -> String -> Void):Void;
	public function getTransactions(address : String, startBlock : Int, endBlock : Int, callback : Error -> Array<ExtendedTransaction> -> Void):Void;
}