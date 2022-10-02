prefix ← "_" ∾˜ "si" ⊣´ •args

# x86
arch ← {
  Type ⇐ { 𝕨𝕊bType‿w‿am‿ptrs:
    u‿f ← bType = "uf"
    (" "∾𝕨) ⊢⊘(∾˜) (ptrs/"*") ∾˜ {
      0≤am      ? "Unsupported vector type" ! ∊⟜(2⋆6+↕4)⌾<l←w×am  # 64…512
                  ∾⟨"__m",•Repr l,{¬f?"i";(64=w)/"d"}⟩ ;
      f         ? "float"‿"double"⊑˜32‿64⊸⊐⌾<w ;
      w=0       ? "void" ;
      u∧w=1     ? "bool" ;
      ⊑w∊2⋆3+↕4 ? ∾⟨u/"u","int",•Repr w,"_t"⟩ ;
      !"Unsupported type"
    }
  ;
    𝕨𝕊⟨"fn",res‿args,ptrs⟩:
    ∾⟨res, " (*",ptrs/"*",𝕨⊢⊘∾")(", ","Join args, ")"⟩
  }
}

prelude ← 1⌽"
#include<stdint.h>
#include<stdbool.h>
#include<xmmintrin.h>
#include<immintrin.h>
#define "∾prefix∾"assert(A) if (!(A)) __builtin_unreachable();
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
  Rename ⇐ prefix∾1⊸↓⍟('$'=⊑)
  I32 ⇐ ('-'=⊑)⊸(⊣-∘⊢⍟⊣Nat∘↓)
  Nest ← +`·-˝=⌜
  Lit ⇐ (⊑"$!"⊐⊏)◶({decl.Call𝕩⋄𝕩}⍟('f'=⊑∘⊣)⟜Rename 1⊸↓)‿{
    Bl ← 0<"{}"⊸Nest ⋄ br ← Bl𝕩
    v‿t ← (1-˜+`×¬)∘(1⌾⊑br<':'⊸=)⊸⊔ 𝕩
    {¬∨´br?
      s ← {'f':{("."/˜¬∨´"e."∊v)∾("f32"≡t)/"f"}; (('u'=𝕩)/"u")∾"ll"} ⊑t
      ∾⟨"((",Type t,")",v,s,")"⟩
    ;
      !"tup{"≡4↑v
      "{"∾"}"∾˜∾1↓⥊(<",")≍˘ Lit¨ ((⊢-˜+`×¬)∘(Bl<','⊸=)⊔⊢)○(¯1↓4↓⊢) v
    }
  }‿⊢
  Type ⇐ { 𝕨𝕊s:  # Singeli type to native
    s ↓˜↩ ptrs ← +´∧`'*'=s
    am ← { '['≠⊑s ? ¯1 ;
      a‿t ← (1-˜+`×¬)∘(1⌾⊑']'⊸=)⊸⊔ s
      s↩t ⋄ Nat a
    }
    ParseFn ← {
      s ← (','=𝕩)∧n←(1⊸=∧·∧`0⊸<)"()"Nest𝕩
      a ← Type¨ ((1-˜+`×¬)s∨»⊸≠⊸≥n)⊔𝕩
      !")->"≡3↑r←n¬⊸/𝕩
      ⟨Type 3↓r, a⟩
    }
    𝕨 arch.Type {
      "void": 'v'‿0‿¯1‿ptrs;
      '('=⊑𝕩? ⟨"fn",ParseFn 𝕩,ptrs⟩;
      ⟨⊑𝕩, Nat 1↓𝕩, am, ptrs⟩
    } s
  }
}

Name‿Rename‿Type‿Lit‿I32 ← {𝕏{𝔽∘𝔾⊘(𝔽⟜𝔾)}{𝕩.Next@}}¨ ⟨as.Name,as.Rename,as.Type,as.Lit,as.I32⟩
All ← {𝕩.All@}

decl ← {
  FromName ← Nat (1+≠prefix)⊸↓  # si_f
  c←o←@ ⋄ Init⇐{𝕤⋄c↩↕0⋄o↩⟨⟩}
  BeginFn ⇐ { n←FromName𝕨 ⋄ n<≠c ? n⊑c ? o∾↩<𝕩 ; @}
  Call ⇐ { i←FromName𝕩 ⋄ c↑˜↩(≠c)⌈1+i ⋄ c 1⌾(i⊸⊑)↩ }
  Emit ⇐ {𝕤⋄ ∾⟜⟨⥊lf⟩⍟(0<≠) (¯2⊸↓∾(";"∾lf)˙)¨ o }
}

Join ← {∾1↓⥊(<𝕨)≍˘𝕩}
List ← ", "⊸Join

BeginFn ← {𝕤
  n ← Rename 𝕩
  ret ← n Type 𝕩
  argc ← I32 𝕩
  param ← List ((Type𝕩˙)∾" v"∾•Repr)¨ ↕argc
  n⊸decl.BeginFn⊸⊢ ∾⟨"static ",ret,"(",param,") {"⟩
}
Export ← {
  exp ← "const "∾Name 𝕩
  ret ← exp Type 𝕩
  val ← Lit 𝕩
  ∾⟨ret," = ",val,";"⟩
}
Define ← {𝕊 ty‿id‿val:
  {'{'=⊑1↑⊑val? '*'=⊑ty? ty↓˜↩1⋄id∾↩"[]"; @}
  ∾ (id as.Type ty)‿" = "∾val
}
Constant ← {
  id   ← Rename 𝕩
  type ← Name 𝕩 # Define turns to type
  val ← Lit 𝕩
  ∾⟨"static ",Define type‿id‿val,";"⟩
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
    "call"‿{ fn ← Lit 𝕩 ⋄ fn Call (Lit𝕩˙)¨ ↕I32 𝕩 }
    "emit"‿(Name ≡⟜"op"◶⟨
        Call⟜(as.Lit¨All)
        { o←Name 𝕩 ⋄ ⟨Lit 𝕩," ",o," ",Lit 𝕩⟩ }
      ⟩ ⊢)
  ⟩
  New ⇐ {
    id   ← Name 𝕩
    kind ← Name 𝕩
    ty   ← Name 𝕩 # Define turns to type
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
