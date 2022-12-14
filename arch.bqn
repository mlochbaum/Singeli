# CPU architecture

Spl ← (⊢-˜+`×¬)∘=⊔⊢

ReadExt ← { ' ' Spl¨ •file.Lines ∾"data/"‿𝕩‿"_ext.txt" }

arches ← ⟨
  {
    name ⇐ "X86_64"
    width ⇐ 64
    ext ⇐ ReadExt "x86"
    VecType ⇐ { 𝕊 w‿v‿u‿f:
      "Unsupported vector type" ! ∊⟜(2⋆6+↕4)⌾<l←w×v  # 64…512
      ⟨5-˜2⋆⁼l, ∾⟨"__m", •Repr l, {¬f?"i";(64=w)/"d"}⟩⟩
    }
    Headers ⇐ {(𝕩>0)/⟨"immintrin.h"⟩}
  }
  {
    name ⇐ "AARCH64"
    width ⇐ 64
    ext ⇐ ReadExt "armv8"
    VecType ⇐ { 𝕊 w‿v‿u‿f:
      1 ⋈ ∾⟨{f?"float"; (u/"u")∾"int"}, •Repr w, "x", •Repr v, "_t"⟩
    }
    Headers ⇐ {(𝕩>0)/⟨"arm_neon.h"⟩}
  }
⟩

allfeats ← ∾ archfeats ← {⟨𝕩.name⟩∾∾𝕩.ext}¨ arches
ReadNative ← {𝕊:
  c ← 1⊑ •SH "cat"‿"/proc/cpuinfo"
  f ← ⊑ (∨˝"flags"‿"Features"(⊣≡≠⊸↑)⌜⊢)⊸/ (@+10) Spl c  # Line with flags
  f ↩ ' ' Spl 2↓(∨`':'⊸=)⊸/ f
  f ↩ "pni"‿"bmi1"‿"pclmulqdq"⊸⊐⊸(⊣◶⟨"sse3",¯1⊸↓,¯3⊸↓,⊢⟩¨) f
  ∊⟜(∾allfeats)⊸/ ((-´"._")×'_'⊸=)⊸+ ((-´"Aa")×'a'⊸≤)⊸+ f
}

feats ← ((-´"Aa")×'a'⊸≤)⊸+ ∾','⊸Spl¨ •args
feats ("NATIVE"⊸≡¨ (¬⊸/∾ReadNative)⍟((0=≠)⊸(∨´)⊣) ⊢)↩
!∘(∾"Unknown features:"<⊸∾' '∾¨/⟜feats)⍟(∨´) ¬feats∊allfeats∾⟨"ALL"⟩
"Incompatible features" ! ∨´ supp ← feats⊸(∧´∊)¨ archfeats
arch ← ⊑ supp / arches

⟨width, VecType, Headers⟩ ⇐ arch

# 𝕩 is a list of extension dependency chains.
# Return a list of unique feature flags and dependency matrix m.
# Such that i‿j⊑m is 1 iff feature i depends on j.
flag‿mat ⇐ {
  TSort ← {{𝕊⍟(𝕩<○≠⊢)⟜(𝕩∾·/𝕨⊸<)𝕨∨∧´∘⊏⟜𝕨¨p}⟜/0¨p←𝕩} # Topological sort
  d ← arch.ext
  u ← ⍷∾d
  u ⊏˜↩ TSort ∾¨ (⊢⊔○∾(¯1↓↑)¨) (<u)⊐¨d
  m ← ∨˝∘∧⎉1‿∞˜⍟(⌈2⋆⁼≠) (≥⌜˜↕∘≠)⊸×∨´×⌜˜¨(<u)∊¨d    # Dependency matrix
  u‿m
}

baseArch ⇐ (⊑ ⊣◶⟨1¨,⊢⟩ 1⊸↓) (⟨"ALL"⟩∾flag)∊feats
