package parity;

typedef Abi = Array<AbiFunction>;

typedef AbiFunction = {
	name : String,
	type : String,
	inputs : Dynamic //TODO
}