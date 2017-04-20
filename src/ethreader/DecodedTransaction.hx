package ethreader;

typedef DecodedTransaction = { 
	> Transaction,
	decoded_call : {
		name: String,
		input : haxe.DynamicAccess<Dynamic>
	}
}