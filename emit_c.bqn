# SSE
arch ← {
  Type ⇐ { bType‿w‿am‿ptrs:
    u‿f ← bType = "uf"
    (ptrs/"*") ∾˜ {𝕏@} {!∘"Unsupported type"} {(⊑𝕨)◶⟨𝕩,1⊑𝕨⟩}´ ⟨
      ⟨0≤am     , {𝕤⋄ "Unsupported type" ! 128=w×am, "__m128"∾f¬⊸/"i" }⟩
      ⟨f        , {𝕤⋄ "float"‿"double"⊑˜32‿64⊸⊐⌾<w }⟩
      ⟨w=0      , "void"⟩
      ⟨u∧w=1    , "bool"⟩
      ⟨⊑w∊2⋆3+↕4, {𝕤⋄ ∾(u/"u")‿"int"‿(•Repr w)‿"_t" }⟩
    ⟩
  }
}

prelude ← 1⌽"
#include<stdint.h>
#include<stdbool.h>
#include<xmmintrin.h>
static inline void si_aseti8 (int8_t * a, uint8_t  n, int8_t  k) { a[n]=k; }
static inline void si_aseti16(int16_t* a, uint64_t n, int16_t k) { a[n]=k; }
static inline void si_aseti32(int32_t* a, uint64_t n, int32_t k) { a[n]=k; }
static inline void si_aseti64(int64_t* a, uint64_t n, int64_t k) { a[n]=k; }
static inline int8_t  si_ageti8 (int8_t * a, uint64_t n) { return a[n]; }
static inline int16_t si_ageti16(int16_t* a, uint64_t n) { return a[n]; }
static inline int32_t si_ageti32(int32_t* a, uint64_t n) { return a[n]; }
static inline int64_t si_ageti64(int64_t* a, uint64_t n) { return a[n]; }
"

lf ← @+10

Generate ← {
  fn ← 0  # Whether a function is active
  ProcLine ← {
    line ← StartLine 𝕩
    c ← code⊸⊐⌾< Name line
    (∾"Unknown operation: `"‿𝕩‿"`") ! c<≠code
    depth‿infn‿do ← c ⊑ op
    ! fn ≡ infn
    fn +↩ depth
    tail ← ⟨infn∧fn,2-fn⟩/';'‿lf
    res ← do {𝕎𝕩}¨ <line
    line.Finish @
    ∾ res∾<tail
  }⍟(0<≠)
  l ← ProcLine¨ lf ((⊢-˜+`×¬)∘=⊔⊢) 𝕩
  "Unclosed function" ! 0≡fn
  ∾ ⟨prelude⟩∾l
}

StartLine ← { 𝕊 str:
  Assert ← { ! ∾𝕨‿": `"‿str‿"`" }⍟(1≢⊢)
  tok ← ' ' ((⊢-˜+`×¬)∘=⊔⊢) str
  i ← ¯1
  Next ⇐ {𝕤
    i +↩ 1
    "Unfinished line" Assert i < ≠tok
    i ⊑ tok
  }
  All ⇐ {𝕤
    r←(i+1)↓tok ⋄ i↩1-˜≠tok ⋄ r
  }
  Finish ⇐ {𝕤
    IsWS ← ∊⟜(" "∾@+9)
    "Excessive IR line" Assert (≠tok) ≤◶⟨(∨´ IsWS ∨ ·∨`'#'⊸=)⊑˜, 1⟩ i+1
  }
}

as ← {
  Name ⇐ ⊢
  Rename ⇐ "si_"⊸∾
  I32 ⇐ •BQN
  Lit ⇐ {
    v‿t ← (1-˜+`×¬)∘(1⌾⊑':'⊸=)⊸⊔ 𝕩
    ∾⟨"((",Type t,")",v,('u'=⊑t)/"u","ll)"⟩
  }⍟('!'=⊑)
  Type ⇐ { 𝕊s:  # Singeli type to native
    s ↓˜↩ ptrs ← +´∧`'*'=s
    am ← ('['=⊑)◶¯1‿{
      a‿t ← (1-˜+`×¬)∘(1⌾⊑']'⊸=)⊸⊔ 𝕩
      s↩t ⋄ •BQN a
    } s
    arch.Type {
      "void": 'v'‿0‿¯1‿ptrs;
      ⟨⊑𝕩, •BQN 1↓𝕩, am, ptrs⟩
    } s
  }
}

Name‿Rename‿Type‿Lit‿I32 ← {𝕏{𝕩.Next@}}¨ ⟨as.Name,as.Rename,as.Type,as.Lit,as.I32⟩
All ← {𝕩.All@}

Join ← {∾1↓⥊(<𝕨)≍˘𝕩}
List ← ", "⊸Join

BeginFn ← {𝕤
  n ← Rename 𝕩
  ret ← Type 𝕩
  argc ← I32 𝕩
  param ← List ((Type𝕩˙)∾" v"∾•Repr)¨ ↕argc
  ∾⟨"static ",ret," ",n,"(",param,") {"⟩
}
Export ← {
  val ← Rename 𝕩
  ret ← Type 𝕩
  aname ← ("v"∾•Repr)¨ ↕≠ atype ← (Type𝕩˙)¨ ↕I32 𝕩
  exp ← Name 𝕩
  param ← ","Join atype {∾𝕨‿" "‿𝕩}¨ aname
  in ← ","Join aname
  ∾⟨ret," ",exp,"(",param,") { return ",val,"(",in,"); }"⟩
}
⟨New⟩ ← {
  Call ← {𝕨‿"("‿𝕩‿")"}⟜List
  code‿op ← <˘⍉>⟨
    "val" ‿(≍○< Lit)
    "call"‿{ fn ← Rename 𝕩 ⋄ fn Call (Lit𝕩˙)¨ ↕I32 𝕩 }
    "emit"‿(Name (≡⟜"op")◶⟨
        Call⟜(as.Lit¨All)
        { o←Name 𝕩 ⋄ ⟨Lit 𝕩," ",o," ",Lit 𝕩⟩ }
      ⟩ ⊢)
  ⟩
  New ⇐ {
    id   ← Name 𝕩
    kind ← Name 𝕩
    ty   ← Type 𝕩
    pre ← "void"⊸≢◶⟨⟨⟩, {𝕩‿" "‿id‿" = "}⟩ ty
    c ← code⊸⊐⌾< kind
    (∾"Unknown new: `"‿kind‿"`") ! c<≠code
    ∾ pre ∾ (c⊑op) {𝕎𝕩} 𝕩
  }
}

code‿op ← (⊑¨ ≍○< 1⊸↓¨) ⟨
  "export" ‿ 0‿0‿⟨Export⟩
  "beginFn"‿ 1‿0‿⟨BeginFn⟩
  "lbl"    ‿ 0‿1‿⟨Name,":"⟩
  "ret"    ‿ 0‿1‿⟨"  ","return","void"⊸≢◶⟨""," "⊸∾⟩ Lit⟩
  "gotoF"  ‿ 0‿1‿⟨"  ","if (!(",Lit,")) ","goto ",Name⟩
  "gotoT"  ‿ 0‿1‿⟨"  ","if (",Lit,") ","goto ",Name⟩
  "goto"   ‿ 0‿1‿⟨"  ","goto ",Name⟩
  "new"    ‿ 0‿1‿⟨"  ",New⟩
  "mut"    ‿ 0‿1‿⟨"  ",Name," = ",Lit⟩
  "endFn"  ‿¯1‿1‿⟨"}"⟩
⟩

•Out Generate •FChars ⊑•args
