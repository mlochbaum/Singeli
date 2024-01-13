# IR passes

# Apply transformation to each function
_onFns ← {
  [o,c] ← +`˘ "beginFn"‿"endFn" (⊣≡≠⊸↑)⌜ 𝕩
  o »↩
  f ← o-c
  r ← 𝔽¨⌾(1⊸↓) (o×f)⊔𝕩
  ((f¬⊸/o)∾/≠¨1↓r) ⍋⊸⊏ ∾r
}

# Attempt to replace goto{,T,F} with two kinds of structure:
#
# - beginBlock/endBlock/break{,T,F}     (do {...} while (0))
# - beginLoop/endLoop/continue{,T,F}    (while (1) {...;break;})
#
# Loops and blocks are properly nested, and have named labels.
# Jumps only occur on break, which goes to the end of its block, and
# continue, which goes to the beginning of its loop. The loop exits when
# endLoop is reached.
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
  # Place endBlock and/or beginLoop at the label, endLoop at the last goto,
  # and beginBlock at the computed location
  mi‿li←2↑lb⊔ai ⋄ lis←⟨lb/id,li⟩
  [nn,nm,ni] ← ⍉¯1⌽[
    ⟨"endBlock " ⟩∾(lb/¬f)⊸/¨lis
    ⟨"beginBlock ", ⌽fl/id, ⌽b⊏ai⟩
    ⟨"beginLoop "⟩∾(lb/¬l)⊸/¨lis
    ⟨"endLoop "  ⟩∾(lb<l)⊸/¨id‿ai # Will be rotated to place after 𝕩
  ]
  # Check that the inserted begin/end markers will be properly nested
  add ← ni ⍋⊸⊏○(∾1⊸⌽) (2/¯1‿1)⋈¨¨nm            # Depth change and label
  ∧´(>○⊑∧≡○(⊢´))´˘ ∘‿2⥊ ((⍋+`-0⊸<)⊑¨)⊸⊏ add ?  # Abort if not nested
  # Change goto to break/continue and insert begin/end
  alm ← ¬lb⌾(am⊸/)am
  br ← "break"‿"continue"⊏˜lb¬⊸/(i⊏i⍋⊸⊏○(lb⊸/)⊢)⊸≤⊒i
  (ni∾</alm) ⍋⊸⊏○(∾1⊸⌽) (nn{𝕨⊸∾¨𝕩}¨nm)∾<alm/(br∾⟜(4⊸↓)¨⊢)⌾(mi⊸⊏)𝕩
;
  𝕩
}_onFns
