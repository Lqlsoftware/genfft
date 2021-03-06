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

type ditdif = DIT | DIF

let ditdif = ref DIT

let usage = "Usage: " ^ Sys.argv.(0) ^ " -n <number> [ -dit | -dif ]"

let uistride = ref Stride_variable

let uostride = ref Stride_variable

let uivstride = ref Stride_variable

let uovstride = ref Stride_variable

let speclist =
  [
    ("-dit", Arg.Unit (fun () -> ditdif := DIT), " generate a DIT codelet");
    ("-dif", Arg.Unit (fun () -> ditdif := DIF), " generate a DIF codelet");
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
  let riarray = "xi"
  and roarray = "xo"
  and istride = "is"
  and ostride = "os"
  and twarray = "W"
  and i = "i"
  and v = "v" in

  let sign = !Genutil.sign
  and name = !Magic.codelet_name
  and byvl x = choose_simd x (ctimes (CVar "VL", x))
  and bytwvl x = choose_simd x (ctimes (CVar "TWVL", x)) in
  let ename = expand_name name in

  let vistride = either_stride !uistride (C.SVar istride)
  and vostride = either_stride !uostride (C.SVar ostride) in

  let sovs = stride_to_string "ovs" !uovstride in
  let sivs = stride_to_string "ivs" !uivstride in

  let bytwiddle, num_twiddles, twdesc = Twiddle.twiddle_policy 0 true in
  let nt = num_twiddles n in

  let byw = bytwiddle n sign (twiddle_array nt twarray) in

  let locations = unique_array_c n in
  let input =
    locative_array_c n
      (C.array_subscript riarray vistride)
      (C.array_subscript "BUG" vistride)
      locations sivs
  in
  let iloc = load_array_r n input in
  let fft = Trig.dft_via_rdft in
  let output =
    match !ditdif with
    | DIT -> array n (fft sign n (byw iloc))
    | DIF -> array n (byw (fft sign n iloc))
  in
  let oloc =
    locative_array_c n
      (C.array_subscript roarray vostride)
      (C.array_subscript "BUG" vostride)
      locations sovs
  in
  let list_of_buddy_stores =
    let k = !Simdmagic.store_multiple in
    if k > 1 then
      if n mod k == 0 then
        List.map
          (fun i -> List.map (fun j -> fst (oloc ((k * i) + j))) (iota k))
          (iota (n / k))
      else failwith "invalid n for -store-multiple"
    else []
  in
  let odag = store_array_r n oloc output in
  let annot = nonstandard_optimizer list_of_buddy_stores odag in

  let body =
    Block
      ( [
          Decl ("INT", i);
          Decl (C.constrealtypep, riarray);
          Decl (C.realtypep, roarray);
        ],
        [
          Stmt_assign (CVar riarray, CVar (if sign < 0 then "ri" else "ii"));
          Stmt_assign (CVar roarray, CVar (if sign < 0 then "ro" else "io"));
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
                    (CVar roarray, CPlus [ CVar roarray; byvl (CVar sovs) ]);
                  Expr_assign
                    (CVar twarray, CPlus [ CVar twarray; bytwvl (Integer nt) ]);
                  make_volatile_stride (2 * n) (CVar istride);
                  make_volatile_stride (2 * n) (CVar ostride);
                ],
              Asch annot );
        ] )
  in

  let tree =
    Fcn
      ( template_prev_str ^ "STATIC GFFT_ALWAYS_INLINE " ^ "void",
        ename,
        [
          Decl (C.constrealtypep, "ri");
          Decl (C.constrealtypep, "ii");
          Decl (C.realtypep, "ro");
          Decl (C.realtypep, "io");
          Decl (C.constrealtypep, twarray);
          Decl (C.stridetype, istride);
          Decl (C.stridetype, ostride);
          Decl ("INT", v);
          Decl ("INT", "ivs");
          Decl ("INT", "ovs");
        ],
        finalize_fcn body )
  in

  let twinstr =
    Printf.sprintf "const TwDesc %s[] = %s;\n\n" (declare_twinstr name)
      (twinstr_to_string "(2 * VL)" (twdesc n))
  in
  let init = "\n" ^ twinstr ^ "\n" in

  unparse tree ^ "\n" ^ init

let main () =
  Simdmagic.simd_mode := true;
  parse (speclist @ Twiddle.speclist) usage;
  print_string (generate (check_size ()));
  print_string template_after_str

let _ = main ()
