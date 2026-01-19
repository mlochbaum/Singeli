cpu‿libpaths‿configs‿⟨ShowOut,ErrOut,ErrExit,DepOut⟩ ← •args

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
  da←»⊸≠«⊸∨»⊸∧𝕩='.'                         # >1 dots group alone
  k∨↩da<∨´(»⊸∧k<𝕩⊸∊)¨wc‿oc                  # Group names, numbers, and ops
  bt←(⌈`↕∘≠×¬)k ⋄ xd←𝕩∊dig
  k∨↩»⊸∨(»(bt⊏xd)∧𝕩='e')∧(𝕩='-')∧«xd        # Negative exponents 12e-3
  ts←(n∧b)∨¬k∨ign                           # Token start mask
  lc←(1+/𝕩=lf){(⊢⋈¨𝕩-⊏⟜(0∾𝕨))𝕨⍋𝕩}/ts        # Line/column numbers
  ⟨𝕩⊔˜1-˜(ign>≠`ab∧s∨d)¬⊸×+`ts, 𝕨 Source 𝕩‿lc⟩
}

# Position handler for error reporting
Source ← { 𝕨 𝕊 src‿lc: file←𝕨⊣""
  { pos 𝕊 disp:
    r‿c←<˘⍉>pos⊏lc
    ErrOut ∾⟨file, ":", •Repr 1+e←¯1⊑r, ":"⟩
    ErrOut src/˜(src=lf)(⊣<+`⊸=)e
    Tr ← {
      e ← (+`(𝕩≤¯1»𝕨≠⊸+¨𝕩))⊔𝕩⋈¨𝕨
      p ← "^"⍟(∧´0=≠¨𝕨)"|" # No names indicates multi-location runtime error
      l ← "^"⌾(1⊑¯1⊑⊑) ⌽ p⌾(1⊸⊑)¨⊸∾` (1+≠e)↑e
      {∾((-⟜»𝕨)∾≠¯1⊑𝕩)↑¨""<⊸∾𝕩}˝∘⍉∘>¨ l
    }
    ErrOut¨ ¯1↓⍟(∧´' '=⊑) disp Tr○((r=e)⊸/) c
  }
}
DispSource ← @⊸≢◶⟨ErrOut¨∘"(unknown position!)"‿"", {𝕎𝕩}´⟩
Err ← { (𝕩≠⊸⥊ErrOut‿DispSource) {𝕎𝕩}¨ 𝕩 ⋄ ErrExit@ }

AsrtGotGen ← {𝕊 disp: {𝔽𝕩 ? 𝕩 ; !∾⟨𝕎𝕩," (got ",Disp𝕩,")"⟩}}
_asrtGotR‿_asrtGotS ← AsrtGotGen¨ •Repr‿{Show𝕩}

# Parameter checks for builtins (_p1 and _p2 to use BQN monad/dyad)
_e1 ← {𝔽⊣"Expected one parameter"  1⊸=_asrtGotR ≠} ⋄ _p1←{𝔽⊑_e1}
_e2 ← {𝔽⊣"Expected two parameters" 2⊸=_asrtGotR ≠} ⋄ _p2←{𝔽´_e2}
_e3 ← {𝔽⊣"Expected three parameters" 3⊸=_asrtGotR ≠}
_v1 ← {𝔽⊣"Expected at least one parameter"  1⊸≤_asrtGotR ≠}
_v2 ← {𝔽⊣"Expected at least two parameters" 2⊸≤_asrtGotR ≠}
_m1 ← {𝔽⊣"Expected at most one parameter" ≤⟜1 _asrtGotR ≠}

# Error messages for generator matching
ErrParams ← { ErrOut 𝕨 ⋄ ! "Parameters: "∾(0<≠)◶⟨"none",ShowMulti⟩ 𝕩 }
_errNoMatch ← { ((∾⟜": "⍟(0<≠)𝕨)⊢⊘∾"No matching "∾𝕗) ErrParams 𝕩 }

numbers ← {kname⇐"number"
  f ← •Import "float2.bqn"
  NN ← 1≠•Type  # Not native number
  Is ← kname≡{Kind𝕩}
  Wrap ← {
    kind⇐kname⋄value⇐𝕩⋄Matches⇐Match⋄Shows⇐FmtLarge∘𝕩
    Matchable ⇐ {𝕊:matchable↩(0≠⊢´)◶⊑‿<value} # Matches as hi or <hi‿lo
  }
  Unwrap ← {
    6=•Type𝕩 ? kname≡𝕩.kind ? 𝕩.value ;
    (𝕨⊣"Expected constant number") 0 _asrtGotS 𝕩
  }
  Promote ← NN◶f.To‿Unwrap
  GetFloat ⇐ f.From∘Unwrap⍟(NN⊢)
  _getter_ ← {(𝕘∾" expected")⊘⊣ 𝔽_asrtGotR GetFloat}
  GetBool ⇐ ⊑∘∊⟜0‿1 _getter_ "Boolean"
  GetNat  ⇐   |∘⌊⊸= _getter_ "Natural number"
  GetInt  ⇐     ⌊⊸= _getter_ "Integer"
  Match ⇐ ∧○Is◶⟨0,≡○Promote⟩

  _cn ← {𝔽 ⊣ "Ill-formed number"!·∧´'0'⊸≤∧≤⟜'9'}
  Nat ← •ParseFloat _cn
  LC ← +⟜(32×1="A["⊸⍋) '_'⊸≠⊸/  # Lowercase, underscores removed
  da ← dig∾'a'+↕26
  Read ⇐ {
    (≠𝕩)>s←⌊´𝕩⊐"bx" ? # Base n with 0x9abc or 31bNUMBER
      b ← ('b'=s⊑𝕩)◶⟨16⊣"x can only appear in 0x in a number"!"0"⊸≡,Nat⟩ s↑𝕩
      "Invalid base (min 2)" ! 2≤b
      (!"Invalid base (max "∾•Repr∾")"˙)⍟(b⊸>) ≠da
      d ← b 𝕎 (b↑da) (≠∘⊣(⊢⊣"Invalid digits"!∧´∘>)⊐) (1+s)↓𝕩
      E ← b⊸×⊸+˜´⌽∘⊢
      EE ← {h‿l←f.To∘E¨𝕨-⊸(↓⋈↑)𝕩⋄Wrap l f.Add (f.To b⋆𝕨)f.Mul h}
      (⌊53÷2⋆⁼b) <⟜≠◶E‿EE d
    ;
      _n ← {('-'=⊑)◶⟨𝔽, -∘𝔽 1⊸↓⟩}
      pe ← ⊑𝕩⊐'e' ⋄ e ← pe (2⌊-˜⟜≠)◶⟨0,!∘"Empty exponent",Nat _n+⟜1⊸↓⟩ 𝕩
      m ← pe↑𝕩 ⋄ m /˜↩ ¬dm←m='.'
      (0≠⊢´)◶⟨⊑,Wrap⟩ (e - (≠m)-⊑dm⊐1)⊸f.ParseDec _cn _n 10 𝕎 m
  }{
    # Pass digit repeater as 𝕎
    ∨´m←𝕩∊c←"rdw" ? # r repeat; d total digits; w total bits
    ∨´m>↩∨`𝕩∊"bx" ? # Not part of the digit stream
      f ← {(𝕩×≠)⊸Re⊢}‿{𝕩⊸Re}‿{𝕩_wf} ⋄ Re←{𝕨⊸⥊⌾⌽𝕩}
      "Empty segment after digit repetition prefix"!¬∨´m∧1«m
      p ← 𝕩⊔˜(¬×1+`⊢)m  # ⟨codes, ...counts, rest⟩
      n ← Nat¨ ¯1↓1↓p   # Parsed counts
      wfm←"Repetition with w requires the base to be a power of two"
      _wf←{b n _𝕣 𝕩: wfm!⌊⊸=l←2⋆⁼b ⋄ (l|n) 2⊸⋆⊸|⌾⊑⍟(≠⟜0) (⌈n÷l) Re 𝕩 }
      rep←{∧´0=n ? "0" ; # 𝔽 assumes >0 digits
        mm←"Digit repetition prefixes don't agree"
        (1<≠)◶⊑‿{(⊑⊣mm!⊣`⊸≡)𝕩{𝕨𝕩{𝕨𝕏𝕗}¨𝕗}} n{𝕎𝕩}¨˜f⊏˜c⊐⊑p
      }
      rep 𝔽 ⊢´p
    ;
      {⊢} 𝔽 𝕩
  }⟜LC⎊{Err⟨•CurrentError@,𝕨⟩}

  InRange ← {1=⊑0⍋˜-˜´⟜(⌽𝕨)¨𝕩}
  FmtFloat ← ('¯'(⊢+=×'-'-⊣)•Repr){(∞>|)◶⟨"/0"∾˜·𝔽0(<->)⊢,𝔽⟩}
  MakeFmt ← {𝕊 Abs‿InRange‿ToSmall‿ToLarge: {
    ⌊⊸≡𝕩 ? (a←Abs 𝕩) InRange 2⋆48‿64 ? 𝕩 InRange -⌾⊑2⋆63‿64 ?
      ((𝕩≢a)/"-")∾"0x"∾da⊏˜⌽ 16‿16 f._repr ToLarge a ;
    FmtFloat ToSmall 𝕩
  }}
  FmtSmall‿FmtLarge ← MakeFmt¨ ⟨
    ⟨|,     1=⊑∘⍋˜,  ⊢,   f.To⟩
    ⟨f.Abs, InRange, f.From, ⊢⟩
  ⟩
  Fmt ⇐ FmtSmall

  Cast ⇐ {'f'‿l𝕊n:1; q‿l𝕊n: # 1 if valid; error otherwise
    n NN◶⋈‿Unwrap↩ ⋄ a←AsrtGotGen {•Repr+´}
    "Can't cast float to integer" ⌊⊸≡_a n
    "Constant doesn't fit" (n InRange -⟜(1⊸⊑÷2˙)⍟(q='i') ⟨0,2⋆l⟩)_a n
  }
  _cmp ⇐ {(f.Cmp 𝔽 0˙)○Promote}
  builtins ⇐ {
    W←Wrap ⋄ P←{𝕊:Promote𝕩 ; 𝕊⁼:W𝕩}
    E←f.To 2⋆GetFloat
    # B gives ⟨sign, 2's complement bits⟩
    Comp←(f.To ¯1)⊸f.Sub ⋄ IsNeg←0>f.Cmp⟜(f.To 0)
    B←≠`∘(f.Bits∘{𝕊⁼:𝕨𝕊𝕩;𝕊:Comp⍟𝕨𝕩}`)∘{𝕊⁼:1⊑𝕩;𝕊:⟨IsNeg𝕩,𝕩⟩}∘P
    [pr,val] ← ⍉[
      ({NN◶⟨𝕎,W∘𝕏○Unwrap⟩}´)‿⟨"neg"‿⟨-,f.Neg⟩, "abs"‿⟨|,f.Abs⟩,
                              "floor"‿⟨⌊,f.Floor⟩, "ceil"‿⟨⌈,f.Ceil⟩⟩
      ⊢          ‿⟨"not"‿(¬GetBool)⟩
      {𝕏⌾P}      ‿⟨"add"‿f.Add, "sub"‿f.Sub, "mul"‿f.Mul, "div"‿f.Div, "mod"‿f.Mod⟩
      {⊣⍟(𝕏_cmp)}‿⟨"min"‿≤, "max"‿>⟩
      {W P⊸𝕏⟜E}  ‿⟨"shl"‿f.Mul, "shr"‿(f.Floor f.Div)⟩
      {𝕏⌾B}      ‿⟨"and"‿∧, "or"‿∨, "xor"‿≠⟩
    ]
    arg ← 2‿4/{𝕏_p1}‿{𝕏_p2}
    ⍉>∾ (arg {𝕎∘{𝕏⚇0}∘𝕏}¨ pr) {⟨"__"⊸∾,𝕎⟩⊸({𝕎𝕩}¨)¨𝕩}¨ val
  }
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
  NewFunction ⇐ {𝕊: r←𝕨 ⊢⊘Union next ⋄ next↩init ⋄ r }
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
  Dec  ⇐ {𝕤⋄i-↩1}
}

Parse ← {𝕊 tokens‿ShowTrace:
  sep ← ⟨";", ⥊lf⟩
  ! ⊑ (¯1⊏tokens) ∊ sep

  keywords ← "include"‿"config"‿"local"‿"if"‿"if_inline"‿"else"‿"while"‿"do"‿"match"‿"extend"‿"def"‿"fn"‿"main"‿"oper"‿"in"‿"over"‿"from"‿"to"‿"and"‿"or"‿"not"
             kInclude ‿kConfig ‿kLocal ‿kIf ‿kIf_inline ‿kElse ‿kWhile ‿kDo ‿kMatch ‿kExtend ‿kDef ‿kFn ‿kMain ‿kOper ‿kIn ‿kOver ‿kFrom ‿kTo ‿kAnd ‿kOr ‿kNot ← ↕≠keywords

  Asrt ← {𝕨𝕊1:@;
    [v, k] ← (<"") ∾˘´ {𝕩⊸•ns.Get¨⊸≍ •ns.Keys 𝕩}¨ c‿tc
    ShowTrace⟜(v⊸⊐ ⊏ k˙)´ <˘⍉>DumpStack@
    ErrOut ""
    F ← (⥊lf)⊸≢◶⟨"end of line", =◶⟨"keyword "∾•Repr∘⊑⟜keywords, •Repr⟩⟩
    ErrOut {∾"Expected "‿𝕨‿" but saw "‿𝕩}⟜F´⍟(1<≡) 𝕨
    ErrExit@
  }
  MakeTokStream ← {
    i←⊐𝕩 ⋄ u←keywords{𝕗⊸⊐⊣⍟(<⟜(≠𝕗))¨⊢}𝕩/˜i>¯1»⌈`i
    ⟨Inc⇐Next,PeekRaw⇐Peek⟩←⟨Pos,Rem,Back⇐Dec⟩⇐MakeStream i
    PeekRaw ↩ PeekRaw ⊣ "File ended unexpectedly" Asrt Rem
    Peek ← ⊑⟜u∘PeekRaw
    Try  ⇐ 1∘Inc⍟⊢ Peek⊸≡
    Get  ⇐ Inc (•Repr⊸⋈ Asrt 0˙)⍟≢⟜Peek
    # Faster tests on raw tokens
    _test ⇐ {(𝔽¨u)⊑˜PeekRaw}
    first←⊑¨u
    _begin_ ⇐ {t←𝔽 first ⋄ Inc ⊢ (⊑⟜u (⊣ ⊣ 𝕘⊸⋈⊸Asrt) ⊑⟜t)∘PeekRaw}
    GetS ← ⊢ {Inc (((•Repr𝕨)⋈⊑⟜u) Asrt 0˙)⍟(𝕩⊸≢)∘PeekRaw}¨ u⊸⊐
    _seq ⇐ {a←3≠•Type¨𝕗 ⋄ (¬a)/{𝕏@}¨∘(GetS⌾(a⊸/)𝕗) }
    _opt_ ⇐ {@_𝕣_𝕘:
      t‿c ← (1⌾(¯1⊸⊑)2|↕∘≠)⊸⊔ 𝕘
      exp ← "one of "∾∾⟜", "⊸∾´•Repr¨t
      (⊑(u⊐t)⊐PeekRaw)◶(c∾⟨(exp⋈Peek) Asrt 0˙⟩)
    }
    _optGet_ ⇐ {@_opt_({𝕏⊣Inc}¨⌾((2|↕∘≠𝕘)⊸/)𝕘)}
    _any ⇐ {⊑(u⊐𝕗)∊˜PeekRaw}
    _anyTry ⇐ {1∘Inc⍟⊢∘(𝕗_any)}
  }
  ⟨Get,Try,Rem,Pos,Back,_test,_begin_,_seq,_opt_,_optGet_,_anyTry,_any⟩ ← MakeTokStream tokens

  # Node creation and error tracking
  c ← nodes ⋄ tc ← targetNodes
  ⟨_whileParse_⇐_while_, DumpStack⇐Arr⟩ ← MakeStack@
  _node_ ← {p←Pos@ ⋄ (ShowTrace⟜(""¨)⥊∘⊢)‿p 𝔽 𝔾_whileParse_⟨p,𝕗⟩ 𝕩}
  AsrtHere ← {𝕨 Asrt _whileParse_ ⟨Pos@,""⟩ 𝕩}

  When  ← {Test‿Cont:       ( ⥊∘< Cont)⍟Test   ⟨⟩  }
  While ← {Test‿Cont‿init: {(𝕊∾⟜<⟜Cont)⍟Test𝕩} Cont¨↕init}

  _ifASCII ← {(@+128)⊸≤∨𝔽}
  Name ← ∊⟜alph _begin_ "name"
  Oper ← ∊⟜oc _ifASCII _begin_ "operator"
  Symbol ← c.symbol _node_ ('''⊸=_begin_"symbol")
  IsLogic ← ∊⟜kAnd‿kOr‿kNot

  LFs ← {𝕊⍟Try ⟨lf⟩}
  Div ← {LFs@ ⋄ 1∘LFs⍟⊢ Try 𝕩}  # Divider, allowing surrounding newlines
  TrySep ← sep _anyTry
  Seps ← {Rem@ ? TrySep@ ? 𝕊𝕩⋄1 ; 0}

  _decl_ ← { 𝔽"Declaration" ⋄ Declare 𝔾 𝕩 }
  _exprStmt ← {AsrtStmt _𝕣: @_opt_⟨
  kIf,     { StIf 𝕩 }
  kWhile,  { StWhile 𝕩 }
  kDo,     { DoWhile 𝕩 }
  kMatch,  { Options 𝕩 }
  "@",     { For 𝕩 }
  kExtend, { Extend 𝕩 }
  kDef,    { Define 𝕩 } ⊣ AsrtStmt∘"def"
  kFn,     { DefFun 𝕩 } ⊣ AsrtStmt∘"fn"
  kMain,   { DefMain𝕩 } ⊣ AsrtStmt∘"main"
  kOper,   { OpDef 𝕩 }  ⊣ AsrtStmt∘"oper"
  "{",     @_optGet_⟨"=>", c.lambda _node_ (⋈⟜{Block𝕩})
                     ":",  AsrtStmt _decl_ ⊢           ⟩ {Params𝕩}
           { AsrtStmt _decl_ ToId⍟(Try":") SimpExpr 𝕩 }
  ⟩}
  Expr ← (∾⟜" must appear on its own line" Asrt 0˙) _exprStmt
  Stmt ← ⊢ _exprStmt

  Vec ← c.run _node_ (c.word∘"__vec" ⋈ "["‿Expr‿"]"‿{CallablePhrase𝕩} _seq)
  ParEx ← ⊑ "("‿Expr‿")" _seq
  EWord ← c.token _node_ (⊑⟜keywords⍟(¬=) (IsLogic∨∊⟜('''∾wc∾oc)_ifASCII) _begin_ "expression")
  Expr0 ← @_opt_⟨"[",Vec, "(",ParEx, EWord⟩

  _spreadable ← {<∘⊢⍟⊣⟜𝔽∘Try∘"..."}
  _args ← {𝕗 _argsFn_ (Expr _spreadable)}
  _divList ← {Div∘"," _and_ (𝕗⊸≢_test)}
  _argsFn_ ← {𝕤
    Get ⊑𝕗
    LFs@
    Try 1⊑𝕗 ? ⟨⟩ ;
    a ← While ⟨(1⊑𝕗)_divList, 𝔾, 1⟩
    Get 1⊑𝕗
    a
  }
  NoPar ← (sep∾","‿"}")_any
  ParC ← {𝕤 # Parameter in call
    s ← Try "..."
    p ← s◶⟨Try∘".", NoPar⟩ @  # Partial application
    <⍟s Expr⍟(¬p) @
  }
  err_ex_gather ← "At most one variable-length parameter allowed"
  ParCs ← ⊢ ⋈ · (err_ex_gather Asrt 1≥·+´(<@)⊸≡¨)⊸⊢ "{"‿"}"_argsFn_ ParC
  AddParams ← @_opt_⟨"{", {AddParams∘(c.run  _node_ ParCs           ) 𝕩}, ⊢⟩
  AddArgs   ← @_opt_⟨"(", {          (c.call _node_ (⊢⋈"("‿")"_args)) 𝕩}, ⊢⟩
  Callable ← AddParams∘Expr0
  CallablePhrase ← c.phrase _node_ (⋈Callable)
  CanCall ← (¬ =◶⟨IsLogic⌾<, ∨´(oc∾"[")=⊏⟩) _test
  StartsOp ← =◶⟨IsLogic⌾<, ⊑∘∊⟜oc _ifASCII∘⊑⟩ _test
  Call ← { c←CanCall @ ⋄ AddArgs⍟c Callable𝕩 }

  ExprFromEnd ← {𝕊 endTok:
    End ← (endTok∾sep∾⥊¨",:)}]")_any
    {
      o ← StartsOp 𝕩
      Cont ← {p←o ⋄ p∨o↩StartsOp 𝕩}_and_(¬End)
      c.phrase _node_ (While∘⟨Cont, Call, 1⟩) 𝕩
    }
  }
  SimpExpr‿TypeExpr ← ExprFromEnd¨ ⟨⟩‿⟨"="⟩

  # 𝕩 is the expression preceding ":"
  Declare ← c.declare _node_ {
    n ← 𝕩
    t ← When ⟨¬Try"=", Get∘"=" ⊢ TypeExpr⟩
    ⟨n,t,Expr@⟩
  }
  ToId ← {"Unexpected "":"""AsrtHere@≢𝕩 ⋄ 𝕩.IsDef@⋄𝕩} c.PhraseTryWord

  _lines_ ← { Line _𝕣_ Cont 𝕩:
    Seps @ ⋄ s ← 1
    SepLine ← {"Expected separator" AsrtHere s ⋄ l←Line𝕩 ⋄ s↩Seps@ ⋄ l}
    While ⟨Cont, SepLine, 0⟩
  }
  _blockLines ← { ⊑ ⟨"{", 𝔽 _lines_ (¬Try∘"}")⟩_seq }
  Body ← Stmt _blockLines
  Block ← @_opt_⟨"{",c.body _node_ Body, Expr⟩

  AnyIf ← ⟨kIf, kIf_inline⟩_anyTry
  _if ← {
    TrySeps ← {s←Seps@ ⋄ Back⊸⊢⍟(s>⊢) Rem◶0‿Try 𝕩}
    1↓ AnyIf‿"("‿Expr‿")"‿𝔽‿(When∘⟨TrySeps∘kElse,𝔽⟩)_seq
  }
  StIf ← c.if _node_ (Block _if)
  StWhile ← c.while _node_ (1 ∾   kWhile‿"("‿Expr‿")"‿Block _seq)
  DoWhile ← c.while _node_ (0 ∾⟜⌽ kDo‿Block‿kWhile‿"("‿Expr‿")" _seq)

  Option ← @_opt_⟨
    "{", c.lambda _node_ {Params‿"=>"‿Block _seq 𝕩}
    "(", c.extgen _node_ ParEx
  ⟩
  Options ← c.options _node_ {𝕤
    Get kMatch
    a ← @_opt_⟨"(", ⋈"("‿")"_args, ⟨⟩⟩ @
    m ← Option _blockLines @
    a‿m
  }

  For ← c.for _node_ {𝕤
    OA← "@for: pointers must be followed by ""over"""⊸AsrtHere
    OW← "@for: pointer (indicated by ""in"") must be followed by ""over"""⊸AsrtHere
    TA← "@for: ""from"" missing ""to"""⊸Asrt
    NA← "@for: loop variable must be a name"⊸Asrt
    Get "@"
    f ← CallablePhrase@
    Get "(" ⋄ LFs@
    to← Expr@
    NE← {𝕤⋄ n←⋈∘{NA@≢𝕩⋄𝕩}∘c.PhraseTryName⍟𝕩 to ⋄ to↩Expr@ ⋄ n}
    {Div kIn? to↩⟨⊑NE 1,to⟩; @}
    pe← While ⟨Div∘",", Div∘kIn◶⟨⋈,⋈⟜Expr⟩ Name, 0⟩
    ps← {Div kOver?(<NE 0==to)∾𝕩; OA 0=≠𝕩⋄OW 0==to⋄⟨⟩} pe # Pointers
    fr← When ⟨Div kFrom, Expr⟩                            # Start index
    i ← {¬Div kTo?TA 0=≠fr⋄⟨⟩; 0<=to?ps∾↩<NE 0⋄⟨⟩; NE 1}  # Index variable
    LFs@ ⋄ Get ")"
    b ← Block@
    ⟨f,ps,i,fr,to,b⟩
  }

  # 𝕩 indicates if preceding token was =
  Result ← c.body _node_ (@_opt_⟨
    "{", Body
    "@", ⋈For
         ⋈∘Expr "Missing = before body?"Asrt⊢
  ⟩)

  TargetList ← tc.list _node_ {𝕤
    Get "{"
    LFs@
    a ← {
      ∊⟜"}"‿kIf⌾<_test@ ? 0⥊<↕2 ;
      Param ← ⟨Try∘"...", TargetElem⟩_seq
      a ← While ⟨"}"_divList, Param, 1⟩ ⋄ err_ex_gather Asrt 1≥+´⊑¨a ⋄ a
    }
    c ← When ⟨Try∘kIf, Expr⟩
    Get "}"
    a‿c
  }
  # Target operations * : = == are all right-associative
  # 𝕩≡0 indicates = should not be parsed
  TargetElem ← =◶⟨0, ∧´'*'⊸=⟩_test◶⟨  # Multiple *s group as one token
    { (𝕩≡0)◶FinishTarget‿FinishDefTarget TargetAtom 𝕩 }
    tc.pointer _node_ {𝕤
      a ← '*'⊸=_begin_"" @
      tc.pointer⍟(1-˜≠a) TargetElem 𝕩
    }
  ⟩
  TargetAtom ← @_opt_⟨
    "(", tc.constant _node_ ParEx
    "[", tc.vector _node_ {"["‿TargetElem‿"]"‿(TargetElem∘𝕩) _seq @}
    "{", TargetList
    =◶⟨0, ⊑⊏∊(dig∾''')˙⟩_test◶⟨tc.name _node_ Name, tc.constant _node_ EWord⟩
  ⟩
  noDestruct ← "Type destructuring would shadow primitive type; add parentheses to use as constant"
  TypeTarget ← TargetElem ⊣ noDestruct Asrt ¬∘∊⟜(types.primTypes≠⊸↑builtins.names)⌾<_test
  _tAdd_ ← {@_opt_(⟨⊢⟩∾˜⥊{s‿n‿P: ⟨s, n _node_ (⋈⟜P ⊣ Get∘s)⟩}˘∘‿3⥊𝕘)}
  FinishTarget    ← @_tAdd_⟨kIf, tc.conds,     Expr⟩ @_tAdd_⟨
    ":",  tc.typed,  TypeTarget
    "=",  tc.same,   TargetElem
    "==", tc.equals, Expr
  ⟩
  # Can't handle = or expressions containing it; don't allow == out of caution
  FinishDefTarget ← @_tAdd_⟨kIf, tc.conds, TypeExpr⟩ @_tAdd_⟨
    ":",  tc.typed,  TypeTarget∘0
  ⟩
  Params ← c.target _node_ TargetList
  _withParams ← {
    Rec ← @_opt_⟨"{",c.lambda _node_ (Params‿{Rec𝕩} _seq), 𝔽⟩
  }
  IdTarget ← c.newId _node_ Name
  Target ← c.target _node_ (TargetElem∘0)

  Arg ← c.arg _node_ ((Try∘"...")‿Name‿":"‿Expr _seq)
  Function ← c.function _node_ {𝕤
    a ← "("‿")" _argsFn_ Arg @
    r ← When ⟨Try":", TypeExpr⟩
    b ← Result Try"="
    ⟨a,r,b⟩
  } _withParams
  DefFun ← c.define _node_ (kFn‿IdTarget‿Function _seq)
  DefMain ← c.main _node_ {𝕤
    Get kMain
    a ← @_opt_⟨"(","("‿")" _argsFn_ Name, ⟨⟩⟩ @
    "Main function can have at most two arguments" Asrt 2≥≠a
    RT ← "Main result must be void or i32" AsrtHere ∊⟜"void"‿"i32"⌾<
    r ← When ⟨Try":", RT⊸⊢ Name⟩
    b ← Result Try"="
    ⟨a,r,b⟩
  }

  ExtPar ← "{"‿"}" _argsFn_ Name
  Extender ← c.extender _node_ (ExtPar‿"="‿Body _seq)
  Extend ← c.extend _node_ (kExtend‿Expr0‿ExtPar _seq)

  GenRes ← ⊑⟨"=",Result∘1⟩_seq
  Value ← @_opt_⟨"=",GenRes, @⟩
  _trySeq←{n←≠s←𝕗 ⋄ n⊸=◶⟨0⊣Back⍟⊢,1⟩0{𝕗<n?@_optGet_⟨𝕗⊑s,(1+𝕗)_𝕣, 𝕗⟩; 𝕗}}
  Generator ← @_opt_⟨
    "{","{"‿"..."‿"}"_trySeq◶⟨GenRes _withParams, c.extgen _node_ Value⟩,
    Value
  ⟩
  # Decide how to parse definition value based on what's after def
  Valuator ← @_optGet_⟨kExtend,Extender˙, @_opt_⟨"{",Value˙,"_",Value˙,Generator˙⟩⟩
  Define ← c.define _node_ {𝕤
    Get kDef
    v ← Valuator @
    ⟨Target, V⟩_seq @
  }
  confName‿confVal ← (⊑¨⋈1⊸⊑¨)configs
  Config ← c.define _node_ {
    Get kConfig
    t‿r ← ⟨IdTarget, "=", Result∘1⟩_seq 𝕩
    n ← t.name
    t‿{ (≠confName) > i←confName⊸⊐⌾<n ? ("config "∾n) ast.Build i⊑confVal ; r }
  }

  OpType ← @_optGet_⟨
    "prefix", 'p'
    "infix",  @_optGet_(⟨'n'⟩∾˜∾⋈⟜⊑¨"none"‿"left"‿"right")
  ⟩
  Number ← c.number _node_ (∊⟜dig _begin_ "number")
  OpName ← @_opt_⟨"(",ParEx, Name⟩
  OpDef ← c.opDef _node_ (kOper‿Oper‿OpName‿OpType‿Number _seq)

  Include ← c.include _node_ (kInclude‿Symbol _seq)

  MultiLine ← {Line𝕩} _blockLines
  TopIf ← c.topif _node_ (∾⌾(¯1⊸⊑) @_opt_⟨"{",MultiLine, ⋈{Line𝕩}⟩ _if)
  SubLine ← @_opt_⟨kInclude,Include, kIf_inline,TopIf, kConfig,Config, Stmt⟩
  LocLine ← @_opt_⟨kIf_inline,"localizable line"‿kIf_inline AsrtHere 0˙, kIf,StIf, SubLine⟩
  Line ← @_optGet_⟨
    kLocal, @_opt_⟨"{",c.body _node_ MultiLine, LocLine⟩
            {𝕩.NonLocal@⋄𝕩}∘SubLine
  ⟩

  Program ← c.body _node_ (Line _lines_ Rem)

  Program @
}

operator ← {
  Parse ⇐ {
  ⟨op⟩ 𝕊 ⟨v⟩: v⊣´{𝕩.V v.pos}¨@⊸≢¨⊸/op.left‿op.null ;
  ops 𝕊 val:
    Peek‿Next‿Rem ← st ← MakeStream ops {null‿left‿bind‿R⇐𝕨 ⋄ value⇐𝕩}¨ val
    E ← {𝕊test: {𝕊∘{𝕩 LeD Next@}⍟(Test Peek)⍟Rem 𝕩} NuD Rem◶Mis‿Next@ }
    Run ← nodes.Run ⋄ P ← {𝕩.value.pos}
    NuD ← { 𝕩.null ≢⟜@◶{𝕩.value}‿{pos←P𝕩 ⋄ pos Run ⟨𝕩.R 𝕨.V pos, ⟨E 𝕨.t⟩⟩} 𝕩 }
    LeD ← { @≢l←𝕩.left ? pos←P𝕩 ⋄ pos Run ⟨𝕩.R l.V pos, ⟨𝕨, E l.t⟩⟩ ; Unk 𝕩.value }
    IsOp ← {"cond_oper"≡𝕩.node?1; "word"≡𝕩.node?∊⟜oc⌾<⊑𝕩.name?1; 0}
    Unk ← {
      ¬IsOp 𝕩 ? st.Dec⍟2@ ⋄ Err "Unknown prefix operator"‿(Next@).value.pos ;
      Rem@ ? Err "Unknown infix operator"‿𝕩.pos ; Mis@
    }
    Mis ← {𝕊: Err "Missing right operand"‿(¯1⊑val).pos }
    E 1
  }
  Run ⇐ {𝕨𝕊⟨op,params⟩:
    Par ← 𝕨 nodes.Run ⋈⟜params
    null‿left ⇐ {⟨T⟩⇐𝕩 ⋄ V⇐Par∘𝕩.V}⍟(@⊸≢)¨ op.null‿op.left
    bind‿R⇐op
  }
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
    Op ← {name 𝕊 V‿p‿c‿a: V⇐
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
    # include statements also resolved in the operator pass
    includes←⟨⟩ ⋄ AlreadyIncluded⇐{∊⟜includes⌾<𝕩 ? 1 ; includes∾↩<𝕩⋄0}
  }
  nilScope ⇐ { tabs ⇐ 2⥊{Get⇐nil˙} } # Lookup ⇐ nil˙
}


# Runtime
# Kinds are:
# - BQN values tuple (list), number, generator (function)
# - Classes symbols, types, registers, constants, functions, blocks
_and_ ← { 𝔽◶⟨0,𝔾⟩ }
IsTup ← 0=•Type
IsGen ← 3=•Type

_tsel ← {•Type∘⊣◶(¯1((↓»(6⥊⟨!∘"Unhandled kind"⟩)˙)∾↑)𝕗)}
Kind  ← ⟨"tuple","number",@,"generator",{𝕩.kind}⟩_tsel
Match ← {𝕨 ⟨≡○≢◶⟨0,∧´𝕊¨⟩, numbers.Match,≡,≡, {𝕨𝕨.Matches𝕩}⟩_tsel 𝕩}
# p Matches q if and only if p ≡○GetMatchable q
GetMatchable ← ⟨{GetMatchable¨ 𝕩}, ⊢,!,⊢, {⟨M⇐Matchable⟩:M@; !{≡}≡𝕩.matches⋄𝕩}⟩_tsel
IsTyped←∊⟜"register"‿"constant"‿"function"⌾< Kind
HasType ← IsTyped∘⊣ _and_ ({𝕩.type}⊸Match)
TypeOf← {⟨types.Tup 𝕊¨, {𝕩.Type@}⟩_tsel 𝕩}
Show‿Repr ← {
  UnEsc ← ⊢-128×(' '+128)⊸= # Non-breaking space to space
  FmtTup ← "tup{"∾"}"∾˜1↓·∾","⊸∾¨
  FmtFn ← {(𝕏˜@).name}⎊"(generator)"
  ReprObj ← {𝕩.Shows@}
  ObjType ← IsTyped◶0‿{𝕩.fmtType}◶""‿{":"∾Repr TypeOf𝕩}
  _ko ← {𝔽≡{𝕩.kind}}
  ShowSub ← "type"_ko◶ReprObj‿{𝕩.TypeShow@}∾ObjType
  ShowObj ← ShowSub⎊("error"_ko⎊0◶("("∾")"∾˜Kind⎊"unknown")‿ReprObj)
  EChar ← "(char "∾•Repr∘-⟜@∾", probably bug)"˙
  _disp_ ← {R←⟨FmtTup {R𝕩}¨, numbers.Fmt, 𝔾, FmtFn, 𝔽⟩_tsel}
  Show ⇐ UnEsc ShowObj _disp_ EChar
  Repr ⇐       ReprObj _disp_ !
}
ShowMulti ← 2↓·∾·", "⊸∾¨Show¨
_genNamed_ ← {N←{n↩𝕩}∘{name⇐𝕩}∘𝔾⋄𝔽⊘{𝕨N𝕩}}

types ← {kname⇐"type"
  New ← {k𝕊d:
    kind⇐kname
    typeKind‿dat⇐𝕨‿𝕩
    Shows‿TypeShow⇐{𝕏∘dat}¨typeKind⊑dispfns
    Matches⇐{𝕨Is∘⊢◶0‿Equiv𝕩}
    Matchable⇐{𝕊:matchable↩<⟨'t',TypeShow@⟩}
  }
  tVOID‿tPRIM‿tVEC‿tPTR‿tFUN‿tTUP ← ↕6
  TypeKind⇐{
    ReqTyp 𝕩
    𝕩.typeKind⊑"void"‿"primitive"‿"vector"‿"pointer"‿"function"‿"tuple"
  }
  dispfns ← {
    _v ← {{∾"["‿𝕨‿"]"‿𝕩}○𝔽´}             # Vector
    _t ← {1↓·∾(","⊸∾⍟(0<≠)𝔽)¨}           # Type tuple, bare
    _tt← {"tuptype{"∾"}"∾˜𝔽_t}           # and for display
    _f ← {("("∾")"∾˜𝔽_t)⊸{∾𝕨‿"->"‿𝕩}⟜𝔽´} # Function args
    {Repr‿Show{d←𝕩⋄𝕨_d}⍟(4=•Type∘⊢)¨𝕩}¨ ⟨
      <"void"    # Void:                     void
      ∾⟜•Repr´   # Primitive:   qual‿len     u8
      _v         # Vector:      count‿t      [4]…
      {"*"∾𝔽}    # Pointer:     t            *…
      _f         # Function:    ⟨q‿r‿s, t⟩   (…,…,…) -> …
      _t‿_tt     # Tuple:       q‿r‿s        …,…,…   /  tuptype{…,…,…}
    ⟩
  }
  IsVoid ⇐ {tVOID≡𝕩.typeKind}

  void ⇐ tVOID New ⟨⟩
  primTypes ⇐ void ∾ tPRIM New¨ qw ← ∾⋈¨¨˝⍉ ∘‿2⥊⟨
    'u', 2⋆0∾3+↕4  # 1/8/16/32/64
    'i', 2⋆  3+↕4  #   8/16/32/64
    'f', 2⋆  5+↕2  #        32/64
  ⟩
  _getPrim ← {{𝕏@} (⟨!∘𝕗⟩«primTypes) ⊑˜ qw⊸⊐⌾<}

  Is ← kname≡Kind
  ReqTyp ⇐ {"Expected type";𝕨∾" type wasn't type"˙} Is _asrtGotS ⊢
  Vec ← {n𝕊t:
    l ← "Vector size should be a constant integer" numbers.GetNat n
    "Vector" ReqTyp t
    tVEC New ⟨l,t⟩
  }
  Ptr ⇐ { 𝕊t: "Pointer" ReqTyp t ⋄ tPTR New t}
  Tup ⇐ { 𝕊t: !IsTup t ⋄ ReqTyp¨ t ⋄ tTUP New t}
  Fun ⇐ tFUN New ⋈
  _get⇐ {IsTup 𝕩 ? Tup 𝕊¨𝕩 ; 𝕗 ReqTyp 𝕩}

  _cases ← {
    Kind←{𝕩.typeKind} ⋄ Dat←{𝕩.dat}
    c ← ⌊‿2⥊𝕗
    k ← ⊏˘c
    d ← (1⊏˘c) ∾ ((≠⥊c)↓𝕗)»⟨!"Unhandled type "∾Repr⟩
    (k⊸⊐⌾< ⊢⊘(≠◶⊢‿¯1)○Kind)◶({𝕏○Dat}¨⌾((≠k)⊸↑)d) ⊣ @○ReqTyp
  }

  TypeErr ← {!∾⟨𝕨," (type was ",Repr 𝕩,")"⟩}

  Quality ← ⟨tPRIM,{symbols.New ⋈⊑𝕩}, "Expected primitive type"⊸TypeErr⟩_cases
  _isQual ← {⟨tPRIM,𝔽⊑,0⟩_cases TypeOf⍟IsTyped⍟(¬Is)}
  IsInt ⇐ ⊑∘∊⟜"iu"_isQual

  Unpack ⇐ ⟨tTUP,{Unpack¨𝕩},⊢⟩_cases
  Ungather ⇐ ⟨tTUP,⊢,"Gathered argument must have a tuple type"⊸TypeErr⟩_cases
  Deref ⇐ { Is 𝕩 ? tPTR=𝕩.typeKind ? 𝕩.dat ; "Expected pointer" TypeErr 𝕩 }
  TupFrom ⇐ { Is _and_ (tTUP≡{𝕩.typeKind}) _asrtGotS⟜(𝕩˙) 𝕨 ⋄ 𝕩.dat }
  UnFun   ⇐ { m←"Expected function type"
            m Is _and_ (tFUN≡{𝕩.typeKind}) _asrtGotS 𝕩 ⋄ ∾⟜<´ 𝕩.dat }
  TupTry ⇐ { Is 𝕩 ? tTUP≡𝕩.typeKind ? 𝕩.dat ; 𝕩 }
  Merge ⇐ {
    l ← (tTUP≡{𝕩.typeKind})◶<‿TupFrom¨ 𝕩  # Assume 𝕩 all types
    "Type parameters must include a tuple type" ! 0<⌈´=¨l
    Tup ∾ l
  }

  Width ← ⟨
    tPRIM, 1⊸⊑
    tVEC,  ×⟜{Width𝕩}´
    tTUP,  +´{Width𝕩}¨
    tPTR,  ptrWidth
    {!∾⟨"Can't find width of ",TypeKind𝕩," type ",Repr𝕩⟩}
  ⟩_cases

  VCount ← ⟨ tVEC,⊑, 1 ⟩ _cases
  VType ← ⟨ tVEC,1⊸⊑, tPTR,⊢ ⟩ _cases
  vecDecompParams ⇐ ⟨Is _and_ {tVEC≡𝕩.typeKind}, {𝕩.dat}⟩
  ptrDecompParams ⇐ ⟨Is _and_ {tPTR≡𝕩.typeKind}, {𝕩.dat}⟩

  FnCast ⇐ {
    args‿ret ← ⟨tFUN,⊢, "Calling non-function"⊸TypeErr⟩_cases 𝕨
    args (!"Expected "∾⊣∾" arguments, got "∾⊢)○•Repr⍟≢○≠ 𝕩
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
    L←¯1⊸⊑ ⋄ ≠○⊑◶⟨𝔽○L, ('f'≠⊑∘⊣)_and_('u'≠⊑∘⊢)_and_(<○L)⟩
  }
  Equiv    ← ≡          _typeRel_ @
  Subtype  ⇐ ≤ _cmpPrim _typeRel_ 1
  SSubtype ⇐ < _cmpPrim _typeRel_ 0

  _asCast ← {
    "Cast" ReqTyp 𝕨
    Fail ← {!∾⟨"Can't cast ",Kind𝕩," to ",Repr𝕨⟩}
    Num ← {t𝕊n:
      ⟨ tPRIM,numbers.Cast⟜n, Fail⟜n ⟩ _cases t
      t constants.New n
    }
    Cast ← 𝕊
    Tup ← {
      ptr ← 0
      c ← ⟨ tTUP,⊢, tPTR,{ptr↩1⋄𝕩}, Fail⟜𝕩 ⟩_cases⍟(0≠•Type) 𝕨
      𝕨 functions.Array⍟ptr c Cast¨ 𝕩
    }
    Obj ← ("number"≢{𝕩.kind})◶⟨Num,IsTyped∘⊢◶⟨Fail˜,𝔽⟩⟩
    # _tsel selects on 𝕨; swap to use 𝕩
    𝕨 ⟨Tup˜, Num˜, Fail˜, Fail˜, Obj˜⟩_tsel˜ 𝕩
  }
  _cc ← { Test‿Conv‿Fail _𝕣:
    (Conv ⊣ Fail○Repr⍟(¬Test˜)⟜TypeOf)⍟(¬Equiv⟜TypeOf)_asCast
  }
  Cast ⇐ ⟨
    0, !
    {!∾⟨"Explicit conversion required to change ",𝕩," to ",𝕨⟩}
  ⟩_cc
  Promote ← ⟨
    Subtype, {functions.Emit⟨𝕨, symbols.New "^promote", 𝕨, 𝕩⟩}
    {!∾⟨"Can't promote from type ",𝕩," to non-superset ",𝕨⟩}
  ⟩_cc
  Reinterpret ← ⟨
    ≡○Width, {functions.Emit⟨𝕨, symbols.New "^bitcast", 𝕨, TypeOf 𝕩, 𝕩⟩}
    {!∾⟨"Can't reinterpret type ",𝕩," as different-width type ",𝕨⟩}
  ⟩_cc
  IsBool ⇐ (tPRIM New 'u'‿1)⊸Equiv

  GetWidth ← "Type width must be a natural number"⊘⊣ numbers.GetNat ⊢
  IncWidth ← {
    n←"First parameter must be a type or natural number" GetWidth 𝕨
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
    e ← "Quality must be 'i', 'u', or 'f'"
    n ← e symbols.From 𝕩 ⋄ e!1=≠n
    ⊑n
  }
  PrimType ← "Invalid primitive type specification"_getPrim GetQual‿GetWidth {𝕎𝕩}¨ ⊢

  builtins ⇐ ∾˘⍉∘‿2⥊⟨
    ⟨"cast"   ,             "promote"   ,"reinterpret"⟩
    ⟨ Cast _p2,Is∘⊣◶IncWidth‿Promote _p2, Reinterpret _p2⟩
    ⟨"eltype"   ,"vcount"   ,"width"   ,"__vec"   ,"__pnt"⟩
    ⟨ VType _p1 , VCount _p1, Width _p1,   Vec _p2,   Ptr _p1⟩
    ⟨"primtype"   ,"quality","isfloat","issigned","isint"⟩
    ⟨ PrimType _e2, Quality _p1⟩∾{𝕩_isQual _p1}¨⟨'f'⊸≡ ⋄ 'i'⊸≡ ⋄ ⊑∘∊⟜"iu"⟩
  ⟩
  pp_u8 ⇐ Ptr⍟2 @_getPrim 'u'‿8  # **u8, for main
}

registers ← {kname⇐"register"
  Is ← kname ≡ Kind
  Transient ⇐ {
    owner⇐functions.current ⋄ labc⇐owner.labc
    kind⇐kname ⋄ shows⇐"(temp)" ⋄ type⇐𝕩 ⋄ fmtType⇐1 ⋄ Matches⇐≡
    name←⟨⟩ ⋄ AddName⇐{name∾↩<𝕩}
    mut⇐0 ⋄ ref⇐0 ⋄ Use⇐{𝕤⋄ref+↩1} ⋄ SetMut⇐!
    ShowReg⇐{showReg↩∾⟨𝕏@⟩∾"_"⊸∾¨(ref=1)/name}
  }
  Declare ⇐ { name 𝕊 type‿val:
    owner⇐functions.current ⋄ labc⇐owner.labc
    kind⇐kname ⋄ shows⇐name ⋄ type⇐ ⋄ fmtType⇐1 ⋄ Matches⇐≡
    addName⇐@ ⋄ {𝕩.AddName name}⍟Is val
    mut⇐0 ⋄ ref⇐0 ⋄ Use⇐{𝕤⋄ref+↩1}
    SetMut⇐{𝕤⋄mut↩1}  # Changed (for blocks, and transient elimination)
    ShowReg⇐{showReg↩𝕩}∘{
      Is val? ¬val.mut? (¬mut)∨1=val.ref? labc=val.labc?
        ref+↩val.ref-1 ⋄ val.ShowReg𝕩 ;
      ∾⟨𝕏@,"_",name⟩
    }
  }
  Mutable ⇐ { Is 𝕩 ? {!}≢𝕩.setMut ; 0 }
  Mutated ⇐ { Is 𝕩 ? 𝕩.mut ; 0 }
  MarkUse ⇐ {𝕩.Use@}⍟Is
  CheckAppend ⇐ { "Register used outside its owning function"!𝕨≡𝕩.owner }⍟(Is⊢)
}
constants ← {kname⇐"constant"
  New ⇐ {
    kind⇐kname ⋄ type⇐𝕨 ⋄ value⇐𝕩
    shows⇐∾"!:"∾¨Repr¨𝕩‿𝕨 ⋄ fmtType⇐0 ⋄ Matches⇐≡
  }
  Static ⇐ {
    kind⇐kname ⋄ type‿handle⇐𝕩
    shows⇐"$c"∾(("_"∾𝕨)⊣"")∾˜•Repr handle ⋄ fmtType⇐1 ⋄ Matches⇐≡
  }
  Undefined ⇐ {
    kind⇐kname ⋄ type⇐𝕨⊢⊘(types.Ptr⊢)𝕩 ⋄ fmtType⇐0 ⋄ Matches⇐≡
    shows⇐∾⟨"?",(•Repr𝕨)⊣"",":",Repr type⟩
  }
  Exportable ⇐ (kname‿"function"⊸⊐⌾< Kind)◶{"?:"≢2↑𝕩.shows}‿1‿0
}

labels ← {kname⇐"label"
  New ⇐ { kind⇐kname ⋄ shows⇐"l"∾•Repr𝕩 ⋄ Matches⇐≡ }
}
symbols ← {kname⇐"symbol"
  Is ← kname ≡ Kind
  From ⇐ {Is _asrtGotS⟜(𝕩˙) 𝕨 ⋄ 𝕩.symstr}
  M ← Is∘⊢_and_(≡○From)
  Enc ← "'"(∾∾⊣)⊢+128×' '⊸= # Space to non-breaking space
  New ⇐ {
    kind⇐kname ⋄ symstr⇐𝕩 ⋄ Shows⇐Enc∘symstr
    Matches⇐M ⋄ Matchable⇐{𝕊:matchable↩<symstr}
  }
}

functions ← {kname⇐"function"
  current⇐nofn←{
    Append⇐NextLabel⇐Return⇐SetArch⇐!∘"No function active"
    arch⇐architecture.init ⋄ labc⇐0
  }
  New ← {𝕤
    kind⇐kname ⋄ Matches⇐≡ ⋄ Type⇐!∘"Explicit function result type needed"
    id⇐𝕩 ⋄ shows⇐("$f"∾(•Repr id)∾"_"⊸∾⍟(0<≠)𝕨)⊣"$main"
    arch⇐current.arch architecture.NewFunction @ ⋄ SetArch⇐{arch↩𝕩}
    label←¯1 ⋄ slabel←⟨⟩ ⋄ args←atypes←ctypes←⟨⟩ ⋄ rType⇐@
    labc⇐0 ⋄ IncLab⇐{𝕊:labc+↩1}  # Labels set: don't alias through label
    NextLabel⇐{𝕤⋄ labels.New label+↩1 }
    UseSymLabel⇐{
      ∊⟜slabel⌾<𝕩 ? !∾"Label "‿𝕩‿" used in this function already" ;
      slabel∾↩<𝕩 ⋄ 𝕩
    }
    NextArg⇐{ name‿gather 𝕊 type:
      a ← (name registers.Declare ⋈⟜@)⚇0 types.Unpack type
      atypes∾↩<type ⋄ ctypes∾↩gather◶<‿types.Ungather type ⋄ args∾↩<a
      a
    }
    ⟨Push,Arr⟩←MakeStack@
    Instrs⇐Arr
    Append⇐{ current registers.CheckAppend¨ 1↓𝕩 ⋄ Push𝕩 ⋄ @ }
    SetRType⇐{
      SetRType↩!∘0 ⋄ "Result" types.ReqTyp rType↩𝕩
      type ↩ ctypes types.Fun rType
    }
    _ret_←{
      Void ← types.IsVoid
      r ← rType ≢⟜@◶⟨𝔽∘⊢, Void∘⊣◶⟨types.Cast,⊑types.primTypes˙⟩⟩ 𝕩
      𝕘◶⟨¬Void,1⟩ rType ? Append ⟨"ret", r⟩ ; @
    }
    Return⇐{
      A ← !∘"Early return from function with no explicit result type"
      A _ret_ 1 @⊣´𝕩
      {Shows⇐!∘"Can't use return result as value"⋄kind⇐"error"}
    }
    Finish⇐{
      e ← "Explicit function result type needed, as result is untyped"
      e IsTyped _asrtGotS 𝕩
      SetRtype TypeOf 𝕩⋄𝕩
    } _ret_ 0
    Prot⇐{𝕊 showReg:
      ext ← (0<≠)◶⟨⟩‿(⋈·'+'⌾⊑·∾','⊸∾¨) architecture.ListExt arch
      at ← ∾ args {IsTup𝕨 ? ∾𝕨𝕊¨𝕩 ; ⋈⟨ShowReg𝕨,Repr𝕩⟩}⟜types.Unpack¨ atypes
      1↓∾" "⊸∾¨⟨1↓shows,Repr rType⟩∾((<∘•Repr∘≠∾∾)at)∾ext
    }
  }
  _with_ ⇐ {
    # 𝕨 passed in by nodes.Define if not main, pretty hacky
    fs←current
    f←current↩(1⊑𝕨) program.AddFunction new
    {(⊑𝕩).Set f} 𝕨
    f (f.Finish 𝔽)program._trace_ 𝕘 𝕩
    current↩fs
    f
  }
  NextArg ⇐ { 𝕨 current.NextArg 𝕩 }
  Label ⇐ { current.NextLabel 𝕩 }
  UseSymLabel ⇐ { current.UseSymLabel 𝕩 }
  Append ← { current.Append 𝕩 }
  _appendReg ← { (1⊸⊑⊣Append) ⟨"new",𝔽𝕨⟩∾{kind⇐@⋄shows⇐𝕩}⌾⊑𝕩 }
  AppendNew ← registers.Transient _appendReg
  Return ⇐ { current.Return 𝕩 }
  GetArch ← {𝕊: current.arch }
  SetArch ← { current.SetArch 𝕩 }
  Emit ⇐ { (⊑𝕩) AppendNew "emit" <⊸∾ 𝕩 }
  Array ⇐ {
    ¬∨´("register"≡Kind)¨𝕩 ? 𝕨 constants.New 𝕩 ;
    𝕨 AppendNew "array"‿𝕨 ∾ 𝕩
  }
  Declare ⇐ {
    current≡nofn ? 𝕨 program.AddConstant 𝕩 ;
    t←TypeOf𝕩 ⋄ 𝕨 registers.Declare⟜t‿𝕩 _appendReg "val"‿t‿𝕩
  }
  _destructure ← {
    0≠•Type𝕩 ? 𝕨𝔽⚇0𝕩;
    "Single assignment target but multiple values" ! 0=•Type𝕨
    "Assignment tuple length mismatch" ! 𝕨 ≡○≢ 𝕩
    𝕨𝕊¨𝕩
  }
  Mut  ⇐ {
    "Can't assign to non-register" registers.Mutable _asrtGotS 𝕨
    Append "mut"‿𝕨‿(𝕨.type types.Cast 𝕩)
    𝕨.SetMut@
    𝕨
  }_destructure
  Call ⇐ {
    f ← ⊑𝕩
    "Calling non-function" IsTyped _asrtGotS f
    a‿t ← (TypeOf f) types.FnCast 1↓𝕩
    t AppendNew ⟨"call",t,f⟩ ∾ ≠⊸∾ {IsTup𝕩 ? ∾𝕊¨𝕩 ; ⟨𝕩⟩} a
  }
  _instr ← { Append (𝕨𝔽𝕩)<⊸∾𝕨⋈𝕩 ⋄ 𝕩 }
  SetLabel ⇐ "lbl"_instr ⊣ { current.IncLab 𝕩 }
  Goto     ⇐ "goto"⊘"gotoT"_instr
  GotoF    ⇐ "gotoF"_instr
  ReadLabel ← {
    l ← "Label or symbol expected" symbols.From 𝕩
    symbols.New "l_" ∾ UseSymLabel⍟𝕨 l
  }⍟("label"≢Kind∘⊢)
  builtins ⇐ ⍉> ⟨
    ⟨"call",Call _v1⟩, ⟨"emit",Emit _v2⟩, ⟨"return",Return⟩
    ⟨"makelabel",Label⟩, ⟨"goto",(Goto 0⊸ReadLabel) _p1⟩
    ⟨"setlabel",(SetLabel 1 ReadLabel ≠◶Label‿⊑)_m1⟩
  ⟩ ∾ { New‿Union‿Has‿List ← architecture ⋄ S←SetArch ⋄ G←GetArch ⋄ ⟨
    ⟨"setarch",S New⟩
    ⟨"addarch",S G Union New⟩
    ⟨"hasarch",G⊸Has⟩
    ⟨"listarch",symbols.New¨List∘G⟩
  ⟩}
}

blocks ← {
  asrtEq ← {𝕊a:≡´_a} AsrtGotGen {∾⟜", needed "⊸∾˜○•Repr´}
  New ⇐ {𝕊 ind‿ptrs‿body‿ls‿e:
    AsrtNP ← AsrtEq⟜((≠ptrs)⋈≠)
    EG ← "Expected generator for @for load or store" IsGen _asrtGotS ⊢
    LenLS ← "Wrong number of @for load or store generators"⊸AsrtNP
    CheckLS ← IsTup◶⟨EG, EG¨⊣LenLS⟩
    {
      "Expected two to four parameters" (2⊸≤∧≤⟜4)_asrtGotR ≠𝕩
      "Wrong number of pointer arguments to @for body" AsrtNP 1⊑𝕩
      CheckLS¨ xls ← 2↓𝕩
      r ← body.Eval be ← ⟨≠ind, xls(⊣∾≠⊸↓)ls, 2↑𝕩, ptrs⟩ env.Block e
      be.Stores @
      r
    }
  }
}

hashMap ← •BQN∘⊣⎊⊢´ "•HashMap"‿{
  keys 𝕊 vals:
  Set ⇐ { keys∾↩<𝕨 ⋄ vals∾↩<𝕩 }
  Get ⇐ { i←keys⊸⊐⌾<𝕩 ⋄ i<≠keys? i⊑vals ; 𝕨 }
}
MemoMap ← {𝕤
  AN←architecture.SeeNext
  resmap ← HashMap˜⟨⟩
  MemoArg ⇐ { ⟨GetMatchable 𝕩, AN@⟩ }
  SetRes ⇐ { 𝕨 resmap.Set 𝕩 ⋄ 𝕩 }
  GetCached ⇐ resmap.Get⟜MemoArg
  _cached ⇐ {
    r ← (none←{⇐}) GetCached 𝕩
    none ≢ r ? r ; 𝔽𝕩
  }
  _memoize ⇐ { (𝔽 SetRes˜ MemoArg) _cached }
}

GenUnhandled ← !∘"Unhandled case"
_targFromPartial ← {@‿⟨{_proc⇐{𝕗_𝕣: ⊢}}, 𝔽, ⊢⟩}
builtins ← {
  # Parameter checking
  _exp_ ← {
    Il ← 1↓·⥊<⊸(≍˘)
    num ← 𝕗⊏"zero"‿"one"‿"two"‿"three"
    err ← ∾" " Il "Expected" <⊸∾ ("or" Il num) ∾⟜< "parameters"
    𝔾⊣ err ({𝕎∨𝕏}´{𝕏⊸=}¨𝕗)_asrtGotR ≠
  }
  AsTup ← { # Returns tuple and a function to go back to original kind
    IsTup 𝕩 ? 𝕩‿⊢ ;
    "type" ≡ Kind 𝕩 ? ⟨𝕨 types.TupFrom 𝕩, types.Tup⟩ ;
    ⟨𝕨 symbols.From 𝕩, symbols.New⟩
  }
  MustBe ← ∾⟜"arameter must be a "⊸∾
  _req_ ← {(𝕩 MustBe 𝕘) 𝔽 _asrtGotS ⊢}
  AsTupP‿AsTup0 ← {(𝕩 MustBe "tuple or symbol")⊸AsTup}¨ "P"‿"First p"
  ⟨RT0⟩ ← ("type"≡Kind)_req_"type"¨ ⟨"First p"⟩
  RGP‿RG0‿RGL ← IsGen _req_"generator"¨ "P"‿"First p"‿"Last p"
  ⟨RL1⟩ ← IsTup _req_"tuple"¨ ⟨"Second p"⟩
  ⟨Sym⇐New,FromSym⇐From⟩ ← symbols
  SymP ← ("P" MustBe "symbol")⊸FromSym
  ReqSym ← "Expected symbol"⊸FromSym
  RTT ← ("Parameters other than the first must be tuples" IsTup _asrtGotS ⊢)¨

  Kinds ← {
    E ← "Unhandled type" ! 0˙
    (e{k‿o←𝕨⋄∧○(k≡⊢)◶⟨𝕏,O˙⟩}´𝕩){o←𝕨𝔽○Kind𝕩⋄𝕨O𝕩}
  }
  Ty2 ← {𝕏⚇0 _p2}∘Kinds ⊣∾⟜(<·"symbol"⌾⊑⊢´)∘⊢⍟(⊑∊⟜=‿≠)"number"‿"type"⋈¨{𝕏numbers._cmp}⊸⋈
  Merge ← {
    0<(0=≠𝕩)⌈´=¨𝕩 ? ∾𝕩 ;
    ∧´("type"≡Kind)¨𝕩 ? types.Merge 𝕩 ;
    m←"Parameters must include a tuple, or be all types or all symbols"
    Sym ∾ m⊸FromSym¨𝕩
  }
  Slice ← 2‿3 _exp_ {
    l‿Ret ← AsTup0 ⊑𝕩
    i←l≠⊸(0⌈⊣⌊+⍟(0⊸>)¨)numbers.GetInt¨1↓𝕩 ⋄ Ret (⊑i)↓(1↓i)↑´˜l
  }
  Select ← { arg 𝕊 ind:
    l‿Wrap ← AsTup0 arg
    sm ← "Indices must be a flat tuple when selecting from a symbol"
    { arg≢l ? "symbol"≡Kind arg ? sm (1=≡)_asrtGotS ind ; @}
    (numbers.GetInt⊑l˙){IsTup 𝕩? Wrap 𝕊¨𝕩 ; 𝔽𝕩} ind
  }_p2
  FindMatches ← {
    ("Parameters must be tuples" IsTup _asrtGotS ⊢)¨ 𝕩‿𝕨
    w‿x ← GetMatchable¨¨ 𝕨‿𝕩
    wc ← ⊐w ⋄ wu ← ((⊢>¯1»⌈`)wc)/w
    (wu⊐x) ⊏ (1+≠)⊸↑⊔wc
  }_p2
  UD ← constants.Undefined{(1<≠)◶⟨𝔽⊑,𝔽˜⟜numbers.GetNat´⟩}
  Undefined ← 1‿2 _exp_ (UD ⊣ RT0∘⊑)
  Load ← Store ← !∘"not yet defined; include 'arch/c' for a standard definition"
  NoEnv ← {!∾"Environment value "‿𝕩‿" hasn't been set"}

  names‿values ⇐ <˘∾≍⟨
    Repr¨⊸≍ types.primTypes
    ⍉> ⟨
      ⟨"__set",functions.Mut _p2⟩
      ⟨"show",(1≠≠)◶⊑‿{Shows⇐!∘"Multiple show used improperly"⋄kind⇐"error"}⊣ShowOut∘ShowMulti⟩
      ⟨"is",Match _p2⟩, ⟨"hastype",1‿2 _exp_ ((1≠≠)◶⟨IsTyped⊑, HasType´⟩)⟩
      ⟨"undefined",Undefined⟩, ⟨"load",Load⟩, ⟨"store",Store⟩
      ⟨"type",TypeOf _p1⟩, ⟨"kind",Sym Kind _p1⟩
      ⟨"typekind",Sym types.TypeKind _p1⟩, ⟨"tuptype",types.Tup⟩
      ⟨"fntype",(¯1⊸(↓ types.Fun ⊑)⊣types.ReqTyp¨)_v1⟩, ⟨"unfntype",types.UnFun _p1⟩
      ⟨"tup",⊢⟩, ⟨"select",Select⟩, ⟨"length",(≠⊑∘AsTupP)_p1⟩
      ⟨"merge",Merge⟩, ⟨"slice",Slice⟩, ⟨"range",↕numbers.GetNat _p1⟩
      ⟨"findmatches", FindMatches⟩
      ⟨"symchars",(Sym∘⋈¨SymP)_p1⟩
      ⟨"fmtnat",Sym∘•Repr numbers.GetNat _p1⟩
      ⟨"bind",⊑RG0⊸{b←generators.Runner˜(0¨𝕩)∾1⋄𝕎_b_𝕎𝕩}1⊸↓_v1⟩
      ⟨"each",⊑{RTT𝕩⋄𝕎¨_ne<˘⍉>𝕩}1⊸↓_v2⟩, ⟨"apply",RG0⊸{𝕎_ne𝕩}⟜RL1 _p2⟩
      ⟨"export",{𝕨 ReqSym⊸program.Export⚇0 𝕩}_p2⟩
      ⟨"require",{program.Require∘ReqSym⚇0 𝕩}⟩
      ⟨"witharch",architecture.With⟩
      ⟨"withenv",{e←program.env⋄e.Push 2↑𝕩⋄r←⟨⟩{𝕎_ne𝕩}˜RGL 2⊑𝕩⋄e.Pop@⋄r}_e3⟩
      ⟨"getenv",1‿2 _exp_ {(1<⟜≠◶⟨NoEnv˙,{𝕏˙}⊑⟩𝕩) program.env.GetDef ⊑𝕩}⟩
      ⟨"hasenv",1‿2 _exp_ {e←program.env⋄(1<≠)◶⟨e.Has⊑,e.HasVal˜´⟩𝕩}⟩
      ⟨"setenv_global", {program.env.SetGlob 𝕩}_e2⟩
      ⟨"memoize",({𝕏 (MemoMap@)._memoize _genNamed_ ({"memoize{"∾(Repr 𝕩)∾"}"}𝕩˙)} RGP)_p1⟩
    ⟩
    functions.builtins
    numbers.builtins
    types.builtins
    >⟨
      "__eq"‿"__ne"‿"__lt"‿"__gt"‿"__le"‿"__ge"
      =‿≠‿<‿>‿≤‿≥ Ty2¨ ⟨Match,¬Match⟩ ∾ ·⥊≍˘⟜({𝕏˜}¨) ⟨types.SSubtype,types.Subtype⟩
    ⟩
  ⟩
  _ne ← {𝔽⎊{𝕊:!":"∾•CurrentError@}} # Protect error from ReErr if builtin runs generator
  ReErr ← {! (':'≠⊑)◶⟨1⊸↓, 𝕩 ∾ (∨`':'⊸=>·∨`'('⊸=)⊸(∨´∘⊣◶⟨": "⊸∾,/⟩)⟩ •CurrentError@}
  values {n𝕊f:
    info ← {name⇐n⋄targs⇐⟨F⎊@_targFromPartial⟩}
    F⎊(ReErr∘n)⊘info
  }⍟(3=•Type∘⊢)¨˜↩ names
}

var ← {
  Get⇐{𝕩.Get 𝕨}
  Fixed⇐{ kind⇐"var" ⋄ Get⇐𝕩˙ }
  New⇐{𝕊: NG←"generator"≢Kind ⋄ kind⇐"var"
    Get⇐{! program._trace_ 𝕩 "Variable definition not yet reached"}
    Set⇐{
      {𝕊:Set↩!∘"Can't extend a non-generator"}⍟NG 𝕩
      Get ↩ 𝕩˙
      𝕩
    }
  }
}
scopes ← {
  noLambda ← var.Fixed genUnhandled
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
  New  ⇐{ (var.New¨   𝕨) Make 𝕩 }
  Fixed⇐{ (var.Fixed¨ 𝕨) Make 𝕩 }
  Block⇐{⟨ni,Load‿Store,ind‿ptrs,names⟩ 𝕊 par:
    Reg ← "register"≡Kind
    pv ← names functions.Declare⍟(Reg⊢)⚇∞‿0⟜({𝕎𝕩}´)¨ load ⋈⟜(⋈⟜ind)¨ ptrs
    vars‿parent ⇐ (var.Fixed¨(ni⥊<ind)∾pv) Make par
    Stores ⇐ {𝕤
      St ← {
        IsTup ⊑𝕩 ? 𝕨𝕊¨⋈¨´𝕩 ;
        s𝕊v‿p: registers.Mutated v ? S p‿ind‿v ;@
      }
      store St pv‿ptrs
    }
  }
}

program ← {
  AddFunction⇐AddConstant⇐Export⇐Require⇐!∘0 ⋄ env⇐trace⇐@
  _with ⇐ {
    fns←⟨⟩ ⋄ AddFunction ↩ { f ← 𝕨 𝕏 ≠fns ⋄ fns∾⟜<↩f ⋄ f }
    cns←⟨⟩ ⋄ AddConstant ↩ { c ← 𝕨 constants.Static ⟨t←TypeOf𝕩, ≠cns⟩ ⋄ cns∾⟜<↩⟨Repr c,t,𝕩⟩ ⋄ c }
    exp←⟨⟩ ⋄ Export ↩ { CheckExport 𝕩 ⋄ exp ∾⟜<↩ 𝕨‿𝕩 }
    req←⟨⟩ ⋄ Require ↩ { req ∾⟜<↩ 𝕩 }
    env ↩ DynamicEnv@
    ⟨_trace_⟩↩s←Stack@
    𝕨 𝔽⎊s.Report 𝕩
    AddFunction↩AddConstant↩Export↩Require↩!∘0 ⋄ env↩trace↩@
    ∾ ⟨DispHeader¨req, DispConstants cns, ∾DispFunction¨fns, DispExport¨exp⟩
  }
  CheckExport ← {
    "Exports must be typed" IsTyped _asrtGotS 𝕩
    "Exports must be global fixed values" constants.Exportable _asrtGotS 𝕩
  }
  Stack ← {𝕤
    ⟨_trace_⇐_while_⟩ ⇐ ⟨Dump⇐Arr⟩ ← MakeStack@
    Report ⇐ {𝕤
      ErrOut (∧`lf⊸≠)⊸/⎊•Repr •CurrentError@
      ErrOut ""
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
      df rt⊸({𝕏⊣·ErrOut𝕨˙}¨)⌾((f-1)⊸⊏)↩
      df {ErrOut∘("}}}"∾@+10)⊢𝕏}¨⌾((i/˜1<n)⊸⊏)↩
      {𝕏@}¨ ⌽ df /˜ 1≠`e≠○(l↑/⁼)f     # Remove extra iterations
      ErrExit@
    }
  }
  DynamicEnv ← {𝕤
    global ← stack ← @
    Sym ← "Environment label must be a symbol"⊸symbols.From
    Push⇐ {   stack ↩ 𝕩‿stack} Sym⌾⊑
    Pop ⇐ {𝕊: stack ↩ 1⊑stack}
    SetGlob ⇐ {global ↩ 𝕩‿global} Sym⌾⊑
    Get ← { yes‿no 𝕊 𝕩:
      s ← Sym 𝕩
      _find ← { @≡𝕩? 𝔽 s ; s≡⊑v←⊑𝕩? Yes 1⊑v ; 𝕊 1⊑𝕩 }
      No _find∘global _find stack
    }
    Has    ⇐ 1‿0⊸Get
    GetDef ⇐ {⊢‿𝕨 Get 𝕩}
    HasVal ⇐ {⟨𝕨˙⊸Match, 0⟩ Get 𝕩}
  }
  J ← 1↓·∾" "⊸∾¨
  DispHeader←{ "require " ∾ "'"(∾∾⊣)𝕩 }
  DispConstants←{ ∾⟜(<⟨⟩)⍟(0<≠) (J"constant"<⊸∾Repr¨⌾(1⊸↓))¨ 𝕩 }
  DispFunction←{
    ShowReg ← {h←¯1⋄{𝕊:"v"∾•Repr h+↩1}}{𝕩.ShowReg𝕗}
    ProcInstrs ← {
      # Mark each register with the number of times it's used after definition
      (registers.MarkUse¨(1+⊏∊"new"‿"mut"˙)↓⊢)¨ 𝕩
      # Combine new into next mut call if that's the only use
      nm ← / ∧⟜«˝ "new"‿"mut" ≡⌜ ⊑¨𝕩
      nm (≡◶0‿{1=𝕩.ref}¨˝1‿2⊑¨𝕩⊏˜0‿1+⌜⊢)⊸/↩
      𝕩 ↩ (¬(≠𝕩)↑/⁼1+nm) / (1⌽𝕩) (⊣⌾(2⊸↑)¨⌾(nm⊸⊏)) 𝕩
      # Convert to names, performing register numbering
      𝕩 ("register"≡Kind)◶Repr‿ShowReg¨⌾(1⊸↓)¨↩
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
  DispExport←{ "export " ∾ J (<"'"⊸(∾∾⊣))⊸∾⟜(TypeOf⋈○Repr⊢)´ 𝕩 }
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
    NonLocal ⇐ ⊢
  }

  # Node types
  Word ⇐ {
    name⇐𝕩 ⋄ pos⇐𝕨⊣@
    ⟨node,Dump,NonLocal⟩⇐d←Defaults "word"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
    Oper⇐{𝕩.Lookup name}
    Eval⇐!∘0 ⋄ Scope⇐{Eval↩pos var.Get (pos 𝕩.Get name){𝔽}}
    # Modify so it defines the variable instead of getting the value
    v0←@⋄V←!∘0 ⋄ IsDef⇐{𝕊:
      ⟨Oper⟩↩d
      Scope↩{
        1𝕊𝕩: v0‿v ↩ pos 𝕩.AddLam name ;
        v ↩ pos 𝕩.Add name
      }
      Eval↩{val‿decl 𝕊 𝕩: u←V𝕩 ⋄ u.Set name⊸functions.Declare⚇0⍟decl val}
    }
    {name≢"_"?@; # _ does nothing on assignment, and errors on access
      scope↩@ ⋄ Eval↩!∘"Can't get value of _"
      IsDef↩{𝕊:Eval↩⊑⊣⋄V↩{Set⇐⊢}˙}
    }
    # If f≡1, set value in Eval for function recursion
    RunEval ⇐ {𝕏 ⟨@, name⟩}
    DefEval ⇐ { f‿ValEval 𝕊 e:
      u←V e ⋄ u.Set program._trace_ pos⍟(¬f) ValEval ⟨f◶⟨V0,u˙⟩ e, name⟩
    }
  }
  NewId ⇐ {𝕩.IsDef@⋄𝕩}∘Word
  _value ← {
    name←𝕩 ⋄ pos⇐𝕨⊣@
    Eval⇐(𝕨𝔽𝕩)˙
    ⟨node,Dump,NonLocal,Oper,Scope⟩⇐Defaults "value"‿⟨⟩
    Disp⇐{𝕤⋄⟨name⟩}
  }
  Number ⇐ numbers.Read _value
  Symbol ⇐ (symbols.New 1↓¯1↓⊢)_value
  Token ⇐ ('''≠⊑∘⊢)◶⟨Symbol,(⊑⊏∘⊢∊dig˙)◶Word‿Number⟩
  consts ⇐ {
    ⟨v⇐values,n⇐names⟩ ← builtins
    Make ← {𝕩˙_value 𝕨}
    call‿i32 ⇐ Make¨⟜(v⊏˜n⊐⊢) "call"‿"i32"
    n0 ⇐ Number "0"
    pp_u8 ⇐ "**u8" Make types.pp_u8
  }
  Run ⇐ {
    𝕨𝕊⟨⟨·⇐evb⟩,params⟩: 𝕨 CondOper 𝕩;
    ⟨caller,params⟩←𝕩 ⋄ pos⇐𝕨
    spread ← 0=•Type¨params ⋄ params ⊑¨↩
    realpar ← params /˜¬ partial ← @⊸≡¨params # . or ...
    Visit←{⟨𝕏caller,𝕏¨realpar⟩}
    em ← spread generators.Runner partial
    ⟨node,Dump,Disp,NonLocal,Scope⟩⇐d←Defaults "run"‿visit
    Oper ⇐ {𝕤⋄ pos operator.Run ⟨⊑Visit o.Oper 𝕩, params⟩}
    Eval ⇐ {
      (IsGen 𝕨)◶⟨!∘"Running non-generator", 𝕎⟩ program._trace_ pos _em_𝕨 𝕩
    }´ d.Eval
  }
  Call ⇐ { 𝕨 Run ⟨consts.call , <⊸∾´𝕩⟩ }
  Phrase ⇐ {
    things←𝕩 ⋄ pos⇐𝕨
    ToWord⇐{𝕤⋄ (1=≠)◶⟨@,@⍟("word"≢{𝕩.node})⊑⟩ things }
    Visit←{⟨𝕏¨things⟩}
    ⟨node,Dump,Disp,NonLocal,Scope,Eval⟩⇐Defaults "phrase"‿visit
    Oper⇐{
      ⟨node⟩↩n ← (o.Oper 𝕩)¨⊸operator.Parse things
      Scope↩{𝕨n.Scope𝕩} ⋄ Eval↩{𝕨(Eval↩n.Eval)𝕩} ⋄ Disp↩{𝕨n.Disp𝕩} # fields of n can change
      operator.nil
    }
  }
  PhraseTryWord ⇐ {"phrase"≡𝕩.node}◶@‿{𝕩.ToWord@}
  PhraseTryName ⇐ {𝕩.name}⍟(@⊸≢)PhraseTryWord
  Target ⇐ {𝕨𝕊⟨1⇐isName⟩:0;1}◶{𝕨 NewId ⊑𝕩.targs}‿{
    pos←𝕨
    names‿eqs‿conds ← target ⇐ pos targetNodes.GetProcs 𝕩
    ProcE ← { ProcE ↩ "Destructuring: "⊸∾ target._proc ⋄ ProcE 𝕩 }
    ns ← pos⊸NewId¨ names
    exprs ← eqs ∾ conds
    Visit←{⟨𝕏¨ns,𝕏¨exprs⟩}
    ⟨node,Dump,Disp,NonLocal,Oper,Scope⟩⇐Defaults "params"‿visit
    VisitLambda ⇐ {⟨names,𝕏¨exprs⟩}
    ScopeLambda ⇐ {names scopes.New 𝕩}
    GB ← "Generator condition must evaluate to boolean" numbers.GetBool ⊢
    _reqConds ← { fail _𝕣 e‿q:
      CQ ← { 𝕨 Match 𝕩.Eval e? @ ; Fail program._trace_ 𝕩.pos "match check failed" }
      CC ← { GB 𝕩? @ ; Fail program._trace_ ((⊑⋈1⊏˘⊢)𝕨) "condition failed" }
      q CQ¨ eqs
      CC˜´∘TraceEval⟜e¨ conds
      e
    }
    GetTry ⇐ {𝕊 e: {fail 𝕊 v‿q: fail _reqConds ⟨v env.Fixed e, q⟩; 𝕊 v‿q:
      ts ← (q {𝕩˙⊸Match}⊸⋈¨ eqs) ∾ GB˙⊸⋈¨conds
      t ← {⊢} {f‿n𝕊𝕩:f⟜n.Eval◶@‿𝕏}´ ts
      𝕨 T v env.Fixed e
    }}
    Eval ⇐ { val‿decl 𝕊 e:
      v‿q ← ProcE val
      ns {𝕩‿decl 𝕨.Eval e}¨ v
      {! "Destructuring "∾𝕩} _reqConds e‿q
      val
    }
    RunEval ⇐ {𝕏 <ns}
    DefEval ⇐ { f‿ValEval 𝕊 e: ⟨RunEval valEval,0⟩ Eval e }
  }
  Lambda ⇐ {
    ⟨par,result⟩←𝕩 ⋄ pos←𝕨
    Visit←{l←par.VisitLambda 𝕩⋄l∾⟨𝕏result⟩}  # Call par.VisitLambda first
    ⟨node,Dump,Disp,NonLocal,Oper⟩⇐Defaults "lambda"‿visit
    Scope⇐{ Visit scopes._defer o.Scope par.ScopeLambda 𝕩 }
    Eval⇐{𝕨 𝕊 e: # 𝕨 is previous value and name, from Define
      ⟨Exec⟩ ← { result.node≢"function"?
        Exec ⇐ result.Eval∘⊢
      ;
        GetCached‿MemoArg‿SetRes ← MemoMap@
        Exec ⇐ {
          r ← (none←{⇐}) GetCached 𝕨 ⋄ none ≢ r ? r ;
          MSet ← (MemoArg 𝕨)⊸SetRes
          n ← (128⌊≠)⊸↑ name∾∾('_'∾·∊⟜(dig∾1↓alph)⊸/Repr)¨𝕨
          {Set⇐MSet}‿n result.Eval 𝕩
        }
      }
      base‿name ← ({𝕩.Get pos}⌾⊑ 𝕨) ⊣ genUnhandled‿""
      name "(generator)"⍟(0=≠)↩
      targs ← ⟨@‿⟨par.target, par.GetTry e, Exec⟩⟩
      ⟨base, name⟩ generators.AddCase targs
    }
  }
  ExtGen ⇐ {
    result←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏result⟩}
    ⟨node,Dump,Disp,NonLocal,Oper,Scope⟩⇐Defaults "lambda"‿visit
    Eval⇐{𝕨 𝕊 e:
      g ← result.Eval e
      "Extension must be a generator" IsGen _asrtGotS program._trace_ pos g
      M ← generators.Merge program._trace_ pos⍟(genUnhandled˙≢⊑∘⊣)
      ({𝕩.Get pos}⌾⊑ 𝕨) ⊢⊘M g
    }
  }
  Extender ⇐ {
    ⟨names,result⟩←𝕩 ⋄ pos←𝕨
    Visit←{names∾⟨𝕏¨result⟩}
    ⟨node,Dump,Disp,NonLocal,Oper⟩⇐Defaults "extender"‿visit
    Scope⇐{ Visit scopes._defer o.Scope names scopes.New 𝕩 }
    Eval⇐{𝕨𝕊e: n←(1⊑𝕨)⊣"" ⋄ {
      A ← ! program._trace_ pos
      "Wrong number of parameters in extension" A names≡○≠𝕩
      "Generator defined with extend must be called with extend" A ∧´ ("var"≡Kind)¨ 𝕩
      (0<≠)◶⟨emptyBody,⊢´⟩ result {𝕨.Eval𝕩}¨ <𝕩 env.Alias e
    }⊘{𝕊: {name⇐𝕩} "(extender)"⍟(0=≠) n}}
  }
  Extend ⇐ {
    ⟨ext,names⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏ext,names⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "extend"‿visit
    N←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}}
    v←@ ⋄ Scope ⇐ { ext.Scope𝕩 ⋄ v ↩ pos⊸(N𝕩).AddLam¨ names }
    Eval ⇐ {
      slots ← {𝕩.Set 𝕨.Get pos⋄𝕩}⍟≢○({𝕎𝕩}⟜(N𝕩))´¨ v
      (!∘"Running non-generator"˙⍟(3≠•Type) ext.Eval𝕩) program._trace_ pos slots
    }
  }
  Arg ⇐ {
    ⟨gather,name,type⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨name,𝕏type⟩}
    ⟨node,Dump,Disp,NonLocal,Oper⟩⇐Defaults "arg"‿visit
    v←@ ⋄ Scope⇐{ type.Scope 𝕩 ⋄ v ↩ pos 𝕩.Add name }
    Eval⇐{
      u ← V 𝕩
      Add ← functions.NextArg⟜("Argument" types._get)
      u.Set name‿gather Add program._trace_ pos type.Eval 𝕩
    }
  }
  Function ⇐ {
    ⟨args,type,result⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏¨args,𝕏¨type,𝕏result⟩}
    ⟨node,Dump,Disp,NonLocal,Oper⟩⇐Defaults "function"‿visit
    Scope⇐{ Visit scopes._defer o.Scope scopes.New 𝕩 }
    Eval⇐{
      ev←o.Eval args env.New 𝕩
      Ev¨ args
      𝕨.SetRType∘Ev¨ type
      Ev result
    } functions._with_ pos
  }
  Main ⇐ {
    ty ← consts.i32‿consts.pp_u8
    𝕨 Function ⟨(≠↑ty˙)(𝕨Arg{⟨0,𝕩,𝕎@⟩})¨⊢, Word¨, ⊢⟩ {𝕎𝕩}¨ 𝕩
  }
  _setType ← { pos type‿env _𝕣 v:
    { ≠type ?
      t ← "Variable" types._get (⊑type).Eval 𝕩
      t types.Cast v
    ;
      "Explicit type needed for untyped initial value" {=𝕩?∧´𝕊¨𝕩;IsTyped𝕩} _asrtGotS v
      v
    } program._trace_ pos env
  }
  Declare ⇐ {
    ⟨name,type,value⟩←𝕩 ⋄ pos←𝕨
    Visit←{¯1⌽⟨":",𝕏¨type,𝕏value,𝕏name⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "declare"‿visit
    N←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}}
    Scope⇐{ {𝕏¨type ⋄ 𝕏value} o.Scope 𝕩 ⋄ name.Scope N 𝕩 }
    Eval⇐{ v←pos type‿𝕩 _setType value.Eval 𝕩 ⋄ v‿1 name.Eval N 𝕩 }
  }
  Define ⇐ {
    ⟨name,value⟩←𝕩 ⋄ pos←𝕨
    value no_def˙⍟(@⊸≡)↩
    Visit←{⟨𝕏name,𝕏value⟩}
    ⟨node,Dump,Disp,Oper⟩⇐Defaults "define"‿visit
    N←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}}
    Scope ⇐ {
      value.Scope 𝕩
      ("lambda"≡value.node) name.Scope N 𝕩
    }
    Eval⇐{
      ⟨"function"≡value.node, value.Eval⟜𝕩⟩ name.DefEval N 𝕩
    }
  }
  no_def ← {
    ENM ← "generator definition"_errNoMatch
    Eval⇐{=𝕨 ? n←1⊑𝕨 ⋄ n⊸ENM⊘{name⇐n⋄targs⇐⟨⟩} ; 𝕊⟜𝕩{𝕩.RunEval 𝕗}¨⊑𝕨}
    ⟨node,Dump,NonLocal,Oper,Scope⟩⇐Defaults "value"‿⟨⟩
    Disp⇐⟨"(no definition)"⟩˙
  }
  OpDef ⇐ {
    ⟨op,fn,type,prec⟩←𝕩 ⋄ pos←𝕨
    prec ↩ numbers.GetFloat prec.Eval@
    Visit←{⟨type,op,𝕏⍟(0==)fn,•Repr prec⟩}
    ⟨node,Dump,Disp,Scope,Eval⟩⇐d←Defaults "opdef"‿visit
    N←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}}
    value←{0<=fn?Word⟜fn;
      v←var.New@
      Eval↩{v.Set fn.Eval 𝕩} # OpDef eval
      Eval⇐{𝕊:v.Get pos}
      ⟨node,Dump,NonLocal,Oper,Scope⟩⇐Defaults "value"‿⟨⟩
      Disp⇐{𝕤⋄⟨"(operator value)",op⟩}
    }
    Oper⇐{d.Oper 𝕩 ⋄ pos (N𝕩).Add type‿op‿value‿prec}
  }
  Include ⇐ {
    # Top-level if statements resolve in operator pass; expand then
    ⟨filename⟩ ← 𝕩 ⋄ pos←𝕨
    file ← •file.RealPath pos files.Resolve symbols.From filename.Eval@
    N←NL←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}⋄NL↩{𝕩.NonLocal@⋄𝕩}}
    ⟨node,Dump,Disp⟩⇐Defaults "include"‿{⟨file⟩} ⋄ Scope⇐Eval⇐!
    Oper ⇐ {𝕤
      (N𝕩).AlreadyIncluded file ? Scope↩Eval↩@˙ ;
      b ← NL files.Include file
      ⟨node,Dump,Disp,Oper,Scope,Eval⟩ ↩ b # Always a body so fields can't change
      b.Oper 𝕩
    }
  }
  Body ⇐ {
    statements←𝕩
    Visit←{⟨𝕏¨statements⟩}
    ⟨node,Dump,Disp⟩⇐d←Defaults "body"‿visit
    N←⊢ ⋄ NonLocal⇐{𝕊:N↩{𝕩.parent}}
    Oper⇐{ d.Oper operator.NewScope N 𝕩 }
    sc←@ ⋄ Scope⇐{ d.Scope sc ↩ scopes.New N 𝕩 }
    Eval⇐{ (0<≠)◶⟨emptyBody,⊢´⟩ ⊑ d.Eval (sc.Names@) env.New N 𝕩 }
  }
  emptyBody ← {Shows⇐!∘"Empty body has no result"⋄kind⇐"error"}

  LazyLabel ← {𝕤
    label ⇐ 𝕩
    GotoC ⇐ {
      label functions.Label⍟(@⊸≡)↩
      GotoC ↩ {𝕩 𝕨◶functions.GotoF‿functions.Goto label}
      𝕨GotoC𝕩
    }
  }
  BoolEval ← {
    E ← IsTyped◶"Expected boolean"‿"Can't use runtime logic outside if() and while()"
    e numbers.GetBool 𝕨.Eval 𝕩
  }
  TraceEval ← { "cond_oper"≡𝕨.node ? 𝕨.Eval ≍≍𝕩 ; ⟨𝕨 BoolEval 𝕩, ≍𝕨.pos⟩ }
  CondEvalS ← {  # Return 0 or 1 for constant result and @ for unknown
    "cond_oper"≡𝕨.node ? 𝕨.Eval 𝕩 ;
    n𝕊⟨jv‿label,e⟩:
    c ← n.Eval e
    { IsTyped c ? "Condition type must be u1" types.IsBool _asrtGotS TypeOf c
      jv label.GotoC c ⋄ @
    ; "If condition must evaluate to boolean" numbers.GetBool c }
  }
  CondEval ← ⊑∘⊑∘⊢ ≢ CondEvalS  # Return 1 if it might jump
  CondOper ← { pos 𝕊 ⟨name‿_evb‿_evt‿_evc, terms⟩: # Node created for and/or/not
    Eval⇐{ev←(=𝕩)⊑evb‿evc‿evt ⋄ terms _ev program._trace_ pos 𝕩}
    Visit←{⟨name,𝕏¨terms⟩} ⋄ pos⇐
    ⟨node,Dump,Disp,NonLocal,Scope⟩⇐Defaults "cond_oper"‿visit
  }
  AddConds ⇐ {
    ev_not ← {
      _evb ⇐ {¬(⊑𝕗) BoolEval 𝕩}
      _evt ⇐ {¬⌾⊑(⊑𝕗) TraceEval ⊑𝕩}
      _evc ⇐ {=𝕩? ¬⍟(@⊸≢) (⊑𝕗) CondEvalS ¬⌾(⊑⊑)𝕩}
    }
    CAccum ← {𝕊id:
      _evb ⇐ {E←BoolEval⟜𝕩 ⋄ (E 1⊑𝕗˙)⍟(id⊸≡) E ⊑𝕗}
      _evt ⇐ {E←TraceEval⟜(⊑𝕩) ⋄ ∾⌾(1⊸⊑)⍟(≡○⊑)⟜(E 1⊑𝕗˙)⍟(id≡⊑) E ⊑𝕗}
      _evc ⇐ {
        𝔽_𝕣 ⟨jv‿label,e⟩:
        l ← LazyLabel@
        i ← (⊑𝕗) CondEvalS ⟨¬id,l⟩⌾⊑⍟(id=jv) 𝕩
        c ← (1⊑𝕗) CondEvalS⟜𝕩⍟((¬id)≢⊢) i
        {jv label.GotoC⍟(id⊸≡) c ⋄ functions.SetLabel 𝕩}⍟(@⊸≢) l.label
        i⍟(id⊸≡) c
      }
    }
    @ 𝕩.Add⟜{𝕊t‿n‿e: t‿n‿{name⇐n⋄evb‿evt‿evc⇐e}‿¯∞}¨ ⟨
      'p'‿"not"‿ev_not
      'l'‿"and"‿(CAccum 1)
      'l'‿"or" ‿(CAccum 0)
    ⟩
  }
  If ⇐ {
    ⟨cond,then,else⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏cond,𝕏then,𝕏¨else⟩}
    ⟨node,Dump,Disp,NonLocal,Oper,Scope⟩⇐Defaults "if"‿visit
    Eval ⇐ {
      lf ← LazyLabel@
      c ← cond CondEval program._trace_ pos ⟨0‿lf, e←𝕩⟩
      { ¬c ?
        r ← {Shows⇐!∘"Can't use if-0 statement result as value"⋄kind⇐"error"}
        functions.SetLabel⍟(@⊸≢) lf.label
        r ⊣´ { 𝕩.Eval e }¨ else
      ;
        r ← then.Eval e ⋄ @≡lf.label ? r ;
        functions.Goto¨ lt ← functions.Label¨ else
        functions.SetLabel lf.label
        lt { 𝕩.Eval e ⋄ functions.SetLabel 𝕨 }¨ else
        {Shows⇐!∘"Can't use runtime if statement result as value"⋄kind⇐"error"}
      }
    }
  }
  TopIf ⇐ {
    ⟨cond,then,else⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏cond,𝕏¨then,𝕏¨else⟩}
    ⟨node,Dump,Disp,NonLocal⟩⇐Defaults "topif"‿visit ⋄ Scope⇐Eval⇐!
    Oper⇐{
      # Latest we can evaluate condition without scope circularity, so do it now
      cond.Oper 𝕩
      c ← {𝕨 BoolEval program._trace_ pos 𝕩}ast._runIfCond cond
      body ← c ¬⊸⊑ then‿else
      ⟨Scope,Eval⟩ ↩ d ← Defaults "topif"‿{⟨𝕏¨body⟩}
      d.Oper 𝕩
      operator.nil
    }
  }
  While ⇐ {
    ⟨testFirst,cond,stmt⟩←𝕩 ⋄ pos←𝕨
    Visit←{⟨𝕏cond,𝕏stmt⟩}
    ⟨node,Dump,Disp,NonLocal,Oper,Scope⟩⇐Defaults "while"‿visit
    Eval ⇐ { 𝕊 e:
      functions.SetLabel ll ← functions.Label@
      { testFirst ?
        lt ← LazyLabel@
        { cond CondEval program._trace_ pos ⟨0‿lt, e⟩ ?
          stmt.Eval e
          functions.Goto ll
        ; @ }
        functions.SetLabel⍟(@⊸≢) lt.label
      ;
        stmt.Eval e
        functions.Goto∘ll⍟¬ cond CondEval ⟨1‿(LazyLabel ll), e⟩
      }
      {Shows⇐!∘"Can't use while statement result as value"⋄kind⇐"error"}
    }
  }

  OptPlain ← {
    gens←𝕩
    Visit←{⟨𝕏¨gens⟩}
    ⟨node,Dump,Disp,NonLocal,Oper,Scope⟩⇐Defaults "match"‿visit
    Eval ⇐ { 𝕊 e:
      n ← "(options)"
      Init ← "option"_errNoMatch ⊘ {name⇐n⋄targs⇐⟨⟩}
      init {𝕩‿n 𝕨.Eval e}⟜{Get⇐𝕩˙}´ gens
    }
  }
  Options ⇐ { (𝕨Run⋈⟜⊑˜)⍟(≠⊣)⟜(𝕨OptPlain⊢)´ 𝕩 }

  For ⇐ {
    ⟨fn,ptrs,ind,from,to,body⟩←𝕩 ⋄ pos←𝕨
    ptri←pos⊸Word¨ptrn←⊑¨ptrs
    ptrv←ptrs(1⊑∾⟜<)¨ptri
    from↩consts.n0⊣´from
    vardisp←1↓∾(","⊸∾¨ptrn)∾" over "⊸∾¨ind
    Visit←{⟨𝕏fn,vardisp⊣𝕏¨ptri≍˘ptrv,𝕏from,𝕏to,𝕏body⟩}
    ⟨node,Dump,Disp,NonLocal,Oper⟩⇐Defaults "for"‿visit
    ls←@
    Scope ⇐ {
      (o.Scope 𝕩)¨ ∾⟨fn⟩‿ptrv‿⟨from,to⟩
      ls ↩ (<pos) 𝕩.Get¨ "load"‿"store"
      body.Scope scopes._defer (ind∾ptrn) scopes.New 𝕩
    }
    Eval ⇐ {
      e←o.Eval 𝕩
      For←(!∘"Running non-generator"˙⍟(3≠•Type) E fn) program._trace_ pos
      lsv←(pos var.Get {𝕎𝕩}⟜𝕩)¨ ls
      For ⟨E¨ptrv, E from, E to, blocks.New ind‿ptrn‿body‿lsv‿𝕩⟩
    }
  }
}

targetNodes ← {
  failedMatch ← {⇐}
  Name ⇐ Constant ⇐ {
    # If constant, "assign" to node to evaluate and compare at cond-time
    isName ⇐ =𝕩
    targs ⇐ ⟨𝕩⟩
    conds ⇐ ⟨⟩
    GetProc ⇐ ⋈˙
  }
  Merge ← { 𝕨 𝕊 targets:
    tn‿tc‿tg ← {𝕏¨targets}¨ {𝕩.targs}‿{𝕩.conds}‿{𝕩.GetProc}
    targs‿conds ⇐ ∾¨ tn‿tc
    MF ← {∨´failedMatch≡¨𝕩 ? failedMatch ; ∾ 𝕩}
    GetProc ⇐ {r𝕊e: (r⊑∾‿MF) {𝕎 𝕩 {𝕎𝕩}¨ ⊢} {r𝕏e}¨tg}
  }
  AddTransform ← { tr 𝕊 t:
    targs‿conds ⇐ t
    GetProc ⇐ {𝕏∘Tr} t.GetProc
  }
  _addCheck ← { pos err‿Check _𝕣 target:
    targs‿conds ⇐ target
    GetFail ← {𝕊e: { (E err) 0 _asrtGotS program._trace_ pos 𝕩 } }
    GetProc ⇐ {r𝕊e: Check◶⟨GetFail⍟(¬r) e, r target.GetProc e⟩ }
  }
  _single ← { e‿C‿Tr _𝕣: ⊣ e‿C _addCheck tr˙ AddTransform ⊢ }
  _multi ← { 𝕗_single⟜Merge }
  Equals  ⇐ { 𝕨 Same 𝕨⊸Constant¨⌾(1⊸↓) 𝕩 }
  Same    ⇐ { ({2=𝕩?⋈˜;𝕩⥊<}≠𝕩) AddTransform Merge 𝕩 }
  Typed   ⇐ ⟨"type is required", IsTyped, ⋈⟜{𝕩.type}⟩_multi
  Vector  ⇐ (⟨ "vector type required"⟩∾types.vecDecompParams)_multi
  Pointer ⇐ (⟨"pointer type required"⟩∾types.ptrDecompParams)_single
  Conds ⇐ { par‿cond ← 𝕩 ⋄ targs‿conds‿GetProc ⇐ par ⋄ conds∾↩<cond }
  List ⇐ {
    ⟨ps, andConds⟩ ← 𝕩 ⋄ [gather,params] ← ⍉>ps ⋄ pos←𝕨
    n ← +´ ¬ gather  # Minimum length
    addLenCheck ← {
      n=≠gather ? ⟨∾⟨"length ",•Repr n," required"⟩, n=≠⟩_addCheck
    ;
      G ← (0‿n-˜⋈⁼/gather)⊸(∾0‿2‿1⊏↑¨⟜<∾⟜<·<↓´˜)
      ⟨∾⟨"length ",•Repr n," or more required"⟩, n≤≠, G⟩_single
    }
    t ← pos AddLenCheck andConds Conds∘⋈˜´˜ Merge params
    types.tupTry AddTransform pos ⟨"tuple required", IsTup⟩ _addCheck t
  }
  # Get functions for evaluating regular node from target node
  GetProcs ⇐ { pos 𝕊 target:
    # An individual target might be a name, _, or a node
    # (which is evaluated and required to match the corresponding value)
    ⟨targs⟩ ← target
    typ ← (0==¨targs) - "_"⊸≡¨targs
    ns‿eqs ← 2↑typ⊔targs ⋄ eqs⇐ ⋄ names⇐⍷ns
    tr ← {𝕎⋈𝕏}´ {∧´𝕩? ⊢ ; ∨´𝕩? 𝕩⊸/ ; 0⊸↑}¨ 0‿1 = <targs (1-˜∊∘⊣)⌾((0=typ)⊸/) typ
    AllEq ← ∧´⊏Match¨1⊸↓
    TrE ← Tr˙ ⋄ ChT ← failedMatch˙⊸≢
    { names≡ns ? @ ;
      ci ← (1<≠¨)⊸/(⊐ns)⊔/0=typ  # Index sets to check
      c ← {𝕎∧𝕏}´{AllEq𝕩⊸⊏}¨ci
      TrE ↩ TrE⊸{t𝕊e:
        Err ← {
          ErrOut m ← E "values given the same name don't match"
          fail ← ¬AllEq¨ sels ← ⊏⟜𝕩¨ ci
          errs ← ci {∾⟨"For ",ns⊑˜⊑𝕨," got: ",ShowMulti𝕩⟩}¨○(fail⊸/) sels
          ErrOut¨ ¯1↓errs ⋄ ! program._trace_ pos ¯1⊑errs
        }
        C◶Err‿T
      }
      ChT ↩ ChT◶0‿C
    }
    ⟨conds⟩ ⇐ target
    GetProc ← { r𝕊e: (r◶⟨TrE,ChT◶⟨@,Tr⟩˙⟩e) {𝕎𝕏} r target.GetProc e }
    _proc ⇐ { 𝕗≡@? 1 GetProc failedMatch ; 0 GetProc 𝕗 }
  }
  # Each case is target‿condition‿evaluate
  CombineParams ⇐ { base 𝕊 cases: genUnhandled ≢ base?
    # Error message comes from Base so just run everything
    base {t‿c‿e𝕊n: ⊢ @⊸≢◶⟨N⊣, @⊸≢◶⟨N⊣,E⟩⟜C⟩ @t._proc}´ cases
  ; ·𝕊 ⟨t‿c‿e⟩:
    Pre ← "Generator destructuring: "⊸∾
    ⊢ E {Pre ErrParams 𝕩˙} C Pre t._proc
  ; ·𝕊 cases:
    Base ← ("generator definition ("∾" tried)"∾˜•Repr≠cases)_errNoMatch
    base 𝕊 cases
  }
}
generators ← {
  AddCase ⇐ {base‿name Make targs:
    GetBase ← {𝕊⟨b⇐base⟩: b ; genUnhandled}
    SetBase ← {𝕨𝕊⟨t⇐targs⟩: targs∾↩⟨t⟩ ⋄ GetBase 𝕩 ; 𝕨} # Push targs to linked list/tree
    base ↩ SetBase⟜{𝕏˜@}⍟(genUnhandled˙≢⊢) base
    info ← { name⇐name ⋄ targs⇐targs ⋄ base⇐base }
    Gen ← {
      gen ↩ base targetNodes.CombineParams {@‿·:1↓𝕩;∾𝕊¨𝕩} targs
      Gen 𝕩
    }
    {Gen𝕩}⊘info
  }
  Merge ⇐ AddCase⟜({
    𝕨𝕊⟨base⟩: base≢genUnhandled ? !"Fallback for generator case unsupported: "∾Show base ;
    𝕨𝕊⟨targs⟩: targs ;
    !"Fallback for generator unsupported: "∾Show 𝕨
  }⟜{𝕏˜@})
  AsTry ← {
    unmatched←{⇐}
    gen ← unmatched‿"(trial)" Merge 𝕩
    unmatched⊸≡◶⟨1⋈⊢, 0‿@⟩ Gen
  }
  Runner ⇐ { spread 𝕊 pp: # (Call _result_ Gen args) runs generator
    Sp ← ⊣◶⟨⋈⊢, "Spread input must be tuple" IsTup _asrtGotS ⊢⟩
    DeSpread ← (pp<spread){∨´𝕗? ∾𝕗{∨´𝕘?𝕗/˜1+𝕘×-○≠⟜𝕗;𝕗}(pp∧spread)Sp¨⊢; ⊢}
    {¬∨´pp? {_𝕣_:𝔽∘DeSpread};
      Fill ← (pp/spread){
        ¬∨´𝕗 ? ((⍋⍋pp)⊏∾) ⊣ (𝕘!(≠𝕗)=≠∘⊢) ;
        c ← +´pp∧»∨`ps←pp∧spread
        i ← (⋈⁼/ps)(↑⋈↓)(⊢-≠×(c-˜≠)⊸≤)⍋⍋ps¬⊸/pp
        (∾0‿2‿1⊏(i⊏¨<∘∾)∾⟜<(c-˜0⋈¯1+´pp)↓´˜⊢) ⊣ (𝕘!c≤≠∘⊢)
      }"Partial and given parameter counts don't match"
      Proc ← DeSpread∘Fill
      GetInfo ← { G‿P:
        s ← Show¨ P (pp/spread)⊏{kind⇐@⋄shows⇐𝕩}¨"."‿"..."
        name ← ∾∾ ⟨Repr g,"{"⟩‿(1↓⥊(<", ")≍˘s)‿⟨"}"⟩
        GetTargs ← {⟨((1⊑𝕏)⍟(@⊸≢) P⎊@) _targFromPartial⟩}
        name {𝕨𝕊@:name⇐𝕨; name⇐𝕨⋄targs⇐GetTargs𝕩} AsTry⎊@ g
      }
      { P←𝕩⊸Proc ⋄ N←{n↩𝕩}∘GetInfo∘𝔾‿P ⋄ 𝔽∘P⊘{𝕨N𝕩} }
    }
  }
}

files ← {
  path←@
  Load ← {
    path ↩ •file.Parent 𝕩
    𝕩 ast.Build •file.Chars 𝕩
  }
  RunImm ← {
    path ↩ •wdpath
    "(-r argument)" ast.Build 𝕩
  }
  lib ← ('/'∾˜⍟(≠⟜(¯1⊸⊑))⍟(0<≠∘⊢)⌾⊑¨libpaths)∾<⟨"","include/"⟩
  Resolve ⇐ {
    '/'=⊑𝕩 ? •file.Exists f←𝕩∾".singeli" ? f ;
    search ← (≠↑𝕩˙)⊸≡∘⊑¨⊸/ ('.'=⊑𝕩) ⊑ ⟨lib,⟨""‿path⟩⟩
    Get ← {pre‿path𝕊𝕩: path •file.At pre ≠⊸(⊢↓˜⊣+'/'=⊑) 𝕩}⟜(𝕩∾".singeli")
    f←@ ⋄ {f≡@? •file.Exists ft←Get𝕩? f↩ft; @}¨ search
    Report ← {" (searched "∾"and Singeli library)"∾˜∾⥊(Get¨¯1↓𝕩)∾˘<", "}
    Err∘((1<≠)◶""‿Report∘search⊸(∾˜)⌾⊑)⍟(f≡@) "File not found"‿𝕨
    f
  }
  Include ⇐ { DepOut 𝕩 ⋄ p←path ⋄ a←Load 𝕩 ⋄ path↩p ⋄ a }
  Build ⇐ { =◶⟨RunImm⊑, Load⟩ 𝕩 }
}

ast ← {
  Show ⇐ {•Out ∾∾⟜lf¨ 𝕩.Disp @}
  baseScope ← builtins.names scopes.New scopes.Init@
  baseEnv   ← builtins.values env.Fixed @
  baseOper  ← operator.NewScope operator.nilScope
  nodes.AddConds baseOper
  @ baseOper.Add 'r'‿"="‿(nodes.Word⟜"__set")‿¯∞
  Build ⇐ Parse∘Tokenize
  Compile ⇐ {
    t ← files.Build 𝕩
    t.Oper operator.NewScope baseOper
    t.Scope scopes._run sc ← scopes.New baseScope
    t.Eval program._with (sc.Names@) env.New baseEnv
  }
  _runIfCond ⇐ { # For top-level if condition
    𝕩.Scope scopes._run baseScope
    e←@ ⋄ {e↩𝕩}∘(𝕩⊸𝔽) program._with baseEnv ⋄ e
  }
}

(∾∾⟜lf¨) ast.Compile
