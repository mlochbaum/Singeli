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
    Vec ← c.run _node_ (⟨MakeVec˜⟩ ∾ "["‿Expr‿"]"‿Expr0 _seq)
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
  "while":  c.while  _node_ ("while"‿"("‿Expr‿")"‿Statement _seq)@ ;
  "do":     c.do     _node_ ("do"‿Statement‿"while"‿"("‿Expr‿")"‿sep _seq)@ ;
  # TODO: make most of the for definition conditional
  "@":      c.for    _node_ ("@"‿Callable‿"("‿(While∘⟨Try∘",", Name, 1⟩)‿"over"‿Name‿"from"‿Expr‿"to"‿Expr‿")"‿Statement _seq)@ ;
  "return": c.return _node_ ("return"‿Expr _seq)@ ;
  "{":      c.body   _node_ Body@ ;
  𝕩:
    n ← Expr@
    k ← Try ":"
    e ← Try "="
    t ← When ⟨k>e, {e↩Try"="⋄𝕩}∘Expr⟩
    c.decl _node_ {⟨𝕩,t,Expr@⟩}⍟e n
  }∘Peek

  Seps ← {Try∘sep◶@‿𝕊𝕩}
  Body ← {𝕤
    Get "{"
    While ⟨¬Try∘"}", Statement∘Seps, 0⟩
  }
  # 𝕩 indicates if preceding token was =
  Result ← c.body _node_ (Next∘"{"◶⟨Expr‿sep _seq !, Body⟩)

  Param ← c.param _node_ {𝕤
    n ← Name@
    e ← When ⟨Try"==", Expr⟩
    n‿e
  }
  Params ← {𝕤
    Get "{"
    a ← While ⟨Try∘",", Param, 1⟩
    c ← While ⟨Try∘"&", Expr, 0⟩
    Get "}"
    a‿c
  }

  FunDecl ← c.funDecl _node_ {𝕤
    n ← Name@
    p ← When ⟨Next"{", c.paramList _node_ Params⟩
    Get "("
    Arg ← c.arg _node_ (Name‿":"‿Expr _seq)
    a ← While ⟨Try∘",", Arg, 1⟩
    Get ")"
    r ← When ⟨Try":", Expr⟩
    b ← Result Try"="
    ⟨n,p,a,r,b⟩
  }

  Define ← c.define _node_ ("def"‿Expr‿"="‿(Result∘1) _seq)

  Symb ← '''=⊑
  Export ← c.export _node_ ((Get symb˙)‿"="‿Callable‿sep _seq)

  Program ← c.program _node_ {𝕤
    Line ← ¬∘Is⟜"def"◶⟨Define, Symb◶FunDecl‿Export⟩∘Peek
    While ⟨Rem, Line∘Seps, 0⟩
  }

  Program @
}

nodes ← {
  # Node operations
  o ← {
    Dump ⇐ {𝕩.Dump@}
    Disp ⇐ {𝕩.Disp@}
  }
  Defaults ← {
    node‿visit ⇐ 𝕩
    Dump⇐{𝕤⋄⟨node,Visit o.dump⟩}
    DispMemb ← <⊸∾⟜("  "⊸∾¨)  # Display node 𝕨 and members 𝕩
    Disp⇐{𝕤⋄node DispMemb ∾∾ @ ⥊∘<∘⊢⍟((2×≡)+≡⟜@)¨○Visit o.disp}
  }

  # Node types
  Word ⇐ {
    name⇐𝕩
    Visit←⟨⟩˙
    ⟨node,Dump⟩⇐Defaults "word"‿visit
    Disp⇐{𝕤⋄⟨name⟩}
  }
  Run ⇐ {
    ⟨caller,params⟩⇐𝕩
    Visit←{⟨𝕏caller,𝕏¨params⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "run"‿visit
  }
  Call ⇐ {
    ⟨caller,args⟩⇐𝕩
    Visit←{⟨𝕏caller,𝕏¨args⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "call"‿visit
  }
  Phrase ⇐ {
    things⇐𝕩
    Visit←{⟨𝕏¨things⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "phrase"‿visit
  }
  Body ⇐ {
    statements⇐𝕩
    Visit←{⟨𝕏¨statements⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "body"‿visit
  }
  FunDecl ⇐ {
    ⟨name,params,args,type,result⟩⇐𝕩
    Visit←{⟨name,𝕏¨params,𝕏¨args,𝕏¨type,𝕏result⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "funDecl"‿visit
  }
  Arg ⇐ {
    ⟨name,type⟩⇐𝕩
    Visit←{⟨name,𝕏type⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "arg"‿visit
  }
  Decl ⇐ {
    ⟨name,type,value⟩⇐𝕩
    Visit←{⟨𝕏name,𝕏¨type,𝕏value⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "decl"‿visit
  }
  Define ⇐ {
    ⟨target,value⟩⇐𝕩
    Visit←{⟨𝕏target,𝕏value⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "define"‿visit
  }
  Export ⇐ {
    ⟨name,value⟩⇐𝕩
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "export"‿visit
  }
  Program ⇐ {
    lines⇐𝕩
    Visit←{⟨𝕏¨lines⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "program"‿visit
  }
  Param ⇐ {
    ⟨name,equals⟩⇐𝕩
    Visit←{⟨name,𝕏¨equals⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "param"‿visit
  }
  ParamList ⇐ {
    ⟨params,conds⟩⇐𝕩
    Visit←{⟨𝕏¨params,𝕏¨conds⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "paramList"‿visit
  }
  If ⇐ {
    ⟨cond,then,else⟩⇐𝕩
    Visit←{⟨𝕏cond,𝕏then,𝕏¨else⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "if"‿visit
  }
  While ⇐ {
    ⟨cond,stmt⟩⇐𝕩
    Visit←{⟨𝕏cond,𝕏stmt⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "while"‿visit
  }
  Do ⇐ {
    ⟨stmt,cond⟩⇐𝕩
    Visit←{⟨𝕏stmt,𝕏cond⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "do"‿visit
  }
  Return ⇐ {
    ⟨value⟩⇐𝕩
    Visit←{⟨𝕏value⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "return"‿visit
  }
}

MakeVec ← !

ast ← Parse ⊑Tokenize •FChars "tests/test.singeli"
•Out ∾∾⟜lf¨ ast.Disp @
