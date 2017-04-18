package parity;

extern class ContractFunction{
	public var signature : String;
	public var name : String;
}

extern class Contract{
	public var functions : Array<ContractFunction>;
}