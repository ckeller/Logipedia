open Ast
open Sttforall
open Environ

module CType  = Compile_type
module CTerm  = Compile_term
module CProof = Compile_proof

let compile_declaration name ty =
  match ty with
  | Term.App (cst, a, []) when is_sttfa_const sttfa_etap cst ->
    Format.eprintf "[COMPILE] parameter: %a@." Pp.print_name name ;
      let ty' = CType.compile_type empty_env a in
      Parameter (of_name name, ty')
  | Term.App (cst, a, []) when is_sttfa_const sttfa_eta cst ->
    Format.eprintf "[COMPILE] parameter: %a@." Pp.print_name name ;
      let ty' = CType.compile__type empty_env a in
      Parameter (of_name name, Ty ty')
  | Term.App (cst, a, []) when is_sttfa_const sttfa_eps cst ->
    Format.eprintf "[COMPILE] axiom: %a@." Pp.print_name name ;
      let te' = CTerm.compile_term empty_env a in
      Axiom (of_name name, te')
  | Term.Const (_, _) when is_sttfa_const sttfa_type ty ->
    Format.eprintf "[COMPILE] typeop: %a@." Pp.print_name name ;
      TyOpDef (of_name name, 0)
  | _ -> assert false

let compile_definition name ty term =
  match ty with
  | Term.App (cst, a, []) when is_sttfa_const sttfa_etap cst ->
    Format.eprintf "[COMPILE] definition: %a@." Pp.print_name name ;
      Definition (of_name name, CType.compile_type empty_env a, CTerm.compile_term empty_env term)
  | Term.App (cst, a, []) when is_sttfa_const sttfa_eps cst ->
    Format.eprintf "[COMPILE] theorem: %a@." Pp.print_name name ;
    (* The statement written and the one we get from the proof are beta,delta convertible *)
    let j, proof = CProof.compile_proof empty_env term in
    let a' = CTerm.compile_term empty_env a in
    let proof' =
      if j.thm = a' then proof
      else
        Conv
          ( {j with thm=a'}
          , proof
          , Sttfatyping.Tracer.annotate empty_env j.thm a'
          )
    in
    Theorem (of_name name, CTerm.compile_term empty_env a, proof')
  | _ -> assert false
