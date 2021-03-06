(*
 * Copyright (c) 1997-1999 Massachusetts Institute of Technology
 * Copyright (c) 2003, 2007-14 Matteo Frigo
 * Copyright (c) 2003, 2007-14 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 *)

open Util
open Genutil
open C

let template_prev_str =
  "#ifdef __cplusplus" ^ "\n\n" ^ "namespace gfft {" ^ "\n\n" ^ "namespace op {"
  ^ "\n\n" ^ "template <typename R>" ^ "\n\n" ^ "#endif" ^ "\n"

let template_after_str =
  "#ifdef __cplusplus" ^ "\n" ^ "}  // namespace op" ^ "\n\n"
  ^ "}  // namespace gfft" ^ "\n" ^ "#endif" ^ "\n"

let usage = "Usage: " ^ Sys.argv.(0) ^ " -n <number>"

let uistride = ref Stride_variable

let uostride = ref Stride_variable

let uivstride = ref Stride_variable

let uovstride = ref Stride_variable

let speclist =
  [
    ( "-with-istride",
      Arg.String (fun x -> uistride := arg_to_stride x),
      " specialize for given input stride" );
    ( "-with-ostride",
      Arg.String (fun x -> uostride := arg_to_stride x),
      " specialize for given output stride" );
    ( "-with-ivstride",
      Arg.String (fun x -> uivstride := arg_to_stride x),
      " specialize for given input vector stride" );
    ( "-with-ovstride",
      Arg.String (fun x -> uovstride := arg_to_stride x),
      " specialize for given output vector stride" );
  ]

let nonstandard_optimizer list_of_buddy_stores dag =
  let sched = standard_scheduler dag in
  let annot = Annotate.annotate list_of_buddy_stores sched in
  let _ = dump_asched annot in
  annot

let generate n =
  let riarray = "ri"
  and iiarray = "ii"
  and roarray = "ro"
  and ioarray = "io"
  and istride = "is"
  and ostride = "os"
  and i = "i"
  and v = "v" in

  let sign = !Genutil.sign
  and name = !Magic.codelet_name
  and byvl x = choose_simd x (ctimes (CVar "(2 * VL)", x)) in
  let ename = expand_name name in

  let vistride = either_stride !uistride (C.SVar istride)
  and vostride = either_stride !uostride (C.SVar ostride) in

  let sovs = stride_to_string "ovs" !uovstride in
  let sivs = stride_to_string "ivs" !uivstride in

  let locations = unique_array_c n in
  let input =
    locative_array_c n
      (C.array_subscript riarray vistride)
      (C.array_subscript iiarray vistride)
      locations sivs
  in
  let output = Fft.dft sign n (load_array_c n input) in
  let oloc =
    locative_array_c n
      (C.array_subscript roarray vostride)
      (C.array_subscript ioarray vostride)
      locations sovs
  in
  let list_of_buddy_stores =
    let k = !Simdmagic.store_multiple in
    if k > 1 then
      if n mod k == 0 then
        List.append
          (List.map
             (fun i -> List.map (fun j -> fst (oloc ((k * i) + j))) (iota k))
             (iota (n / k)))
          (List.map
             (fun i -> List.map (fun j -> snd (oloc ((k * i) + j))) (iota k))
             (iota (n / k)))
      else failwith "invalid n for -store-multiple"
    else []
  in

  let odag = store_array_c n oloc output in
  let annot = nonstandard_optimizer list_of_buddy_stores odag in

  let body =
    Block
      ( [ Decl ("INT", i) ],
        [
          For
            ( Expr_assign (CVar i, CVar v),
              Binop (" > ", CVar i, Integer 0),
              list_to_comma
                [
                  Expr_assign
                    (CVar i, CPlus [ CVar i; CUminus (byvl (Integer 1)) ]);
                  Expr_assign
                    (CVar riarray, CPlus [ CVar riarray; byvl (CVar sivs) ]);
                  Expr_assign
                    (CVar iiarray, CPlus [ CVar iiarray; byvl (CVar sivs) ]);
                  Expr_assign
                    (CVar roarray, CPlus [ CVar roarray; byvl (CVar sovs) ]);
                  Expr_assign
                    (CVar ioarray, CPlus [ CVar ioarray; byvl (CVar sovs) ]);
                  make_volatile_stride (4 * n) (CVar istride);
                  make_volatile_stride (4 * n) (CVar ostride);
                ],
              Asch annot );
        ] )
  in

  let tree =
    Fcn
      ( template_prev_str ^ "STATIC GFFT_ALWAYS_INLINE " ^ "void",
        ename,
        [
          Decl (C.constrealtypep, riarray);
          Decl (C.constrealtypep, iiarray);
          Decl (C.realtypep, roarray);
          Decl (C.realtypep, ioarray);
          Decl (C.stridetype, istride);
          Decl (C.stridetype, ostride);
          Decl ("INT", v);
          Decl ("INT", "ivs");
          Decl ("INT", "ovs");
        ],
        finalize_fcn body )
  in

  unparse tree ^ "\n"

let main () =
  Simdmagic.simd_mode := false;
  parse speclist usage;
  print_string (generate (check_size ()));
  print_string template_after_str

let _ = main ()
