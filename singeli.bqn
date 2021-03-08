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
  MakeStream ← {
    len←≠src←𝕩 ⋄ i←0
    Pos  ⇐ {𝕤⋄i}
    Inc  ← {𝕤⋄i+↩1}
    Rem  ⇐ {𝕤⋄(i+1)<len}
    Peek ⇐ {𝕤⋄i⊑src}
    Next ⇐ Peek⊸Is
    Get  ⇐ Inc ⊢ Peek⊸(⊣⊣≍○<Err⍟(¬⊢)Is)
    Try  ⇐ 1∘Inc⍟⊢∘Next
  }
  ⟨Next,Get,Peek,Try,Rem,Pos⟩ ← MakeStream 𝕩

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
  Generator ← ⟨"=",Result∘1⟩_seq _withParams
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

_and_ ← { 𝔽◶⟨0,𝔾⟩ }
IsNum ← 1=•Type
IsInt ← IsNum _and_ (⌊⊸=)
IsNat ← IsInt _and_ (0⊸≤)
Show ← {•Type◶⟨"tup{"∾"}"«·∾(","∾𝕊)¨, ⍕, !,!,!,!,!, {𝕩.Show@}⟩𝕩}

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

# Other types:
# Instruction result (type, index)
# Generator, encoded as function

CallFn ← !  # Check types; emit call instruction


builtins ← ∾≍⟨
  Show¨⊸≍ types.primTypes
  ⍉> ⟨"call"‿CallFn,⟨"vector",types.Vec⟩⟩
⟩

scopes ← {
  null←{Get⇐"Undefined name: "⊸∾!0˙}
  New⇐{
    n←⟨⟩ ⋄ PG←𝕩.Get
    Add⇐{ ("Duplicate definition: "∾𝕩)!¬∨´≡⟜𝕩¨n ⋄ c←≠n ⋄ n∾↩<𝕩 ⋄ c⊑env.Vars }
    Get⇐{ (n⊸⊐⌾<𝕩) =⟜(≠n)◶{𝕨⊑env.Vars}‿{(PG𝕩)∘env.Parent} 𝕩 }
    Names⇐{𝕤⋄n}
  }
  Init⇐New null˙
}
var ← {
  New⇐{𝕤⋄ v←@ ⋄ Get⇐{𝕤⋄v} ⋄ Set⇐{v↩𝕩} }
  Get⇐{𝕩.Get@}
  Set⇐{𝕨.Set𝕩}
}
env ← {
  Vars⇐{𝕩.vars}
  Parent⇐{𝕩.parent}
  New⇐{
    vars⇐MakeVar¨ 𝕨.Names@
    parent⇐𝕩
  }
}

nodes ← {
  # Node operations
  o ← {
    Dump ⇐ {𝕩.Dump@}
    Disp ⇐ {𝕩.Disp@}
    Scope⇐ {𝕊sc :{𝕩.Scope sc }}
    Eval ⇐ {𝕊env:{𝕩.Eval  env}}
  }
  Defaults ← {
    node‿visit ⇐ 𝕩
    Dump ⇐{𝕤⋄⟨node,Visit o.dump⟩}
    Disp ⇐{𝕤⋄node <⊸∾ "  "⊸∾¨ ∾∾ @ ⥊∘<∘⊢⍟((2×≡)+≡⟜@)¨○Visit o.disp}
    Scope⇐{𝕤⋄Visit o.Scope 𝕩⋄@}
    Eval ⇐{𝕤⋄Visit o.eval⋄@}
  }

  # Node types
  Ident ← {
    name⇐𝕩
    ⟨node,Dump⟩⇐Defaults "ident"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
    Eval⇐!∘0 ⋄ Scope⇐{Eval↩var.Get∘(𝕩.Get name)}
  }
  Value ← {
    name⇐𝕨
    eval⇐𝕩
    ⟨node,Dump,Scope⟩⇐Defaults "value"‿⟨⟩
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
    Eval ⇐ {𝕎𝕩}´ d.Eval
  }
  Call ⇐ Run (Word"call") ≍○< <⊸∾´
  Phrase ⇐ {
    things⇐𝕩
    Visit←{⟨𝕏¨things⟩}
    ⟨node,Dump,Disp,Scope⟩⇐d←Defaults "phrase"‿visit
    Eval⇐("TODO: operator parsing"!0˙)´d.Eval
  }
  Function ⇐ {
    ⟨args,type,result⟩⇐𝕩
    Visit←{⟨𝕏¨args,𝕏¨type,𝕏result⟩}
    ⟨node,Dump,Disp,Scope⟩⇐Defaults "function"‿visit
  }
  ParamEq ← Run (Word"match"){⟨𝕗,𝕨‿𝕩⟩}
  Lambda ⇐ {
    ⟨⟨params,conds⟩,value⟩⇐𝕩
    conds∾˜↩∾<⊸(Word⊸ParamEq¨)´¨params
    params↩⊑¨params
    Visit←{params∾⟨𝕏¨conds,𝕏value⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "lambda"‿visit
    Scope⇐{
      𝕩.Add¨ params
      Visit o.Scope 𝕩
    }
  }
  Arg ⇐ {
    ⟨name,type⟩⇐𝕩
    Visit←{⟨name,𝕏type⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "arg"‿visit
    Set←!∘0 ⋄ Scope⇐{ Set ↩ (𝕩.Add name)⊸var.Set }
  }
  Assign ⇐ {
    ⟨name,decl,type,value⟩⇐𝕩
    name {n←⊑t←𝕩.things ⋄ !1=≠t ⋄ !"ident"≡n.node ⋄ n.name}˜↩@
    Visit←{⟨name∾decl/":",𝕏¨type,𝕏value⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "assign"‿visit
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
    scoped←"lambda"‿"function"(∨´≡¨)<value.node
    ⟨node,Dump,Disp⟩⇐Defaults "define"‿visit
    Set←!∘0 ⋄ sc←@ ⋄ Scope⇐{
      Set ↩ (𝕩.Add name)⊸var.Set
      value.Scope sc ↩ scopes.New⍟scoped 𝕩
    }
    Eval⇐{
      𝕩 Set value.Eval sc env.New⍟scoped 𝕩
    }
  }
  Export ⇐ {
    ⟨name,value⟩⇐𝕩
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp,Scope⟩⇐Defaults "export"‿visit
    Eval⇐"TODO:exports"!0˙
  }
  Body ⇐ {
    statements⇐𝕩
    Visit←{⟨𝕏¨statements⟩}
    ⟨node,Dump,Disp,Scope⟩⇐d←Defaults "body"‿visit
    Eval⇐¯1⊑d.Eval
  }
  If ⇐ {
    ⟨cond,then,else⟩⇐𝕩
    Visit←{⟨𝕏cond,𝕏then,𝕏¨else⟩}
    ⟨node,Dump,Disp,Scope⟩⇐Defaults "if"‿visit
    Eval ⇐ {𝕤
      c ← cond.Eval@
      lf ← Label@
      c GotoF lf
      then.Eval@
      Goto¨ lt ← Label¨ else
      SetLabel lf
      { 𝕩.Eval@ ⋄ SetLabel lt }¨ else
    }
  }
  While ⇐ {
    ⟨testFirst,cond,stmt⟩⇐𝕩
    Visit←{⟨𝕏cond,𝕏stmt⟩}
    ⟨node,Dump,Disp,Scope⟩⇐Defaults "while"‿visit
    Eval ⇐ {𝕤
      Goto¨ lc ← Label¨↕testFirst
      SetLabel lt ← Label@
      stmt.Eval@
      SetLabel¨ lc
      (cond.Eval@) Goto lt
    }
  }
  Return ⇐ {
    ⟨value⟩⇐𝕩
    Visit←{⟨𝕏value⟩}
    ⟨node,Dump,Disp,Scope⟩⇐Defaults "return"‿visit
    Eval ⇐ {𝕤
      r←o.Eval value
      # ! r IsOfType fntype
      Emit "ret"‿r
    }
  }
}

ast ← Parse ⊑Tokenize •FChars "tests/test.singeli"
•Out ∾∾⟜lf¨ ast.Disp @
