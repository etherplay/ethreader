package ethreader;

using Lambda;

import ethreader.Cache;

class TransactionsReader{
	
	var _address : String;
	var _ethReader : EthReader;
	var _networkId : String;

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

	

	function _collect_abi(startBlock : Int, endBlock : Int, callback : Error -> Array<DecodedTransaction> -> Void){
		if(!TransactionDecoder.hasABI(_address)){
			trace("getting abi from cache...");
			Cache.get_abi_from_cache(_networkId, _address, function(error, abi){
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
					TransactionDecoder.addABI(_address, abi);
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
				Cache.save_abi_to_cache(_networkId, _address, data, function(error){
					callback(error);
				});
			}
		});		
	}

	

	function _collect(startBlock : Int, endBlock : Int, callback : Error -> Array<DecodedTransaction> -> Void){
		trace("getting transactions from cache...");
		Cache.get_transactions_from_cache(_networkId, _address, _ethReader.type, function(error, transactionsCache){
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
							Cache.save_transactions_to_cache(_networkId, _address, _ethReader.type, prevTransactions,function(error){
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
				Cache.save_transactions_to_cache(_networkId, _address, _ethReader.type, transactionsCache.transactions,function(error){
					callback(null,transactionsToOutput);
				});
				#else
				callback(null,transactionsToOutput);
				#end
			}
		});
		
	}

}