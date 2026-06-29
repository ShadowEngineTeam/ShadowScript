import haxe.ds.EnumValueMap;
import haxe.ds.Option;
import hscript.Macro;
import hscript.Tools;
import hscript.Async;
import hscript.Printer;
import hscript.Checker;
import hscript.Parser;
import hscript.Interp;
import haxe.unit.*;

class TestHScript extends TestCase {
	function assertScript(x,v:Dynamic,?vars : Dynamic, allowTypes=false, ?pos:haxe.PosInfos) {
		var p = new hscript.Parser();
		p.allowTypes = allowTypes;
		var program = p.parseString(x);
		var bytes = hscript.Bytes.encode(program);
		program = hscript.Bytes.decode(bytes);
		var interp = new hscript.Interp();
		if( vars != null )
			for( v in Reflect.fields(vars) )
				interp.variables.set(v,Reflect.field(vars,v));
		var ret : Dynamic = interp.execute(program);
		assertEquals(v, ret, pos);
	}

	function test():Void {
		assertScript("0",0);
		assertScript("0xFF", 255);
		#if !(php || python)
			assertScript("0xBFFFFFFF", 0xBFFFFFFF);
			assertScript("0x7FFFFFFF", 0x7FFFFFFF);
		#end
		assertScript("-123",-123);
		assertScript("- 123",-123);
		assertScript("1.546",1.546);
		assertScript(".545",.545);
		assertScript("'bla'","bla");
		assertScript("null",null);
		assertScript("true",true);
		assertScript("false",false);
		assertScript("1 == 2",false);
		assertScript("1.3 == 1.3",true);
		assertScript("5 > 3",true);
		assertScript("0 < 0",false);
		assertScript("-1 <= -1",true);
		assertScript("1 + 2",3);
		assertScript("~545",-546);
		assertScript("'abc' + 55","abc55");
		assertScript("'abc' + 'de'","abcde");
		assertScript("-1 + 2",1);
		assertScript("1 / 5",0.2);
		assertScript("3 * 2 + 5",11);
		assertScript("3 * (2 + 5)",21);
		assertScript("3 * 2 // + 5 \n + 6",12);
		assertScript("3 /* 2\n */ + 5",8);
		assertScript("[55,66,77][1]",66);
		assertScript("var a = [55]; a[0] *= 2; a[0]",110);
		assertScript("x",55,{ x : 55 });
		assertScript("var y = 33; y",33);
		assertScript("{ 1; 2; 3; }",3);
		assertScript("{ var x = 0; } x",55,{ x : 55 });
		assertScript("o.val",55,{ o : { val : 55 } });
		assertScript("o.val",null,{ o : {} });
		assertScript("var a = 1; a++",1);
		assertScript("var a = 1; a++; a",2);
		assertScript("var a = 1; ++a",2);
		assertScript("var a = 1; a *= 3",3);
		assertScript("a = b = 3; a + b",6);
		assertScript("add(1,2)",3,{ add : function(x,y) return x + y });
		assertScript("a.push(5); a.pop() + a.pop()",8,{ a : [3] });
		assertScript("if( true ) 1 else 2",1);
		assertScript("if( false ) 1 else 2",2);
		assertScript("var t = 0; for( x in [1,2,3] ) t += x; t",6);
		assertScript("var a = new Array(); for( x in 0...5 ) a[x] = x; a.join('-')","0-1-2-3-4");
		assertScript("(function(a,b) return a + b)(4,5)",9);
		assertScript("var y = 0; var add = function(a) y += a; add(5); add(3); y", 8);
		assertScript("var a = [1,[2,[3,[4,null]]]]; var t = 0; while( a != null ) { t += a[0]; a = a[1]; }; t",10);
		assertScript("var a = false; do { a = true; } while (!a); a;",true);
		assertScript("var t = 0; for( x in 1...10 ) t += x; t", 45);
		assertScript("var t = 0; for( x in new IntIterator(1,10) ) t +=x; t", 45);
		assertScript("var x = 1; try { var x = 66; throw 789; } catch( e : Dynamic ) e + x",790);
		assertScript("var x = 1; var f = function(x) throw x; try f(55) catch( e : Dynamic ) e + x",56);
		assertScript("var i=2; if( true ) --i; i",1);
		assertScript("var i=0; if( i++ > 0 ) i=3; i",1);
		assertScript("var a = 5/2; a",2.5);
		assertScript("{ x = 3; x; }", 3);
		assertScript("{ x : 3, y : {} }.x", 3);
		assertScript("function bug(){ \n }\nbug().x", null);
		assertScript("1 + 2 == 3", true);
		assertScript("-2 == 3 - 5", true);
		assertScript("var x=-3; x", -3);
		assertScript("var a:Array<Dynamic>=[1,2,4]; a[2]", 4, null, true);
		assertScript("/**/0", 0);
		assertScript("x=1;x*=-2", -2);
		assertScript("var f = x -> x + 1; f(3)", 4);
		assertScript("var f = () -> 55; f()", 55);
		assertScript("var f = (x) -> x + 1; f(3)", 4);
		assertScript("var f = (x:Int) -> x + 1; f(3)", 4);
		assertScript("var f = (x,y) -> x + y; f(3,1)", 4);
		assertScript("var f = (x,y:Int) -> x + y; f(3,1)", 4);
		assertScript("var f = (x:Int,y:Int) -> x + y; f(3,1)", 4);
		assertScript("var f:Int->Int->Int = (x:Int,y:Int) -> x + y; f(3,1)", 4, null, true);
		assertScript("var f:(x:Int, y:Int)->Int = (x:Int,y:Int) -> x + y; f(3,1)", 4, null, true);
		assertScript("var f:(x:Int)->(y:Int, z:Int)->Int = (x:Int) -> (y:Int, z:Int) -> x + y + z; f(3)(1, 2)", 6, null, true);
		assertScript("var f:(x:Int)->(Int, Int)->Int = (x:Int) -> (y:Int, z:Int) -> x + y + z; f(3)(1, 2)", 6, null, true);
		assertScript("var a = 10; var b = 5; a - -b", 15);
		assertScript("var a = 10; var b = 5; a - b / 2", 7.5);
	}

	function testMap():Void {
		var objKey = { ok:true };
		var vars = {
			stringMap: ["foo" => "Foo", "bar" => "Bar"],
			intMap:[100 => "one hundred"],
			objKey: objKey,
			objMap:[objKey => "ok"],
			enumKey:Option.Some("some"),
			enumMap:new EnumValueMap<Option<String>, String>(),
			stringIntMap: ["foo" => 100]
		}
		vars.enumMap.set(vars.enumKey, "ok");

		assertScript('stringMap["foo"]', "Foo", vars);
		assertScript('intMap[100]', "one hundred", vars);
		assertScript('objMap[objKey]', "ok", vars);
		assertScript('enumMap[enumKey]', "ok", vars);
		assertScript('stringMap["a"] = "A"; stringMap["a"]', "A", vars);
		assertScript('intMap[200] = objMap[{foo:false}] = enumMap[enumKey] = "A"', "A", vars);
		assertEquals('A', vars.intMap[200]);
		assertEquals('A', vars.enumMap.get(vars.enumKey));
		for (key in vars.objMap.keys()) {
			if (key != objKey) {
				assertEquals(false, (key:Dynamic).foo);
				assertEquals('A', vars.objMap[key]);
			}
		}

		assertScript('
			var keys = [];
			for (key in stringMap.keys()) keys.push(key);
			keys.join("_");
		', {
			var keys = [];
			for (key in vars.stringMap.keys()) keys.push(key);
			keys.join("_");
		}, vars);
		assertScript('stringMap.remove("foo"); stringMap.exists("foo");', false, vars);
		assertScript('stringMap["foo"] = "a"; stringMap["foo"] += "b"', 'ab', vars);
		assertEquals('ab', vars.stringMap['foo']);
		assertScript('stringIntMap["foo"]++', 100, vars);
		assertEquals(101, vars.stringIntMap['foo']);
		assertScript('++stringIntMap["foo"]', 102, vars);
		assertScript('var newMap = ["foo"=>"foo"]; newMap["foo"];', 'foo', vars);
		#if (!php || (haxe_ver >= 3.3))
		assertScript('var newMap = [enumKey=>"foo"]; newMap[enumKey];', 'foo', vars);
		#end
		assertScript('var newMap = [{a:"a"}=>"foo", objKey=>"bar"]; newMap[objKey];', 'bar', vars);
	}

	function testPatternMatching():Void {
		// Literal match
		assertScript("switch(2) { case 1: 10; case 2: 20; }", 20);
		// Wildcard
		assertScript("switch('hello') { case _: 99; }", 99);
		// Variable binding
		assertScript("switch(42) { case x: x + 1; }", 43);
		// Array destructuring
		assertScript("switch([1,2,3]) { case [a,b,c]: a + b + c; }", 6);
		// Array with wildcard
		assertScript("switch([10,20,30]) { case [a,_,_]: a; }", 10);
		// Nested array pattern
		assertScript("switch([[1,2],[3,4]]) { case [[a,b],_]: a + b; }", 3);
		// Object pattern
		assertScript("switch({x:1,y:2}) { case {x:a,y:b}: a + b; }", 3);
		// Guard with binding
		assertScript("switch(10) { case x if x > 5: x * 2; }", 20);
		// Guard no match
		assertScript("switch(2) { case x if x > 5: 100; case _: 0; }", 0);
		// Guard match on second
		assertScript("switch(2) { case x if x > 5: 100; case x: x; }", 2);
		// Or pattern
		assertScript("switch(3) { case 1|3|5: true; case _: false; }", true);
		// Or pattern no match
		assertScript("switch(2) { case 1|3|5: true; case _: false; }", false);
		// String literal match
		assertScript("switch('foo') { case 'bar': 0; case 'foo': 1; case _: 2; }", 1);
		// First-match semantics
		assertScript("switch(1) { case 1: 10; case 1: 20; }", 10);
	}

	function testTypeParams():Void {
		// Type parameter with constraint (consumed at parse time, no runtime effect)
		assertScript("var f = function<T:Int>(x:T):T return x; f(5)", 5, null, true);
		assertScript("var f = function<T:Float>(x:T):T return x; f(1.5)", 1.5, null, true);
		// Multiple type params
		assertScript("var f = function<T,U>(x:T,y:U):T return x; f(1,'a')", 1, null, true);
	}

	function testAbstract():Void {
		// Basic abstract with constructor, verify __value__ is set
		assertScript("
			abstract MyInt(Int) {
				public function new(v) __value__ = v;
			}
			var x = new MyInt(42);
			x.__value__;
		", 42);
	}

	function testPatternAdvanced():Void {
		// Empty array match
		assertScript("switch([]) { case []: 1; case _: 0; }", 1);
		// Bool match
		assertScript("switch(false) { case false: 1; case true: 2; }", 1);
		// Null match
		assertScript("switch(null) { case null: 1; case _: 0; }", 1);
		// Float match
		assertScript("switch(1.5) { case 1.5: 1; case _: 0; }", 1);
		// Array in object pattern
		assertScript("switch({a:[1,2]}) { case {a:[x,y]}: x + y; }", 3);
		// Object in array pattern
		assertScript("switch([{x:1},{x:2}]) { case [{x:a},{x:b}]: a + b; }", 3);
		// Guard with or-pattern
		assertScript("switch(5) { case x if x > 10: 100; case 1|3|5: 1; case _: 0; }", 1);
		// Default case
		assertScript("switch(99) { case 1: 0; case _: 1; }", 1);
		// No default, no match
		assertScript("switch(99) { case 1: 10; }", null);
		// Multiple guards
		assertScript("switch(15) { case x if x > 0 && x < 10: 1; case x if x >= 10 && x < 20: 2; case _: 0; }", 2);
		// Variable binding preserved in body
		assertScript("switch('world') { case x: 'hello ' + x; }", "hello world");
		// Array with two elements only (not three)
		assertScript("switch([1,2,3]) { case [a,b]: a + b; case _: 0; }", 0);
		// Exact array length mismatch
		assertScript("switch([1]) { case [a,b]: 0; case [a]: a; }", 1);
	}

	function testAbstractAdvanced():Void {
		// Two different abstracts
		assertScript("
			abstract A(Int) {
				public function new(v) __value__ = v;
			}
			abstract B(String) {
				public function new(v) __value__ = v;
			}
			var a = new A(10);
			var b = new B('hi');
			a.__value__;
		", 10);
		// Two abstract instances
		assertScript("
			abstract Box(Int) {
				public function new(v) __value__ = v;
			}
			var a = new Box(3);
			var b = new Box(4);
			a.__value__ + b.__value__;
		", 7);
	}

	function testMetadataAdvanced():Void {
		// Metadata with string arg
		assertScript("@:deprecated('use newFunc') var x = 1; x", 1);
		// Metadata on expression (no space ambiguity with args)
		assertScript("@:keep 1 + 2", 3);
		// Metadata chained
		assertScript("@:a @:b @:c var x = 42; x", 42);
		// Metadata on function expression
		assertScript("var f = @:keep function() return 99; f()", 99);
	}

	function testCrossFeature():Void {
		// Pattern matching with metadata-annotated values
		assertScript("@:keep switch(42) { case x: x; }", 42);
		// Abstract with pattern matching (direct __value__ access)
		assertScript("
			abstract Box(Int) {
				public function new(v) __value__ = v;
			}
			var items = [new Box(1), new Box(2)];
			switch(items) {
				case [a,b]: a.__value__ + b.__value__;
				case _: 0;
			}
		", 3);
		// Type params with pattern matching
		assertScript("
			var pair = function<T,U>(a:T,b:U):Array<Dynamic> return [a,b];
			switch(pair(1,'two')) {
				case [x,y]: Std.string(x) + y;
			}
		", "1two", null, true);
	}

	function testAbstractMethods():Void {
		// Method with single param
		assertScript("
			abstract Calc(Int) {
				public function new(v) __value__ = v;
				public function triple(v) v * 3;
			}
			var c = new Calc(5);
			c.triple(4);
		", 12);
		// Method with multiple params
		assertScript("
			abstract Calc(Int) {
				public function new(v) __value__ = v;
				public function add(a,b) a + b;
			}
			var c = new Calc(0);
			c.add(10, 20);
		", 30);
		// Two instances calling methods
		assertScript("
			abstract Box(Int) {
				public function new(v) __value__ = v;
				public function mul(a) a * 2;
			}
			var a = new Box(1);
			var b = new Box(2);
			a.mul(5) + b.mul(10);
		", 30);
		// Method on different abstracts
		assertScript("
			abstract A(Int) {
				public function new(v) __value__ = v;
				public function ident(v) v;
			}
			abstract B(String) {
				public function new(v) __value__ = v;
				public function greet(v) 'hello ' + v;
			}
			var a = new A(99);
			var b = new B('world');
			a.ident(42) == 42 && b.greet('x') == 'hello x';
		", true);
	}

	function testMetadataUtilities():Void {
		// Metadata stored and retrievable via getMetas/getMeta
		var p = new Parser();
		var interp = new Interp();
		var ast = p.parseString("@:keep @:deprecated('v1') {x: 1}");
		var obj = interp.execute(ast);
		var metas = Interp.getMetas(obj);
		assertEquals(2, metas.length);
		assertEquals("deprecated", metas[0].name);
		assertEquals("keep", metas[1].name);
		assertEquals("v1", metas[0].params[0]);

		var params = Interp.getMeta(obj, "deprecated");
		assertEquals("v1", params[0]);

		assertEquals(null, Interp.getMeta(obj, "nonexistent"));

		// Metadata on null/primitive is silently dropped
		p = new Parser();
		interp = new Interp();
		ast = p.parseString("@:keep 42;");
		var n = interp.execute(ast);
		assertEquals(null, Interp.getMetas(n));
	}

	static function main() {
		#if ((haxe_ver < 4) && php)
		// uncaught exception: The each() function is deprecated. This message will be suppressed on further calls (errno: 8192)
		// in file: /Users/travis/build/andyli/hscript/bin/lib/Type.class.php line 178
		untyped __php__("error_reporting(E_ALL ^ E_DEPRECATED);");
		#end

		var runner = new TestRunner();
		runner.add(new TestHScript());
		var succeed = runner.run();

		#if sys
			Sys.exit(succeed ? 0 : 1);
		#elseif flash
			flash.system.System.exit(succeed ? 0 : 1);
		#else
			if (!succeed)
				throw "failed";
		#end
	}

}