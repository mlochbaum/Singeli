# High-precision numbers as pairs representing unevaluated sums
# Format is ⟨high,low⟩

To   ⇐ ⋈⟜0
From ⇐ +´

Add12 ← {a𝕊b:
  s ← a + b
  av← s - bv← s - a
  ⟨s, +´a‿b-av‿bv⟩
}
Add ⇐ {a𝕊b:
  r ← a +○⊑ b
  s ← (-r) +´ ¯1⌽⌽⍟(a<○(|⊑)b) b⌽⊸∾a
  r Add12 s
}

Neg ⇐ -
Abs ⇐ -⍟(0>⊑)
Floor‿Ceil ⇐ {𝕏∘⊑⊸(⊣⋈·𝕏-⊸(+´)⟜⌽)}¨ ⌊‿⌈
Sub ⇐ Add⟜Neg

Cmp ⇐ × · (0=⊑)⊸⊑ Sub

p ← 53  # Double-precision float
Split ← (1+2⋆⌈p÷2){sp _𝕣 a:
  c ← sp × a
  al← a - ah← c - c - a
  ⟨al, ah⟩ # Backwards for convenient reduction
}
Mul12 ← {a𝕊b:
  h ← a × b
  ⟨h, (-h) +´ ⥊ b ×⌜○Split a⟩
}
Mul ⇐ {a𝕊b:
  ph‿pl ← a Mul12○⊑ b
  ph Add12 pl + +´ a × ⌽b
}

Div ⇐ {b𝕊a:
  yn ← (⊑b) × xn ← ÷⊑a
  diff ← ⊑ b Sub a Mul yn‿0
  yn‿0 Add xn Mul12 diff
}

Mod ⇐ {
  b𝕊a‿0: a>0 ? h←a÷2 ⋄ Add12´ a⊸+⌾⊑⍟(<⟜-´) (h-˜a|h+⊢)⍟(h<|)¨b ;
  # Not correctly rounded but probably okay
  b𝕊a: a Sub b Mul (Floor a Div b)
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
