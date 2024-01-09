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
# - beginBlock/endBlock: breaks go to end       (do {...} while (0))
# - beginLoop /endLoop:  breaks go to beginning (while (1) {...;break;})
# - break{,T,F}: conditionally jump to beginning/end of a section
#
# Loops and blocks are properly nested, and have named labels.
# Since breaking "from" a loop goes to the beginning, it's more like a
# continue statement. Note that no jump happens when endLoop is reached.
Restructure ⇐ {
  [lm,am] ← ∨` "lbl "‿"goto" ≡⌜ 4↑¨𝕩
  ai ← /am
  lb ← ai ⊏ lm                    # Which statements are lbl (not goto)
  i ← ⊐id ← (∧`⌾⌽' '⊸≠)⊸/¨ ai ⊏ 𝕩 # Label ID
  f ← ∊i ⋄ l ← ∊⌾⌽i               # First and last use of label
  IM ← {(𝕩⊐○(/⟜i)𝕨) ⊏ /𝕩}         # /𝕩 ordered by matching 𝕨 (requires 𝕨≡○(∧/⟜i)𝕩)
  ff ← (fl ← f<lb) IM lb<f        # First use of label, ordered by fl
  ll ← (bl ← lb<l) IM l<lb        # Loop start, ordered by end
  ff ⌊↩ {⌊´𝕨↓𝕩↑ll}¨˝[ff,/fl]⊏+`bl # Surround loops where end is caught
  b ← ↕0                          # Block start
  ff {b∾↩𝕨⌊´𝕩↓b⋄@}¨ ff ⊏ +`fl     # Surround caught blocks, iteratively
  mi‿li←2↑lb⊔ai ⋄ lis←⟨lb/id,li⟩
  [nn,nm,ni] ← ⍉¯1⌽[
    ⟨"endBlock " ⟩∾(lb/¬f)⊸/¨lis
    ⟨"beginBlock ", ⌽fl/id, ⌽b⊏ai⟩
    ⟨"beginLoop "⟩∾(lb/¬l)⊸/¨lis
    ⟨"endLoop "  ⟩∾(lb<l)⊸/¨id‿ai # Will be rotated to place after 𝕩
  ]
  alm ← ¬lb⌾(am⊸/)am
  (ni∾</alm) ⍋⊸⊏○(∾1⊸⌽) (nn{𝕨⊸∾¨𝕩}¨nm)∾<alm/("break"∾4⊸↓)¨⌾(mi⊸⊏)𝕩
  # TODO check whether that resulted in properly nested blocks
;
  𝕩
}_onFns
