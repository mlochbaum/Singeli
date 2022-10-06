# Utilities for dealing with CPU architectures

Spl ← (⊢-˜+`×¬)∘=⊔⊢

# 𝕩 is a list of extension dependency chains.
# Return a list of unique feature flags and dependency matrix m.
# Such that i‿j⊑m is 1 iff feature i depends on j.
ArchFlagAndMat ⇐ {
  TSort ← {{𝕊⍟(𝕩<○≠⊢)⟜(𝕩∾·/𝕨⊸<)𝕨∨∧´∘⊏⟜𝕨¨p}⟜/0¨p←𝕩} # Topological sort
  d ← ' ' Spl¨ 𝕩
  u ← ⍷∾d
  u ⊏˜↩ TSort ∾¨ (⊢⊔○∾(¯1↓↑)¨) (<u)⊐¨d
  m ← ∨˝∘∧⎉1‿∞˜⍟(⌈2⋆⁼≠) (≥⌜˜↕∘≠)⊸×∨´×⌜˜¨(<u)∊¨d    # Dependency matrix
  u‿m
}

ReadNative ← {𝕊:
  c ← 1⊑ •SH "cat"‿"/proc/cpuinfo"
  f ← ⊑ "flags"⊸(⊣≡≠⊸↑)¨⊸/ (@+10) Spl c  # Line with flags"
  ((-´"Aa")×'a'⊸≤)⊸+ ' ' Spl 2↓(∨`':'⊸=)⊸/ f
}

BaseArch ⇐ { u 𝕊 feats:
  feats ↩ ((-´"Aa")×'a'⊸≤)⊸+ ∾','⊸Spl¨ feats
  !∘(∾"Unknown features:"<⊸∾' '∾¨/⟜feats)⍟(∨´) ¬feats∊u∾"NONE"‿"NATIVE"‿"ALL"
  ⟨uf,nat‿all⟩ ← ¯2(↓⋈↑)(u∾"NATIVE"‿"ALL")∊feats
  nat ∨↩ 0=≠feats
  (¬all)◶⟨1¨, (u∊ReadNative)⊸∨⍟nat⟩ uf
}
