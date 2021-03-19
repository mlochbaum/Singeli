tab‿lf←@+9‿10

dig ← '0'+↕10
alph← ⥊"aA"+⌜↕26
wc  ← dig∾alph∾"._"      # Word characters
oc  ← "!$%&*+-/<=>?\^|~" # Operator characters that can stick together

# Source to list of token strings
Tokenize←{
  # Resolve comments and strings
  s‿d‿c‿n←𝕩⊸=¨"'""#"∾lf⋄sd←/¨s‿d
  g←⍋q←(¯1↓¨sd)∾⊸∾/c ⋄q↩g⊏q                 # Open indices
  e← g⊏( 1↓¨sd)∾⊸∾-⟜»∘⊏⟜(0∾+`c)⊸//n∾1       # Matching close indices
  Se←{(⊏˜𝕨)Se 1¨⌾((𝕩/𝕨)⊸⊏)𝕩}⍟(0=¯1⊑⊢)       # Mark reachable openings
  a‿b←((≠𝕩)↑·/⁼((≠↑∾⟜≠Se 1∾0¨)q⍋e)⊸/)¨q‿e   # Open/close masks
  k←»≠`ab←a∨b                               # Token continuation mask
  {⟨⊑/𝕩,"Unclosed quote"⟩!0}⍟(∨´)(s∨d)>k∨a
  ign←(𝕩∊" "∾tab)∨≠`ab∧c∨n                  # Ignored characters
  # Other stuff
  k∨↩∨´(»⊸∧k<𝕩⊸∊)¨wc‿oc                     # Group names, numbers, and ops
  ts←¬k∨ign                                 # Token start mask
  ⟨𝕩⊔˜1-˜ign¬⊸×+`ts, /ts⟩
}

MakeStack ← {𝕤
  st←@ ⋄ d←0
  Push⇐{   st↩𝕩‿st ⋄ d+↩1}
  Pop ⇐{𝕤⋄ r‿s←st ⋄ st↩s ⋄ d-↩1 ⋄ r}
  Arr ⇐{𝕤⋄ ⊑¨ ⌽ 1⊸⊑⍟(↕d) st}
  _while_⇐{Pop ⊢ 𝔽 ⊣ ·Push𝕘˙}
}

MakeStream ← {
  len←≠src←𝕩 ⋄ i←0
  Pos  ⇐ {𝕤⋄i}
  Inc  ← {𝕤⋄i+↩1}
  Rem  ⇐ {𝕤⋄(i+1)<len}
  Peek ⇐ {𝕤⋄i⊑src}
  Next ⇐ Inc ⊢ Peek
}

Parse ← {
  # Three kinds of token tests, distinguished by depth.
  Is ← ≡∘⊢◶⟨
    {𝕏𝕨}   # 0 Function to apply
    ≡      # 1 Token
    ⊑<⊸∊   # 2 List of tokens
  ⟩
  sep ← ⟨";", ⥊lf⟩

  ! (¯1⊑𝕩) Is sep

  Err ← {•←>DumpStack@ ⋄ 𝕨!𝕩}
  MakeTokStream ← {
    Pos‿Rem‿Peek⇐s←MakeStream 𝕩
    Inc ← s.Next
    Next ⇐ Peek⊸Is
    Get  ⇐ Inc ⊢ Peek⊸(⊣⊣≍○<Err⍟(¬⊢)Is)
    Try  ⇐ 1∘Inc⍟⊢∘Next
  }
  ⟨Next,Get,Peek,Try,Rem,Pos⟩ ← MakeTokStream 𝕩

  # Node creation and error tracking
  c ← nodes
  ⟨_whileParse_⇐_while_, DumpStack⇐Arr⟩ ← MakeStack@
  _node_ ← {𝔽 𝔾_whileParse_⟨𝕗,Pos@⟩ 𝕩}

  When  ← {Test‿Cont:       ( ⥊∘< Cont)⍟Test   ⟨⟩  }
  While ← {Test‿Cont‿init: {(𝕊∾⟜<⟜Cont)⍟Test𝕩} Cont¨↕init}
  _seq ← {≡¨⊸((≠⟜1∧(<sep)≢¨⊢)/>⟜0◶{𝕏@}‿Get¨) 𝔽}

  Name ← Get (⊑alph∊˜⊏)˙
  Word ← Get (⊑(wc∾oc)∊˜⊏)˙

  AddParams ← {𝕊∘(c.run  _node_ (⊢≍○<"{"‿"}"_args))⍟(Next"{") 𝕩}
  AddArgs   ← {  (c.call _node_ (⊢≍○<"("‿")"_args))⍟(Next"(") 𝕩}
  Expr0 ← {𝕤
    Vec ← c.run _node_ (⟨c.Word"vector"⟩ ∾ "["‿Expr‿"]"‿Expr0 _seq)
    Par ← ⊑ "("‿Expr‿")" _seq
    ¬∘Is⟜"["◶⟨Vec, ¬∘Is⟜"("◶⟨Par,c.word _node_ Word⟩⟩ Peek@
  }
  Callable ← AddParams∘Expr0
  Expr ← c.phrase _node_ {𝕤
    While ⟨¬Next∘(sep∾⥊¨",:=)}"), AddArgs∘Callable, 0⟩
  }

  _args ← {𝕤
    Get ⊑𝕗
    a ← While ⟨Try∘",", Expr, 1⟩
    Get 1⊑𝕗
    a
  }

  Statement ← {
  "if":     c.if     _node_ ("if"‿"("‿Expr‿")"‿Statement‿(When∘⟨Next∘"else",Statement⟩)_seq)@ ;
  "while":  c.while  _node_ (1 ∾   "while"‿"("‿Expr‿")"‿Statement _seq)@ ;
  "do":     c.while  _node_ (0 ∾⟜⌽ "do"‿Statement‿"while"‿"("‿Expr‿")"‿sep _seq)@ ;
  # TODO: make most of the for definition conditional
  "@":      c.for    _node_ ("@"‿Callable‿"("‿(While∘⟨Try∘",", Name, 1⟩)‿"over"‿Name‿"from"‿Expr‿"to"‿Expr‿")"‿Statement _seq)@ ;
  "return": c.return _node_ ("return"‿Expr _seq)@ ;
  "{":      c.body   _node_ Body@ ;
  𝕩:
    n ← Expr@
    d ← Try ":"
    e ← Try "="
    t ← When ⟨d>e, {e↩Try"="⋄𝕩}∘Expr⟩
    c.assign _node_ {⟨𝕩,d,t,Expr@⟩}⍟e n
  }∘Peek

  Seps ← {Try∘sep◶@‿𝕊𝕩}
  Body ← {𝕤
    Get "{"
    While ⟨¬Try∘"}"∘Seps, Statement, 0⟩
  }
  # 𝕩 indicates if preceding token was =
  Result ← c.body _node_ (Next∘"{"◶⟨Expr‿sep _seq !, Body⟩)

  Params ← {𝕤
    Param ← {𝕤
      n ← Name@
      e ← When ⟨Try"==", Expr⟩
      n‿e
    }
    Get "{"
    a ← While ⟨Try∘",", Param, 1⟩
    c ← While ⟨Try∘"&", Expr, 0⟩
    Get "}"
    a‿c
  }
  _withParams ← {𝕤
    (Next"{")◶⟨𝔽, c.lambda _node_ (Params‿𝕊 _seq)⟩@
  }

  Function ← c.function _node_ {𝕤
    Get "("
    Arg ← c.arg _node_ (Name‿":"‿Expr _seq)
    a ← While ⟨Try∘",", Arg, 1⟩
    Get ")"
    r ← When ⟨Try":", Expr⟩
    b ← Result Try"="
    ⟨a,r,b⟩
  } _withParams
  Generator ← {𝕤⋄ Get"=" ⋄ Result 1} _withParams
  DefFun ← c.define _node_ (      Name‿Function  _seq)
  Define ← c.define _node_ ("def"‿Name‿Generator _seq)

  Symb ← '''=⊑
  Export ← c.export _node_ ((Get symb˙)‿"="‿Callable‿sep _seq)

  Program ← c.body _node_ {𝕤
    Line ← ¬∘Is⟜"def"◶⟨Define, Symb◶DefFun‿Export⟩∘Peek
    While ⟨Rem, Line∘Seps, 0⟩
  }

  Program @
}

operator ← {
  Parse ⇐ {ops 𝕊 val:
    Peek‿Next‿Rem ← MakeStream ops {null‿left‿bind‿R⇐𝕨 ⋄ value⇐𝕩}¨ val
    E ← {𝕊test: {𝕊∘{𝕩 LeD Next@}⍟(Test Peek)⍟Rem 𝕩} NuD Next@ }
    NuD ← { 𝕩.null ≢⟜@◶{𝕩.value}‿{nodes.Run ⟨𝕩.R 𝕨.v, ⟨E 𝕨.t⟩⟩} 𝕩 }
    LeD ← { !@≢l←𝕩.left ⋄ nodes.Run ⟨𝕩.R l.v, ⟨𝕨, E l.t⟩⟩ }
    E 1
  }
  New ← {𝕤
    null ⇐ left ⇐ @
    bind ⇐ ¯∞
    R ⇐ ⊢
    Op ← {val‿p‿c←𝕩 ⋄ v⇐val ⋄ T⇐p C {𝕩.bind}}  # Value and test
    AddNull ⇐ {𝕊⟨value, prec⟩: AddNull↩!∘0
      null ↩ Op ⟨value, prec, <⟩
    }
    AddLeft ⇐ {𝕊⟨value, prec, assoc⟩: AddLeft↩!∘0
      bind ↩ prec
      left ↩ Op ⟨value, prec, ("lrn"⊸⊐⌾<assoc)⊑<‿≤‿(!∘≠⊢<)⟩
    }
  }
  Run ⇐ {𝕊⟨op,params⟩: null‿left‿bind⇐op ⋄ R⇐nodes.Run op.R≍○<params˙}
  nil ⇐ New @

  Lookup‿AddPrefix‿AddInfix ⇐ {
    n←⟨⟩ ⋄ o←⟨⟩
    _get ← {(n⊸⊐⌾<𝕩) =⟜(≠n)◶{𝕨⊑o}‿𝔽 𝕩}
    Lookup ⇐ nil _get
    Define ← {n∾↩<𝕩 ⋄ o∾↩<r←New@ ⋄ r} _get
    AddPrefix ⇐ {𝕊name‿value‿prec:
      p←Define name ⋄ p.AddNull ⟨nodes.Word value,prec⟩
    }
    AddInfix ⇐ {𝕊name‿value‿prec‿assoc:
      p←Define name ⋄ p.AddLeft ⟨nodes.Word value,prec,assoc⟩
    }
  }
}

_and_ ← { 𝔽◶⟨0,𝔾⟩ }
IsNum ← 1=•Type
IsInt ← IsNum _and_ (⌊⊸=)
IsNat ← IsInt _and_ (0⊸≤)
IsTup ← 0=•Type
IsGet ← 3=•Type
Show ← {•Type◶⟨"tup{"∾"}"«·∾(","∾𝕊)¨, ⍕, !,!,!,!,!, {𝕩.Show@}⟩𝕩}

TypeCast ← ⊢ # TODO

⟨IsType⟩ ← types ← {
  IsType ⇐ {𝕊v: type=v.class}
  Type ← {k𝕊d:
    class⇐𝕤
    kind‿dat⇐𝕨‿𝕩
    Show⇐kind◶⟨
      "void"               # Void:                     void
      ∾⟜⍕´                 # Primitive:   qual‿len     u8
      {∾"["‿𝕨‿"]"‿𝕩}○Show´ # Vector:      count‿t      [4]…
      "*"∾Show             # Pointer:     t            *…
      {∾𝕨‿" -> "‿𝕩}○Show´  # Function:    ⟨t, q‿r‿s⟩   (…,…,…) -> …
      Show                 # Tuple:       q‿r‿s        (…,…,…)
    ⟩∘dat
  }
  tVOID‿tPRIM‿tVEC‿tPTR‿tFUN‿tTUP ← ↕6

  primTypes ⇐ (tVOID Type ⟨⟩)∾∾(<(tPRIM Type ≍)¨´)˘ ∘‿2⥊⟨
    'u', 2⋆0∾3+↕4  # 1/8/16/32/64
    'i', 2⋆  3+↕4  #   8/16/32/64
    'f', 2⋆  5+↕2  #        32/64
  ⟩

  Vec ⇐ {n𝕊t: !IsNat n ⋄ !IsType t ⋄ tVEC Type ⟨n,t⟩}
  Ptr ⇐ { 𝕊t: !IsType t ⋄ tPTR Type t}

  Kind←{𝕩.kind} ⋄ Dat←{𝕩.dat}
  _cases ← {
    c ← ⌊‿2⥊𝕗
    k ← ⊏˘c
    d ← (1⊏˘c) ∾ ((≠⥊c)↓𝕗)»⟨!∘0⟩
    (k⊸⊐⌾< ⊢⊘(≠◶⊢‿¯1)○Kind)◶({𝕏○Dat}¨d) ⊣ @○(!IsType)
  }

  Size ⇐ ⟨
    tPRIM, 1⊸⊑
    tVEC,  ×⟜{Size𝕩}´
    tTUP,  +´{Size𝕩}¨
  ⟩_cases

  VCount ⇐ ⟨ tVEC,⊑, 1 ⟩ _cases

  _sub ← {
    L ← ¯1⊸⊑
    𝕨 ⟨
      tVEC,  =○⊑ _and_ (𝕊○L)
      tTUP,  =○≠ _and_ (∧´𝕊¨)
      tPRIM, ≠○⊑◶⟨𝔽○L, ('f'≠⊑∘⊣)_and_(<○L)⟩
      0
    ⟩ _cases 𝕩
  }
  Subtype  ⇐ ≤ _sub
  SSubtype ⇐ < _sub
}

⟨IsReg⟩ ← register ← {
  IsReg ⇐ {new=𝕩.class}
  New ⇐ {class⇐𝕤 ⋄ type⇐𝕨 ⋄ handle⇐𝕩}
}

⟨IsFun,Emit,CallFn⟩ ← functions ← {
  IsFun ⇐ {new=𝕩.class}
  fid←¯1 ⋄ current⇐@
  New ⇐ {𝕤
    class⇐𝕤 ⋄ id⇐fid+↩1
    handle←¯1 ⋄ label←¯1 ⋄ args←⟨⟩ ⋄ rType⇐@
    Next⇐{ 𝕩 register.New handle+↩1 }
    NextArg⇐{ args∾↩𝕩 ⋄ Next 𝕩 }
    SetRType⇐{!IsType rType↩𝕩}
    Append‿Instrs⇐
    ⟨Append⇐Push,Instrs⇐Arr⟩←MakeStack@
  }
  NextHandle ⇐ { current.Next 𝕩 }
  NextArg ⇐ { current.NextArg 𝕩 }
  Label ⇐ { current.NextLabel 𝕩 }
  Emit ⇐ {
    current.Append "emit" <⊸∾ 𝕩
  }
  CallFn ⇐ {
    f←⊑𝕩
    ! IsFun f
    current.Append ⟨"call",f.id⟩ ∾ 1↓𝕩
  }
  _instr ← { current.Append (<𝕗)∾𝕨≍○<𝕩 }
  SetLabel ⇐ "lbl"_instr
  Goto     ⇐ "goto"_instr
  GotoF    ⇐ "gotoF"_instr
}


builtins ← ∾≍⟨
  Show¨⊸≍ types.primTypes
  ⍉> ⟨"call"‿CallFn,"emit"‿Emit,⟨"vector",types.Vec⟩,⟨"pointer",types.Ptr⟩⟩
⟩

scopes ← {
  null←{Get⇐"Undefined name: "⊸∾!0˙}
  New⇐{
    n←𝕨⊣⟨⟩ ⋄ PG←𝕩.Get
    Add⇐{ ("Duplicate definition: "∾𝕩)!¬∨´≡⟜𝕩¨n ⋄ c←≠n ⋄ n∾↩<𝕩 ⋄ c⊑env.Vars }
    Get⇐{ (n⊸⊐⌾<𝕩) =⟜(≠n)◶{𝕨⊑env.Vars}‿{(PG𝕩)∘env.Parent} 𝕩 }
    Names⇐{𝕤⋄n}
  }
  Init⇐New null˙
}
var ← {
  Fixed⇐{ Get⇐𝕩˙ }
  New⇐{
    v←𝕩 ⋄ Get⇐{𝕤⋄v} ⋄ Set⇐{v↩𝕩}
    Type⇐{Type↩!∘0 ⋄ Set↩Set 𝕩⊸TypeCast}
  }
  Get⇐{𝕩.Get@}
  Set⇐{𝕨.Set𝕩}
}
env ← {
  Vars  ⇐{𝕩.vars}
  Parent⇐{𝕩.parent}
  Make ←{ vars⇐𝕨 ⋄ parent⇐𝕩 ⋄ fn⇐𝕩.fn ⋄ SetFn⇐{fn↩𝕩} }
  New  ⇐{ (var.New∘@¨ 𝕨) Make 𝕩 }
  Fixed⇐{ (var.Fixed¨ 𝕨) Make 𝕩 }
}

nodes ← {
  # Node operations
  o ← {
    Verify ⇐ {𝕩.node}
    Dump ⇐ {𝕩.Dump@}
    Disp ⇐ {𝕩.Disp@}
    Oper ⇐ {𝕩.Oper@}
    Scope⇐ {𝕊sc :{𝕩.Scope sc }}
    Eval ⇐ {𝕊env:{𝕩.Eval  env}}
  }
  Defaults ← {
    node‿visit ⇐ 𝕩
    Visit o.verify
    Dump ⇐ {𝕤⋄⟨node,Visit o.dump⟩}
    Disp ⇐ {𝕤⋄node <⊸∾ "  "⊸∾¨ ∾∾ @ ⥊∘<∘⊢⍟((2×≡)+≡⟜@)¨○Visit o.disp}
    Oper ⇐ {𝕤⋄Visit o.oper ⋄ operator.nil}
    Scope⇐ {Visit o.Scope 𝕩⋄@}
    Eval ⇐ {Visit o.Eval 𝕩}
  }

  # Node types
  Ident ← {
    name⇐𝕩
    ⟨node,Dump⟩⇐Defaults "ident"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
    Oper⇐{𝕤⋄operator.Lookup name}
    E←!∘0 ⋄ Eval⇐{E𝕩} ⋄ Scope⇐{E↩var.Get∘(𝕩.Get name)}
  }
  Value ← {
    name⇐𝕨
    Eval⇐𝕩˙
    ⟨node,Dump,Oper,Scope⟩⇐Defaults "value"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
  }
  bName‿bVal ← <˘builtins
  Word ⇐ {
    AWord ← bName⊸⊐⌾< ≥⟜(≠bName)◶⟨⊢ Value ⊑⟜bVal, Ident ⊢⟩ ⊢
    (∧´∊⟜("."∾dig))◶⟨AWord, Value⟜⍎⟩ 𝕩
  }
  Run ⇐ {
    ⟨caller,params⟩⇐𝕩
    Visit←{⟨𝕏caller,𝕏¨params⟩}
    ⟨node,Dump,Disp,Scope⟩⇐d←Defaults "run"‿visit
    Oper ⇐ {𝕤⋄ operator.Run ⟨⊑Visit o.oper,params⟩}
    Eval ⇐ {𝕎𝕩}´ d.Eval
  }
  Call ⇐ Run (Word"call") ≍○< <⊸∾´
  Return ⇐ Run (Word"return") ≍○< ⥊∘<
  Phrase ⇐ {
    things⇐𝕩
    Visit←{⟨𝕏¨things⟩}
    ⟨node,Dump,Disp,Scope,Eval⟩⇐d←Defaults "phrase"‿visit
    Oper⇐{𝕤
      ⟨node,Dump,Disp,Scope,Eval⟩↩o.Oper¨⊸operator.Parse things
      operator.nil
    }
  }
  ParamEq ← Run (Word"match"){⟨𝕗,𝕨‿𝕩⟩}
  Lambda ⇐ {
    ⟨⟨params,conds⟩,result⟩⇐𝕩
    conds∾˜↩∾<⊸(Word⊸ParamEq¨)´¨params
    params↩⊑¨params
    Visit←{params∾⟨𝕏¨conds,𝕏result⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "lambda"‿visit
    Scope⇐{ Visit o.Scope params scopes.New 𝕩 }
    Eval⇐{𝕊 e:
      class⇐lambda
      Test⇐{params≡○≢𝕩}  # TODO
      Run⇐{result.Eval 𝕩 env.Fixed e}
    }
  }
  Arg ⇐ {
    ⟨name,type⟩⇐𝕩
    Visit←{⟨name,𝕏type⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "arg"‿visit
    v←@ ⋄ Scope⇐{ v ↩ 𝕩.Add name }
    Eval⇐{ u←V𝕩 ⋄ u.Type t←type.Eval 𝕩 ⋄ u.Set functions.NextArg t }
  }
  Function ⇐ {
    ⟨args,type,result⟩⇐𝕩
    Visit←{⟨𝕏¨args,𝕏¨type,𝕏result⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "function"‿visit
    Scope⇐{ Visit o.Scope scopes.New 𝕩 }
    Eval⇐{
      fs←functions.current ⋄ f←functions.current↩functions.New@
      ev←o.Eval args env.New 𝕩
      f.SetRType∘Ev¨ type
      Ev¨ args
      Ev result
      functions.current↩fs
      f
    }
  }
  Assign ⇐ {
    ⟨name,decl,type,value⟩⇐𝕩
    name {n←⊑t←𝕩.things ⋄ !1=≠t ⋄ !"ident"≡n.node ⋄ n.name}˜↩@
    Visit←{⟨name∾decl/":",𝕏¨type,𝕏value⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "assign"‿visit
    GetVar←!∘0 ⋄ Scope⇐{
      Visit o.Scope 𝕩
      getVar ↩ decl◶⟨𝕩.Get, 𝕩.Add⟩ name
    }
    Eval⇐{
      u ← GetVar 𝕩
      v ← value.Eval𝕩
      u var.SetType⟜(≠◶⟨TypeOf v˙, (o.Eval𝕩)∘⊑⟩)⍟decl type
      u Set v
    }
  }
  Define ⇐ {
    ⟨name,value⟩⇐𝕩
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "define"‿visit
    v←@ ⋄ Scope⇐{ v ↩ 𝕩.Add name ⋄ value.Scope 𝕩 }
    Eval⇐{ (V𝕩) var.Set value.Eval 𝕩 }
  }
  Export ⇐ {
    ⟨name,value⟩⇐𝕩
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp,Oper,Scope⟩⇐Defaults "export"‿visit
    Eval⇐"TODO:exports"!0˙
  }
  Body ⇐ {
    statements⇐𝕩
    Visit←{⟨𝕏¨statements⟩}
    ⟨node,Dump,Disp,Oper⟩⇐d←Defaults "body"‿visit
    sc←@ ⋄ Scope⇐{ Visit o.Scope sc ↩ scopes.New 𝕩 }
    Eval⇐{ ¯1⊑⊑d.Eval (sc.Names@) env.New 𝕩 }
  }
  If ⇐ {
    ⟨cond,then,else⟩⇐𝕩
    Visit←{⟨𝕏cond,𝕏then,𝕏¨else⟩}
    ⟨node,Dump,Disp,Oper,Scope⟩⇐Defaults "if"‿visit
    Eval ⇐ {𝕊e:
      c ← cond.Eval𝕩
      lf ← functions.Label@
      c functions.GotoF lf
      then.Eval𝕩
      functions.Goto¨ lt ← functions.Label¨ else
      functions.SetLabel lf
      { 𝕩.Eval e ⋄ functions.SetLabel lt }¨ else
    }
  }
  While ⇐ {
    ⟨testFirst,cond,stmt⟩⇐𝕩
    Visit←{⟨𝕏cond,𝕏stmt⟩}
    ⟨node,Dump,Disp,Oper,Scope⟩⇐Defaults "while"‿visit
    Eval ⇐ {
      functions.Goto¨ lc ← functions.Label¨↕testFirst
      functions.SetLabel lt ← functions.Label@
      stmt.Eval𝕩
      functions.SetLabel¨ lc
      (cond.Eval𝕩) functions.Goto lt
    }
  }
}

operator.AddPrefix¨⟨
  "-"‿"__neg" ‿30
  "$"‿"vector"‿50
  "*"‿"pointer"‿60
⟩
operator.AddInfix¨⟨
  "<"‿"__lt" ‿20‿'n'
  ">"‿"__gt" ‿20‿'n'
 "<="‿"__le" ‿20‿'n'
 ">="‿"__ge" ‿20‿'n'
  "+"‿"__add"‿30‿'l'
  "-"‿"__sub"‿30‿'l'
  "*"‿"__mul"‿40‿'l'
  "/"‿"__div"‿40‿'l'
⟩

ShowAST ← {•Out ∾∾⟜lf¨ 𝕩.Disp @}
ast ← Parse ⊑Tokenize •FChars "tests/bqn_test.singeli"
ast.Oper @
#ShowAST ast
ast.Scope scopes.Init@
p←ast.Eval {fn⇐@}
•←p.Instrs@
