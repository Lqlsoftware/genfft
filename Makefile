# Require: ocaml -version == 4.10.0
OCAMLBUILD := ocamlbuild

INSTALL_DIR := ../../gfft/operator/codelets
CURRENT_DIR := .

PRELUDE = cat PRELUDE; echo ""
ADD_DATE = sed -e s/@DATE@/"`date`"/
FORMAT = clang-format -style=file
MKDIR = mkdir -p

GEN_N = codelet_n.native
GEN_T = codelet_t.native
GEN_G = codelet_g.native
GEN_NV = codelet_n_simd.native
GEN_TV = codelet_t_simd.native
GEN_GV = codelet_g_simd.native

GEN_PLATFORM_FLAGS = -compact -variables 4 -pipeline-latency 4
GEN_PLATFORM_SIMD_FLAGS = -simd -compact -variables 4 -pipeline-latency 8

CODELET_N1 = 2 4 8 16 32 64
CODELET_N1_FLAGS = $(GEN_PLATFORM_FLAGS)
CODELET_T1 = 2 4 8 16 32 64
CODELET_T1_FLAGS = $(GEN_PLATFORM_FLAGS)
CODELET_T2 = 2 4 8 16 32 64
CODELET_T2_FLAGS = $(GEN_PLATFORM_FLAGS) -twiddle-log3 -precompute-twiddles
CODELET_G1 = 2 4 8 16 32 64
CODELET_G1_FLAGS = $(GEN_PLATFORM_FLAGS)
CODELET_G2 = 2 4 8 16 32 64
CODELET_G2_FLAGS = $(GEN_PLATFORM_FLAGS) -twiddle-log3 -precompute-twiddles

CODELET_N1V = 2 4 8 16 32 64
CODELET_N1V_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS)
CODELET_N2V = 2 4 8 16 32 64
CODELET_N2V_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS) -with-ostride 2 -store-multiple 2
CODELET_N3V = 2 4 8 16 32 64
CODELET_N3V_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS) -with-ostride 2 -store-multiple 2
CODELET_T1V = 2 4 8 16 32 64
CODELET_T1V_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS)
CODELET_T1UV = 2 4 8
CODELET_T1UV_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS)
CODELET_T2V = 2 4 8 16 32 64
CODELET_T2V_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS)
CODELET_T3V = 2 4 8 16 32 64
CODELET_T3V_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS) -twiddle-log3 -precompute-twiddles -no-generate-bytw
CODELET_G1V = 2 4 8 16 32 64
CODELET_G1V_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS)
CODELET_G2V = 2 4 8 16 32 64
CODELET_G2V_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS)
CODELET_G3V = 2 4 8 16 32 64
CODELET_G3V_FLAGS = $(GEN_PLATFORM_SIMD_FLAGS) -twiddle-log3 -precompute-twiddles -no-generate-bytw

CODELETS = 	$(addsuffix .h,\
			$(addprefix $(INSTALL_DIR)/reference/n1/n1_, $(CODELET_N1)) 	\
			$(addprefix $(INSTALL_DIR)/reference/t1/t1_, $(CODELET_T1)) 	\
			$(addprefix $(INSTALL_DIR)/reference/t2/t2_, $(CODELET_T2)) 	\
			$(addprefix $(INSTALL_DIR)/reference/g1/g1_, $(CODELET_G1)) 	\
			$(addprefix $(INSTALL_DIR)/reference/g2/g2_, $(CODELET_G2)) 	\
			$(addprefix $(INSTALL_DIR)/simd/n1/n1fv_, 	 $(CODELET_N1V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/n1/n1bv_, 	 $(CODELET_N1V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/n2/n2fv_, 	 $(CODELET_N2V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/n2/n2bv_, 	 $(CODELET_N2V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/n3/n3fv_, 	 $(CODELET_N3V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/n3/n3bv_, 	 $(CODELET_N3V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/t1/t1fv_, 	 $(CODELET_T1V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/t1/t1bv_, 	 $(CODELET_T1V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/t1/t1fuv_, 	 $(CODELET_T1UV)) 	\
			$(addprefix $(INSTALL_DIR)/simd/t1/t1buv_, 	 $(CODELET_T1UV)) 	\
			$(addprefix $(INSTALL_DIR)/simd/t2/t2fv_, 	 $(CODELET_T2V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/t2/t2bv_, 	 $(CODELET_T2V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/t3/t3fv_, 	 $(CODELET_T3V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/t3/t3bv_, 	 $(CODELET_T3V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/g1/g1fv_, 	 $(CODELET_G1V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/g1/g1bv_, 	 $(CODELET_G1V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/g2/g2fv_, 	 $(CODELET_G2V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/g2/g2bv_, 	 $(CODELET_G2V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/g3/g3fv_, 	 $(CODELET_G3V)) 	\
			$(addprefix $(INSTALL_DIR)/simd/g3/g3bv_, 	 $(CODELET_G3V))	\
			)

GENFFT_NATIVE = $(GEN_N) $(GEN_NV) \
				$(GEN_T) $(GEN_TV) \
				$(GEN_G) $(GEN_GV)

$(GENFFT_NATIVE):
	cd $(CURRENT_DIR); $(OCAMLBUILD) -classic-display -libs unix,nums -I src $(GENFFT_NATIVE)

clean:
	$(OCAMLBUILD) -classic-display -clean

install: $(GENFFT_NATIVE) $(CODELETS)

$(INSTALL_DIR)/reference/n1/n1_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_N) $(CODELET_N1_FLAGS) -n $* -name n1_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/reference/t1/t1_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_T) $(CODELET_T1_FLAGS) -n $* -name t1_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/reference/t2/t2_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_T) $(CODELET_T2_FLAGS) -n $* -name t2_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/reference/g1/g1_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_G) $(CODELET_G1_FLAGS) -n $* -name g1_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/reference/g2/g2_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_G) $(CODELET_G2_FLAGS) -n $* -name g2_$*) | $(ADD_DATE) | $(FORMAT) > $@
	
$(INSTALL_DIR)/simd/n1/n1fv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_NV) $(CODELET_N1V_FLAGS) -n $* -name n1fv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/n1/n1bv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_NV) $(CODELET_N1V_FLAGS) -sign 1 -n $* -name n1bv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/n2/n2fv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_NV) $(CODELET_N2V_FLAGS) -n $* -name n2fv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/n2/n2bv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_NV) $(CODELET_N2V_FLAGS) -sign 1 -n $* -name n2bv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/n3/n3fv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_NV) $(CODELET_N3V_FLAGS) -n $* -name n3fv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/n3/n3bv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_NV) $(CODELET_N3V_FLAGS) -sign 1 -n $* -name n3bv_$*) | $(ADD_DATE) | $(FORMAT) > $@

$(INSTALL_DIR)/simd/t1/t1fv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_TV) $(CODELET_T1V_FLAGS) -n $* -name t1fv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/t1/t1bv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_TV) $(CODELET_T1V_FLAGS) -sign 1 -n $* -name t1bv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/t1/t1fuv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_TV) $(CODELET_T1UV_FLAGS) -n $* -name t1fuv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/t1/t1buv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_TV) $(CODELET_T1UV_FLAGS) -sign 1 -n $* -name t1buv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/t2/t2fv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_TV) $(CODELET_T2V_FLAGS) -n $* -name t2fv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/t2/t2bv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_TV) $(CODELET_T2V_FLAGS) -sign 1 -n $* -name t2bv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/t3/t3fv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_TV) $(CODELET_T3V_FLAGS) -n $* -name t3fv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/t3/t3bv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_TV) $(CODELET_T3V_FLAGS) -sign 1 -n $* -name t3bv_$*) | $(ADD_DATE) | $(FORMAT) > $@

$(INSTALL_DIR)/simd/g1/g1fv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_GV) $(CODELET_G1V_FLAGS) -n $* -name g1fv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/g1/g1bv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_GV) $(CODELET_G1V_FLAGS) -sign 1 -n $* -name g1bv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/g2/g2fv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_GV) $(CODELET_G2V_FLAGS) -n $* -name g2fv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/g2/g2bv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_GV) $(CODELET_G2V_FLAGS) -sign 1 -n $* -name g2bv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/g3/g3fv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_GV) $(CODELET_G3V_FLAGS) -n $* -name g3fv_$*) | $(ADD_DATE) | $(FORMAT) > $@
$(INSTALL_DIR)/simd/g3/g3bv_%.h:
	$(MKDIR) $(@D) && ($(PRELUDE); $(CURRENT_DIR)/$(GEN_GV) $(CODELET_G3V_FLAGS) -sign 1 -n $* -name g3bv_$*) | $(ADD_DATE) | $(FORMAT) > $@
