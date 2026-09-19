# CPU architecture definitions and utilities

Spl ← (⊢-˜+`×¬)∘=⊔⊢
ToUpper ⇐ ((-´"Aa")×'a'⊸≤∧≤⟜'z')⊸+
UtoDot ← ((-´"._")×'_'⊸=)⊸+

ReadDeps ⇐ {@:⟨⟩; ' ' Spl¨ •file.Lines ∾"data/"‿𝕩‿"_ext.txt" }
ReadFeats ← { ⟨𝕨⟩ ∾ ⍷∾ ReadDeps 𝕩 }

unknownArch ← {
  width ⇐ 𝕩
  name ⇐ "UNKNOWN" ∾ •Repr width
  extfile ⇐ @
  feats ⇐ ⟨name⟩
  header ⇐ "(no vector types)"
  mainDefine ⇐ "__"∾name
  StripDefines ⇐ ⟨"UNKNOWN"⟩˙
  VecType ⇐ {𝕊: <"Vector types not supported on "∾name}
}¨ 64‿32

arches ⇐ unknownArch ∾ ⟨
  {
    name ⇐ "X86_64"
    width ⇐ 64
    ExtFile ⇐ {𝕩⊑"x86_strict"‿"x86"}
    feats ⇐ name ReadFeats ExtFile 0
    header ⇐ "immintrin.h"
    VecType ⇐ {
      𝕊 1‿⟨v⟩‿1‿0: v≤64?
        { ∊⟜(2⋆1+↕6)⌾<v ? ⟨4, "__mmask"∾•Repr 8⌈v⟩ # AVX-512 mask
        ; <"mask register length must a power of 2 between 2 and 64" } ;
      𝕊 w‿⟨v⟩‿u‿f:
        { ∊⟜(2⋆6+↕4)⌾<l←w×v ? ⟨5-˜2⋆⁼l, ∾⟨"__m", •Repr l, {l=64?"";¬f?"i";(64=w)/"d"}⟩⟩
        ; <"non-boolean register width must a power of 2 between 64 and 512" } ;
      <"nested vector type unsupported in x86"
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
      <"Nested vector type not yet supported in ARM"
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
      <"Only two levels of vector nesting supported in RISC-V"
    }
    mainDefine ⇐ "__riscv_xlen"
    StripDefines ⇐ { "RVV"¨ "__riscv_v"⊸≡¨⊸/ 𝕩 }
  }
⟩

# Attempt to get the CPU's native architecture from OS resources
ReadNative ⇐ {𝕊:
  f ← {
    cf ← {
      0<≠c ←  1⊑•SH "cat"‿"/proc/cpuinfo" ? ⟨c, "flags"‿"Features"⟩ ;
      0<≠c ← (1⊑•SH)⎊⟨⟩ ⟨"lscpu"⟩         ? ⟨c, ⟨"Flags"⟩⟩ ;
      @
    }
    @≢cf ? c‿f ← cf
    l ← (∨˝f(⊣≡≠⊸↑)⌜⊢)⊸/ (@+10) Spl c  # Line with flags
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
  f ↩ "PNI"‿"ABM"‿"BMI1"‿"PCLMULQDQ"‿"AVX1.0"⊸⊐⊸(⊣◶⟨"SSE3","LZCNT",¯1⊸↓,¯3⊸↓,¯3⊸↓,⊢⟩¨) f
  UtoDot '_'⊸≠⊸/⍟("AVX512"(⊣≡≠⊸↑)⊢)¨ f
}

# Get extension list from a list of C defines as returned by cc -dM -E
ParseCDefines ⇐ { 𝕊 lines:
  pre ← "#define "
  ! ∧´ pre⊸(⊣≡≠⊸↑)¨ lines
  names ← (∧`' '⊸≠)⊸/¨ (≠pre)⊸↓¨ lines
  as ← ({𝕩.mainDefine}¨ ∊ names˙)⊸/ arches
  {⟨a⟩: ⟨a.name⟩ ∾ ∊⟜a.feats⊸/ UtoDot a.StripDefines names; ⟨"NONE"⟩} as
}
