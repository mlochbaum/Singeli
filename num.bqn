# High-precision numbers as pairs representing unevaluated sums
# Format is ⟨high,low⟩

To   ⇐ ≍○<⟜0
From ⇐ +´

Add12 ← {a𝕊b:
  s ← a + b
  av← s - bv← s - a
  ⟨s, +´a‿b-av‿bv⟩
}
Add ⇐ {a𝕊b:
  r ← a +○⊑ b
  s ← (-r) +´ ¯1⌽⌽⍟(a<○⊑b) b⌽⊸∾a
  r Add12 s
}

Neg ⇐ -
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
