# CPU architecture definitions and utilities

Spl ← (⊢-˜+`×¬)∘=⊔⊢
ToUpper ⇐ ((-´"Aa")×'a'⊸≤∧≤⟜'z')⊸+
TSort ← {{𝕊⍟(𝕩<○≠⊢)⟜(𝕩∾·/𝕨⊸<)𝕨∨∧´∘⊏⟜𝕨¨p}⟜/0¨p←𝕩} # Topological sort

ReadDeps ← { ' ' Spl¨ •file.Lines ∾"data/"‿𝕩‿"_ext.txt" }
ReadFeats ← { ⟨𝕨⟩ ∾ ⍷∾ ReadDeps 𝕩 }

MakeArch ⇐ {
  name‿width‿VecType ⇐ ExtFile‿header ← 𝕩
  infer ← 𝕨⊣0
  Headers ⇐ {(𝕩>0)/⟨header⟩}
  # d is a list of extension dependency chains
  u ← ⍷∾ d ← ReadDeps ExtFile infer
  u ⊏˜↩ TSort ∾¨ (⊢⊔○∾(¯1↓↑)¨) (<u)⊐¨d
  # Unique feature flags including arch name
  feats ⇐ ⟨name⟩ ∾ u
  # Make a dependency matrix: i‿j⊑m is 1 iff feature i depends on j
  GetMat ⇐ {𝕊:
    m ← (≥⌜˜↕∘≠)⊸×∨´×⌜˜¨(<u)∊¨d # Dependencies from file
    m ∨˝∘∧⎉1‿∞˜⍟(⌈2⋆⁼≠)↩        # Transitive closure
    1 ∾˘ 0¨∘⊏⊸∾ m               # Plus base architecture
  }
}

arches ⇐ ⟨
  {
    name ⇐ "X86_64"
    width ⇐ 64
    ExtFile ⇐ {𝕩⊑"x86_strict"‿"x86"}
    feats ⇐ name ReadFeats ExtFile 0
    header ⇐ "immintrin.h"
    us ← "Unsupported vector type"
    VecType ⇐ {
      𝕊 1‿⟨v⟩‿1‿0: v≤64?
        us ! ∊⟜(2⋆3+↕4)⌾<v      # 8…64
        ⟨4, "__mmask"∾•Repr v⟩; # AVX-512 mask
      𝕊 w‿⟨v⟩‿u‿f:
        us ! ∊⟜(2⋆6+↕4)⌾<l←w×v  # 64…512
        ⟨5-˜2⋆⁼l, ∾⟨"__m", •Repr l, {l=64?"";¬f?"i";(64=w)/"d"}⟩⟩;
      !"Nested vector type unsupported in x86"
    }
    mainDefine ⇐ "__x86_64__"
    StripDefines ⇐ { u ← "__" ⋄ (¯2↓2↓⊢)¨ ((u≡2⊸↑)∧u≡¯2⊸↑)¨⊸/ 𝕩 }
  }
  {
    name ⇐ "AARCH64"
    width ⇐ 64
    feats ⇐ name ReadFeats extfile ⇐ "armv8"
    header ⇐ "arm_neon.h"
    VecType ⇐ {
      𝕊 w‿⟨v⟩‿u‿f:
        1 ⋈ ∾⟨{f?"float"; (u/"u")∾"int"}, •Repr w, "x", •Repr v, "_t"⟩;
      !"Nested vector type not yet supported in ARM"
    }
    mainDefine ⇐ "__aarch64__"
    StripDefines ⇐ { l←≠pre←"__ARM_FEATURE_" ⋄ l↓¨(pre≡l⊸↑)¨⊸/ 𝕩 }
  }
  {
    name ⇐ "RV64"
    width ⇐ 64
    feats ⇐ name ReadFeats extfile ⇐ "rv"
    header ⇐ "riscv_vector.h"
    VecType ⇐ {
      𝕊 ⟨w, x‿v, u, f⟩: 1 ⋈ ∾⟨¯2↓1⊑𝕊 w‿⟨v⟩‿u‿f, 'x', •Repr x, "_t"⟩;
      𝕊 1‿⟨v⟩‿1‿0:
        1 ⋈ ∾⟨"vbool", •Repr 128÷v, "_t"⟩;
      𝕊 w‿⟨v⟩‿u‿f:
        lmul ← (v×w)÷128
        mf ← lmul<1
        1 ⋈ ∾⟨"v", {f?"float"; (u/"u")∾"int"}, •Repr w, "m", mf/"f", •Repr ÷⍟mf lmul, "_t"⟩;
      !"Only two levels of vector nesting supported in RISC-V"
    }
    mainDefine ⇐ "__riscv_xlen"
    StripDefines ⇐ { "RVV"¨ "__riscv_v"⊸≡¨⊸/ 𝕩 }
  }
⟩

allfeats ⇐ ∾ archfeats ⇐ {𝕩.feats}¨ arches

ReadNative ⇐ {𝕊:
  f ← {
    c ← 1⊑ •SH "cat"‿"/proc/cpuinfo"
    l ← (∨˝"flags"‿"Features"(⊣≡≠⊸↑)⌜⊢)⊸/ (@+10) Spl c  # Line with flags
    0<≠l ? ToUpper¨ 1↑l
  ;
    l ← (@+10) Spl (1⊑•SH)⎊⟨⟩ "sysctl"‿"machdep.cpu" # For macs
    0<≠l ? {
      ∨´(∨´"feature"⊸⍷)¨l ? l
    ;
      l ← (@+10) Spl 1⊑ •SH "sysctl"‿"hw.optional" # ARM
      ⋈ToUpper ":"∾ ∾ {" "∾(∧`⌾⌽·¬∊⟜"_.")⊸/(∧`':'⊸≠)⊸/𝕩}¨ ('0'≠⊢´¨)⊸/ l
    }
  ;
    ! "Couldn't find CPU features"
  }
  f ↩ ∾ (' ' Spl 2↓(∨`':'⊸=)⊸/)¨ f
  f ↩ "PNI"‿"BMI1"‿"PCLMULQDQ"‿"AVX1.0"⊸⊐⊸(⊣◶⟨"SSE3",¯1⊸↓,¯3⊸↓,¯3⊸↓,⊢⟩¨) f
  f ↩ '_'⊸≠⊸/⍟("AVX512"(⊣≡≠⊸↑)⊢)¨ f
  ∊⟜allfeats⊸/ ((-´"._")×'_'⊸=)⊸+ f
}

# Get extension list from a list of C defines as returned by cc -dM -E
ParseCDefines ⇐ { 𝕊 lines:
  pre ← "#define "
  ! ∧´ pre⊸(⊣≡≠⊸↑)¨ lines
  names ← (∧`' '⊸≠)⊸/¨ (≠pre)⊸↓¨ lines
  as ← ({𝕩.mainDefine}¨ ∊ names˙)⊸/ arches
  0 < ≠as?
  arch ← ⊑ as
  ⟨arch.name⟩ ∾ ∊⟜arch.feats⊸/ ((-´"._")×'_'⊸=)⊸+ arch.StripDefines names
  ; ⟨"NONE"⟩
}
