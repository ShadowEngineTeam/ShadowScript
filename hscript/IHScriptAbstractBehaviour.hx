package hscript;

interface IHScriptAbstractBehaviour extends IHScriptCustomBehaviour {
	public var hasOp:Bool;
	public var hasArr:Bool;
	public var hasResolve:Bool;
	public var hasCall:Bool;
	// @:op(A * B), @:op(A++), etc...
	public function hop(kind:String, a:Dynamic, ?b:Dynamic):Dynamic;

	public function harrayget(key:Dynamic):Dynamic;
	public function harrayset(key:Dynamic, val:Dynamic):Dynamic;

	// @:resolve
	public function hresolve(name:String):Dynamic;

	// @:callable
	public function hcall(args:Array<Dynamic>):Dynamic;
}