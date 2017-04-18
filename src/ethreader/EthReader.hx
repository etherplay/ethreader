package ethreader;


interface EthReader{
	public function newTransactionReader(address : String) : ethreader.TransactionsReader;
	public function getAbi(address : String, callback : Error -> Abi -> Void):Void;
	public function getTransactions(address : String, startBlock : Int, endBlock : Int, callback : Error -> Array<Transaction> -> Void):Void;
}