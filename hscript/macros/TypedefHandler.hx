package hscript.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

using StringTools;

class TypedefHandler {
	public static function init() {
		#if HSCRIPT_TYPEDEF_SUPPORT
		#if !display
		if(Context.defined("display")) return;
		Context.onGenerate(onGenerate);
		#end
		#end
	}

	#if HSCRIPT_TYPEDEF_SUPPORT
	public static var modifiedTypedefs:Array<String> = [];

	static function onGenerate(types:Array<Type>) {
		var allowed = Config.ALLOWED_TYPEDEFS;
		var disallowed = Config.DISALLOW_TYPEDEFS;

		for(t in types) {
			switch(t) {
				case TType(ref, _):
					var td = ref.get();
					if (td == null) continue;

					var packStr = td.pack.join(".");

					if (allowed != null && allowed.length > 0) {
						var matches = false;
						for(allowedPack in allowed) {
							if (packStr == allowedPack || packStr.startsWith(allowedPack + ".")) {
								matches = true;
								break;
							}
						}
						if (!matches) continue;
					} else if (disallowed != null && disallowed.length > 0) {
						var matches = false;
						for(disallowedPack in disallowed) {
							if (packStr == disallowedPack || packStr.startsWith(disallowedPack + ".")) {
								matches = true;
								break;
							}
						}
						if (matches) continue;
					} else {
						continue;
					}

					var underlyingType = TypeTools.toComplexType(td.type);
					if (underlyingType == null) continue;
					processTypedef(td, underlyingType);
				default:
			}
		}
	}

	static function processTypedef(td:DefType, underlyingType:ComplexType) {
		var path:TypePath = switch(underlyingType) {
			case TPath(p): p;
			default: return;
		}

		var fqName = td.pack.join(".") + "." + td.name;
		if (modifiedTypedefs.contains(fqName)) return;
		modifiedTypedefs.push(fqName);

		var classRef = macro $p{path.pack.concat([path.name])};

		var shadowClass:TypeDefinition = {
			pack: td.pack.copy(),
			name: td.name + "_HSC",
			pos: Context.currentPos(),
			meta: [
				{name: ":dox", params: [macro hide], pos: Context.currentPos()},
				{name: ":noCompletion", params: [], pos: Context.currentPos()},
			],
			params: null,
			kind: TDClass(null, [
				{name: "IHScriptCustomConstructor", pack: ["hscript"], params: []}
			], false, false, false),
			fields: [
				{
					name: "new",
					pos: Context.currentPos(),
					meta: [],
					kind: FFun({
						ret: null,
						params: [],
						expr: macro {},
						args: []
					}),
					doc: null,
					access: [APublic]
				},
				{
					name: "hnew",
					pos: Context.currentPos(),
					meta: [],
					kind: FFun({
						ret: macro: Dynamic,
						params: [],
						expr: macro Type.createInstance($e{classRef}, args),
						args: [
							{
								name: "args",
								opt: false,
								meta: [],
								type: macro: Array<Dynamic>
							}
						]
					}),
					doc: null,
					access: [APublic]
				}
			],
			doc: null
		};

		var packImport:ImportExpr = {
			path: [for(m in td.pack) { name: m, pos: Context.currentPos() }],
			mode: INormal
		};
		var haxeImport:ImportExpr = {
			path: [{name: "Type", pos: Context.currentPos()}],
			mode: INormal
		};
		Context.defineModule(td.pack.join(".") + "." + td.name, [shadowClass], [packImport, haxeImport]);
	}
	#end
}
#end
