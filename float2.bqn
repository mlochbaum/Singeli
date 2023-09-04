# High-precision numbers as pairs representing unevaluated sums
# Format is ⟨high,low⟩

To   ⇐ ⋈⟜0
From ⇐ +´

Add12 ← {a𝕊b:
  s ← a + b
  {¬∞>|s ? s‿0 ;
  av← s - bv← s - a
  ⟨s, +´a‿b-av‿bv⟩ }
}
Add ⇐ {a𝕊b:
  r ← a +○⊑ b
  {¬∞>|r ? r‿0 ;
  s ← (-r) +´ ¯1⌽⌽⍟(a<○(|⊑)b) b⌽⊸∾a
  r Add12 s }
}

Neg ⇐ -
Abs ⇐ -⍟(0>⊑)
Floor‿Ceil ⇐ {𝕏∘⊑⊸(⊣⋈·𝕏-⊸(+´)⟜⌽)}¨ ⌊‿⌈
Sub ⇐ Add⟜Neg

Cmp ⇐ × · (0=⊑)⊸⊑ Sub

Split ← 53‿1024{p‿e _𝕣:  # Double-precision float
  sp← 1+2⋆se←⌈p÷2
  m ← 2⋆e-1+se ⋄ f ← 2⋆-p  # Adjustments to avoid hitting ∞
  {¬m>|𝕩? 𝕊⌾(f⊸×) 𝕩; 𝕊a:
    c ← sp × a
    al← a - ah← c - c - a
    ⟨al, ah⟩ # Backwards for convenient reduction
  }
}
Mul12 ← {a𝕊b:
  h ← a × b
  {∞>|h? ⟨h, (-h) +´ ⥊ b ×⌜○Split a⟩ ; h‿0}
}
Mul ⇐ {a𝕊b:
  ph‿pl ← a Mul12○⊑ b
  {∞>|⊑ph? ph Add12 pl + +´ a × ⌽b ; ph‿0}
}

Div ⇐ {b𝕊a:
  yn ← (⊑b) × xn ← ÷⊑a
  {¬∞>|yn? yn‿0 ;
  diff ← ⊑ b Sub a Mul yn‿0
  yn‿0 Add xn Mul12 diff }
}

Mod ⇐ {
  b𝕊a‿0: a>0 ? h←a÷2 ⋄ Add12´ a⊸+⌾⊑⍟(<⟜-´) (-⟜(a×h<⊢)a|⊢)⍟(h<|)¨b ;
  # Not correctly rounded but probably okay
  b𝕊a: a Sub b Mul (Floor a Div b)
}

# Decimal parsing
# For one double, max digits is 15 and max power of 10 is 1e22
Exp10 ← { 22≥𝕩? To 10⋆𝕩; 308<𝕩? To ∞; (⊣´Mul⊢´)𝕊¨⍷⌊2÷˜𝕩+↕2 } # Could save results
N1 ← •ParseFloat
Nat ← ≠⊸{
  15≥𝕨 ? To N1 𝕩 ;
  20≥𝕨 ? ¯15 ((1e15×N1∘↓) Add12 N1∘↑) 𝕩 ;  # Exact
  35≥𝕨 ? ¯20 ((1e20 Mul12 •ParseFloat∘↓) Add Nat∘↑) 𝕩 ; # Sum of exacts so it's correctly rounded
  (Exp10 𝕨-35) Mul Nat 35↑𝕩  # Imprecise
}
ParseDec ⇐ { # 𝕨 is base-10 exponent; 𝕩 is digit string
  0≤𝕨 ? 𝕨 Exp10⊸Mul⍟(0<⊣) Nat 𝕩 ;
  (𝕨↓𝕩) Nat⊸Add⍟(0<≠∘⊣) (Exp10-𝕨) Div˜ Nat (𝕨⌈-≠𝕩)↑𝕩
}

_repr ⇐ { len‿b _𝕣:
  ! ⌊⊸= 2⋆⁼b # Need division by b to be exact
  {c←0 ⋄ {𝕩+↩c⋄c↩⌊𝕩÷b⋄b|𝕩}¨𝕩} ·+´ b|⌊∘÷⟜b⍟(↕len)¨
}
Bits ⇐ {
  𝕊⁼𝕩: (2⋆48)⊸×⊸Add12˜○(2⊸×⊸+˜´)˝ 2‿∘⥊𝕩 ;
  ∧´𝕩=⟜1⊸∨⌾⊑𝕩=0 ? 96↑⊏𝕩 ;
  "Bitwise operation: arguments must be unsigned integers" ! ⌊⊸≡◶⟨0,>⟜-´⟩ 𝕩
  "Bitwise operation: arguments can't exceed 2^96" ! 0<(2⋆96)-˜´⌽𝕩
  96‿2 _repr 𝕩
}
