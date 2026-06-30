# FEATURES

- Custom Classes
  - Final Classes
  - Static Classes
  - Allow for type check (`is`)
  - Allow extending other custom classes
- Enums

  ```haxe
  enum TypeValue {
    NUMBER(n:Int);
    DECIMAL(d:Float, ?p:Int);
    CHARACTER(s:String);
    BOOLEAN(b:Bool);
  }

  var type = TypeValue.DECIMAL(10.1234, 2);
  // You need to type the full enum field for each case
  // i.e. you can't type the enum field directly (limitation for now)
  switch(type) {
    case TypeValue.NUMBER(number): 
      trace("number: " + number);
    case TypeValue.DECIMAL(decimal, precision): 
      if(precision != null)
        trace("decimal: " + decimal + " | rounded decimal: " + roundDecimal(decimal, precision));
      else
        trace("decimal: " + decimal);
    case TypeValue.CHARACTER(char): 
      trace("character: " + char);
    default: 
      trace("unknown type");
  }

  function roundDecimal(Value:Float, Precision:Int) {
    var mult:Float = Math.pow(10, Precision);
    return Math.fround(Value * mult) / mult;
  }
  ```

  - Enum matching with arguments for switch statements (for real and scripted enums)
- Property Fields (`(get, set)` variables)

  ```haxe
  public var myvar(get, set):Int;
  var _myvar:Int = 10;

  function get_myvar():Int {
    return _myvar;
  }

  function set_myvar(val:Int):Int {
    if(val > 10) return _myvar = val;
    return val;
  }
  ```

  - `@:isVar` metadata support
  
- Static extension (`using`)

  ```haxe
  using StringTools;

  class IntExtender {
    static public function triple(i:Int) {
      return i * 3;
    }
  }

  // need to create/import the custom class
  // before setting the extension (limitation for now)
  using IntExtender;

  var str = "  Hello World!  ";
  trace(str.trim()); // "Hello World!"
  trace(12.triple()); // 36
  ```

  - Support for real and custom classes
- Metadata Support

  Metadata is parsed when `parser.allowMetadata` is set, and the interpreter recognizes the following tags on fields/classes:

  - `@:to` / `@:from`: basic abstract-style conversions. A `@:to` instance (or static, via `using`) method is invoked when `cast(x, T)` is evaluated and `T` matches its declared return type; a `@:from` static method on the target custom class is tried as a fallback.

    ```haxe
    class Meters {
      var value:Float;
      function new(v:Float) value = v;

      @:to function toFloat():Float return value;
      @:from static function fromFloat(v:Float):Meters return new Meters(v);
    }

    var m = cast(10.0, Meters);
    var f:Float = cast(m, Float);
    ```

  - `@:noUsing`: exclude a static-extension function from being picked up by `using`, even if its enclosing class is imported with `using`.
  - `@:forward`: if a field isn't found directly on an object, forward the get/set to a named underlying field.
  - `@:const`: reassigning a field tagged `@:const` throws instead of silently succeeding.
  - `@:deprecated` / `@:deprecated("message")`: accessing the field emits a warning through the interpreter's normal warning channel.
  - `@:structInit`: allows `new MyClass({ a: 1, b: 2 })` to construct an instance by copying matching fields from the object argument.
  - `@:noCompletion`: purely a hint for completion-aware tooling (editors, etc.) built on top of hscript; the interpreter itself ignores it at runtime aside from exposing `Interp.isNoCompletionField`.

- Operator & Array-Access Overloading (`IHScriptAbstractBehaviour`)

  Host (real Haxe) objects, or scripted custom-class instances, can implement `IHScriptAbstractBehaviour` to participate in hscript's operators:

  - `hasOp` / `hop(kind, a, ?b)`: overload binary/unary operators (`+`, `-`, `==`, prefix/postfix `++`, etc).
  - `hasArr` / `harrayget(key)` / `harrayset(key, val)`: overload `obj[key]` reads and writes (including compound assignment, e.g. `obj[key] += 1`).
  - `hasResolve` / `hresolve(name)`: fallback used when a field isn't found by normal means.
  - `hasCall` / `hcall(args)`: makes an instance directly callable, e.g. `myObj(1, 2)`.

- Bytes Serialization

  `hscript.Bytes` can encode/decode the full expression set, including class, interface, and typedef declarations: round-tripping is exact for everything the interpreter itself uses (some structural detail that the interpreter doesn't care about, like full typedef bodies, is intentionally dropped on decode).

- Pattern Matching (`switch`)

  Beyond plain value equality, `switch` cases support full pattern matching:

  ```haxe
  switch([1, 2, 3]) {
    case [a, b, c]: trace(a + b + c); // array destructuring: 6
  }

  switch([10, 20, 30]) {
    case [a, _, _]: trace(a); // wildcards ignore positions: 10
  }

  switch([[1, 2], [3, 4]]) {
    case [[a, b], _]: trace(a + b); // nested patterns: 3
  }

  switch({x: 1, y: 2}) {
    case {x: a, y: b}: trace(a + b); // object destructuring: 3
  }

  switch(10) {
    case x if (x > 5): trace(x * 2); // guard + binding: 20
    case _: trace(0);
  }

  switch(3) {
    case 1 | 3 | 5: trace(true); // or-patterns
    case _: trace(false);
  }
  ```

  - Bare identifiers in a `case` bind the matched value to that name (`case x: ...`) rather than requiring it to equal an existing variable.
  - `_` is a wildcard that matches anything without binding.
  - Cases are tried in source order (first match wins), and `if` guards may follow a pattern before the `:`.

- Type Parameter Constraints

  `<T:Constraint>` syntax is accepted on functions and parsed alongside type parameters; the constraint is consumed at parse time (matching Haxe's syntax) but, like other type annotations, isn't enforced by the interpreter at runtime.

  ```haxe
  var f = function<T:Int>(x:T):T return x;
  f(5);

  var g = function<T,U>(x:T, y:U):T return x;
  g(1, "a");
  ```

- Standalone `abstract` Declarations

  `abstract Name(UnderlyingType) { ... }` can be parsed and registered as a custom-class-like type, constructible via `new`/`hnew`. The underlying value is conventionally stored on a `__value__` field:

  ```haxe
  abstract MyInt(Int) {
    public function new(v) __value__ = v;
  }

  var x = new MyInt(42);
  x.__value__; // 42
  ```

- Wildcard Imports (`import pkg.*;`)

  Importing with a trailing `.*` pulls in every class/enum-valued static field exposed on the target type (via reflection) as a top-level identifier in the script, instead of requiring one `import` per symbol:

  ```haxe
  import haxe.ds.*;
  ```

  Names already bound in `variables` are left untouched, so script-local declarations always take precedence over a wildcard import.

- Expression-Level Metadata

  In addition to the field/class metadata above, simple `@:meta` / `@:meta("arg")` annotations can precede any statement (`var`, `function`, etc.) and are recorded for runtime inspection rather than being only a parser-level hint:

  ```haxe
  @:keep var x = 5;
  @:deprecated('use bar') function foo() return 1;
  @:keep @:noDebug var y = 1;
  ```

- Misc.
  - Allow using type parameters for creating objects (i.e. `var a = new TypedObject<Int>();`)
  - Allow `package` declaration. Ignored by the interpreter.
