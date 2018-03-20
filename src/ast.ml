type ty_var = string

type te_var = string

type name   = string * string

type tyOp   = name

type cst = name

type _ty = TyVar of ty_var
         | Arrow of _ty * _ty
         | TyOp of tyOp * _ty list
         | Prop

type ty  = ForallK of ty_var * ty
         | Ty of _ty



type _te = TeVar of te_var
         | Abs of te_var * _ty * _te
         | App of _te * _te
         | Forall of te_var * _ty * _te
         | Impl of _te * _te
         | AbsTy of ty_var * _te
         | Cst of cst * _ty list

type te  = ForallP of ty_var * te
         | Te of _te

type ty_ctx = ty_var list

type te_ctx = (te_var * _ty) list

module TeSet = Set.Make(struct type t = _te let compare = compare end)

type hyp = TeSet.t


type judgment =
  {
    ty:ty_ctx;
    te:te_ctx;
    hyp:hyp;
    thm:te;
  }

type proof =
  | Assume of judgment
  | Lemma of judgment
  | Conv of judgment * proof
  | ImplE of judgment * proof * proof
  | ImplI of judgment * proof
  | ForallE of judgment * proof * _te
  | ForallI of judgment * proof
  | ForallPE of judgment * proof * _ty
  | ForallPI of judgment * proof

type arity = int

type item =
    Parameter  of name * ty
  | Definition of name * ty * te
  | Axiom      of name * te
  | Theorem    of name * te * proof
  | TyOpDef    of tyOp * arity

type ast = item list