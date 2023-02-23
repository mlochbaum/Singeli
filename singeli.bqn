cpu‿libpaths ← •args

tab‿lf←@+9‿10

dig ← '0'+↕10
alph← "_"∾⥊"aA"+⌜↕26
wc  ← dig∾alph∾"."       # Word characters
oc  ← "!$%&*+-/<=>?\^|~" # Operator characters that can stick together

# Source to list of token strings
Tokenize←{
  𝕩+↩𝕩(=×lf⊸-)@+13                          # Convert CR to LF
  𝕩∾↩lf(≠⥊⊣)¯1↑𝕩                            # Trailing newline
  # Resolve comments and strings
  s‿d‿c‿n←𝕩⊸=¨"'""#"∾lf⋄sd←/¨s‿d
  g←⍋q←(¯1↓¨sd)∾⊸∾/c ⋄q↩g⊏q                 # Open indices
  e← g⊏( 1↓¨sd)∾⊸∾-⟜»∘⊏⟜(0∾+`c)⊸//n∾1       # Matching close indices
  Se←≠(>/⊢)∾⟜≠{(⊏˜𝕨)𝕊⍟(≠○(¯1⊸⊑))𝕩∾𝕩⊏𝕨}⟨0⟩˙  # Find reachable openings
  a‿b←((≠𝕩)↑·/⁼(Se q⍋e)⊸⊏)¨q‿e              # Open/close masks
  k←»≠`ab←a∨b                               # Token continuation mask
  {⟨⊑/𝕩,"Unclosed quote"⟩!0}⍟(∨´)(s∨d)>k∨a
  ign←(𝕩∊" "∾tab)∨≠`ab∧c∨n                  # Ignored characters
  # Other stuff
  da←(»𝕩='.')∧𝕩∊alph                        # Don't group ...word
  k∨↩da<∨´(»⊸∧k<𝕩⊸∊)¨wc‿oc                  # Group names, numbers, and ops
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

# Parameter checks for builtins (_p1 and _p2 to use BQN monad/dyad)
_e1 ← {𝔽⊣"Expected one parameter" !1=≠} ⋄ _p1←{𝔽⊑_e1}
_e2 ← {𝔽⊣"Expected two parameters"!2=≠} ⋄ _p2←{𝔽´_e2}
_e3 ← {𝔽⊣"Expected three parameters"!3=≠}
_v1 ← {𝔽⊣"Expected at least one parameter"!1≤≠}

numbers ← {kname⇐"number"
  f ← •Import "float2.bqn"
  NN ← 1≠•Type  # Not native number
  Is ← kname≡{Kind𝕩}
  Wrap ← {kind⇐kname⋄value⇐𝕩⋄Matches⇐Match⋄Shows⇐FmtLarge∘𝕩}
  Unwrap ← {6=•Type𝕩?kname≡𝕩.kind?𝕩.value; !"Expected constant number"}
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
    ⌊⊸≡𝕩 ? (f.Abs 𝕩) InRange 2⋆48‿64 ? "0x"∾da⊏˜⌽ 16‿16 f._repr 𝕩 ;
    FmtNum f.From 𝕩
  }

  Cast ⇐ {'f'‿l𝕊n:1; q‿l𝕊n: # 1 if valid; error otherwise
    n NN◶⋈‿Unwrap↩
    "Cannot cast float to integer"!⌊⊸≡n
    "Constant doesn't fit"!n InRange -⟜(1⊸⊑÷2˙)⍟(q='i') ⟨0,2⋆l⟩
  }
  builtins ⇐ {
    W←Wrap ⋄ P←{𝕊:Promote𝕩 ; 𝕊⁼:W𝕩} ⋄ B←f.Bits∘P
    E←f.To 2⋆From
    pr‿val ← <˘⍉∘‿2⥊ ⟨
      ⊢        ,⟨"neg",NN◶⟨-,W∘f.Neg○Unwrap⟩⟩‿⟨"not",¬GetBool⟩
      {𝕏⌾P}    ,⟨"add"‿f.Add, "sub"‿f.Sub, "mul"‿f.Mul, "div"‿f.Div, "mod"‿f.Mod⟩
      {W P⊸𝕏⟜E},⟨"shl", f.Mul⟩‿⟨"shr", f.Floor f.Div⟩
      {𝕏⌾B}    ,⟨ "and"‿∧, "or"‿∨, "xor"‿≠ ⟩
    ⟩
    arg ← 1‿3/{𝕏_p1}‿{𝕏_p2}
    ⍉>∾ (arg {𝕎∘𝕏}¨ {{𝕏⚇0}∘𝕏⚇0}¨ pr) {⟨"__"⊸∾,𝕎⟩⊸({𝕎𝕩}¨)¨𝕩}¨ val
  }
  _cmp ⇐ {(f.Cmp 𝔽 0˙)○Promote}
}

ptrWidth ← cpu.width
architecture ← {
  feats‿mat‿FeatInd ← cpu
  init ⇐ cpu.baseArch
  # Look up a list of symbols
  Id ← {𝕨 FeatInd "Expected symbol for architecture feature"⊸symbols.From¨𝕩}
  # An architecture is a mask of supported features
  New ⇐ { 𝕨 ∨˝ (1 Id 𝕩) ⊏ mat }
  Contains ⇐ ∧´≥
  Intersect ⇐ ∧ ⋄ Union ⇐ ∨
  Has ⇐ ∧´{(0 Id 𝕩)⊏𝕨∾0}  # Has all in list 𝕩
  List ⇐ /⟜feats
  ListExt ⇐ List init⊸<
  # Architecture to be used for the next function created
  next ← init
  SeeNext ⇐ {𝕊:next}
  NewFunction ⇐ {𝕊: r←next ⋄ next↩init ⋄ r }
  With ⇐ { NewFunction ⊢ (⊑𝕩){𝔽} ⊣ {next↩𝕩}∘(New 1↓𝕩) }_v1
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
    l←{𝕨⊸⊐⊏𝕩˙}˝⍉∘‿2⥊⟨c.arg,"arg",c.assign,"assign",c.body,"body",c.call,"call",c.const,"const",c.define,"define",c.export,"export",c.extend,"extend",c.extender,"extender",c.for,"for",c.function,"function",c.if,"if",c.include,"include",c.lambda,"lambda",c.number,"number",c.opdef,"opdef",c.phrase,"phrase",c.require,"require",c.run,"run",c.symbol,"symbol",c.topif,"topif",c.while,"while",c.word,"word"⟩
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
  NoCall ← ∊⟜"and"‿"or"‿"not"⌾<∨´(oc∾"[")=⊏
  Call ← { c←¬Next noCall ⋄ AddArgs⍟c Callable𝕩 }
  _exprEnd ← {endTok _𝕣:
    end ← endTok∾sep∾⥊¨",:=)}]"
    c.phrase _node_ (While∘⟨¬Next∘end, Call, 1⟩)
  }
  Expr ← ⟨⟩_exprEnd

  LFs ← {𝕊⍟Try ⟨lf⟩}
  Div ← {LFs@ ⋄ 1∘LFs⍟⊢ Try 𝕩}

  _spreadable ← {<∘⊢⍟⊣⟜𝔽∘Try∘"..."}
  _args ← {𝕗 _argsFn_ (Expr _spreadable)}
  _argsFn_ ← {𝕤
    Get ⊑𝕗
    Try 1⊑𝕗 ? ⟨⟩ ;
    LFs@
    a ← While ⟨Div∘",", 𝔾, 1⟩
    Get 1⊑𝕗
    a
  }

  StSub ← {
  "def":    Define@ ;
  "extend": Extend@ ;
  "if":     c.if     _node_ ("if"‿"("‿Expr‿")"‿Block‿(When∘⟨Try∘"else"∘Seps,Block⟩)_seq)@ ;
  "while":  c.while  _node_ (1 ∾   "while"‿"("‿Expr‿")"‿Block _seq)@ ;
  "do":     c.while  _node_ (0 ∾⟜⌽ "do"‿Block‿"while"‿"("‿Expr‿")"‿sep _seq)@ ;
  "@":      For@ ;
  𝕩:
    n ← Expr@
    d ← Try ":"
    e ← Try "="
    t ← When ⟨d>e, {e↩Try"="⋄𝕩}∘Expr⟩
    ToName ← (Asrt@⊸≢)⊸⊢∘c.PhraseTryName
    c.assign _node_ {⟨ToName⍟d 𝕩,d,t,Expr@⟩}⍟e n
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
    Expr ← "in"‿"over"‿"from"‿"to"_exprEnd # Shadow
    Get "@"
    f ← Callable@
    Get "("
    to← Expr@ ⋄ NE←{𝕤⋄ n←⋈∘{NA@≢𝕩⋄𝕩}∘c.PhraseTryName⍟𝕩 to ⋄ to↩Expr@ ⋄ n}
    {Try"in"? to↩⟨⊑NE 1,to⟩; @}
    pe← While ⟨Try∘",", Try∘"in"◶⟨⋈,⋈⟜Expr⟩ Name, 0⟩
    ps← {Try"over"?(<NE 0==to)∾𝕩; OA 0=≠𝕩⋄⟨⟩} pe # Pointers
    fr← When ⟨Try"from", Expr⟩                   # Start index
    i ← {¬Try"to"?TA 0=≠fr⋄⟨⟩; 0<=to?ps∾↩<NE 0⋄⟨⟩; NE 1}  # Index variable
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
    Get "{"
    Try "}" ? (0⥊<↕4)‿⟨⟩ ;
    ExprA ← ⟨"&"⟩_exprEnd
    Param ← {𝕤
      v ← Try "..."
      n ← Name@
      e ← When ⟨     Try "==", ExprA⟩
      t ← When ⟨(≠e)◶Try‿0":", ExprA⟩
      v‿n‿e‿t
    }
    vm ← "At most one variable-length parameter allowed"
    LFs@
    a ← While ⟨Div∘",", Param, 1⟩ ⋄ vm Asrt 1≥+´⊑¨a
    c ← While ⟨Div∘"&", ExprA, 0⟩
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
  Const ← c.const _node_ {𝕤
    t ← When ⟨¬Next"=", Expr⟩
    Get "="
    v ← Expr@
    t‿v
  }
  FunConst ← (Try∘":"◶Function‿Const)
  DefFun ← c.define _node_ (Name‿FunConst  _seq)
  
  ExtPar ← "{"‿"}" _argsFn_ Name
  Extender ← c.extender _node_ (ExtPar‿"="‿Body _seq)
  Extend ← c.extend _node_ ("extend"‿Expr0‿ExtPar _seq)

  Generator ← {𝕤⋄ Get"=" ⋄ Result 1} _withParams
  Define ← c.define _node_ {
    Get "def" ⋄  e ← Try "extend"
    ⟨Name, e◶Generator‿Extender⟩_seq 𝕩
  }

  Export ← c.export _node_ ((While∘⟨Try∘",",Symbol,1⟩)‿"="‿Callable‿sep _seq)

  OpType ← {𝕤
    pre ← (⊑≢Get) "prefix"‿"infix"
    pre◶⟨'p', Next◶⟨'n', ⊑∘Get∘1⟩⟩ "none"‿"left"‿"right"
  }
  Number ← c.number _node_ (∊⟜dig _begin_ "number")
  OpDef ← c.opDef _node_ ("oper"‿Oper‿Name‿OpType‿Number _seq)

  Include ← c.include _node_ ("include"‿Symbol _seq)
  Require ← c.require _node_ ("require"‿Symbol _seq)

  TopIf ← c.topif _node_ {𝕤
    B ← Try∘"{"◶⟨⋈Line, MultiLine⟩
    "if"‿"("‿Expr‿")"‿B‿(∾When∘⟨Try∘"else"∘Seps,B⟩)_seq 𝕩
  }

  SubLine ← "def"‿"extend"‿"oper"‿"include"‿"require"‿"if"⊸⊐⌾<◶⟨
    Define, Extend, OpDef, Include, Require, TopIf, ('''=⊑)◶DefFun‿Export
  ⟩
  ChkLoc ← ("localizable line"⊸⋈ Asrt (¬"if"⊸≡∨'''=⊑))⊸⊢∘Peek
  Line ← {𝕤
    Try "local" ? Try∘"{"◶⟨SubLine∘ChkLoc,c.body _node_ MultiLine⟩@ ;
    {𝕩.NonLocal@⋄𝕩} SubLine∘Peek@
  }
  MultiLine ← While∘⟨¬Try∘"}"∘Seps, Line, 0⟩

  Program ← c.body _node_ {𝕤
    Seps@
    While ⟨Rem, Seps⊢Line, 0⟩
  }

  Program @
}

operator ← {
  Parse ⇐ {
  ⟨op⟩ 𝕊 ⟨v⟩: v⊣´{𝕩.V@}¨@⊸≢¨⊸/op.left‿op.null ;
  ops 𝕊 val:
    Peek‿Next‿Rem ← MakeStream ops {null‿left‿bind‿R⇐𝕨 ⋄ value⇐𝕩}¨ val
    E ← {𝕊test: {𝕊∘{𝕩 LeD Next@}⍟(Test Peek)⍟Rem 𝕩} NuD Rem◶Mis‿Next@ }
    NuD ← { 𝕩.null ≢⟜@◶{𝕩.value}‿{𝕩 Run ⟨𝕩.R 𝕨.V@, ⟨E 𝕨.t⟩⟩} 𝕩 }
    LeD ← { Unk⍟(@≡l←𝕩.left)𝕩 ⋄ 𝕩 Run ⟨𝕩.R l.V@, ⟨𝕨, E l.t⟩⟩ }
    Run ← {𝕩.value.pos}⊸nodes.Run
    Unk ← { Err "Unknown infix operator"‿𝕩.value.pos }
    Mis ← {𝕊: Err "Missing right operand"‿(¯1⊑val).pos }
    E 1
  }
  Run ⇐ {𝕨𝕊⟨op,params⟩: null‿left‿bind⇐op ⋄ R⇐𝕨 nodes.Run op.R⋈params˙}
  Compose ← {pre𝕊in: ⟨null⟩⇐pre ⋄ left‿bind⇐in ⋄ R⇐⊢ }
  nil ⇐ { null⇐left⇐@ ⋄ bind⇐¯∞ ⋄ R⇐⊢ }

  Tab ⇐ { par 𝕊 new:
    p←n←o←⟨⟩  # pos, name, output
    Ind ← { n⊸⊐⌾<𝕩 }
    Add ⇐ {
      i ← Ind 1⊑𝕩
      i<≠n ? Err⟨"Duplicate operator definition:",⊑𝕩,"Previously defined here:",i⊑p⟩ ;
      p‿n‿o ∾⟜<¨↩ r←(1⊑𝕩)⊸New⌾(2⊸⊑)𝕩 ⋄ 2⊑r
    }
    Get ⇐ { i←Ind𝕩 ⋄ (i=≠n)◶⟨i⊑o˙,par.Get⟩ 𝕩 }
  }
  NewScope ⇐ {
    parent ⇐ 𝕩
    Op ← {name𝕊val‿p‿c‿a:
      V ⇐ nodes.Word∘val
      AC ← { Err ("Associativity for operator "∾name∾" must be disambiguated")‿𝕨.value.pos }⍟(0⊸>)
      T ⇐ (p C {𝕩.bind}){{⊣AC𝕏}⍟a𝕗}
    }
    tabs ⇐ nul‿lef ← parent.tabs Tab¨ ⟨
      {𝕨𝕊⟨value, prec⟩: null ⇐ 𝕨 Op ⟨value, prec, <, 0⟩ }
      {𝕨𝕊⟨value, prec, assoc⟩:
        bind ⇐ prec
        left ⇐ 𝕨 Op ⟨value, prec, ("lrn"⊸⊐⌾<assoc)⊑⟨<,≤,<-=⟩, 'n'=assoc⟩
      }
    ⟩
    Add ⇐ {𝕨𝕊type‿name‿value‿prec:
      l←type≠'p'
      (l⊑tabs).Add ⟨𝕨, name, value‿prec∾l⥊type⟩
    }
    Lookup ⇐ nul.Get Compose lef.Get
  }
  nilScope ⇐ { tabs ⇐ 2⥊{Get⇐nil˙} } # Lookup ⇐ nil˙
  CondScope ⇐ { 𝕊 par:
    parent‿tabs‿Add ⇐ par
    Lookup ⇐ {@≢c←nodes.CondOp𝕩?c; par.Lookup 𝕩}
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

_tsel ← {•Type∘⊣◶(¯1((↓»(6⥊⟨!∘"Unhandled kind"⟩)˙)∾↑)𝕗)}
Kind  ← ⟨"tuple","number",@,"generator",{𝕩.kind}⟩_tsel
Show  ← {⟨"tup{"∾"}"∾˜1↓·∾(","∾𝕊)¨, FmtNum, !, {(𝕏˜@).name}, {𝕩.Shows@}⟩_tsel 𝕩}
Match ← {𝕨 ⟨∧´𝕊¨, numbers.Match,≡,≡, {𝕨𝕨.Matches𝕩}⟩_tsel 𝕩}
IsTyped←∊⟜"register"‿"constant"‿"function"⌾< Kind
TypeOf← {⟨types.Tup 𝕊¨, {𝕩.Type@}⟩_tsel 𝕩}

types ← {kname⇐"type"
  New ← {k𝕊d:
    kind⇐kname
    typeKind‿dat⇐𝕨‿𝕩
    T←"("∾")"∾˜1↓·∾(","∾Show)¨  # Display type tuple
    Shows⇐typeKind◶⟨
      "void"               # Void:                     void
      ∾⟜•Repr´             # Primitive:   qual‿len     u8
      {∾"["‿𝕨‿"]"‿𝕩}○Show´ # Vector:      count‿t      [4]…
      "*"∾Show             # Pointer:     t            *…
      T⊸{∾𝕨‿"->"‿𝕩}⟜Show´  # Function:    ⟨q‿r‿s, t⟩   (…,…,…) -> …
      T                    # Tuple:       q‿r‿s        (…,…,…)
    ⟩∘dat
    Matches⇐{𝕨Is∘⊢◶0‿Equiv𝕩}
  }
  tVOID‿tPRIM‿tVEC‿tPTR‿tFUN‿tTUP ← ↕6
  TypeKind⇐{
    "typekind argument must be type"!Is 𝕩
    𝕩.typeKind⊑"void"‿"primitive"‿"vector"‿"pointer"‿"function"‿"tuple"
  }
  IsVoid ⇐ {tVOID≡𝕩.typeKind}

  primTypes ⇐ (tVOID New ⟨⟩) ∾ tPRIM New¨ qw ← ∾⋈¨¨˝⍉ ∘‿2⥊⟨
    'u', 2⋆0∾3+↕4  # 1/8/16/32/64
    'i', 2⋆  3+↕4  #   8/16/32/64
    'f', 2⋆  5+↕2  #        32/64
  ⟩
  _getPrim ← {{𝕏@} (⟨!∘𝕗⟩«primTypes) ⊑˜ qw⊸⊐⌾<}

  Is ⇐ kname≡Kind
  Vec ← {n𝕊t: "Vector size should be a constant integer"!IsNat n ⋄ !Is t ⋄ tVEC New ⟨n,t⟩}
  Ptr ← { 𝕊t: "Pointer type wasn't type"!Is t ⋄ tPTR New t}
  Tup ⇐ { 𝕊t: !IsTup t ⋄ !∧´Is¨ t ⋄ tTUP New t}
  Fun ⇐ tFUN New ⋈

  _cases ← {
    Kind←{𝕩.typeKind} ⋄ Dat←{𝕩.dat}
    c ← ⌊‿2⥊𝕗
    k ← ⊏˘c
    d ← (1⊏˘c) ∾ ((≠⥊c)↓𝕗)»⟨!∘0⟩
    (k⊸⊐⌾< ⊢⊘(≠◶⊢‿¯1)○Kind)◶({𝕏○Dat}¨⌾((≠k)⊸↑)d) ⊣ @○(!Is)
  }

  Quality ← ⟨tPRIM,{symbols.New ⋈⊑𝕩}, !∘"Non-primitive type"⟩_cases
  _isQual ← {⟨tPRIM,𝔽⊑,0⟩_cases TypeOf⍟(¬Is)}

  Deref ⇐ { Is 𝕩 ? tPTR=𝕩.typeKind ? 𝕩.dat ; !"Expected pointer" }

  Width ← ⟨
    tPRIM, 1⊸⊑
    tVEC,  ×⟜{Width𝕩}´
    tTUP,  +´{Width𝕩}¨
    tPTR,  ptrWidth
    {!∾⟨"Can't find width of ",TypeKind𝕩," types"⟩}
  ⟩_cases

  VCount ← ⟨ tVEC,⊑, 1 ⟩ _cases
  VType ← ⟨ tVEC,1⊸⊑, tPTR,⊢ ⟩ _cases

  FnCast ⇐ {
    args‿ret ← ⟨tFUN,⊢, !∘"Calling non-function"⟩_cases 𝕨
    args(("Wrong number of arguments: expected "∾•Repr∘⊣)!≡)○≠𝕩
    ⟨args Cast¨ 𝕩, ret⟩
  }

  _typeRel_ ← {
    𝕨 ⟨
      tVOID, 1
      tPRIM, 𝔽
      tVEC,  =○⊑ _and_ (𝕊○(¯1⊸⊑))
      tPTR,  (@≢𝕘)⊑𝕊‿𝕘
      tTUP,  MTup ← =○≠ _and_ (∧´𝕊¨)
      tFUN,  𝕊○(1⊸⊑) _and_ (MTup○⊑)
      0
    ⟩ _cases 𝕩
  }
  _cmpPrim ← {
    L←¯1⊸⊑ ⋄ ≠○⊑◶⟨𝔽○L, ('f'≠⊑∘⊣)_and_(<○L)⟩
  }
  Equiv    ← ≡          _typeRel_ @
  Subtype  ⇐ ≤ _cmpPrim _typeRel_ 1
  SSubtype ⇐ < _cmpPrim _typeRel_ 0

  _asCast ← {
    "Can't cast to non-type"!Is𝕨
    Fail ← {!∾⟨"Can't cast ",Kind𝕩," to ",Show𝕨⟩}
    Num ← {t𝕊n:
      ⟨ tPRIM,numbers.Cast⟜n, Fail⟜n ⟩ _cases t
      t constants.New n
    }
    Cast ← 𝕊
    Tup ← {
      ptr ← 0
      c ← ⟨ tTUP,⊢, tPTR,{ptr↩1⋄𝕩}, Fail⟜𝕩 ⟩_cases⍟(0≠•Type) 𝕨
      𝕨 constants.New⍟ptr c Cast¨ 𝕩
    }
    Obj ← ("number"≢{𝕩.kind})◶⟨Num,IsTyped∘⊢◶⟨Fail˜,𝔽⟩⟩
    # _tsel selects on 𝕨; swap to use 𝕩
    𝕨 ⟨Tup˜, Num˜, Fail˜, Fail˜, Obj˜⟩_tsel˜ 𝕩
  }
  _cc ← { Test‿Conv‿Fail _𝕣:
    (Conv ⊣ Fail○Show⍟(¬Test˜)⟜TypeOf)_asCast
  }
  Cast ⇐ ⟨
    Equiv, ⊢
    {!∾⟨"Explicit conversion required to change ",𝕩," to ",𝕨⟩}
  ⟩_cc
  Promote ← ⟨
    Subtype, {functions.Emit⟨𝕨, symbols.New "^promote", 𝕨, 𝕩⟩}
    {!∾⟨"Can't promote from type ",𝕩," to non-subset ",𝕨⟩}
  ⟩_cc
  Reinterpret ← ⟨
    ≡○Width, {functions.Emit⟨𝕨, symbols.New "^promote", 𝕨, 𝕩⟩}
    {!∾⟨"Can't reinterpret type ",𝕩," as different-width type ",𝕨⟩}
  ⟩_cc

  IncWidth ← {
    "First parameter of promote must be a type or number"!"number"≡Kind𝕨
    n←numbers.From 𝕨
    t←TypeOf 𝕩
    (1 + n ×∘- Width t)◶⟨
      !∘"Can't decrease width in promotion"
      ⊢
      ⟨
        tPRIM, "Invalid width"_getPrim 𝕨⌾(1⊸⊑)
        !∘"Can't increase width of non-primitive type"
      ⟩_cases∘t⊸Promote
    ⟩ 𝕩
  }
  GetQual ← {
    e ← "Quality must be a single-letter symbol (i,u,f)"
    n ← e symbols.From 𝕩 ⋄ e!1=≠n
    ⊑n
  }
  PrimType ← "Invalid primitive type specification"_getPrim ⟨GetQual,numbers.From⟩ {𝕎𝕩}¨ ⊢

  builtins ⇐ ∾˘⍉∘‿2⥊⟨
    ⟨"cast"   ,             "promote"   ,"reinterpret"⟩
    ⟨ Cast _p2,Is∘⊣◶IncWidth‿Promote _p2, Reinterpret _p2⟩
    ⟨"eltype"   ,"vcount"   ,"width"   ,          "__vec"   ,"__pnt"⟩
    ⟨ VType _p1 , VCount _p1, Width _p1,numbers.From⊸Vec _p2,   Ptr _p1⟩
    ⟨"primtype"   ,"quality","isfloat","issigned","isint"⟩
    ⟨ PrimType _e2, Quality _p1⟩∾{𝕩_isQual _p1}¨⟨'f'⊸≡ ⋄ 'i'⊸≡ ⋄ ⊑∘∊⟜"iu"⟩
  ⟩
}

registers ← {kname⇐"register"
  Is ← kname ≡ Kind
  Transient ⇐ {
    kind⇐kname ⋄ shows⇐"(temp)" ⋄ type⇐𝕩 ⋄ fmtType⇐1 ⋄ Matches⇐≡
    name←⟨⟩ ⋄ AddName⇐{name∾↩<𝕩}
    mut⇐0 ⋄ ref⇐0 ⋄ Use⇐{𝕤⋄ref+↩1} ⋄ SetMut⇐!
    ShowReg⇐{showReg↩∾⟨𝕏@⟩∾"_"⊸∾¨(ref=1)/name}
  }
  Declare ⇐ { name 𝕊 type‿val:
    kind⇐kname ⋄ shows⇐name ⋄ type⇐ ⋄ fmtType⇐1 ⋄ Matches⇐≡
    addName⇐@ ⋄ {𝕩.AddName name}⍟Is val
    mut⇐0 ⋄ ref⇐0 ⋄ Use⇐{𝕤⋄ref+↩1}
    SetMut⇐{𝕤⋄mut↩1}  # Changed (for blocks, and transient elimination)
    ShowReg⇐{showReg↩𝕩}∘{
      Is val? ¬val.mut? (¬mut)∨1=val.ref? ref+↩val.ref-1 ⋄ val.ShowReg𝕩 ;
      ∾⟨𝕏@,"_",name⟩
    }
  }
  Mutable ⇐ { Is 𝕩 ? {!}≢𝕩.setMut ; 0 }
  Mutated ⇐ { Is 𝕩 ? 𝕩.mut ; 0 }
  MarkUse ⇐ {𝕩.Use@}⍟Is
}
constants ← {kname⇐"constant"
  New ⇐ {
    kind⇐kname ⋄ type⇐𝕨 ⋄ value⇐𝕩
    shows⇐∾"!:"∾¨Show¨𝕩‿𝕨 ⋄ fmtType⇐0 ⋄ Matches⇐≡
  }
  Static ⇐ {
    kind⇐kname ⋄ type‿handle⇐𝕩
    shows⇐"$c"∾(""⊢"_"∾𝕨)∾˜•Repr handle ⋄ fmtType⇐1 ⋄ Matches⇐≡
  }
  Undefined ⇐ {
    kind⇐kname ⋄ shows⇐"?:"∾Show type⇐𝕩 ⋄ fmtType⇐0 ⋄ Matches⇐≡
  }
}

labels ← {kname⇐"label"
  New ⇐ { kind⇐kname ⋄ shows⇐"l"∾•Repr𝕩 ⋄ Matches⇐≡ }
}
symbols ← {kname⇐"symbol"
  Is ← kname ≡ Kind
  From ⇐ {!⟜(Is𝕩˙)𝕨 ⋄ 𝕩.symstr}
  M ← Is∘⊢_and_(≡○From)
  Enc ← "'"(∾∾⊣)⊢+128×' '⊸= # Space to non-breaking space
  New ⇐ { kind⇐kname ⋄ symstr⇐𝕩 ⋄ Shows⇐Enc∘symstr ⋄ Matches⇐M }
}

functions ← {kname⇐"function"
  current⇐{
    Append⇐NextLabel⇐Return⇐SetArch⇐!∘"No function active"
    arch ⇐ architecture.init
  }
  New ← {𝕤
    kind⇐kname ⋄ shows⇐"$f"∾(•Repr id⇐𝕩)∾"_"⊸∾⍟(0<≠)𝕨 ⋄ Matches⇐≡ ⋄ type⇐@
    arch⇐architecture.NewFunction@ ⋄ SetArch⇐{arch↩𝕩}
    label←¯1 ⋄ args←atypes←⟨⟩ ⋄ rType⇐@
    NextLabel⇐{𝕤⋄ labels.New label+↩1 }
    NextArg⇐{ atypes∾↩<𝕩 ⋄ args∾↩<a←𝕨 registers.Declare 𝕩‿@ ⋄ a }
    ⟨Push,Arr⟩←MakeStack@
    Instrs⇐Arr
    Append⇐{ Push𝕩⋄@ }
    SetRType⇐{
      SetRType↩!∘0 ⋄ !types.Is rType↩𝕩
      type ↩ atypes types.Fun rType
    }
    _ret_←{
      @≢rType? types.IsVoid rType? Append⍟𝕘 ⟨"ret",⊑types.primTypes⟩ ⋄@ ;
      Append ⟨"ret", rType ≢⟜@◶⟨𝔽∘⊢, types.Cast⟩ 𝕩⟩
      {Shows⇐!∘"Can't use return result as value"⋄kind⇐"error"}
    }
    Return⇐!∘"Early return from function with no explicit result type" _ret_ 1 @⊣´⊢
    Finish⇐{"Explicit result type needed"!IsTyped 𝕩⋄SetRtype TypeOf 𝕩⋄𝕩} _ret_ 0
    Prot⇐{𝕊:
      ext ← (0<≠)◶⟨⟩‿(⋈·'+'⌾⊑·∾','⊸∾¨) architecture.ListExt arch
      at ← (𝕏¨args)≍˘Show¨atypes
      1↓∾" "⊸∾¨⟨1↓shows,Show rType⟩∾((<∘•Repr∘≠∾⥊)at)∾ext
    }
  }
  _with_ ⇐ {
    u‿name ← 𝕨  # Passed in by nodes.Define, pretty hacky
    fs←current
    f←current↩name program.AddFunction new
    u.Set f
    f (f.Finish 𝔽)program._trace_ 𝕘 𝕩
    current↩fs
    f
  }
  NextArg ⇐ { 𝕨 current.NextArg 𝕩 }
  Label ⇐ { current.NextLabel 𝕩 }
  Append ← { current.Append 𝕩 }
  _appendReg ← { (1⊸⊑⊣Append) ⟨"new",𝔽𝕨⟩∾{kind⇐@⋄shows⇐𝕩}⌾⊑𝕩 }
  AppendNew ← registers.Transient _appendReg
  Return ⇐ { current.Return 𝕩 }
  GetArch ← {𝕊: current.arch }
  SetArch ← { current.SetArch 𝕩 }
  Emit ⇐ { (⊑𝕩) AppendNew "emit" <⊸∾ 𝕩 }
  Declare ⇐ { t←TypeOf𝕩 ⋄ 𝕨 registers.Declare⟜t‿𝕩 _appendReg "val"‿t‿𝕩 }
  _destructure ← {
    0≠•Type𝕩 ? 𝕨𝔽⚇0𝕩;
    "Single assignment target but multiple values" ! 0=•Type𝕨
    "Assignment tuple length mismatch" ! 𝕨 ≡○≢ 𝕩
    𝕨𝕊¨𝕩
  }
  Mut  ⇐ {
    "Can't assign to non-register" ! registers.Mutable 𝕨
    Append "mut"‿𝕨‿(𝕨.type types.Cast 𝕩)
    𝕨.SetMut@
    𝕨
  }_destructure
  Call ⇐ {
    f ← ⊑𝕩
    "Calling non-function" ! IsTyped f
    a‿t ← (TypeOf f) types.FnCast 1↓𝕩
    t AppendNew ⟨"call",t,f⟩ ∾ ≠⊸∾ a
  }
  _instr ← { Append (𝕨𝔽𝕩)<⊸∾𝕨⋈𝕩 ⋄ 𝕩 }
  SetLabel ⇐ "lbl"_instr
  Goto     ⇐ "goto"⊘"gotoT"_instr
  GotoF    ⇐ "gotoF"_instr
  builtins ⇐ ⍉> ⟨
    ⟨"call",Call _v1⟩, ⟨"emit",Emit _v1⟩, ⟨"return",Return⟩
    ⟨"makelabel",Label⟩, ⟨"goto",Goto _p1⟩
    ⟨"setlabel",SetLabel _p1 ⋈∘Label⍟(0=≠)⟩
  ⟩ ∾ { New‿Union‿Has‿List ← architecture ⋄ S←SetArch ⋄ G←GetArch ⋄ ⟨
    ⟨"setarch",S New⟩
    ⟨"addarch",S G Union New⟩
    ⟨"hasarch",G⊸Has⟩
    ⟨"listarch",symbols.New¨List∘G⟩
  ⟩}
}

blocks ← {kname⇐"block"
  New ⇐ {𝕊 ind‿ptrs‿body‿ls‿e:
    kind⇐kname
    shows⇐"{block}" ⋄ Matches⇐≡
    Exec⇐{
      "Wrong number of pointer arguments in block exec" ! ptrs≡○≠1⊑𝕩
      r ← body.Eval be ← ⟨≠ind,ls,𝕩,ptrs⟩ env.Block e
      be.Stores @
      r
    }
  }
  Exec ⇐ {𝕊 ind‿vars‿block:
    "Executing non-block" ! "block"≡Kind block
    block.Exec ind‿vars
  }
}
Load ← {  𝕊 ptr‿i: functions.Emit ⟨types.Deref TypeOf ptr, symbols.New "^load", ptr, i⟩ }
Store← {v 𝕊 ptr‿i: functions.Emit ⟨types.Deref TypeOf ptr, symbols.New "^store", ptr, i, v⟩ }


builtins ← {
  Kinds ← {
    E ← "Unhandled type" ! 0˙
    (e{k‿o←𝕨⋄∧○(k≡⊢)◶⟨𝕏,O˙⟩}´𝕩){o←𝕨𝔽○Kind𝕩⋄𝕨O𝕩}
  }
  Ty2 ← {𝕏⚇0 _p2}∘Kinds ⊣∾⟜(<·"symbol"⌾⊑⊢´)∘⊢⍟(⊑∊⟜=‿≠)"number"‿"type"⋈¨{𝕏numbers._cmp}⊸⋈
  TypeSuff ← IsTyped◶0‿{𝕩.fmtType}◶""‿{":"∾Fmt TypeOf𝕩}
  UnEsc ← ⊢-128×(' '+128)⊸= # Non-breaking space to space
  Fmt ← 2↓·∾·", "⊸∾¨(UnEsc∘Show∾TypeSuff)⎊("("∾")"∾˜Kind⎊"unknown")¨
  Merge ← {
    0<⌈´=¨𝕩 ? ∾𝕩 ;
    m←"merge: parameters must include at least one tuple or all be symbols"
    symbols.New ∾ m⊸symbols.From¨𝕩
  }
  Slice ← {
    "slice: one or two slicing values expected"!(2⊸≤∧≤⟜3)≠𝕩
    s←¬=l←⊑𝕩
    l "slice: first parameter must be a tuple or symbol"⊸symbols.From⍟s↩
    i←l≠⊸(0⌈⊣⌊+⍟(0⊸>)¨)numbers.From¨1↓𝕩 ⋄ symbols.New⍟s (⊑i)↓(1↓i)↑´˜l
  }
  names‿values ⇐ <˘∾≍⟨
    Show¨⊸≍ types.primTypes
    ⍉> ⟨
      ⟨"show",(1≠≠)◶⊑‿{Shows⇐!∘"Multiple show used improperly"}⊣•Out∘Fmt⟩
      ⟨"exec",blocks.Exec _e3⟩
      ⟨"match",Match _p2⟩
      ⟨"undefined",(constants.Undefined⊣"undefined: expected type"!"type"≡Kind)_p1⟩
      ⟨"hastype",IsTyped∘⊑ _and_ ({𝕩.type}⊸Match´)_e2⟩
      ⟨"type",TypeOf _p1⟩, ⟨"kind",symbols.New Kind _p1⟩
      ⟨"typekind",symbols.New types.TypeKind _p1⟩
      ⟨"load",Load _e2⟩, ⟨"store",¯1⊸(⊑Store↓)_e3⟩
      ⟨"tup",⊢⟩, ⟨"tupsel",numbers.From⊸⊑⚇0‿∞ _p2⟩, ⟨"tuplen",≠_p1⟩
      ⟨"merge",Merge⟩, ⟨"slice",Slice⟩
      ⟨"symchars",(symbols.New∘⋈¨"symchars: expected symbol"⊸symbols.From)_p1⟩
      ⟨"bind",⊑{𝕎𝕩⊸∾}1⊸↓_v1⟩, ⟨"each",⊑{𝕎¨<˘⍉>𝕩}1⊸↓_v1⟩
      ⟨"apply",{"apply: second parameter must be a tuple"!1==𝕩⋄𝕎𝕩}_p2⟩
      ⟨"witharch",architecture.With⟩
    ⟩
    functions.builtins
    numbers.builtins
    types.builtins
    >⟨
      "__eq"‿"__ne"‿"__lt"‿"__gt"‿"__le"‿"__ge"
      =‿≠‿<‿>‿≤‿≥ Ty2¨ ⟨Match,¬Match⟩ ∾ ·⥊≍˘⟜({𝕏˜}¨) ⟨types.SSubtype,types.Subtype⟩
    ⟩
  ⟩
  values {name⇐𝕩}⊸{𝕏⊘𝕨}⍟(3=•Type∘⊢)¨˜↩ names
}

var ← {
  Get⇐{𝕩.Get@}
  Fixed⇐{ kind⇐"var" ⋄ Get⇐𝕩˙ }
  New⇐{NG←"generator"≢Kind ⋄ kind⇐"var"
    v←𝕩 ⋄ Get⇐{𝕤⋄v}
    Set⇐{
      {𝕊:Set↩!∘"Can't extend a non-generator"}⍟NG𝕩
      v↩𝕩
    }
  }
}
scopes ← {
  noLambda ← var.Fixed {!∘"Unhandled case"}
  null←{Get⇐{Err⟨"Undefined name: "∾𝕩,𝕨⟩} ⋄ GetLam⇐noLambda˙}
  New⇐{
    p←@¨n←𝕨⊣⟨⟩ ⋄ Names⇐{𝕤⋄n}
    parent ⇐ 𝕩  # For nonlocal
    Sel ←{𝕩⊑env.Vars}
    Make←{c←≠n⋄p‿n∾⟜<¨↩𝕩⋄c}
    Dup ←{Err⟨"Duplicate definition:",⊑𝕩,"Previously defined here:",𝕨⊑p⟩}
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
  Alias⇐Make
  New  ⇐{ (var.New∘@¨ 𝕨) Make 𝕩 }
  Fixed⇐{ (var.Fixed¨ 𝕨) Make 𝕩 }
  Block⇐{⟨ni,Load‿Store,ind‿ptrs,names⟩ 𝕊 par:
    pv ← names functions.Declare⚇∞‿0⟜(Load∘⋈⟜ind)¨ ptrs
    vars‿parent ⇐ (var.Fixed¨(ni⥊<ind)∾pv) Make par
    Stores ⇐ {𝕤
      ptrs {registers.Mutated 𝕩 ? Store 𝕨‿ind‿𝕩 ;@}⚇0 pv
    }
  }
}

program ← {
  AddFunction⇐AddConstant⇐Export⇐Require⇐!∘0 ⋄ trace⇐@
  _with ⇐ {
    fns←⟨⟩ ⋄ AddFunction ↩ { f ← 𝕨 𝕏 ≠fns ⋄ fns∾⟜<↩f ⋄ f }
    cns←⟨⟩ ⋄ AddConstant ↩ { c ← 𝕨 constants.Static ⟨t←TypeOf𝕩, ≠cns⟩ ⋄ cns∾⟜<↩⟨Show c,t,𝕩⟩ ⋄ c }
    exp←⟨⟩ ⋄ Export ↩ { "Exports must be typed" ! IsTyped 𝕩 ⋄ exp ∾⟜<↩ 𝕨‿𝕩 }
    req←⟨⟩ ⋄ Require ↩ { req ∾⟜<↩ 𝕩 }
    ⟨_trace_⟩↩s←Stack@
    𝕨 𝔽⎊s.Report 𝕩
    AddFunction↩AddConstant↩Export↩!∘0
    ∾ ⟨DispHeader¨req, DispConstants cns, ∾DispFunction¨fns, DispExport¨exp⟩
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
  DispHeader←{ "require " ∾ Show 𝕩 }
  DispConstants←{ ∾⟜(<⟨⟩)⍟(0<≠) (J"constant"<⊸∾Show¨⌾(1⊸↓))¨ 𝕩 }
  DispFunction←{
    ShowReg ← {h←¯1⋄{𝕊:"v"∾•Repr h+↩1}}{𝕩.ShowReg𝕗}
    ProcInstrs ← {
      # Mark each register with the number of times it's used after definition
      (registers.MarkUse¨2↓⊢)¨ 𝕩
      # Combine new into next mut call if that's the only use
      nm ← / ∧⟜«˝ "new"‿"mut" ≡⌜ ⊑¨𝕩
      nm (≡◶0‿{1=𝕩.ref}¨˝1‿2⊑¨𝕩⊏˜0‿1+⌜⊢)⊸/↩
      𝕩 ↩ (¬(≠𝕩)↑/⁼1+nm) / (1⌽𝕩) (⊣⌾(2⊸↑)¨⌾(nm⊸⊏)) 𝕩
      # Convert to names, performing register numbering
      𝕩 ("register"≡Kind)◶Show‿ShowReg¨⌾(1⊸↓)¨↩
      # Registers are aliased when possible, leading to no-op new
      # instructions removed here
      {"new"≡⊑𝕩 ? "val"≡2⊑𝕩 ? ≡´1‿4⊏𝕩 ? 0 ; 1}¨⊸/ 𝕩
    }
    ∾⟨
      ⟨"beginFn "∾𝕩.Prot showReg⟩
      J¨ ProcInstrs 𝕩.Instrs@
      ⟨"endFn",""⟩
    ⟩
  }
  DispExport←{ "export " ∾ J <⊸∾⟜(TypeOf⋈○Show⊢)´ 𝕩 }
}

nodes ← {
  # Node operations
  o ← {
    Verify ⇐ {𝕩.node}
    Dump ⇐ {𝕩.Dump@}
    Disp ⇐ {𝕩.Disp@}
    Oper ⇐ {𝕊op :{𝕩.Oper  op }}
    Scope⇐ {𝕊sc :{𝕩.Scope sc }}
    Eval ⇐ {𝕊env:{𝕩.Eval  env}}
  }
  Defaults ← {
    node‿visit ⇐ 𝕩
    Visit o.verify
    Dump ⇐ {𝕤⋄⟨node,Visit o.dump⟩}
    Disp ⇐ {𝕤⋄node <⊸∾ "  "⊸∾¨ ∾∾ @ ⥊∘<∘⊢⍟((2×≡)+≡⟜@)¨○Visit o.disp}
    Oper ⇐ {Visit o.Oper  𝕩 ⋄ operator.nil}
    Scope⇐ {Visit o.Scope 𝕩⋄@}
    Eval ⇐ {Visit o.Eval  𝕩}
  }

  # Node types
  Ident ← {
    name⇐𝕩 ⋄ pos⇐𝕨⊣@
    ⟨node,Dump⟩⇐Defaults "ident"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
    Oper⇐{𝕩.Lookup name}
    Eval⇐!∘0 ⋄ Scope⇐{Eval↩var.Get∘(pos 𝕩.Get name)}
  }
  _value ← {
    name←𝕩 ⋄ pos⇐𝕨⊣@
    Eval⇐(𝕨𝔽𝕩)˙
    ⟨node,Dump,Oper,Scope⟩⇐Defaults "value"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
  }
  Number ⇐ numbers.Read
  Word ⇐ (⊑⊏∘⊢∊dig˙)◶⟨Ident, Number _value⟩
  Symbol ⇐ (symbols.New 1↓¯1↓⊢)_value
  Run ⇐ {
    𝕨𝕊⟨⟨infix⟩,params⟩: CondNode´ 𝕩;
    ⟨caller,params⟩←𝕩 ⋄ pos⇐𝕨
    spread ← 0=•Type¨params ⋄ params ⊑¨↩
    deSpread ← (∨´spread)⊑⊢‿{
      ∾ spread ⊣◶⟨⋈⊢,("Spread input must be tuple"!IsTup)⊸⊢⊢⟩¨𝕩
    }
    Visit←{⟨𝕏caller,𝕏¨params⟩}
    ⟨node,Dump,Disp,Scope⟩⇐d←Defaults "run"‿visit
    Oper ⇐ {𝕤⋄ pos operator.Run ⟨⊑Visit o.Oper 𝕩, params⟩}
    Eval ⇐ {
      (3=•Type𝕨)◶⟨!∘"Running non-generator", 𝕎∘DeSpread⟩ program._trace_ pos 𝕩
    }´ d.Eval
  }
  Call ⇐ { 𝕨 Run ⟨Ident"call" , <⊸∾´𝕩⟩ }
  Phrase ⇐ {
    things←𝕩 ⋄ pos⇐𝕨
    ToName⇐{𝕤⋄ (1=≠)◶@‿(("ident"≡{𝕩.node})◶@‿{𝕩.name}⊑) things }
    Visit←{⟨𝕏¨things⟩}
    ⟨node,Dump,Disp,Scope,Eval⟩⇐Defaults "phrase"‿visit
    Oper⇐{
      ⟨node⟩↩n ← (o.Oper 𝕩)¨⊸operator.Parse things
      Scope↩{𝕨n.Scope𝕩} ⋄ Eval↩{𝕨n.Eval𝕩} ⋄ Disp↩{𝕨n.Disp𝕩} # fields of n can change
      operator.nil
    }
  }
  PhraseTryName ⇐ {"phrase"≡𝕩.node}◶@‿{𝕩.ToName@}
  notTypeVar ← types.primTypes≠⊸↑builtins.names
  Lambda ⇐ {
    ⟨⟨paramsPlus,conds⟩,result⟩←𝕩 ⋄ pos←𝕨
    pvar‿params‿pmatch‿ptype ← <˘⍉>paramsPlus
    tname ← (¬∘∊⟜(⟨@⟩∾notTypeVar)⊸/ PhraseTryName¨)¨ ptype
    uTyp‿iTyp←(⍷∘∾ ⋈ ⊐∘∾⊔·/≠¨)tname
    _pc ← {n←𝕨⋄f←𝕗 ⋄ {pos Run ⟨Ident f,⟨Ident n,𝕩⟩⟩}¨𝕩}
    conds∾˜↩∾(params "hastype"_pc¨ tname≠⊸↓¨ptype)∾(params "match"_pc¨ pmatch)
    uPar‿iPar←(⍷⋈⊐)params
    Visit←{((iPar⊏uPar)∾⟜(∾""<⊸∾":"⊸∾¨)¨tname)∾⟨𝕏¨conds,𝕏result⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "lambda"‿visit
    Scope⇐{ Visit scopes._defer o.Scope (uPar∾uTyp) scopes.New 𝕩 }
    Eval⇐{𝕨 𝕊 e: # 𝕨 is previous value and name, from Define
      next ← ({𝕩.Get@}⊑𝕨)⊣{"No matching generator definition"!0˙}
      name ← (1⊑𝕨)⊣""
      AllEq ← ∧´⊏Match¨1⊸↓
      Count‿DeVar ← (+´¬)⊸{
        ¬∨´𝕩 ? ⟨𝕨=≠, ⊢⟩ ;
        ⟨𝕨≤≠, (0‿𝕨-˜⋈⁼/𝕩)⊸(∾0‿2‿1⊏↑¨⟜<∾⟜<·<↓´˜)⟩
      } pvar
      CT ← {∧´((∧´IsTyped¨)_and_(AllEq{𝕩.type}¨)⊏⟜𝕩)¨iTyp}
      Exec‿_cached ← { result.node≢"function"?
        Exec ⇐ result.Eval∘⊢ ⋄ _cached ⇐ {𝔽}
      ;
        args←res←arches←⟨⟩ ⋄ AN←architecture.SeeNext
        Exec ⇐ {
          args∾↩<𝕨 ⋄ arches∾↩<AN@
          n ← (128⌊≠)⊸↑ name∾∾('_'∾·∊⟜(dig∾1↓alph)⊸/Show)¨𝕨
          {Set⇐{res∾↩<𝕩}}‿n result.Eval 𝕩
        }
        _cached ⇐ {
          i ← (𝕩⊸((=○≠)◶⟨0,∧´Match¨⟩)¨args) ∧ arches≡¨<AN@
          ∨´i ? (⊑/i)⊑res ; 𝔽𝕩
        }
      }
      {
        Count 𝕩 ? a←DeVar𝕩 ⋄ ∧´AllEq¨iPar⊔a ? CT a ?
        try ← (⊑⟨a˙⊸exec⟩) (Next 𝕩˙){numbers.GetBool∘𝕨.Eval◶𝔽‿𝕏}´ conds
        Try ((iPar∊⊸/a)∾{𝕩.type}¨iTyp⊑¨⊸⊏a) env.Fixed e
      ;
        Next 𝕩
      }_cached⊘{𝕊: {name⇐𝕩} "(generator)"⍟(0=≠) name}
    }
  }
  Extender ⇐ {
    ⟨names,result⟩←𝕩 ⋄ pos←𝕨
    Visit←{names∾⟨𝕏¨result⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "extender"‿visit
    Scope⇐{ Visit scopes._defer o.Scope names scopes.New 𝕩 }
    Eval⇐{𝕨𝕊e: {
      A ← ! program._trace_ pos
      "Wrong number of parameters in extension" A names≡○≠𝕩
      "Generator defined with extend must be called with extend" A ∧´ ("var"≡Kind)¨ 𝕩
      ¯1⊑result {𝕨.Eval𝕩}¨ <𝕩 env.Alias e
    }⊘{𝕊: {name⇐𝕩} "(extender)"⍟(0=≠) (1⊑𝕨)⊣""}}
  }
  Extend ⇐ {
    ⟨ext,names⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏ext,names⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "extend"‿visit
    N←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}}
    v←@ ⋄ Scope ⇐ { ext.Scope𝕩 ⋄ v ↩ pos⊸(N𝕩).AddLam¨ names }
    Eval ⇐ {
      slots ← {𝕩.Set𝕨.Get@⋄𝕩}⍟≢○({𝕎𝕩}⟜(N𝕩))´¨ v
      (ext.Eval𝕩){𝔽} program._trace_ pos slots
    }
  }
  Arg ⇐ {
    ⟨name,type⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨name,𝕏type⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "arg"‿visit
    v←@ ⋄ Scope⇐{ type.Scope 𝕩 ⋄ v ↩ pos 𝕩.Add name }
    Eval⇐{
      u←V𝕩 ⋄ t←type.Eval 𝕩
      "Argument type must be a type" ! program._trace_ pos types.Is t
      u.Set name functions.NextArg t
    }
  }
  Function ⇐ {
    ⟨args,type,result⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏¨args,𝕏¨type,𝕏result⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "function"‿visit
    Scope⇐{ Visit scopes._defer o.Scope scopes.New 𝕩 }
    Eval⇐{
      ev←o.Eval args env.New 𝕩
      Ev¨ args
      𝕨.SetRType∘Ev¨ type
      Ev result
    } functions._with_ pos
  }
  _setType ← { pos type‿env _𝕣 v:
    { ≠type ?
      t ← (⊑type).Eval 𝕩
      "Variable type must be a type" ! types.Is t
      t types.Cast v
    ;
      "Explicit type needed for untyped initial value" ! {=𝕩?∧´𝕊¨𝕩;IsTyped𝕩} v
      v
    } program._trace_ pos env
  }
  Assign ⇐ { pos 𝕊 ⟨name,1,type,value⟩: # Declaration
    Visit←{⟨name∾":",𝕏¨type,𝕏value⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "assign"‿visit
    GetVar←!∘0 ⋄ Scope⇐{
      Visit o.Scope 𝕩
      getVar ↩ pos 𝕩.Add name
    }
    Eval⇐{
      u ← GetVar 𝕩
      v ← pos type‿𝕩 _setType value.Eval 𝕩
      u.Set name⊸functions.Declare⚇0 v
    }
  ;
    𝕨 Run ⟨{functions.Mut´𝕩}˙_value"=" , 0‿3⊏𝕩⟩
  }
  Const ⇐ {
    ⟨type,value⟩←𝕩 ⋄ pos←𝕨
    Visit←{⌽⟨𝕏¨type,":",𝕏value⟩}
    ⟨node,Dump,Disp,Oper,Scope⟩⇐Defaults "assign"‿visit
    Eval⇐{ (1⊑𝕨) program.AddConstant pos type‿𝕩 _setType value.Eval 𝕩 }
  }
  Define ⇐ {
    ⟨name,value⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "define"‿visit
    N←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}}
    v0←v←@ ⋄ Scope ⇐ {
      value.Scope 𝕩
      s ← N 𝕩
      v0‿v ↩ pos ("lambda"≡value.node)◶⟨ @⋈s.Add , s.AddLam ⟩ name
    }
    Eval⇐{
      f←"function"≡value.node  # Set value in Eval for function recursion
      e ← N 𝕩
      u←V e ⋄ u.Set program._trace_ pos⍟(¬f) (name⋈˜f◶⟨V0,u˙⟩e) value.Eval 𝕩
    }
  }
  OpDef ⇐ {
    ⟨op,fn,type,prec⟩←𝕩 ⋄ pos←𝕨
    Visit←{𝕤⋄⟨type,op,fn,•Repr prec⟩}
    ⟨node,Dump,Disp,Scope,Eval⟩⇐Defaults "opdef"‿visit
    N←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}}
    Oper⇐{pos (N𝕩).Add type‿op‿fn‿prec}
  }
  Export ⇐ {
    ⟨name,value⟩ ← {Show 𝕩.Eval@}¨⌾⊑ 𝕩 ⋄ pos←𝕨
    Visit←{⟨name,𝕏value⟩}
    ⟨node,Dump,Disp,Oper,Scope⟩⇐d←Defaults "export"‿visit
    NonLocal ⇐ ⊢
    Eval ⇐ { program.Export program._trace_ pos¨⟜<´ d.Eval 𝕩 }
  }
  Include ⇐ {
    # Top-level if statements resolve in operator pass; expand then
    ⟨file⟩ ← 𝕩 ⋄ pos←𝕨
    NL←⊢ ⋄ NonLocal⇐{𝕊:NL↩{𝕩.NonLocal@⋄𝕩}}
    ⟨node,Dump,Disp⟩⇐Defaults "include"‿{⟨𝕏file⟩} ⋄ Scope⇐Eval⇐!
    Oper ⇐ {𝕤
      b ← NL pos files.Include symbols.From file.Eval@
      ⟨node,Dump,Disp,Oper,Scope,Eval⟩ ↩ b # Always a body so fields can't change
      b.Oper 𝕩
    }
  }
  Require ⇐ {
    ⟨file⟩ ← 𝕩
    ⟨node,Dump,Disp⟩⇐Defaults "require"‿{⟨𝕏file⟩} ⋄ Scope⇐Oper⇐NonLocal⇐⊢
    Eval ⇐ {𝕊: program.Require file.Eval@}
  }
  Body ⇐ {
    statements←𝕩
    Visit←{⟨𝕏¨statements⟩}
    ⟨node,Dump,Disp⟩⇐d←Defaults "body"‿visit
    N←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}}
    Oper⇐{ d.Oper operator.NewScope N 𝕩 }
    sc←@ ⋄ Scope⇐{ d.Scope sc ↩ scopes.New N 𝕩 }
    Eval⇐{ ¯1⊑⊑d.Eval (sc.Names@) env.New N 𝕩 }
  }

  LazyLabel ← {𝕤
    label ⇐ 𝕩
    GotoC ⇐ {
      label functions.Label⍟(@⊸≡)↩
      GotoC ↩ {𝕩 𝕨◶functions.GotoF‿functions.Goto label}
      𝕨GotoC𝕩
    }
  }
  CondNode ← {
    terms ← 𝕩
    name‿_ev ← 𝕨 ⋄ Eval⇐terms _ev
    Visit←{⟨name,𝕏¨terms⟩}
    ⟨node,Dump,Disp,Scope⟩⇐d←Defaults "cond"‿visit
  }
  CondEval ← {
    "cond"≡𝕨.node ? 𝕨.Eval 𝕩 ;
    n𝕊⟨jv‿label,e⟩:
    c ← n.Eval e
    { IsTyped c ? jv label.GotoC c ⋄ ¬jv ; numbers.GetBool c }
  }
  CAccum ← {𝕊id: {
    ⟨jv‿label,e⟩←𝕩
    l ← LazyLabel@
    i ← (⊑𝕗) CondEval ⟨¬id,l⟩⌾⊑⍟(id=jv) 𝕩
    c ← (1⊑𝕗) CondEval⟜𝕩⍟((¬id)≢⊢) i
    functions.SetLabel⍟(@⊸≢) l.label
    c
  }}
  condNodes ← ⟨
    { name⇐"not" ⋄ infix⇐0 ⋄ _ev ⇐ { ¬ (⊑𝕗) CondEval ¬⌾(⊑⊑)𝕩 } }
    { name⇐"and" ⋄ infix⇐1 ⋄ ev ⇐ CAccum 1 }
    { name⇐"or"  ⋄ infix⇐1 ⋄ ev ⇐ CAccum 0 }
  ⟩
  CO ← {𝕊n: bind⇐¯∞⋄R⇐⊢⋄null‿left⇐n.infix⌽{V⇐n˙ ⋄ T⇐¯∞<{𝕩.bind}}‿@}
  condOp ⇐ ({𝕩.name}¨ {𝕨⊸⊐⌾< =⟜(≠𝕨)◶⟨⊑⟜𝕩,@⟩ ⊢} CO¨) condNodes
  If ⇐ {
    ⟨cond,then,else⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏cond,𝕏then,𝕏¨else⟩}
    ⟨node,Dump,Disp,Scope⟩⇐Defaults "if"‿visit
    IfLabel←LazyLabel
    Oper ⇐ { cond.Oper operator.CondScope 𝕩 ⋄ {𝕏then⋄𝕏¨else}o.Oper 𝕩 ⋄ operator.nil }
    Eval ⇐ {
      lf ← IfLabel@
      c ← cond CondEval ⟨0‿lf, e←𝕩⟩
      { @≢lf.label ?
        then.Eval e
        functions.Goto¨ lt ← functions.Label¨ else
        functions.SetLabel lf.label
        lt { 𝕩.Eval e ⋄ functions.SetLabel 𝕨 }¨ else
        {Shows⇐!∘"Can't use runtime if statement result as value"⋄kind⇐"error"}
      ;
        numbers.GetBool c ? then.Eval e ;
        r ← {Shows⇐!∘"Can't use if-0 statement result as value"⋄kind⇐"error"}
        r ⊣´ { 𝕩.Eval e }¨ else
      }
    }
  }
  TopIf ⇐ {
    ⟨cond,then,else⟩←𝕩 ⋄ pos←𝕨 ⋄ NonLocal⇐⊢
    Visit←{⟨𝕏cond,𝕏¨then,𝕏¨else⟩}
    ⟨node,Dump,Disp⟩⇐Defaults "topif"‿visit ⋄ Scope⇐Eval⇐!
    Oper⇐{
      # Latest we can evaluate condition without scope circularity, so do it now
      lf ← { label⇐@ ⋄ GotoC⇐{𝕊:!program._trace_ pos"Dynamic top-level if statement unsupported"} }
      cond.Oper operator.CondScope 𝕩
      c ← {𝕨 CondEval ⟨0‿lf, 𝕩⟩}ast._runIfCond cond
      body ← c ¬⊸⊑ then‿else
      ⟨Scope,Eval⟩ ↩ d ← Defaults "topif"‿{⟨𝕏¨body⟩}
      d.Oper 𝕩
      operator.nil
    }
  }
  While ⇐ {
    ⟨testFirst,cond,stmt⟩←𝕩
    Visit←{⟨𝕏cond,𝕏stmt⟩}
    ⟨node,Dump,Disp,Scope⟩⇐Defaults "while"‿visit
    Oper ⇐ { cond.Oper operator.CondScope 𝕩 ⋄ stmt.Oper 𝕩 ⋄ operator.nil }
    Eval ⇐ {
      functions.Goto¨ lc ← functions.Label¨↕testFirst
      functions.SetLabel lt ← functions.Label@
      stmt.Eval 𝕩
      functions.SetLabel¨ lc
      functions.Goto∘lt⍟(1≡⊢) cond CondEval ⟨1‿(LazyLabel lt), 𝕩⟩
      {Shows⇐!∘"Can't use while statement result as value"⋄kind⇐"error"}
    }
  }

  n0 ← Word "0"
  For ⇐ {
    ⟨fn,ptrs,ind,from,to,body⟩←𝕩 ⋄ pos←𝕨
    ptri←pos⊸Ident¨ptrn←⊑¨ptrs
    ptrv←ptrs(1⊑∾⟜<)¨ptri
    from↩n0⊣´from
    vardisp←1↓∾(","⊸∾¨ptrn)∾" over "⊸∾¨ind
    Visit←{⟨𝕏fn,vardisp⊣𝕏¨ptri≍˘ptrv,𝕏from,𝕏to,𝕏body⟩}
    ⟨node,Dump,Disp,Oper⟩⇐d←Defaults "for"‿visit
    ls←@
    Scope ⇐ {
      (o.Scope 𝕩)¨ ∾⟨fn⟩‿ptrv‿⟨from,to⟩
      ls ↩ (<pos) {𝕏}∘𝕩.Get¨ "load"‿"store"
      body.Scope scopes._defer (ind∾ptrn) scopes.New 𝕩
    }
    Eval ⇐ {
      e←o.Eval 𝕩
      For←(E fn) program._trace_ pos
      lsv←var.Get∘{𝕎𝕩}⟜𝕩¨ ls
      For ⟨E¨ptrv, E from, E to, blocks.New ind‿ptrn‿body‿lsv‿𝕩⟩
    }
  }
}

files ← {
  path←@ ⋄ log←⟨⟩
  Load ← {
    path ↩ (∨`⌾⌽'/'⊸=)⊸/ 𝕩
    ast.Build •file.Chars 𝕩
  }
  lib ← ('/'∾˜⍟(≠⟜(¯1⊸⊑))⌾⊑¨libpaths)∾<⟨"","include/"⟩
  Include ⇐ {
    search ← (≠↑𝕩˙)⊸≡∘⊑¨⊸/ ('.'=⊑𝕩) ⊑ ⟨lib,⟨""‿path⟩⟩
    Get ← {pre‿path𝕊𝕩: path •file.At pre ≠⊸(⊢↓˜⊣+'/'=⊑) 𝕩}⟜(𝕩∾".singeli")
    f←@ ⋄ {f≡@? •file.Exists ft←Get𝕩? f↩ft; @}¨ search
    Report ← {" (searched "∾"and Singeli library)"∾˜∾⥊(Get¨¯1↓𝕩)∾˘<", "}
    Err∘((1<≠)◶""‿Report∘search⊸(∾˜)⌾⊑)⍟(f≡@) "File not found"‿𝕨
    log ∾↩ <f
    op←path ⋄ a←Load f ⋄ path↩op ⋄ a
  }
  Build ⇐ { log↩⟨⟩ ⋄ Load 𝕩 }
  WriteDeps ⇐ { @≢𝕩 ? 𝕩 •file.Lines log ; @ }
}

ast ← {
  Show ⇐ {•Out ∾∾⟜lf¨ 𝕩.Disp @}
  baseScope ← builtins.names scopes.New scopes.Init@
  baseEnv   ← builtins.values env.Fixed @
  Build ⇐ Parse∘Tokenize
  Compile ⇐ {
    t ← files.Build 𝕩
    t.Oper operator.NewScope operator.nilScope
    files.WriteDeps 𝕨
    t.Scope scopes._run sc ← scopes.New baseScope
    t.Eval program._with (sc.Names@) env.New baseEnv
  }
  _runIfCond ⇐ { # For top-level if condition
    𝕩.Scope scopes._run baseScope
    e←@ ⋄ {e↩𝕩}∘(𝕩⊸𝔽) program._with baseEnv ⋄ e
  }
}

(∾∾⟜lf¨) ast.Compile
