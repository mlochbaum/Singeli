# CPU architecture namespace, based on provided feature set argfeats
argfeats‿infer ← ⋈⟜0⍟(0=≠) •args

arches‿ReadDeps‿ReadNative‿ToUpper ← •Import "archutil.bqn"

# Process feature flags and detect architecture family
allfeats ← ∾ archfeats ← {𝕩.feats}¨ arches
AllNat ← ∊⟜allfeats⊸/ ReadNative
MaybeNat ← "NATIVE"⊸≡¨ (¬⊸/∾AllNat)⍟((0=≠)⊸(∨´)⊣) ⊢
arg ← ⟨"NONE"⟩⊸≢◶⟨⟩‿MaybeNat ToUpper argfeats
all ← "ALL"⊸≡¨ arg
!∘(∾"Unknown features:"<⊸∾' '∾¨/⟜arg)⍟(∨´) ¬all∨arg∊allfeats
"Incompatible features" ! ∨´ supp ← (all¬⊸/arg)⊸(∧´∊)¨ archfeats
archDesc ← ⊑ supp / arches
width‿VecType‿header ⇐ ⟨aname⇐name⟩ ← archDesc

# Parse dependencies for the chosen architecture
⟨feats, mat⟩ ⇐ {
  TSort ← {{𝕊⍟(𝕩<○≠⊢)⟜(𝕩∾·/𝕨⊸<)𝕨∨∧´∘⊏⟜𝕨¨p}⟜/0¨p←𝕩} # Topological sort
  # d is a list of extension dependency chains
  u ← ⍷∾ d ← ReadDeps archDesc.ExtFile infer
  u ⊏˜↩ TSort ∾¨ (⊢⊔○∾(¯1↓↑)¨) (<u)⊐¨d
  # Unique feature flags including arch name
  feats ⇐ ⟨aname⟩ ∾ u
  # Make a dependency matrix: i‿j⊑m is 1 iff feature i depends on j
  mat ⇐ {
    0=≠u? ≍≍1 ;
    m ← (≥⌜˜↕∘≠)⊸×∨´×⌜˜¨(<u)∊¨d # Dependencies from file
    m ∨˝∘∧⎉1‿∞˜⍟(⌈2⋆⁼≠)↩        # Transitive closure
    1 ∾˘ 0¨∘⊏⊸∾ m               # Plus base architecture
  }
}
baseArch ⇐ ∨˝∘∧⟜mat (∨´all)◶⟨∊⟜arg,1¨⟩ feats

FeatInd ⇐ { # 𝕨 is 0 to allow features outside current architecture
  i ← feats ⊐ 𝕩
  m ← (i=≠feats)/○⥊𝕩
  !∘(∾"arch: Unknown architecture features:"<⊸∾' '∾¨/⟜m)⍟(∨´) ¬m∊allfeats
  !∘(1↓·∾' '∾¨⟨"arch: Features not in",aname,"architecture:"⟩∾⊢)⍟(0<≠)⍟𝕨 m
  i
}

# For external tools, return base architecture as C compiler flags
GetCFlags ⇐ {𝕊:
  "-m"⊸∾¨ ((-´"aA")×'A'⊸≤∧≤⟜'Z')⊸+ (baseArch ∧ (aname)⊸≢¨)⊸/ feats
}
