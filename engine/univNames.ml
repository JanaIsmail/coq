(************************************************************************)
(*         *   The Coq Proof Assistant / The Coq Development Team       *)
(*  v      *         Copyright INRIA, CNRS and contributors             *)
(* <O___,, * (see version control and CREDITS file for authors & dates) *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

open Util
open Names
open Univ


let qualid_of_level l =
  match Level.name l with
  | Some qid  ->
    (try Some (Nametab.shortest_qualid_of_universe qid)
     with Not_found -> None)
  | None -> None

let pr_with_global_universes l =
  match qualid_of_level l with
  | Some qid  -> Libnames.pr_qualid qid
  | None -> Level.pr l

(** Global universe information outside the kernel, to handle
    polymorphic universe names in sections that have to be discharged. *)

(** Local universe names of polymorphic references *)

type universe_binders = Univ.Level.t Names.Id.Map.t

let empty_binders = Id.Map.empty

type univ_name_list = Names.lname list

let universe_binders_with_opt_names orig names =
  let orig = AUContext.names orig in
  let orig = Array.to_list orig in
  let udecl = match names with
  | None -> orig
  | Some udecl ->
    try
      List.map2 (fun orig {CAst.v = na} ->
          match na with
          | Anonymous -> orig
          | Name id -> Name id) orig udecl
    with Invalid_argument _ ->
      let len = List.length orig in
      CErrors.user_err ~hdr:"universe_binders_with_opt_names"
        Pp.(str "Universe instance should have length " ++ int len)
  in
  let fold i acc na = match na with
  | Name id -> Names.Id.Map.add id (Level.var i) acc
  | Anonymous -> acc
  in
  List.fold_left_i fold 0 empty_binders udecl
