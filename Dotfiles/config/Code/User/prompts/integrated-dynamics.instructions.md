---
applyTo: "**.indy.ml"
---

# Integrated Dynamics (InDy) Combinator Code Generation
Generate OCaml code that will be used to aid in typechecking combinatory logic derivations.

Then, present an alternative presentation of the same code, as in-game instructions for combining Integrated Dynamics operators.

## Critical Constraints
Violating any of these has caused many type errors and wasted much time on invalid reasoning:
- SSA discipline: Exactly one top-level built-in combinator invocation per binding; its (curried) arguments must be previously-bound names; no parentheticals/nesting. Each binding must introduce exactly one new computational step.
- Semantic naming: Every intermediate binding must have a meaningful name reflecting its combinatorial purpose, not generic names like `tmp1` or `helper`
- Directional composition: `ID.revpipe f g x = g (f x)` is reverse of textbook B combinator. Standard SKI/BCK reasoning must be adapted for left-to-right composition
- Arity management: Before any `ID.revpipe f g`, ensure f and g compose at exactly one argument position (`f : α → β` and `g : β → γ`). The β type may itself contain arrows (`τ₁ → τ₂ → ... → result`) - this preserves residual arity intentionally. Only saturate with `ID.apply` if you need to eliminate trailing arguments completely.
- Re-use of bindings: Every binding must be used **at most once**. If a binding is needed multiple times (i.e. `compose`), it must be re-declared with a new name immediately before each use (e.g. `compose'`, then `compose''`, etc.)

Important to note: THIS IS NOT PRODUCTION OCAML CODE. Idiomatic style, D.R.Y., performance, etc. - all traditional programming concerns are irrelevant. The only goal is to produce a sequence of combinatorial reasoning steps, and to use the code as a logical step-by-step framework to validate your own reasoning. It exists to ensure model performance and correctness, not to be read or maintained by humans.

## Domain Model
InDy cards consist of:
- A single built-in operator (from the `C` module below)
- Zero or more previously-created cards, inserted into the built-in operator's slots

Operators (both built-ins, as well as combinatorial results) may themselves be stored in a card, then invoked by the `ID.apply` built-in operator.

InDy behaves like an untyped SKI-style combinator calculus with crucial differences:
- `ID.apply`, `ID.flip` - standard application and argument flipping
- `ID.revpipe f g x = g (f x)` - left-to-right composition (reverse of textbook B)
- `ID.pipe2 f g h x = h (f x) (g x)` - parallel application and merging (close to standard S combinator, but generalized)
- Any lambda can be rendered via bracket abstraction, but `ID.revpipe`'s direction requires adapted reasoning
- Functions are partial/curried; composition consumes only the leftmost parameter at each step and preserves any remaining parameters, which should be saturated with `ID.apply` only when a first-order result is required.

We intentionally (mi)suse OCaml's typechecker for combinatorial reasoning. Each OCaml binding represents one in-game combination action. Each MUST:
1. Be clearly named, based on the type-signature and combinatorial role, not the arguments (reason through the possible usage of the step; refer to FP/CT terminology and concepts for clarity, brevity, and precision)
2. Contain a complete, correct, and general primary type signature (the first time it is presented)
3. Begin with the application of a single built-in combinator (from the `ID` module; defaulting to `ID.apply` if necessary for previously-bound combinators)
4. Only include other direct, previous bindings as parameters to that combinator (no parentheticals, no nesting, no free variables or lambdas)
5. Subject to all of the above, we want the shortest series of operations we can produce - but not at the cost of correctness (i.e. you still cannot re-use, nest, create helpers, etc. Traditional programming solutions are not helpful; only logical reduction of the actual operations.)

## Example binding-sequences
These bindings are example output, and will not be present in the typechecking file. If you need to reuse some of these bindings, then reproduce those bindings in your output, as they represent actual productive steps.

```ocaml
(* ## Example output for: piping the Nth arg through g *)

let revpipe (* builtin *) = ID.operator ID.revpipe
let comap1              : ('a -> 'b -> 'c -> 'ret) -> ('x -> 'a) -> 'x -> 'b -> 'c -> 'ret
   = ID.flip revpipe
(* Goal reached: `comap1 f g x b c = f (g x) b c` *)

let whisker_left        : ((('a -> 'b) -> 'x -> 'b) -> 'ret) -> ('x -> 'a) -> 'ret
   = ID.revpipe comap1
let revpipe' (* builtin *) = ID.operator ID.revpipe
let comap2              : ('a -> 'b -> 'c -> 'ret) -> ('x -> 'b) -> 'a -> 'x -> 'c -> 'ret
   = ID.revpipe revpipe' whisker_left
(* Goal reached: `comap2 f g a x c = f a (g x) c` *)

(* note the redeclarations to respect SSA! *)
let revpipe'' (* builtin *) = ID.operator ID.revpipe
let compose             : ('a -> 'ret) -> ('c -> 'a) -> 'c -> 'ret
   = ID.flip revpipe''
let revpipe''' (* builtin *) = ID.operator ID.revpipe
let whisker_left' (* redeclare *) = ID.revpipe revpipe'''
let apply (* builtin *) = ID.operator ID.apply
let with_cont_from      : (('c -> 'ret) -> 'x -> 'ret) -> ('b -> 'c -> 'ret) -> 'b -> 'x -> 'ret
   = ID.revpipe apply compose
let contramap2          : ('x -> 'c) -> ('b -> 'c -> 'ret) -> 'b -> 'x -> 'ret
   = ID.apply whisker_left' with_cont_from

let revpipe'''' (* builtin *) = ID.operator ID.revpipe
let compose' (* redeclare *) = ID.flip revpipe''''
let contramap3          : ('x -> 'c) -> ('a -> 'b -> 'c -> 'ret) -> 'a -> 'b -> 'x -> 'ret
   = ID.revpipe contramap2 compose'
let comap3              : ('a -> 'b -> 'c -> 'ret) -> ('x -> 'c) -> 'a -> 'b -> 'x -> 'ret
   = ID.flip contramap3
(* Goal reached: `comap3 f g a b x = f a b (g x)` *)

(* ## Example output for: N-ary array-creation functions *)

let append (* builtin *) = ID.operator ID.append
let with_snoc_from      : (('t -> 't list) -> 'ret) -> 't list -> 'ret
   = ID.revpipe append
let id (* builtin *) = ID.operator ID.id
let collate             : 't list -> 't -> 't list
   = ID.apply with_snoc_from id
(* Goal reached: `collate xs x = append xs x` *)

let append' (* builtin *) = ID.operator ID.append
let with_snoc_from' (* redeclare *) = ID.revpipe append'
let revpipe''''' (* builtin *) = ID.operator ID.revpipe
let compose'' (* redeclare *) = ID.flip revpipe'''''
let lift1               : ('a -> 'ret) -> ('x -> 'a) -> 'x -> 'ret
   = ID.apply compose''
let append'' (* builtin *) = ID.operator ID.append
let lift_append         : ('x -> 't list) -> 'x -> 't -> 't list
   = ID.apply lift1 append''
let collate2            : 't list -> 't -> 't -> 't list
   = ID.apply with_snoc_from' lift_append
(* Goal reached: `collate2 xs x y = append (append xs x) y` *)

let append''' (* builtin *) = ID.operator ID.append
let with_snoc_from'' (* redeclare *) = ID.revpipe append'''
let revpipe'''''' (* builtin *) = ID.operator ID.revpipe
let compose''' (* redeclare *) = ID.flip revpipe''''''
let lift1' (* redeclare *) = ID.apply compose'''
let lift2_collate       : ('x -> 't list) -> 'x -> 't -> 't -> 't list
   = ID.apply lift1' collate2
let collate3            : 't list -> 't -> 't -> 't -> 't list
   = ID.apply with_snoc_from'' lift2_collate
(* Goal reached: `collate3 xs x y z = append (append (append xs x) y) z` *)
```

(Repeat: These examples are not included in the test-file; they are included for illustration. You must duplicate them in your output if you need them; begin all prime-counting at 1.)

## Generation Instructions

### Step 1: Plan the derivation
- State exact lambda expression being derived
- Identify argument order and composition pattern
- Account for `ID.revpipe`'s left-to-right direction

### Step 2: Generate each binding
For each intermediate step:

Write binding as:
```ocaml
let meaningful_name : type_signature = ID.core_combinator operand operand
```

Check each binding after writing:
- This binding refers only to previously-bound names, that have not yet been consumed
  - If not, first redeclare the needed binding with a new, primed name - e.g. `compose'`, `compose''`, etc
- If `revpipe` is used, verify a single-argument boundary: write `f : α → β` and `g : β → γ` for this step; `β` may itself be an arrow chain (`τ1 → … → τk → r`), which is preserved for later steps
  - Only eliminate trailing arrows when needed: if the next step expects a first-order value, explicitly saturate with `ID.apply` before composing. Otherwise, keep residual arity intact for further lifting.
- The name reflects combinatorial meaning (not something generic like `tmp1` or `helper`)
- The type signature is complete, correct, and clear (unless it's being redeclared or is a builtin, in which case it may be elided)
- The first identifier is a built-in from the `C` module (defaulting to `ID.apply` if necessary when invoking a previously-bound combinator)
- All other identifiers are previously-locally-bound names (i.e. no parentheticals, no lambdas, no free variables, no `ID.foo` builtins)
  - The sole exception to this rule is `ID.operator` itself, which may have another `ID.foo` builtin as its operand
  - If not, extract the dependency into its own binding first - for references to builtins, use a prior local binding to `ID.operator ID.builtin_name`

### Step 3: Verify correctness
- Test resulting function matches expected behavior
- Confirm all bindings follow SSA discipline (no parentheses, one application each, any re-used bindings reduplicated/primed, no `ID.foo` built-in operands ...)
- Check that directional composition is handled correctly

### Step 4: Provide in-game instructions
- Translate each OCaml binding into a single instruction for creating a single card in InDy
- This will involve using one of the built-in combinators (`ID.flip`) in the in-game "Portable Logic Programmer", and inserting other operator-cards from previous steps into the correct slots
- If a binding was redeclared (e.g. `compose'`), indicate that the player may re-use the same operator-card that they've already created (unlike in the OCaml code, where it must be redeclared with a new name for typechecking!)
- If `ID.revpipe` was used, ensure to refer to it as simply "Pipe" in the in-game instructions, since the game does not expose the directionality explicitly. Mention this to the user at the start of the instructions, to ensure clarity.

Print the OCaml code first, then the numbered, linearly-numbered, in-game "create this card" instructions second.

## External references

- InDy documentation: https://integrateddynamics.rubensworks.net/book/
- "The Value of Operators" tutorial: https://integrateddynamics.rubensworks.net/book/tutorials/theValueOfOperators.html
- Java implementation: https://github.com/CyclopsMC/IntegratedDynamics
- Haskell modeling: https://gitlab.com/yogghy/haskell_indy
- Bracket abstraction: https://www.reddit.com/r/haskell/comments/8els6f/why_are_combinators_as_powerful_as_full/

## OCaml Environment
The below is the only pre-existing content in the typechecking file, and SHOULD NOT be duplicated into the output; it will be ambiently available to your generated code.

```ocaml
module ID (* Integrated-Dynamics-in-OCaml model *) : sig
  val operator : 'a -> 'a                                         (* let operator x = x *)
  (* Promote raw builtin into a binding/card (in OCaml model of the domain, simple identity). *)

  val apply : ('a -> 'ret) -> 'a -> 'ret                          (* let apply f x = f x *)
  val apply0 : (unit -> 'ret) -> 'ret                             (* let apply0 f = f () *)
  val apply2 : ('a -> 'b -> 'ret) -> 'a -> 'b -> 'ret             (* let apply2 f x y = f x y *)
  val apply3 : ('a -> 'b -> 'c -> 'ret) -> 'a -> 'b -> 'c -> 'ret (* let apply3 f x y z = f x y z *)
  val apply_n : ('a list -> 'ret) -> 'a list -> 'ret              (* let apply_n f xs = f xs *)
  (* NOTE: lists in-game are hetrogeneous, but OCaml lists are homogeneous. apply_n makes less sense
     in this model of the domain. Inform the user if you need hetrogenous apply_n and explain. *)

  val id : 'a -> 'a                                               (* let id x = x *)
  val constant : 'a -> 'discard -> 'a                             (* let constant a _ = a *)

  val flip : ('a -> 'b -> 'ret) -> 'b -> 'a -> 'ret               (* let flip f x y = f y x *)
  val pipe2 : ('a -> 'b) -> ('a -> 'c) -> ('b -> 'c -> 'ret) -> 'a -> 'ret
  (* let pipe2 f g h x = h (f x) (g x) *)
  val revpipe : ('a -> 'b) -> ('b -> 'ret) -> 'a -> 'ret          (* let revpipe f g x = g (f x) *)
  (* NOTE: revpipe corresponds to in‑game "Pipe"; naming chosen to encourage correct left→right reasoning. *)

  (* Boolean predicate combinators *)
  val conjunct : ('x -> bool) -> ('x -> bool) -> 'x -> bool (* let conjunct p q x = p x && q x *)
  val disjunct : ('x -> bool) -> ('x -> bool) -> 'x -> bool (* let disjunct p q x = p x || q x *)
  val negate : ('x -> bool) -> 'x -> bool                   (* let negate p x = not (p x) *)

  val equals : 'a -> 'a -> bool
  val not_equals : 'a -> 'a -> bool
  val is_null : 'a -> bool
  val is_not_null : 'a -> bool
  val greater_than : int -> int -> bool
  val less_than : int -> int -> bool
  val greater_than_or_equals : int -> int -> bool
  val less_than_or_equals : int -> int -> bool

  val choice : bool -> 'a -> 'a -> 'a (* let choice b x y = if b then x else y *)

  (* Opaque domain types *)
  type named
  type uniquely_named
  type block
  type item
  type fluid
  type nbt
  type entity
  type ingredients
  type recipe

  module Boolean : sig
    val and_ : bool -> bool -> bool
    val or_ : bool -> bool -> bool
    val not : bool -> bool
    val nand : bool -> bool -> bool
    val nor : bool -> bool -> bool
  end

  module Number : sig
    val add : int -> int -> int
    val subtract : int -> int -> int
    val multiply : int -> int -> int
    val divide : int -> int -> int
    val max : int -> int -> int
    val min : int -> int -> int
    val increment : int -> int
    val decrement : int -> int
    val modulus : int -> int -> int
    (* Bitwise / shifts *)
    val binary_and : int -> int -> int
    val binary_or : int -> int -> int
    val xor : int -> int -> int
    val complement : int -> int
    val left_shift : int -> int -> int
    val right_shift : int -> int -> int
    val unsigned_right_shift : int -> int -> int
    val round : float -> int
    val ceil : float -> int
    val floor : float -> int
    val compact : int -> string
  end

  module Cast : sig
    val integer_to_double : int -> float
    val integer_to_long : int -> int64
    val double_to_integer : float -> int
    val double_to_long : float -> int64
    val long_to_integer : int64 -> int
    val long_to_double : int64 -> float
  end

  module String : sig
    val length : string -> int
    val concat : string -> string -> string
    val contains : string -> string -> bool
    val contains_regex : string -> string -> bool
    val matches_regex : string -> string -> bool
    val index_of : string -> string -> int
    val index_of_regex : string -> string -> int
    val starts_with : string -> string -> bool
    val ends_with : string -> string -> bool
    val split_on : string -> string -> string list
    val split_on_regex : string -> string -> string list
    val substring : int -> int -> string -> string
    val regex_group : string -> int -> string -> string
    val regex_groups : string -> string -> string list
    val regex_scan : string -> int -> string -> string list
    val replace : string -> string -> string -> string
    val replace_regex : string -> string -> string -> string
    val join : string -> string list -> string
    val name : named -> string
    val uname : uniquely_named -> string
    val parse_boolean : string -> bool
    val parse_double : string -> float
    val parse_integer : string -> int
    val parse_long : string -> int64
    val parse_nbt : string -> nbt
  end

  module List : sig
    (* NOTE: In-game lists are hetrogeneous, but OCaml lists are homogeneous. Use with caution. *)
    val length : 'a list -> int
    val is_empty : 'a list -> bool
    val is_not_empty : 'a list -> bool
    val get : 'a list -> int -> 'a
    val get_or_default : 'a list -> int -> 'a -> 'a
    val contains : 'a list -> 'a -> bool
    val contains_p : 'a list -> ('a -> bool) -> bool
    val count : 'a list -> 'a -> int
    val count_p : 'a list -> ('a -> bool) -> int
    val append : 'a list -> 'a -> 'a list
    val concat : 'a list -> 'a list -> 'a list
    val lazy_built : 'a -> ('a -> 'a) -> 'a Seq.t
    val head : 'a list -> 'a
    val tail : 'a list -> 'a list
    val uniq_p : 'a list -> ('a -> 'a -> bool) -> 'a list
    val uniq : 'a list -> 'a list
    val slice : 'a list -> int -> int -> 'a list
    val intersection : 'a list -> 'a list -> 'a list
    val map : ('a -> 'b) -> 'a list -> 'b list
    val filter : ('a -> bool) -> 'a list -> 'a list
    val reduce : ('ret -> 'a -> 'ret) -> 'a list -> 'ret -> 'ret
    val reduce1 : ('a -> 'a -> 'a) -> 'a list -> 'a
  end

  module Block : sig
    val opaque : block -> bool
    val itemstack : block -> item
    val mod_ : block -> string
    val break_sound : block -> string
    val place_sound : block -> string
    val step_sound : block -> string
    val is_shearable : block -> bool
    val plant_age : block -> int
    val block_by_name : string -> block
    val block_props : block -> nbt
    val block_with_props : block -> nbt -> block
    val block_all_props : block -> nbt
  end

  module Item : sig
    val size : item -> int
    val maxsize : item -> int
    val stackable : item -> bool
    val damageable : item -> bool
    val damage : item -> int
    val max_damage : item -> int
    val enchanted : item -> bool
    val enchantable : item -> bool
    val repair_cost : item -> int
    val rarity : item -> string
    val strength : item -> block -> float
    val can_harvest : item -> block -> bool
    val block : item -> block
    val is_fluidstack : item -> bool
    val fluidstack : item -> fluid
    val fluidstack_capacity : item -> int
    val is_nbt_equal : item -> item -> bool
    val is_equal_non_nbt : item -> item -> bool
    val is_equal_raw : item -> item -> bool
    val mod_ : item -> string
    val burn_time : item -> int
    val can_burn : item -> bool
    val tag_names : item -> string list
    val tag_values : string -> item list
    val with_size : item -> int -> item
    val is_fe_container : item -> bool
    val stored_fe : item -> int
    val capacity_fe : item -> int
    val has_inventory : item -> bool
    val inventory_size : item -> int
    val inventory : item -> item list
    val item_by_name : string -> item
    val item_list_count : item list -> item -> int
    val nbt : item -> nbt
    val has_nbt : item -> bool
  end

  module Entity : sig
    val is_mob : entity -> bool
    val is_animal : entity -> bool
    val is_item : entity -> bool
    val is_player : entity -> bool
    val is_minecart : entity -> bool
    val item : entity -> item
    val health : entity -> float
    val width : entity -> float
    val height : entity -> float
    val is_burning : entity -> bool
    val is_wet : entity -> bool
    val is_crouching : entity -> bool
    val is_eating : entity -> bool
    val armor_inventory : entity -> item list
    val inventory : entity -> item list
    val mod_ : entity -> string
    val target_block : entity -> block
    val target_entity : entity -> entity
    val has_gui_open : entity -> bool
    val held_item_1 : entity -> item
    val held_item_2 : entity -> item
    val mounted : entity -> entity list
    val itemframe_contents : entity -> item
    val itemframe_rotation : entity -> int
    val hurtsound : entity -> string
    val deathsound : entity -> string
    val age : entity -> int
    val is_child : entity -> bool
    val canbreed : entity -> bool
    val is_in_love : entity -> bool
    val can_breed_with : entity -> item -> bool
    val is_shearable : entity -> bool
    val nbt : entity -> nbt
    val entity_type : entity -> string
    val entity_items : entity -> item list
    val entity_fluids : entity -> fluid list
    val entity_stored_fe : entity -> int
    val entity_capacity_fe : entity -> int
  end

  module Fluid : sig
    val amount : fluid -> int
    val block : fluid -> block
    val light_level : fluid -> int
    val density : fluid -> int
    val temperature : fluid -> int
    val viscosity : fluid -> int
    val lighter_than_air : fluid -> bool
    val rarity : fluid -> string
    val sound_bucket_empty : fluid -> string
    val sound_fluid_vaporize : fluid -> string
    val sound_bucket_fill : fluid -> string
    val bucket : fluid -> item
    val raw_equal : fluid -> fluid -> bool
    val mod_ : fluid -> string
    val nbt : fluid -> nbt
    val with_amount : fluid -> int -> fluid
  end

  module Nbt : sig
    val size : nbt -> int
    val keys : nbt -> string list
    val has_key : nbt -> string -> bool
    val type_ : nbt -> string -> string
    val get_tag : nbt -> string -> nbt
    val get_boolean : nbt -> string -> bool
    val get_integer : nbt -> string -> int
    val get_long : nbt -> string -> int64
    val get_double : nbt -> string -> float
    val get_string : nbt -> string -> string
    val get_compound : nbt -> string -> nbt
    val get_list_tag : nbt -> string -> nbt list
    val get_list_byte : nbt -> string -> int list
    val get_list_int : nbt -> string -> int list
    val get_list_long : nbt -> string -> int64 list
    val without : nbt -> string -> nbt
    val with_boolean : nbt -> string -> bool -> nbt
    val with_short : nbt -> string -> int -> nbt
    val with_integer : nbt -> string -> int -> nbt
    val with_long : nbt -> string -> int64 -> nbt
    val with_double : nbt -> string -> float -> nbt
    val with_float : nbt -> string -> float -> nbt
    val with_string : nbt -> string -> string -> nbt
    val with_tag : nbt -> string -> nbt -> nbt
    val with_tag_list : nbt -> string -> nbt list -> nbt
    val with_byte_list : nbt -> string -> int list -> nbt
    val with_int_list : nbt -> string -> int list -> nbt
    val with_list_long : nbt -> string -> int64 list -> nbt
    val subset : nbt -> nbt -> bool
    val union : nbt -> nbt -> nbt
    val intersection : nbt -> nbt -> nbt
    val minus : nbt -> nbt -> nbt
    val as_boolean : nbt -> bool
    val as_byte : nbt -> int
    val as_short : nbt -> int
    val as_int : nbt -> int
    val as_long : nbt -> int64
    val as_double : nbt -> float
    val as_float : nbt -> float
    val as_string : nbt -> string
    val as_tag_list : nbt -> nbt list
    val as_byte_list : nbt -> int list
    val as_int_list : nbt -> int list
    val as_long_list : nbt -> int64 list
    val from_boolean : bool -> nbt
    val from_short : int -> nbt
    val from_byte : int -> nbt
    val from_int : int -> nbt
    val from_long : int64 -> nbt
    val from_double : float -> nbt
    val from_float : float -> nbt
    val from_string : string -> nbt
    val from_tag_list : nbt list -> nbt
    val from_byte_list : int list -> nbt
    val from_int_list : int list -> nbt
    val from_long_list : int64 list -> nbt
    val path_match_first : string -> nbt -> nbt
    val path_match_all : string -> nbt -> nbt list
    val path_test : string -> nbt -> bool
  end

  module Ingredients : sig
    val items : ingredients -> item list
    val fluids : ingredients -> fluid list
    val energies : ingredients -> int list
    val with_item : ingredients -> int -> item -> ingredients
    val with_fluid : ingredients -> int -> fluid -> ingredients
    val with_energy : ingredients -> int -> int64 -> ingredients
    val with_items : ingredients -> item list -> ingredients
    val with_fluids : ingredients -> fluid list -> ingredients
    val with_energies : ingredients -> int list -> ingredients
  end

  module Recipe : sig
    val recipe_in : recipe -> ingredients
    val recipe_out : recipe -> ingredients
    val with_in : recipe -> ingredients -> recipe
    val with_out : recipe -> ingredients -> recipe
    val with_io : ingredients -> ingredients -> recipe
  end
end
```
