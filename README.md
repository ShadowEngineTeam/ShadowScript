ShadowScript
=======

A fork of hscript-improved, originally created to add the `SScript` class (ver 7.7.0) for use in Shadow Engine.

Since then this fork has grown well past that: full pattern matching in `switch` (destructuring, guards, or-patterns), standalone `abstract` declarations, type parameter constraints, wildcard imports (`import pkg.*;`), custom-class metadata support (`@:to`/`@:from`/`@:noUsing`/`@:forward`/`@:resolve`/`@:callable`/`@:const`/`@:deprecated`/`@:structInit`), abstract-style operator/array-access overloading for scripted and host objects, full `Bytes` serialization for class/interface/typedef/abstract expressions, and various bugfixes to the static-extension (`using`) and assignment-operator paths. See [Features](docs/FEATURES.md) for the full list, and [CHANGES](#changes-in-this-fork) below for what's specific to ShadowScript versus upstream hscript-improved.

This fork is licensed under MIT; see the original hscript-improved README below.

hscript-improved
=======

- [Features](docs/FEATURES.md)

How to install
```
haxelib git hscript-improved https://github.com/ShadowEngineTeam/ShadowScript.git
```

To enable custom classes support you have to do this in project.xml

```xml
<define name="CUSTOM_CLASSES" />
```

or set this in build.hxml

```hxml
-D CUSTOM_CLASSES
```

Current Custom Class Limitations :

- You cannot create custom classes that extends a typed class (those ones that has `<T>`), this will be implemented in the future.

-----------

Parse and evalutate Haxe expressions.


In some projects it's sometimes useful to be able to interpret some code dynamically, without recompilation.

Haxe script is a complete subset of the Haxe language.

It is dynamically typed but allows all Haxe expressions apart from type (class,enum,typedef) declarations.

Usage
-----

```haxe
var expr = "var x = 4; 1 + 2 * x";
var parser = new hscript.Parser();
var ast = parser.parseString(expr);
var interp = new hscript.Interp();
trace(interp.execute(ast));
```

In case of a parsing error an `hscript.Expr.Error` is thrown. You can use `parser.line` to check the line number.

You can set some globaly accessible identifiers by using `interp.variables.set("name",value)`

Example
-------

Here's a small example of Haxe Script usage :
```haxe
var script = "
	var sum = 0;
	for( a in angles )
		sum += Math.cos(a);
	sum; 
";
var parser = new hscript.Parser();
var program = parser.parseString(script);
var interp = new hscript.Interp();
interp.variables.set("Math",Math); // share the Math class
interp.variables.set("angles",[0,1,2,3]); // set the angles list
trace( interp.execute(program) ); 
```

This will calculate the sum of the cosines of the angles given as input.

Haxe Script has not been really optimized, and it's not meant to be very fast. But it's entirely crossplatform since it's pure Haxe code (it doesn't use any platform-specific API).

Advanced Usage
--------------

When compiled with `-D hscriptPos` you will get fine error reporting at parsing time.

You can subclass `hscript.Interp` to override behaviors for `get`, `set`, `call`, `fcall` and `cnew`.

You can add more binary and unary operations to the parser by setting `opPriority`, `opRightAssoc` and `unops` content.

You can use `parser.allowJSON` to allow JSON data.

You can use `parser.allowTypes` to parse types for local vars, exceptions, function args and return types. Types are ignored by the interpreter.

You can use `parser.allowMetadata` to parse metadata before expressions on in anonymous types. Metadata are ignored by the interpreter.

You can use `new hscript.Macro(pos).convert(ast)` to convert an hscript AST to a Haxe macros one.

You can use `hscript.Checker` in order to type check and even get completion, using `haxe -xml` output for type information.

Limitations
-----------

Compared to Haxe, limitations are :

- `switch` construct is supported but not pattern matching (no variable capture, we use strict equality to compare `case` values and `switch` value)
- only one variable declaration is allowed in `var`
- the parser supports optional types for `var` and `function` if `allowTypes` is set, but the interpreter ignores them
- you can enable per-expression position tracking by compiling with `-D hscriptPos`
- you can parse some type declarations (import, class, typedef, etc.) with parseModule

Changes in this fork
--------------------

Beyond upstream `hscript-improved`, ShadowScript adds:

- **Full pattern matching in `switch`**: array/object destructuring (`case [a,b,c]:`, `case {x:a,y:b}:`), wildcards (`_`), variable-binding cases, `if` guards, and or-patterns (`case 1|3|5:`), evaluated with first-match semantics.
- **Type parameter constraints** (`<T:Constraint>`) accepted on functions, parsed like Haxe but not enforced at runtime, same treatment as other type annotations.
- **Standalone `abstract Name(Type) { ... }` declarations**, registered like custom classes and constructible with `new`/`hnew`.
- **Wildcard imports** (`import pkg.*;`), which pull in every class/enum-valued static field on the target type as top-level identifiers instead of one `import` per symbol.
- **Expression-level metadata** (`@:keep`, `@:deprecated('msg')`, etc.) on arbitrary statements, retained for runtime inspection rather than parsed and discarded.
- **Abstract-like behavior on scripted/host objects** via `IHScriptAbstractBehaviour`: operator overloading (`hop`), array-access overloading (`harrayget`/`harrayset`), a resolve fallback (`hresolve`, for objects with no matching field), and callable objects (`hcall`, so an object can be invoked like a function).
- **Field/class metadata recognized by the interpreter**, attached the same way Haxe attaches metadata (`@:meta` before a field or class):
  - `@:to` / `@:from`: basic abstract-style conversions, used when evaluating `cast(x, T)`.
  - `@:noUsing`: exclude a static-extension function from being picked up by `using`.
  - `@:forward`: forward unresolved field get/set to an underlying field.
  - `@:const`: make a field reject reassignment after construction.
  - `@:deprecated`: emit a warning when a tagged field is accessed.
  - `@:structInit`: allow constructing a class from a single anonymous-object argument.
  - `@:noCompletion`: hide a field from completion-aware tooling built on top of hscript.
- **Static extensions (`using`) for custom (scripted) classes**, not just real Haxe classes, including `@:noUsing` exclusion on scripted static functions.
- **Full `Bytes` round-tripping for `EClass`, `EInterface`, `ETypedef`, `EAbstract`, `EPackage`, `EImport`, `ECast`, and `ERegex`** expressions (previously several of these were write-side no-ops in upstream, which corrupted the rest of the byte stream when serialized).
- Various correctness fixes around compound assignment (`+=` etc.) on arrays/maps/abstract-array-access objects, and the package (`EPackage`) opcode in `Bytes`.

-----------

Install
-------

In order to install Haxe Script, use `haxelib install hscript` and compile your program with `-lib hscript`.

These are the main required files in hscript :

  - `hscript.Expr` : contains enums declarations
  - `hscript.Parser` : a small parser that turns a string into an expression structure (AST)
  - `hscript.Interp` : a small interpreter that execute the AST and returns the latest evaluated value

Some other optional files :
  
  - `hscript.Async` : converts Expr into asynchronous version
  - `hscript.Bytes` : Expr serializer/unserializer
  - `hscript.Checker` : type checking and completion for hscript Expr
  - `hscript.Macro` : convert Haxe macro into hscript Expr
  - `hscript.Printer` : convert hscript Expr to String
  - `hscript.Tools` : utility functions (map/iter)
 
