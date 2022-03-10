tab‿lf←@+9‿10

dig ← '0'+↕10
alph← "_"∾⥊"aA"+⌜↕26
wc  ← dig∾alph∾"."       # Word characters
oc  ← "!$%&*+-/<=>?\^|~" # Operator characters that can stick together

# Source to list of token strings
Tokenize←{
  𝕩∾↩lf(≠⥊⊣)¯1↑𝕩                            # Trailing newline
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
  bt←(⌈`↕∘≠×¬)k ⋄ xd←𝕩∊dig
  k∨↩»⊸∨(»(bt⊏xd)∧𝕩='e')∧(𝕩='-')∧«xd        # Negative exponents 12e-3
  ts←n∨¬k∨ign                               # Token start mask
  lc←(1+/𝕩=lf){(⊢⋈¨𝕩-⊏⟜(0∾𝕨))𝕨⍋𝕩}/ts        # Line/column numbers
  ⟨𝕩⊔˜1-˜(ign>≠`ab∧s∨d)¬⊸×+`ts, Source 𝕩‿lc⟩
}

# Position handler for error reporting
Source ← {
  src‿lc←𝕩
  { pos 𝕊 disp:
    r‿c←<˘⍉>pos⊏lc
    •Out src/˜(src=lf)(⊣<+`⊸=)e←¯1⊑r
    Tr ← {
      e ← (+`(𝕩≤¯1»𝕨≠⊸+¨𝕩))⊔𝕩⋈¨𝕨
      l ← "^"⌾(1⊑¯1⊑⊑) ⌽ "|"⌾(1⊸⊑)¨⊸∾` (1+≠e)↑e
      {∾((-⟜»𝕨)∾≠¯1⊑𝕩)↑¨""<⊸∾𝕩}˝∘⍉∘>¨ l
    }
    •Out¨ disp Tr○((r=e)⊸/) c
  }
}
DispSource ← {𝕎𝕩}´
Err ← { (𝕩≠⊸⥊•Out‿DispSource) {𝕎𝕩}¨ 𝕩 ⋄ •Exit 1 }

numbers ← {kname⇐"number"
  f ← •Import "float2.bqn"
  NN ← 1≠•Type  # Not native number
  Is ← kname≡{Kind𝕩}
  Wrap ← {kind⇐kname⋄value⇐𝕩⋄Matches⇐Match⋄Shows⇐FmtLarge∘𝕩}
  Unwrap ← {6=•Type𝕩?kname≡𝕩.kind?𝕩.value; !"Expected number"}
  Promote ← NN◶f.To‿Unwrap
  From ⇐ f.From∘Unwrap⍟NN
  GetBool ⇐ {"Boolean expected"!⊑𝕩∊0‿1⋄𝕩}∘From
  Match ⇐ ∧○Is◶⟨0,≡○Promote⟩

  _be ← {𝕗⊸×⊸+˜´⌽∘⊢}
  Nat ← (10 _be ⊣ "Ill-formed number"!·∧´0⊸≤∧≤⟜9) -⟜'0'
  LC ← +⟜(32×1="A["⊸⍋) '_'⊸≠⊸/  # Lowercase, underscores removed
  da ← dig∾'a'+↕26
  Read ⇐ {
    (≠𝕩)>s←⌊´𝕩⊐"bx" ? # Base n with 0x9abc or 31bNUMBER
      b ← ('b'=s⊑𝕩)◶⟨16⊣·!"0"⊸≡,Nat⟩ s↑𝕩
      "Invalid base" ! b≤≠da
      d ← (b↑da) (≠∘⊣(⊢⊣"Invalid digits"!∧´∘>)⊐) (1+s)↓𝕩
      E←b _be ⋄ EE←{h‿l←f.To∘E¨𝕨-⊸(↓⋈↑)𝕩⋄Wrap l f.Add (f.To b⋆𝕨)f.Mul h}
      (⌊53÷2⋆⁼b) <⟜≠◶E‿EE d
    ;
      _n ← {('-'=⊑)◶⟨𝔽, -∘𝔽 1⊸↓⟩}
      Pos ← ⊐⟜"."⊸(Nat∘↑ + ·(0<≠)◶⟨0,Nat÷10⋆≠⟩+⟜1⊸↓)
      ⊐⟜"e"⊸(Pos _n∘↑ × <⟜≠◶⟨1,10⋆·Nat _n+⟜1⊸↓⟩) 𝕩
  }⟜LC⎊{Err⟨•CurrentError@,𝕨⟩}

  InRange ← {1=⊑0⍋˜-˜´⟜(⌽𝕨)¨𝕩}
  FmtLarge ← {
    ⌊⊸≡𝕩 ? (f.Abs 𝕩) InRange 2⋆53‿64 ? "0x"∾da⊏˜⌽ 16‿16 f._repr 𝕩 ;
    FmtNum f.From 𝕩
  }

  Cast ⇐ {'f'‿l𝕊n:1; q‿l𝕊n: # 1 if valid; error otherwise
    n NN◶⋈‿Unwrap↩
    "Cannot cast float to integer"!⌊⊸≡n
    "Constant doesn't fit"!n InRange -⟜(1⊸⊑÷2˙)⍟(q='i') ⟨0,2⋆l⟩
  }
  builtins ⇐ {
    W←Wrap ⋄ P←Promote ⋄ B←GetBool
    E←f.To 2⋆From
    pr‿val ← <˘⍉∘‿2⥊ ⟨
      {𝕏⊑}     ,⟨"neg",NN◶⟨-,W∘f.Neg○Unwrap⟩⟩‿⟨"not",¬∘B⟩
      {W∘𝕏○P}  ,⟨"add"‿f.Add, "sub"‿f.Sub, "mul"‿f.Mul, "div"‿f.Div⟩
      {W P⊸𝕏⟜E},⟨"shl", f.Mul⟩‿⟨"shr", f.Floor f.Div⟩
      {𝕏○B}    ,⟨ "and"‿∧, "or"‿∨, "xor"‿≠ ⟩
    ⟩
    ⍉>∾ ({{𝕏´}∘𝕏}¨⌾(1⊸↓) {𝕏⚇0}¨ pr) {⟨"__"⊸∾,𝕎⟩⊸({𝕎𝕩}¨)¨𝕩}¨ val
  }
  _cmp ⇐ {(f.Cmp 𝔽 0˙)○Promote}
}

architectures ← {
  # 𝕩 is a list of extension dependency chains.
  New ⇐ {
    TSort ← {{𝕊⍟(𝕩<○≠⊢)⟜(𝕩∾·/𝕨⊸<)𝕨∨∧´∘⊏⟜𝕨¨p}⟜/0¨p←𝕩} # Topological sort
    u ← ⍷∾𝕩
    u ⊏˜↩ TSort ∾¨ (⊢⊔○∾(¯1↓↑)¨) (<u)⊐¨𝕩
    m ← ∨˝∘∧⎉1‿∞˜⍟(⌈2⋆⁼≠) (≥⌜˜↕∘≠)⊸×∨´×⌜˜¨(<u)∊¨𝕩    # Dependency matrix
    Id ← u⊸⊐
    Set ⇐ {
      mask ⇐ ({𝕩.mask}𝕨) ∨˝ (Id 𝕩) ⊏ m
      Has ⇐ mask ⊑˜ Id⌾<
    }
  }
  x86 ⇐ New ((⊢-˜+`×¬)' '⊸=)⊸⊔¨ •file.Lines "data/x86_ext.txt"
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
  Rem  ⇐ {𝕤⋄i<len}
  Peek ⇐ {𝕤⋄i⊑src}
  Next ⇐ Inc ⊢ Peek
}

Parse ← {𝕊 tokens‿ShowTrace:
  # Three kinds of token tests, distinguished by depth.
  Is ← ≡∘⊢◶⟨
    {𝕏𝕨}   # 0 Function to apply
    ≡      # 1 Token
    ⊑<⊸∊   # 2 List of tokens
  ⟩
  sep ← ⟨";", ⥊lf⟩

  ! (¯1⊑tokens) Is sep

  Asrt ← {𝕨𝕊1:@;
    l←{𝕨⊸⊐⊏𝕩˙}˝⍉∘‿2⥊⟨c.arg,"arg",c.assign,"assign",c.body,"body",c.call,"call",c.define,"define",c.export,"export",c.for,"for",c.function,"function",c.if,"if",c.lambda,"lambda",c.opdef,"opdef",c.phrase,"phrase",c.run,"run",c.while,"while",c.word,"word"⟩
    ShowTrace⟜L´ <˘⍉>DumpStack@
    •Out ""
    F ← (⥊lf)⊸≡◶•Repr‿"end of line"
    •Out {∾"Expected "‿𝕨‿" but saw "‿𝕩}⟜F´⍟(1<≡) 𝕨
    •Exit 1
  }
  MakeTokStream ← {
    ⟨Inc⇐Next⟩←Pos‿Rem‿Peek⇐MakeStream 𝕩
    Peek ↩ Peek ⊣ "File ended unexpectedly" Asrt Rem
    Next ⇐ Peek⊸Is
    Get  ⇐ Inc ⊢ {𝕩 (⊢ ⊣ (𝕨•Repr⊘⊣⊢)⊸⋈ Asrt Is˜) Peek@}
    Try  ⇐ 1∘Inc⍟⊢∘Next
  }
  ⟨Next,Get,Peek,Try,Rem,Pos⟩ ← MakeTokStream tokens

  # Node creation and error tracking
  c ← nodes
  ⟨_whileParse_⇐_while_, DumpStack⇐Arr⟩ ← MakeStack@
  _node_ ← {p←Pos@ ⋄ (ShowTrace○⋈⟜""⊢)‿p 𝔽 𝔾_whileParse_⟨p,𝕗⟩ 𝕩}

  When  ← {Test‿Cont:       ( ⥊∘< Cont)⍟Test   ⟨⟩  }
  While ← {Test‿Cont‿init: {(𝕊∾⟜<⟜Cont)⍟Test𝕩} Cont¨↕init}
  _seq ← {≡¨⊸((≠⟜1∧(<sep)≢¨⊢)/>⟜0◶{𝕏@}‿(Get⊢)¨) 𝔽}

  _begin_ ← {𝕘 Get (⊑∘𝔽⊑)˙}
  _ifASCII ← {(@+128)⊸≤◶𝔽‿1}
  Name ← ∊⟜alph _begin_ "name"
  Oper ← ∊⟜oc _ifASCII _begin_ "operator"
  Word ← c.word _node_ (∊⟜(wc∾oc)_ifASCII _begin_ "word")
  Symbol ← c.symbol _node_ ('''⊸=_begin_"symbol")

  AddParams ← {𝕊∘(c.run  _node_ (⊢⋈"{"‿"}"_args))⍟(Next"{") 𝕩}
  AddArgs   ← {  (c.call _node_ (⊢⋈"("‿")"_args))⍟(Next"(") 𝕩}
  Expr0 ← {𝕤
    Vec ← c.run _node_ ((c.Word"__vec") ⋈ "["‿Expr‿"]"‿Expr0 _seq)
    Par ← ⊑ "("‿Stmt‿")" _seq
    ARes← c.body _node_ (Next∘"{"◶⟨⋈Expr, Body⟩)
    Anon← c.lambda _node_ (Params‿"=>"‿ARes _seq)
    (⊑"[({'"⊐⊏)◶Vec‿Par‿Anon‿Symbol‿Word Peek@
  }
  Callable ← AddParams∘Expr0
  _exprEnd ← {endTok _𝕣:
    end ← endTok∾sep∾⥊¨",:=)}]"
    Call ← { Op←∨´(oc∾"[")=⊏ ⋄ c←¬Next op ⋄ AddArgs⍟c Callable𝕩 }
    c.phrase _node_ (While∘⟨¬Next∘end, Call, 0⟩)
  }
  Expr ← ⟨⟩_exprEnd

  _args ← {𝕗 _argsFn_ Expr}
  _argsFn_ ← {𝕤
    Get ⊑𝕗
    Try 1⊑𝕗 ? ⟨⟩ ;
    a ← While ⟨Try∘",", 𝔾, 1⟩
    Get 1⊑𝕗
    a
  }

  StSub ← {
  "def":    Define@ ;
  "if":     c.if     _node_ ("if"‿"("‿Expr‿")"‿Block‿(When∘⟨Try∘"else"∘Seps,Block⟩)_seq)@ ;
  "while":  c.while  _node_ (1 ∾   "while"‿"("‿Expr‿")"‿Block _seq)@ ;
  "do":     c.while  _node_ (0 ∾⟜⌽ "do"‿Block‿"while"‿"("‿Expr‿")"‿sep _seq)@ ;
  "@":      For@ ;
  𝕩:
    n ← Expr@
    d ← Try ":"
    e ← Try "="
    t ← When ⟨d>e, {e↩Try"="⋄𝕩}∘Expr⟩
    c.assign _node_ {⟨𝕩,d,t,Expr@⟩}⍟e n
  }
  Stmt ← StSub Peek

  Seps ← {Try∘sep◶@‿𝕊⍟Rem𝕩}
  Body ← {𝕤
    Get "{"
    b ← While ⟨¬Try∘"}"∘Seps, Stmt, 0⟩
    "Empty body" Asrt 0<≠b
    b
  }
  Block ← "{"⊸≡◶⟨StSub, c.body _node_ Body⟩ Peek

  For ← c.for _node_ {𝕤
    OA← "@for: multiple variables must use ""over"""⊸Asrt
    TA← "@for: ""from"" missing ""to"""⊸Asrt
    NA← "@for: loop variable must be a name"⊸Asrt
    Expr ← "over"‿"from"‿"to"_exprEnd # Shadow
    Get "@"
    f ← Callable@
    Get "("
    to← Expr@ ⋄ NE←{𝕤⋄ NA@≢n←c.PhraseTryName to ⋄ to↩Expr@ ⋄ n}
    pe← While ⟨Try∘",", Name, 0⟩
    ps← pe ⊢◶{OA 0=≠𝕨⋄⟨⟩}‿{(<NE@)∾𝕨} Try"over" # Pointers
    fr← When ⟨Try"from", Expr⟩                 # Start index
    i ← ⊢◶{𝕤⋄TA 0=≠fr⋄⟨⟩}‿{𝕤⋄⟨NE@⟩} Try"to"    # Index variable
    Get ")"
    b ← Block@
    ⟨f,ps,i,fr,to,b⟩
  }

  # 𝕩 indicates if preceding token was =
  Result ← c.body _node_ (("{"‿"@"⊸⊐⌾<Peek)◶⟨
    Body
    ⋈For
    Expr‿sep _seq "Missing = before body?"Asrt⊢
  ⟩)

  Params ← {𝕤
    ExprA ← ⟨"&"⟩_exprEnd
    Param ← {𝕤
      n ← Name@
      e ← When ⟨     Try "==", ExprA⟩
      t ← When ⟨(≠e)◶Try‿0":", ExprA⟩
      n‿e‿t
    }
    Get "{"
    a ← While ⟨Try∘",", Param, 1⟩
    c ← While ⟨Try∘"&", ExprA, 0⟩
    Get "}"
    a‿c
  }
  _withParams ← {𝕤
    (Next"{")◶⟨𝔽, c.lambda _node_ (Params‿𝕊 _seq)⟩@
  }

  Function ← c.function _node_ {𝕤
    Arg ← c.arg _node_ (Name‿":"‿Expr _seq)
    a ← "("‿")" _argsFn_ Arg @
    r ← When ⟨Try":", Expr⟩
    b ← Result Try"="
    ⟨a,r,b⟩
  } _withParams
  Const ← {𝕤
    t ← When ⟨Try":", Expr⟩
    Get "="
    c.run _node_ ((c.Word"cast") ⋈ t∾<)⍟(0<≠t) Expr@
  }
  FunConst ← (Next∘"("‿"{"◶Const‿Function)
  Generator ← {𝕤⋄ Get"=" ⋄ Result 1} _withParams
  DefFun ← c.define _node_ (      Name‿FunConst  _seq)
  Define ← c.define _node_ ("def"‿Name‿Generator _seq)

  Export ← c.export _node_ ((While∘⟨Try∘",",Symbol,1⟩)‿"="‿Callable‿sep _seq)

  OpType ← {𝕤
    pre ← (⊑≢Get) "prefix"‿"infix"
    pre◶⟨'p', Next◶⟨'n', ⊑∘Get∘1⟩⟩ "none"‿"left"‿"right"
  }
  OpDef ← c.opDef _node_ ("oper"‿OpType‿Oper‿Name‿Word _seq)

  Include ← c.include _node_ ("include"‿Symbol _seq)

  Program ← c.body _node_ {𝕤
    Line ← "def"‿"oper"‿"include"⊸⊐⌾<◶⟨
      Define, OpDef, Include, ('''=⊑)◶DefFun‿Export
    ⟩∘Peek
    Seps@
    While ⟨Rem, Seps⊢Line, 0⟩
  }

  Program @
}

operator ← {
  Parse ⇐ {ops 𝕊 val:
    Peek‿Next‿Rem ← MakeStream ops {null‿left‿bind‿R⇐𝕨 ⋄ value⇐𝕩}¨ val
    E ← {𝕊test: {𝕊∘{𝕩 LeD Next@}⍟(Test Peek)⍟Rem 𝕩} NuD Rem◶Mis‿Next@ }
    NuD ← { 𝕩.null ≢⟜@◶{𝕩.value}‿{𝕩 Run ⟨𝕩.R 𝕨.V@, ⟨E 𝕨.t⟩⟩} 𝕩 }
    LeD ← { Unk⍟(@≡l←𝕩.left)𝕩 ⋄ 𝕩 Run ⟨𝕩.R l.V@, ⟨𝕨, E l.t⟩⟩ }
    Run ← {𝕩.value.pos}⊸nodes.Run
    Unk ← { Err "Unknown operator"‿𝕩.value.pos }
    Mis ← {𝕊: Err "Missing right operand"‿(¯1⊑val).pos }
    E 1
  }
  New ← {𝕤
    null ⇐ left ⇐ @
    bind ⇐ ¯∞
    R ⇐ ⊢
    Op ← {𝕊val‿p‿c‿a:
      V ⇐ nodes.Word∘val
      T ⇐ (p C {𝕩.bind}){{⊣AC𝕏}⍟a𝕗}
    }
    AddNull ⇐ {𝕨𝕊⟨value, prec⟩: AddNull↩𝕨_dup
      null ↩ Op ⟨value, prec, <, 0⟩
    }
    AddLeft ⇐ {𝕨𝕊⟨value, prec, assoc⟩: AddLeft↩𝕨_dup
      bind ↩ prec
      left ↩ Op ⟨value, prec, ("lrn"⊸⊐⌾<assoc)⊑⟨<,≤,<-=⟩, 'n'=assoc⟩
    }
    _dup ← { Err "Duplicate operator definition:"‿𝕨‿"Previously defined here:"‿𝕗 }
    AC ← 𝕩{ Err ("Associativity for operator "∾𝕗∾" must be disambiguated")‿𝕨.value.pos }⍟(0⊸>)
  }
  Run ⇐ {𝕨𝕊⟨op,params⟩: null‿left‿bind⇐op ⋄ R⇐𝕨 nodes.Run op.R⋈params˙}
  nil ⇐ New @

  Lookup⇐Add⇐!∘0
  _with ⇐ {
    n←⟨⟩ ⋄ o←⟨⟩
    _get ← {(n⊸⊐⌾<𝕩) =⟜(≠n)◶{𝕨⊑o}‿𝔽 𝕩}
    Lookup ↩ nil _get
    Define ← {n∾↩<𝕩 ⋄ o∾↩<r←New𝕩 ⋄ r} _get
    Add ↩ {𝕨𝕊type‿name‿value‿prec:
      p ← Define name
      (type≠'p')◶⟨𝕨p.AddNull⊢, 𝕨p.AddLeft∾⟜type⟩ ⟨value,prec⟩
    }
    𝕨𝔽𝕩
    Lookup↩Add↩!∘0
  }
}


# Runtime
# Kinds are:
# - BQN values tuple (list), number, generator (function)
# - Classes symbols, types, registers, constants, functions, blocks
_and_ ← { 𝔽◶⟨0,𝔾⟩ }
IsNum ← 1=•Type
IsInt ← IsNum _and_ (⌊⊸=)
IsNat ← IsInt _and_ (0⊸≤)
IsTup ← 0=•Type
FmtNum ← '¯'(⊢+=×'-'-⊣)•Repr

_tsel ← {•Type∘⊣◶(¯1((↓»(6⥊⟨!⟩)˙)∾↑)𝕗)}
Kind  ← ⟨"tuple","number",@,"generator",{𝕩.kind}⟩_tsel
Show  ← {⟨"tup{"∾"}"«·∾(","∾𝕊)¨, FmtNum, {𝕩.Shows@}⟩_tsel 𝕩}
Match ← {𝕨 ⟨∧´𝕊¨, numbers.Match,≡,≡, {𝕨𝕨.Matches𝕩}⟩_tsel 𝕩}
IsTyped←("register"⊸≡∨"constant"⊸≡) Kind
TypeOf← {⟨types.Tup 𝕊¨, {𝕩.Type@}⟩_tsel 𝕩}

types ← {kname⇐"type"
  New ← {k𝕊d:
    kind⇐kname
    typeKind‿dat⇐𝕨‿𝕩
    T←"("∾")"«·∾(","∾Show)¨  # Display type tuple
    Shows⇐typeKind◶⟨
      "void"               # Void:                     void
      ∾⟜•Repr´             # Primitive:   qual‿len     u8
      {∾"["‿𝕨‿"]"‿𝕩}○Show´ # Vector:      count‿t      [4]…
      "*"∾Show             # Pointer:     t            *…
      T⊸{∾𝕨‿" -> "‿𝕩}⟜Show´# Function:    ⟨t, q‿r‿s⟩   (…,…,…) -> …
      T                    # Tuple:       q‿r‿s        (…,…,…)
    ⟩∘dat
    Matches⇐{𝕨MT𝕩}
  }
  tVOID‿tPRIM‿tVEC‿tPTR‿tFUN‿tTUP ← ↕6
  TypeKind⇐{
    "typekind argument must be type"!Is 𝕩
    𝕩.typeKind⊑"void"‿"primitive"‿"vector"‿"pointer"‿"function"‿"tuple"
  }
  IsVoid ⇐ {tVOID≡𝕩.typeKind}

  primTypes ⇐ (tVOID New ⟨⟩)∾∾(<(tPRIM New ⋈)¨´)˘ ∘‿2⥊⟨
    'u', 2⋆0∾3+↕4  # 1/8/16/32/64
    'i', 2⋆  3+↕4  #   8/16/32/64
    'f', 2⋆  5+↕2  #        32/64
  ⟩

  Is ⇐ kname≡Kind
  Vec ← {n𝕊t: "Vector size should be a constant integer"!IsNat n ⋄ !Is t ⋄ tVEC New ⟨n,t⟩}
  Ptr ← { 𝕊t: "Pointer type wasn't type"!Is t ⋄ tPTR New t}
  Tup ⇐ { 𝕊t: !IsTup t ⋄ !∧´Is¨ t ⋄ tTUP New t}
  Fun ⇐ tFUN New ⋈

  _isQual ← {{tPRIM≡𝕩.typeKind}◶⟨0,𝔽{⊑𝕩.dat}⟩ TypeOf⍟(¬Is)}

  Deref ⇐ { Is 𝕩 ? tPTR=𝕩.typeKind ? 𝕩.dat ; !"Expected pointer" }

  _cases ← {
    Kind←{𝕩.typeKind} ⋄ Dat←{𝕩.dat}
    c ← ⌊‿2⥊𝕗
    k ← ⊏˘c
    d ← (1⊏˘c) ∾ ((≠⥊c)↓𝕗)»⟨!∘0⟩
    (k⊸⊐⌾< ⊢⊘(≠◶⊢‿¯1)○Kind)◶({𝕏○Dat}¨d) ⊣ @○(!Is)
  }

  Size ← ⟨
    tPRIM, 1⊸⊑
    tVEC,  ×⟜{Size𝕩}´
    tTUP,  +´{Size𝕩}¨
  ⟩_cases

  VCount ← ⟨ tVEC,⊑, 1 ⟩ _cases
  VType ← ⟨ tVEC,1⊸⊑, tPTR,⊢ ⟩ _cases

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
      ⟨ tPRIM,numbers.Cast⟜n, !"Cannot cast number to "∾Show ⟩ _cases t
      t constants.New n
    }
    Obj←{
      "number"≡𝕩.kind ? 𝕨 Num 𝕩 ;
      "Cast failed" ! IsTyped◶⟨0,TypeOf MT 𝕨˙⟩ 𝕩
      𝕩
    }
    𝕨 ⟨⟨tTUP,⊢⟩_cases⊸(𝕊¨)˜, Num˜, Obj˜⟩_tsel˜ 𝕩
  }

  builtins ⇐ ∾˘⍉∘‿2⥊⟨
    ⟨"cast","eltype","vcount","width",          "__vec","__pnt"⟩
    ⟨ Cast´, VType⊑ , VCount⊑, Size⊑ ,numbers.From⊸Vec´,   Ptr⊑⟩
    "isfloat"‿"issigned"‿"isint"
    {𝕩_isQual⊑}¨⟨'f'⊸≡ ⋄ 'i'⊸≡ ⋄ ⊑∘∊⟜"iu"⟩
  ⟩
}

registers ← {kname⇐"register"
  New ⇐ {
    kind⇐kname ⋄ type⇐𝕨 ⋄ handle⇐𝕩
    shows⇐"v"∾•Repr𝕩 ⋄ Matches⇐≡
    used⇐0 ⋄ SetUsed⇐{𝕤⋄used↩1}
    mut⇐0  ⋄ SetMut ⇐{𝕤⋄mut ↩1}
  }
}
constants ← {kname⇐"constant"
  New ⇐ {
    kind⇐kname ⋄ type⇐𝕨 ⋄ value⇐𝕩
    shows⇐∾"!:"∾⟜Show¨𝕩‿𝕨 ⋄ Matches⇐≡
  }
}

NewLabel  ← { shows⇐"l"∾•Repr𝕩 }
symbols ← {kname⇐"symbol"
  M←(kname≡Kind∘⊢)_and_(≡○Show)
  New⇐{ kind⇐kname ⋄ shows⇐𝕩 ⋄ Matches⇐M }
}

functions ← {kname⇐"function"
  current⇐@
  New ← {𝕤
    kind⇐kname ⋄ shows⇐"f"∾•Repr id⇐𝕩 ⋄ Matches⇐≡ ⋄ type⇐@
    handle←¯1 ⋄ label←¯1 ⋄ args←⟨⟩ ⋄ rType⇐@
    Next⇐{ 𝕩 registers.New handle+↩1 }
    NextLabel⇐{𝕤⋄ NewLabel label+↩1 }
    NextArg⇐{ args∾↩𝕩 ⋄ Next 𝕩 }
    ⟨Push,Arr⟩←MakeStack@
    Instrs⇐Arr
    Append⇐{ Push𝕩⋄@ ; (1⊸⊑⊣𝕊) ⟨"new",Next𝕨⟩∾symbols.New⌾⊑𝕩 }
    SetRType⇐{
      SetRType↩!∘0 ⋄ !types.Is rType↩𝕩
      type ↩ args types.Fun rType
    }
    _ret_←{
      @≢rType? types.IsVoid rType? Append⍟𝕘 ⟨"ret",⊑types.primTypes⟩ ⋄@ ;
      Append ⟨"ret", rType ≢⟜@◶⟨𝔽∘⊢, types.Cast⟩ 𝕩⟩
    }
    Return⇐!∘"Early return from function with no explicit result type" _ret_ 1 @⊣´⊢
    Finish⇐{"Explicit result type needed"!IsTyped 𝕩⋄SetRtype TypeOf 𝕩⋄𝕩} _ret_ 0
    Prot⇐{𝕤⋄ 1↓∾" "⊸∾¨⟨shows,Show rType⟩∾(•Repr∘≠⊸∾Show¨args)}
  }
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
  Mut  ⇐ {
    "Can't assign to non-register" ! "register"≡Kind 𝕨
    Append "mut"‿𝕨‿𝕩
    𝕨.SetMut@
    𝕨
  }
  Call ⇐ {
    f ← ⊑𝕩
    ! "function"≡Kind f
    t ← f.rType
    t Append ⟨"call",t,f⟩ ∾ ≠⊸∾ 1↓𝕩
  }
  _instr ← { Append (𝕨𝔽𝕩)<⊸∾𝕨⋈𝕩 }
  SetLabel ⇐ "lbl"_instr
  Goto     ⇐ "goto"⊘"gotoT"_instr
  GotoF    ⇐ "gotoF"_instr
}

blocks ← {kname⇐"block"
  New ⇐ {𝕊 ind‿ptrs‿body‿ls‿e:
    kind⇐kname
    shows⇐"{block}" ⋄ Matches⇐≡
    Exec⇐{
      ! ptrs≡○≠1⊑𝕩
      r ← body.Eval be ← ⟨≠ind,ls,𝕩⟩ env.Block e
      be.Stores @
      r
    }
  }
  Exec ⇐ {𝕊 ind‿vars‿block:
    ! "block"≡Kind block
    block.Exec ind‿vars
  }
}
Load ← {  𝕊 ptr‿i: functions.Emit ⟨types.Deref TypeOf ptr, symbols.New "si_load", ptr, i⟩ }
Store← {v 𝕊 ptr‿i: functions.Emit ⟨types.Deref TypeOf ptr, symbols.New "si_store", ptr, i, v⟩ }


builtins ← {
  Kinds ← {
    E ← "Unhandled type" ! 0˙
    (e{k‿o←𝕨⋄∧○(k≡⊢)◶⟨𝕏,O˙⟩}´𝕩){o←𝕨𝔽○Kind𝕩⋄𝕨O𝕩}
  }
  Ty2 ← {𝕏⚇0´}∘Kinds "number"‿"type"⋈¨{𝕏numbers._cmp}⊸⋈
  Fmt ← 2↓·∾·", "⊸∾¨Show⎊("("∾")"∾˜Kind⎊"unknown")¨
  names‿values ⇐ <˘∾≍⟨
    Show¨⊸≍ types.primTypes
    ⍉> ⟨
      ⟨"show",(1≠≠)◶⊑‿{Shows⇐!∘"Multiple show used improperly"}⊣•Out∘Fmt⟩
      ⟨"call",functions.Call⟩, ⟨"emit",functions.Emit⟩,
      ⟨"return",functions.Return⟩, ⟨"exec",blocks.Exec⟩
      ⟨"match",Match´⟩
      ⟨"hastype",IsTyped∘⊑ _and_ ({𝕩.type}⊸Match´)⟩
      ⟨"type",TypeOf∘⊑⟩, ⟨"kind",symbols.New Kind∘⊑⟩
      ⟨"typekind",symbols.New types.TypeKind∘⊑⟩
      ⟨"load",Load⟩, ⟨"store",¯1⊸(⊑Store↓)⟩
      ⟨"tup",⊢⟩, ⟨"tupsel",numbers.From⊸⊑´⟩, ⟨"merge",∾⟩
      ⟨"bind",⊑{𝕎𝕩⊸∾}1⊸↓⟩, ⟨"apply",{𝕎𝕩}´⟩, ⟨"each",⊑{𝕎¨<˘⍉>𝕩}1⊸↓⟩
    ⟩
    numbers.builtins
    types.builtins
    >⟨
      "__eq"‿"__ne"‿"__lt"‿"__gt"‿"__le"‿"__ge"
      =‿≠‿<‿>‿≤‿≥ Ty2¨ ⟨Match,¬Match⟩ ∾ ·⥊≍˘⟜({𝕏˜}¨) ⟨types.SSubtype,types.Subtype⟩
    ⟩
  ⟩
}

var ← {
  Get⇐{𝕩.Get@}
  SetType⇐{𝕨.SetType𝕩}
  Fixed⇐{ Get⇐𝕩˙ }
  New⇐{
    v←𝕩 ⋄ Get⇐{𝕤⋄v} ⋄ Set⇐{v↩𝕩}
    SetType⇐{SetType↩!∘0
      C ← functions.Copy 𝕩⋈⊢
      G ← ("register"≡Kind∘⊢)◶⟨ C , {𝕩.SetUsed@⋄𝕩} C⍟{𝕩.used} ⟩
      Set↩Set ·G 𝕩⊸types.Cast
    }
  }
}
scopes ← {
  noLambda ← var.Fixed {!∘"Unhandled case"}
  null←{Get⇐{Err⟨"Undefined name: "∾𝕩,𝕨⟩} ⋄ GetLam⇐noLambda˙}
  New⇐{
    p←@¨n←𝕨⊣⟨⟩ ⋄ Names⇐{𝕤⋄n}
    Sel ←{𝕩⊑env.Vars}
    Make←{c←≠n⋄p‿n∾⟜<¨↩𝕩⋄c}
    Dup ←{Err⟨"Duplicate definition: ",⊑𝕩,"Previously defined here: ",𝕨⊑p⟩}
    Par ←{𝕏∘env.Parent}
    _find ← { (n⊸⊐⌾<𝕩) =⟜(≠n)◶𝕗 𝕨‿𝕩 }
    Get ⇐ ⟨Sel⊣, Par 𝕩.Get´∘⊢⟩ _find
    Add ⇐ Sel Dup‿Make _find
    Lam ← Par⍟(noLambda⊸≢) 𝕩.GetLam´∘⊢
    AddLam ⇐ ⟨⋈˜Sel∘⊣, Lam⋈Sel∘Make⟩ _find
    GetLam ⇐ ⟨Sel⊣, Lam⟩ _find
  }
  Init⇐New null˙

  queue ← ⟨⟩
  _defer ⇐ { queue∾↩<𝔽‿𝕩 }
  _run ⇐ {
    𝔽 _defer 𝕩
    _while_ ← {𝔽⍟𝔾∘𝔽_𝕣_𝔾∘𝔽⍟𝔾𝕩}
    {𝕊:d←⊑queue⋄queue↓˜↩1⋄{𝕎𝕩}´d}_while_{𝕊:0<≠queue} @
  }
}
env ← {
  Vars  ⇐{𝕩.vars}
  Parent⇐{𝕩.parent}
  Make ←{ vars⇐𝕨 ⋄ parent⇐𝕩 }
  New  ⇐{ (var.New∘@¨ 𝕨) Make 𝕩 }
  Fixed⇐{ (var.Fixed¨ 𝕨) Make 𝕩 }
  Block⇐{⟨ni,Load‿Store,ind‿ptrs⟩ 𝕊 par:
    pi ← ptrs ⋈¨ <ind
    pv ← Load¨ pi
    vars‿parent ⇐ (var.Fixed¨(ind¨↕ni)∾pv) Make par
    Stores ⇐ {𝕤
      m←{(𝕩.Get@).mut}¨v←ni↓vars
      v var.Get⊸(Store∾⟜<˜)¨○(m⊸/) pi
    }
  }
}

program ← {
  AddFunction⇐Export⇐!∘0 ⋄ trace⇐@
  _with ⇐ {
    fns←⟨⟩ ⋄ AddFunction ↩ { f ← 𝕏 ≠fns ⋄ fns∾⟜<↩f ⋄ f }
    exp←⟨⟩ ⋄ Export ↩ { "Exporting non-function" ! "function"≡Kind 𝕩 ⋄ exp ∾⟜<↩ 𝕨‿𝕩 }
    ⟨_trace_⟩↩s←Stack@
    𝕨 𝔽⎊s.Report 𝕩
    AddFunction↩Export↩!∘0
    ∾ ⟨∾DispFunction¨fns, DispExport¨exp⟩
  }
  Stack ← {𝕤
    ⟨_trace_⇐_while_⟩ ⇐ ⟨Dump⇐Arr⟩ ← MakeStack@
    Report ⇐ {𝕤
      •Out (∧`lf⊸≠)⊸/⎊•Repr •CurrentError@
      •Out ""
      # DispSource¨ ⌽ Dump@
      # ^ would be the easy way, but we want to compress repeats
      l ← ≠s ← Dump@
      n ← (↕l)-˜ l⊸=⊸+ ⍷⊸(⊣≠⊸↓⊢⊒∾)⊐s  # Distance to next repetition
      n ⊏˜↩ i ← /»⊸≠n                 # Split into blocks of equal distance
      e ← n+l«i                       # Last possible endpoint
      Sc ← {𝕨𝕊n‿i‿e:e-n|⍟(+˜⊸≤)e-𝕨⌈i} # Full reps (if ≥2) not overlapping previous
      i ⌈↩» e ↩ 0 Sc` <˘⍉>⟨n,i,e⟩     # Adjust start and end
      i‿n‿e (i<e)⊸/¨↩                 # Filter out empties
      f ← i+n                         # End of displayed reps
      df ← {DispSource 𝕩˙}¨ s
      rt ← (1<n) ("Repeated "∾•Repr∘⊢∾" times:"∾/⟜" {{{")¨ (e-i)÷n
      df rt⊸({𝕏⊣·•Out𝕨˙}¨)⌾((f-1)⊸⊏)↩
      df {•Out∘("}}}"∾@+10)⊢𝕏}¨⌾((i/˜1<n)⊸⊏)↩
      {𝕏@}¨ ⌽ df /˜ 1≠`e≠○(l↑/⁼)f     # Remove extra iterations
      •Exit 1
    }
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
    name⇐𝕩 ⋄ pos⇐𝕨⊣@
    ⟨node,Dump⟩⇐Defaults "ident"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
    Oper⇐{𝕤⋄operator.Lookup name}
    Eval⇐!∘0 ⋄ Scope⇐{Eval↩var.Get∘(pos 𝕩.Get name)}
  }
  _value ← {
    name←𝕩
    Eval⇐(𝕨𝔽𝕩)˙
    ⟨node,Dump,Oper,Scope⟩⇐Defaults "value"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
  }
  Word ⇐ (⊑⊏∘⊢∊dig˙)◶⟨Ident, numbers.Read _value⟩
  Symbol ⇐ (symbols.New 1↓¯1↓⊢)_value
  Run ⇐ {
    ⟨caller,params⟩←𝕩 ⋄ pos⇐𝕨
    Visit←{⟨𝕏caller,𝕏¨params⟩}
    ⟨node,Dump,Disp,Scope⟩⇐d←Defaults "run"‿visit
    Oper ⇐ {𝕤⋄ pos operator.Run ⟨⊑Visit o.oper,params⟩}
    Eval ⇐ {𝕎 program._trace_ pos 𝕩}´ d.Eval
  }
  Call ⇐ { 𝕨 Run ⟨Ident"call" , <⊸∾´𝕩⟩ }
  Phrase ⇐ {
    things←𝕩
    ToName⇐{𝕤⋄ (1=≠)◶@‿(("ident"≡{𝕩.node})◶@‿{𝕩.name}⊑) things }
    Visit←{⟨𝕏¨things⟩}
    ⟨node,Dump,Disp,Scope,Eval⟩⇐Defaults "phrase"‿visit
    Oper⇐{𝕤
      n ← o.Oper¨⊸operator.Parse things
      Scope↩{𝕨n.Scope𝕩} ⋄ Eval↩{𝕨n.Eval𝕩} ⋄ Disp↩{𝕨n.Disp𝕩}
      operator.nil
    }
  }
  PhraseTryName ⇐ {"phrase"≡𝕩.node}◶@‿{𝕩.ToName@}
  PhraseToName ⇐ @ (⊢⊣!∘≢) PhraseTryName
  notTypeVar ← types.primTypes≠⊸↑builtins.names
  Lambda ⇐ {
    ⟨⟨paramsPlus,conds⟩,result⟩←𝕩 ⋄ pos←𝕨
    params‿pmatch‿ptype ← <˘⍉>paramsPlus
    tname ← (¬∘∊⟜(⟨@⟩∾notTypeVar)⊸/ PhraseTryName¨)¨ ptype
    uTyp‿iTyp←(⍷∘∾ ⋈ ⊐∘∾⊔·/≠¨)tname
    _pc ← {n←𝕨⋄f←𝕗 ⋄ {pos Run ⟨Ident f,⟨Ident n,𝕩⟩⟩}¨𝕩}
    conds∾˜↩∾(params "hastype"_pc¨ tname≠⊸↓¨ptype)∾(params "match"_pc¨ pmatch)
    uPar‿iPar←(⍷⋈⊐)params
    Visit←{((iPar⊏uPar)∾⟜(∾""<⊸∾":"⊸∾¨)¨tname)∾⟨𝕏¨conds,𝕏result⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "lambda"‿visit
    Scope⇐{ Visit scopes._defer o.Scope (uPar∾uTyp) scopes.New 𝕩 }
    Eval⇐{𝕨 𝕊 e: # 𝕨 is previous value
      next ← ({𝕩.Get@}𝕨)⊣{"No matching generator definition"!0˙}
      AllEq ← ∧´⊏Match¨1⊸↓
      Check ← {iPar (≡○≢)_and_(∧´AllEq¨∘⊔) 𝕩}
      CT ← {∧´((∧´IsTyped¨)_and_(AllEq{𝕩.type}¨)⊏⟜𝕩)¨iTyp}
      Check _and_ CT◶Next‿{
        F←Next 𝕩˙
        try ← result.eval{numbers.GetBool∘𝕨.Eval◶F‿𝕏}´conds
        Try ((iPar∊⊸/𝕩)∾{𝕩.type}¨iTyp⊑¨⊸⊏𝕩) env.Fixed e
      }
    }
  }
  Arg ⇐ {
    ⟨name,type⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨name,𝕏type⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "arg"‿visit
    v←@ ⋄ Scope⇐{ type.Scope 𝕩 ⋄ v ↩ pos 𝕩.Add name }
    Eval⇐{ u←V𝕩 ⋄ u.SetType t←type.Eval 𝕩 ⋄ u.Set functions.NextArg t }
  }
  Function ⇐ {
    ⟨args,type,result⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏¨args,𝕏¨type,𝕏result⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "function"‿visit
    Scope⇐{ Visit scopes._defer o.Scope scopes.New 𝕩 }
    Eval⇐{
      Ev←(o.Eval args env.New 𝕩) program._trace_ pos
      Ev¨ args
      𝕨.SetRType∘Ev¨ type
      Ev result
    }functions._with
  }
  Assign ⇐ { pos 𝕊 ⟨name,1,type,value⟩: # Declaration
    name PhraseToName˜↩@
    Visit←{⟨name∾":",𝕏¨type,𝕏value⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "assign"‿visit
    GetVar←!∘0 ⋄ Scope⇐{
      Visit o.Scope 𝕩
      getVar ↩ pos 𝕩.Add name
    }
    Eval⇐{
      u ← GetVar 𝕩
      v ← value.Eval 𝕩
      u var.SetType ≠◶⟨TypeOf v˙, (o.Eval𝕩)∘⊑⟩ type
      u.Set v
    }
  ;
    𝕨 Run ⟨{functions.Mut´𝕩}˙_value"=" , 0‿3⊏𝕩⟩
  }
  Define ⇐ {
    ⟨name,value⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "define"‿visit
    v0←v←@ ⋄ Scope ⇐ {
      value.Scope 𝕩
      v0‿v ↩ pos ("lambda"≡value.node)◶⟨ @⋈𝕩.Add , 𝕩.AddLam ⟩ name
    }
    Eval⇐{ u←V𝕩 ⋄ u.Set (V0𝕩) value.Eval 𝕩 }
  }
  OpDef ⇐ {
    ⟨type,op,fn,prec⟩←𝕩 ⋄ pos←𝕨
    !"value"≡prec.node ⋄ prec↩numbers.From prec.Eval@
    Visit←{𝕤⋄⟨type,op,fn,•Repr prec⟩}
    ⟨node,Dump,Disp,Scope,Eval⟩⇐Defaults "opdef"‿visit
    Oper⇐{𝕤⋄ pos operator.Add type‿op‿fn‿prec}
  }
  Export ⇐ {
    ⟨name,value⟩ ← {Show 𝕩.Eval@}¨⌾⊑ 𝕩 ⋄ pos←𝕨
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp,Oper,Scope⟩⇐d←Defaults "export"‿visit
    Eval ⇐ { program.Export program._trace_ pos¨⟜<´ d.Eval 𝕩 }
  }
  Include ⇐ {
    {𝕩.NoScope@⋄𝕩} files.Include Show (⊑𝕩).Eval@
  }
  Body ⇐ {
    statements←𝕩
    Visit←{⟨𝕏¨statements⟩}
    ⟨node,Dump,Disp,Oper⟩⇐d←Defaults "body"‿visit
    sc←@ ⋄ Scope⇐{ Visit o.Scope sc ↩ scopes.New 𝕩 }
    Eval⇐{ ¯1⊑⊑d.Eval (sc.Names@) env.New 𝕩 }
    # Hack for include statements
    NoScope⇐{𝕤⋄ Scope↩d.Scope ⋄ Eval↩¯1⊑·⊑d.Eval }
  }
  If ⇐ {
    ⟨cond,then,else⟩←𝕩
    Visit←{⟨𝕏cond,𝕏then,𝕏¨else⟩}
    ⟨node,Dump,Disp,Oper,Scope⟩⇐Defaults "if"‿visit
    Eval ⇐ {
      c ← cond.Eval e←𝕩
      { IsTyped c ?
        lf ← functions.Label@
        c functions.GotoF lf
        then.Eval e
        functions.Goto¨ lt ← functions.Label¨ else
        functions.SetLabel lf
        lt { 𝕩.Eval e ⋄ functions.SetLabel 𝕨 }¨ else
        {Shows⇐!∘"Can't use if statement result as value"⋄kind⇐"error"}
      ;
        numbers.GetBool c ? then.Eval e ;
        r ← {Shows⇐!∘"Can't use if-0 statement result as value"⋄kind⇐"error"}
        r ⊣´ { 𝕩.Eval e }¨ else
      }
    }
  }
  While ⇐ {
    ⟨testFirst,cond,stmt⟩←𝕩
    Visit←{⟨𝕏cond,𝕏stmt⟩}
    ⟨node,Dump,Disp,Oper,Scope⟩⇐Defaults "while"‿visit
    Eval ⇐ {
      functions.Goto¨ lc ← functions.Label¨↕testFirst
      functions.SetLabel lt ← functions.Label@
      stmt.Eval 𝕩
      functions.SetLabel¨ lc
      (cond.Eval 𝕩) functions.Goto lt
      {Shows⇐!∘"Can't use while statement result as value"⋄kind⇐"error"}
    }
  }
  n0 ← Word "0"
  For ⇐ {
    ⟨fn,ptrs,ind,from,to,body⟩←𝕩 ⋄ pos←𝕨
    from↩n0⊣´from
    ptri←Ident¨ptrs
    vardisp←1↓∾(","⊸∾¨ptrs)∾" over "⊸∾¨ind
    Visit←{⟨𝕏fn,vardisp⊣𝕏¨ptri,𝕏from,𝕏to,𝕏body⟩}
    ⟨node,Dump,Disp,Oper⟩⇐d←Defaults "for"‿visit
    ls←@
    Scope ⇐ {
      (o.Scope 𝕩)¨ ∾⟨fn⟩‿ptri‿⟨from,to⟩
      ls ↩ (<pos) {𝕏}∘𝕩.Get¨ "load"‿"store"
      body.Scope scopes._defer (ind∾ptrs) scopes.New 𝕩
    }
    Eval ⇐ {
      e←o.Eval 𝕩
      For←(E fn) program._trace_ pos
      lsv←var.Get∘{𝕎𝕩}⟜𝕩¨ ls
      For ⟨E¨ptri, E from, E to, blocks.New ind‿ptrs‿body‿lsv‿𝕩⟩
    }
  }
}

files ← {
  path←@ ⋄ log←⟨⟩
  Load ← {
    path ↩ (∨`⌾⌽'/'⊸=)⊸/ 𝕩
    ast.Build •file.Chars 𝕩
  }
  Include ⇐ {
    f ← ('.'=⊑)◶⟨"include/",path⟩⊸•file.At 𝕩∾".singeli"
    log ∾↩ <f
    op←path ⋄ a←Load f ⋄ path↩op ⋄ a
  }
  Build ⇐ {
    log ↩ ⟨⟩
    a ← Load 𝕩
    •file.Lines⟜log⍟(@⊸≢) 𝕨
    a
  }
}

ast ← {
  Show ⇐ {•Out ∾∾⟜lf¨ 𝕩.Disp @}
  baseScope ← builtins.names scopes.New scopes.Init@
  baseEnv   ← builtins.values env.Fixed @
  Build ⇐ Parse∘Tokenize
  Compile ⇐ {
    t ← 𝕨 files.Build 𝕩
    t.Oper operator._with @
    t.Scope scopes._run baseScope
    t.Eval program._with baseEnv
  }
}

(∾∾⟜lf¨) ast.Compile
