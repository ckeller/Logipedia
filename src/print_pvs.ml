open Ast

let current_module : string ref = ref ""

let with_types = ref false

let forallp = "\\rotatebox[origin=c]{180}{\\ensuremath{\\mathcal{A}}}"

let sanitize_name : string -> string =
 fun n -> String.concat "\\_" (String.split_on_char '_' n)


let sanitize_name_pvs : string -> string =
 fun n ->
  if String.equal n "True" || String.equal n "False" || String.equal n "Imp"
     || String.equal n "Not" || String.equal n "And" || String.equal n "Or"
     || String.equal n "Ex"
  then "Id_" ^ n
  else if String.equal n "__" then "x__"
  else n


let print_name : out_channel -> name -> unit =
 fun oc (m, n) ->
  let name = sanitize_name_pvs n in
  output_string oc name


let print__ty_pvs : out_channel -> _ty -> unit =
  let rec print is_atom oc _ty =
    match _ty with
    | TyVar x -> output_string oc x
    | Arrow (_, _) when is_atom -> Printf.fprintf oc "%a" (print false) _ty
    | Arrow (a, b) ->
        Printf.fprintf oc "[%a -> %a]" (print true) a (print false) b
    | TyOp (op, l) -> ()
    (*        print_name oc op;
          List.iter (Printf.fprintf oc " %a" (print true)) l *)
    | Prop ->
        output_string oc "Prop"
  in
  print false


let rec print_ty_pvs : out_channel -> ty -> unit =
 fun oc ty ->
  match ty with
  | ForallK (x, ty') -> print_ty_pvs oc ty'
  | Ty _ty -> print__ty_pvs oc _ty


let rec prefix_of_ty : ty -> string list =
 fun ty ->
  match ty with ForallK (x, ty') -> x :: prefix_of_ty ty' | Ty _ty -> []


let rec print_type_list_pvs : out_channel -> _ty list -> unit =
 fun oc l ->
  match l with
  | [] -> ()
  | [a] -> print__ty_pvs oc a
  | a :: l ->
      print__ty_pvs oc a ; Printf.fprintf oc "," ; print_type_list_pvs oc l


let rec print_type_list_b_pvs : out_channel -> _ty list -> unit =
 fun oc ty ->
  match ty with
  | [] -> ()
  | _ ->
      Printf.fprintf oc "[" ; print_type_list_pvs oc ty ; Printf.fprintf oc "]"


let rec print_string_type_list_pvs : out_channel -> string list -> unit =
 fun oc l ->
  match l with
  | [] -> ()
  | [a] -> Printf.fprintf oc "%s:TYPE" a
  | a :: l ->
      Printf.fprintf oc "%s:TYPE," a ;
      print_string_type_list_pvs oc l


let rec print_prenex_ty_pvs : out_channel -> ty -> unit =
 fun oc ty ->
  let p = prefix_of_ty ty in
  match p with
  | [] -> ()
  | _ ->
      Printf.fprintf oc "[" ;
      print_string_type_list_pvs oc p ;
      Printf.fprintf oc "]"


let print__te_pvs : out_channel -> _te -> unit =
  let rec print oc _te =
    match _te with
    | TeVar x -> output_string oc (sanitize_name_pvs x)
    | Abs (x, a, t) ->
        Printf.fprintf oc "LAMBDA(%s:%a):%a" (sanitize_name_pvs x)
          print__ty_pvs a print t
    | App (t, u) -> Printf.fprintf oc "%a(%a)" print t print u
    | Forall (x, a, t) ->
        Printf.fprintf oc "id(FORALL(%s:%a):%a)" x print__ty_pvs a print t
    | Impl (t, u) -> Printf.fprintf oc "id(%a => %a)" print t print u
    | AbsTy (x, t) -> Printf.fprintf oc "%a" print t
    | Cst (c, l) ->
        print_name oc c ;
        match l with
        | [] -> ()
        | _ ->
            Printf.fprintf oc "[" ;
            print_type_list_pvs oc l ;
            Printf.fprintf oc "]"
  in
  print


let rec prefix_of_te : te -> string list =
 fun te ->
  match te with ForallP (x, te') -> x :: prefix_of_te te' | Te te' -> []


let rec print_prenex_te_pvs : out_channel -> te -> unit =
 fun oc te ->
  let p = prefix_of_te te in
  match p with
  | [] -> ()
  | _ ->
      Printf.fprintf oc "[" ;
      print_string_type_list_pvs oc p ;
      Printf.fprintf oc "]"


let rec print_te_pvs : out_channel -> te -> unit =
 fun oc te ->
  match te with
  | ForallP (x, te') -> print_te_pvs oc te'
  | Te te' -> print__te_pvs oc te'


let print__ty_ctx : out_channel -> ty_ctx -> unit =
 fun oc ctx ->
  match ctx with
  | [] -> Printf.fprintf oc "∅"
  | [_ty] -> Printf.fprintf oc "%s" _ty
  | _ty :: l ->
      Printf.fprintf oc "%s" _ty ;
      List.iter (fun _ty -> Printf.fprintf oc ", %s" _ty) l ;
      Printf.fprintf oc " "


let print_te_ctx : out_channel -> te_ctx -> unit =
 fun oc ctx ->
  match ctx with
  | [] -> Printf.fprintf oc "∅"
  | [(x, _ty)] ->
      if !with_types then Printf.fprintf oc "%s:%a" x print__ty_pvs _ty
      else Printf.fprintf oc "%s" x
  | (x, _ty) :: l ->
      if !with_types then (
        Printf.fprintf oc "%s:%a" x print__ty_pvs _ty ;
        List.iter
          (fun (x, _) -> Printf.fprintf oc ", %s:%a" x print__ty_pvs _ty)
          l ;
        Printf.fprintf oc " " )
      else (
        Printf.fprintf oc "%s" x ;
        List.iter (fun (x, _) -> Printf.fprintf oc ", %s" x) l ;
        Printf.fprintf oc " " )


let print_hyp : out_channel -> hyp -> unit =
 fun oc hyp ->
  let l = TeSet.elements hyp in
  match l with
  | [] -> Printf.fprintf oc "∅"
  | [x] -> Printf.fprintf oc "%a" print__te_pvs x
  | x :: l ->
      Printf.fprintf oc "%a" print__te_pvs x ;
      List.iter (fun x -> Printf.fprintf oc ", %a" print__te_pvs x) l ;
      Printf.fprintf oc " "


let print_judgment : out_channel -> judgment -> unit =
 fun oc j ->
  if !with_types then
    Printf.fprintf oc "%a; %a; %a ⊢ %a" print__ty_ctx (List.rev j.ty)
      print_te_ctx (List.rev j.te) print_hyp j.hyp print_te_pvs j.thm
  else
    Printf.fprintf oc "%a; %a ⊢ %a" print_te_ctx (List.rev j.te) print_hyp
      j.hyp print_te_pvs j.thm


let conclusion_pvs : proof -> te =
 fun prf ->
  let j =
    match prf with
    | Assume j -> j
    | Lemma (_, j) -> j
    | Conv (j, p, _) -> j
    | ImplE (j, p, q) -> j
    | ImplI (j, p) -> j
    | ForallE (j, p, _te) -> j
    | ForallI (j, p, _) -> j
    | ForallPE (j, p, _ty) -> j
    | ForallPI (j, p, _) -> j
  in
  j.thm


let print_proof_pvs : out_channel -> proof -> unit =
 fun oc prf ->
  let rec print acc oc prf =
    match prf with
    | Assume j -> Printf.fprintf oc "(propax)"
    | Lemma ((_, s), j) ->
        Printf.fprintf oc "(then (lemma \"%s%a\") (assert))" s
          print_type_list_b_pvs acc
    | Conv (j, p, _) -> print acc oc p
    | ImplE (j, p, q) ->
        let pc = conclusion_pvs p in
        let qc = conclusion_pvs q in
        Printf.fprintf oc
          "(spread (case \"%a\" \"%a\") ((grind) (then (hide 2) (do-rewrite) \
           %a) (then (hide 2) (do-rewrite) %a)))" print_te_pvs pc print_te_pvs
          qc (print acc) q (print acc) p
    | ImplI (j, p) ->
        Printf.fprintf oc "(id-flatten)" ;
        print acc oc p
    | ForallE (j, p, _te) ->
        let pc = conclusion_pvs p in
        Printf.fprintf oc
          "(spread (case \"%a\") ((then (do-rewrite) (id-inst \"%a\")) (then \
           (hide 2) (do-rewrite) %a)))" print_te_pvs pc print__te_pvs _te
          (print acc) p
    | ForallI (j, p, n) ->
        Printf.fprintf oc "(id-skolem \"%s\")" n ;
        (print acc) oc p
    | ForallPE (j, p, _ty) -> print (_ty :: acc) oc p
    | ForallPI (j, p, n) -> print acc oc p
  in
  Printf.fprintf oc "%%|- (then (do-rewrite)" ;
  print [] oc prf ;
  Printf.fprintf oc ")\n"


let print_ast_pvs : out_channel -> string -> ast -> unit =
 fun oc prefix ast ->
  let prefix = Filename.basename prefix in
  let line fmt = Printf.fprintf oc (fmt ^^ "\n") in
  let print_item it =
    match it with
    | TyOpDef (op, ar) -> ()
    (*        line "\\noindent";
        line "The type \\texttt{%a} has $%i$ parameters."
          print_name op ar;
          line "" *)
    | Parameter (n, ty) ->
        line "%a %a: %a" print_name n print_prenex_ty_pvs ty print_ty_pvs ty ;
        line ""
    | Definition (n, ty, te) ->
        line "%a %a : %a = %a" print_name n print_prenex_ty_pvs ty print_ty_pvs
          ty print_te_pvs te ;
        line "AUTO_REWRITE+ %a" print_name n ;
        line ""
    | Axiom (n, te) ->
        line "%a %a : AXIOM %a" print_name n print_prenex_te_pvs te
          print_te_pvs te ;
        line ""
    | Theorem (n, te, prf) ->
        line "%a %a : LEMMA %a" print_name n print_prenex_te_pvs te
          print_te_pvs te ;
        line "" ;
        line "%%|- %a : PROOF" print_name n ;
        print_proof_pvs oc prf ;
        line "%%|- QED" ;
        line ""
  in
  let pf = "_sttfa" in
  let postfix s = s ^ pf in
  line "%s%s : THEORY" prefix pf ;
  line "BEGIN" ;
  let deps oc deps =
    let l = QSet.elements (QSet.remove "sttfa" deps) in
    let l = List.map postfix l in
    let rec deps oc l =
      match l with
      | [] -> Printf.fprintf oc "STP"
      | [x] -> Printf.fprintf oc "%s" x
      | x :: t -> Printf.fprintf oc "%s, %a" x deps t
    in
    deps oc l
  in
  line "IMPORTING %a" deps ast.dep ;
  line "" ;
  List.iter print_item ast.items ;
  line "END %s_sttfa" prefix
