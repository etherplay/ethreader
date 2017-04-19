package ethreader;

typedef Transaction = {
	blockNumber : Float,
	timeStamp : Float,
	input : Dynamic, //TODO
	?decoded_call : Dynamic //TODO
}