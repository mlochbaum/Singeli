tab‿lf←@+9‿10

dig ← '0'+↕10
alph← "_"∾⥊"aA"+⌜↕26
wc  ← dig∾alph∾"."       # Word characters
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
  ts←n∨¬k∨ign                               # Token start mask
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

  Err ← {
    l←{𝕨⊸⊐⊏𝕩˙}˝⍉∘‿2⥊⟨c.arg,"arg",c.assign,"assign",c.body,"body",c.call,"call",c.define,"define",c.export,"export",c.for,"for",c.function,"function",c.if,"if",c.lambda,"lambda",c.opdef,"opdef",c.phrase,"phrase",c.run,"run",c.while,"while",c.word,"word"⟩
    •←L⌾(⊏∘⌽⍉)>DumpStack@
    𝕨!𝕩
  }
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
  _node_ ← {𝔽 𝔾_whileParse_⟨Pos@,𝕗⟩ 𝕩}

  When  ← {Test‿Cont:       ( ⥊∘< Cont)⍟Test   ⟨⟩  }
  While ← {Test‿Cont‿init: {(𝕊∾⟜<⟜Cont)⍟Test𝕩} Cont¨↕init}
  _seq ← {≡¨⊸((≠⟜1∧(<sep)≢¨⊢)/>⟜0◶{𝕏@}‿Get¨) 𝔽}

  _begin ← {Get (⊑𝕗∊˜⊏)˙}
  Name ← alph _begin
  Oper ← oc _begin
  Word ← c.word _node_ ((wc∾oc)_begin)
  Symbol ← c.symbol _node_ ("'"_begin)

  AddParams ← {𝕊∘(c.run  _node_ (⊢≍○<"{"‿"}"_args))⍟(Next"{") 𝕩}
  AddArgs   ← {  (c.call _node_ (⊢≍○<"("‿")"_args))⍟(Next"(") 𝕩}
  Expr0 ← {𝕤
    Vec ← c.run _node_ (⟨c.Word"vector"⟩ ∾ "["‿Expr‿"]"‿Expr0 _seq)
    Par ← ⊑ "("‿Expr‿")" _seq
    (⊑"[('"⊐⊏)◶Vec‿Par‿Symbol‿Word Peek@
  }
  Callable ← AddParams∘Expr0
  _exprEnd ← {endTok _𝕣:
    end ← endTok∾sep∾⥊¨",:=)}"
    Call ← { Op←∨´(oc∾"[")=⊏ ⋄ c←¬Next op ⋄ AddArgs⍟c Callable𝕩 }
    c.phrase _node_ (While∘⟨¬Next∘end, Call, 0⟩)
  }
  Expr ← ⟨⟩_exprEnd

  _args ← {𝕤
    Get ⊑𝕗
    a ← While ⟨Try∘",", Expr, 1⟩
    Get 1⊑𝕗
    a
  }

  Statement ← {
  "def":    Define@ ;
  "if":     c.if     _node_ ("if"‿"("‿Expr‿")"‿Statement‿(When∘⟨Next∘"else",Statement⟩)_seq)@ ;
  "while":  c.while  _node_ (1 ∾   "while"‿"("‿Expr‿")"‿Statement _seq)@ ;
  "do":     c.while  _node_ (0 ∾⟜⌽ "do"‿Statement‿"while"‿"("‿Expr‿")"‿sep _seq)@ ;
  "@":      For@ ;
  "{":      c.body   _node_ Body@ ;
  𝕩:
    n ← Expr@
    d ← Try ":"
    e ← Try "="
    t ← When ⟨d>e, {e↩Try"="⋄𝕩}∘Expr⟩
    c.assign _node_ {⟨𝕩,d,t,Expr@⟩}⍟e n
  }∘Peek

  For ← c.for _node_ {𝕤
    Expr ← "over"‿"from"‿"to"_exprEnd # Shadow
    Get "@"
    f ← Callable@
    Get "("
    to← Expr@ ⋄ NE←{𝕤⋄ n←c.PhraseToName to ⋄ to↩Expr@ ⋄ n}
    pe← While ⟨Try∘",", Name, 0⟩
    ps← pe ⊢◶{!0=≠𝕨⋄⟨⟩}‿{(<NE@)∾𝕨} Try"over" # Pointers
    fr← When ⟨Try"from", Expr⟩               # Start index
    i ← ⊢◶{𝕤⋄!0=≠fr⋄⟨⟩}‿{𝕤⋄⟨NE@⟩} Try"to"    # Index variable
    Get ")"
    b ← Statement@
    ⟨f,ps,i,fr,to,b⟩
  }

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

  Export ← c.export _node_ (Symbol‿"="‿Callable‿sep _seq)

  OpType ← {𝕤
    pre ← (⊑≢Get) "prefix"‿"infix"
    pre◶⟨'p', Next◶⟨'n', ⊑∘Get∘1⟩⟩ "none"‿"left"‿"right"
  }
  OpDef ← c.opDef _node_ ("oper"‿OpType‿Oper‿Name‿Word _seq)

  Program ← c.body _node_ {𝕤
    Line ← "def"‿"oper"⊸⊐⌾<◶⟨Define, OpDef, ('''=⊑)◶DefFun‿Export⟩∘Peek
    While ⟨Rem, Line∘Seps, 0⟩
  }

  Program @
}

operator ← {
  Parse ⇐ {ops 𝕊 val:
    Peek‿Next‿Rem ← MakeStream ops {null‿left‿bind‿R⇐𝕨 ⋄ value⇐𝕩}¨ val
    E ← {𝕊test: {𝕊∘{𝕩 LeD Next@}⍟(Test Peek)⍟Rem 𝕩} NuD Next@ }
    NuD ← { 𝕩.null ≢⟜@◶{𝕩.value}‿{nodes.Run ⟨𝕩.R 𝕨.V@, ⟨E 𝕨.t⟩⟩} 𝕩 }
    LeD ← { !@≢l←𝕩.left ⋄ nodes.Run ⟨𝕩.R l.V@, ⟨𝕨, E l.t⟩⟩ }
    E 1
  }
  New ← {𝕤
    null ⇐ left ⇐ @
    bind ⇐ ¯∞
    R ⇐ ⊢
    Op ← {val‿p‿c←𝕩 ⋄ V⇐nodes.Word∘val ⋄ T⇐p C {𝕩.bind}}  # Value and test
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

  Lookup⇐Add⇐!∘0
  _with ⇐ {
    n←⟨⟩ ⋄ o←⟨⟩
    _get ← {(n⊸⊐⌾<𝕩) =⟜(≠n)◶{𝕨⊑o}‿𝔽 𝕩}
    Lookup ↩ nil _get
    Define ← {n∾↩<𝕩 ⋄ o∾↩<r←New@ ⋄ r} _get
    Add ↩ {𝕊type‿name‿value‿prec:
      p ← Define name
      (type≠'p')◶⟨p.AddNull, p.AddLeft∾⟜type⟩ ⟨value,prec⟩
    }
    𝕨𝔽𝕩
    Lookup↩Add↩!∘0
  }
}


# Runtime
# Kinds are:
# - BQN values tuple (list), number, generator (function)
# - Classes symbols, types, registers, functions, blocks
_and_ ← { 𝔽◶⟨0,𝔾⟩ }
IsNum ← 1=•Type
IsInt ← IsNum _and_ (⌊⊸=)
IsNat ← IsInt _and_ (0⊸≤)
IsTup ← 0=•Type

_tsel ← {•Type∘⊣◶(¯1((↓»(6⥊⟨!⟩)˙)∾↑)𝕗)}
Kind  ← ⟨"tuple","number",@,"generator",{𝕩.kind}⟩_tsel
Show  ← {⟨"tup{"∾"}"«·∾(","∾𝕊)¨, ⍕, {𝕩.Shows@}⟩_tsel 𝕩}
Match ← {𝕨 ⟨∧´𝕊¨, ≡, {𝕨𝕨.Matches𝕩}⟩_tsel 𝕩}
TypeOf← {⟨types.Tup 𝕊¨, {𝕩.Type@}⟩_tsel 𝕩}

types ← {kname⇐"type"
  New ← {k𝕊d:
    kind⇐kname
    typeKind‿dat⇐𝕨‿𝕩
    Shows⇐typeKind◶⟨
      "void"               # Void:                     void
      ∾⟜⍕´                 # Primitive:   qual‿len     u8
      {∾"["‿𝕨‿"]"‿𝕩}○Show´ # Vector:      count‿t      [4]…
      "*"∾Show             # Pointer:     t            *…
      {∾𝕨‿" -> "‿𝕩}○Show´  # Function:    ⟨t, q‿r‿s⟩   (…,…,…) -> …
      Show                 # Tuple:       q‿r‿s        (…,…,…)
    ⟩∘dat
    Matches⇐{𝕨MT𝕩}
  }
  tVOID‿tPRIM‿tVEC‿tPTR‿tFUN‿tTUP ← ↕6

  primTypes ⇐ (tVOID New ⟨⟩)∾∾(<(tPRIM New ≍)¨´)˘ ∘‿2⥊⟨
    'u', 2⋆0∾3+↕4  # 1/8/16/32/64
    'i', 2⋆  3+↕4  #   8/16/32/64
    'f', 2⋆  5+↕2  #        32/64
  ⟩

  IsType ← kname≡Kind
  Vec ⇐ {n𝕊t: !IsNat n ⋄ !IsType t ⋄ tVEC New ⟨n,t⟩}
  Ptr ⇐ { 𝕊t: !IsType t ⋄ tPTR New t}
  Tup ⇐ { 𝕊t: !IsTup t ⋄ !∧´IsType¨ t ⋄ tTUP New t}

  Deref ⇐ { !IsType 𝕩 ⋄ !tPTR=𝕩.typeKind ⋄ 𝕩.dat }

  _cases ← {
    Kind←{𝕩.typeKind} ⋄ Dat←{𝕩.dat}
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
      tPTR,  𝕊
      tTUP,  =○≠ _and_ (∧´𝕊¨)
      tPRIM, ≠○⊑◶⟨𝔽○L, ('f'≠⊑∘⊣)_and_(<○L)⟩
      0
    ⟩ _cases 𝕩
  }
  Subtype  ⇐ ≤ _sub
  SSubtype ⇐ < _sub
  MT ⇐ Subtype ∧ Subtype˜

  Cast ⇐ {
    Num←{t𝕊n:
      C←{𝕊q‿l:
        "Cannot cast float to integer"!IsInt n
        "Constant doesn't fit"!1=(-⟜(1⊸⊑÷2˙)⍟(q='i')⟨0,2⋆l⟩)⊸⍋⌾<n
      }⍟('f'≠⊑)
      ⟨ tPRIM,C, 0!˜"Cannot cast number to "∾Show ⟩ _cases t
      t constants.New n
    }
    Obj←{
      ! 𝕩 TypeOf⊸MT 𝕨
      𝕩
    }
    𝕨 ⟨⟨tTUP,⊢⟩_cases⊸(𝕊¨)˜, Num˜, Obj˜⟩_tsel˜ 𝕩
  }
}

registers ← {kname⇐"register"
  New ⇐ {
    kind⇐kname ⋄ type⇐𝕨 ⋄ handle⇐𝕩
    shows⇐"v"∾⍕𝕩 ⋄ Matches⇐≡
    Get⇐⊢ ⋄ SetUsed⇐{𝕤⋄Get↩{ functions.Copy type‿𝕩 }}
  }
  Is ← "register"≡Kind
  JoinNew ← (Is⊣)◶{ 𝕩.SetUsed@ ⋄ 𝕩 }‿{ 𝕨 functions.Mut 𝕩 }
  Join ⇐ JoinNew⟜{ 𝕩.Get 𝕩 }⍟(Is⊢)
}
constants ← {kname⇐"constant"
  New ⇐ {
    kind⇐kname ⋄ type⇐𝕨 ⋄ value⇐𝕩
    shows⇐∾"!:"∾⟜Show¨𝕩‿𝕨 ⋄ Matches⇐≡
  }
}

NewLabel  ← { shows⇐"l"∾⍕𝕩 }
symbols ← {kname⇐"symbol"
  M←(kname≡Kind∘⊢)_and_(≡○Show)
  New⇐{ kind⇐kname ⋄ shows⇐𝕩 ⋄ Matches⇐M }
}

functions ← {kname⇐"function"
  current⇐@
  New ← {𝕤
    kind⇐kname ⋄ shows⇐"f"∾⍕id⇐𝕩 ⋄ Matches⇐≡
    handle←¯1 ⋄ label←¯1 ⋄ args←⟨⟩ ⋄ rType←@
    Next⇐{ 𝕩 registers.New handle+↩1 }
    NextLabel⇐{𝕤⋄ NewLabel label+↩1 }
    NextArg⇐{ args∾↩𝕩 ⋄ Next 𝕩 }
    ⟨Push,Arr⟩←MakeStack@
    Instrs⇐Arr
    Append⇐{ Push𝕩⋄@ ; (1⊸⊑⊣𝕊) ⟨"new",Next𝕨⟩∾symbols.New⌾⊑𝕩 }
    SetRType⇐{ SetRType↩!∘0 ⋄ !IsType rType↩𝕩 }
    _ret←{ Append ⟨"ret", rType ≢⟜@◶⟨𝔽∘⊢, types.Cast⟩ 𝕩⟩ }
    Return⇐!∘0 _ret ⊑
    Finish⇐{SetRtype TypeOf 𝕩⋄𝕩} _ret
    Prot⇐{𝕤⋄ 1↓∾" "⊸∾¨⟨"f"∾⍕id,Show rType⟩∾(⍕∘≠⊸∾Show¨args)}
  }
  IsType ← "type"≡Kind
  _with ⇐ {
    fs←current
    f←current↩program.AddFunction new
    f.Finish f 𝔽 𝕩
    current↩fs
    f
  }
  NextHandle ⇐ { current.Next 𝕩 }
  NextArg ⇐ { current.NextArg 𝕩 }
  Label ⇐ { current.NextLabel 𝕩 }
  Append ← { 𝕨 current.Append 𝕩 }
  Return ⇐ { current.Return 𝕩 }
  Emit ⇐ { (⊑𝕩) Append "emit" <⊸∾ 𝕩 }
  Copy ⇐ { (⊑𝕩) Append "val" <⊸∾ 𝕩 }
  Mut  ⇐ { Append "mut"‿𝕨‿𝕩 ⋄ 𝕨 }
  Call ⇐ {
    f ← ⊑𝕩
    ! "function"≡Kind f
    t ← f.rType
    t Append ⟨"call",t,f.id⟩ ∾ 1↓𝕩
  }
  _instr ← { Append (𝕨𝔽𝕩)<⊸∾𝕨≍○<𝕩 }
  SetLabel ⇐ "lbl"_instr
  Goto     ⇐ "goto"⊘"gotoT"_instr
  GotoF    ⇐ "gotoF"_instr
}

blocks ← {kname⇐"block"
  New ⇐ {𝕊 ind‿ptrs‿body‿e:
    kind⇐kname
    shows⇐"{block}" ⋄ Matches⇐≡
    Exec⇐{
      ! ptrs≡○≠1⊑𝕩
      r ← body.Eval be ← ⟨≠ind,𝕩⟩ env.Block e
      be.Stores @
      r
    }
  }
  Exec ⇐ {𝕊 ind‿vars‿block:
    ! "block"≡Kind block
    block.Exec ind‿vars
  }
}
Load ← {  𝕊 ptr‿i: functions.Emit ⟨types.Deref TypeOf ptr, symbols.New "load", ptr, i⟩ }
Store← {v 𝕊 ptr‿i: functions.Emit ⟨types.Deref TypeOf ptr, symbols.New "store", ptr, i, v⟩ }


builtins ← {
  names‿values ⇐ <˘∾≍⟨
    Show¨⊸≍ types.primTypes
    ⍉> ⟨
      ⟨"call",functions.Call⟩, ⟨"emit",functions.Emit⟩,
      ⟨"return",functions.Return⟩, ⟨"exec",blocks.Exec⟩
      ⟨"match",Match´⟩
      ⟨"type",TypeOf∘⊑⟩, ⟨"kind",symbols.New Kind∘⊑⟩
      ⟨"tup",⊢⟩, ⟨"tupsel",⊑´⟩
      ⟨"cast",types.Cast´⟩
      ⟨"__vec",types.Vec∘⊑⟩, ⟨"__pnt",types.Ptr∘⊑⟩
      ⟨"__neg",-⟩
      ⟨"__lt",<´⟩,  ⟨"__gt",>´⟩,  ⟨"__le",≤´⟩,  ⟨"__ge",≥´⟩
      ⟨"__add",+´⟩, ⟨"__sub",-´⟩, ⟨"__mul",×´⟩, ⟨"__div",÷´⟩
    ⟩
  ⟩
}

scopes ← {
  null←{Get⇐"Undefined name: "⊸∾!0˙}
  New⇐{
    n←𝕨⊣⟨⟩ ⋄ PG←𝕩.Get
    Add⇐{
      i←/≡⟜𝕩¨n
      c ← 𝕨 (≠i)◶{c←≠n⋄n∾↩<𝕩⋄c}‿{("Duplicate definition: "∾𝕩)!𝕨⊣0⋄⊑i} 𝕩
      c⊑env.Vars
    }
    Get⇐{ (n⊸⊐⌾<𝕩) =⟜(≠n)◶{𝕨⊑env.Vars}‿{(PG𝕩)∘env.Parent} 𝕩 }
    Names⇐{𝕤⋄n}
  }
  Init⇐New null˙
}
var ← {
  Get⇐{𝕩.Get@}
  SetType⇐{𝕨.SetType𝕩}
  Fixed⇐{ Get⇐𝕩˙ }
  New⇐{
    v←𝕩 ⋄ Get⇐{𝕤⋄v} ⋄ Set⇐{v↩v registers.Join 𝕩}
    SetType⇐{SetType↩!∘0 ⋄ Set↩Set 𝕩⊸types.Cast}
  }
  # Variable that tracks when it's been set, for block exec
  Marked⇐{
    write⇐0 ⋄ ⟨Get⟩⇐v←New 𝕩 ⋄ Set⇐{write↩1⋄v.Set𝕩}
  }
}
env ← {
  Vars  ⇐{𝕩.vars}
  Parent⇐{𝕩.parent}
  Make ←{ vars⇐𝕨 ⋄ parent⇐𝕩 }
  New  ⇐{ (var.New∘@¨ 𝕨) Make 𝕩 }
  Fixed⇐{ (var.Fixed¨ 𝕨) Make 𝕩 }
  Block⇐{⟨ni,ind‿ptrs⟩ 𝕊 par:
    pi ← ptrs ≍○<¨ <ind
    pv ← Load¨ pi
    vars‿parent ⇐ ((var.New¨↕ni)∾(var.Marked¨pv)) Make 𝕩
    Stores ⇐ {𝕤
      m←{𝕩.write}¨v←ni↓vars
      v var.Get⊸Store¨○(m⊸/) pi
    }
  }
}

program ← {
  AddFunction⇐Export⇐!∘0
  _with ⇐ {
    fns←⟨⟩ ⋄ AddFunction ↩ { f ← 𝕏 ≠fns ⋄ fns∾⟜<↩f ⋄ f }
    exp←⟨⟩ ⋄ Export ↩ { exp ∾⟜<↩ 𝕩 }
    𝕨𝔽𝕩
    AddFunction↩Export↩!∘0
    ∾ ⟨∾DispFunction¨fns, DispExport¨exp⟩
  }
  J ← 1↓·∾" "⊸∾¨
  Disp ← J Show¨⌾(1⊸↓)
  DispFunction←{ ∾⟨"beginFn "∾𝕩.Prot@⟩‿(Disp¨ 𝕩.Instrs@)‿⟨"endFn",""⟩ }
  DispExport←{ "export " ∾ J {𝕩.Prot@}⌾⊑ ⌽𝕩 }
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
    Eval⇐!∘0 ⋄ Scope⇐{Eval↩var.Get∘(𝕩.Get name)}
  }
  Value ← {
    name←𝕨
    Eval⇐𝕩˙
    ⟨node,Dump,Oper,Scope⟩⇐Defaults "value"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
  }
  Word ⇐ (∧´∊⟜("."∾dig))◶⟨Ident, Value⟜•BQN⟩
  Symbol ⇐ Value⟜(symbols.New 1↓¯1↓⊢)
  Run ⇐ {
    ⟨caller,params⟩←𝕩
    Visit←{⟨𝕏caller,𝕏¨params⟩}
    ⟨node,Dump,Disp,Scope⟩⇐d←Defaults "run"‿visit
    Oper ⇐ {𝕤⋄ operator.Run ⟨⊑Visit o.oper,params⟩}
    Eval ⇐ {𝕎𝕩}´ d.Eval
  }
  Call ⇐ { Run ⟨Ident"call" , <⊸∾´𝕩⟩ }
  Phrase ⇐ {
    things←𝕩
    ToName⇐{𝕤⋄ !1=≠things ⋄ n←⊑things ⋄ !"ident"≡n.node ⋄ n.name }
    Visit←{⟨𝕏¨things⟩}
    ⟨node,Dump,Disp,Scope,Eval⟩⇐Defaults "phrase"‿visit
    Oper⇐{𝕤
      n ← o.Oper¨⊸operator.Parse things
      Scope↩{𝕨n.Scope𝕩} ⋄ Eval↩{𝕨n.Eval𝕩} ⋄ Disp↩{𝕨n.Disp𝕩}
      operator.nil
    }
  }
  PhraseToName ⇐ {!"phrase"≡𝕩.node ⋄ 𝕩.ToName@}
  ParamEq ← { Run ⟨Ident"match", 𝕨‿𝕩⟩ }
  Lambda ⇐ {
    ⟨⟨params,conds⟩,result⟩←𝕩
    conds∾˜↩∾<⊸(Ident⊸ParamEq¨)´¨params
    uPar‿iPar←(⍷≍○<⊐)⊑¨params
    Visit←{(iPar⊏uPar)∾⟨𝕏¨conds,𝕏result⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "lambda"‿visit
    Scope⇐{ Visit o.Scope uPar scopes.New 𝕩 }
    Eval⇐{𝕨 𝕊 e: # 𝕨 is previous value
      next ← ({𝕩.Get@}𝕨)⊣{"No matching generator definition"!0˙}
      Check ← {iPar (≡○≢)_and_(∧´(∧´⊏Match¨1⊸↓)¨∘⊔) 𝕩}
      Check◶Next‿{
        F←Next 𝕩˙
        try ← result.eval{𝕨.Eval◶F‿𝕏}´conds
        Try (iPar∊⊸/𝕩) env.Fixed e
      }
    }
  }
  Arg ⇐ {
    ⟨name,type⟩←𝕩
    Visit←{⟨name,𝕏type⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "arg"‿visit
    v←@ ⋄ Scope⇐{ type.Scope 𝕩 ⋄ v ↩ 𝕩.Add name }
    Eval⇐{ u←V𝕩 ⋄ u.SetType t←type.Eval 𝕩 ⋄ u.Set functions.NextArg t }
  }
  Function ⇐ {
    ⟨args,type,result⟩←𝕩
    Visit←{⟨𝕏¨args,𝕏¨type,𝕏result⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "function"‿visit
    Scope⇐{ Visit o.Scope scopes.New 𝕩 }
    Eval⇐{
      ev←o.Eval args env.New 𝕩
      Ev¨ args
      𝕨.SetRType∘Ev¨ type
      Ev result
    }functions._with
  }
  Assign ⇐ {
    ⟨name,decl,type,value⟩←𝕩
    name PhraseToName˜↩@
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
      u.Set v
    }
  }
  Define ⇐ {
    ⟨name,value⟩←𝕩
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "define"‿visit
    isLambda ← "lambda"≡value.node
    v←@ ⋄ Scope⇐{ v ↩ isLambda 𝕩.Add name ⋄ value.Scope 𝕩 }
    Eval⇐{ u←V𝕩 ⋄ u.Set u value.Eval 𝕩 }
  }
  OpDef ⇐ {
    ⟨type,op,fn,prec⟩←𝕩
    !"value"≡prec.node ⋄ !IsNum prec↩prec.Eval@
    Visit←{𝕤⋄⟨type,op,fn,⍕prec⟩}
    ⟨node,Dump,Disp,Scope,Eval⟩⇐Defaults "opdef"‿visit
    Oper⇐{𝕤⋄ operator.Add type‿op‿fn‿prec}
  }
  Export ⇐ {
    ⟨name,value⟩←𝕩 ⋄ name↩Show name.Eval@
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp,Oper,Scope⟩⇐d←Defaults "export"‿visit
    Eval ⇐ { program.Export d.Eval 𝕩 }
  }
  Body ⇐ {
    statements←𝕩
    Visit←{⟨𝕏¨statements⟩}
    ⟨node,Dump,Disp,Oper⟩⇐d←Defaults "body"‿visit
    sc←@ ⋄ Scope⇐{ Visit o.Scope sc ↩ scopes.New 𝕩 }
    Eval⇐{ ¯1⊑⊑d.Eval (sc.Names@) env.New 𝕩 }
  }
  If ⇐ {
    ⟨cond,then,else⟩←𝕩
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
    ⟨testFirst,cond,stmt⟩←𝕩
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
  n0 ← Word "0"
  For ⇐ {
    ⟨fn,ptrs,ind,from,to,body⟩←𝕩
    from↩n0⊣´from
    ptri←Ident¨ptrs
    vardisp←1↓∾(","⊸∾¨ptrs)∾" over "⊸∾¨ind
    Visit←{⟨𝕏fn,vardisp⊣𝕏¨ptri,𝕏from,𝕏to,𝕏body⟩}
    ⟨node,Dump,Disp,Oper⟩⇐d←Defaults "for"‿visit
    Scope ⇐ {
      d.Scope 𝕩
      body.Scope (ind∾ptrs) scopes.New 𝕩
    }
    Eval ⇐ {
      e←o.Eval 𝕩
      for←E fn
      For ⟨E¨ptri, E from, E to, blocks.New ind‿ptrs‿body‿𝕩⟩
    }
  }
}

preamble ← 1↓"
oper prefix      -  __neg 30
oper prefix      $  __vec 50
oper prefix      *  __pnt 60

oper infix none  <  __lt  20
oper infix none  >  __gt  20
oper infix none  <= __le  20
oper infix none  >= __ge  20
oper infix left  +  __add 30
oper infix left  -  __sub 30
oper infix left  *  __mul 40
oper infix left  /  __div 40
"

ast ← {
  Show ⇐ {•Out ∾∾⟜lf¨ 𝕩.Disp @}
  baseScope ← builtins.names scopes.New scopes.Init@
  baseEnv   ← builtins.values env.Fixed @
  Build ⇐ Parse∘⊑ Tokenize
  Compile ⇐ {
    t ← Build 𝕩
    t.Oper operator._with @
    t.Scope baseScope
    t.Eval program._with baseEnv
  }
}
•Out¨ ast.Compile preamble ∾ ∾ •FChars¨ •args
