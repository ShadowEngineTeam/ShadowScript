package hscript.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class DefinesMacro {
	macro public static function buildDefaultDefines():Expr {
		var defines = Context.getDefines();
		var exprs:Array<Expr> = [];
		for (k => v in defines) {
			var value = v != null ? v : "1";
			exprs.push(macro m.set($v{k}, $v{value}));
		}
		return macro {
			var m = new Map<String, Dynamic>();
			$b{exprs};
			m;
		}
	}
}
