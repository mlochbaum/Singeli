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
  _node_ ← {⟨𝕗, 𝔾_whileParse_⟨𝕗,Pos@⟩ 𝕩⟩}

  When  ← {Test‿Cont:       ( ⥊∘< Cont)⍟Test   ⟨⟩  }
  While ← {Test‿Cont‿init: {(𝕊∾⟜<⟜Cont)⍟Test𝕩} Cont¨↕init}
  _seq ← {≡¨⊸((≠⟜1∧(<sep)≢¨⊢)/>⟜0◶{𝕏@}‿Get¨) 𝔽}

  Name ← Get (⊑alph∊˜⊏)˙
  Word ← Get (⊑(wc∾oc)∊˜⊏)˙

  AddParams ← {𝕊∘(c.run  _node_ (<∾Params))⍟(Next"{") 𝕩}
  AddArgs   ← {  (c.call _node_ (<∾Args  ))⍟(Next"(") 𝕩}
  Expr0 ← {𝕤
    Vec ← c.run _node_ (⟨MakeVec˜⟩ ∾ "["‿Expr‿"]"‿Expr0 _seq)
    Par ← ⊑ "("‿Expr‿")" _seq
    ¬∘Is⟜"["◶⟨Vec, ¬∘Is⟜"("◶⟨Par,Word⟩⟩ Peek@
  }
  Callable ← AddParams∘Expr0
  Expr ← c.phrase _node_ {𝕤
    While ⟨¬Next∘(sep∾⥊¨",:=)}"), AddArgs∘Callable, 0⟩
  }

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

  Args ← {𝕤
    Get "("
    a ← While ⟨Try∘",", Expr, 1⟩
    Get ")"
    a
  }

  Statement ← {
  "if":     c.if     _node_ ("if"‿"("‿Expr‿")"‿Statement‿(When∘⟨Next∘"else",Statement⟩)_seq)@ ;
  "while":  c.while  _node_ ("while"‿"("‿Expr‿")"‿Statement _seq)@ ;
  "do":     c.do     _node_ ("do"‿Statement‿"while"‿"("‿Expr‿")"‿sep _seq)@ ;
  # TODO: make most of the for definition conditional
  "@":      c.for    _node_ ("@"‿Callable‿"("‿(While∘⟨Try∘",", Name, 1⟩)‿"over"‿Name‿"from"‿Expr‿"to"‿Expr‿")"‿Statement _seq)@ ;
  "return": c.return _node_ ("return"‿Expr _seq)@ ;
  "{":      Body@ ;
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
  Node ← {
    n←⊑𝕩 ⋄ d←0⍟(⟨3⟩⊸≡)1⍟(⟨2⟩⊸≡)1↓𝕩
    {
      (<n) ∾ "  "⊸∾¨∾ d⊣◶⟨≍○<⊢,RunNode,∾RunNode¨⟩¨𝕩
    }
  }
  run      ⇐ Node "run"      ‿0‿2‿2     # name params conds
  call     ⇐ Node "call"     ‿0‿2       # name args
  phrase   ⇐ Node "phrase"   ‿3         # things
  body     ⇐ Node "body"     ‿2         # statements
  funDecl  ⇐ Node "funDecl"  ‿0‿2‿2‿2‿1 # name params args type result
  arg      ⇐ Node "arg"      ‿0‿1       # name type
  decl     ⇐ Node "decl"     ‿1‿2‿1     # name type value
  define   ⇐ Node "define"   ‿1‿1       # target value
  export   ⇐ Node "export"   ‿0‿1       # name value
  program  ⇐ Node "program"  ‿2         # lines
  param    ⇐ Node "param"    ‿0‿2       # name equals
  paramList⇐ Node "paramList"‿2‿2       # params conds
  if       ⇐ Node "if"       ‿1‿1‿2     # cond then else
  while    ⇐ Node "while"    ‿1‿1       # cond stmt
  do       ⇐ Node "do"       ‿1‿1       # stmt cond
  return   ⇐ Node "return"   ‿1         # value
}

RunNode ← {𝕎𝕩}´⊢

MakeVec ← !

•Out ∾∾⟜lf¨ RunNode Parse ⊑Tokenize 1↓"
add{T}(a:*T, b:*T, r:*T, l:u64) : void = {
  i := 0u64;
  i = i+1;
}
def a=1+2
'abc'=fn{x,y}
"
