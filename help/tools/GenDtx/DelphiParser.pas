unit DelphiParser;

interface

uses
  Classes, ParserTypes;

const
  toComment = Char(6);
  toColon = Char(':');
  toSemiColon = Char(';');
  toHaakjeOpen = Char('(');
  toHaakjeSluiten = Char(')');
  toEquals = Char('=');
  toDot = Char('.');
  toCompilerDirective = Char(7);

type
  TModuleType = (mtLibrary, mtUnit);

  TBasicParser = class(TObject)
  private
    FStream: TStream;
    FOrigin: Longint;
    FBuffer: PChar;
    FBufPtr: PChar;
    FBufEnd: PChar;
    FSourcePtr: PChar;
    FSourceEnd: PChar;
    FTokenPtr: PChar;
    FStringPtr: PChar;
    FSourceLine: Integer;
    FSaveChar: Char;
    FToken: Char;
    FFloatType: Char;
    FWideStr: WideString;
    FRecordStr: string;
    FRecording: Boolean;
    FCompilerDirectives: TStringList;
    procedure ReadBuffer;
    function ReadPortion: Boolean;
    procedure SkipBlanks;
    procedure AddTokenToRecordStr;
    procedure SetRecording(const Value: Boolean);
    function GetRecordStrWithCurrentToken: string;
  protected
    function ReadNextToken: Char; virtual; abstract;
    procedure Init; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure CheckToken(T: Char);
    procedure CheckNotToken(T: Char);
    procedure CheckTokenSymbol(const S: string);
    procedure Error(const Ident: string);
    procedure ErrorFmt(const Ident: string; const Args: array of const);
    procedure ErrorStr(const Message: string);
    procedure HexToBinary(Stream: TStream);
    function NextToken(SkipBlanks: Boolean = True): Char; virtual;
    function SourcePos: Longint;
    function TokenComponentIdent: string;
    function TokenFloat: Extended;
    function TokenInt: Int64;
    function TokenString: string;
    function TokenWideString: WideString;
    function TokenSymbolIs(const S: string): Boolean;
    function TokenSymbolIsExact(const S: string): Boolean;
    function TokenSymbolIn(const List: array of string): Integer;
    procedure BeginRecording;
    procedure EndRecording;
    property FloatType: Char read FFloatType;
    property SourceLine: Integer read FSourceLine;
    property Token: Char read FToken;
    property RecordStr: string read GetRecordStrWithCurrentToken;
    property RecordStrWithoutCurrentToken: string read FRecordStr;
    property Recording: Boolean read FRecording write SetRecording;
  end;

  TDelphiParser = class(TBasicParser)
  private
    FTypeList: TTypeList;
    FErrorMsg: string;
    FAcceptCompilerDirectives: TStrings;
    FAcceptVisibilities: TClassVisibilities;
    FLastCompilerDirectiveAccepted: Boolean;
    procedure SetAcceptCompilerDirectives(const Value: TStrings);
  protected
    function ReadNextToken: Char; override;

    procedure ReadClass(const TypeName: string; const AddToList: Boolean);
    procedure ReadClassMethods(AClassItem: TClassItem; const AddToList: Boolean);
    procedure ReadClass_Property(AClassItem: TClassItem; Position: TClassVisibility; DoAdd: Boolean);
    procedure ReadClass_Function(AClassItem: TClassItem; Position: TClassVisibility; DoAdd, IsClassMethod: Boolean);
    procedure ReadClass_Procedure(AClassItem: TClassItem; Position: TClassVisibility; DoAdd, IsClassMethod: Boolean);
    procedure ReadClass_ClassMethod(AClassItem: TClassItem; Position: TClassVisibility; DoAdd: Boolean);
    procedure ReadClass_Field(AClassItem: TClassItem; Position: TClassVisibility; DoAdd: Boolean);
    procedure ReadCommentBlock;
    procedure ReadConst;
    procedure ReadConstValue;
    procedure ReadDirectives(var Directives: TDirectives);
    procedure ReadDispInterface(const TypeName: string; const AddToList: Boolean);
    procedure ReadInterfaceBlock;
    procedure ReadInterfaceStatement;
    procedure ReadInterfaceType(const TypeName: string; const AddToList: Boolean);
    procedure ReadInterfaceMethods(AInterfaceItem: TInterfaceItem; const AddToList: Boolean);
    procedure ReadFunction;
    procedure ReadFunctionType(const TypeName: string; const AddToList: Boolean);
    procedure ReadParamList(AParams, ATypes: TStrings);
    procedure ReadProcedure;
    procedure ReadProcedureType(const TypeName: string; const AddToList: Boolean);
    procedure ReadRecord(const TypeName: string; const AddToList: Boolean);
    procedure ReadResourceString;
    procedure ReadEnumerator(const TypeName: string; const AddToList: Boolean);
    procedure ReadType(const ATypeName: string; const AddToList: Boolean);
    procedure ReadTypeDef;
    procedure ReadConstantExpression(const ExpectDotDot: Boolean);
    procedure ReadSimpleType(const TypeName: string; const AddToList: Boolean);
    procedure ReadUnitBlock(out AModuleType: TModuleType);
    procedure ReadUsesBlock;
    procedure ReadVar;

    procedure SkipUntilToken(T: Char);
    procedure SkipUntilSemiColonInHaak;
    procedure SkipUntilSymbol(const Symbol: string);
    procedure SkipUntilTokenInHaak(T: Char; const InitHaak: Integer = 0); overload;
    procedure SkipUntilTokenInHaak(OpenHaak, CloseHaak: Char; const InitHaak: Integer = 0); overload;

    procedure Init; override;
    function Parse: Boolean; virtual;
  public
    constructor Create; override;
    destructor Destroy; override;

    function NextToken(SkipBlanks: Boolean = True): Char; override;

    function ExecuteFile(const AFileName: string): Boolean; virtual;
    function Execute(AStream: TStream): Boolean; virtual;
    property TypeList: TTypeList read FTypeList;
    property AcceptCompilerDirectives: TStrings read FAcceptCompilerDirectives
      write SetAcceptCompilerDirectives;
    property AcceptVisibilities: TClassVisibilities read FAcceptVisibilities
      write FAcceptVisibilities default [inPublic, inPublished];
    property ErrorMsg: string read FErrorMsg;
  end;

  TDtxCompareErrorFlag = (defJVCLInfoGroup, defJVCLInfoFlag, defNoPackageTag,
    defPackageTagNotFilled, defNoStatusTag, defEmptySeeAlso, defNoAuthor);
  TDtxCompareErrorFlags = set of TDtxCompareErrorFlag;

  TPasCheckErrorFlag = (pefNoLicense, pefUnitCase);
  TPasCheckErrorFlags = set of TPasCheckErrorFlag;

  TDefaultText = (dtWriteSummary, dtWriteDescription, dtTypeUsedBy,
    dtListProperties, dtRemoveSeeAlso, dtDescribeReturns, dtOverridenMethod,
    dtInheritedMethod, dtDescriptionFor);

  TDefaultTexts = set of TDefaultText;

  TDtxCompareTokenType = (ctHelpTag, ctText, ctParseTag, ctSeperator);

  TDtxCompareParser = class(TBasicParser)
  private
    FList: TStrings;
    FErrors: TDtxCompareErrorFlags;
    FDefaultTexts: TDefaultTexts;
    function GeTDtxCompareTokenType: TDtxCompareTokenType;
  protected
    function ReadNextToken: Char; override;

    //function Parse: Boolean;
    function Parse: Boolean;
    procedure ReadPackage;
    procedure ReadAuthor;
    procedure ReadStatus;
    procedure ReadJVCLINFO;
    procedure ReadStartBlock;
    procedure ReadSeeAlso;
    procedure ReadRest;

    property CompareTokenType: TDtxCompareTokenType read GeTDtxCompareTokenType;
  public
    constructor Create; override;
    destructor Destroy; override;

    function Execute(const AFileName: string): Boolean;
    property List: TStrings read FList;
    property Errors: TDtxCompareErrorFlags read FErrors;
    property DefaultTexts: TDefaultTexts read FDefaultTexts;
  end;

  TDpkParser = class(TDelphiParser)
  private
    FList: TStrings;
    procedure ReadUntilContainsBlock;
    function ReadFileReference: Boolean;
  protected
    function Parse: Boolean; override;
    procedure Init; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    property List: TStrings read FList;
  end;

  TRegisteredClassesParser = class(TDelphiParser)
  private
    FList: TStrings;
  protected
    function ReadUntilRegisterBlock: Boolean;
    function ReadUntilRegisterComponentsBlock: Boolean;
    function ReadRegisterComponentsBlock: Boolean;
    function Parse: Boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Init; override;

    property List: TStrings read FList;
  end;

  TPasCasingParser = class(TDelphiParser)
  private
    FList: TStrings;
    FID: Integer;
    FAllSymbols: Boolean;
  protected
    function Parse: Boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    property List: TStrings read FList;
    property ID: Integer read FID write FID;
    property AllSymbols: Boolean read FAllSymbols write FAllSymbols;
  end;

  TPasCheckParser = class(TDelphiParser)
  private
    FErrors: TPasCheckErrorFlags;
    FFileName: string;
    FUnitName: string;
  protected
    procedure ReadCommentBlock;
    procedure ReadUnitName;
    function Parse: Boolean; override;
  public
    function ExecuteFile(const AFileName: string): Boolean; override;
    property Errors: TPasCheckErrorFlags read FErrors;

    property FileName: string read FFileName;
    property UnitName: string read FUnitName;
  end;

  TFunctionParser = class(TDelphiParser)
  private
    FFunctions: TStrings;
    FSkipped: TStrings;
    FFileName: string;
  protected
    procedure ReadUntilImplementationBlock;
    function ReadUntilFunction: Boolean;
    procedure ReadFunction;

    procedure Init; override;
    function Parse: Boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    function ExecuteFile(const AFileName: string): Boolean; override;
    property Functions: TStrings read FFunctions;
    property Skipped: TStrings read FSkipped;
  end;

implementation

uses
  SysUtils, Dialogs, Windows;

const
  SCharExpected = '''''%s'''' expected';
  SIdentifierExpected = 'Identifier expected';
  SInvalidBinary = 'Invalid binary value';
  SInvalidString = 'Invalid string constant';
  SLineTooLong = 'Line too long';
  SNotCharExpected = 'Not ''''%s'''' expected';
  SNotEofExpected = 'Not EOF expected';
  SNotIdentifierExpected = 'Not identifier expected';
  SNotNumberExpected = 'Not number expected';
  SNotStringExpected = 'Not string expected';
  SNumberExpected = 'Number expected';
  SParseError = '%s on line %d';
  SStringExpected = 'String expected';
  SSymbolExpected = '%s expected';

  { TDelphiParser }

const
  CParseBufSize = 4096 * 16;

const
  CAllowableSymbolsInTypeDef: array[0..4] of string = ('Low', 'High', 'Ord', 'Succ', 'Pred');

function RemoveEndChars(const S: string; const Chars: TSysCharSet): string;
begin
  Result := S;
  while (Length(Result) > 0) and (Result[Length(Result)] in Chars) do
    Delete(Result, Length(Result), 1);
end;

procedure TBasicParser.CheckToken(T: Char);
begin
  if Token <> T then
    case T of
      toSymbol:
        Error(SIdentifierExpected);
      toString, toWString:
        Error(SStringExpected);
      toInteger, toFloat:
        Error(SNumberExpected);
    else
      ErrorFmt(SCharExpected, [T]);
    end;
end;

procedure TBasicParser.CheckTokenSymbol(const S: string);
begin
  if not TokenSymbolIs(S) then
    ErrorFmt(SSymbolExpected, [S]);
end;

constructor TBasicParser.Create;
begin
  GetMem(FBuffer, CParseBufSize);
  FCompilerDirectives := TStringList.Create;
end;

destructor TBasicParser.Destroy;
begin
  FCompilerDirectives.Free;
  if FBuffer <> nil then
  begin
    if Assigned(FStream) then
      FStream.Seek(Longint(FTokenPtr) - Longint(FBufPtr), 1);
    FreeMem(FBuffer, CParseBufSize);
  end;
end;

procedure TBasicParser.Error(const Ident: string);
begin
  ErrorStr(Ident);
end;

procedure TBasicParser.ErrorFmt(const Ident: string;
  const Args: array of const);
begin
  ErrorStr(Format(Ident, Args));
end;

procedure TBasicParser.ErrorStr(const Message: string);
begin
  raise EParserError.CreateFmt(SParseError, [Message, FSourceLine]);
end;

procedure TBasicParser.HexToBinary(Stream: TStream);
var
  Count: Integer;
  Buffer: array[0..255] of Char;
begin
  SkipBlanks;
  while FSourcePtr^ <> '}' do
  begin
    Count := HexToBin(FSourcePtr, Buffer, SizeOf(Buffer));
    if Count = 0 then
      Error(SInvalidBinary);
    Stream.Write(Buffer, Count);
    Inc(FSourcePtr, Count * 2);
    SkipBlanks;
  end;
  NextToken;
end;

procedure TBasicParser.Init;
begin
  FBuffer[0] := #0;
  FBufPtr := FBuffer;
  FBufEnd := FBuffer + CParseBufSize;
  FSourcePtr := FBuffer;
  FSourceEnd := FBuffer;
  FTokenPtr := FBuffer;
  FSourceLine := 1;
  NextToken(False);
end;

procedure TBasicParser.ReadBuffer;
var
  Count: Integer;
begin
  Inc(FOrigin, FSourcePtr - FBuffer);
  FSourceEnd[0] := FSaveChar;
  Count := FBufPtr - FSourcePtr;
  if Count <> 0 then
    Move(FSourcePtr[0], FBuffer[0], Count);
  FBufPtr := FBuffer + Count;
  if FBufEnd = FBufPtr then
    raise Exception.Create('ReadBuffer Error');
  Inc(FBufPtr, FStream.Read(FBufPtr[0], FBufEnd - FBufPtr));
  FSourcePtr := FBuffer;
  FSourceEnd := FBufPtr;
  if FSourceEnd = FBufEnd then
  begin
    FSourceEnd := LineStart(FBuffer, FSourceEnd - 1);
    if FSourceEnd = FBuffer then
      Error(SLineTooLong);
  end;
  FSaveChar := FSourceEnd[0];
  FSourceEnd[0] := #0;
end;

function TBasicParser.ReadPortion: Boolean;
begin
  ReadBuffer;
  Result := FSourcePtr^ <> #0;
end;

procedure TBasicParser.SkipBlanks;
begin
  while True do
  begin
    case FSourcePtr^ of
      #0:
        begin
          ReadBuffer;
          if FSourcePtr^ = #0 then
            Exit;
          Continue;
        end;
      #10:
        Inc(FSourceLine);
      #33..#255:
        Exit;
    end;
    Inc(FSourcePtr);
  end;
end;

function TBasicParser.SourcePos: Longint;
begin
  Result := FOrigin + (FTokenPtr - FBuffer);
end;

function TBasicParser.TokenComponentIdent: string;
var
  P: PChar;
begin
  CheckToken(toSymbol);
  P := FSourcePtr;
  while P^ = '.' do
  begin
    Inc(P);
    if not (P^ in ['A'..'Z', 'a'..'z', '_']) then
      Error(SIdentifierExpected);
    repeat
      Inc(P)
    until not (P^ in ['A'..'Z', 'a'..'z', '0'..'9', '_']);
  end;
  FSourcePtr := P;
  Result := TokenString;
end;

function TBasicParser.TokenFloat: Extended;
begin
  if FFloatType <> #0 then
    Dec(FSourcePtr);
  Result := StrToFloat(TokenString);
  if FFloatType <> #0 then
    Inc(FSourcePtr);
end;

function TBasicParser.TokenInt: Int64;
begin
  Result := StrToInt64(TokenString);
end;

function TBasicParser.TokenString: string;
var
  L: Integer;
begin
  if FToken = toString then
    L := FStringPtr - FTokenPtr
  else
    L := FSourcePtr - FTokenPtr;
  SetString(Result, FTokenPtr, L);
end;

function TBasicParser.TokenSymbolIn(const List: array of string): Integer;
var
  S: string;
begin
  if (Token <> toSymbol) or (High(List) <= 0) then
  begin
    Result := -1;
    Exit;
  end;

  S := TokenString;
  Result := 0;
  while (Result <= High(List)) and not SameText(S, List[Result]) do
    Inc(Result);
  if Result > High(List) then
    Result := -1;
end;

function TBasicParser.TokenSymbolIs(const S: string): Boolean;
begin
  Result := (Token = toSymbol) and SameText(S, TokenString);
end;

function TBasicParser.TokenWideString: WideString;
begin
  if FToken = toString then
    Result := TokenString
  else
    Result := FWideStr;
end;

procedure TDelphiParser.ReadCommentBlock;
const
  CCopyRight1 = 'Initial Developer of the Original Code is';
  CCopyRight2 = 'Initial Developers of the Original Code are:';
var
  AuthorFound: Boolean;
  S, T: string;
  P: Integer;
  Q, Q1, Q2, R: PChar;
  SpacesFound: Integer;
begin
  AuthorFound := False;
  while Token = toComment do
  begin
    if not AuthorFound then
    begin
      S := TokenString;
      P := Pos(CCopyRight1, S);
      Q := nil;
      if P > 0 then
        Q := PChar(S) + P + Length(CCopyRight1)
      else
      begin
        P := Pos(CCopyRight2, S);
        if P > 0 then
          Q := PChar(S) + P + Length(CCopyRight2);
      end;
      AuthorFound := P > 0;
      if AuthorFound then
      begin
        R := Q;
        Q1 := AnsiStrPos(Q, 'Copyright');
        Q2 := AnsiStrPos(Q, 'Portions');

        if Q1 = nil then
          Q := Q2
        else
          if (Q2 = nil) or (Q1 < Q2) then
          Q := Q1
        else
          Q := Q2;

        if Q = nil then
        begin
          SpacesFound := 0;
          Q := R;
          while (Q^ <> #0) and (SpacesFound < 2) do
          begin
            if Q^ = ' ' then
              Inc(SpacesFound);
            Inc(Q);
          end;
        end;
        SetLength(T, Q - R);
        Move(R^, PChar(T)^, Q - R);

        { Remove e-mail address }
        if Pos('[', T) > 0 then
          T := Copy(T, 1, Pos('[', T) - 1);
        if Pos('<', T) > 0 then
          T := Copy(T, 1, Pos('<', T) - 1);

        FTypeList.Author := Trim(T);
      end;
    end;
    NextToken(False);
  end;
end;

procedure TDelphiParser.ReadInterfaceBlock;
type
  TPosition = (inConst, inType, inNull, inVar, inResourceString);
var
  Position: TPosition;
begin
  Position := inNull;
  while Token <> toEof do
    case Token of
      toSymbol:
        begin
          if SameText(TokenString, 'implementation') then
            Exit;
          if SameText(TokenString, 'procedure') then
            ReadProcedure
          else
            if SameText(TokenString, 'function') then
            ReadFunction
          else
            if TokenSymbolIs('resourcestring') then
          begin
            Position := inResourceString;
            NextToken;
          end
          else
            if SameText(TokenString, 'const') then
          begin
            Position := inConst;
            NextToken;
          end
          else
            if SameText(TokenString, 'type') then
          begin
            Position := inType;
            NextToken;
          end
          else
            if TokenSymbolIs('var') then
          begin
            Position := inVar;
            NextToken;
          end
          else
            case Position of
              inConst: ReadConst;
              inType: ReadTypeDef;
              inVar: ReadVar;
              inResourceString: ReadResourceString;
            else
              Error('Not in Type, Const, Var');
            end;
        end;
      toComment:
        NextToken;
    else
      NextToken;
    end;

  while (Token <> toEof) and
    ((Token <> toSymbol) or not SameText(TokenString, 'implementation')) do
    NextToken;
end;

procedure TDelphiParser.ReadInterfaceStatement;
begin
  CheckToken(toSymbol);
  CheckTokenSymbol('interface');
  NextToken;
end;

procedure TDelphiParser.ReadUnitBlock(out AModuleType: TModuleType);
begin
  CheckToken(toSymbol);
  if TokenSymbolIs('library') then
    AModuleType := mtLibrary
  else
    if TokenSymbolIs('unit') then
    AModuleType := mtUnit
  else
    Error('''library'' or ''unit'' expected');
  NextToken;
  SkipUntilToken(toSemiColon);
  CheckToken(toSemiColon);
  NextToken;
end;

procedure TDelphiParser.ReadUsesBlock;
begin
  if not (Token = toSymbol) or not TokenSymbolIs('uses') then
    Exit;

  CheckToken(toSymbol);
  CheckTokenSymbol('uses');
  NextToken;
  SkipUntilToken(toSemiColon);
  CheckToken(toSemiColon);
  NextToken;
end;

procedure TDelphiParser.ReadFunction;
var
  FunctionItem: TFunctionItem;
  Directives: TDirectives;
begin
  { VB:

    function F1(P1: T1; P2: T2);

    PRE : Token staat op 'function'
    POST: Token staat op teken na laatste ;
  }
  NextToken;
  SkipUntilToken(toSymbol);
  //while not (Token in [toEof, toSymbol]) do
  //  NextToken;
  if Token = toEof then
    Exit;

  FunctionItem := TFunctionItem.Create(TokenString);
  FTypeList.Add(FunctionItem);
  NextToken;

  { Token staat op ( of op : }
  { TODO: Eigenlijk niet ReadParamList aanroepen als token is : }
  ReadParamList(FunctionItem.Params, FunctionItem.ParamTypes);
  Directives := [];
  ReadDirectives(Directives);
  FunctionItem.Directives := Directives;
end;

procedure TDelphiParser.ReadProcedure;
var
  ProcedureItem: TProcedureItem;
  Directives: TDirectives;
begin
  { VB:

    procedure P1(P1: T1; P2: T2);
    procedure P1;

    PRE : Token staat op 'procedure'
    POST: Token staat op teken na laatste ;
  }
  NextToken;
  SkipUntilToken(toSymbol);
  //while not (Token in [toEof, toSymbol]) do
  //  NextToken;
  if Token = toEof then
    Exit;

  ProcedureItem := TProcedureItem.Create(TokenString);
  FTypeList.Add(ProcedureItem);

  NextToken;

  { Token staat op ( of op ; }
  ReadParamList(ProcedureItem.Params, ProcedureItem.ParamTypes);
  Directives := [];
  ReadDirectives(Directives);
  ProcedureItem.Directives := Directives;
end;

procedure TDelphiParser.ReadTypeDef;
var
  TypeName: string;
begin
  { VB:

    T1 = record F1: T1; F2: T2; end;
    T1 = class() [classdef] end;
    T1 = sometype;

    PRE : Token staat op een typename
    POST: Token staat op eerste teken na ;
  }
  TypeName := TokenString;
  NextToken;
  CheckToken(toEquals);
  NextToken;

  ReadType(TypeName, True);

  if Token = toSemiColon then
    NextToken;
end;

procedure TDelphiParser.ReadConst;
var
  ConstItem: TConstItem;
begin
  { VB:

    C1 = V1;
    C1: type = V1;
    C1: array[xx] of TSpecialFolderInfo = ((), (), ());

    PRE : Token staat op identifier [C1]
    POST: Token staat op teken na ;
  }

  ConstItem := TConstItem.Create(TokenString);
  FTypeList.Add(ConstItem);

  BeginRecording;

  NextToken;
  case Token of
    '=':
      begin
        NextToken;
        ReadConstValue;
      end;
    ':':
      begin
        NextToken;
        ReadType('', False);
        CheckToken('=');
        NextToken;
        ReadConstValue;
      end;
  else
    Error('''='' or '':'' expected');
  end;

  //SkipUntilToken(toSemiColon); //SkipUntilSemiColonInHaak;
  CheckToken(toSemiColon);
  EndRecording;
  ConstItem.Value := RecordStr;
  NextToken;
end;

procedure TDelphiParser.ReadDirectives(var Directives: TDirectives);
var
  Directive: Integer;
begin
  { Pre  :
    Post : Token staat op teken na ; na directives }
  while True do
  begin
    case Token of
      toSymbol:
        { TODO: Ook toevoegen aan object }
        if TokenSymbolIs('message') then
        begin
          { message X ; }
          SkipUntilToken(toSemiColon);
          CheckToken(toSemiColon);
        end
        else
        begin
          Directive := TokenSymbolIn(CDirectives);
          if Directive < 0 then
            Exit
          else
            Include(Directives, TDirective(Directive));
        end;
      toSemiColon, toComment:
        ;
    else
      Exit;
    end;
    NextToken;
  end;
end;

procedure TDelphiParser.ReadClass(const TypeName: string; const AddToList: Boolean);
var
  ClassItem: TClassItem;
begin
  { VB:

    Tx = class(Tx1) .. end;
    Tx = class .. end;
    Tx = class;               -> Deze niet toevoegen, moet nog compleet
                                 gedefinieerd worden
    Tx = class(Tx1);          -> Hack class
    Tx = class of Tx1;        -> Meta class

    PRE : Token staat op 'class'
    POST: Token staat op eerste teken na ;
  }

  NextToken;
  if Token = toSemiColon then
  begin
    { Class is nog niet compleet gedefinieerd; niet toevoegen }
    NextToken;
    Exit;
  end;

  { Nu pas toevoegen }
  if AddToList then
  begin
    ClassItem := TClassItem.Create(TypeName);
    FTypeList.Add(ClassItem);
  end
  else
    ClassItem := nil;

  if Token = toHaakjeOpen then
  begin
    SkipUntilToken(toHaakjeSluiten); // SluitHaakje;
    CheckToken(toHaakjeSluiten);
    NextToken;
  end;

  { TODO: Iets doen met meta-class }
  if (Token <> toSemiColon) and not TokenSymbolIs('of') then
    ReadClassMethods(ClassItem, AddToList)
      { Token staat op eerste token na [end]; }
  else
  begin
    SkipUntilToken(toSemiColon); //SkipUntilSemiColon;
    CheckToken(toSemiColon);
    NextToken;
  end;
end;

procedure TDelphiParser.ReadRecord(const TypeName: string; const AddToList: Boolean);
var
  RecordItem: TRecordItem;
begin
  { VB:

    R1 = record F1, F2: T1 end;          <-- Let op ","
    R1 = record F1: T1; F2: T2; end;
    R1 = record case tag: ordinalType of
           constantList1: (variant1);
           ...
           constantListn: (variantn);
         end;

         variant1 = fieldList1: type1;
                    ...
                    fieldListn: typen;

    R1 = record
      F1: T1; F2: T2;
      F3: record case T3 of
        constantList1: (F1': T1');
        ...
        constantListn: (Fn': Tn');
      end;
    end;

    PRE : Token is 'record'
    POST: Token is teken na end
  }
  if AddToList then
  begin
    RecordItem := TRecordItem.Create(TypeName);
    FTypeList.Add(RecordItem);
  end
  else
    RecordItem := nil;

  NextToken;

  while True do
  begin
    case Token of
      toSymbol:
        if TokenSymbolIs('end') then
          Break
        else
          if TokenSymbolIs('case') then
        begin
          SkipUntilSymbol('of');
          NextToken;
          SkipUntilToken(toHaakjeOpen);
          CheckToken(toHaakjeOpen);
        end
        else
        begin
          { Lees (identifier:type) paar in }
          if AddToList then
            RecordItem.Items.Add(TokenString);
          NextToken;
          if Token <> ',' then
          begin
            CheckToken(toColon);
            NextToken;

            ReadType('', False);
            Continue;
          end;
        end;
      toHaakjeSluiten: { empty list or closing }
        begin
          NextToken;
          while Token = toHaakjeSluiten do
            NextToken;
          if Token = toSemiColon then
            NextToken;
          if TokenSymbolIs('end') then
            Break
          else
          begin
            SkipUntilToken(toColon);
            CheckToken(toColon);
            NextToken;
            CheckToken(toHaakjeOpen);
          end;
        end;
      toEof:
        Exit;
    end;
    NextToken;
  end;

  { we staan nu op end }
  CheckTokenSymbol('end');
  NextToken;
  { TODO : Change to while }
  if Token = toSemiColon then
    NextToken;
end;

constructor TDelphiParser.Create;
begin
  inherited;
  FTypeList := TTypeList.Create;
  FAcceptCompilerDirectives := TStringList.Create;
  TStringList(FAcceptCompilerDirectives).Sorted := True;
  FAcceptVisibilities := [inPublic, inPublished];
  //FList := TStringList.Create;
end;

destructor TDelphiParser.Destroy;
begin
  FTypeList.Free;
  FAcceptCompilerDirectives.Free;
  //FList.Free;
  inherited;
end;

procedure TDelphiParser.ReadFunctionType(const TypeName: string; const AddToList: Boolean);
var
  FunctionTypeItem: TFunctionTypeItem;
  Directives: TDirectives;
begin
  { VB:

    F1 = Function();

    PRE : Token is 'Function'
    POST: Token is eerste token na ;
  }

  if AddToList then
  begin
    FunctionTypeItem := TFunctionTypeItem.Create(TypeName);
    FTypeList.Add(FunctionTypeItem);
  end
  else
    FunctionTypeItem := nil;

  {AddFunctionType(TypeName);}

  NextToken;

  { Token staat op ( of op ; }
  if AddToList then
    ReadParamList(FunctionTypeItem.Params, FunctionTypeItem.ParamTypes)
  else
    ReadParamList(nil, nil);
  Directives := [];
  ReadDirectives(Directives);
  if AddToList then
    FunctionTypeItem.Directives := Directives;
end;

procedure TDelphiParser.ReadProcedureType(const TypeName: string; const AddToList: Boolean);
var
  ProcedureTypeItem: TProcedureTypeItem;
  Directives: TDirectives;
begin
  { VB:

    TStrProc = procedure(const S: string);
    TNotifyEvent = procedure(Sender: TObject) of object;

    PRE : Token is 'procedure'
    POST: Token is teken na ;
  }

  if AddToList then
  begin
    ProcedureTypeItem := TProcedureTypeItem.Create(TypeName);
    FTypeList.Add(ProcedureTypeItem);
  end
  else
    ProcedureTypeItem := nil;

  NextToken;
  { Token staat op ( of ; }
  if AddToList then
    ReadParamList(ProcedureTypeItem.Params, ProcedureTypeItem.ParamTypes)
  else
    ReadParamList(nil, nil);

  Directives := [];
  ReadDirectives(Directives);
  if AddToList then
    ProcedureTypeItem.Directives := Directives;
end;

procedure TDelphiParser.ReadParamList(AParams, ATypes: TStrings);

  procedure EndParamTypeRecording;
  begin
    if not Recording then
      Exit;

    if Assigned(ATypes) and Assigned(AParams) then
      while ATypes.Count < AParams.Count do
        ATypes.Add(Trim(RemoveEndChars(RecordStr, [' ', ';', '=', ')'])));

    Recording := False;
  end;

var
  Haakjes: Integer;
  NewParam: Boolean;
begin
  { VB:

    (P1: T1);
    (P1, P2: T1);
    ;

    PRE : Token staat voor (
          AStrings kan nil zijn
    POST: Token staat op teken na ; die bij paramlist hoort
  }
  Haakjes := 0;
  NewParam := True;
  try
    while True do
    begin
      case Token of
        toSemiColon:
          begin
            EndParamTypeRecording;
            if Haakjes = 0 then
            begin
              NextToken;
              Exit;
            end;

            NewParam := True;
          end;
        toEquals:
          { Do not add default values to the type }
          EndParamTypeRecording;
        toHaakjeOpen:
          Inc(Haakjes);
        toHaakjeSluiten:
          begin
            Dec(Haakjes);
            if Haakjes = 0 then
              EndParamTypeRecording;
          end;
        toEof:
          Exit;
        toSymbol:
          if (Haakjes > 0) and NewParam then
          begin
            if TokenSymbolIn(['const', 'var', 'out']) >= 0 then
            begin
              NextToken;
              Continue;
            end;

            { (var X) is ook mogelijk }
            if Assigned(AParams) then
              AParams.Add(TokenString);
            NextToken;
            {SkipComments;}
            if Token <> ',' then
            begin
              NewParam := False;
              { Let op deze !! }
              Continue;
            end;
          end
          else
            Recording := True;
      end;
      NextToken;
    end;
  finally
    Recording := False;
  end;
end;

procedure TDelphiParser.ReadVar;
begin
  { VB:

    V1: T1;

    PRE:  Token staat op identifier
    POST: Token staat op teken na ;
  }

  FTypeList.Add(TVarItem.Create(TokenString));

  SkipUntilToken(toSemiColon); //SkipUntilSemiColon;
  CheckToken(toSemiColon);
  NextToken;
end;

procedure TDelphiParser.ReadResourceString;
var
  ResourceStringItem: TResourceStringItem;
begin
  { RS1 = V1; }

  ResourceStringItem := TResourceStringItem.Create(TokenString);
  FTypeList.Add(ResourceStringItem);
  NextToken;
  CheckToken(toEquals);
  BeginRecording;
  SkipUntilToken(toSemiColon); //SkipUntilSemiColon;
  CheckToken(toSemiColon);
  EndRecording;
  ResourceStringItem.Value := RecordStr;
  NextToken;
end;

procedure TDelphiParser.ReadInterfaceType(const TypeName: string; const AddToList: Boolean);
var
  InterfaceItem: TInterfaceItem;
begin
  (* vb

    IJvDataConsumer = interface;
    IJvDataConsumer = interface
    ['{B2F18D03-F615-4AA2-A51A-74D330C05C0E}']

    PRE : Token staat op 'class'
    POST: Token staat op eerste teken na ;
  *)
  NextToken;
  if Token = toSemiColon then
  begin
    { Class is nog niet compleet gedefinieerd; niet toevoegen }
    NextToken;
    Exit;
  end;
  if Token = '[' then
  begin
    SkipUntilToken(']');
    CheckToken(']');
  end;

  { Nu pas toevoegen }
  if AddToList then
  begin
    InterfaceItem := TInterfaceItem.Create(TypeName);
    FTypeList.Add(InterfaceItem);
  end
  else
    InterfaceItem := nil;

  ReadInterfaceMethods(InterfaceItem, AddToList);
end;

procedure TDelphiParser.ReadEnumerator(const TypeName: string; const AddToList: Boolean);
var
  EnumItem: TEnumItem;
  NewValue: Boolean;
  Haakjes: Integer;
begin
  { VB:

    (E1, E2, E3);
    ();
    (Small = 5, Medium = 10, Large = Small + Medium);

    PRE : Token staat op '(';
    POST: Token staat op ;
  }

  if AddToList then
  begin
    EnumItem := TEnumItem.Create(TypeName);
    FTypeList.Add(EnumItem);
  end
  else
    EnumItem := nil;

  { NewValue hebben we nodig om bv in '(Small = 5, ..' 5 niet mee te nemen }
  NewValue := True;
  Haakjes := 0;
  while True do
  begin
    case Token of
      toSemiColon:
        if Haakjes = 0 then
          Exit;
      toHaakjeOpen:
        Inc(Haakjes);
      toHaakjeSluiten:
        begin
          Dec(Haakjes);
          if Haakjes = 0 then
          begin
            NextToken;
            Exit;
          end;
        end;
      toSymbol:
        if NewValue then
        begin
          if AddToList then
            EnumItem.Items.Add(TokenString);
          NewValue := False;
        end;
      toEof:
        Exit;
      ',':
        NewValue := True;
    end;
    NextToken;
  end;
end;

procedure TDelphiParser.ReadSimpleType(const TypeName: string; const AddToList: Boolean);
var
  SimpleType: TTypeItem;
begin
  { VB:

    T1 = array[..] of record F1: T1; F2: T2; end;
    T1 = xx;

    PRE: Token staat op xx/array
    POST: Token staat op eerste teken na ;
  }

  if AddToList then
    BeginRecording;
  if TokenSymbolIs('array') then
  begin
    SkipUntilSymbol('of');
    NextToken;
    ReadType('', False);
  end
  else
    if TokenSymbolIs('set') then
  begin
    { same as array }
    SkipUntilSymbol('of');
    NextToken;
    ReadType('', False);
  end
  else
    if Token = '^' then
  begin
    NextToken;
    CheckToken(toSymbol);
    NextToken;
  end
  else
    if TokenSymbolIs('string') then
  begin
    NextToken;
    if Token = '[' then
    begin
      SkipUntilTokenInHaak('[', ']');
      CheckToken(']');
      NextToken;
    end;
  end
  else
    if TokenSymbolIn(CAllowableSymbolsInTypeDef) >= 0 then
    ReadConstantExpression(True)
  else
  begin
    { We can't skip until ; }

    if TokenSymbolIs('type') then
      NextToken;

    NextToken;
    if Token = '.' then
    begin
      NextToken;
      if Token = '.' then
      begin
        { TSomeType = a..b; }
        NextToken;

        ReadConstantExpression(False);
      end
      else
      begin
        CheckToken(toSymbol);
        NextToken;
        while Token = '.' do
        begin
          NextToken;
          CheckToken(toSymbol);
          NextToken;
        end;
      end;
    end
    else
      if not (Token in [toHaakjeSluiten, toSemiColon, '=']) and not TokenSymbolIs('end') then
      ReadConstantExpression(True);
  end;

  CheckNotToken(toEof);
  if AddToList then
  begin
    EndRecording;
    SimpleType := TTypeItem.Create(TypeName);
    SimpleType.Value := RecordStr;
    FTypeList.Add(SimpleType);
  end;

  //if Token = toSemiColon then
  //  NextToken;
end;

procedure TDelphiParser.SkipUntilSymbol(const Symbol: string);
begin
  while (Token <> toEof) and not TokenSymbolIs(Symbol) do
    NextToken;
end;

procedure TDelphiParser.SkipUntilSemiColonInHaak; //SkipUntilSemiColonInHaak;
var
  Haakjes: Integer;
begin
  { TODO: Post conditie veranderen: Token staat op ; }

  { PRE  :
    POST : Token staat op ; of #0 en heeft een 'in-de-haak' reeks afgelegd
  }
  Haakjes := 0;
  while True do
  begin
    case Token of
      toSemiColon:
        if Haakjes <= 0 then
          Exit;
      toHaakjeOpen:
        Inc(Haakjes);
      toHaakjeSluiten:
        Dec(Haakjes);
      toEof:
        Exit;
    end;
    NextToken;
  end;
end;

procedure TDelphiParser.ReadDispInterface(const TypeName: string; const AddToList: Boolean);
begin
  { TODO: DispInterface toevoegen }
  SkipUntilSymbol('end');
  SkipUntilToken(toSemiColon); //SkipUntilSemiColon;
  CheckToken(toSemiColon);
  NextToken;
end;

procedure TDelphiParser.ReadClassMethods(AClassItem: TClassItem; const AddToList: Boolean);
var
  Position: TClassVisibility;
begin
  { vb

    public property P1; end;

    PRE : Token staat op eerste token na class()
    POST: Token staat op eerste token na [end];
  }
  Position := inPublic;
  while True do
  begin
    case Token of
      toSymbol:
        begin
          if TokenSymbolIs('end') then
          begin
            SkipUntilToken(toSemiColon); //SkipUntilSemiColon;
            CheckToken(toSemiColon);
            NextToken;
            Exit;
          end
          else
            if TokenSymbolIs('private') then
            Position := inPrivate
          else
            if TokenSymbolIs('protected') then
            Position := inProtected
          else
            if TokenSymbolIs('public') then
            Position := inPublic
          else
            if TokenSymbolIs('published') then
            Position := inPublished
          else
            if TokenSymbolIs('property') then
          begin
            ReadClass_Property(AClassItem, Position,
              AddToList and (Position in [inProtected, inPublic, inPublished]));
            { Token is eerste token na ; }
            Continue;
          end
          else
            if TokenSymbolIn(['procedure', 'constructor', 'destructor']) >= 0 then
          begin
            ReadClass_Procedure(AClassItem, Position,
              AddToList and (Position in AcceptVisibilities), False);
            { Token is eerste token na ; }
            Continue;
          end
          else
            if TokenSymbolIs('function') then
          begin
            ReadClass_Function(AClassItem, Position,
              AddToList and (Position in AcceptVisibilities), False);
            { Token is eerste token na ; }
            Continue;
          end
          else
            if TokenSymbolIs('class') then
          begin
            ReadClass_ClassMethod(AClassItem, Position,
              AddToList and (Position in AcceptVisibilities));
            { Token is eerste token na ; }
            Continue;
          end
          else
          begin
            ReadClass_Field(AClassItem, Position, AddToList and (Position in AcceptVisibilities));
            { Token is eerste token na ; }
            Continue;
          end;
        end;
      toEof:
        Error('Unexpected end of file');
    end;
    NextToken;
  end;
end;

procedure TDelphiParser.ReadClass_ClassMethod(AClassItem: TClassItem;
  Position: TClassVisibility; DoAdd: Boolean);
begin
  NextToken;
  SkipUntilToken(toSymbol);
  if Token = toEof then
    Exit;

  if TokenSymbolIs('function') then
    ReadClass_Function(AClassItem, Position, DoAdd, True)
  else
    ReadClass_Procedure(AClassItem, Position, DoAdd, True);
end;

procedure TDelphiParser.ReadClass_Function(AClassItem: TClassItem;
  Position: TClassVisibility; DoAdd, IsClassMethod: Boolean);
var
  MethodFunc: TMethodFunc;
  Directives: TDirectives;
begin
  { function F1(P1: T1; P2: T2); }
  NextToken;
  SkipUntilToken(toSymbol);
  if Token = toEof then
    Exit;

  if DoAdd then
  begin
    MethodFunc := TMethodFunc.Create(TokenString);
    MethodFunc.OwnerClass := AClassItem;
    MethodFunc.Position := Position;
    MethodFunc.IsClassMethod := IsClassMethod;

    FTypeList.Add(MethodFunc);

    NextToken;
    ReadParamList(MethodFunc.Params, MethodFunc.ParamTypes);
    Directives := [];
    ReadDirectives(Directives);
    MethodFunc.Directives := Directives;
  end
  else
  begin
    NextToken;
    ReadParamList(nil, nil);
    Directives := [];
    ReadDirectives(Directives);
  end;
end;

procedure TDelphiParser.ReadClass_Procedure(AClassItem: TClassItem;
  Position: TClassVisibility; DoAdd, IsClassMethod: Boolean);
var
  MethodProc: TMethodProc;
  MethodType: TMethodType;
  Directives: TDirectives;
begin
  { VB:

    procedure P1(P1: T1; P2: T2);

    PRE : Token is procedure/constructor/destructor
    POST: Token is eerste Token na ;
  }

  if TokenSymbolIs('constructor') then
    MethodType := mtConstructor
  else
    if TokenSymbolIs('destructor') then
    MethodType := mtDestructor
  else
    MethodType := mtNormal;

  NextToken;
  SkipUntilToken(toSymbol);
  if Token = toEof then
    Exit;

  { Token is nu de naam van de procedure }
  if DoAdd then
  begin
    MethodProc := TMethodProc.Create(TokenString);
    MethodProc.OwnerClass := AClassItem;
    MethodProc.MethodType := MethodType;
    MethodProc.Position := Position;
    MethodProc.IsClassMethod := IsClassMethod;

    FTypeList.Add(MethodProc);
    NextToken;
    ReadParamList(MethodProc.Params, MethodProc.ParamTypes);
    Directives := [];
    ReadDirectives(Directives);
    MethodProc.Directives := Directives;
  end
  else
  begin
    NextToken;
    {SkipComments;}
    ReadParamList(nil, nil);
    Directives := [];
    ReadDirectives(Directives);
  end;
end;

procedure TDelphiParser.ReadClass_Property(AClassItem: TClassItem;
  Position: TClassVisibility; DoAdd: Boolean);
var
  ClassProperty: TClassProperty;
begin
  { Bv:

    propery P1: X1 read Get1 write Get2
    property P1;
    property P1 default X;

    Pre : Token staat op 'property'
    Post: Token staat op eerste symbool na ;
  }

  NextToken;
  SkipUntilToken(toSymbol);
  CheckNotToken(toEof);

  if DoAdd then
  begin
    ClassProperty := TClassProperty.Create(TokenString);
    ClassProperty.OwnerClass := AClassItem;
    ClassProperty.Position := Position;

    FTypeList.Add(ClassProperty);
    NextToken;
    if (Token = toSemiColon) or ((Token = toSymbol) and TokenSymbolIs('default')) then
    begin
      ClassProperty.InheritedProp := True;
      SkipUntilToken(toSemiColon); //SkipUntilSemiColon;
    end
    else
    begin
      ClassProperty.InheritedProp := False;
      if Token = '[' then
        SkipUntilTokenInHaak('[', ']');
      SkipUntilToken(toSymbol);
      CheckNotToken(toEof);
      BeginRecording;
      repeat
        NextToken;
      until (TokenSymbolIn(['end', 'read', 'write', 'index']) >= 0) or (Token in [toEof, toSemiColon]);
      EndRecording;
      ClassProperty.TypeStr := RecordStrWithoutCurrentToken;
      SkipUntilToken(toSemiColon); //SkipUntilSemiColon;
    end;
    CheckToken(toSemiColon);
    NextToken;
  end
  else
  begin
    SkipUntilToken(toSemiColon); //SkipUntilSemiColon;
    CheckToken(toSemiColon);
    NextToken;
  end;
  if TokenSymbolIs('default') then
  begin
    SkipUntilToken(toSemiColon);
    CheckToken(toSemiColon);
    NextToken;
  end;
end;

procedure TDelphiParser.ReadClass_Field(AClassItem: TClassItem;
  Position: TClassVisibility; DoAdd: Boolean);
var
  ClassField: TClassField;
begin
  { Bv:

    Pre : Token staat op 'field name'
    Post: Token staat op eerste symbool na ;
  }

  if DoAdd then
  begin
    ClassField := TClassField.Create(TokenString);
    ClassField.OwnerClass := AClassItem;
    ClassField.Position := Position;

    FTypeList.Add(ClassField);
    NextToken;

    SkipUntilToken(toSymbol);
    CheckNotToken(toEof);
    BeginRecording;
    repeat
      NextToken;
    until Token in [toEof, toSemiColon];
    CheckNotToken(toEof);
    EndRecording;
    ClassField.TypeStr := RecordStrWithoutCurrentToken;
    SkipUntilToken(toSemiColon);
    CheckToken(toSemiColon);
    NextToken;
  end
  else
  begin
    SkipUntilToken(toSemiColon);
    CheckToken(toSemiColon);
    NextToken;
  end;
end;

function TDelphiParser.Parse: Boolean;
var
  LModuleType: TModuleType;
begin
  Result := False;
  try
    ReadCommentBlock;
    ReadUnitBlock(LModuleType);
    if LModuleType = mtLibrary then
    begin
      Result := True;
      Exit;
    end;
    ReadInterfaceStatement;
    ReadUsesBlock;
    ReadInterfaceBlock;
    FErrorMsg := '';
    FTypeList.SortIt;
    FTypeList.CalculateCombines;
    Result := True;
  except
    on E: Exception do
      FErrorMsg := E.Message;
  end;
end;

function TDelphiParser.Execute(AStream: TStream): Boolean;
begin
  FStream := AStream;
  Init;
  try
    Result := Parse;
  finally
    FStream := nil;
  end;
end;

procedure TDelphiParser.Init;
begin
  inherited Init;
  FTypeList.Clear;
  FLastCompilerDirectiveAccepted := False;
end;

function TBasicParser.NextToken(SkipBlanks: Boolean): Char;
begin
  if Recording and (Token <> toComment) then
    AddTokenToRecordStr;
  repeat
    Result := ReadNextToken;
  until not SkipBlanks or (Token <> toComment);
end;

procedure TBasicParser.AddTokenToRecordStr;
begin
  if FRecordStr > '' then
    FRecordStr := FRecordStr + ' ' + TokenString
  else
    FRecordStr := TokenString;
end;

procedure TBasicParser.BeginRecording;
begin
  FRecording := True;
  FRecordStr := '';
end;

procedure TBasicParser.EndRecording;
begin
  FRecording := False;
end;

procedure TBasicParser.SetRecording(const Value: Boolean);
begin
  if Value then
    BeginRecording
  else
    EndRecording;
end;

function TDelphiParser.ReadNextToken: Char;
var
  I, J: Integer;
  IsWideStr: Boolean;
  P, S: PChar;

  function IsEndReached: Boolean;
  begin
    { P^ = #0 -> Einde buffer }
    Result := P^ = #0;
    if not Result then
      Exit;

    { Kan nog iets ingelezen worden? }
    Result := ReadPortion;
    if Result then
      P := FSourcePtr;
  end;

  procedure NextChar;
  begin
    Inc(P);
    if P^ = #10 then
      Inc(FSourceLine);
    if P^ = #0 then
      IsEndReached;
  end;

begin
  { Let op: !!!!!!!!!!!!

    geen multi-exit; FToken moet nog gezet worden }

  SkipBlanks;
  P := FSourcePtr;
  FTokenPtr := P;
  case P^ of
    '{':
      begin
        NextChar;
        if P^ <> '$' then
        begin
          while P^ <> '}' do
            NextChar;
          if P^ = '}' then
            NextChar;
          Result := toComment;
        end
        else
        begin
          Result := toCompilerDirective;
          NextChar;
        end;
      end;
    '(':
      begin
        NextChar;
        if P^ = '*' then
        begin
          NextChar;
          repeat
            while P^ <> '*' do
              NextChar;
            if P^ = '*' then
              NextChar;
          until P^ in [#0, ')'];
          if P^ = ')' then
            NextChar;
          Result := toComment;
        end
        else
          Result := toHaakjeOpen;
      end;
    'A'..'Z', 'a'..'z', '_':
      begin
        NextChar;
        while P^ in ['A'..'Z', 'a'..'z', '0'..'9', '_'] do
          NextChar;
        Result := toSymbol;
      end;
    '#', '''':
      begin
        IsWideStr := False;
        J := 0;
        S := P;
        while True do
          case P^ of
            '#':
              begin
                NextChar;
                I := 0;
                while P^ in ['0'..'9'] do
                begin
                  I := I * 10 + (Ord(P^) - Ord('0'));
                  NextChar;
                end;
                if (I > 127) then
                  IsWideStr := True;
                Inc(J);
              end;
            '''':
              begin
                NextChar;
                while True do
                begin
                  case P^ of
                    #0, #10, #13:
                      Error(SInvalidString);
                    '''':
                      begin
                        NextChar;
                        if P^ <> '''' then
                          Break;
                      end;
                  end;
                  Inc(J);
                  NextChar;
                end;
              end;
          else
            Break;
          end;
        P := S;
        if IsWideStr then
          SetLength(FWideStr, J);
        J := 1;
        while True do
          case P^ of
            '#':
              begin
                NextChar;
                I := 0;
                while P^ in ['0'..'9'] do
                begin
                  I := I * 10 + (Ord(P^) - Ord('0'));
                  NextChar;
                end;
                if IsWideStr then
                begin
                  FWideStr[J] := WideChar(SmallInt(I));
                  Inc(J);
                end
                else
                begin
                  S^ := Chr(I);
                  Inc(S);
                end;
              end;
            '''':
              begin
                NextChar;
                while True do
                begin
                  case P^ of
                    #0, #10, #13:
                      Error(SInvalidString);
                    '''':
                      begin
                        NextChar;
                        if P^ <> '''' then
                          Break;
                      end;
                  end;
                  if IsWideStr then
                  begin
                    FWideStr[J] := WideChar(P^);
                    Inc(J);
                  end
                  else
                  begin
                    S^ := P^;
                    Inc(S);
                  end;
                  NextChar;
                end;
              end;
          else
            Break;
          end;
        FStringPtr := S;
        if IsWideStr then
          Result := toWString
        else
          Result := toString;
      end;
    '$':
      begin
        NextChar;
        while P^ in ['0'..'9', 'A'..'F', 'a'..'f'] do
          NextChar;
        Result := toInteger;
      end;
    '-', '0'..'9':
      begin
        NextChar;
        while P^ in ['0'..'9'] do
          NextChar;
        Result := toInteger;
        if P^ = '.' then
        begin
          NextChar;
          if P^ = '.' then
            Dec(P)
          else
            Result := toFloat;
        end;
        while P^ in ['0'..'9', 'e', 'E', '+', '-'] do
        begin
          NextChar;
          Result := toFloat;
        end;
        if P^ in ['c', 'C', 'd', 'D', 's', 'S'] then
        begin
          Result := toFloat;
          FFloatType := P^;
          NextChar;
        end
        else
          FFloatType := #0;
      end;
    {';':
      begin
        NextChar;
        Result := toSemiColon;
      end;}
    {')':
      begin
        NextChar;
        Result := toHaakjeSluiten;
      end;
    '=':
      begin
        NextChar;
        Result := toEquals;
      end;}
    '/':
      begin
        NextChar;
        if P^ = '/' then
        begin
          while not (P^ in [#13, #10, #0]) do
            NextChar;
          while P^ in [#13, #10] do
            NextChar;
          Result := toComment;
        end
        else
          Result := '/';
      end;
  else
    Result := P^;
    if Result <> toEof then
      NextChar;
  end;
  FSourcePtr := P;
  FToken := Result;
end;

function TDelphiParser.NextToken(SkipBlanks: Boolean): Char;
var
  IfDefCount: Integer;
  SkipUntilIfDefCount0: Boolean;
begin
  IfDefCount := 0;
  SkipUntilIfDefCount0 := False;

  while True do
  begin
    Result := inherited NextToken(SkipBlanks);

    if (Token <> toCompilerDirective) and not SkipUntilIfDefCount0 then
      Exit;

    while not (Token in [toCompilerDirective, toEof]) do
      inherited NextToken(SkipBlanks);

    if Token = toEof then
    begin
      Result := toEof;
      Exit;
    end;

    inherited NextToken(SkipBlanks);

    if TokenSymbolIs('IFDEF') then
    begin
      if SkipUntilIfDefCount0 then
      begin
        Inc(IfDefCount);
        while Token <> '}' do
          inherited NextToken(SkipBlanks);

        Continue;
      end;

      inherited NextToken(SkipBlanks);

      if FAcceptCompilerDirectives.IndexOf(TokenString) >= 0 then
      begin
        FLastCompilerDirectiveAccepted := True;
        while Token <> '}' do
          inherited NextToken(SkipBlanks);
        Continue;
      end
      else
      begin
        FLastCompilerDirectiveAccepted := False;
        IfDefCount := 1;
        SkipUntilIfDefCount0 := True;
        while Token <> '}' do
          inherited NextToken(SkipBlanks);
        Continue;
      end;
    end
    else
      if TokenSymbolIs('IFNDEF') then
    begin
      if SkipUntilIfDefCount0 then
      begin
        Inc(IfDefCount);
        while Token <> '}' do
          inherited NextToken(SkipBlanks);
        Continue;
      end;

      inherited NextToken(SkipBlanks);

      if FAcceptCompilerDirectives.IndexOf(TokenString) < 0 then
      begin
        FLastCompilerDirectiveAccepted := True;
        while Token <> '}' do
          inherited NextToken(SkipBlanks);
        Continue;
      end
      else
      begin
        FLastCompilerDirectiveAccepted := False;
        IfDefCount := 1;
        SkipUntilIfDefCount0 := True;
        while Token <> '}' do
          inherited NextToken(SkipBlanks);
        Continue;
      end;
    end
    else
      if TokenSymbolIs('ENDIF') then
    begin
      if SkipUntilIfDefCount0 then
      begin
        Dec(IfDefCount);
        if IfDefCount > 0 then
          Continue;

        SkipUntilIfDefCount0 := False;

        while Token <> '}' do
          inherited NextToken(SkipBlanks);
        Continue;
      end;

      while Token <> '}' do
        inherited NextToken(SkipBlanks);
      Continue;
    end
    else
      if TokenSymbolIs('ELSE') then
    begin
      if SkipUntilIfDefCount0 then
      begin
        if IfDefCount = 1 then
          Dec(IfDefCount);
        if IfDefCount > 0 then
          Continue;

        SkipUntilIfDefCount0 := False;

        while Token <> '}' do
          inherited NextToken(SkipBlanks);
        Continue;
      end;

      inherited NextToken(SkipBlanks);

      if not FLastCompilerDirectiveAccepted then
      begin
        while Token <> '}' do
          inherited NextToken(SkipBlanks);
        Continue;
      end
      else
      begin
        IfDefCount := 1;
        SkipUntilIfDefCount0 := True;
        while Token <> '}' do
          inherited NextToken(SkipBlanks);
        Continue;
      end;
    end
    else
    begin
      while Token <> '}' do
        inherited NextToken(SkipBlanks);
      Continue;
    end;
  end;
end;

procedure TDelphiParser.SetAcceptCompilerDirectives(const Value: TStrings);
begin
  FAcceptCompilerDirectives.Assign(Value);
end;

procedure TDelphiParser.SkipUntilToken(T: Char);
begin
  { PRE  :
    POST : Token staat op ; of #0
  }
  while not (Token in [T, toEof]) do
    NextToken;
end;

procedure TDelphiParser.ReadInterfaceMethods(
  AInterfaceItem: TInterfaceItem; const AddToList: Boolean);
begin
  while True do
  begin
    case Token of
      toSymbol:
        begin
          if TokenSymbolIs('end') then
          begin
            SkipUntilToken(toSemiColon); //SkipUntilSemiColon;
            CheckToken(toSemiColon);
            NextToken;
            Exit;
          end
          else
            if TokenSymbolIs('property') then
          begin
            ReadClass_Property(AInterfaceItem, inPublic, AddToList);
            { Token is eerste token na ; }
            Continue;
          end
          else
            if TokenSymbolIs('procedure') then
          begin
            ReadClass_Procedure(AInterfaceItem, inPublic, AddToList, False);
            { Token is eerste token na ; }
            Continue;
          end
          else
            if TokenSymbolIs('function') then
          begin
            ReadClass_Function(AInterfaceItem, inPublic, AddToList, False);
            { Token is eerste token na ; }
            Continue;
          end;
        end;
      toEof:
        Error('Unexpected end of file');
    end;
    NextToken;
  end;
end;

procedure TDelphiParser.ReadType(const ATypeName: string; const AddToList: Boolean);
begin
  if Token = toHaakjeOpen then
    ReadEnumerator(ATypeName, AddToList)
  else
    if TokenSymbolIs('record') then
    ReadRecord(ATypeName, AddToList)
  else
    if TokenSymbolIs('class') then
    ReadClass(ATypeName, AddToList)
  else
    if TokenSymbolIs('procedure') then
    ReadProcedureType(ATypeName, AddToList)
  else
    if TokenSymbolIs('function') then
    ReadFunctionType(ATypeName, AddToList)
  else
    if TokenSymbolIs('interface') then
    ReadInterfaceType(ATypeName, AddToList)
  else
    if TokenSymbolIs('dispinterface') then
    ReadDispInterface(ATypeName, AddToList)
  else
    if TokenSymbolIs('packed') then
  begin
    NextToken;
    CheckToken(toSymbol);
    if TokenSymbolIs('record') then
      ReadRecord(ATypeName, AddToList)
    else
      if TokenSymbolIs('array') then
      ReadSimpleType(ATypeName, AddToList)
    else
      Error('record or array expected');
  end
  else
    ReadSimpleType(ATypeName, AddToList)
end;

procedure TDelphiParser.SkipUntilTokenInHaak(T: Char; const InitHaak: Integer);
var
  Haakjes: Integer;
begin
  { TODO: Post conditie veranderen: Token staat op ; }

  { PRE  :
    POST : Token staat op ; of #0 en heeft een 'in-de-haak' reeks afgelegd
  }
  Haakjes := InitHaak;
  while True do
  begin
    case Token of
      toHaakjeOpen:
        Inc(Haakjes);
      toHaakjeSluiten:
        Dec(Haakjes);
      toEof:
        Exit;
    end;
    if Token = T then
      if Haakjes <= 0 then
        Exit;
    NextToken;
  end;
end;

function TDelphiParser.ExecuteFile(const AFileName: string): Boolean;
var
  LStream: TFileStream;
begin
  Result := FileExists(AFileName);
  if not Result then
    Exit;

  Result := False;
  FTypeList.FileName := AFileName;

  LStream := TFileStream.Create(AFileName, fmOpenRead, fmShareDenyWrite);
  try
    Result := Execute(LStream);
  finally
    FreeAndNil(LStream);
  end;
end;

procedure TDelphiParser.SkipUntilTokenInHaak(OpenHaak, CloseHaak: Char;
  const InitHaak: Integer);
var
  Haakjes: Integer;
begin
  if OpenHaak = CloseHaak then
    Error('Internal error: OpenHaak = CloseHaak');
  Haakjes := InitHaak;
  while True do
  begin
    if Token = OpenHaak then
      Inc(Haakjes)
    else
      if Token = CloseHaak then
    begin
      Dec(Haakjes);
      if Haakjes = 0 then
        Exit;
    end
    else
      if Token = toEof then
      Exit;
    NextToken;
  end;
end;

procedure TDelphiParser.ReadConstantExpression(
  const ExpectDotDot: Boolean);
begin
  { Post : token staat op ; of op end of op ) }

  while True do
  begin
    CheckNotToken(toEof);

    if TokenSymbolIn(CAllowableSymbolsInTypeDef) >= 0 then
      SkipUntilTokenInHaak('(', ')')
    else
      if TokenSymbolIs('end') then
      Exit
    else
      case Token of
        toHaakjeSluiten:
          Exit;
        toHaakjeOpen:
          begin
            SkipUntilTokenInHaak('(', ')');
            NextToken;
          end;
        toDot:
          if ExpectDotDot then
          begin
            NextToken;
            if Token = toDot then
            begin
              NextToken;
              CheckNotToken(toDot);
              ReadConstantExpression(False);
              Exit;
            end;
          end
          else
          begin
            NextToken;
            CheckNotToken(toDot);
          end;
        toSemiColon:
          Exit;
      end;
    NextToken;
  end;
end;

procedure TDelphiParser.ReadConstValue;
begin
  if Token = '(' then
  begin
    SkipUntilTokenInHaak('(', ')');
    NextToken;
    CheckToken(toSemiColon);
  end
  else
    SkipUntilToken(toSemiColon);
end;

{ TDtxCompareParser }

constructor TDtxCompareParser.Create;
begin
  inherited;
  FList := TStringList.Create;
  TStringList(FList).Sorted := True;
end;

destructor TDtxCompareParser.Destroy;
begin
  FList.Free;
  inherited;
end;

function TDtxCompareParser.Execute(const AFileName: string): Boolean;
begin
  FErrors := [];
  FDefaultTexts := [];

  Result := FileExists(AFileName);
  if not Result then
    Exit;

  FStream := TFileStream.Create(AFileName, fmOpenRead, fmShareDenyWrite);
  try
    FList.Clear;
    Init;
    Result := Parse;
  finally
    FreeAndNil(FStream);
  end;
end;

const
  CDefaultText: array[TDefaultText] of PChar = (
    'write here a summary (1 line)',
    'write here a description',
    'this type is used by (for reference):',
    'list here other properties, methods',
    'remove the ''see also'' section if there are no references',
    'describe here what the function returns',
    'this is an overridden method, you don''t have to describe these',
    'if it does the same as the inherited method',
    'description for'
    );

function TDtxCompareParser.GeTDtxCompareTokenType: TDtxCompareTokenType;
var
  S: string;
begin
  S := TokenString;
  if Length(S) > 2 then
  begin
    if (S[1] = '@') and (S[2] = '@') then
      Result := ctHelpTag
    else
      if (S[1] = '#') and (S[2] = '#') then
      Result := ctParseTag
    else
      if (S[1] = '-') and (S[2] = '-') then
      Result := ctSeperator
    else
      Result := ctText;
  end
  else
    Result := ctText;
end;

function TDtxCompareParser.Parse: Boolean;
begin
  FErrors := [defNoPackageTag, defNoStatusTag, defNoAuthor];

  ReadStartBlock;
  ReadRest;
  Result := True;
end;

procedure TDtxCompareParser.ReadAuthor;
begin
  NextToken;
  if CompareTokenType = ctText then
    Exclude(FErrors, defNoAuthor);
end;

procedure TDtxCompareParser.ReadJVCLINFO;
begin
  NextToken;

  { first expect 'GROUP=', abort if not found }

  if StrLComp(PChar(TokenString), 'GROUP=', 6) <> 0 then
  begin
    Include(FErrors, defJVCLInfoFlag);
    Include(FErrors, defJVCLInfoGroup);
    Exit;
  end;

  { Search until 'FLAG=' found }
  repeat
    if Pos('?', TokenString) > 0 then
      Include(FErrors, defJVCLInfoGroup);
    NextToken;
  until (Token = toEof) or (StrLComp(PChar(TokenString), 'FLAG=', 5) = 0);

  if Pos('?', TokenString) > 0 then
    Include(FErrors, defJVCLInfoFlag);
end;

function TDtxCompareParser.ReadNextToken: Char;
var
  P: PChar;

  procedure NextChar;
  begin
    Inc(P);
    if P^ = #10 then
      Inc(FSourceLine);
  end;
begin
  SkipBlanks;
  P := FSourcePtr;
  FTokenPtr := P;
  case P^ of
    #32..#255:
      begin
        NextChar;
        while P^ in [#33..#255] do
          NextChar;
        Result := toSymbol;
      end;
  else
    Result := P^;
    if Result <> toEof then
      NextChar;
  end;
  FSourcePtr := P;
  FToken := Result;
end;

procedure TDtxCompareParser.ReadPackage;
begin
  Exclude(FErrors, defNoPackageTag);

  NextToken;
  while (Token <> toEof) and (CompareTokenType = ctText) do
  begin
    if Pos('?', TokenString) > 0 then
      Include(FErrors, defPackageTagNotFilled);

    NextToken;
  end;
end;

procedure TDtxCompareParser.ReadRest;
type
  TState = (stNone, stSee);

  procedure CheckDefaultText(var ACheck: string);
  var
    DefaultText: TDefaultText;
  begin
    for DefaultText := Low(TDefaultText) to High(TDefaultText) do
      if StrLIComp(PChar(ACheck), CDefaultText[DefaultText], Length(ACheck)) = 0 then
      begin
        if Length(ACheck) = Length(CDefaultText[DefaultText]) then
        begin
          ACheck := '';
          Include(FDefaultTexts, DefaultText);
        end;
        Exit;
      end;
    ACheck := '';
  end;

var
  Check: string;
  S: string;
  State: TState;
begin
  Check := '';
  State := stNone;

  while Token <> toEof do
  begin
    S := TokenString;
    case CompareTokenType of
      ctHelpTag:
        begin
          FList.Add(S);
          Check := '';
        end;
      ctText:
        begin
          { check defaults }
          if Check = '' then
            Check := S
          else
            Check := Check + ' ' + S;
          CheckDefaultText(Check);
          if Check = '' then
            Check := S;
          if (State = stNone) and TokenSymbolIsExact('See') then
            State := stSee
          else
            if (State = stSee) and TokenSymbolIsExact('Also') then
          begin
            ReadSeeAlso;
            State := stNone;
          end
          else
            State := stNone;
          if TokenSymbolIsExact('JVCLInfo') then
          begin
            ReadJVCLINFO;
            State := stNone;
          end;
        end
    else
      Check := '';
    end;

    ReadNextToken;
  end;
end;

procedure TDtxCompareParser.ReadSeeAlso;
begin
  NextToken;
  if CompareTokenType <> ctText then
    Include(FErrors, defEmptySeeAlso);
end;

procedure TDtxCompareParser.ReadStartBlock;
type
  TState = (stNone, stPasTagRead, stSummaryRead, stAuthorRead);
var
  LState: TState;
begin
  LState := stNone;
  {

  ##Package: SomePackage
  ##Status: SomeComment
  ----------------------------------------------------------------------------------------------------
  @@Somefile.pas
  Summary
    SomeSummary
  <INCLUDE JVCL.UnitText.dtx>
  Author
    SomeAuthor
  ----------------------------------------------------------------------------------------------------
  }
  { Assume first @@Somefile.pas then Summary then Author }

  while (Token <> toEof) and (LState <> stAuthorRead) do
    case CompareTokenType of
      ctHelpTag:
        begin
          FList.Add(TokenString);
          if (LState = stNone) and
            SameText(Copy(TokenString, Length(TokenString) - 3, 4), '.pas') then
            LState := stPasTagRead;
          NextToken;
        end;
      ctParseTag:
        if TokenSymbolIs('##package:') then
          ReadPackage
        else
          if TokenSymbolIs('##status:') then
          ReadStatus
        else
          NextToken;
      ctText:
        if (LState = stPasTagRead) and TokenSymbolIs('summary') then
        begin
          LState := stSummaryRead;
          NextToken;
        end
        else
          if (LState = stSummaryRead) and TokenSymbolIs('author') then
        begin
          LState := stAuthorRead;
          ReadAuthor;
        end
        else
          NextToken;
      ctSeperator:
        NextToken;
    else
      NextToken;
    end;
end;

procedure TDtxCompareParser.ReadStatus;
begin
  Exclude(FErrors, defNoStatusTag);
  NextToken;
end;

{ TFunctionParser }

constructor TFunctionParser.Create;
begin
  inherited;
  FFunctions := TStringList.Create;
  FSkipped := TStringList.Create;
end;

destructor TFunctionParser.Destroy;
begin
  FFunctions.Free;
  FSkipped.Free;
  //FList.Free;
  inherited;
end;

function TFunctionParser.ExecuteFile(const AFileName: string): Boolean;
begin
  FFileName := ExtractFileName(AFileName);

  Result := inherited ExecuteFile(AFileName);
end;

procedure TFunctionParser.Init;
begin
  inherited Init;
  FFunctions.Clear;
  FSkipped.Clear;
end;

function TFunctionParser.Parse: Boolean;
begin
  Result := False;
  try
    ReadUntilImplementationBlock;
    while ReadUntilFunction do
      ReadFunction;
    Result := True;
  except
    on E: Exception do
      FErrorMsg := E.Message;
  end;
end;

procedure TFunctionParser.ReadFunction;

  function CheckAllChars(const S: string): Boolean;
  var
    I: Integer;
  begin
    Result := True;
    I := 0;
    while Result and (I < Length(S)) do
    begin
      Result := S[I + 1] in ['a'..'z', 'A'..'Z', '0'..'9', '_'];
      Inc(I);
    end;
  end;

var
  S: string;
begin
  NextToken;
  S := TokenString;
  if not CheckAllChars(S) then
  begin
    FSkipped.Add(S);
    Exit;
  end;

  NextToken;
  if TokenString <> '.' then
  begin
    FFunctions.Add(Format('%s (%s)', [S, FFileName]));
  end;
end;

function TFunctionParser.ReadUntilFunction: Boolean;
begin
  while (Token <> toEof) and not TokenSymbolIs('function')
    and not TokenSymbolIs('procedure') do

    if TokenSymbolIs('class') then
      ReadClass('dummy', False)
    else
      NextToken;

  Result := Token <> toEof;
end;

procedure TFunctionParser.ReadUntilImplementationBlock;
begin
  SkipUntilSymbol('implementation');
end;

function TBasicParser.GetRecordStrWithCurrentToken: string;
begin
  Result := FRecordStr + ' ' + TokenString;
end;

{ TDpkParser }

constructor TDpkParser.Create;
begin
  inherited;
  FList := TStringList.Create;
  TStringList(FList).Sorted := True;
end;

destructor TDpkParser.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TDpkParser.Init;
begin
  inherited Init;
  FList.Clear;
end;

function TDpkParser.Parse: Boolean;
begin
  Result := False;
  try
    ReadUntilContainsBlock;
    while ReadFileReference do
      ;
    {while ReadUntilFunction do
      ReadFunction;}
    Result := True;
  except
    on E: Exception do
      FErrorMsg := E.Message;
  end;
end;

function TDpkParser.ReadFileReference: Boolean;
begin
  NextToken;
  Result := (Token = toSymbol) and not TokenSymbolIs('end');
  if not Result then
    Exit;

  List.Add(TokenString);
  ReadNextToken;
  while not (Token in [',', toSemiColon, toEof]) do
    ReadNextToken;
end;

procedure TDpkParser.ReadUntilContainsBlock;
begin
  SkipUntilSymbol('contains');
end;

{ TRegisteredClassesParser }

constructor TRegisteredClassesParser.Create;
begin
  inherited Create;
  FList := TStringList.Create;
  TStringList(FList).Sorted := True;
end;

destructor TRegisteredClassesParser.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TRegisteredClassesParser.Init;
begin
  inherited Init;
  FList.Clear;
end;

function TRegisteredClassesParser.Parse: Boolean;
begin
  Result := False;
  try
    if not ReadUntilRegisterBlock then
    begin
      Result := True;
      Exit;
    end;
    while ReadUntilRegisterComponentsBlock and ReadRegisterComponentsBlock do
      ;
    Result := True;
  except
    on E: Exception do
      FErrorMsg := E.Message;
  end;
end;

function TRegisteredClassesParser.ReadRegisterComponentsBlock: Boolean;
begin
  { PRE : Token = 'RegisterComponents'
    POST: Token = token after ; or )

   vb:

    RegisterComponents(x, [C1]);
    RegisterComponents(x, [C1, C2, C3]);
  }

  NextToken;
  CheckToken('(');
  SkipUntilToken(',');
  CheckToken(',');
  NextToken;
  CheckToken('[');
  NextToken;
  CheckToken(toSymbol);
  List.Add(TokenString);
  NextToken;
  while Token = ',' do
  begin
    NextToken;
    CheckToken(toSymbol);
    List.Add(TokenString);
    NextToken;
  end;
  CheckToken(']');
  NextToken;
  CheckToken(toHaakjeSluiten);
  NextToken;
  if Token = toSemiColon then
    NextToken;
  Result := Token <> toEof;
end;

function TRegisteredClassesParser.ReadUntilRegisterBlock: Boolean;
begin
  while (Token <> toEof) and not TokenSymbolIsExact('Register') and not TokenSymbolIs('implementation') do
    NextToken;

  Result := TokenSymbolIsExact('Register');
end;

function TRegisteredClassesParser.ReadUntilRegisterComponentsBlock: Boolean;
begin
  SkipUntilSymbol('RegisterComponents');
  Result := TokenSymbolIs('RegisterComponents');
end;

function TBasicParser.TokenSymbolIsExact(const S: string): Boolean;
begin
  Result := (Token = toSymbol) and (CompareStr(S, TokenString) = 0);
end;

{ TPasCheckParser }

function TPasCheckParser.ExecuteFile(const AFileName: string): Boolean;
var
  FindData: TWin32FindData;
  Handle: THandle;
begin
  { TODO : Naar init }
  FErrors := [pefNoLicense];

  Result := FileExists(AFileName);
  if not Result then
    Exit;

  Handle := FindFirstFile(PChar(AFileName), FindData);
  Result := Handle <> INVALID_HANDLE_VALUE;
  if not Result then
    Exit;

  Windows.FindClose(Handle);
  FFileName := ChangeFileExt(FindData.cFileName, '');

  Result := inherited ExecuteFile(AFileName);
end;

function TPasCheckParser.Parse: Boolean;
begin
  Result := False;
  try
    ReadCommentBlock;
    ReadUnitName;

    Result := True;
  except
    on E: Exception do
      FErrorMsg := E.Message;
  end;
end;

procedure TPasCheckParser.ReadCommentBlock;
const
  CLicenseText = 'The contents of this file are subject to the';
var
  LicenseFound: Boolean;
begin
  LicenseFound := False;
  while Token = toComment do
  begin
    LicenseFound := LicenseFound or
      (Pos(CLicenseText, TokenString) > 0);
    NextToken(False);
  end;
  if LicenseFound then
    Exclude(FErrors, pefNoLicense);
end;

procedure TPasCheckParser.ReadUnitName;
begin
  while (Token <> toEof) and not TokenSymbolIs('unit') do
    NextToken;
  NextToken;
  CheckToken(toSymbol);
  FUnitName := TokenString;
  if CompareStr(FUnitName, FFileName) <> 0 then
    Include(FErrors, pefUnitCase);
end;

{ TPasCasingParser }

constructor TPasCasingParser.Create;
begin
  inherited Create;
  FList := TStringList.Create;
  with FList as TStringList do
  begin
    Duplicates := dupIgnore;
    CaseSensitive := True;
    Sorted := True;
  end;
end;

destructor TPasCasingParser.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

function TPasCasingParser.Parse: Boolean;
var
  I: Integer;
  Item: TAbstractItem;
begin
  if AllSymbols then
  begin
    Result := False;
    try
      while Token <> toEof do
      begin
        if Token = toSymbol then
          FList.AddObject(TokenString, TObject(ID));
        NextToken;
      end;

      Result := True;
    except
      on E: Exception do
        FErrorMsg := E.Message;
    end
  end
  else
  begin
    Result := inherited Parse;
    if not Result then
      Exit;

    for I := 0 to FTypeList.Count - 1 do
    begin
      Item := TAbstractItem(FTypeList[I]);
      FList.AddObject(Item.SimpleName, TObject(ID));

      if Item is TClassProperty then
        FList.AddObject(TClassProperty(Item).TypeStr, TObject(ID));
    end;
  end;
end;

procedure TBasicParser.CheckNotToken(T: Char);
begin
  if Token = T then
    case T of
      toSymbol:
        Error(SNotIdentifierExpected);
      toString, toWString:
        Error(SNotStringExpected);
      toInteger, toFloat:
        Error(SNotNumberExpected);
      toEof:
        Error(SNotEofExpected);
    else
      ErrorFmt(SNotCharExpected, [T]);
    end;
end;

end.

