package parity;

import parity.Abi;

extern class Util{
	public function decodeCallData(input : Dynamic) : Dynamic;//TODO
	public function decodeMethodInput(abi : AbiFunction, paramData : Dynamic) : Array<Dynamic>; //TODO
}