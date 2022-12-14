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
      ⟨5-˜2⋆⁼l, ∾⟨"__m", •Repr l, {¬f?"i";(64=w)/"d"}⟩⟩
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
  c ← 1⊑ •SH "cat"‿"/proc/cpuinfo"
  f ← ⊑ (∨˝"flags"‿"Features"(⊣≡≠⊸↑)⌜⊢)⊸/ (@+10) Spl c  # Line with flags
  f ↩ ' ' Spl 2↓(∨`':'⊸=)⊸/ f
  f ↩ "pni"‿"bmi1"‿"pclmulqdq"⊸⊐⊸(⊣◶⟨"sse3",¯1⊸↓,¯3⊸↓,⊢⟩¨) f
  ∊⟜(∾allfeats)⊸/ ((-´"._")×'_'⊸=)⊸+ ((-´"Aa")×'a'⊸≤)⊸+ f
}

arg ← ToUpper ∾','⊸Spl¨ •args
arg ("NATIVE"⊸≡¨ (¬⊸/∾ReadNative)⍟((0=≠)⊸(∨´)⊣) ⊢)↩
!∘(∾"Unknown features:"<⊸∾' '∾¨/⟜arg)⍟(∨´) ¬arg∊allfeats∾⟨"ALL"⟩
"Incompatible features" ! ∨´ supp ← arg⊸(∧´∊)¨ archfeats
arch ← ⊑ supp / arches

⟨width, VecType, Headers, feats⟩ ⇐ arch
mat ⇐ arch.GetMat@

baseArch ⇐ (⊑ ⊣◶⟨1¨,⊢⟩ 1⊸↓) (⟨"ALL"⟩∾feats)∊arg

FeatInd ⇐ { # 𝕨 is 0 to allow features outside current architecture
  i ← feats ⊐ 𝕩
  m ← (i=≠feats)/○⥊𝕩
  !∘(∾"Unknown architecture features:"<⊸∾' '∾¨/⟜m)⍟(∨´) ¬m∊allfeats
  !∘(1↓·∾' '∾¨⟨"Features not in",arch.name,"architecture:"⟩∾⊢)⍟(0<≠)⍟𝕨 m
  i
}
