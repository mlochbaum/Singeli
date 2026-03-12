cpp‿cpu‿prefix‿⟨·,ErrOut,ErrExit,·⟩ ← ∾⟜"_"⌾(2⊸⊑) •args

Asrt ← {𝕨𝕊1:𝕩; ·𝕊𝕩:𝕊𝕨;
  ErrOut "Invalid IR, likely implementation bug!"
  ErrOut⍟(0⊸≢) 𝕩 ⋄ ErrExit@
}

types ← {
  ub←uv←um←0 ⋄ req←⟨⟩ ⋄ init ⇐ {ub↩uv↩um↩0⋄req↩⟨⟩}
  Require ⇐ {𝕊: req∾↩<𝕩}
  Headers ⇐ {𝕊: ⍷ req ∾˜ 1‿ub‿um‿(uv>0)/⟨"stdint.h","stdbool.h","math.h",cpu.header⟩}
  Type ⇐ { 𝕨 𝕊 bType‿w‿am‿ptrs‿disp:
    Err ← {ErrOut ∾⟨"Unhandled type `",disp,"`: ",𝕩⟩ ⋄ ErrExit@} 
    u‿f ← bType = "uf"
    (" "∾𝕨) ⊢⊘(∾˜) (ptrs/"*") ∾˜ {
      0<≠am     ? uu‿t ← Err∘⊑⍟(0==) cpu.VecType w‿am‿u‿f ⋄ uv⌈↩uu ⋄ t ;
      f         ? "float"‿"double"⊑˜32‿64⊸⊐⌾<w ;
      w=0       ? "void" ;
      u∧w=1     ? "bool" ⊣ ub↩1 ;
      ⊑w∊2⋆3+↕4 ? ∾⟨u/"u","int",•Repr w,"_t"⟩ ;
      Err "invalid scalar type"
    }
  ;
    𝕨𝕊⟨"fn",res‿args,ptrs,disp⟩:
    ∾⟨res, " (*",ptrs/"*",𝕨⊢⊘∾")(", ","Join args, ")"⟩
  }
  SpecialFloat ⇐ {um↩1 ⋄ n←'-'=⊑𝕩 ⋄ (n↑𝕩)∾"NAN"‿"INFINITY"⊑˜"0/0"‿"1/0"⊸⊐⌾<n↓𝕩}
}

lf ← @+10
Pr ← ≤○≠◶⟨0,⊣≡≠⊸↑⟩

Generate ← {
  decl.Init@ ⋄ types.Init@
  fn ← 0  # Whether a function is active
  ProcLine ← {
    line ← StartLine 𝕩
    c ← code⊸⊐⌾< Name line
    (∾"Unknown operation: `"‿𝕩‿"`") Asrt c<≠code
    depth‿infn‿do ← c ⊑ op
    "Invalid function containment" Asrt fn ≡ infn
    fn +↩ depth
    res ← ∾ do {𝕎𝕩}¨ <line
    line.Finish @
    res ∾ ⟨infn∧fn,(0<≠res)∧2-fn⟩/';'‿lf
  }⍟(0<≠)
  l ← ProcLine¨ lf ((⊢-˜+`×¬)∘=⊔⊢) 𝕩
  "Unclosed function" Asrt 0≡fn
  prelude ← lf Join ("#include"∾("<"∾∾⟜">")⍟('"'≠⊑))¨ types.Headers@
  ∾ (𝕨⊣prelude) ((⊣⋈(⊣×1+⊢)○(0<≠)⥊lf˙)∾⊢) (decl.Emit@)∾l
}

StartLine ← { 𝕊 str:
  Assert ← { Asrt ∾𝕨‿": `"‿str‿"`" }⍟(1≢⊢)
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
    "Excessive IR line" Assert tok ≠⊸≤◶⟨(∨´ IsWS ∨ ·∨`'#'⊸=)⊑˜, 1⟩ i+1
  }
}

Nat ← 10⊸×⊸+˜´∘⌽ -⟜'0'
Nest ← +`·-˝=⌜
as ← {
  Sym ⇐ (⊢-128×(' '+128)⊸=) 1↓¯1↓⊢
  Name ⇐ Sym⍟('''=⊑)
  Rename ⇐ prefix∾1⊸↓⍟('$'=⊑)
  I32 ⇐ ('-'=⊑)⊸(⊣-∘⊢⍟⊣Nat∘↓)
  Lit ⇐ (⊑"'$!"⊐⊏)◶Sym‿({decl.Call𝕩⋄𝕩}⍟('f'=⊑∘⊣)⟜Rename 1⊸↓)‿{
    Bl ← 0<"{}"⊸Nest ⋄ br ← Bl𝕩
    v‿t ← (1-˜+`×¬)∘(1⌾⊑br<':'⊸=)⊸⊔ 𝕩
    {¬∨´br?
      v ∾↩ {
        'f': h←⊑'x'∊v ⋄ v types.SpecialFloat⍟(e←⊑'/'∊v)↩
             {𝕩∾(h/"p0")∾e¬⊸/"f"}⍟("f32"≡t) "."/˜¬e∨h∨´"e."∊v ;
        (('u'=𝕩)/"u")∾"ll"
      }⊑t
      m ← "-0x8000000000000000"≡v # For floats: negate after cast
      ∾⟨"(",m↑v,"(",Type t,")",m↓v,")"⟩
    ;
      "Invalid IR literal" Asrt "tup{" Pr v
      "{"∾"}"∾˜∾1↓⥊(<",")≍˘ Lit¨ ((⊢-˜+`×¬)∘(Bl<','⊸=)⊔⊢)○(¯1↓4↓⊢) v
    }
  }‿⊢
  Type ⇐ { 𝕨𝕊s:  # Singeli type to native
    s ↓˜↩ ptrs ← +´∧`'*'=s
    s ↩ ⊢´ v ← ((1-˜¬∘∨×1+`⊢)˝·⊑⊸∧"[]"=⌜⊢)⊸⊔ s
    am ← Nat¨ ¯1↓v
    ParseFn ← {
      s ← (','=𝕩)∧n←(1⊸=∧·∧`0⊸<)"()"Nest𝕩
      a ← Type¨ ((1-˜+`×¬)s∨»⊸≠⊸≥n)⊔𝕩
      "Invalid IR type" Asrt ")->" Pr r←n¬⊸/𝕩
      ⟨Type 3↓r, a⟩
    }
    𝕨 types.Type ⟨𝕩⟩ ∾˜ {
      "void": 'v'‿0‿⟨⟩‿ptrs;
      '('=⊑𝕩? ⟨"fn",ParseFn 𝕩,ptrs⟩;
      ⟨⊑𝕩, Nat 1↓𝕩, am, ptrs⟩
    } s
  }
}

Name‿Rename‿Type‿Lit‿I32 ← {𝕏{𝔽∘𝔾⊘(𝔽⟜𝔾)}{𝕩.Next@}}¨ ⟨as.Name,as.Rename,as.Type,as.Lit,as.I32⟩
All ← {𝕩.All@}

decl ← {
  FromName ← Nat · (∧`'_'⊸≠)⊸/ (1+≠prefix)⊸↓  # si_f
  c←o←@ ⋄ Init⇐{𝕤⋄c↩↕0⋄o↩⟨⟩}
  BeginFn ⇐ { n←FromName𝕨 ⋄ n<≠c ? n⊑c ? o∾↩<𝕩 ; @}
  Call ⇐ { i←FromName𝕩 ⋄ c↑˜↩(≠c)⌈1+i ⋄ c 1⌾(i⊸⊑)↩ }
  Emit ⇐ {𝕤⋄ ∾⟜⟨⥊lf⟩⍟(0<≠) (¯2⊸↓∾(";"∾lf)˙)¨ o }
}

Join ← {∾1↓⥊(<𝕨)≍˘𝕩}
List ← ", "⊸Join

BeginFn ← {𝕤
  FmtExt ← {
    e ← ((-´"aA")×'A'⊸≤)⊸+ 1↓𝕩
    ∾"__attribute__ ((__target__ ("""‿e‿""")))"‿lf
  }
  n ← as.Rename nn ← Name 𝕩
  ret ← n Type 𝕩
  argc ← I32 𝕩
  param ← Name⊸Type∘𝕩¨ ↕argc
  exts ← All 𝕩 ⋄ Asrt 1≥≠exts ⋄ Asrt ∧´('+'=⊑)¨exts
  fexts ← FmtExt¨exts
  { "main"≢nn
  ? n⊸decl.BeginFn⊸⊢ ∾fexts∾⟨"static ",ret,"(",List param,") {"⟩
  ; pc ← (⊢∾" = ("∾(∧`' '⊸≠)⊸/∾")argv;"˙)¨1↓param
    ∾fexts∾⟨"int main(",List "char** argv"¨⌾(1⊸↓)param,") {"⟩∾pc
  }
}
Export ← {
  exp ← "const "∾Name 𝕩
  ret ← exp Type 𝕩
  val ← Lit 𝕩
  ∾⟨ret," = ",val,";"⟩
}
Define ← {st 𝕊 ty‿id‿val:
  arr ← {'*'=⊑ty? ∨´"{?"=c←⊑1↑⊑val? # Define array, then pointer cover
    v←val ⋄ val↩i←id∾"_" ⋄ id∾⍟st˜↩"const "
    {'?'=c? UndefArr ⟨ty,i,(∧`':'⊸≠)⊸/1↓⊑v⟩ ;
     cpp>st? DefCppArr ⟨ty,i,∾v⟩ ; ⟨st Define ⟨1↓ty,i∾"[]",v⟩, "; "⟩}
  ; ⟨⟩}
  eq ← {cpp>st? ⟨"; ",id," = "⟩ ; ⟨" = "⟩}
  ∾∾⟨
    arr, (1=st)/⟨"static "⟩
    ⟨id as.Type ty⟩, ((¬"?"Pr⥊∘⊑) / eq⊸∾) val
  ⟩
}
UndefArr ← {𝕊 ty‿id‿n: (0 Define ⟨1↓ty,∾id‿"["‿n‿"]",⟨"?"⟩⟩) ∾ "; "}
# For C++, initialize array by creating a second in a temp scope and copying
DefCppArr ← {𝕊 ty‿i‿v:
  it←i∾"t"
  n←•Repr("{}"≢v)+´(','⊸=∧1="{}"⊸Nest)v
  ∾⟨
    UndefArr ty‿i‿n, "{ "
    2 Define ⟨1↓ty,it∾"[]",v⟩, "; "
    "for (unsigned i=0; i<",n,"; i++) ",i,"[i] = ",it,"[i]; } "
  ⟩
}
Constant ← {
  id   ← Rename 𝕩
  type ← Name 𝕩 # Define turns to type
  val ← Lit 𝕩
  (1 Define type‿id‿val)∾";"
}
Require ← { types.Require Name 𝕩 ⋄ "" }
⟨New, Mut⟩ ← {
  Cast ← {∾"("‿(as.Type 𝕨)‿")"‿𝕩}
  Special ← {
    "^promote"𝕊⟨t,v⟩  : t Cast v ;
    "^bitcast"𝕊⟨s,t,v⟩: { s∧○(⊑⊏∊"iu*"˙)t ? s Cast v ;
                          s ≡○as.Type t ? v ; "^bitcast"‿t‿v } ;
    "^load"   𝕊⟨p,i  ⟩: ∾p‿"["‿i‿"]" ;
    "^store"  𝕊⟨p,i,v⟩:  p‿"["‿i‿"] = "‿v
  }
  Call ← ("^"Pr⊣)◶⟨{𝕨‿"("‿𝕩‿")"}⟜List, Special⟩
  code‿op ← <˘⍉>⟨
    "val" ‿(⋈ Lit)
    "call"‿{ fn ← Lit 𝕩 ⋄ fn Call (Lit𝕩˙)¨ ↕I32 𝕩 }
    "emit"‿(Name ("op "Pr⊣)◶⟨
        Call⟜(as.Lit¨All)
        { o←3↓𝕨 ⋄ ⟨Lit 𝕩," ",o," ",Lit 𝕩⟩ }
      ⟩ ⊢)
    "array"‿{"{"∾"}"∾˜∾1↓⥊(<",")≍˘ as.Lit¨ All 𝕩}
  ⟩
  Memcpy ← {id𝕊"^bitcast"‿t‿v:
    types.Require "string.h"
    m ← id∾"_"
    ∾⟨"{",0 Define ⟨t,m,v⟩,"; memcpy(&",id,", &",m,", sizeof(",as.Type t,"));}"⟩
  ;𝕊:@}
  New ⇐ {
    id   ← Name 𝕩
    kind ← Name 𝕩
    ty   ← Name 𝕩 # Define turns to type
    c ← code⊸⊐⌾< kind
    (∾"Unknown new: `"‿kind‿"`") Asrt c<≠code
    val ← (c⊑op) {𝕎𝕩} 𝕩
    {
      "void"≡ty?∾val ;
      @≢m←id Memcpy val?∾⟨id as.Type ty,"; ",m⟩ ;
      0 Define ty‿id‿val
    }
  }
  Mut ⇐ {
    id   ← Name 𝕩
    kind ← Name 𝕩
    c ← code⊸⊐⌾< kind
    val ← {
      c=≠code ? ⟨as.Lit kind⟩ ;
      Name 𝕩 ⋄ (c⊑op) {𝕎𝕩} 𝕩  # Discard type
    } 𝕩
    {@≢m←id Memcpy val? m ; ∾id‿" = "∾val}
  }
}

code‿op ← (⊑¨ ⋈ 1⊸↓¨) ⟨
  "export"  ‿ 0‿0‿⟨Export⟩
  "constant"‿ 0‿0‿⟨Constant⟩
  "require" ‿ 0‿0‿⟨Require⟩
  "beginFn" ‿ 1‿0‿⟨BeginFn⟩
  "lbl"     ‿ 0‿1‿⟨Name,":"⟩
  "ret"     ‿ 0‿1‿⟨"  ","return","void"⊸≢◶⟨""," "⊸∾⟩ Lit⟩
  "gotoF"   ‿ 0‿1‿⟨"  ","if (!(",Lit,")) ","goto ",Name⟩
  "gotoT"   ‿ 0‿1‿⟨"  ","if (",Lit,") ","goto ",Name⟩
  "goto"    ‿ 0‿1‿⟨"  ","goto ",Name⟩
  "new"     ‿ 0‿1‿⟨"  ",New⟩
  "mut"     ‿ 0‿1‿⟨"  ",Mut⟩
  "endFn"   ‿¯1‿1‿⟨"}"⟩
⟩

Generate
