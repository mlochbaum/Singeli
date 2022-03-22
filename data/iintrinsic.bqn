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

filter ← ∧´ filters ← ⟨
  ¬ ∨˝"_ss"‿"_sd"(⊣≡-∘≠⊸↑)⌜names
  svml < cpuid<≠isaList
  ¬ (∨´·("&b"∧´∘∊⊢)¨1⊑¨⊢)¨ proto
  (⊑'b'∊1⊑⊑)◶⟨1,⊑·(⊏∊1⊸↓)1⊑¨⊢⟩¨ proto
⟩
names‿proto‿cpuid‿cat filter⊸/¨↩

_seg ← {(𝔽·+`'_'⊸=)⊸/}
sname ← 3⊸=_seg⊸(∾˜)⍟("_mask"⊸≡)⟜(2⊸=_seg)¨ names
id ← ⊐ sname ≍˘ 1↓¨proto
Disamb ← { U←{¬∧´∊𝕩} ⋄ 𝕩 2⊸<_seg¨⊸(∾¨˜⍟U˜)⍟U ("_"∾·¬∘∊⟜"[]"⊸/1⊑⊑)¨𝕨 }
sname ∾¨↩ proto (1<≠∘⊢)◶⟨""¨,Disamb⟩¨⌾(id⊸⊔) names

#⌜
# Format as Singeli definition
MakeDef ← {instr 𝕊 prot:
  # Utilities
  Br←"{"∾∾⟜"}" ⋄ A←∾⟜Br ⋄ M←{"match"A∾𝕨‿","‿𝕩}
  Int←<⊸(≍˘) ⋄ J←∾1↓·⥊Int
  # Test if 𝕩 is of type 𝕨
  IsT ← (∊⟜"bm"⌾<⊑∘⊢)◶M‿{ "ii_intvec"A∾⟨1↓𝕩,",",𝕨⟩ }
  # Type handling and formatting
  pn‿pt ← <˘⍉> prot
  an←1↓pn ⋄ ! ∊⟜""‿"dst"‿"k"⌾< ⊑pn
  pt ("__pnt" A 1⊸↓)⍟(∊⟜"*&"⌾<⊑)¨↩
  rt‿at ← (⊑⋈1⊸↓) pt
  vf ← ¬ if ← "IMM"⊸≡¨ at
  tn ← ⥊¨'T'-⊐vf/at
  vars ← an (∾⟜":"⊸∾¨⟜tn ⋈ tn IsT¨○⍷⊢)○(vf⊸/) at
  imms ← (⊢ ⋈ "ii_num"⊸A¨) if/an
  rt ↩ (≠at)⊸=◶⟨⊑⟜tn, rt⟩ at⊸⊐⌾< rt
  ∾⟨
    Br ∾ 1↓⥊ ∾ ⟨", "," & "⟩ Int¨ vars ∾¨ imms
    " = emit"
    Br ", "J ⟨rt, "'"(∾∾⊣)instr⟩ ∾ an
  ⟩
}
defs ← cpuid ⊔○((⍋cat)⊸⊏) sname {∾"def _"‿𝕨‿𝕩}¨ names MakeDef¨ proto
•Out 1⌽"
def ii_intvec{w,T} = 0
def ii_intvec{w,T & match{'vector',typekind{T}} & isint{eltype{T}} & match{w,width{T}}} = 1
def ii_num{T} = match{'number',kind{T}}"
•Out¨ ∾ 1↓⥊(<2⥊<⟨⟩) ∾˘ ("#"⊸∾¨isaList) <⊸≍˘ defs
