# CPU feature processing
argfeats‿infer ← ⋈⟜0⍟(0=≠) •args

arches‿allfeats‿archfeats‿MakeArch‿ReadNative‿ToUpper ← •Import "archutil.bqn"

MaybeNat ← "NATIVE"⊸≡¨ (¬⊸/∾ReadNative)⍟((0=≠)⊸(∨´)⊣) ⊢
arg ← ⟨"NONE"⟩⊸≢◶⟨⟩‿MaybeNat ToUpper argfeats
all ← "ALL"⊸≡¨ arg
!∘(∾"Unknown features:"<⊸∾' '∾¨/⟜arg)⍟(∨´) ¬all∨arg∊allfeats
"Incompatible features" ! ∨´ supp ← (all¬⊸/arg)⊸(∧´∊)¨ archfeats
arch ← infer MakeArch ⊑ supp / arches

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

# For external tools, return base architecture as C compiler flags
GetCFlags ⇐ {𝕊:
  "-m"⊸∾¨ ((-´"aA")×'A'⊸≤∧≤⟜'Z')⊸+ (baseArch ∧ (arch.name)⊸≢¨)⊸/ feats
}
