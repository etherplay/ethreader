package parity.api;

@:jsRequire("@parity/parity.js", "Api.Transport")
extern class Transport{

}

@:jsRequire("@parity/parity.js", "Api.Transport.Http")
extern class Http extends Transport{
	public function new(url : String);
}