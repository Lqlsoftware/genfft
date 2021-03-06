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

let urs = ref Stride_variable

let ums = ref Stride_variable

let speclist =
  [
    ("-dit", Arg.Unit (fun () -> ditdif := DIT), " generate a DIT codelet");
    ("-dif", Arg.Unit (fun () -> ditdif := DIF), " generate a DIF codelet");
    ( "-with-rs",
      Arg.String (fun x -> urs := arg_to_stride x),
      " specialize for given i/o stride" );
    ( "-with-ms",
      Arg.String (fun x -> ums := arg_to_stride x),
      " specialize for given ms" );
  ]

let generate n =
  let rioarray = "ri"
  and iioarray = "ii"
  and rs = "rs"
  and twarray = "W"
  and m = "m"
  and mb = "mb"
  and me = "me"
  and ms = "ms" in

  let sign = !Genutil.sign
  and name = !Magic.codelet_name
  and byvl x = choose_simd x (ctimes (CVar "(2 * VL)", x)) in
  let ename = expand_name name in

  let bytwiddle, num_twiddles, twdesc = Twiddle.twiddle_policy 0 false in
  let nt = num_twiddles n in

  let byw = bytwiddle n sign (twiddle_array nt twarray) in

  let vrs = either_stride !urs (C.SVar rs) in
  let sms = stride_to_string "ms" !ums in

  let locations = unique_array_c n in
  let iloc =
    locative_array_c n
      (C.array_subscript rioarray vrs)
      (C.array_subscript iioarray vrs)
      locations sms
  and oloc =
    locative_array_c n
      (C.array_subscript rioarray vrs)
      (C.array_subscript iioarray vrs)
      locations sms
  in
  let liloc = load_array_c n iloc in
  let output =
    match !ditdif with
    | DIT -> array n (Fft.dft sign n (byw liloc))
    | DIF -> array n (byw (Fft.dft sign n liloc))
  in
  let odag = store_array_c n oloc output in
  let annot = standard_optimizer odag in

  let vm = CVar m and vmb = CVar mb and vme = CVar me in

  let body =
    Block
      ( [ Decl ("INT", m) ],
        [
          For
            ( list_to_comma
                [
                  Expr_assign (vm, vmb);
                  Expr_assign
                    ( CVar twarray,
                      CPlus [ CVar twarray; ctimes (vmb, Integer nt) ] );
                ],
              Binop (" < ", vm, vme),
              list_to_comma
                [
                  Expr_assign (vm, CPlus [ vm; byvl (Integer 1) ]);
                  Expr_assign
                    (CVar rioarray, CPlus [ CVar rioarray; byvl (CVar sms) ]);
                  Expr_assign
                    (CVar iioarray, CPlus [ CVar iioarray; byvl (CVar sms) ]);
                  Expr_assign
                    (CVar twarray, CPlus [ CVar twarray; byvl (Integer nt) ]);
                  make_volatile_stride (2 * n) (CVar rs);
                ],
              Asch annot );
        ] )
  in

  let tree =
    Fcn
      ( template_prev_str ^ "STATIC GFFT_ALWAYS_INLINE " ^ "void",
        ename,
        [
          Decl (C.realtypep, rioarray);
          Decl (C.realtypep, iioarray);
          Decl (C.constrealtypep, twarray);
          Decl (C.stridetype, rs);
          Decl ("INT", mb);
          Decl ("INT", me);
          Decl ("INT", ms);
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
  Simdmagic.simd_mode := false;
  parse (speclist @ Twiddle.speclist) usage;
  print_string (generate (check_size ()));
  print_string template_after_str

let _ = main ()
