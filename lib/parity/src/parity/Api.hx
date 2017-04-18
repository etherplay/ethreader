package parity;

import parity.api.Transport;

@:jsRequire("@parity/parity.js", "Api")
extern class Api{
	public function new(transport : Transport);

	public function newContract(abi : Abi) : Contract;

	public var util : Util;
}

