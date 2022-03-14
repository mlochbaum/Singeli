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

names‿GetCont‿GetVoid ← {
  parent‿open‿cont ← ParseXml xml
  findOpen ← {(⍷𝕩)⊸⊐⊏(⊔⊐𝕩)˙} (∧`' '⊸≠)⊸/¨ open
  _on_ ← {𝔽○((∾FindOpen𝕘)⊸⊏)}
  child ← ⊔ parent
  intr ⇐ cont ∊⟜isaList⊸/_on_⟨"CPUID"⟩ parent
  IG ← intr⊏⊔
  GetCont ⇐ { parent IG _on_𝕩 cont }
  GetVoid ⇐ { parent IG⟜((¯1⊑·ParseAttr ¯1⊸↓)¨)_on_𝕩 open }
  names ⇐ ≡¨⟜(<"name")⊸(⊑∘/)˝∘(⍉1⊑ParseAttr)¨ intr⊏open
}

ProcType ← {
  IsDig ← 1=0‿10⍋-⟜'0'
  t‿n‿e ← ((1⊏˘𝕩)∾<"")⊏˜(⊏˘𝕩)⊐"type"‿"varname"‿"etype"
  pre ← ""
  t ↩ " const" {c←𝕨≡(-≠𝕨)↑𝕩⋄pre∾↩c⊏"&*"⋄(-c×≠𝕨)↓𝕩}⟜((-1+' '=¯2⊸⊑)⊸↓)⍟('*'≡¯1⊸⊑) t
  {𝕤⋄pre‿t↩"IMM"‿""}⍟("IMM"⊸≡) e
  EP ← ∾·((⥊¨"uifbm")⊑˜"UI"‿"SI"‿"FP"‿"M"‿"MASK"⊸⊐⌾<)⌾⊑IsDig⊸⊔
  tp‿act ← <˘⍉∘‿2⥊⟨
    "void"   , ⊢
    "int"    , "i32"
    "float"  , "f32"
    "double" , "f64"
    "__m"    , (("["∾"]"∾˜·•Repr÷○((0<≠)◶1‿•BQN))○(IsDig⊸/)∾EP∘⊢)⟜e
    ""       , ⊢
  ⟩
  act ∾↩ ⟨EP∘e⟩ # Various integer types
  ⟨n, pre∾(tp⊸⊐⌾<(∧`∘¬IsDig)⊸/)◶act t⟩
}

proto ← (¯1↓⍟(""‿"void"≡⊑)ProcType¨)¨ GetVoid "return"‿"parameter"
cpuid‿cat ← GetCont∘(⥊<)¨ "CPUID"‿"category"
cpuid ↩ isaList ⊐ ⊑¨cpuid
#instrs ← 0‿1⊸⊑¨¨ GetVoid ⟨"instruction"⟩  # x86 instruction name

#⌜
# Format as Singeli definition
MakeDef ← {name 𝕊 prot:
  pn‿pt ← <˘⍉> prot
  an←1↓pn ⋄ ! ∊⟜""‿"dst"‿"k"⌾< ⊑pn
  rt‿at ← (⊑⋈1⊸↓) pt
  at ("__pnt{"∾1⊸↓∾"}"˙)⍟('*'=⊑)¨↩
  vf ← ¬ if ← "IMM"⊸≡¨ at
  tn ← ⥊¨'T'-⊐vf/at
  vars ← an (∾⟜":"⊸∾¨⟜tn ⋈ tn{∾"match{"‿𝕨‿","‿𝕩‿"}"}¨○⍷⊢)○(vf⊸/) at
  imms ← (⊢ ⋈ ("match{'number',kind{"∾∾⟜"}}")¨) if/an
  rt ↩ (≠at)⊸=◶⟨⊑⟜tn, rt⟩ at⊸⊐⌾< rt
  Br ← "{"∾∾⟜"}"
  ∾⟨
    "def "
    "_"∾(2=·+`'_'⊸=)⊸/⍟(0<≠an) name
    Br ∾ 1↓⥊ ∾ ⟨", "," & "⟩ <⊸(≍˘)¨ vars ∾¨ imms
    " = emit"
    Br ∾1↓⥊(<", ")≍˘⟨rt, "'"(∾∾⊣)name⟩ ∾ an
  ⟩
}
filter ← ¬ (∨˝"_ss"‿"_sd"(⊣≡-∘≠⊸↑)⌜names) ∨ (∨´"&bm"∊·∾1⊑¨⊢)¨ proto
filter ∧↩ cpuid<≠isaList
defs ← (cpuid≍˘cat) ⍋⊸⊏○(filter⊸/) names MakeDef¨ proto
•Out¨ ∾ 1↓⥊(<2⥊<⟨⟩) ∾˘ ("#"⊸∾¨isaList) <⊸≍˘ (∧filter/cpuid) ⊔ defs
