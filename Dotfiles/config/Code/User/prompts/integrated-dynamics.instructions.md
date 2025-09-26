---
applyTo: "**.indy.ml"
---

# Integrated Dynamics (InDy) Combinator Code Generation
Generate OCaml code that will be used to aid in typechecking combinatory logic derivations.

## Critical Constraints
Violating any of these has caused many type errors and wasted much time on invalid reasoning:
- SSA discipline: One application per binding, no parentheses. Each binding must introduce exactly one new computation
- Semantic naming: Every intermediate binding must have a meaningful name reflecting its combinatorial purpose, not generic names like `tmp1` or `helper`
- Directional composition: `C.revpipe f g x = g (f x)` is reverse of textbook B combinator. Standard SKI/BCK reasoning must be adapted for left-to-right composition
- Arity management: Before any `C.revpipe f g`, ensure f and g compose at exactly one argument position (`f : α → β` and `g : β → γ`). The β type may itself contain arrows (`τ₁ → τ₂ → ... → result`) - this preserves residual arity intentionally. Only saturate with `C.apply` if you need to eliminate trailing arguments completely.
- Re-use of bindings: Every binding must be used **at most once**. If a binding is needed multiple times (i.e. `compose`), it must be re-declared with a new name immediately before each use (e.g. `compose'`, then `compose''`, etc.)

## Domain Model
InDy behaves like an untyped SKI-style combinator calculus with crucial differences:
- `C.apply`, `C.flip` - standard application and argument flipping
- `C.revpipe f g x = g (f x)` - left-to-right composition (reverse of textbook B)
- `C.pipe2 f g h x = h (f x) (g x)` - parallel application and merging (close to standard S combinator, but generalized)
- Any lambda can be rendered via bracket abstraction, but `C.revpipe`'s direction requires adapted reasoning
- Functions are partial/curried; composition consumes only the leftmost parameter at each step and preserves any remaining parameters, which should be saturated with `C.apply` only when a first-order result is required.

We intentionally (mi)suse OCaml's typechecker for combinatorial reasoning. Each OCaml binding represents one in-game combination action. Each must:
1. Be clearly named, based on the type-signature and combinatorial role, not the arguments (reason through the possible usage of the step; refer to FP/CT terminology and concepts for clarity, brevity, and precision)
2. Contain a complete, correct, and general primary type signature (the first time it is presented)
3. Begin with the application of a single built-in combinator (from the `C` module), defaulting to `C.apply` if necessary for previously-bound combinators
4. Only include that single combinator-application (no parentheticals, nesting)

## OCaml Environment
```ocaml
module Combinators : sig
   val apply : ('a -> 'b) -> 'a -> 'b
   val id : 'a -> 'a (* The I(x) combinator *)
   val constant : 'a -> 'b -> 'a (* The K(x, y) combinator *)
   val revpipe : ('a -> 'b) -> ('b -> 'c) -> 'a -> 'c (* Note that this is the _reverse_ of the B(f, g, x) combinator! *)
   val pipe2 : ('a -> 'b) -> ('a -> 'c) -> ('b -> 'c -> 'ret) -> 'a -> 'ret (* Also not *quite* the S(f, g, x) combinator; but becomes S when combined with apply() *)
   val flip : ('a -> 'b -> 'c) -> 'b -> 'a -> 'c (* The C(f, x, y) combinator *)

   val conjunct : ('a -> bool) -> ('a -> bool) -> 'a -> bool
   val disjunct : ('a -> bool) -> ('a -> bool) -> 'a -> bool
   val negate : ('a -> bool) -> 'a -> bool

   val append : 'a list -> 'a -> 'a list
   val map : ('a -> 'b) -> 'a list -> 'b list
   val filter : ('a -> bool) -> 'a list -> 'a list
end = struct
   let apply = (@@)
   let id x = x
   let constant x _y = x
   let revpipe f g x = g (f x)
   let pipe2 f g h x = h (f x) (g x)
   let flip f x y = f y x

   let conjunct f g x = (f x) && (g x)
   let disjunct f g x = (f x) || (g x)
   let negate f x = not (f x)

   let append xs x = List.append xs [x]
   let map = List.map
   let filter = List.filter

   let reduce f xs y = List.fold_left f y xs
   let reduce1 f xs = reduce f (List.tl xs) (List.hd xs)
end

module C = Combinators
```

(This is the only content in the typechecking file; all other content must be generated/duplicated into your output, as they represent the actual productive steps.)

## Example Output
```ocaml
(* ## Example pattern: "Pipe the nth arg through g" *)
(* 1st argument mapping: f (g x) b c *)
let comap1              : ('a -> 'b -> 'c -> 'ret) -> ('x -> 'a) -> 'x -> 'b -> 'c -> 'ret
   = C.revpipe

(* 2nd argument mapping: f a (g x) c *)
let whisker_left        : ((('a -> 'b) -> 'x -> 'b) -> 'ret) -> ('x -> 'a) -> 'ret
   = C.revpipe C.revpipe
let comap2              : ('a -> 'b -> 'c -> 'ret) -> ('x -> 'b) -> 'a -> 'x -> 'c -> 'ret
   = C.revpipe C.revpipe whisker_left

(* 3rd argument mapping: f a b (g x) *)
(* note the redeclaration to respect SSA! *)
let compose             : ('a -> 'ret) -> ('c -> 'a) -> 'c -> 'ret
   = C.flip C.revpipe
let whisker_left' (* redeclare *) = C.revpipe C.revpipe
let with_cont_from      : (('c -> 'ret) -> 'x -> 'ret) -> ('b -> 'c -> 'ret) -> 'b -> 'x -> 'ret
   = C.revpipe C.apply compose
let contramap2          : ('x -> 'c) -> ('b -> 'c -> 'ret) -> 'b -> 'x -> 'ret
   = whisker_left' with_cont_from

let compose' (* redeclare *) = C.flip C.revpipe
let contramap3          : ('x -> 'c) -> ('a -> 'b -> 'c -> 'ret) -> 'a -> 'b -> 'x -> 'ret
   = C.revpipe contramap2 compose'
let comap3              : ('a -> 'b -> 'c -> 'ret) -> ('x -> 'c) -> 'a -> 'b -> 'x -> 'ret
   = C.flip contramap3

(* ## Example output: N-ary array-creation functions *)
(* collate xs x = append xs x *)
let with_snoc_from      : (('t -> 't list) -> 'ret) -> 't list -> 'ret
   = C.revpipe C.append
let collate             : 't list -> 't -> 't list
   = with_snoc_from C.id

(* collate2 xs x y = append (append xs x) y *)
let with_snoc_from' (* redeclare *) = C.revpipe C.append
let compose'' (* redeclare *) = C.flip C.revpipe
let lift1               : ('a -> 'ret) -> ('x -> 'a) -> 'x -> 'ret
   = C.apply compose''
let lift_append         : ('x -> 't list) -> 'x -> 't -> 't list
   = lift1 C.append
let collate2            : 't list -> 't -> 't -> 't list
   = with_snoc_from' lift_append

(* collate3 xs x y z = append (append (append xs x) y) z *)
let with_snoc_from'' (* redeclare *) = C.revpipe C.append
let compose''' (* redeclare *) = C.flip C.revpipe
let lift1' (* redeclare *) = C.apply compose'''
let lift2_collate       : ('x -> 't list) -> 'x -> 't -> 't -> 't list
   = lift1' collate2
let collate3            : 't list -> 't -> 't -> 't -> 't list
   = with_snoc_from'' lift2_collate
```

(These examples are not included; they are included for illustration. You must duplicate them in your output if you need them. Begin all duplication-counting at 1.)

## Generation Instructions

### Step 1: Plan the derivation
- State exact lambda expression being derived
- Identify argument order and composition pattern
- Account for `C.revpipe`'s left-to-right direction

### Step 2: Generate each binding
For each intermediate step:

Check before writing:
- Does this binding contain exactly one application? (i.e. no parentheses or nesting)
  - If not, extract the inner application into its own binding first
- Does this binding refer to any previously-bound names? If so, have those already been used previously?
  - If so, redeclare with a new name (e.g. `compose'`, `compose''`, etc.)
- For any `C.revpipe f g`, verify a single-argument boundary: write `f : α → β` and `g : β → γ` for this step; `β` may itself be an arrow chain (`τ1 → … → τk → r`), which is preserved for later steps.
  - Only eliminate trailing arrows when needed: if the next step expects a first-order value, explicitly saturate with `C.apply` before composing. Otherwise, keep residual arity intact for further lifting.
- Does the name reflect combinatorial meaning (not generic like `tmp1` or `helper`)?
- Is the type signature complete and as general as possible? (unless it's been identically declared in a previous step, in which case omit the type signature, commentary, etc)

Write binding as:
```ocaml
let meaningful_name : principal_type = C.core_combinator operands
```

### Step 3: Verify correctness
- Test resulting function matches expected behavior
- Confirm all bindings follow SSA discipline (no parentheses, one application each, any re-used bindings reduplicated)
- Check that directional composition is handled correctly

## Authoritative References

- InDy documentation: https://integrateddynamics.rubensworks.net/book/
- "The Value of Operators" tutorial: https://integrateddynamics.rubensworks.net/book/tutorials/theValueOfOperators.html
- Java implementation: https://github.com/CyclopsMC/IntegratedDynamics
- Haskell modeling: https://gitlab.com/yogghy/haskell_indy
- Bracket abstraction: https://www.reddit.com/r/haskell/comments/8els6f/why_are_combinators_as_powerful_as_full/
