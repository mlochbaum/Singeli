# https://www.intel.com/content/dam/develop/public/us/en/include/intrinsics-guide/data-3-6-1.xml
xml ← •FChars •wdpath •file.At ⊑•args

#⌜
# An xml parser good enough for our use case
# Accept xml; return (as three lists):
# - Parent index of each tag
# - Contents of open tag
# - Text after last child tag
E ← +`⊸×⟜¬-⊢
ParseXml ← {
  text‿tags ← ('?'=·⊑·⊑1⊸⊑)⊸(↓¨) <˘⍉⌊‿2⥊((+⟜»E∨)˝"<>"=⌜⊢)⊸⊔𝕩
  d←+`tt←1-(+˜⊸+´'/'=0‿¯1⊸⊏)¨tags    # Tag type: ¯1 close, 0 void, 1 open
  tp←(⍋⊏⟜d)⊸⊏∘/˘ 1‿¯1=⌜tt            # Tag pairs
  ! (∧`' '⊸≠)⊸/¨⊸≡⟜(1⊸↓¨)˝tp⊏tags    # Tag matching
  oi←(0<tt)(⌈`↕∘≠⊸×)⊸⊏⌾((⍋d)⊸⊏)↕≠tt  # Open index, for closed and void tags
  ci←⍋⊸⊏○(∾⟜(/0=tt))˝tp
  pi←(/0≤tt)(1-˜⍋)¯1⌾⊑ci⊏oi          # Parent index
  ⟨pi,(0≤tt)/tags,ci⊏text⟩
}
ParseAttr ← {
  name‿a ← (⊑⋈1⊸↓) (E˜' '⊸=>·≠`'"'⊸=)⊸⊔𝕩
  ⟨name, >(E˝·∨`"="""=⌜⊢)⊸⊔¨a⟩
}

#⌜
# Now process the contents
isaList ← "SSE"‿"SSE2"‿"SSE3"‿"SSSE3"‿"SSE4.1"‿"SSE4.2"‿"AVX"‿"AVX2"‿"FMA"

names‿GetCont‿GetVoid‿svml ← {
  parent‿open‿cont ← ParseXml xml
  findOpen ← {(⍷𝕩)⊸⊐⊏(⊔⊐𝕩)˙} (∧`' '⊸≠)⊸/¨ open
  _on_ ← {𝔽○((∾FindOpen𝕘)⊸⊏)}
  child ← ⊔ parent
  intr ⇐ cont ∊⟜isaList⊸/_on_⟨"CPUID"⟩ parent
  IG ← intr⊏⊔
  GetCont ⇐ { parent IG _on_𝕩 cont }
  GetVoid ⇐ { parent IG⟜((¯1⊑·ParseAttr ¯1⊸↓)¨)_on_𝕩 open }
  at ← (1⊑ParseAttr)¨ intr⊏open
  names ⇐ ≡¨⟜(<"name")⊸(⊑∘/)˝∘⍉¨ at
  svml ⇐ (⊑"tech"‿"SVML"∊⊢)¨ at
}

ProcType ← {
  IsDig ← 1=0‿10⍋-⟜'0'
  Nat ← 10⊸×⊸+˜´∘⌽ -⟜'0'
  Num ← {𝕊⁼:•Repr𝕩; (0<≠)◶1‿Nat IsDig⊸/𝕩}
  t‿n‿e ← ((1⊏˘𝕩)∾<"")⊏˜(⊏˘𝕩)⊐"type"‿"varname"‿"etype"
  pre ← ""
  t ↩ " const" {c←𝕨≡(-≠𝕨)↑𝕩⋄pre∾↩c⊏"&*"⋄(-c×≠𝕨)↓𝕩}⟜((-1+' '=¯2⊸⊑)⊸↓)⍟('*'≡¯1⊸⊑) t
  {𝕤⋄pre‿t↩"IMM"‿""}⍟("IMM"⊸≡) e
  EP ← (∾·((⥊¨"uifbm")⊑˜"UI"‿"SI"‿"FP"‿"M"‿"MASK"⊸⊐⌾<)⌾⊑IsDig⊸⊔) e˙
  tp‿act ← <˘⍉∘‿2⥊⟨
    "void"   , ⊢
    "int"    , "i32"
    "float"  , "f32"
    "double" , "f64"
    "__m"    , (∊⟜"bm"⌾<⊑∘⊢)◶⟨("["∾"]"∾˜÷⌾Num)∾⊢, ⊏∘⊢∾·IsDig⊸/⊣⟩⟜EP
    ""       , ⊢
  ⟩
  act ∾↩ ⟨EP⟩ # Various integer types
  ⟨n, pre∾(tp⊸⊐⌾<(∧`∘¬IsDig)⊸/)◶act t⟩
}

proto ← (¯1↓⍟(""‿"void"≡⊑)ProcType¨)¨ GetVoid "return"‿"parameter"
cpuid‿cat ← GetCont∘(⥊<)¨ "CPUID"‿"category"
cpuid ↩ isaList ⊐ ⊑¨cpuid
#instrs ← 0‿1⊸⊑¨¨ GetVoid ⟨"instruction"⟩  # x86 instruction name

#⌜
# Singeli-specific adjustments; try to fix wrong signedness
_seg ← {(𝔽·+`'_'⊸=)⊸/}
GetSname ← 3⊸=_seg⊸(∾˜)⍟("_mask"⊸≡)⟜(2⊸=_seg)
# Exclude intrinsics covered by basic.singeli
excl ← E˜∘=⟜' '⊸⊔"setr set set1 loadu load storeu store extract insert and or xor andnot add sub adds subs min max mullo mul slli srai srli sll sra srl sllv srav srlv cmpeq cmpgt cmp cmpneq cmpge cmplt cmple div sqrt floor ceil round abs sign avg shuffle shufflehi shufflelo permute permutevar permute2f128 permute2x128 permute4x64 permute8x32 permutevar8x32 unpacklo unpackhi bslli bsrli alignr blend blendv"
incl ← E˜∘=⟜' '⊸⊔"_mm_cmp_pd _mm_cmp_ps _mm256_set_m128 _mm256_set_m128d _mm256_set_m128i _mm256_setr_m128 _mm256_setr_m128d _mm256_setr_m128i _mm_mul_epu32 _mm_mul_epi32 _mm256_mul_epi32 _mm256_mul_epu32"
filter ← ∧´ ⟨
  (names∊incl) ∨ ¬((1↓GetSname)¨ names)∊excl
  ¬ ∨˝"_ss"‿"_sd"‿"1"(⊣≡-∘≠⊸↑)⌜names
  svml < cpuid<≠isaList
  ¬ (∨´·("&b"∧´∘∊⊢)¨1⊑¨⊢)¨ proto
  (⊑'b'∊1⊑⊑)◶⟨1,⊑·(⊏∊1⊸↓)1⊑¨⊢⟩¨ proto
⟩
names‿proto‿cpuid‿cat filter⊸/¨↩

sname ← GetSname¨ names

pi ← ("pi"≡¯2↑·(¬·∨`'0'⊸≤∧'9'⊸≥)⊸/(∧`⌾⌽'_'⊸≠)⊸/)¨names
pi ∧↩ ¬sname∊"_mullo"‿"_srl"‿"_srli"‿"_srlv"‿"_abs"
proto ((-´"iu")×(<<0‿1)×'u'=⊢)⊸+⌾(pi⊸/)↩

id ← ⊐ sname ≍˘ 1↓¨proto
Disamb ← { U←{¬∧´∊𝕩} ⋄ 𝕩 2⊸<_seg¨⊸(∾¨˜⍟U˜)⍟U ("_"∾·¬∘∊⟜"[]"⊸/1⊑⊑)¨𝕨 }
sname ∾¨↩ proto (1<≠∘⊢)◶⟨""¨,Disamb⟩¨⌾(id⊸⊔) names

#⌜
# Format as Singeli definition
MakeDef ← {instr 𝕊 prot:
  # Utilities
  Br←"{"∾∾⟜"}" ⋄ A←∾⟜Br
  Int←⥊<⊸(≍˘) ⋄ J←∾1↓Int
  # Type handling and formatting
  pn‿pt ← <˘⍉> prot
  an←1↓pn ⋄ ! ∊⟜""‿"dst"‿"k"⌾< ⊑pn
  pp ← "*&"∊˜⊑¨pt
  rt‿at ← (⊑⋈1⊸↓) pp↓¨pt
  ri ← "void"⊸≢◶⟨≠at, at⊸⊐⌾<⟩ rt
  iv ← "bm"∊˜⊑¨at ⋄ vf ← "IMM"⊸≢¨ at
  c‿i ← iv(<⋈∧)vf∧∊at # c for type constant, i for intvec
  uf ← vf ∧ (ri=↕∘≠)⊸∨ iv ∨ ¬(∊∧∊⌾⌽)at # Which types are named
  tn ← uf⥊¨'T'- 1-˜1↓⊐0∾uf×1+⊐at
  vt ← at (0<≠∘⊣)◶⟨"("∾")"∾˜⊢,∾⟜"=="⊸∾⟩¨˜⌾(c/⊢) tn
  par ← an ∾¨ vf":"⊸∾⍟⊣¨ (1↓pp)"*"⊸∾⍟⊣¨ vt
  conds ← (tn {"intvec"A∾⟨1↓𝕩,",",𝕨⟩}¨○(i/⊢) at) ∾ "num"⊸A¨ vf¬⊸/an
  rt ↩ "__pnt"⊸A⍟(⊑pp) (≠at)⊸=◶⟨⊑⟜tn, rt⟩ ri
  ∾⟨
    Br ∾ 1↓ (", " Int par) ∾ " if "⌾⊑⍟(0<≠) " and " Int conds
    " = emit"
    Br ", "J ⟨rt, "'"(∾∾⊣)instr⟩ ∾ an
  ⟩
}
defs ← cpuid ⊔○((⍋cat)⊸⊏) sname {∾"def _"‿𝕨‿𝕩}¨ names MakeDef¨ proto
•Out 1⌽"
local {
  def intvec{w,T} = 0
  def intvec{(width{V}),V=[_]T if isint{T}} = 1
  def num{T} = is{'number',kind{T}}
}"
•Out¨ ∾ 1↓⥊(<2⥊<⟨⟩) ∾˘ ("#"⊸∾¨isaList) <⊸≍˘ defs
