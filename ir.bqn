# IR passes

# Apply transformation to each function
_onFns ← {
  [o,c] ← +`˘ "beginFn"‿"endFn" (⊣≡≠⊸↑)⌜ 𝕩
  o »↩
  f ← o-c
  r ← 𝔽¨⌾(1⊸↓) (o×f)⊔𝕩
  ((f¬⊸/o)∾/≠¨1↓r) ⍋⊸⊏ ∾r
}

# Attempt to replace goto{,T,F} with:
#
# - beginBlock/endBlock: a breakable code section
# - beginLoop /endLoop: jumps to beginLoop when endLoop is reached
# - break{,T,F} d: jumps to the end of loop or block at depth d
#
# Loops and blocks are properly nested, and depth 0 indicates the
# immediately enclosing section, depth 1 the one enclosing it, and so on.
# Breaking "from" a loop effectively goes to the beginning, making it
# more like a continue statement.
Restructure ⇐ {
  lm‿ai ← (⊣⋈/∘∨)˝ "lbl "‿"goto" ≡⌜ 4↑¨𝕩
  lb ← ai ⊏ lm                # Which statements are lbl (not goto)
  id ← (∧`⌾⌽' '⊸≠)⊸/¨ ai ⊏ 𝕩  # Label ID
  l ← ∊⌾⌽ i ← ⊐ id            # Last use of label
  l ≡ lb?                     # Only handle forward goto
  f ← (l/i) ⊏ (/⟜i⍋⊸⊏/) ∊i    # First use of label, ordered by l
  e ← f ⊏ +`l                 # Next label after it
  b←bm←1↑e                    # Block start; bm≡⌊`b
  {b∾↩a←𝕩⊑b∾≠b⋄bm∾↩a⌊⊢´bm⋄@}¨ 1↓e
  xm ← (⟨"break"∾4⊸↓,"endBlock"∾3⊸↓⟩{𝕎¨𝕩}¨⊢)⌾(l⊔ai⊸⊏)𝕩
  ((b⊏f⊏ai)∾↕≠𝕩) ⍋⊸⊏ ("beginBlock "⊸∾¨l/id)∾xm
;
  𝕩
}_onFns
