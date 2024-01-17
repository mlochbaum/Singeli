# Given a list of bitmasks, find operations that will pack them together
# The two kinds of operations are:
# - Number r for the shift r⌽bits, evaluated as x>>r, x<<(-r), or x
# - Boolean array for add-mask evaluated as (x+a)&~a, where a←≠`mask≠out
# Return a list of one of these for each argument
FindBitPacker ⇐ { 𝕊 masks:
  # p is a list of ⟨mask, shifts⟩ pairs
  # where mask indicates the bits *not* yet used
  Rec ← { rem‿defer‿di 𝕊 p: { 0=≠p ? @ ;
    # Try all shifts, recursing in blocks
    0<≠rem ? m←⊑rem
    s ← {(↕1+𝕨)∾¯1-↕𝕩}○(+´∧`)⟜⌽ m      # Possible shifts (0 first)
    Fp ← {r←𝕩⌽m⋄(r⊸∧⌾⊑ ∾⟜𝕩⌾(1⊸⊑))¨(∧´r∨⊑)¨⊸/p}
    Rs ← ⟨1↓rem,defer,di⟩ Rec ·∾Fp¨    # Recurse on several shifts
    l←¯1                               # Shifts per block increases
    sol ← Rs∘{𝕊:(-≠s↓˜↩l+↩3)↓s}•_while_{(0<≠s)∧@≡𝕩} @
    @≢sol ? sol
  ; # Shift failed; defer this one to try shifting the next
    1<≠rem ? ⟨1↓rem,defer∾⊏rem,di∾≠rem⟩ Rec p
  ; # Try add+mask
    # 𝕩 is a list of masks; result is @ or i∾suff with i an index in 𝕩
    RecA ← {
      0=≠𝕨 ? ⟨0⟩ ; m←⊑𝕨 ⋄ rem←1↓𝕨
      s ← ⊢´ g ← +`¬m  # (g-1)⊔𝕩 groups positions by which bit of m can go there
      R ← {
        0=≠rem ? (s=+´)◶@‿⋈ (0⊸<∧∊)𝕩×g ;        # First that works
        a ← ⥊(<0¨𝕩) ∨⌜´ (<↕≠𝕩)⊸=¨ ⊔(𝕩×g)-1      # All possibilities
        0<≠a ? @≢sol ← rem RecA 𝕩⊸>¨ a ? ⊑⟜a⌾⊑sol ; @
      }
      i←¯1 ⋄ e←1-˜≠𝕩
      sol ← (R 𝕩⊑˜{𝕊:i+↩1})•_while_{(i<e)∧@≡𝕩} @
      i⊸∾⍟(@⊸≢) sol
    }
    sol ← (rem∾defer) RecA ⊑¨p
    @≢sol ? (⍋∘⍋↕∊-⟜di)∘≠⊸⊏ (1⊑(⊑sol)⊑p)∾1↓sol
  ;
    @ # Failed
  }}
  ⟨¬masks, ⟨⟩, ↕0⟩ Rec ⋈⟨1¨⊑masks,⟨⟩⟩
}⍟(0<≠)
