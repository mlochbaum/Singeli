# CPU architecture

Spl ← (⊢-˜+`×¬)∘=⊔⊢
ToUpper ← ((-´"Aa")×'a'⊸≤∧≤⟜'z')⊸+
TSort ← {{𝕊⍟(𝕩<○≠⊢)⟜(𝕩∾·/𝕨⊸<)𝕨∨∧´∘⊏⟜𝕨¨p}⟜/0¨p←𝕩} # Topological sort

MakeArch ← {
  name‿width‿VecType ⇐ extfile‿header ← 𝕩
  Headers ⇐ {(𝕩>0)/⟨header⟩}
  # d is a list of extension dependency chains
  u ← ⍷∾ d ← ' ' Spl¨ •file.Lines ∾"data/"‿extfile‿"_ext.txt"
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

arches ← MakeArch¨ ⟨
  {
    name ⇐ "X86_64"
    width ⇐ 64
    extfile ⇐ "x86"
    header ⇐ "immintrin.h"
    VecType ⇐ { 𝕊 w‿v‿u‿f:
      "Unsupported vector type" ! ∊⟜(2⋆6+↕4)⌾<l←w×v  # 64…512
      ⟨5-˜2⋆⁼l, ∾⟨"__m", •Repr l, {l=64?"";¬f?"i";(64=w)/"d"}⟩⟩
    }
  }
  {
    name ⇐ "AARCH64"
    width ⇐ 64
    extfile ⇐ "armv8"
    header ⇐ "arm_neon.h"
    VecType ⇐ { 𝕊 w‿v‿u‿f:
      1 ⋈ ∾⟨{f?"float"; (u/"u")∾"int"}, •Repr w, "x", •Repr v, "_t"⟩
    }
  }
⟩

allfeats ← ∾ archfeats ← {𝕩.feats}¨ arches

ReadNative ← {𝕊:
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
      a ← "hw.optional.arm.FEAT"
      ⋈ToUpper ":"∾ ∾ {' '⌾⊑(≠a)↓(∧`':'⊸≠)⊸/𝕩}¨ a⊸(⊣≡≠⊸↑)¨⊸/ l
    }
  ;
    ! "Couldn't find CPU features"
  }
  f ↩ ∾ (' ' Spl 2↓(∨`':'⊸=)⊸/)¨ f
  f ↩ "PNI"‿"BMI1"‿"PCLMULQDQ"‿"AVX1.0"⊸⊐⊸(⊣◶⟨"SSE3",¯1⊸↓,¯3⊸↓,¯3⊸↓,⊢⟩¨) f
  ∊⟜allfeats⊸/ ((-´"._")×'_'⊸=)⊸+ f
}

MaybeNat ← "NATIVE"⊸≡¨ (¬⊸/∾ReadNative)⍟((0=≠)⊸(∨´)⊣) ⊢
arg ← ⟨"NONE"⟩⊸≢◶⟨⟩‿MaybeNat ToUpper •args
all ← "ALL"⊸≡¨ arg
!∘(∾"Unknown features:"<⊸∾' '∾¨/⟜arg)⍟(∨´) ¬all∨arg∊allfeats
"Incompatible features" ! ∨´ supp ← (all¬⊸/arg)⊸(∧´∊)¨ archfeats
arch ← ⊑ supp / arches

⟨width, VecType, Headers, feats⟩ ⇐ arch
mat ⇐ arch.GetMat@

baseArch ⇐ ∨˝∘∧⟜mat (∨´all)◶⟨∊⟜arg,1¨⟩ feats

FeatInd ⇐ { # 𝕨 is 0 to allow features outside current architecture
  i ← feats ⊐ 𝕩
  m ← (i=≠feats)/○⥊𝕩
  !∘(∾"Unknown architecture features:"<⊸∾' '∾¨/⟜m)⍟(∨´) ¬m∊allfeats
  !∘(1↓·∾' '∾¨⟨"Features not in",arch.name,"architecture:"⟩∾⊢)⍟(0<≠)⍟𝕨 m
  i
}
