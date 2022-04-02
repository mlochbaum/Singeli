# x86
arch ← {
  Type ⇐ { bType‿w‿am‿ptrs:
    u‿f ← bType = "uf"
    (ptrs/"*") ∾˜ {
      0≤am      ? "Unsupported vector type" ! ∊⟜(2⋆6+↕4)⌾<l←w×am  # 64…512
                  ∾⟨"__m",•Repr l,{¬f?"i";(64=w)/"d"}⟩ ;
      f         ? "float"‿"double"⊑˜32‿64⊸⊐⌾<w ;
      w=0       ? "void" ;
      u∧w=1     ? "bool" ;
      ⊑w∊2⋆3+↕4 ? ∾⟨u/"u","int",•Repr w,"_t"⟩ ;
      !"Unsupported type"
    }
  }
}

prelude ← 1⌽"
#include<stdint.h>
#include<stdbool.h>
#include<xmmintrin.h>
#include<immintrin.h>
#define si_assert(A) if (!(A)) __builtin_unreachable();
"

lf ← @+10

Generate ← {
  decl.Init@
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
  ∾ ⟨𝕨⊣prelude⟩∾(decl.Emit@)∾l
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

Nat ← 10⊸×⊸+˜´∘⌽ -⟜'0'
as ← {
  Name ⇐ ⊢
  Rename ⇐ "si_"⊸∾
  I32 ⇐ ('-'=⊑)⊸(⊣-∘⊢⍟⊣Nat∘↓)
  Lit ⇐ (⊑"c!"⊐⊏)◶Rename‿{
    Bl ← {0<+`-˝"{}"=⌜𝕩} ⋄ br ← Bl𝕩
    v‿t ← (1-˜+`×¬)∘(1⌾⊑br<':'⊸=)⊸⊔ 𝕩
    {¬∨´br?
      s ← {'f':{("."/˜¬∨´"e."∊v)∾("f32"≡t)/"f"}; (('u'=𝕩)/"u")∾"ll"} ⊑t
      ∾⟨"((",Type t,")",v,s,")"⟩
    ;
      !"tup{"≡4↑v
      "{"∾"}"∾˜∾1↓⥊(<",")≍˘ Lit¨ ((⊢-˜+`×¬)∘(Bl<','⊸=)⊔⊢)○(¯1↓4↓⊢) v
    }
  }‿⊢
  Type ⇐ { 𝕊s:  # Singeli type to native
    s ↓˜↩ ptrs ← +´∧`'*'=s
    am ← { '['≠⊑s ? ¯1 ;
      a‿t ← (1-˜+`×¬)∘(1⌾⊑']'⊸=)⊸⊔ s
      s↩t ⋄ Nat a
    }
    arch.Type {
      "void": 'v'‿0‿¯1‿ptrs;
      ⟨⊑𝕩, Nat 1↓𝕩, am, ptrs⟩
    } s
  }
}

Name‿Rename‿Type‿Lit‿I32 ← {𝕏{𝕩.Next@}}¨ ⟨as.Name,as.Rename,as.Type,as.Lit,as.I32⟩
All ← {𝕩.All@}

decl ← {
  FromName ← Nat 4⊸↓  # si_f
  c←o←@ ⋄ Init⇐{𝕤⋄c↩↕0⋄o↩⟨⟩}
  BeginFn ⇐ { n←FromName𝕨 ⋄ n<≠c ? n⊑c ? o∾↩<𝕩 ; @}
  Call ⇐ { i←FromName𝕩 ⋄ c↑˜↩(≠c)⌈1+i ⋄ c 1⌾(i⊸⊑)↩ }
  Emit ⇐ {𝕤⋄ ∾⟜⟨⥊lf⟩⍟(0<≠) (¯2⊸↓∾(";"∾lf)˙)¨ o }
}

Join ← {∾1↓⥊(<𝕨)≍˘𝕩}
List ← ", "⊸Join

BeginFn ← {𝕤
  n ← Rename 𝕩
  ret ← Type 𝕩
  argc ← I32 𝕩
  param ← List ((Type𝕩˙)∾" v"∾•Repr)¨ ↕argc
  n⊸decl.BeginFn⊸⊢ ∾⟨"static ",ret," ",n,"(",param,") {"⟩
}
Export ← {
  val ← Rename 𝕩
  ret ← Type 𝕩
  aname ← ("v"∾•Repr)¨ ↕≠ atype ← (Type𝕩˙)¨ ↕I32 𝕩
  exp ← Name 𝕩
  param ← ","Join atype {∾𝕨‿" "‿𝕩}¨ aname
  ∾⟨ret," (*const ",exp,")(",param,") = ",val,";"⟩
}
Define ← {𝕊 ty‿id‿val:
  {'{'=⊑1↑⊑val? '*'=¯1⊑ty? ty↓˜↩¯1⋄id∾↩"[]"; @}
  ∾ ty‿" "‿id‿" = "∾val
}
Constant ← {
  name ← Rename 𝕩
  type ← Type 𝕩
  val ← Lit 𝕩
  ∾⟨"static ",Define type‿name‿val,";"⟩
}
⟨New⟩ ← {
  Special ← {
    "^promote"𝕊⟨t,v⟩  : ∾"("‿(as.Type t)‿")"‿v ;
    "^load"   𝕊⟨p,i  ⟩: ∾p‿"["‿i‿"]" ;
    "^store"  𝕊⟨p,i,v⟩: ∾p‿"["‿i‿"] = "‿v
  }
  Call ← 1⊸↑⊸≡⟜"^"◶⟨{𝕨‿"("‿𝕩‿")"}⟜List, Special⟩
  code‿op ← <˘⍉>⟨
    "val" ‿(⋈ Lit)
    "call"‿{ decl.Call fn ← Rename 𝕩 ⋄ fn Call (Lit𝕩˙)¨ ↕I32 𝕩 }
    "emit"‿(Name ≡⟜"op"◶⟨
        Call⟜(as.Lit¨All)
        { o←Name 𝕩 ⋄ ⟨Lit 𝕩," ",o," ",Lit 𝕩⟩ }
      ⟩ ⊢)
  ⟩
  New ⇐ {
    id   ← Name 𝕩
    kind ← Name 𝕩
    ty   ← Type 𝕩
    c ← code⊸⊐⌾< kind
    (∾"Unknown new: `"‿kind‿"`") ! c<≠code
    val ← (c⊑op) {𝕎𝕩} 𝕩
    {"void"≡ty?∾val; Define ty‿id‿val}
  }
}

code‿op ← (⊑¨ ⋈ 1⊸↓¨) ⟨
  "export"  ‿ 0‿0‿⟨Export⟩
  "constant"‿ 0‿0‿⟨Constant⟩
  "beginFn" ‿ 1‿0‿⟨BeginFn⟩
  "lbl"     ‿ 0‿1‿⟨Name,":"⟩
  "ret"     ‿ 0‿1‿⟨"  ","return","void"⊸≢◶⟨""," "⊸∾⟩ Lit⟩
  "gotoF"   ‿ 0‿1‿⟨"  ","if (!(",Lit,")) ","goto ",Name⟩
  "gotoT"   ‿ 0‿1‿⟨"  ","if (",Lit,") ","goto ",Name⟩
  "goto"    ‿ 0‿1‿⟨"  ","goto ",Name⟩
  "new"     ‿ 0‿1‿⟨"  ",New⟩
  "mut"     ‿ 0‿1‿⟨"  ",Name," = ",Lit⟩
  "endFn"   ‿¯1‿1‿⟨"}"⟩
⟩

Generate
