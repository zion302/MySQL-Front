unit FreeSQLParser;

interface {********************************************************************}

uses
  Classes,
  SQLUtils,
  fspTypes, fspConst;

type
  TCustomSQLParser = class
  protected
    type
      TOrigin = record X, Y: Integer; end;

      TWordList = class(TObject)
      private
        FCount: Integer;
        FIndex: array of PChar;
        FFirst: array of Integer;
        FParser: TCustomSQLParser;
        FText: string;
        function GetWord(Index: Integer): string;
        procedure SetText(AText: string);
      protected
        procedure Clear();
        property Parser: TCustomSQLParser read FParser;
      public
        constructor Create(const ASQLParser: TCustomSQLParser; const AText: string = '');
        destructor Destroy(); override;
        function IndexOf(const Word: PChar; const Length: Integer): Integer;
        property Count: Integer read FCount;
        property Text: string read FText write SetText;
        property Word[Index: Integer]: string read GetWord; default;
      end;

  public
    type
      PNode = ^TNode;
      PDeletedNode = ^TDeletedNode;
      PToken = ^TToken;
      PRangeNode = ^TRangeNode;
      PRoot = ^TRoot;
      PStmtNode = ^TStmtNode;
      PSiblings = ^TSiblings;
      PStmt = ^TStmt;
      PExpressions = ^TExpressions;
      PDbIdentifier = ^TDbIdentifier;
      PFunction = ^TFunction;
      PUnaryOperation = ^TUnaryOperation;
      PBinaryOperation = ^TBinaryOperation;
      PBetweenOperation = ^TBetweenOperation;
      PCaseCond = ^TCaseCond;
      PCaseOp = ^TCaseOp;
      PSoundsLikeOperation = ^TSoundsLikeOperation;

      TParseFunction = function(): ONode of object;

      TNode = packed record
      private
        FNodeType: TNodeType;
        FParser: TCustomSQLParser;
      private
        class function Create(const AParser: TCustomSQLParser; const ANodeType: TNodeType): ONode; static;
        function GetOffset(): ONode; {$IFNDEF Debug} inline; {$ENDIF}
        property Offset: Integer read GetOffset;
      public
        property NodeType: TNodeType read FNodeType;
        property Parser: TCustomSQLParser read FParser;
      end;

      TStmtNode = packed record  // Virtual node for TRangeNode / TToken
      private
        Heritage: TNode;
        FParentNode: ONode;
      private
        function GetFFirstToken(): ONode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFirstToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFLastToken(): ONode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetNextSibling(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetParentNode(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        property FFirstToken: ONode read GetFFirstToken;
        property FLastToken: ONode read GetFLastToken;
      public
        property FirstToken: PToken read GetFirstToken;
        property LastToken: PToken read GetLastToken;
        property NextSibling: PNode read GetNextSibling;
        property NodeType: TNodeType read Heritage.FNodeType;
        property ParentNode: PNode read GetParentNode;
        property Parser: TCustomSQLParser read Heritage.FParser;
      end;

      TToken = packed record
      private
        Heritage: TStmtNode;
      private
        FErrorCode: Integer;
        FKeywordIndex: Integer;
        FMySQLVersion: Integer;
        FOperatorType: TOperatorType;
        FOrigin: TOrigin;
        FPriorToken: ONode;
        FText: packed record
          SQL: PChar;
          Length: Integer;
          NewText: string;
        end;
        FTokenType: TTokenType;
        FUsageType: TUsageType;
        class function Create(const AParser: TCustomSQLParser;
          const ASQL: PChar; const ALength: Integer; const AOrigin: TOrigin;
          const AErrorCode: Integer; const AMySQLVersion: Integer; const ATokenType: TTokenType;
          const AOperatorType: TOperatorType; const AKeywordIndex: Integer): ONode; static;
        function GetAsString(): string;
        function GetDbIdentifierType(): TDbIdentifierType;
        function GetErrorMessage(): string;
        function GetGeneration(): Integer;
        function GetIndex(): Integer;
        function GetIsUsed(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
        function GetNextToken(): PToken;
        function GetOffset(): ONode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetParentNode(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetText(): string;
        procedure SetText(AText: string);
        property FParentNode: ONode read Heritage.FParentNode write Heritage.FParentNode;
        property Generation: Integer read GetGeneration;
        property Index: Integer read GetIndex;
        property Offset: Integer read GetOffset;
      public
        property AsString: string read GetAsString;
        property DbIdentifierType: TDbIdentifierType read GetDbIdentifierType;
        property ErrorCode: Integer read FErrorCode;
        property ErrorMessage: string read GetErrorMessage;
        property IsUsed: Boolean read GetIsUsed;
        property KeywordIndex: Integer read FKeywordIndex;
        property MySQLVersion: Integer read FMySQLVersion;
        property NextToken: PToken read GetNextToken;
        property NodeType: TNodeType read Heritage.Heritage.FNodeType;
        property OperatorType: TOperatorType read FOperatorType;
        property Origin: TOrigin read FOrigin;
        property ParentNode: PNode read GetParentNode;
        property Parser: TCustomSQLParser read Heritage.Heritage.FParser;
        property Text: string read GetText write SetText;
        property TokenType: TTokenType read FTokenType;
        property UsageType: TUsageType read FUsageType;
      end;

      TRangeNode = packed record
      private
        Heritage: TStmtNode;
        FFirstToken: ONode;
        FLastToken: ONode;
        property FParentNode: ONode read Heritage.FParentNode write Heritage.FParentNode;
      private
        class function Create(const AParser: TCustomSQLParser; const ANodeType: TNodeType): ONode; static;
        function GetFirstToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOffset(): ONode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetParentNode(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        procedure AddChild(const ChildNode: ONode);
        property Offset: ONode read GetOffset;
      public
        property FirstToken: PToken read GetFirstToken;
        property LastToken: PToken read GetLastToken;
        property NodeType: TNodeType read Heritage.Heritage.FNodeType;
        property Parser: TCustomSQLParser read Heritage.Heritage.FParser;
        property ParentNode: PNode read GetParentNode;
      end;

      TDeletedNode = packed record
      private
        Heritage: TRangeNode;
        property FNodeType: TNodeType read Heritage.Heritage.Heritage.FNodeType write Heritage.Heritage.Heritage.FNodeType;
      private
        FNodeSize: Integer;
      end;

      TRoot = packed record
      private
        Heritage: TRangeNode;
        property FFirstToken: ONode read Heritage.FFirstToken write Heritage.FFirstToken;
        property FLastToken: ONode read Heritage.FLastToken write Heritage.FLastToken;
      private
        FFirstStmt: ONode;
        FLastStmt: ONode;
        class function Create(const AParser: TCustomSQLParser): ONode; static;
        function GetFirstStmt(): PStmt; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFirstToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastStmt(): PStmt; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
      public
        property FirstStmt: PStmt read GetFirstStmt;
        property FirstToken: PToken read GetFirstToken;
        property LastStmt: PStmt read GetLastStmt;
        property LastToken: PToken read GetLastToken;
        property NodeType: TNodeType read Heritage.Heritage.Heritage.FNodeType;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      TSiblings = packed record
      private
        Heritage: TRangeNode;
        FFirstSibling: ONode;
      private
        procedure AddSibling(const ASibling: ONode);
        class function Create(const AParser: TCustomSQLParser; const ANodeType: TNodeType): ONode; static;
        function GetFirstChild(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
      public
        property FirstChild: PNode read GetFirstChild;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      TExpressions = packed record
      private
        Heritage: TSiblings;
      public
        class function Create(const AParser: TCustomSQLParser): ONode; static; {$IFNDEF Debug} inline; {$ENDIF}
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      TDbIdentifier = packed record
      private
        Heritage: TRangeNode;
        FPrefix1: ONode;
        FPrefix2: ONode;
        FDbIdentifierType: TDbIdentifierType;
        FIdentifier: ONode;
        procedure AddPrefix(const APrefix, ADot: ONode);
        function GetIdentifier(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetParentNode(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetPrefix1(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetPrefix2(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
      public
        class function Create(const AParser: TCustomSQLParser; const AIdentifier: ONode; const ADbIdentifierType: TDbIdentifierType = ditUnknown): ONode; static;
        property DbIdentifierType: TDbIdentifierType read FDbIdentifierType;
        property Identifier: PToken read GetIdentifier;
        property LastToken: PToken read GetLastToken;
        property ParentNode: PNode read GetParentNode;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
        property Prefix1: PToken read GetPrefix1;
        property Prefix2: PToken read GetPrefix2;
      end;

      TFunction = packed record
      private
        Heritage: TRangeNode;
      private
        FArguments: ONode;
        FIdentifier: ONode;
        function GetArguments(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetIdentifier(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
      public
        class function Create(const AParser: TCustomSQLParser; const AIdentifier, AArguments: ONode): ONode; static;
        property Arguments: PStmtNode read GetArguments;
        property Identifier: PStmtNode read GetIdentifier;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      TUnaryOperation = packed record
      private
        Heritage: TRangeNode;
      private
        FOperand: ONode;
        FOperator: ONode;
        function GetOperand(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperator(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
      public
        class function Create(const AParser: TCustomSQLParser; const AOperator, AOperand: ONode): ONode; static;
        property Operand: PStmtNode read GetOperand;
        property Operator: PStmtNode read GetOperator;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      TBinaryOperation = packed record
      private
        Heritage: TRangeNode;
      private
        FOperand1: ONode;
        FOperand2: ONode;
        FOperator: ONode;
        function GetOperand1(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperand2(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperator(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
      public
        class function Create(const AParser: TCustomSQLParser; const AOperator, AOperand1, AOperand2: ONode): ONode; static;
        property Operand1: PStmtNode read GetOperand1;
        property Operand2: PStmtNode read GetOperand2;
        property Operator: PStmtNode read GetOperator;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PUser = ^TUser;
      TUser = packed record
      private type
        TNodes = record
          NameToken: ONode;
          AtToken: ONode;
          HostToken: ONode;
        end;
      private
        Heritage: TRangeNode;
      private
        FNodes: TNodes;
        class function Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode; static;
      public
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      TBetweenOperation = packed record
      private
        Heritage: TRangeNode;
      private
        FExpr: ONode;
        FMax: ONode;
        FMin: ONode;
        FOperator1: ONode;
        FOperator2: ONode;
        function GetExpr(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetMax(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetMin(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperator1(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperator2(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
      public
        class function Create(const AParser: TCustomSQLParser; const AOperator1, AOperator2: ONode; const AExpr, AMin, AMax: ONode): ONode; static;
        property Expr: PStmtNode read GetExpr;
        property Max: PStmtNode read GetMax;
        property Min: PStmtNode read GetMin;
        property Operator1: PToken read GetOperator1;
        property Operator2: PToken read GetOperator2;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      TCaseCond = packed record
      private
        Heritage: TRangeNode;
      private
        FConditionValue: ONode;
        FResultValue: ONode;
        function GetConditionValue(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetNextCond(): PCaseCond; {$IFNDEF Debug} inline; {$ENDIF}
        function GetResultValue(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
      public
        class function Create(const AParser: TCustomSQLParser; const AConditionValue, AResultValue: ONode): ONode; static;
        property ConditionValue: PStmtNode read GetConditionValue;
        property NextCond: PCaseCond read GetNextCond;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
        property ResultValue: PStmtNode read GetResultValue;
      end;

      TCaseOp = packed record
      private
        Heritage: TSiblings;
      private
        FElseValue: ONode;
        FReferenceValue: ONode;
        procedure AddCondition(const AConditionValue, AResultValue: ONode);
        function GetFirstCond(): PCaseCond; {$IFNDEF Debug} inline; {$ENDIF}
        function GetReferenceValue(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        procedure SetElse(const AElseValue: ONode);
      public
        class function Create(const AParser: TCustomSQLParser; const AReferenceValue: ONode): ONode; static;
        property FirstCond: PCaseCond read GetFirstCond;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
        property ReferenceValue: PStmtNode read GetReferenceValue;
      end;

      TSoundsLikeOperation = packed record
      private
        Heritage: TRangeNode;
      private
        FOperand1: ONode;
        FOperand2: ONode;
        FOperator1: ONode;
        FOperator2: ONode;
        function GetOperand1(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperand2(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperator1(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperator2(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
      public
        class function Create(const AParser: TCustomSQLParser; const AOperator1, AOperator2: ONode; const AOperand1, AOperand2: ONode): ONode; static;
        property Operand1: PStmtNode read GetOperand1;
        property Operand2: PStmtNode read GetOperand2;
        property Operator1: PToken read GetOperator1;
        property Operator2: PToken read GetOperator2;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PPLSQLCondPart = ^TPLSQLCondPart;
      TPLSQLCondPart = packed record
      private
        Heritage: TRangeNode;
      private
        FExpression: ONode;
        FOperator: ONode;
        FThen: ONode;
      private
        procedure AddStmt(const AStmt: ONode); {$IFNDEF Debug} inline; {$ENDIF}
        class function Create(const AParser: TCustomSQLParser; const AOperatorToken, AExpression, AThenToken: ONode): ONode; static;
      public
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      TStmt = packed record
      private
        Heritage: TRangeNode;
        FStmtType: TStmtType;
        FErrorCode: Integer;
        FErrorToken: ONode;
        property FFirstToken: ONode read Heritage.FFirstToken write Heritage.FFirstToken;
        property FLastToken: ONode read Heritage.FLastToken write Heritage.FLastToken;
        property FParentNode: ONode read Heritage.Heritage.FParentNode write Heritage.Heritage.FParentNode;
      private
        class function Create(const AParser: TCustomSQLParser; const AStmtType: TStmtType): ONode; static;
        function GetError(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
        function GetErrorMessage(): string;
        function GetErrorToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFirstToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetNextStmt(): PStmt;
      public
        property Error: Boolean read GetError;
        property ErrorCode: Integer read FErrorCode;
        property ErrorMessage: string read GetErrorMessage;
        property ErrorToken: PToken read GetErrorToken;
        property FirstToken: PToken read GetFirstToken;
        property LastToken: PToken read GetLastToken;
        property NextStmt: PStmt read GetNextStmt;
        property NodeType: TNodeType read Heritage.Heritage.Heritage.FNodeType;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
        property StmtType: TStmtType read FStmtType;
      end;

      PCreateRoutineStmt = ^TCreateRoutineStmt;
      TCreateRoutineStmt = packed record
      private type
        TNodes = record
          CreateToken: ONode;
          Definer: record
            IdentifierToken: ONode;
            AssignToken: ONode;
            Value: record
              NameToken: ONode;
              AtToken: ONode;
              HostToken: ONode;
            end;
          end;
          RoutineToken: ONode;
          IdentifierNode: ONode;
          Parameter: ONode;
          Return: record
            ReturnsToken: ONode;
            ReturnsDataTypeNode: ONode;
          end;
          CommentToken: ONode;
          CommentStringNode: ONode;
          Language: record
            LanguageToken: ONode;
            SQLToken: ONode;
          end;
          Deterministic: record
            NotToken: ONode;
            DeterministicToken: ONode;
          end;
          Characteristic: record
            ContainsToken: ONode;
            SQLToken: ONode;
            NoToken: ONode;
            ReadsToken: ONode;
            DataToken: ONode;
            ModifiesToken: ONode;
          end;
          Security: record
            SQLToken: ONode;
            SecurityToken: ONode;
            DefinerToken: ONode;
            InvokerToken: ONode;
          end;
          SelectStmt: ONode;
        end;
        TRoutineType = (rtFunction, rtRoutine);
      private
        Heritage: TStmt;
        FNodes: TNodes;
        class function Create(const ARoutineType: TRoutineType; const AParser: TCustomSQLParser; const ANodes: TNodes): ONode; static;
      end;

      PCreateViewStmt = ^TCreateViewStmt;
      TCreateViewStmt = packed record
      private type
        TNodes = record
          CreateTag: ONode;
          OrReplaceTag: ONode;
          AlgorithmValue: ONode;
          DefinerNode: ONode;
          SQLSecurityTag: ONode;
          ViewTag: ONode;
          IdentifierNode: ONode;
          Columns: ONode;
          AsTag: ONode;
          SelectStmt: ONode;
          OptionTag: ONode;
        end;
      private
        Heritage: TStmt;
        FNodes: TNodes;
        class function Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode; static;
      end;

      PSelectStmt = ^TSelectStmt;
      TSelectStmt = packed record
      private
        Heritage: TStmt;
      public
        type
          PColumns = ^TColumns;
          PTables = ^TTables;

          PColumn = ^TColumn;
          TColumn = packed record
          private
            Heritage: TRangeNode;
            property FParentNode: ONode read Heritage.Heritage.FParentNode write Heritage.Heritage.FParentNode;
          private
            FAsToken: ONode;
            FAlias: ONode;
            FExpression: ONode;
            function GetAlias(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
            function GetAsToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
            function GetColumns(): PColumns; {$IFNDEF Debug} inline; {$ENDIF}
            function GetDisplayName(): string;
            function GetExpression(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
          public
            class function Create(const AParser: TCustomSQLParser; const AValue, AAsToken, AAlias: ONode): ONode; static;
            property Alias: PToken read GetAlias;
            property AsToken: PToken read GetAsToken;
            property Columns: PColumns read GetColumns;
            property DisplayName: string read GetDisplayName;
            property Expression: PStmtNode read GetExpression;
            property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
          end;

          TColumns = packed record
          private
            Heritage: TSiblings;
          public
            class function Create(const AParser: TCustomSQLParser): ONode; static;
            property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
          end;

          PTable = ^TTable;
          TTable = packed record
          public type
            PIndexHint = ^TIndexHint;
            TIndexHint = packed record
            public type
              TIndexHintKind = (ihkUnknown, ihkJoin, ihkOrderBy, ihkGroupBy);
              TIndexHintType = (ihtUnknown, ihtUse, ihtIgnore, ihtForce);
            private
              Heritage: TRangeNode;
              FIndexHintType: TIndexHintType;
              FIndexHintKind: TIndexHintKind;
              function GetNextIndexHint(): PIndexHint; {$IFNDEF Debug} inline; {$ENDIF}
            public
              class function Create(const AParser: TCustomSQLParser; const AIndexHintType: TIndexHintType; const AIndexHintKind: TIndexHintKind): ONode; static;
              property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
              property NextIndexHint: PIndexHint read GetNextIndexHint;
            end;

            TIndexHints = packed record
            private
              Heritage: TSiblings;
            private
              class function Create(const AParser: TCustomSQLParser): ONode; static;
              function GetFirstIndexHint(): PIndexHint; {$IFNDEF Debug} inline; {$ENDIF}
            public
              property FirstIndexHint: PIndexHint read GetFirstIndexHint;
            end;

          private
            Heritage: TRangeNode;
            FAlias: ONode;
            FAsToken: ONode;
            FIdentifier: ONode;
            FIndexHints: ONode;
            FPartitionToken: ONode;
            FPartitions: ONode;
          public
            class function Create(const AParser: TCustomSQLParser; const AIdentifier, AAsToken, AAlias: ONode; const AIndexHints: ONode = 0; const APartitionToken: ONode = 0; const APartitions: ONode = 0): ONode; static;
            property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
          end;

          PJoin = ^TJoin;
          TJoin = packed record
          private type
            TKeywordTokens = array [0..3] of Integer;
          private
            Heritage: TRangeNode;
          private
            FCondition: ONode;
            FJoinType: TJoinType;
            FLeftTable: ONode;
            FRightTable: ONode;
            class function Create(const AParser: TCustomSQLParser; const ALeftTable: ONode; const AJoinType: TJoinType; const ARightTable: ONode; const ACondition: ONode; const AKeywordTokens: TKeywordTokens): ONode; static;
          end;

          TTables = packed record
          private
            Heritage: TSiblings;
          public
            class function Create(const AParser: TCustomSQLParser): ONode; static;
            property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
          end;

          PGroup = ^TGroup;
          TGroup = packed record
          private
            Heritage: TRangeNode;
          private
            FExpression: ONode;
            FDirection: ONode;
            function GetAscending(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
            function GetExpression(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
          public
            class function Create(const AParser: TCustomSQLParser; const AExpression, ADirection: ONode): ONode; static;
            property Expression: PStmtNode read GetExpression;
            property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
            property Ascending: Boolean read GetAscending;
          end;

          PGroups = ^TGroups;
          TGroups = packed record
          private
            Heritage: TSiblings;
          private
            FRollupKeyword: ONode;
            FWithKeyword: ONode;
            function GetFirstGroup(): PGroup; {$IFNDEF Debug} inline; {$ENDIF}
            function GetRollup(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
          public
            procedure AddWithRollup(const AWithKeyword, ARollupKeyword: ONode);
            class function Create(const AParser: TCustomSQLParser): ONode; static;
            property FirstGroup: PGroup read GetFirstGroup;
            property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
            property Rollup: Boolean read GetRollup;
          end;

          POrder = ^TOrder;
          TOrder = packed record
          private
            Heritage: TRangeNode;
          private
            FExpression: ONode;
            FDirection: ONode;
            function GetAscending(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
            function GetExpression(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
          public
            class function Create(const AParser: TCustomSQLParser; const AExpression, ADirection: ONode): ONode; static;
            property Expression: PStmtNode read GetExpression;
            property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.FParser;
            property Ascending: Boolean read GetAscending;
          end;

          POrders = ^TOrders;
          TOrders = packed record
          private
            Heritage: TSiblings;
          private
            function GetFirstOrder(): POrder; {$IFNDEF Debug} inline; {$ENDIF}
          public
            class function Create(const AParser: TCustomSQLParser): ONode; static;
            property FirstOrder: POrder read GetFirstOrder;
            property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
          end;
      private type
        TNodes = record
          SelectToken: ONode;
          DistinctToken: ONode;
          HighPriorityToken: ONode;
          StraightJoinToken: ONode;
          SQLSmallResultToken: ONode;
          SQLBigResultToken: ONode;
          SQLBufferResultToken: ONode;
          SQLNoCacheToken: ONode;
          SQLCalcFoundRowsToken: ONode;
          ColumnsNode: ONode;
          FromToken: ONode;
          TablesNodes: ONode;
          WhereToken: ONode;
          WhereNode: ONode;
          GroupToken: ONode;
          GroupByToken: ONode;
          GroupsNode: ONode;
          HavingToken: ONode;
          HavingNode: ONode;
          OrderToken: ONode;
          OrderByToken: ONode;
          OrdersNode: ONode;
          Limit: record
            LimitToken: ONode;
            OffsetToken: ONode;
            OffsetValueToken: ONode;
            CommaToken: ONode;
            RowCountValueToken: ONode;
          end;
        end;
      private
        FNodes: TNodes;
        class function Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode; static;
        function GetColumns(): PColumns; {$IFNDEF Debug} inline; {$ENDIF}
        function GetDistinct(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
        function GetGroups(): PGroups; {$IFNDEF Debug} inline; {$ENDIF}
        function GetHaving(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOrders(): POrders; {$IFNDEF Debug} inline; {$ENDIF}
        function GetTables(): PTables; {$IFNDEF Debug} inline; {$ENDIF}
        function GetWhere(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
      public
        property Columns: PColumns read GetColumns;
        property Distinct: Boolean read GetDistinct;
        property Groups: PGroups read GetGroups;
        property Having: PStmtNode read GetHaving;
        property Orders: POrders read GetOrders;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
        property Tables: PTables read GetTables;
        property Where: PStmtNode read GetWhere;
      end;

      PCompoundStmt = ^TCompoundStmt;
      TCompoundStmt = packed record
      private
        Heritage: TStmt;
      private
        procedure AddStmt(const AStmt: ONode); {$IFNDEF Debug} inline; {$ENDIF}
        class function Create(const AParser: TCustomSQLParser): ONode; static;
      end;

      PLoopStmt = ^TLoopStmt;
      TLoopStmt = packed record
      private
        Heritage: TStmt;
      private
        procedure AddStmt(const AStmt: ONode); {$IFNDEF Debug} inline; {$ENDIF}
        class function Create(const AParser: TCustomSQLParser): ONode; static;
      end;

      PRepeatStmt = ^TRepeatStmt;
      TRepeatStmt = packed record
      private
        Heritage: TStmt;
      private
        FCondition: ONode;
        procedure AddStmt(const AStmt: ONode); {$IFNDEF Debug} inline; {$ENDIF}
        class function Create(const AParser: TCustomSQLParser): ONode; static;
        function GetCondition(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
        procedure SetCondition(const ACondition: ONode);
      public
        property Condition: PStmtNode read GetCondition;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PWhileStmt = ^TWhileStmt;
      TWhileStmt = packed record
      private
        Heritage: TStmt;
      private
        FCondition: ONode;
        procedure AddStmt(const AStmt: ONode); {$IFNDEF Debug} inline; {$ENDIF}
        class function Create(const AParser: TCustomSQLParser; const ACondition: ONode): ONode; static;
        function GetCondition(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
      public
        property Condition: PStmtNode read GetCondition;
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PIfStmt = ^TIfStmt;
      TIfStmt = packed record
      private
        Heritage: TStmt;
        procedure AddPart(const APart: ONode);
        class function Create(const AParser: TCustomSQLParser): ONode; static;
      public
        property Parser: TCustomSQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PTag = ^TTag;
      TTag = packed record
      private type
        TNodes = record
          KeywordToken1: ONode;
          KeywordToken2: ONode;
          KeywordToken3: ONode;
          KeywordToken4: ONode;
          KeywordToken5: ONode;
        end;
      private
        Heritage: TSiblings;
      private
        FNodes: TNodes;
        class function Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode; static;
      end;

      PValue = ^TValue;
      TValue = packed record
      private type
        TNodes = record
          KeywordToken: ONode;
          AssignToken: ONode;
          ValueNode: ONode;
        end;
      private
        Heritage: TSiblings;
      private
        FNodes: TNodes;
        class function Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode; static;
      end;

  private
    FErrorCode: Integer;
    FErrorToken: ONode;
    FFunctions: TWordList;
    FHighNotPrecedence: Boolean;
    FKeywords: TWordList;
    FMySQLVersion: Integer;
    FNodes: packed record
      Mem: PAnsiChar;
      Offset: Integer;
      Size: Integer;
    end;
    FParsedText: string;
    FParsedTokens: TList;
    FParsePos: packed record Text: PChar; Length: Integer; Origin: TOrigin; end;
    FPipesAsConcat: Boolean;
    FRoot: ONode;
    FSQLDialect: TSQLDialect;
    function GetCurrentToken(): ONode; {$IFNDEF Debug} inline; {$ENDIF}
    function GetErrorMessage(const AErrorCode: Integer): string;
    function GetFunctions(): string; {$IFNDEF Debug} inline; {$ENDIF}
    function GetKeywords(): string; {$IFNDEF Debug} inline; {$ENDIF}
    function GetNextToken(Index: Integer): ONode; {$IFNDEF Debug} inline; {$ENDIF}
    function GetParsedToken(Index: Integer): ONode;
    function GetRoot(): PRoot; {$IFNDEF Debug} inline; {$ENDIF}
    procedure SetFunctions(AFunctions: string); {$IFNDEF Debug} inline; {$ENDIF}
    procedure SetKeywords(AKeywords: string);

  protected
    kiALL,
    kiAND,
    kiALGORITHM,
    kiAS,
    kiASC,
    kiBINARY,
    kiBEGIN,
    kiBETWEEN,
    kiBY,
    kiCASCADED,
    kiCASE,
    kiCHECK,
    kiCOLLATE,
    kiCREATE,
    kiCROSS,
    kiCURRENT_USER,
    kiDEFINER,
    kiDESC,
    kiDISTINCT,
    kiDISTINCTROW,
    kiDIV,
    kiDO,
    kiELSE,
    kiELSEIF,
    kiEND,
    kiFROM,
    kiFOR,
    kiFORCE,
    kiFUNCTION,
    kiGROUP,
    kiHAVING,
    kiHIGH_PRIORITY,
    kiIGNORE,
    kiIF,
    kiIN,
    kiINDEX,
    kiINNER,
    kiINTERVAL,
    kiINVOKER,
    kiIS,
    kiJOIN,
    kiKEY,
    kiLEFT,
    kiLIKE,
    kiLIMIT,
    kiLOCAL,
    kiLOOP,
    kiMERGE,
    kiMOD,
    kiNATURAL,
    kiNOT,
    kiNULL,
    kiOFFSET,
    kiOJ,
    kiON,
    kiOPTION,
    kiOR,
    kiORDER,
    kiOUTER,
    kiPARTITION,
    kiPROCEDURE,
    kiREGEXP,
    kiREPEAT,
    kiREPLACE,
    kiRIGHT,
    kiRLIKE,
    kiROLLUP,
    kiSECURITY,
    kiSELECT,
    kiSOUNDS,
    kiSQL,
    kiSQL_BIG_RESULT,
    kiSQL_BUFFER_RESULT,
    kiSQL_CACHE,
    kiSQL_CALC_FOUND_ROWS,
    kiSQL_NO_CACHE,
    kiSQL_SMALL_RESULT,
    kiSTRAIGHT_JOIN,
    kiTEMPTABLE,
    kiTHEN,
    kiUNDEFINED,
    kiUNTIL,
    kiUSE,
    kiUSING,
    kiVIEW,
    kiWHEN,
    kiWITH,
    kiWHERE,
    kiWHILE,
    kiXOR: Integer;

    OperatorTypeByKeywordIndex: array of TOperatorType;

    procedure APPLYCURRENTTOKEN();
    procedure DeleteNode(const ANode: PNode);
    function GetError(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
    function IsRangeNode(const ANode: PNode): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
    function IsSiblingNode(const ANode: PNode): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
    function IsStmt(const ANode: PNode): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
    function IsStmtNode(const ANode: PNode): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
    function IsSibling(const ANode: ONode): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsSibling(const ANode: PNode): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsSiblings(const ANode: PNode): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
    function IsToken(const ANode: ONode): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsToken(const ANode: PNode): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function NewNode(const ANodeType: TNodeType): ONode;
    function NodePtr(const ANode: ONode): PNode; {$IFNDEF Debug} inline; {$ENDIF}
    function NodeSize(const ANode: ONode): Integer; overload;
    function NodeSize(const ANodeType: TNodeType): Integer; overload;
    function ParseCaseOp(): ONode;
    function ParseColumn(): ONode;
    function ParseCompoundStmt(): ONode;
    function ParseColumnIdentifier(): ONode;
    function ParseCreateFunctionStmt(): ONode;
    function ParseCreateStmt(): ONode;
    function ParseCreateViewStmt(): ONode;
    function ParseDbIdentifier(const ADbIdentifierType: TDbIdentifierType): ONode;
    function ParseDefinerValue(): ONode;
    function ParseExpression(): ONode;
    function ParseFunction(): ONode;
    function ParseGroup(): ONode;
    function ParseGroups(): ONode;
    function ParseIfStmt(): ONode;
    function ParseIndexHint(): ONode;
    function ParseIndexIdentifier(): ONode;
    function ParseLoopStmt(): ONode;
    function ParseTag(const KeywordIndex1: Integer; const KeywordIndex2: Integer = -1; const KeywordIndex3: Integer = -1; const KeywordIndex4: Integer = -1; const KeywordIndex5: Integer = -1): ONode;
    function ParseOrder(): ONode;
    function ParsePartitionIdentifier(): ONode;
    function ParseRepeatStmt(): ONode;
    function ParseSelectStmt(): ONode;
    function ParseSiblings(const ANodeType: TNodeType; const ParseSibling: TParseFunction; const Empty: Boolean = False): ONode;
    function ParseSubArea(const ASubAreaTypes: TSubAreaTypes; const CanEmpty: Boolean = False): ONode;
    function ParseStmt(const PL_SQL: Boolean = False): ONode;
    function ParseTableReference(): ONode;
    function ParseToken(): ONode;
    function ParseUnknownStmt(): ONode;
    function ParseUser(): ONode;
    function ParseValue(const KeywordIndex: Integer): ONode;
    function ParseWhileStmt(): ONode;
    function RangeNodePtr(const ANode: ONode): PRangeNode; {$IFNDEF Debug} inline; {$ENDIF}
    procedure SetError(const AErrorCode: Integer; const AErrorNode: ONode = 0);
    function SiblingsPtr(const ANode: ONode): PSiblings; {$IFNDEF Debug} inline; {$ENDIF}
    function StmtNodePtr(const ANode: ONode): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
    function StmtPtr(const ANode: ONode): PStmt; {$IFNDEF Debug} inline; {$ENDIF}
    function TokenPtr(const ANode: ONode): PToken; {$IFNDEF Debug} inline; {$ENDIF}

    property CurrentToken: ONode read GetCurrentToken;
    property Error: Boolean read GetError;
    property ParsedText: string read FParsedText;
    property NextToken[Index: Integer]: ONode read GetNextToken;

  public
    constructor Create(const ASQLDialect: TSQLDialect);
    destructor Destroy(); override;
    function Parse(const Text: PChar; const Length: Integer): Boolean; overload;
    function Parse(const Text: string): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    procedure SaveToFile(const Filename: string; const FileType: TFileType = ftSQL);
    property Root: PRoot read GetRoot;
    property Functions: string read GetFunctions write SetFunctions;
    property HighNotPrecedence: Boolean read FHighNotPrecedence write FHighNotPrecedence;
    property Keywords: string read GetKeywords write SetKeywords;
    property PipesAsConcat: Boolean read FPipesAsConcat write FPipesAsConcat;
    property SQLDialect: TSQLDialect read FSQLDialect;
    property Text: string read FParsedText;
  end;

  TMySQLSQLParser = class(TCustomSQLParser)
  private
    FAnsiQuotes: Boolean;
    FLowerCaseTableNames: Integer;
    FMySQLVersion: Integer;
  public
    constructor Create(const MySQLVersion: Integer = 0; const LowerCaseTableNames: Integer = 0);
    property AnsiQuotes: Boolean read FAnsiQuotes write FAnsiQuotes;
    property LowerCaseTableNames: Integer read FLowerCaseTableNames write FLowerCaseTableNames;
    property MySQLVersion: Integer read FMySQLVersion write FMySQLVersion;
  end;

implementation {***************************************************************}

uses
  Windows,
  SysUtils, StrUtils, RTLConsts, Math,
  fspUtils;

resourcestring
  SUnknownError = 'Unknown Error';
  SKeywordNotFound = 'Keyword "%s" not found';
  SUnknownOperatorPrecedence = 'Unknown operator precedence for operator "%s"';
  STooManyTokensInExpression = 'Too many tokens (%d) in expression';
  SUnknownNodeType = 'Unknown node type';

{ TCustomSQLParser.TWordList **************************************************}

procedure TCustomSQLParser.TWordList.Clear();
begin
  FText := '';

  FCount := 0;
  SetLength(FIndex, 0);

  SetLength(Parser.OperatorTypeByKeywordIndex, 0);
end;

constructor TCustomSQLParser.TWordList.Create(const ASQLParser: TCustomSQLParser; const AText: string = '');
begin
  inherited Create();

  FParser := ASQLParser;

  FCount := 0;
  SetLength(FIndex, 0);

  Text := AText;
end;

destructor TCustomSQLParser.TWordList.Destroy();
begin
  Clear();

  inherited;
end;

function TCustomSQLParser.TWordList.GetWord(Index: Integer): string;
begin
  Result := StrPas(FIndex[Index]);
end;

function TCustomSQLParser.TWordList.IndexOf(const Word: PChar; const Length: Integer): Integer;
var
  Comp: Integer;
  Left: Integer;
  Mid: Integer;
  Right: Integer;
begin
  Result := -1;

  if (Length <= System.Length(FFirst) - 2) then
  begin
    Left := FFirst[Length];
    Right := FFirst[Length + 1] - 1;
    while (Left <= Right) do
    begin
      Mid := (Right - Left) div 2 + Left;
      Comp := StrLIComp(FIndex[Mid], Word, Length);
      if (Comp < 0) then
        Left := Mid + 1
      else if (Comp = 0) then
        begin Result := Mid; break; end
      else
        Right := Mid - 1;
    end;
  end;
end;

procedure TCustomSQLParser.TWordList.SetText(AText: string);
var
  Counts: array of Integer;

  function InsertIndex(const Word: PChar; const Len: Integer; out Index: Integer): Boolean;
  var
    Comp: Integer;
    Left: Integer;
    Mid: Integer;
    Right: Integer;
  begin
    Result := True;

    if ((Counts[Len] = 0) or (StrLIComp(Word, FIndex[FFirst[Len] + Counts[Len] - 1], Len) > 0)) then
      Index := FFirst[Len] + Counts[Len]
    else
    begin
      Left := FFirst[Len];
      Right := Left + Counts[Len] - 1;
      while (Left <= Right) do
      begin
        Mid := (Right - Left) div 2 + Left;
        Comp := StrLIComp(FIndex[Mid], Word, Len);
        if (Comp < 0) then
          begin Left := Mid + 1;  Index := Mid + 1; end
        else if (Comp = 0) then
          begin Result := False; Index := Mid; break; end
        else
          begin Right := Mid - 1; Index := Mid; end;
      end;
    end;
  end;

  procedure Add(const Word: PChar; const Len: Integer);
  var
    I: Integer;
    Index: Integer;
  begin
    if (InsertIndex(Word, Len, Index)) then
    begin
      for I := FFirst[Len] + Counts[Len] - 1 downto Index do
        Move(FIndex[I], FIndex[I + 1], SizeOf(FIndex[0]));
      FIndex[Index] := Word;
      Inc(Counts[Len]);
    end;
  end;

var
  First: Integer;
  I: Integer;
  Index: Integer;
  Len: Integer;
  MaxLen: Integer;
  OldIndex: Integer;
begin
  Clear();

  FText := UpperCase(ReplaceStr(AText, ',', #0)) + #0;
  if (FText <> '') then
  begin
    SetLength(Counts, Length(FText) + 1);

    OldIndex := 1; Index := 1; MaxLen := 0; FCount := 0;
    while (Index < Length(FText)) do
    begin
      while (FText[Index] <> #0) do Inc(Index);
      Len := Index - OldIndex;
      Inc(Counts[Len]);
      Inc(FCount);
      if (Len > MaxLen) then MaxLen := Len;
      Inc(Index);
      OldIndex := Index;
    end;

    SetLength(FFirst, MaxLen + 2);
    SetLength(FIndex, FCount);
    First := 0;
    for I := 1 to MaxLen do
    begin
      FFirst[I] := First;
      Inc(First, Counts[I]);
      Counts[I] := 0;
    end;
    FFirst[MaxLen + 1] := First;

    OldIndex := 1; Index := 1;
    while (Index < Length(FText)) do
    begin
      while (FText[Index] <> #0) do Inc(Index);
      Len := Index - OldIndex;
      Add(@FText[OldIndex], Len);
      Inc(Index);
      OldIndex := Index;
    end;

    SetLength(Counts, 0);
  end;
end;

{ TCustomSQLParser.TNode ******************************************************}

class function TCustomSQLParser.TNode.Create(const AParser: TCustomSQLParser; const ANodeType: TNodeType): ONode;
begin
  Result := AParser.NewNode(ANodeType);

  AParser.NodePtr(Result)^.FParser := AParser;
  AParser.NodePtr(Result)^.FNodeType := ANodeType;
end;

function TCustomSQLParser.TNode.GetOffset(): ONode;
begin
  Result := @Self - Parser.FNodes.Mem;
end;

{ TCustomSQLParser.TStmtNode **************************************************}

function TCustomSQLParser.TStmtNode.GetFFirstToken(): ONode;
begin
  if (NodeType = ntToken) then
    Result := @Self - Parser.FNodes.Mem
  else
  begin
    Assert(Parser.IsRangeNode(@Self));
    Result := TCustomSQLParser.PRangeNode(@Self).FFirstToken;
  end;
end;

function TCustomSQLParser.TStmtNode.GetFirstToken(): PToken;
begin
  if (NodeType = ntToken) then
    Result := @Self
  else
  begin
    Assert(Parser.IsRangeNode(@Self));
    Result := PRangeNode(@Self).FirstToken;
  end;
end;

function TCustomSQLParser.TStmtNode.GetFLastToken(): ONode;
begin
  if (NodeType = ntToken) then
    Result := PNode(@Self)^.Offset
  else
  begin
    Assert(Parser.IsRangeNode(@Self));
    Result := PRangeNode(@Self)^.FLastToken;
  end;
end;

function TCustomSQLParser.TStmtNode.GetLastToken(): PToken;
begin
  if (NodeType = ntToken) then
    Result := @Self
  else
  begin
    Assert(Parser.IsRangeNode(@Self));
    Result := PRangeNode(@Self).LastToken;
  end;
end;

function TCustomSQLParser.TStmtNode.GetNextSibling(): PNode;
var
  Node: PNode;
  Token: PToken;
begin
  Assert(Parser.IsStmtNode(@Self));

  if (not Parser.IsSiblingNode(@Self)) then
    Result := nil
  else
  begin
    Token := PStmtNode(@Self)^.LastToken^.NextToken;

    if (Assigned(Token) and (Token^.TokenType = ttComma)) then
      Token := PToken(Token)^.NextToken; // ttComma

    Node := PNode(Token);

    Result := nil;
    while (Assigned(Node) and (not Parser.IsToken(Node) or (PToken(Node)^.TokenType <> ttComma)) and Parser.IsStmtNode(Node) and (PStmtNode(Node) <> PStmtNode(ParentNode))) do
    begin
      Result := Node;
      Node := PStmtNode(Node)^.ParentNode;
    end;

    if (Assigned(Result) and (PStmtNode(Token)^.FParentNode <> PStmtNode(Node)^.FParentNode)) then
      Result := nil;
  end;
end;

function TCustomSQLParser.TStmtNode.GetParentNode(): PNode;
begin
  Result := Parser.NodePtr(FParentNode);
end;

{ TCustomSQLParser.TToken *****************************************************}

class function TCustomSQLParser.TToken.Create(const AParser: TCustomSQLParser;
  const ASQL: PChar; const ALength: Integer; const AOrigin: TOrigin;
  const AErrorCode: Integer; const AMySQLVersion: Integer; const ATokenType: fspTypes.TTokenType;
  const AOperatorType: TOperatorType; const AKeywordIndex: Integer): ONode;
begin
  Result := TNode.Create(AParser, ntToken);

  with PToken(AParser.NodePtr(Result))^ do
  begin
    Heritage.Heritage.FParser := AParser;
    FText.SQL := ASQL;
    FText.Length := ALength;
    FOrigin := AOrigin;
    FTokenType := ATokenType;
    FErrorCode := AErrorCode;
    FMySQLVersion := AMySQLVersion;
    FOperatorType := AOperatorType;
    FKeywordIndex := AKeywordIndex;
  end;
end;

function TCustomSQLParser.TToken.GetAsString(): string;
begin
  case (TokenType) of
    ttComment:
      if (Copy(Text, 1, 1) = '#') then
        Result := Trim(Copy(Text, Length(Text) - 1, 1))
      else if (Copy(Text, 1, 2) = '--') then
        Result := Trim(Copy(Text, 3, Length(Text) - 2))
      else if ((Copy(Text, 1, 2) = '/*') and (Copy(Text, Length(Text) - 1, 2) = '*/')) then
        Result := Trim(Copy(Text, 3, Length(Text) - 4))
      else
        Result := Text;
    ttBeginLabel:
      if (Copy(Text, Length(Text), 1) = ':') then
        Result := Trim(Copy(Text, 1, Length(Text) - 1))
      else
        Result := Text;
    ttBindVariable:
      if (Copy(Text, 1, 1) = ':') then
        Result := Trim(Copy(Text, 2, Length(Text) - 1))
      else
        Result := Text;
    ttString:
      Result := SQLUnescape(Text);
    ttDQIdentifier:
      Result := SQLUnescape(Text);
    ttDBIdentifier:
      if ((Copy(Text, 1, 1) = '[') and (Copy(Text, Length(Text), 1) = ']')) then
        Result := Trim(Copy(Text, 1, Length(Text) - 2))
      else
        Result := Text;
    ttBRIdentifier:
      if ((Copy(Text, 1, 1) = '{') and (Copy(Text, Length(Text), 1) = '}')) then
        Result := Trim(Copy(Text, 1, Length(Text) - 2))
      else
        Result := Text;
    ttMySQLIdentifier:
      Result := SQLUnescape(Text);
    ttMySQLCodeStart:
      Result := Copy(Text, 1, Length(Text) - 3);
    ttCSString:
      Result := Copy(Text, 1, Length(Text) - 1);
    else
      Result := Text;
  end;
end;

function TCustomSQLParser.TToken.GetDbIdentifierType(): TDbIdentifierType;
begin
  if ((FParentNode = 0) or (Parser.NodePtr(FParentNode)^.NodeType <> ntDbIdentifier)) then
    Result := ditUnknown
  else if (@Self = PDbIdentifier(Parser.NodePtr(FParentNode))^.Identifier) then
    Result := PDbIdentifier(Parser.NodePtr(FParentNode))^.DbIdentifierType
  else if (@Self = PDbIdentifier(Parser.NodePtr(FParentNode))^.Prefix1) then
    case (PDbIdentifier(Parser.NodePtr(FParentNode))^.DbIdentifierType) of
      ditUnknown: Result := ditUnknown;
      ditTable,
      ditFunction,
      ditProcedure,
      ditTrigger,
      ditView,
      ditEvent: Result := ditDatabase;
      ditField,
      ditAllFields: Result := ditTable;
      else raise ERangeError.Create(SArgumentOutOfRange);
    end
  else if (@Self = PDbIdentifier(Parser.NodePtr(FParentNode))^.Prefix2) then
    case (PDbIdentifier(Parser.NodePtr(FParentNode))^.DbIdentifierType) of
      ditUnknown: Result := ditUnknown;
      ditField,
      ditAllFields: Result := ditDatabase;
      else raise ERangeError.Create(SArgumentOutOfRange);
    end
  else
    Result := ditUnknown;
end;

function TCustomSQLParser.TToken.GetErrorMessage(): string;
begin
  Result := Parser.GetErrorMessage(ErrorCode);
end;

function TCustomSQLParser.TToken.GetGeneration(): Integer;
var
  Node: PNode;
begin
  Result := 0;
  Node := ParentNode;
  while (Parser.IsStmtNode(Node)) do
  begin
    Inc(Result);
    Node := PStmtNode(Node)^.ParentNode;
  end;
end;

function TCustomSQLParser.TToken.GetIndex(): Integer;
var
  Token: PToken;
begin
  Token := Parser.Root^.FirstToken;
  Result := 0;
  while (Assigned(Token) and (Token <> @Self)) do
  begin
    Inc(Result);
    Token := Token^.NextToken;
  end;
end;

function TCustomSQLParser.TToken.GetIsUsed(): Boolean;
begin
  Result := not (TokenType in [ttSpace, ttReturn, ttComment]) and (not (Parser is TMySQLSQLParser) or (TMySQLSQLParser(Parser).MySQLVersion >= FMySQLVersion));
end;

function TCustomSQLParser.TToken.GetNextToken(): PToken;
var
  Offset: ONode;
begin
  Offset := PNode(@Self)^.Offset;
  repeat
    repeat
      Inc(Offset, Parser.NodeSize(Offset));
    until ((Offset = Parser.FNodes.Offset) or (Parser.NodePtr(Offset)^.NodeType = ntToken));
    if (Offset = Parser.FNodes.Offset) then
      Result := nil
    else
      Result := PToken(Parser.NodePtr(Offset));
  until (not Assigned(Result) or (Result^.IsUsed));
end;

function TCustomSQLParser.TToken.GetOffset(): ONode;
begin
  Result := Heritage.Heritage.GetOffset();
end;

function TCustomSQLParser.TToken.GetParentNode(): PNode;
begin
  Result := Heritage.GetParentNode();
end;

function TCustomSQLParser.TToken.GetText(): string;
begin
  if (FText.NewText = '') then
    SetString(Result, FText.SQL, FText.Length)
  else
    Result := FText.NewText;
end;

procedure TCustomSQLParser.TToken.SetText(AText: string);
begin
  FText.NewText := AText;
end;

{ TCustomSQLParser.TRangeNode *************************************************}

class function TCustomSQLParser.TRangeNode.Create(const AParser: TCustomSQLParser; const ANodeType: TNodeType): ONode;
begin
  Result := TNode.Create(AParser, ANodeType);
end;

function TCustomSQLParser.TRangeNode.GetFirstToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FFirstToken));
end;

function TCustomSQLParser.TRangeNode.GetLastToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FLastToken));
end;

function TCustomSQLParser.TRangeNode.GetOffset(): ONode;
begin
  Result := Heritage.Heritage.Offset;
end;

function TCustomSQLParser.TRangeNode.GetParentNode(): PNode;
begin
  Result := PNode(Parser.NodePtr(FParentNode));
end;

procedure TCustomSQLParser.TRangeNode.AddChild(const ChildNode: ONode);
var
  Child: PStmtNode;
begin
  if (ChildNode > 0) then
  begin
    Child := Parser.StmtNodePtr(ChildNode);
    Child^.FParentNode := Offset;
    if ((FFirstToken = 0) or (FFirstToken > Child^.FFirstToken)) then
      FFirstToken := Child^.FFirstToken;
    if ((FLastToken = 0) or (FLastToken < Child^.FLastToken)) then
      FLastToken := Child^.FLastToken;
  end;
end;

{ TCustomSQLParser.TRoot ******************************************************}

class function TCustomSQLParser.TRoot.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TNode.Create(AParser, ntRoot);
end;

function TCustomSQLParser.TRoot.GetFirstStmt(): PStmt;
begin
  Result := PStmt(Parser.NodePtr(FFirstStmt));
end;

function TCustomSQLParser.TRoot.GetFirstToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FFirstToken));
end;

function TCustomSQLParser.TRoot.GetLastStmt(): PStmt;
begin
  Result := PStmt(Parser.NodePtr(FLastStmt));
end;

function TCustomSQLParser.TRoot.GetLastToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FLastToken));
end;

{ TCustomSQLParser.TSiblings **************************************************}

procedure TCustomSQLParser.TSiblings.AddSibling(const ASibling: ONode);
begin
  if (FFirstSibling = 0) then
    FFirstSibling := ASibling;

  Heritage.AddChild(ASibling);
end;

class function TCustomSQLParser.TSiblings.Create(const AParser: TCustomSQLParser; const ANodeType: TNodeType): ONode;
begin
  Result := TRangeNode.Create(AParser, ANodeType);
end;

function TCustomSQLParser.TSiblings.GetFirstChild(): PNode;
begin
  Result := Parser.NodePtr(FFirstSibling);
end;

{ TCustomSQLParser.TExpressions ***********************************************}

class function TCustomSQLParser.TExpressions.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TSiblings.Create(AParser, ntExpressions);
end;

{ TCustomSQLParser.TDbIdentifier **********************************************}

procedure TCustomSQLParser.TDbIdentifier.AddPrefix(const APrefix, ADot: ONode);
var
  Node: PNode;
begin
  Assert(Parser.NodePtr(APrefix)^.NodeType = ntDbIdentifier);
  Assert(Parser.TokenPtr(ADot)^.OperatorType = otDot);

  FPrefix1 := PDbIdentifier(Parser.NodePtr(APrefix))^.FIdentifier;
  FPrefix2 := PDbIdentifier(Parser.NodePtr(APrefix))^.FPrefix1;

  Heritage.AddChild(FPrefix1);
  Heritage.AddChild(FPrefix2);
  Heritage.AddChild(ADot);

  Parser.DeleteNode(Parser.NodePtr(APrefix));

  Node := ParentNode;
  while (Parser.IsRangeNode(Node)) do
  begin
    if (PRangeNode(Node)^.FFirstToken > Heritage.FFirstToken) then
      PRangeNode(Node)^.FFirstToken := Heritage.FFirstToken;
    Node := PRangeNode(ParentNode)^.ParentNode;
  end;
end;

class function TCustomSQLParser.TDbIdentifier.Create(const AParser: TCustomSQLParser; const AIdentifier: ONode; const ADbIdentifierType: TDbIdentifierType = ditUnknown): ONode;
begin
  Result := TRangeNode.Create(AParser, ntDbIdentifier);

  with PDbIdentifier(AParser.NodePtr(Result))^ do
  begin
    FIdentifier := AIdentifier;
    FDbIdentifierType := ADbIdentifierType;

    FPrefix1 := 0;
    FPrefix2 := 0;

    Heritage.AddChild(AIdentifier);
  end;
end;

function TCustomSQLParser.TDbIdentifier.GetIdentifier(): PToken;
begin
  Result := Parser.TokenPtr(FIdentifier);
end;

function TCustomSQLParser.TDbIdentifier.GetLastToken(): PToken;
begin
  Result := Heritage.GetLastToken();
end;

function TCustomSQLParser.TDbIdentifier.GetParentNode(): PNode;
begin
  Result := Heritage.GetParentNode();
end;

function TCustomSQLParser.TDbIdentifier.GetPrefix1(): PToken;
begin
  if (FPrefix1 = 0) then
    Result := nil
  else
    Result := Parser.TokenPtr(FPrefix1);
end;

function TCustomSQLParser.TDbIdentifier.GetPrefix2(): PToken;
begin
  if (FPrefix2 = 0) then
    Result := nil
  else
    Result := Parser.TokenPtr(FPrefix2);
end;

{ TCustomSQLParser.TFunction **************************************************}

class function TCustomSQLParser.TFunction.Create(const AParser: TCustomSQLParser; const AIdentifier, AArguments: ONode): ONode;
var
  Token: PToken;
begin
  Result := TRangeNode.Create(AParser, ntFunction);

  with PFunction(AParser.NodePtr(Result))^ do
  begin
    FIdentifier := AIdentifier;
    FArguments := AArguments;

    Heritage.AddChild(AIdentifier);
    Heritage.AddChild(AArguments);

    Token := Identifier^.LastToken^.NextToken;
    while (Assigned(Token) and not Token^.IsUsed) do
      Token := Token^.NextToken;
    if (Assigned(Token) and (Token^.TokenType = ttOpenBracket)) then
      Heritage.AddChild(Token^.Offset);

    Token := Arguments^.LastToken^.NextToken;
    while (Assigned(Token) and not Token^.IsUsed) do
      Token := Token^.NextToken;
    if (Assigned(Token) and (Token^.TokenType = ttCloseBracket)) then
      Heritage.AddChild(Token^.Offset);
  end;
end;

function TCustomSQLParser.TFunction.GetArguments(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FArguments);
end;

function TCustomSQLParser.TFunction.GetIdentifier(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FIdentifier);
end;

{ TCustomSQLParser.TUnaryOperation ********************************************}

class function TCustomSQLParser.TUnaryOperation.Create(const AParser: TCustomSQLParser; const AOperator, AOperand: ONode): ONode;
begin
  Result := TRangeNode.Create(AParser, ntUnaryOp);

  with PUnaryOperation(AParser.NodePtr(Result))^ do
  begin
    FOperator := AOperator;
    FOperand := AOperand;

    Heritage.AddChild(AOperator);
    Heritage.AddChild(AOperand);
  end;
end;

function TCustomSQLParser.TUnaryOperation.GetOperand(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FOperand);
end;

function TCustomSQLParser.TUnaryOperation.GetOperator(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FOperator);
end;

{ TCustomSQLParser.TBinaryOperation *******************************************}

class function TCustomSQLParser.TBinaryOperation.Create(const AParser: TCustomSQLParser; const AOperator, AOperand1, AOperand2: ONode): ONode;
begin
  Result := TRangeNode.Create(AParser, ntBinaryOp);

  with PBinaryOperation(AParser.NodePtr(Result))^ do
  begin
    FOperator := AOperator;
    FOperand1 := AOperand1;
    FOperand2 := AOperand2;

    Heritage.AddChild(AOperator);
    Heritage.AddChild(AOperand1);
    Heritage.AddChild(AOperand2);
  end;
end;

function TCustomSQLParser.TBinaryOperation.GetOperand1(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FOperand1);
end;

function TCustomSQLParser.TBinaryOperation.GetOperand2(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FOperand2);
end;

function TCustomSQLParser.TBinaryOperation.GetOperator(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FOperator);
end;

{ TCustomSQLParser.TUser ******************************************************}

class function TCustomSQLParser.TUser.Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode;
begin
  Result := TRangeNode.Create(AParser, ntUser);

  with PUser(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.NameToken);
    Heritage.AddChild(ANodes.AtToken);
    Heritage.AddChild(ANodes.HostToken);
  end;
end;

{ TCustomSQLParser.TBetweenOperation ******************************************}

class function TCustomSQLParser.TBetweenOperation.Create(const AParser: TCustomSQLParser; const AOperator1, AOperator2: ONode; const AExpr, AMin, AMax: ONode): ONode;
begin
  Result := TRangeNode.Create(AParser, ntBetweenOp);

  with PBetweenOperation(AParser.NodePtr(Result))^ do
  begin
    FOperator1 := AOperator1;
    FOperator2 := AOperator2;
    FExpr := AExpr;
    FMin := AMin;
    FMax := AMax;

    Heritage.AddChild(AOperator1);
    Heritage.AddChild(AOperator2);
    Heritage.AddChild(AExpr);
    Heritage.AddChild(AMin);
    Heritage.AddChild(AMax);
  end;
end;

function TCustomSQLParser.TBetweenOperation.GetExpr(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FExpr);
end;

function TCustomSQLParser.TBetweenOperation.GetMax(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FMax);
end;

function TCustomSQLParser.TBetweenOperation.GetMin(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FMin);
end;

function TCustomSQLParser.TBetweenOperation.GetOperator1(): PToken;
begin
  Result := Parser.TokenPtr(FOperator1);
end;

function TCustomSQLParser.TBetweenOperation.GetOperator2(): PToken;
begin
  Result := Parser.TokenPtr(FOperator2);
end;

{ TCustomSQLParser.TCaseCond **************************************************}

class function TCustomSQLParser.TCaseCond.Create(const AParser: TCustomSQLParser; const AConditionValue, AResultValue: ONode): ONode;
begin
  Result := TRangeNode.Create(AParser, ntCaseCond);

  with PCaseCond(AParser.NodePtr(Result))^ do
  begin
    FConditionValue := AConditionValue;
    FResultValue := AResultValue;

    Heritage.AddChild(AConditionValue);
    Heritage.AddChild(AResultValue);
  end;
end;

function TCustomSQLParser.TCaseCond.GetConditionValue(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FConditionValue);
end;

function TCustomSQLParser.TCaseCond.GetNextCond(): PCaseCond;
begin
  Result := PCaseCond(Heritage.Heritage.NextSibling);
end;

function TCustomSQLParser.TCaseCond.GetResultValue(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FResultValue);
end;

{ TCustomSQLParser.TCase ******************************************************}

procedure TCustomSQLParser.TCaseOp.AddCondition(const AConditionValue, AResultValue: ONode);
begin
  Heritage.AddSibling(TCaseCond.Create(Parser, AConditionValue, AResultValue));
end;

class function TCustomSQLParser.TCaseOp.Create(const AParser: TCustomSQLParser; const AReferenceValue: ONode): ONode;
begin
  Result := TSiblings.Create(AParser, ntCaseOp);

  with PCaseOp(AParser.NodePtr(Result))^ do
  begin
    FReferenceValue := AReferenceValue;

    Heritage.Heritage.AddChild(AReferenceValue);
  end;
end;

function TCustomSQLParser.TCaseOp.GetFirstCond(): PCaseCond;
begin
  Result := PCaseCond(Heritage.FirstChild);
end;

function TCustomSQLParser.TCaseOp.GetReferenceValue(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FReferenceValue);
end;

procedure TCustomSQLParser.TCaseOp.SetElse(const AElseValue: ONode);
begin
  FElseValue := AElseValue;

  Heritage.Heritage.AddChild(AElseValue);
end;

{ TCustomSQLParser.TSoundsLikeOperation ***************************************}

class function TCustomSQLParser.TSoundsLikeOperation.Create(const AParser: TCustomSQLParser; const AOperator1, AOperator2: ONode; const AOperand1, AOperand2: ONode): ONode;
begin
  Result := TRangeNode.Create(AParser, ntSoundsLikeOp);

  with PSoundsLikeOperation(AParser.NodePtr(Result))^ do
  begin
    FOperator1 := AOperator1;
    FOperator2 := AOperator2;
    FOperand1 := AOperand1;
    FOperand2 := AOperand2;

    Heritage.AddChild(AOperator1);
    Heritage.AddChild(AOperator2);
    Heritage.AddChild(AOperand1);
    Heritage.AddChild(AOperand2);
  end;
end;

function TCustomSQLParser.TSoundsLikeOperation.GetOperand1(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FOperator1);
end;

function TCustomSQLParser.TSoundsLikeOperation.GetOperand2(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FOperator2);
end;

function TCustomSQLParser.TSoundsLikeOperation.GetOperator1(): PToken;
begin
  Result := Parser.TokenPtr(FOperator1);
end;

function TCustomSQLParser.TSoundsLikeOperation.GetOperator2(): PToken;
begin
  Result := Parser.TokenPtr(FOperator2);
end;

{ TCustomSQLParser.TStmt ******************************************************}

procedure TCustomSQLParser.TPLSQLCondPart.AddStmt(const AStmt: ONode);
begin
  Heritage.AddChild(AStmt);
end;

class function TCustomSQLParser.TPLSQLCondPart.Create(const AParser: TCustomSQLParser; const AOperatorToken, AExpression, AThenToken: ONode): ONode;
begin
  Result := TRangeNode.Create(AParser, ntPLSQLCondPart);

  with PPLSQLCondPart(AParser.NodePtr(Result))^ do
  begin
    FOperator := AOperatorToken;
    FExpression := AExpression;
    FThen := AThenToken;

    Heritage.AddChild(AOperatorToken);
    Heritage.AddChild(AExpression);
    Heritage.AddChild(AThenToken);
  end;
end;

{ TCustomSQLParser.TStmt ******************************************************}

class function TCustomSQLParser.TStmt.Create(const AParser: TCustomSQLParser; const AStmtType: TStmtType): ONode;
var
  NodeType: TNodeType;
begin
  case (AStmtType) of
    stUnknown: NodeType := ntUnknownStmt;
    stCreateView: NodeType := ntCreateViewStmt;
    stCompound: NodeType := ntCompoundStmt;
    stIF: NodeType := ntIfStmt;
    stSELECT: NodeType := ntSelectStmt;
    else raise ERangeError.Create(SArgumentOutOfRange);
  end;
  Result := TRangeNode.Create(AParser, NodeType);

  with AParser.StmtPtr(Result)^ do
  begin
    FStmtType := AStmtType;
  end;
end;

function TCustomSQLParser.TStmt.GetError(): Boolean;
begin
  Result := FErrorCode <> PE_Success;
end;

function TCustomSQLParser.TStmt.GetErrorMessage(): string;
begin
  Result := Parser.GetErrorMessage(ErrorCode);
end;

function TCustomSQLParser.TStmt.GetErrorToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FErrorToken));
end;

function TCustomSQLParser.TStmt.GetFirstToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FFirstToken));
end;

function TCustomSQLParser.TStmt.GetLastToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FLastToken));
end;

function TCustomSQLParser.TStmt.GetNextStmt(): PStmt;
var
  Token: PToken;
  Node: PNode;
begin
  Token := LastToken^.NextToken;
  while (Assigned(Token) and not Token^.IsUsed) do
    Token := Token^.NextToken;
  if (Assigned(Token) and (Token^.TokenType = ttDelimiter)) then
    Token := Token^.NextToken;
  while (Assigned(Token) and not Token^.IsUsed) do
    Token := Token^.NextToken;

  if (not Assigned(Token)) then
    Result := nil
  else
  begin
    Node := Token^.ParentNode;
    while (Assigned(Node) and not Parser.IsStmt(Node)) do
      Node := PStmtNode(Node)^.ParentNode;

    if (not Assigned(Node) or not Parser.IsStmt(Node)) then
      Result := nil
    else
      Result := PStmt(Node);
  end;
end;

{ TCustomSQLParser.TCreateRoutineStmt *****************************************}

class function TCustomSQLParser.TCreateRoutineStmt.Create(const ARoutineType: TRoutineType; const AParser: TCustomSQLParser; const ANodes: TNodes): ONode;
begin
  if (ARoutineType = rtFunction) then
    Result := TStmt.Create(AParser, stCreateFunction)
  else
    Result := TStmt.Create(AParser, stCreateProcedure);

  with PCreateRoutineStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;
  end;
end;

{ TCustomSQLParser.TCreateViewStmt ********************************************}

class function TCustomSQLParser.TCreateViewStmt.Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode;
begin
  Result := TStmt.Create(AParser, stCreateView);

  with PCreateViewStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.OrReplaceTag);
    Heritage.Heritage.AddChild(ANodes.AlgorithmValue);
    Heritage.Heritage.AddChild(ANodes.DefinerNode);
    Heritage.Heritage.AddChild(ANodes.SQLSecurityTag);
    Heritage.Heritage.AddChild(ANodes.ViewTag);
    Heritage.Heritage.AddChild(ANodes.IdentifierNode);
    Heritage.Heritage.AddChild(ANodes.Columns);
    Heritage.Heritage.AddChild(ANodes.AsTag);
    Heritage.Heritage.AddChild(ANodes.SelectStmt);
    Heritage.Heritage.AddChild(ANodes.OptionTag);
  end;
end;

{ TCustomSQLParser.TSelectStmt.TColumn ****************************************}

class function TCustomSQLParser.TSelectStmt.TColumn.Create(const AParser: TCustomSQLParser; const AValue, AAsToken, AAlias: ONode): ONode;
begin
  Result := TRangeNode.Create(AParser, ntColumn);

  with PColumn(AParser.NodePtr(Result))^ do
  begin
    FExpression := AValue;
    FAsToken := AAsToken;
    FAlias := AAlias;

    Heritage.AddChild(AValue);
    Heritage.AddChild(AAsToken);
    Heritage.AddChild(AAlias);
  end;
end;

function TCustomSQLParser.TSelectStmt.TColumn.GetAlias(): PToken;
begin
  if (FAlias = 0) then
    Result := nil
  else
    Result := Parser.TokenPtr(FAlias);
end;

function TCustomSQLParser.TSelectStmt.TColumn.GetAsToken(): PToken;
begin
  if (FAlias = 0) then
    Result := nil
  else
    Result := Parser.TokenPtr(FAlias);
end;

function TCustomSQLParser.TSelectStmt.TColumn.GetColumns(): PColumns;
begin
  Assert(Parser.StmtNodePtr(FParentNode)^.NodeType = ntColumns);
  Result := PColumns(Parser.NodePtr(FParentNode));
end;

function TCustomSQLParser.TSelectStmt.TColumn.GetDisplayName(): string;
begin

end;

function TCustomSQLParser.TSelectStmt.TColumn.GetExpression(): PStmtNode;
begin
  Assert(Parser.IsStmtNode(Parser.NodePtr(FExpression)));

  Result := PStmtNode(Parser.NodePtr(FExpression));
end;

{ TCustomSQLParser.TSelectStmt.TColumns ***************************************}

class function TCustomSQLParser.TSelectStmt.TColumns.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TSiblings.Create(AParser, ntColumns);
end;

{ TCustomSQLParser.TSelectStmt.TTable.TIndexHint ******************************}

class function TCustomSQLParser.TSelectStmt.TTable.TIndexHint.Create(const AParser: TCustomSQLParser; const AIndexHintType: TIndexHintType; const AIndexHintKind: TIndexHintKind): ONode;
begin
  Result := TRangeNode.Create(AParser, ntIndexHint);

  with TSelectStmt.TTable.PIndexHint(AParser.NodePtr(Result))^ do
  begin
    FIndexHintType := AIndexHintType;
    FIndexHintKind := AIndexHintKind;
  end;
end;

function TCustomSQLParser.TSelectStmt.TTable.TIndexHint.GetNextIndexHint(): PIndexHint;
begin
  Result := PIndexHint(Heritage.Heritage.GetNextSibling());
end;

{ TCustomSQLParser.TSelectStmt.TTable.TIndexHints *****************************}

class function TCustomSQLParser.TSelectStmt.TTable.TIndexHints.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TSiblings.Create(AParser, ntIndexHints);
end;

function TCustomSQLParser.TSelectStmt.TTable.TIndexHints.GetFirstIndexHint(): PIndexHint;
begin
  Result := PIndexHint(Heritage.GetFirstChild());
end;

{ TCustomSQLParser.TSelectStmt.TTable *****************************************}

class function TCustomSQLParser.TSelectStmt.TTable.Create(const AParser: TCustomSQLParser; const AIdentifier, AAsToken, AAlias: ONode; const AIndexHints: ONode = 0; const APartitionToken: ONode = 0; const APartitions: ONode = 0): ONode;
begin
  Result := TRangeNode.Create(AParser, ntTable);

  with TSelectStmt.PTable(AParser.NodePtr(Result))^ do
  begin
    FIdentifier := AIdentifier;
    FPartitionToken := APartitionToken;
    FPartitions := APartitions;
    FAsToken := AAsToken;
    FAlias := AAlias;
    FIndexHints := AIndexHints;

    Heritage.AddChild(AIdentifier);
    Heritage.AddChild(APartitionToken);
    Heritage.AddChild(APartitions);
    Heritage.AddChild(AAsToken);
    Heritage.AddChild(AAlias);
    Heritage.AddChild(AIndexHints);
  end;
end;

{ TCustomSQLParser.TSelectStmt.TJoin ******************************************}

class function TCustomSQLParser.TSelectStmt.TJoin.Create(const AParser: TCustomSQLParser; const ALeftTable: ONode; const AJoinType: TJoinType; const ARightTable: ONode; const ACondition: ONode; const AKeywordTokens: TKeywordTokens): ONode;
var
  I: Integer;
begin
  Result := TRangeNode.Create(AParser, ntJoin);

  with PJoin(AParser.NodePtr(Result))^ do
  begin
    FLeftTable := ALeftTable;
    FJoinType := AJoinType;
    FRightTable := ARightTable;
    FCondition := ACondition;

    Heritage.AddChild(ALeftTable);
    Heritage.AddChild(ARightTable);
    Heritage.AddChild(ACondition);
    for I := 0 to Length(AKeywordTokens) - 1 do
      Heritage.AddChild(AKeywordTokens[I]);
  end;
end;

{ TCustomSQLParser.TSelectStmt.TTables ****************************************}

class function TCustomSQLParser.TSelectStmt.TTables.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TSiblings.Create(AParser, ntTables);
end;

{ TCustomSQLParser.TSelectStmt.TGroup *****************************************}

class function TCustomSQLParser.TSelectStmt.TGroup.Create(const AParser: TCustomSQLParser; const AExpression, ADirection: ONode): ONode;
begin
  Result := TRangeNode.Create(AParser, ntGroup);

  with PGroup(AParser.NodePtr(Result))^ do
  begin
    FExpression := AExpression;
    FDirection := ADirection;

    Heritage.AddChild(AExpression);
    Heritage.AddChild(ADirection);
  end;
end;

function TCustomSQLParser.TSelectStmt.TGroup.GetExpression(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FExpression);
end;

function TCustomSQLParser.TSelectStmt.TGroup.GetAscending(): Boolean;
begin
  Result := (FDirection = 0) or (Parser.TokenPtr(FDirection)^.KeywordIndex = Parser.kiASC);
end;

{ TCustomSQLParser.TSelectStmt.TGroups ****************************************}

procedure TCustomSQLParser.TSelectStmt.TGroups.AddWithRollup(const AWithKeyword, ARollupKeyword: ONode);
begin
  FWithKeyword := AWithKeyword;
  FRollupKeyword := ARollupKeyword;

  Heritage.Heritage.AddChild(AWithKeyword);
  Heritage.Heritage.AddChild(ARollupKeyword);
end;

class function TCustomSQLParser.TSelectStmt.TGroups.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TSiblings.Create(AParser, ntGroups);
end;

function TCustomSQLParser.TSelectStmt.TGroups.GetFirstGroup(): PGroup;
begin
  Result := PGroup(Heritage.GetFirstChild());
end;

function TCustomSQLParser.TSelectStmt.TGroups.GetRollup(): Boolean;
begin
  Result := (FWithKeyword > 0) and (FRollupKeyword > 0);
end;

{ TCustomSQLParser.TSelectStmt.TOrder *****************************************}

class function TCustomSQLParser.TSelectStmt.TOrder.Create(const AParser: TCustomSQLParser; const AExpression, ADirection: ONode): ONode;
begin
  Result := TRangeNode.Create(AParser, ntOrder);

  with PGroup(AParser.NodePtr(Result))^ do
  begin
    FExpression := AExpression;
    FDirection := ADirection;

    Heritage.AddChild(AExpression);
    Heritage.AddChild(ADirection);
  end;
end;

function TCustomSQLParser.TSelectStmt.TOrder.GetExpression(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FExpression);
end;

function TCustomSQLParser.TSelectStmt.TOrder.GetAscending(): Boolean;
begin
  Result := (FDirection = 0) or (Parser.TokenPtr(FDirection)^.KeywordIndex = Parser.kiASC);
end;

{ TCustomSQLParser.TSelectStmt.TOrders ****************************************}

class function TCustomSQLParser.TSelectStmt.TOrders.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TSiblings.Create(AParser, ntOrders);
end;

function TCustomSQLParser.TSelectStmt.TOrders.GetFirstOrder(): POrder;
begin
  Result := POrder(Heritage.GetFirstChild());
end;

{ TCustomSQLParser.TSelectStmt ************************************************}

class function TCustomSQLParser.TSelectStmt.Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode;
begin
  Result := TStmt.Create(AParser, stSelect);

  with PSelectStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(FNodes.SelectToken);
    Heritage.Heritage.AddChild(FNodes.DistinctToken);
    Heritage.Heritage.AddChild(FNodes.ColumnsNode);
    Heritage.Heritage.AddChild(FNodes.FromToken);
    Heritage.Heritage.AddChild(FNodes.TablesNodes);
    Heritage.Heritage.AddChild(FNodes.WhereToken);
    Heritage.Heritage.AddChild(FNodes.WhereNode);
    Heritage.Heritage.AddChild(FNodes.GroupToken);
    Heritage.Heritage.AddChild(FNodes.GroupByToken);
    Heritage.Heritage.AddChild(FNodes.GroupsNode);
    Heritage.Heritage.AddChild(FNodes.HavingToken);
    Heritage.Heritage.AddChild(FNodes.HavingNode);
    Heritage.Heritage.AddChild(FNodes.OrderToken);
    Heritage.Heritage.AddChild(FNodes.OrderByToken);
    Heritage.Heritage.AddChild(FNodes.OrdersNode);
    Heritage.Heritage.AddChild(FNodes.Limit.LimitToken);
    Heritage.Heritage.AddChild(FNodes.Limit.OffsetToken);
    Heritage.Heritage.AddChild(FNodes.Limit.OffsetValueToken);
    Heritage.Heritage.AddChild(FNodes.Limit.CommaToken);
    Heritage.Heritage.AddChild(FNodes.Limit.RowCountValueToken);
  end;
end;

function TCustomSQLParser.TSelectStmt.GetDistinct(): Boolean;
begin
  Result := (FNodes.DistinctToken <> 0) and ((Parser.TokenPtr(FNodes.DistinctToken)^.KeywordIndex = Parser.kiDISTINCT) or (Parser.TokenPtr(FNodes.DistinctToken)^.KeywordIndex = Parser.kiDISTINCTROW));
end;

function TCustomSQLParser.TSelectStmt.GetColumns(): PColumns;
begin
  Result := PColumns(Parser.NodePtr(FNodes.ColumnsNode));
end;

function TCustomSQLParser.TSelectStmt.GetGroups(): PGroups;
begin
  Result := PGroups(Parser.NodePtr(FNodes.GroupsNode));
end;

function TCustomSQLParser.TSelectStmt.GetHaving(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FNodes.HavingNode);
end;

function TCustomSQLParser.TSelectStmt.GetOrders(): POrders;
begin
  Result := POrders(Parser.NodePtr(FNodes.OrdersNode));
end;

function TCustomSQLParser.TSelectStmt.GetTables(): PTables;
begin
  Result := PTables(Parser.NodePtr(FNodes.TablesNodes));
end;

function TCustomSQLParser.TSelectStmt.GetWhere(): PStmtNode; {$IFNDEF Debug} inline; {$ENDIF}
begin
  Result := Parser.StmtNodePtr(FNodes.WhereNode);
end;

{ TCustomSQLParser.TCompoundStmt **********************************************}

procedure TCustomSQLParser.TCompoundStmt.AddStmt(const AStmt: ONode);
begin
  Heritage.Heritage.AddChild(AStmt);
end;

class function TCustomSQLParser.TCompoundStmt.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TStmt.Create(AParser, stCompound);
end;

{ TCustomSQLParser.TLoopStmt **************************************************}

procedure TCustomSQLParser.TLoopStmt.AddStmt(const AStmt: ONode);
begin
  Heritage.Heritage.AddChild(AStmt);
end;

class function TCustomSQLParser.TLoopStmt.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TStmt.Create(AParser, stLOOP);
end;

{ TCustomSQLParser.TRepeatStmt ************************************************}

procedure TCustomSQLParser.TRepeatStmt.AddStmt(const AStmt: ONode);
begin
  Heritage.Heritage.AddChild(AStmt);
end;

class function TCustomSQLParser.TRepeatStmt.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TStmt.Create(AParser, stREPEAT);
end;

function TCustomSQLParser.TRepeatStmt.GetCondition(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FCondition);
end;

procedure TCustomSQLParser.TRepeatStmt.SetCondition(const ACondition: ONode);
begin
  Assert(FCondition = 0);

  FCondition := ACondition;

  Heritage.Heritage.AddChild(ACondition);
end;

{ TCustomSQLParser.TWhileStmt *************************************************}

procedure TCustomSQLParser.TWhileStmt.AddStmt(const AStmt: ONode);
begin
  Heritage.Heritage.AddChild(AStmt);
end;

class function TCustomSQLParser.TWhileStmt.Create(const AParser: TCustomSQLParser; const ACondition: ONode): ONode;
begin
  Result := TStmt.Create(AParser, stWHILE);

  with PWhileStmt(AParser.NodePtr(Result))^ do
  begin
    FCondition := ACondition;

    Heritage.Heritage.AddChild(ACondition);
  end;
end;

function TCustomSQLParser.TWhileStmt.GetCondition(): PStmtNode;
begin
  Result := Parser.StmtNodePtr(FCondition);
end;

{ TCustomSQLParser.TIfStmt ****************************************************}

procedure TCustomSQLParser.TIfStmt.AddPart(const APart: ONode);
begin
  Heritage.Heritage.AddChild(APart);
end;

class function TCustomSQLParser.TIfStmt.Create(const AParser: TCustomSQLParser): ONode;
begin
  Result := TStmt.Create(AParser, stIf);
end;

{ TCustomSQLParser.TTag *******************************************************}

class function TCustomSQLParser.TTag.Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode;
begin
  Result := TSiblings.Create(AParser, ntTag);

  with PTag(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.KeywordToken1);
    Heritage.Heritage.AddChild(ANodes.KeywordToken2);
    Heritage.Heritage.AddChild(ANodes.KeywordToken3);
    Heritage.Heritage.AddChild(ANodes.KeywordToken4);
    Heritage.Heritage.AddChild(ANodes.KeywordToken5);
  end;
end;

{ TCustomSQLParser.TValue *******************************************************}

class function TCustomSQLParser.TValue.Create(const AParser: TCustomSQLParser; const ANodes: TNodes): ONode;
begin
  Result := TSiblings.Create(AParser, ntValue);

  with PValue(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.KeywordToken);
    Heritage.Heritage.AddChild(ANodes.AssignToken);
    Heritage.Heritage.AddChild(ANodes.ValueNode);
  end;
end;

{ TCustomSQLParser ************************************************************}

procedure TCustomSQLParser.ApplyCurrentToken();
begin
  if (CurrentToken > 0) then
    FParsedTokens.Delete(0);
end;

constructor TCustomSQLParser.Create(const ASQLDialect: TSQLDialect);
begin
  inherited Create();

  FFunctions := TWordList.Create(Self);
  FHighNotPrecedence := False;
  FKeywords := TWordList.Create(Self);
  FNodes.Mem := nil;
  FNodes.Offset := 0;
  FNodes.Size := 0;
  FParsedTokens := TList.Create();
  FPipesAsConcat := False;
  FSQLDialect := ASQLDialect;
end;

procedure TCustomSQLParser.DeleteNode(const ANode: PNode);
begin
  PDeletedNode(ANode)^.FNodeSize := NodeSize(ANode^.NodeType);
  PDeletedNode(ANode)^.FNodeType := ntDeleted;
end;

destructor TCustomSQLParser.Destroy();
begin
  FFunctions.Free();
  FKeywords.Free();
  if (FNodes.Size > 0) then
    FreeMem(FNodes.Mem);
  FParsedTokens.Free();

  inherited;
end;

function TCustomSQLParser.GetCurrentToken(): ONode;
begin
  Result := GetParsedToken(0);
end;

function TCustomSQLParser.GetError(): Boolean;
begin
  Result := FErrorCode <> PE_Success;
end;

function TCustomSQLParser.GetErrorMessage(const AErrorCode: Integer): string;
begin
  case (AErrorCode) of
    PE_Success: Result := '';
    PE_Unknown: Result := 'Unknown error';
    PE_EmptyText: Result := 'Text is empty';
    PE_Syntax: Result := 'Invalid or unexpected character';
    PE_IncompleteToken: Result := 'Uncompleted Token';
    PE_UnexpectedToken: Result := 'Token unexpected or not understood';
    PE_UnkownStmt: Result := 'First Token is not a known keyword';
    PE_IncompleteStmt: Result := 'Uncompleted Token';
    PE_InvalidEndLabel: Result := 'Begin and End Token are different';
    else Result := '[Unknown Error Message]';
  end;
end;

function TCustomSQLParser.GetFunctions(): string;
begin
  Result := FFunctions.Text;
end;

function TCustomSQLParser.GetKeywords(): string;
begin
  Result := FKeywords.Text;
end;

function TCustomSQLParser.GetNextToken(Index: Integer): ONode;
begin
  Assert(Index > 0);

  Result := GetParsedToken(Index);
end;

function TCustomSQLParser.GetParsedToken(Index: Integer): ONode;
var
  Token: ONode;
begin
  if (FParsedTokens.Count - 1 < Index) then
    repeat
      Token := ParseToken();
      if ((Token > 0) and TokenPtr(Token)^.IsUsed) then
        FParsedTokens.Add(Pointer(Token));
    until ((Token = 0) or (FParsedTokens.Count - 1 = Index));

  if (FParsedTokens.Count - 1 < Index) then
    Result := 0
  else
    Result := ONode(FParsedTokens[Index]);
end;

function TCustomSQLParser.GetRoot(): PRoot;
begin
  Result := PRoot(NodePtr(FRoot));
end;

function TCustomSQLParser.IsRangeNode(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and not (ANode^.NodeType in [ntUnknown, ntRoot, ntToken]);
end;

function TCustomSQLParser.IsSiblingNode(const ANode: PNode): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
begin
  Result := IsStmtNode(ANode) and (PStmtNode(ANode)^.NodeType in [ntExpressions, ntCaseOp, ntColumns, ntIndexHints, ntTables, ntGroups, ntOrders, ntTag]);
end;

function TCustomSQLParser.IsStmt(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and (ANode^.NodeType in [ntUnknownStmt, ntCompoundStmt, ntSelectStmt]);
end;

function TCustomSQLParser.IsStmtNode(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and not (ANode^.NodeType in [ntUnknown, ntRoot]);
end;

function TCustomSQLParser.IsSibling(const ANode: ONode): Boolean;
begin
  Result := IsSibling(NodePtr(ANode));
end;

function TCustomSQLParser.IsSibling(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and (ANode^.NodeType in [ntCaseCond, ntColumn, ntIndexHint, ntTable, ntGroup, ntOrder]);
end;

function TCustomSQLParser.IsSiblings(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and (ANode^.NodeType in [ntColumns]);
end;

function TCustomSQLParser.IsToken(const ANode: ONode): Boolean;
begin
  Result := IsToken(NodePtr(ANode));
end;

function TCustomSQLParser.IsToken(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and (ANode^.NodeType in [ntToken]);
end;

function TCustomSQLParser.NewNode(const ANodeType: TNodeType): ONode;
var
  AdditionalSize: Integer;
  Size: Integer;
begin
  Size := NodeSize(ANodeType);

  if (FNodes.Offset + Size > FNodes.Size) then
  begin
    AdditionalSize := Max(FNodes.Offset + Size, FNodes.Size);
    ReallocMem(FNodes.Mem, FNodes.Size + AdditionalSize);
    FillChar(FNodes.Mem[FNodes.Size], AdditionalSize, #0);
    Inc(FNodes.Size, AdditionalSize);
  end;

  Result := FNodes.Offset;

  Inc(FNodes.Offset, Size);
end;

function TCustomSQLParser.NodePtr(const ANode: ONode): PNode;
begin
  if (ANode = 0) then
    Result := nil
  else
    Result := @FNodes.Mem[ANode];
end;

function TCustomSQLParser.NodeSize(const ANode: ONode): Integer;
begin
  if (NodePtr(ANode)^.NodeType = ntDeleted) then
    Result := PDeletedNode(NodePtr(ANode))^.FNodeSize
  else
    Result := NodeSize(NodePtr(ANode)^.NodeType);
end;

function TCustomSQLParser.NodeSize(const ANodeType: TNodeType): Integer;
begin
  case (ANodeType) of
    ntRoot: Result := SizeOf(TRoot);
    ntToken: Result := SizeOf(TToken);
    ntRangeNode: Result := SizeOf(TRangeNode);
    ntExpressions: Result := SizeOf(TExpressions);
    ntDbIdentifier: Result := SizeOf(TDbIdentifier);
    ntFunction: Result := SizeOf(TFunction);
    ntUnaryOp: Result := SizeOf(TUnaryOperation);
    ntBinaryOp: Result := SizeOf(TBinaryOperation);
    ntUser: Result := SizeOf(TUser);
    ntColumns: Result := SizeOf(TSelectStmt.TColumns);
    ntColumn: Result := SizeOf(TSelectStmt.TColumn);
    ntJoin: Result := SizeOf(TSelectStmt.TJoin);
    ntTable: Result := SizeOf(TSelectStmt.TTable);
    ntTables: Result := SizeOf(TSelectStmt.TTables);
    ntGroup: Result := SizeOf(TSelectStmt.TGroup);
    ntGroups: Result := SizeOf(TSelectStmt.TGroups);
    ntOrder: Result := SizeOf(TSelectStmt.TOrder);
    ntOrders: Result := SizeOf(TSelectStmt.TOrders);
    ntPLSQLCondPart: Result := SizeOf(TPLSQLCondPart);
    ntUnknownStmt: Result := SizeOf(TStmt);
    ntCreateViewStmt: Result := SizeOf(TCreateViewStmt);
    ntCompoundStmt: Result := SizeOf(TCompoundStmt);
    ntIfStmt: Result := SizeOf(TIfStmt);
    ntSelectStmt: Result := SizeOf(TSelectStmt);
    ntTag: Result := SizeOf(TTag);
    ntValue: Result := SizeOf(TValue);
    else raise ERangeError.Create(SArgumentOutOfRange);
  end;
end;

function TCustomSQLParser.Parse(const Text: PChar; const Length: Integer): Boolean;
begin
  SetString(FParsedText, Text, Length);
  FParsePos.Text := PChar(ParsedText);
  FParsePos.Length := Length;
  FParsePos.Origin.X := 0;
  FParsePos.Origin.Y := 0;

  FNodes.Offset := 1;
  FNodes.Size := 1024 * 1024;
  ReallocMem(FNodes.Mem, FNodes.Size);
  FillChar(FNodes.Mem[0], FNodes.Size, #0);

  FRoot := TRoot.Create(Self);
  FMySQLVersion := -1;

  Result := True;

  Root^.FFirstToken := CurrentToken;
  Root^.FFirstStmt := 0;

  while (CurrentToken <> 0) do
  begin
    FErrorCode := PE_Success;
    FErrorToken := 0;

    if (Root^.FFirstStmt = 0) then
    begin
      Root^.FFirstStmt := ParseStmt();
      Root^.FLastStmt := Root^.FFirstStmt;
    end
    else
      Root^.FLastStmt := ParseStmt();

    if (CurrentToken > 0) then
      if (TokenPtr(CurrentToken)^.TokenType <> ttDelimiter) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
      begin
        TokenPtr(CurrentToken)^.FUsageType := utSymbol;
        ApplyCurrentToken();
      end;
  end;
end;

function TCustomSQLParser.Parse(const Text: string): Boolean;
begin
  Result := Parse(PChar(Text), Length(Text));
end;

function TCustomSQLParser.ParseCaseOp(): ONode;
var
  First: Boolean;
  ResultValue: ONode;
  Value: ONode;
begin
  TokenPtr(CurrentToken)^.FUsageType := utOperator;
  ApplyCurrentToken(); // CASE

  Value := 0;
  if (CurrentToken = 0) then
  begin
    Result := 0;
    SetError(PE_IncompleteStmt);
  end
  else
  begin
    if ((TokenPtr(CurrentToken)^.KeywordIndex <> kiWHEN)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiTHEN)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiELSE)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiEND)) then
      Value := ParseExpression;

    Result := TCaseOp.Create(Self, Value);
    with PCaseOp(NodePtr(Result))^ do
    begin
      First := True;
      repeat
        if (First) then
          First := False
        else
        begin
          TokenPtr(CurrentToken)^.FUsageType := utOperator;
          ApplyCurrentToken(); // WHEN
        end;

        if (CurrentToken = 0) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiWHEN) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          Value := ParseExpression();
          if (CurrentToken = 0) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTHEN) then
            SetError(PE_UnexpectedToken, CurrentToken)
          else
          begin
            TokenPtr(CurrentToken)^.FUsageType := utOperator;
            ApplyCurrentToken(); // THEN

            ResultValue := ParseExpression();

            AddCondition(Value, ResultValue);
          end;
        end;
      until (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiWHEN));

      if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiELSE)) then
      begin
        TokenPtr(CurrentToken)^.FUsageType := utOperator;
        ApplyCurrentToken(); // ELSE

        if (CurrentToken = 0) then
          SetError(PE_IncompleteStmt)
        else
          SetElse(ParseExpression());
      end;

      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiEND) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
      begin
        TokenPtr(CurrentToken)^.FUsageType := utOperator;
        ApplyCurrentToken(); // END
      end;
    end;
  end;
end;

function TCustomSQLParser.ParseColumn(): ONode;
var
  Alias: ONode;
  AsToken: ONode;
  Value: ONode;
begin
  Value := ParseExpression();

  if (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiAs)) then
    AsToken := 0
  else
  begin
    AsToken := CurrentToken;
    ApplyCurrentToken();
  end;

  Alias := 0;
  if (not Error) then
    if ((AsToken > 0) and ((CurrentToken = 0) or (TokenPtr(CurrentToken)^.TokenType = ttDelimiter))) then
      SetError(PE_IncompleteStmt)
    else if ((AsToken > 0) and (CurrentToken > 0) and not (TokenPtr(CurrentToken)^.TokenType in ttIdentifiers)) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else if ((CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType in ttIdentifiers)) then
    begin
      TokenPtr(CurrentToken)^.FUsageType := utAlias;
      Alias := CurrentToken;
      ApplyCurrentToken();
    end;

  if (Error) then
    Result := 0
  else
    Result := TSelectStmt.TColumn.Create(Self, Value, AsToken, Alias);
end;

function TCustomSQLParser.ParseCompoundStmt(): ONode;
var
  BeginLabel: ONode;
begin
  if (TokenPtr(CurrentToken)^.TokenType <> ttBeginLabel) then
    BeginLabel := 0
  else
  begin
    BeginLabel := CurrentToken;
    TokenPtr(CurrentToken)^.FUsageType := utLabel;
    ApplyCurrentToken();
  end;

  Assert(TokenPtr(CurrentToken)^.KeywordIndex = kiBEGIN);
  ApplyCurrentToken();

  Result := TCompoundStmt.Create(Self);

  repeat
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiEnd) then
      PCompoundStmt(NodePtr(Result))^.AddStmt(ParseStmt(True));

    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttDelimiter) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else
    begin
      TokenPtr(CurrentToken)^.FUsageType := utSymbol;
      ApplyCurrentToken();
    end;
  until (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex = kiEND));

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else
    begin
      ApplyCurrentToken();

      if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType = ttIdentifier)) then
        if ((BeginLabel = 0) or (StrIComp(PChar(TokenPtr(CurrentToken)^.AsString), PChar(TokenPtr(BeginLabel)^.AsString)) <> 0)) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          TokenPtr(CurrentToken)^.FTokenType := ttEndLabel;
          TokenPtr(CurrentToken)^.FUsageType := utLabel;
          ApplyCurrentToken();
        end;
    end;
end;

function TCustomSQLParser.ParseColumnIdentifier(): ONode;
begin
  Result := 0;
  if (CurrentToken = 0) then
    SetError(PE_IncompleteStmt)
  else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdentifiers)) then
    SetError(PE_UnexpectedToken, CurrentToken)
  else
  begin
    Result := CurrentToken;
    ApplyCurrentToken();
  end;
end;

function TCustomSQLParser.ParseCreateFunctionStmt(): ONode;
begin

end;

function TCustomSQLParser.ParseCreateStmt(): ONode;
var
  Index: Integer;
begin
  Assert(TokenPtr(CurrentToken)^.KeywordIndex = kiCREATE);

  Result := 0;
  Index := 1;

  if (not Error and (NextToken[Index] > 0) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiOR)) then
  begin
    Inc(Index);
    if (NextToken[Index] = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex <> kiREPLACE) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
      Inc(Index);
  end;

  if (not Error and (NextToken[Index] > 0) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiALGORITHM)) then
  begin
    Inc(Index);
    if (NextToken[Index] = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
    begin
      Inc(Index);

      if (NextToken[Index] = 0) then
        SetError(PE_IncompleteStmt)
      else if ((TokenPtr(NextToken[Index])^.KeywordIndex <> kiUNDEFINED)
        and (TokenPtr(NextToken[Index])^.KeywordIndex <> kiMERGE)
        and (TokenPtr(NextToken[Index])^.KeywordIndex <> kiTEMPTABLE)) then
        SetError(PE_UnexpectedToken, NextToken[Index])
      else
        Inc(Index);
    end;
  end;

  if (not Error and (NextToken[Index] > 0) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiDEFINER)) then
  begin
    Inc(Index);
    if (NextToken[Index] = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
    begin
      Inc(Index);

      if (NextToken[Index] = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiCURRENT_USER) then
        if (((NextToken[Index + 1] = 0) or (TokenPtr(NextToken[Index + 1])^.TokenType <> ttOpenBracket))
          and ((NextToken[Index + 2] = 0) or (TokenPtr(NextToken[Index + 2])^.TokenType <> ttCloseBracket))) then
          Inc(Index)
        else
          Inc(Index, 3)
      else
      begin
        Inc(Index); // Username

        if (not Error and (NextToken[Index] > 0) and (TokenPtr(NextToken[Index])^.TokenType = ttAt)) then
        begin
          Inc(Index); // @
          if (not Error and (NextToken[Index] > 0)) then
            Inc(Index); // Servername
        end;
      end;
    end;
  end;

  if (not Error and (NextToken[Index] > 0) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiSQL)) then
  begin
    Inc(Index);
    if (NextToken[Index] = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex <> kiSECURITY) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
    begin
      Inc(Index);
      if (NextToken[Index] = 0) then
        SetError(PE_IncompleteStmt)
      else if ((TokenPtr(NextToken[Index])^.KeywordIndex <> kiDEFINER)
        and (TokenPtr(NextToken[Index])^.KeywordIndex <> kiINVOKER)) then
        SetError(PE_UnexpectedToken, NextToken[Index])
      else
        Inc(Index);
    end;
  end;

  if (not Error) then
    if (NextToken[Index] = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiFUNCTION) then
      Result := ParseCreateFunctionStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiVIEW) then
      Result := ParseCreateViewStmt()
    else
      SetError(PE_UnexpectedToken, NextToken[Index]);
end;

function TCustomSQLParser.ParseCreateViewStmt(): ONode;
var
  Nodes: TCreateViewStmt.TNodes;
  ValueNodes: TValue.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE);

  if (not Error and (TokenPtr(CurrentToken)^.KeywordIndex = kiOR)) then
    Nodes.OrReplaceTag := ParseTag(kiOR, kiREPLACE);

  if (not Error and (TokenPtr(CurrentToken)^.KeywordIndex = kiALGORITHM)) then
    Nodes.AlgorithmValue := ParseValue(kiALGORITHM);

  if (not Error and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFINER)) then
    Nodes.DefinerNode := ParseDefinerValue();

  if (not Error and (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL)) then
    if (NextToken[2] = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiDEFINER) then
      Nodes.SQLSecurityTag := ParseTag(kiSQL, kiSECURITY, kiDEFINER)
    else
      Nodes.SQLSecurityTag := ParseTag(kiSQL, kiSECURITY, kiINVOKER);

  if (not Error) then
    Nodes.ViewTag := ParseTag(kiVIEW);

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else
    begin
      Nodes.IdentifierNode := ParseExpression();

      if (not Error) then
        if (StmtNodePtr(Nodes.IdentifierNode)^.NodeType <> ntDbIdentifier) then
          SetError(PE_UnexpectedToken, StmtNodePtr(Nodes.IdentifierNode)^.FirstToken^.Offset)
        else
          PDbIdentifier(NodePtr(Nodes.IdentifierNode))^.FDbIdentifierType := ditView;
    end;

  if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
    Nodes.Columns := ParseSubArea([satColumnIdentifiers]);

  if (not Error) then
    Nodes.AsTag := ParseTag(kiAS);

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiSELECT) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else
    begin
      Nodes.SelectStmt := ParseSelectStmt();

      if (not Error and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
        if (NextToken[1] = 0) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(NextToken[1])^.KeywordIndex = kiCASCADED) then
          Nodes.OptionTag := ParseTag(kiWITH, kiCASCADED, kiCHECK, kiOPTION)
        else if (TokenPtr(NextToken[1])^.KeywordIndex = kiLOCAL) then
          Nodes.OptionTag := ParseTag(kiWITH, kiLOCAL, kiCHECK, kiOPTION)
        else
          Nodes.OptionTag := ParseTag(kiWITH, kiCHECK, kiOPTION);
    end;

  if (Error) then
    Result := 0
  else
    Result := TCreateViewStmt.Create(Self, Nodes);
end;

function TCustomSQLParser.ParseDbIdentifier(const ADbIdentifierType: TDbIdentifierType): ONode;
begin
  Result := 0;
  if (CurrentToken = 0) then
    SetError(PE_IncompleteStmt)
  else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdentifiers)) then
    SetError(PE_UnexpectedToken, CurrentToken)
  else
    Result := TDbIdentifier.Create(Self, CurrentToken, ADbIdentifierType);
end;

function TCustomSQLParser.ParseDefinerValue(): ONode;
var
  Nodes: TValue.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.KeywordToken := CurrentToken;
  ApplyCurrentToken();

  if (CurrentToken = 0) then
    SetError(PE_IncompleteStmt)
  else if (not (TokenPtr(CurrentToken)^.OperatorType in [otEqual, otAssign])) then
    SetError(PE_UnexpectedToken, CurrentToken)
  else
  begin
    TokenPtr(CurrentToken)^.FOperatorType := otAssign;
    Nodes.AssignToken := CurrentToken;
    ApplyCurrentToken();

    Nodes.ValueNode := ParseUser();
  end;

  if (Error) then
    Result := 0
  else
    Result := TValue.Create(Self, Nodes);
end;

function TCustomSQLParser.ParseExpression(): ONode;
const
  MaxNodeCount = 100;
var
  NodeCount: Integer;
  Nodes: array[0 .. MaxNodeCount - 1] of ONode;

  procedure AddNode(const ANode: ONode; const Apply: Boolean = True);
  begin
    if (NodeCount = MaxNodeCount) then
      raise Exception.CreateFmt(STooManyTokensInExpression, [NodeCount]);

    Nodes[NodeCount] := ANode;
    Inc(NodeCount);
    if (Apply) then
      ApplyCurrentToken();
  end;

var
  I: Integer;
  InCaseOp: Boolean;
  KeywordIndex: Integer;
  OperatorPrecedence: Integer;
begin
  NodeCount := 0; InCaseOp := False;

  repeat
    KeywordIndex := TokenPtr(CurrentToken)^.KeywordIndex;
    if (KeywordIndex > 0) then
      if (KeywordIndex = kiBETWEEN) then
        TokenPtr(CurrentToken)^.FOperatorType := otBetween
      else if (KeywordIndex = kiBINARY) then
        TokenPtr(CurrentToken)^.FOperatorType := otBinary
      else if (KeywordIndex = kiCOLLATE) then
        TokenPtr(CurrentToken)^.FOperatorType := otCollate
      else if (KeywordIndex = kiCASE) then
      begin
        TokenPtr(CurrentToken)^.FOperatorType := otCase;
        InCaseOp := True;
      end
      else if (KeywordIndex = kiEND) then
        InCaseOp := False
      else if (KeywordIndex = kiIN) then
        TokenPtr(CurrentToken)^.FOperatorType := otIf
      else if (KeywordIndex = kiIN) then
        TokenPtr(CurrentToken)^.FOperatorType := otIn
      else if (KeywordIndex = kiINTERVAL) then
        TokenPtr(CurrentToken)^.FOperatorType := otInterval
      else if (KeywordIndex = kiSOUNDS) then
        TokenPtr(CurrentToken)^.FOperatorType := otSounds
      else if (KeywordIndex = kiTHEN) then
        TokenPtr(CurrentToken)^.FOperatorType := otThen
      else if (KeywordIndex = kiWHEN) then
        TokenPtr(CurrentToken)^.FOperatorType := otWhen;

    case (TokenPtr(CurrentToken)^.TokenType) of
      ttUnknown,
      ttSpace,
      ttReturn:
        raise ERangeError.Create(SArgumentOutOfRange);
      ttComma,
      ttCloseBracket,
      ttDelimiter:
        SetError(PE_UnexpectedToken, CurrentToken);
      ttOpenBracket:
        if (NodeCount = 0) then
          AddNode(ParseSubArea([]), False)
        else if (IsRangeNode(NodePtr(Nodes[NodeCount - 1]))) then
          SetError(PE_UnexpectedToken, RangeNodePtr(Nodes[NodeCount - 1])^.FFirstToken)
        else if (TokenPtr(Nodes[NodeCount - 1])^.OperatorType = otIn) then
          AddNode(ParseSubArea([satSelectStmt, satExpressions]))
        else if (TokenPtr(Nodes[NodeCount - 1])^.OperatorType in [otInterval, otBinary, otCollate]) then
          AddNode(ParseSubArea([satPartitionIdentifiers]))
        else
          AddNode(ParseSubArea([]));
      else
        if ((NodeCount = 0) or (IsToken(Nodes[NodeCount - 1]) and (TokenPtr(Nodes[NodeCount - 1])^.OperatorType <> otUnknown))) then
          // Operand
          case (TokenPtr(CurrentToken)^.TokenType) of
            ttOperator:
              if (TokenPtr(CurrentToken)^.OperatorType <> otMulti) then
                SetError(PE_UnexpectedToken, CurrentToken)
              else
              begin
                TokenPtr(CurrentToken)^.FTokenType := ttIdentifier;
                TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
                TokenPtr(CurrentToken)^.FUsageType := utDbIdentifier;
                AddNode(TDbIdentifier.Create(Self, CurrentToken, ditAllFields));
              end;
            ttInteger,
            ttNumeric,
            ttString,
            ttDQIdentifier,
            ttCSString:
              begin
                TokenPtr(CurrentToken)^.FUsageType := utConst;
                AddNode(CurrentToken);
              end;
            ttVariable:
              begin
                TokenPtr(CurrentToken)^.FUsageType := utVariable;
                AddNode(CurrentToken);
              end;
            ttIdentifier,
            ttDBIdentifier,
            ttBRIdentifier,
            ttMySQLIdentifier:
              if ((NextToken[1] = 0) or (TokenPtr(NextToken[1])^.TokenType <> ttOpenBracket)) then
              begin
                TokenPtr(CurrentToken)^.FUsageType := utDbIdentifier;
                AddNode(TDbIdentifier.Create(Self, CurrentToken, ditField));
              end
              else
                AddNode(ParseFunction(), False);
            ttKeyword:
              if (TokenPtr(CurrentToken)^.KeywordIndex = kiNULL) then
              begin
                TokenPtr(CurrentToken)^.FUsageType := utConst;
                AddNode(CurrentToken);
              end
              else
                SetError(PE_UnexpectedToken, CurrentToken);
             else SetError(PE_UnexpectedToken, CurrentToken);
          end
        else if ((NodeCount > 0) and (not IsToken(Nodes[NodeCount - 1]) or (TokenPtr(Nodes[NodeCount - 1])^.OperatorType = otUnknown))) then
          // Operator
          case (TokenPtr(CurrentToken)^.OperatorType) of
            otFunction_,
            otInterval,
            otBinary,
            otCollate,
            otNot1,
            otInvertBits,
            otDot,
            otBitXOR,
            otMulti,
            otDivision,
            otDiv,
            otMod,
            otMinus,
            otPlus,
            otShiftLeft,
            otShiftRight,
            otBitAND,
            otBitOR,
            otEqual,
            otNullSaveEqual,
            otGreaterEqual,
            otGreater,
            otLessEqual,
            otLess,
            otNotEqual,
            otIS,
            otSounds,
            otLike,
            otRegExp,
            otIn,
            otBetween,
            otNot2,
            otAnd,
            otXOr,
            otPipes,
            otOr:
              begin
                TokenPtr(CurrentToken)^.FUsageType := utOperator;
                AddNode(CurrentToken);
              end;
            else
              SetError(PE_UnexpectedToken, CurrentToken);
          end
        else
          // Operand Prefix
          case (TokenPtr(CurrentToken)^.OperatorType) of
            otFunction_,
            otInterval,
            otBinary,
            otCollate,
            otNot1,
            otInvertBits:
              begin
                TokenPtr(CurrentToken)^.FUsageType := utOperator;
                AddNode(CurrentToken);
              end;
            otMinus:
              begin
                TokenPtr(CurrentToken)^.FUsageType := utOperator;
                TokenPtr(CurrentToken)^.FOperatorType := otUnaryMinus;
                AddNode(CurrentToken);
              end;
            otPlus:
              begin
                TokenPtr(CurrentToken)^.FUsageType := utOperator;
                TokenPtr(CurrentToken)^.FOperatorType := otUnaryPlus;
                AddNode(CurrentToken);
              end;
            otLike:
              if (not IsToken(Nodes[NodeCount - 1]) or (TokenPtr(Nodes[NodeCount - 1])^.OperatorType <> otSounds)) then
                SetError(PE_UnexpectedToken, CurrentToken)
              else
              begin
                TokenPtr(CurrentToken)^.FUsageType := utOperator;
                AddNode(CurrentToken);
              end;
            else
              SetError(PE_UnexpectedToken, CurrentToken);
          end;
    end;

    if (CurrentToken = 0) then
      KeywordIndex := -1
    else
      KeywordIndex := TokenPtr(CurrentToken)^.KeywordIndex;
  until (Error
    or (CurrentToken = 0)
    or (TokenPtr(CurrentToken)^.TokenType in [ttComma, ttCloseBracket, ttDelimiter])
    or ((not IsToken(Nodes[NodeCount - 1]) or (TokenPtr(Nodes[NodeCount - 1])^.OperatorType = otUnknown))
      and not ((TokenPtr(CurrentToken)^.OperatorType <> otUnknown)
        or (KeywordIndex = kiBETWEEN)
        or (KeywordIndex = kiBINARY)
        or (KeywordIndex = kiCOLLATE)
        or (KeywordIndex = kiCASE)
        or (KeywordIndex = kiIN)
        or (KeywordIndex = kiINTERVAL)
        or (KeywordIndex = kiSOUNDS)
        or (KeywordIndex = kiTHEN)
        or (KeywordIndex = kiWHEN)))
    or (not InCaseOp and (KeywordIndex = kiTHEN)));

  for OperatorPrecedence := 1 to MaxOperatorPrecedence do
  begin
    I := 0;
    while (not Error and (I < NodeCount - 1)) do
    begin
      if ((NodePtr(Nodes[I])^.FNodeType = ntToken) and (OperatorPrecedenceByOperatorType[TokenPtr(Nodes[I])^.OperatorType] = OperatorPrecedence)) then
        case (TokenPtr(Nodes[I])^.OperatorType) of
          otFunction_,
          otInterval,
          otBinary,
          otCollate:
            if (I >= NodeCount - 1) then
              if (CurrentToken = 0) then
                SetError(PE_IncompleteStmt)
              else
                SetError(PE_UnexpectedToken, CurrentToken)
            else if (not (NodePtr(Nodes[I + 1])^.FNodeType = ntExpressions)) then
              SetError(PE_UnexpectedToken, StmtNodePtr(Nodes[I + 1])^.FFirstToken)
            else
            begin
              Nodes[I] := TFunction.Create(Self, Nodes[I], Nodes[I + 1]);
              Dec(NodeCount);
              Move(Nodes[I + 2], Nodes[I + 1], (NodeCount - I - 1) * SizeOf(Nodes[0]));
            end;
          otNot1,
          otUnaryMinus,
          otUnaryPlus,
          otInvertBits,
          otNot2:
            if (I >= NodeCount - 1) then
              SetError(PE_IncompleteStmt)
            else
            begin
              Nodes[I] := TUnaryOperation.Create(Self, Nodes[I], Nodes[I + 1]);
              Dec(NodeCount);
              Move(Nodes[I + 2], Nodes[I + 1], (NodeCount - I - 1) * SizeOf(Nodes[0]));
            end;
          otDot:
            if (I >= NodeCount - 1) then
              SetError(PE_IncompleteStmt)
            else if (I = 0) then
              SetError(PE_UnexpectedToken, Nodes[I])
            else if ((NodePtr(Nodes[I - 1])^.NodeType <> ntDbIdentifier) or (PDbIdentifier(NodePtr(Nodes[I - 1]))^.FPrefix2 > 0)) then
              SetError(PE_UnexpectedToken, Nodes[I])
            else if (NodePtr(Nodes[I + 1])^.NodeType = ntDbIdentifier) then
            begin
              PDbIdentifier(NodePtr(Nodes[I + 1]))^.AddPrefix(Nodes[I - 1], Nodes[I]);
              Dec(NodeCount, 2);
              Move(Nodes[I + 1], Nodes[I - 1], (NodeCount - I + 1) * SizeOf(Nodes[0]));
              Dec(I);
            end
            else if (NodePtr(Nodes[I + 1])^.NodeType = ntFunction) then
            begin
              if ((PDbIdentifier(NodePtr(Nodes[I - 1]))^.FPrefix1 > 0) or (PFunction(NodePtr(Nodes[I + 1]))^.Identifier^.NodeType <> ntDbIdentifier)) then
                SetError(PE_UnexpectedToken, Nodes[I + 1])
              else
              begin
                PDbIdentifier(PFunction(NodePtr(Nodes[I + 1]))^.Identifier)^.AddPrefix(Nodes[I - 1], Nodes[I]);
                Dec(NodeCount, 2);
                Move(Nodes[I + 1], Nodes[I - 1], (NodeCount - I + 1) * SizeOf(Nodes[0]));
                Dec(I);
              end;
            end
            else
              SetError(PE_UnexpectedToken, Nodes[I + 1]);
          otBitXOR,
          otMulti,
          otDivision,
          otDiv,
          otMod,
          otMinus,
          otPlus,
          otShiftLeft,
          otShiftRight,
          otBitAND,
          otBitOR,
          otEqual,
          otNullSaveEqual,
          otGreaterEqual,
          otGreater,
          otLessEqual,
          otLess,
          otNotEqual,
          otIS,
          otLike,
          otRegExp,
          otIn,
          otAnd,
          otXOr,
          otPipes,
          otOr:
            if (I = 0) then
              SetError(PE_UnexpectedToken, Nodes[I])
            else if (I >= NodeCount - 1) then
              SetError(PE_IncompleteStmt)
            else
            begin
              Nodes[I - 1] := TBinaryOperation.Create(Self, Nodes[I], Nodes[I - 1], Nodes[I + 1]);
              Dec(NodeCount, 2);
              Move(Nodes[I + 2], Nodes[I], (NodeCount - I) * SizeOf(Nodes[0]));
              Dec(I);
            end;
          otBetween:
            if (I + 3 >= NodeCount) then
              SetError(PE_IncompleteToken, Nodes[I])
            else if ((NodePtr(Nodes[I + 2])^.NodeType <> ntToken) or (TokenPtr(Nodes[I + 2])^.OperatorType <> otAnd)) then
              SetError(PE_UnexpectedToken, Nodes[I + 2])
            else
            begin
              Nodes[I + 3] := TBetweenOperation.Create(Self, Nodes[I], Nodes[I + 2], Nodes[I - 1], Nodes[I + 1], Nodes[I + 3]);
              Dec(NodeCount, 4);
              Move(Nodes[I + 3], Nodes[I - 1], NodeCount - I);
              Dec(I);
            end;
          otSounds:
            if (NodeCount - 1 < I + 2) then
              SetError(PE_IncompleteToken, Nodes[I])
            else if ((NodePtr(Nodes[I + 1])^.NodeType <> ntToken) or (TokenPtr(Nodes[I + 1])^.OperatorType <> otLike)) then
              SetError(PE_UnexpectedToken, Nodes[I + 1])
            else
            begin
              Nodes[I + 2] := TSoundsLikeOperation.Create(Self, Nodes[I], Nodes[I + 1], Nodes[I - 1], Nodes[I + 2]);
              Dec(NodeCount, 3);
              Move(Nodes[I + 2], Nodes[I - 1], NodeCount - I);
              Dec(I);
            end;
          else
            begin
              case (NodePtr(Nodes[I])^.FNodeType) of
                ntToken: SetError(PE_UnexpectedToken, Nodes[I]);
                ntRangeNode: SetError(PE_UnexpectedToken, RangeNodePtr(Nodes[I])^.FFirstToken);
                else raise ERangeError.Create(SArgumentOutOfRange);
              end;
            end;
        end
      else
        Inc(I);
    end;
  end;

  if (not Error and (NodeCount > 1)) then
    SetError(PE_Unknown);
  if (Error or (NodeCount <> 1)) then
    Result := 0
  else
    Result := Nodes[0];
end;

function TCustomSQLParser.ParseFunction(): ONode;
var
  Identifier: ONode;
  Arguments: ONode;
begin
  TokenPtr(CurrentToken)^.FOperatorType := otFunction_;
  if ((FFunctions.Count = 0) or (FFunctions.IndexOf(TokenPtr(CurrentToken)^.FText.SQL, TokenPtr(CurrentToken)^.FText.Length) >= 0)) then
  begin
    TokenPtr(CurrentToken)^.FUsageType := utFunction;
    Identifier := CurrentToken;
  end
  else
  begin
    TokenPtr(CurrentToken)^.FUsageType := utDbIdentifier;
    Identifier := TDbIdentifier.Create(Self, CurrentToken, ditFunction);
  end;
  ApplyCurrentToken();

  Arguments := ParseSubArea([satExpressions]);

  if (Error) then
    Result := 0
  else
    Result := TFunction.Create(Self, Identifier, Arguments);
end;

function TCustomSQLParser.ParseGroup(): ONode;
var
  Expression: ONode;
  Direction: ONode;
begin
  Expression := ParseExpression();

  if (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiASC) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiDESC)) then
    Direction := 0
  else
  begin
    Direction := CurrentToken;
    ApplyCurrentToken();
  end;

  if (Error) then
    Result := 0
  else
    Result := TSelectStmt.TGroup.Create(Self, Expression, Direction);
end;

function TCustomSQLParser.ParseGroups(): ONode;
var
  RollupKeyword: ONode;
  WithKeyword: ONode;
begin
  Result := ParseSiblings(ntGroups, ParseGroup);

  if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
  begin
    WithKeyword := CurrentToken;
    ApplyCurrentToken();

    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiROLLUP) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else
    begin
      RollupKeyword := CurrentToken;
      ApplyCurrentToken();

      TSelectStmt.PGroups(NodePtr(Result))^.AddWithRollup(WithKeyword, RollupKeyword);
    end;
  end;
end;

function TCustomSQLParser.ParseIfStmt(): ONode;
var
  Expression: ONode;
  First: Boolean;
  OperatorToken: ONode;
  Part: ONode;
  ThenToken: ONode;
begin
  Assert((CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF));

  Result := TIfStmt.Create(Self);

  First := True;

  repeat
    if (First) then
      First := False
    else if (TokenPtr(CurrentToken)^.TokenType = ttDelimiter) then
      ApplyCurrentToken(); // ttDelimiter;

    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken).KeywordIndex <> kiIF)
      and (TokenPtr(CurrentToken).KeywordIndex <> kiELSE)
      and (TokenPtr(CurrentToken).KeywordIndex <> kiELSEIF)) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else
    begin
      OperatorToken := CurrentToken;
      if (TokenPtr(OperatorToken)^.KeywordIndex <> kiELSE) then
        ApplyCurrentToken();

      if (TokenPtr(OperatorToken)^.KeywordIndex = kiELSE) then
        Expression := 0
      else
        Expression := ParseExpression;

      if (not Error) then
        if (CurrentToken = 0) then
          SetError(PE_IncompleteStmt)
        else if ((TokenPtr(OperatorToken)^.KeywordIndex <> kiELSE) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiTHEN)) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          ThenToken := CurrentToken;
          ApplyCurrentToken();

          Part := TPLSQLCondPart.Create(Self, OperatorToken, Expression, ThenToken);

          if (CurrentToken = 0) then
            SetError(PE_IncompleteStmt)
          else
            repeat
              PPLSQLCondPart(NodePtr(Part))^.AddStmt(ParseStmt(True));

              if (CurrentToken = 0) then
                SetError(PE_IncompleteStmt)
              else if (TokenPtr(CurrentToken)^.TokenType <> ttDelimiter) then
                SetError(PE_UnexpectedToken, CurrentToken)
              else
                ApplyCurrentToken();
            until (Error
              or (CurrentToken = 0)
              or (TokenPtr(CurrentToken)^.KeywordIndex = kiELSE)
              or (TokenPtr(CurrentToken)^.KeywordIndex = kiELSEIF)
              or (TokenPtr(CurrentToken)^.KeywordIndex = kiEND));

          PIfStmt(NodePtr(Result))^.AddPart(Part);
        end;
    end;
  until (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex = kiEND));

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiEND) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else
    begin
      ApplyCurrentToken();

      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiIF) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
        ApplyCurrentToken();
    end;
end;

function TCustomSQLParser.ParseIndexHint(): ONode;
var
  IndexHintKind: TSelectStmt.TTable.TIndexHint.TIndexHintKind;
  IndexHintType: TSelectStmt.TTable.TIndexHint.TIndexHintType;
begin
  Result := 0;
  IndexHintKind := ihkUnknown;

  IndexHintType := ihtUnknown;
  if (CurrentToken = 0) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUSE) then
  begin
    IndexHintType := ihtUse;
    ApplyCurrentToken();
  end
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE) then
  begin
    IndexHintType := ihtIgnore;
    ApplyCurrentToken();
  end
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFORCE) then
  begin
    IndexHintType := ihtForce;
    ApplyCurrentToken();
  end
  else
    SetError(PE_UnexpectedToken, CurrentToken);

  if (not Error) then
  begin
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex <> kiINDEX) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiKEY)) then
      SetError(PE_UnexpectedToken, CurrentToken);

    if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFOR)) then
    begin
      ApplyCurrentToken();

      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiJOIN) then
        begin
          IndexHintKind := ihkJoin;
          ApplyCurrentToken();
          ParseSubArea([satIndexIdentifiers], True);
        end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiORDER) then
        if (CurrentToken = 0) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiBY) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          IndexHintKind := ihkOrderBy;
          ApplyCurrentToken();
          ParseSubArea([satIndexIdentifiers]);
        end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiGROUP) then
      begin
        ApplyCurrentToken();
        if (CurrentToken = 0) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiBY) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          IndexHintKind := ihkGroupBy;
          ApplyCurrentToken();
          ParseSubArea([satIndexIdentifiers]);
        end;
      end
      else
        SetError(PE_UnexpectedToken, CurrentToken);

      if (not Error) then
        Result := TSelectStmt.TTable.TIndexHint.Create(Self, IndexHintType, IndexHintKind);
    end;
  end;
end;

function TCustomSQLParser.ParseIndexIdentifier(): ONode;
begin
  Result := ParseDbIdentifier(ditIndex);
end;

function TCustomSQLParser.ParseTag(const KeywordIndex1: Integer; const KeywordIndex2: Integer = -1; const KeywordIndex3: Integer = -1; const KeywordIndex4: Integer = -1; const KeywordIndex5: Integer = -1): ONode;
var
  Nodes: TTag.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (CurrentToken = 0) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex1) then
    SetError(PE_UnexpectedToken, CurrentToken)
  else
  begin
    Nodes.KeywordToken1 := CurrentToken;
    ApplyCurrentToken();

    if (KeywordIndex2 >= 0) then
    begin
      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex2) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
      begin
        Nodes.KeywordToken2 := CurrentToken;
        ApplyCurrentToken();

        if (KeywordIndex3 >= 0) then
        begin
          if (CurrentToken = 0) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex3) then
            SetError(PE_UnexpectedToken, CurrentToken)
          else
          begin
            Nodes.KeywordToken3 := CurrentToken;
            ApplyCurrentToken();

            if (KeywordIndex4 >= 0) then
            begin
              if (CurrentToken = 0) then
                SetError(PE_IncompleteStmt)
              else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex4) then
                SetError(PE_UnexpectedToken, CurrentToken)
              else
              begin
                Nodes.KeywordToken4 := CurrentToken;
                ApplyCurrentToken();

                if (KeywordIndex5 >= 0) then
                begin
                  if (CurrentToken = 0) then
                    SetError(PE_IncompleteStmt)
                  else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex5) then
                    SetError(PE_UnexpectedToken, CurrentToken)
                  else
                  begin
                    Nodes.KeywordToken5 := CurrentToken;
                    ApplyCurrentToken();
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;

  if (Error) then
    Result := 0
  else
    Result := TTag.Create(Self, Nodes);
end;

function TCustomSQLParser.ParseOrder(): ONode;
var
  Expression: ONode;
  Direction: ONode;
begin
  Expression := ParseExpression();

  if (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiASC) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiDESC)) then
    Direction := 0
  else
  begin
    Direction := CurrentToken;
    ApplyCurrentToken();
  end;

  if (Error) then
    Result := 0
  else
    Result := TSelectStmt.TOrder.Create(Self, Expression, Direction);
end;

function TCustomSQLParser.ParseLoopStmt(): ONode;
var
  BeginLabel: ONode;
begin
  if (TokenPtr(CurrentToken)^.TokenType <> ttBeginLabel) then
    BeginLabel := 0
  else
  begin
    BeginLabel := CurrentToken;
    TokenPtr(CurrentToken)^.FUsageType := utLabel;
    ApplyCurrentToken();
  end;

  Assert(TokenPtr(CurrentToken)^.KeywordIndex = kiLOOP);
  ApplyCurrentToken();

  Result := TLoopStmt.Create(Self);

  repeat
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiEnd) then
      PLoopStmt(NodePtr(Result))^.AddStmt(ParseStmt(True));

    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttDelimiter) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else
    begin
      TokenPtr(CurrentToken)^.FUsageType := utSymbol;
      ApplyCurrentToken();
    end;
  until (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex = kiEND));

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else
    begin
      ApplyCurrentToken();

      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiLOOP) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
        ApplyCurrentToken();

      if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType = ttIdentifier)) then
        if ((BeginLabel = 0) or (StrIComp(PChar(TokenPtr(CurrentToken)^.AsString), PChar(TokenPtr(BeginLabel)^.AsString)) <> 0)) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          TokenPtr(CurrentToken)^.FTokenType := ttEndLabel;
          TokenPtr(CurrentToken)^.FUsageType := utLabel;
          ApplyCurrentToken();
        end;
    end;
end;

function TCustomSQLParser.ParsePartitionIdentifier(): ONode;
begin
  Result := ParseDbIdentifier(ditPartition);
end;

function TCustomSQLParser.ParseRepeatStmt(): ONode;
var
  BeginLabel: ONode;
begin
  if (TokenPtr(CurrentToken)^.TokenType <> ttBeginLabel) then
    BeginLabel := 0
  else
  begin
    BeginLabel := CurrentToken;
    TokenPtr(CurrentToken)^.FUsageType := utLabel;
    ApplyCurrentToken();
  end;

  Assert(TokenPtr(CurrentToken)^.KeywordIndex = kiREPEAT);
  ApplyCurrentToken();

  Result := TRepeatStmt.Create(Self);

  repeat
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiEnd) then
      PRepeatStmt(NodePtr(Result))^.AddStmt(ParseStmt(True));

    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttDelimiter) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else
    begin
      TokenPtr(CurrentToken)^.FUsageType := utSymbol;
      ApplyCurrentToken();
    end;
  until (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex = kiUNTIL));

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else
    begin
      ApplyCurrentToken(); // UNTIL

      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else
        PRepeatStmt(NodePtr(Result))^.SetCondition(ParseExpression());

      if (not Error) then
      begin
        if (CurrentToken = 0) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiREPEAT) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
          ApplyCurrentToken();

        if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType = ttIdentifier)) then
          if ((BeginLabel = 0) or (StrIComp(PChar(TokenPtr(CurrentToken)^.AsString), PChar(TokenPtr(BeginLabel)^.AsString)) <> 0)) then
            SetError(PE_UnexpectedToken, CurrentToken)
          else
          begin
            TokenPtr(CurrentToken)^.FTokenType := ttEndLabel;
            TokenPtr(CurrentToken)^.FUsageType := utLabel;
            ApplyCurrentToken();
          end;
      end;
    end;
end;

function TCustomSQLParser.ParseSelectStmt(): ONode;
var
  Found: Boolean;
  Nodes: TSelectStmt.TNodes;
begin
  Assert(TokenPtr(CurrentToken)^.KeywordIndex = kiSELECT);

  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.SelectToken := CurrentToken;
  ApplyCurrentToken();

  repeat
    Found := True;
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiAll) or (TokenPtr(CurrentToken)^.KeywordIndex = kiDISTINCT) or (TokenPtr(CurrentToken)^.KeywordIndex = kiDISTINCTROW)) then
    begin
      Nodes.DistinctToken := CurrentToken;
      ApplyCurrentToken();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiHIGH_PRIORITY) then
    begin
      Nodes.HighPriorityToken := CurrentToken;
      ApplyCurrentToken();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSTRAIGHT_JOIN) then
    begin
      Nodes.StraightJoinToken := CurrentToken;
      ApplyCurrentToken();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_SMALL_RESULT) then
    begin
      Nodes.SQLSmallResultToken := CurrentToken;
      ApplyCurrentToken();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_BIG_RESULT) then
    begin
      Nodes.SQLBigResultToken := CurrentToken;
      ApplyCurrentToken();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_BUFFER_RESULT) then
    begin
      Nodes.SQLBufferResultToken := CurrentToken;
      ApplyCurrentToken();
    end
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_CACHE) or (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_NO_CACHE)) then
    begin
      Nodes.SQLNoCacheToken := CurrentToken;
      ApplyCurrentToken();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_CALC_FOUND_ROWS) then
    begin
      Nodes.SQLCalcFoundRowsToken := CurrentToken;
      ApplyCurrentToken();
    end
    else
      Found := False;
  until (not Found);

  Nodes.ColumnsNode := ParseSiblings(ntColumns, ParseColumn);

  if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM)) then
  begin
    if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFROM) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else
    begin
      Nodes.FromToken := CurrentToken;
      ApplyCurrentToken();

      Nodes.TablesNodes := ParseSiblings(ntTables, ParseTableReference);
    end;

    if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE)) then
    begin
      Nodes.WhereToken := ParseExpression();
      ApplyCurrentToken();

      Nodes.WhereNode := ParseExpression();
    end;

    if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiGROUP)) then
    begin
      Nodes.GroupToken := ParseExpression();
      ApplyCurrentToken();

      if (CurrentToken = 0) then
        SetError(PE_IncompleteToken)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiBY) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
      begin
        Nodes.GroupByToken := ParseExpression();
        ApplyCurrentToken();

        Nodes.GroupsNode := ParseGroups();
      end;
    end;

    if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiHAVING)) then
    begin
      Nodes.HavingToken := CurrentToken;
      ApplyCurrentToken();

      if (CurrentToken = 0) then
        SetError(PE_IncompleteToken)
      else
        Nodes.HavingNode := ParseExpression();
    end;

    if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiORDER)) then
    begin
      Nodes.OrderToken := CurrentToken;
      ApplyCurrentToken();

      if (CurrentToken = 0) then
        SetError(PE_IncompleteToken)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiBY) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
      begin
        Nodes.OrderByToken := CurrentToken;
        ApplyCurrentToken();

        Nodes.OrdersNode := ParseSiblings(ntOrders, ParseOrder);
      end;
    end;

    if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLIMIT)) then
    begin
      Nodes.Limit.LimitToken := CurrentToken;
      ApplyCurrentToken();

      if (CurrentToken = 0) then
        SetError(PE_IncompleteToken)
      else
      begin
        Nodes.Limit.RowCountValueToken := CurrentToken;

        if ((CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType = ttComma)) then
        begin
          Nodes.Limit.CommaToken := CurrentToken;
          ApplyCurrentToken();

          Nodes.Limit.OffsetValueToken := Nodes.Limit.RowCountValueToken;
          Nodes.Limit.RowCountValueToken := CurrentToken;
          ApplyCurrentToken();
        end
        else if ((CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiOFFSET)) then
        begin
          Nodes.Limit.OffsetToken := CurrentToken;
          ApplyCurrentToken();

          Nodes.Limit.OffsetValueToken := CurrentToken;
          ApplyCurrentToken();
        end;
      end;
    end;
  end;

  Result := TSelectStmt.Create(Self, Nodes);
end;

function TCustomSQLParser.ParseSiblings(const ANodeType: TNodeType; const ParseSibling: TParseFunction; const Empty: Boolean = False): ONode;
var
  First: Boolean;
  Sibling: ONode;
begin
  case (ANodeType) of
    ntExpressions: Result := TExpressions.Create(Self);
    ntColumns: Result := TSelectStmt.TColumns.Create(Self);
    ntTables: Result := TSelectStmt.TTables.Create(Self);
    ntIndexHint: Result := TSelectStmt.TTable.TIndexHints.Create(Self);
    ntGroups: Result := TSelectStmt.TGroups.Create(Self);
    ntOrders: Result := TSelectStmt.TOrders.Create(Self);
    ntCompoundStmt: Result := TCompoundStmt.Create(Self);
    else raise ERangeError.Create(SArgumentOutOfRange);
  end;

  if (not Empty) then
    with PSiblings(NodePtr(Result))^ do
    begin
      First := True;
      repeat
        if (First) then
          First := False
        else
        begin
          TokenPtr(CurrentToken)^.FUsageType := utSymbol;
          ApplyCurrentToken();
        end;
        Sibling := ParseSibling();
        if (not Error) then
          AddSibling(Sibling);
      until (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.TokenType <> ttComma));
    end;
end;

function TCustomSQLParser.ParseSubArea(const ASubAreaTypes: TSubAreaTypes; const CanEmpty: Boolean = False): ONode;
var
  Empty: Boolean;
begin
  Assert(TokenPtr(CurrentToken)^.TokenType = ttOpenBracket);

  TokenPtr(CurrentToken)^.FUsageType := utSymbol;
  ApplyCurrentToken(); // ttOpenBracket

  if (CurrentToken = 0) then
  begin
    Result := 0;
    SetError(PE_IncompleteStmt);
  end
  else
  begin
    Empty := (CurrentToken = 0) or (TokenPtr(CurrentToken)^.TokenType = ttCloseBracket);
    if ((satSelectStmt in ASubAreaTypes) and not Empty and (TokenPtr(CurrentToken)^.KeywordIndex = kiSelect)) then
      Result := ParseSelectStmt()
    else if (satExpressions in ASubAreaTypes) then
      Result := ParseSiblings(ntExpressions, ParseExpression, CanEmpty and Empty)
    else if (satPartitionIdentifiers in ASubAreaTypes) then
      Result := ParseSiblings(ntExpressions, ParsePartitionIdentifier, CanEmpty and Empty)
    else if (satIndexIdentifiers in ASubAreaTypes) then
      Result := ParseSiblings(ntExpressions, ParseIndexIdentifier, CanEmpty and Empty)
    else if (satTableReferences in ASubAreaTypes) then
      Result := ParseSiblings(ntExpressions, ParseTableReference, CanEmpty and Empty)
    else if (satColumnIdentifiers in ASubAreaTypes) then
      Result := ParseSiblings(ntExpressions, ParseColumnIdentifier, CanEmpty and Empty)
    else
      Result := ParseExpression();

    if (not Error) then
      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
      begin
        TokenPtr(CurrentToken)^.FUsageType := utSymbol;
        ApplyCurrentToken(); // ttCloseBracket
      end;
  end;
end;

function TCustomSQLParser.ParseStmt(const PL_SQL: Boolean = False): ONode;
var
  FirstToken: ONode;
  KeywordIndex: Integer;
  KeywordToken: ONode;
  LabelToken: ONode;
  Stmt: PStmt;
  Token: PToken;
begin
  FirstToken := CurrentToken;
  KeywordToken := CurrentToken;
  if ((CurrentToken = 0) or (TokenPtr(CurrentToken)^.TokenType <> ttBeginLabel)) then
    LabelToken := 0
  else
  begin
    LabelToken := CurrentToken;
    KeywordToken := NextToken[1];
  end;

  if ((KeywordToken = 0) or (TokenPtr(KeywordToken)^.TokenType <> ttKeyword)) then
    KeywordIndex := 0
  else
    KeywordIndex := TokenPtr(KeywordToken)^.KeywordIndex;

  if (PL_SQL and (KeywordIndex = kiBEGIN)) then
    Result := ParseCompoundStmt()
  else if (LabelToken > 0) then
    Result := ParseUnknownStmt()
  else if (KeywordIndex = kiCREATE) then
    Result := ParseCreateStmt()
  else if (PL_SQL and (KeywordIndex = kiIF)) then
    Result := ParseIfStmt()
  else if (PL_SQL and (KeywordIndex = kiLOOP)) then
    Result := ParseLoopStmt()
  else if (PL_SQL and (KeywordIndex = kiREPEAT)) then
    Result := ParseRepeatStmt()
  else if (KeywordIndex = kiSELECT) then
    Result := ParseSelectStmt()
  else
    Result := ParseUnknownStmt();

  if (Error) then
    while ((CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType <> ttDelimiter)) do
      ApplyCurrentToken();

  Stmt := StmtPtr(Result);
  Stmt^.FErrorCode := FErrorCode;
  Stmt^.FErrorToken := FErrorToken;
  Stmt^.FParentNode := FRoot;
  Stmt^.FFirstToken := FirstToken;
  if (Root^.LastToken^.TokenType = ttDelimiter) then
    Stmt^.FLastToken := Root^.LastToken^.FPriorToken
  else
    Stmt^.FLastToken := Root^.FLastToken;
  while ((Stmt^.FLastToken <> Stmt^.FFirstToken) and (Stmt^.LastToken^.TokenType in [ttSpace, ttReturn, ttComment])) do
    Stmt^.FLastToken := Stmt^.LastToken^.FPriorToken;

  Token := Stmt^.FirstToken;
  while (Assigned(Token)) do
  begin
    if (Token^.FParentNode = 0) then
      Token^.FParentNode := Result;
    if (Token = StmtPtr(Result)^.LastToken) then
      Token := nil
    else
      Token := Token^.NextToken;
  end;
end;

function TCustomSQLParser.ParseTableReference(): ONode;

  function ParseTableFactor(): ONode;
  var
    Alias: ONode;
    AsToken: ONode;
    IndexHints: ONode;
    OJToken: ONode;
    OpenBracketToken: ONode;
    Partition: PNode;
    PartitionToken: ONode;
    Partitions: ONode;
    Prefix: ONode;
  begin
    if (CurrentToken = 0) then
    begin
      SetError(PE_IncompleteStmt);
      Result := 0;
    end
    else if (TokenPtr(CurrentToken)^.TokenType in ttIdentifiers) then
    begin
      Result := TDbIdentifier.Create(Self, CurrentToken, ditTable);
      ApplyCurrentToken();

      if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.OperatorType = otDot)) then
      begin
        if (NextToken[1] = 0) then
          SetError(PE_IncompleteStmt)
        else if (PDbIdentifier(NodePtr(Result))^.FPrefix2 > 0) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else if (not (TokenPtr(NextToken[1])^.TokenType in ttIdentifiers)) then
          SetError(PE_UnexpectedToken, NextToken[1])
        else
        begin
          Prefix := Result;
          Result := TDbIdentifier.Create(Self, NextToken[1], ditTable);
          PDbIdentifier(NodePtr(Result))^.AddPrefix(Prefix, CurrentToken);
        end;
        ApplyCurrentToken();
        ApplyCurrentToken();
      end;

      PartitionToken := 0;
      Partitions := 0;
      if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITION)) then
      begin
        PartitionToken := CurrentToken;
        ApplyCurrentToken();

        if (CurrentToken = 0) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          Partitions := ParseSubArea([satPartitionIdentifiers]);
          Partition := PSiblings(NodePtr(Partitions))^.FirstChild;
          while (Assigned(Partition)) do
          begin
            if (Partition^.NodeType <> ntDbIdentifier) then
              SetError(PE_UnexpectedToken, PStmtNode(Partition)^.FFirstToken)
            else if (PDbIdentifier(Partition)^.FPrefix1 > 0) then
              SetError(PE_UnexpectedToken, PDbIdentifier(Partition)^.Identifier^.NextToken^.Offset)
            else
              PDbIdentifier(Partition)^.FDbIdentifierType := ditPartition;
            Partition := PStmtNode(Partition)^.NextSibling;
          end;
        end;
      end;

      if (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiAs)) then
        AsToken := 0
      else
      begin
        AsToken := CurrentToken;
        ApplyCurrentToken();
      end;

      Alias := 0;
      if (not Error) then
        if ((AsToken > 0) and ((CurrentToken = 0) or (TokenPtr(CurrentToken)^.TokenType = ttDelimiter))) then
          SetError(PE_IncompleteStmt)
        else if ((AsToken > 0) and (CurrentToken > 0) and not (TokenPtr(CurrentToken)^.TokenType in ttIdentifiers)) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else if ((CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType in ttIdentifiers)) then
        begin
          TokenPtr(CurrentToken)^.FUsageType := utAlias;
          Alias := CurrentToken;
          ApplyCurrentToken();
        end;

      if (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiUSE) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiIGNORE) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiFORCE)) then
        IndexHints := 0
      else
        IndexHints := ParseSiblings(ntIndexHints, ParseIndexHint);

      Result := TSelectStmt.TTable.Create(Self, Result, AsToken, Alias, IndexHints, PartitionToken, Partitions);
    end
    else if (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket) then
    begin
      Result := ParseSubArea([satSelectStmt, satTableReferences]);

      if (not Error) then
        if (NodePtr(Result)^.NodeType = ntSelectStmt) then
        begin
          AsToken := 0;
          if (CurrentToken = 0) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiAs) then
            SetError(PE_UnexpectedToken, CurrentToken)
          else
          begin
            AsToken := CurrentToken;
            ApplyCurrentToken();
          end;

          Alias := 0;
          if (not Error) then
            if (CurrentToken = 0) then
              SetError(PE_IncompleteStmt)
            else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdentifiers)) then
              SetError(PE_UnexpectedToken, CurrentToken)
            else
            begin
              TokenPtr(CurrentToken)^.FUsageType := utAlias;
              Alias := CurrentToken;
              ApplyCurrentToken();
            end;

          Result := TSelectStmt.TTable.Create(Self, Result, AsToken, Alias);
        end;
    end
    else if (TokenPtr(CurrentToken)^.TokenType = ttOpenCurlyBracket) then
    begin
      OpenBracketToken := CurrentToken;
      ApplyCurrentToken(); // ttOpenCurlyBracket

      OJToken := 0;
      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiOJ) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
      begin
        OJToken := CurrentToken;
        ApplyCurrentToken();
      end;

      Result := ParseTableReference();

      if (not Error) then
        if (CurrentToken = 0) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseCurlyBracket) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          if (not IsRangeNode(NodePtr(Result))) then
            raise ERangeError.Create(SArgumentOutOfRange);
          RangeNodePtr(Result)^.AddChild(OpenBracketToken);
          RangeNodePtr(Result)^.AddChild(OJToken);
          RangeNodePtr(Result)^.AddChild(CurrentToken);
          ApplyCurrentToken();
        end;
    end
    else
    begin
      SetError(PE_UnexpectedToken, CurrentToken);
      Result := 0;
    end;
  end;

  procedure ApplyKeywordToken(var AKeywordTokens: TSelectStmt.TJoin.TKeywordTokens);
  var
    Index: Integer;
  begin
    Index := 0;
    while (AKeywordTokens[Index] > 0) do
    begin
      Inc(Index);
      if (Index = Length(AKeywordTokens)) then
        raise ERangeError.Create(SArgumentOutOfRange)
    end;

    AKeywordTokens[Index] := CurrentToken;

    ApplyCurrentToken();
  end;

var
  Condition: ONode;
  I: Integer;
  JoinType: TJoinType;
  JoinedTable: ONode;
  KeywordIndex: Integer;
  KeywordTokens: TSelectStmt.TJoin.TKeywordTokens;
begin
  repeat
    Result := ParseTableFactor();

    JoinType := jtUnknown;
    JoinedTable := 0;
    Condition := 0;
    for I := 0 to Length(KeywordTokens) - 1 do
      KeywordTokens[I] := 0;

    if (not Error and (CurrentToken > 0)) then
    begin
      KeywordIndex := TokenPtr(CurrentToken)^.KeywordIndex;

      if (KeywordIndex = kiINNER) then
        JoinType := jtInner
      else if (KeywordIndex = kiCROSS) then
        JoinType := jtCross
      else if (KeywordIndex = kiJOIN) then
        JoinType := jtEqui
      else if (KeywordIndex = kiLEFT) then
        JoinType := jtCross
      else if (KeywordIndex = kiRIGHT) then
        JoinType := jtCross
      else if (KeywordIndex = kiNATURAL) then
      begin
        ApplyKeywordToken(KeywordTokens);
        if (CurrentToken = 0) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLEFT) then
          JoinType := jtNaturalLeft
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiRIGHT) then
          JoinType := jtNaturalRight
        else
          SetError(PE_UnexpectedToken, CurrentToken);
      end
      else if (KeywordIndex = kiSTRAIGHT_JOIN) then
        JoinType := jtEqui
      else
        JoinType := jtUnknown;

      if (JoinType <> jtUnknown) then
      begin
        if (JoinType in [jtNaturalLeft, jtNaturalRight]) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          ApplyKeywordToken(KeywordTokens);

          if ((JoinType in [jtLeft, jtRight]) and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiOUTER)) then
            ApplyKeywordToken(KeywordTokens);

          if (JoinType in [jtInner, jtCross, jtLeft, jtRight]) then
            if (CurrentToken = 0) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiJOIN) then
              SetError(PE_UnexpectedToken, CurrentToken)
            else
              ApplyKeywordToken(KeywordTokens);
        end;

        if (not Error) then
          if ((JoinType in [jtInner, jtCross, jtEqui]) or (JoinType in [jtNaturalLeft, jtNaturalRight])) then
            JoinedTable := ParseTableFactor()
          else
            JoinedTable := ParseTableReference();

        if (not Error) then
          if (CurrentToken > 0) then
            if ((TokenPtr(CurrentToken)^.KeywordIndex = kiON) and not (JoinType in [jtNaturalLeft, jtNaturalRight])) then
            begin
              ApplyKeywordToken(KeywordTokens);
              Condition := ParseExpression()
            end
            else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiUSING) and not (JoinType in [jtNaturalLeft, jtNaturalRight])) then
            begin
              ApplyKeywordToken(KeywordTokens);
              Condition := ParseSubArea([satColumnIdentifiers]);
            end;

        Result := TSelectStmt.TJoin.Create(Self, Result, JoinType, JoinedTable, Condition, KeywordTokens);
      end;
    end;

    if (Error or (CurrentToken = 0)) then
      KeywordIndex := 0
    else
      KeywordIndex := TokenPtr(CurrentToken)^.KeywordIndex;
  until ((KeywordIndex <> kiINNER)
    and (KeywordIndex <> kiCROSS)
    and (KeywordIndex <> kiJOIN)
    and (KeywordIndex <> kiSTRAIGHT_JOIN)
    and (KeywordIndex <> kiLEFT)
    and (KeywordIndex <> kiRIGHT)
    and (KeywordIndex <> kiNATURAL));
end;

function TCustomSQLParser.ParseToken(): ONode;
label
  TwoChars,
  Selection, SelSpace, SelQuotedIdentifier, SelNotLess, SelNotEqual1, SelNotGreater, SelNot1, SelDoubleQuote, SelComment, SelModulo, SelDolor, SelAmpersand2, SelBitAND, SelSingleQuote, SelOpenBracket, SelCloseBracket, SelMySQLCodeEnd, SelMulti, SelComma, SelDoubleDot, SelDot, SelMySQLCode, SelDiv, SelNumeric, SelSLComment, SelArrow, SelMinus, SelPlus, SelAssign, SelColon, SelDelimiter, SelNULLSaveEqual, SelLessEqual, SelShiftLeft, SelNotEqual2, SelLess, SelEqual, SelGreaterEqual, SelShiftRight, SelGreater, SelParameter, SelAt, SelUnquotedIdentifier, SelDBIdentifier, SelBackslash, SelCloseSquareBracket, SelHat, SelMySQLCharacterSet, SelMySQLIdentifier, SelUnquotedIdentifierLower, SelOpenCurlyBracket, SelOpenCurlyBracket2, SelOpenCurlyBracket3, SelPipe, SelBitOR, SelCloseCurlyBracket, SelTilde, SelE,
  BindVariable,
  Colon,
  Comment,
  Intger, IntgerL, IntgerE,
  MLComment, MLCommentL, MLComment2,
  MySQLCharacterSet, MySQLCharacterSetL, MySQLCharacterSetLE, MySQLCharacterSetE,
  MySQLCondCode, MySQLCondCodeL, MySQLCondCodeE,
  Numeric, NumericL, NumericExp, NumericE, NumericDot, NumericLE,
  QuotedIdentifier, QuotedIdentifier2,
  Return, ReturnE,
  Separator,
  UnquotedIdentifier, UnquotedIdentifierLE, UnquotedIdentifierLabel,
  Variable,
  WhiteSpace, WhiteSpaceL, WhiteSpaceLE,
  Empty, Incomplete, Syntax, Error,
  TrippelChar,
  DoubleChar,
  SingleChar,
  Finish;
const
  Terminators: PChar = #9#10#13#32'#$%&()*+,-./;<=>@'; // Characters, terminating a token
  TerminatorsL = 21; // Count of Terminators
var
  DotFound: Boolean;
  EFound: Boolean;
  ErrorCode: Integer;
  KeywordIndex: Integer;
  Length: Integer;
  MySQLVersion: Integer;
  OperatorType: TOperatorType;
  SQL: PChar;
  TokenLength: Integer;
  TokenType: fspTypes.TTokenType;
begin
  SQL := FParsePos.Text;
  Length := FParsePos.Length;
  asm
      PUSH ES
      PUSH ESI
      PUSH EDI
      PUSH EBX

      PUSH DS                          // string operations uses ES
      POP ES
      CLD                              // string operations uses forward direction

      MOV ESI,SQL
      MOV ECX,Length

      MOV TokenType,ttUnknown
      MOV OperatorType,otUnknown
      MOV MySQLVersion,0
      MOV ErrorCode,PE_Success

    // ------------------------------

      CMP ECX,1                        // One character in SQL?
      JB Empty                         // Less!
      JA TwoChars                      // More!
      MOV EAX,0                        // Hi Char in EAX
      MOV AX,[ESI]                     // One character from SQL to AX
    TwoChars:
      MOV EAX,[ESI]                    // Two characters from SQL to AX

    Selection:
      CMP AX,9                         // Tab ?
      JE WhiteSpace                    // Yes!
      CMP AX,10                        // Line feed ?
      JE Return                        // Yes!
      CMP AX,13                        // Carriadge Return ?
      JE Return                        // Yes!
      CMP AX,31                        // Invalid char ?
      JBE Syntax                       // Yes!
    SelSpace:
      CMP AX,' '                       // Space ?
      JE WhiteSpace                    // Yes!
    SelNotLess:
      CMP AX,'!'                       // "!" ?
      JNE SelDoubleQuote               // No!
      CMP EAX,$003C0021                // "!<" ?
      JNE SelNotEqual1                 // No!
      MOV OperatorType,otGreaterEqual
      JMP DoubleChar
    SelNotEqual1:
      CMP EAX,$003D0021                // "!=" ?
      JNE SelNotGreater                // No!
      MOV OperatorType,otNotEqual
      JMP DoubleChar
    SelNotGreater:
      CMP EAX,$003E0021                // "!>" ?
      JNE SelNot1                      // No!
      MOV OperatorType,otLessEqual
      JMP DoubleChar
    SelNot1:
      MOV OperatorType,otNot1
      JMP SingleChar
    SelDoubleQuote:
      CMP AX,'"'                       // Double Quote  ?
      JNE SelComment                   // No!
      MOV TokenType,ttDQIdentifier
      MOV DX,'"'                       // End Quoter
      JMP QuotedIdentifier
    SelComment:
      CMP AX,'#'                       // "#" ?
      JE Comment                       // Yes!
    SelDolor:
      CMP AX,'$'                       // "$" ?
      JE Syntax                        // Yes!
    SelModulo:
      CMP AX,'%'                       // "%" ?
      JNE SelAmpersand2                // No!
      MOV OperatorType,otMOD
      JMP SingleChar
    SelAmpersand2:
      CMP AX,'&'                       // "&" ?
      JNE SelSingleQuote               // No!
      CMP EAX,$00260026                // "&&" ?
      JNE SelBitAND                    // No!
      MOV OperatorType,otAND
      JMP DoubleChar
    SelBitAND:
      MOV OperatorType,otBitAND
      JMP SingleChar
    SelSingleQuote:
      CMP AX,''''                      // Single Quote ?
      JNE SelOpenBracket               // No!
      MOV TokenType,ttString
      MOV DX,''''                      // End Quoter
      JMP QuotedIdentifier
    SelOpenBracket:
      CMP AX,'('                       // "(" ?
      JNE SelCloseBracket              // No!
      MOV TokenType,ttOpenBracket
      JMP SingleChar
    SelCloseBracket:
      CMP AX,')'                       // ")" ?
      JNE SelMySQLCodeEnd              // No!
      MOV TokenType,ttCloseBracket
      JMP SingleChar
    SelMySQLCodeEnd:
      CMP AX,'*'                       // "*" ?
      JNE SelPlus                      // No!
      CMP EAX,$002F002A                // "*/" ?
      JNE SelMulti                     // No!
      MOV TokenType,ttMySQLCodeEnd
      JMP DoubleChar
    SelMulti:
      MOV OperatorType,otMulti
      JMP SingleChar
    SelPlus:
      CMP AX,'+'                       // "+" ?
      JNE SelComma                     // No!
      MOV OperatorType,otPlus
      JMP SingleChar
    SelComma:
      CMP AX,','                       // "," ?
      JNE SelSLComment                 // No!
      MOV TokenType,ttComma
      JMP SingleChar
    SelSLComment:
      CMP AX,'-'                       // "-" ?
      JNE SelDoubleDot                 // No!
      CMP EAX,$002D002D                // "--" ?
      JE Comment                       // Yes!
    SelArrow:
      CMP EAX,$003E002D                // "->" ?
      JNE SelMinus                     // No!
      MOV OperatorType,otArrow
      JMP DoubleChar
    SelMinus:
      MOV OperatorType,otMinus
      JMP SingleChar
    SelDoubleDot:
      CMP AX,'.'                       // "." ?
      JNE SelMySQLCode                 // No!
      CMP EAX,$002E002E                // ".." ?
      JNE SelDot                       // No!
      MOV OperatorType,otDoubleDot
      JMP DoubleChar
    SelDot:
      MOV OperatorType,otDot
      JMP SingleChar
    SelMySQLCode:
      CMP AX,'/'                       // "/" ?
      JNE SelNumeric                   // No!
      CMP EAX,$002A002F                // "/*" ?
      JNE SelDiv                       // No!
      CMP ECX,3                        // Three characters in SQL?
      JB MLComment                     // No!
      CMP WORD PTR [ESI + 4],'!'       // "/*!" ?
      JNE MLComment                    // No!
      JMP MySQLCondCode                // MySQL Code!
    SelDiv:
      MOV OperatorType,otDivision
      JMP SingleChar
    SelNumeric:
      CMP AX,'9'                       // Digit?
      JBE Intger                       // Yes!
    SelAssign:
      CMP AX,':'                       // ":" ?
      JNE SelDelimiter                 // No!
      CMP EAX,$003D003A                // ":=" ?
      JNE Colon                        // No!
      MOV OperatorType,otAssign2
      JMP SingleChar
    SelDelimiter:
      CMP AX,';'                       // ";" ?
      JNE SelNULLSaveEqual             // No!
      MOV TokenType,ttDelimiter
      JMP SingleChar
    SelNULLSaveEqual:
      CMP AX,'<'                       // "<" ?
      JNE SelShiftLeft                 // No!
      CMP EAX,$003D003C                // "<=" ?
      JNE SelShiftLeft                 // No!
      CMP ECX,3                        // Three characters in SQL?
      JB SelShiftLeft                  // No!
      CMP WORD PTR [ESI + 4],'>'       // "<=>" ?
      JNE SelLessEqual                 // No!
      MOV OperatorType,otNULLSaveEqual
      JMP TrippelChar
    SelLessEqual:
      MOV OperatorType,otLessEqual
      JMP DoubleChar
    SelShiftLeft:
      CMP EAX,$003C003C                // "<<" ?
      JNE SelNotEqual2                 // No!
      MOV OperatorType,otShiftLeft
      JMP DoubleChar
    SelNotEqual2:
      CMP EAX,$003E003C                // "<>" ?
      JNE SelEqual                     // No!
      MOV OperatorType,otNotEqual
      JMP DoubleChar
    SelLess:
      MOV OperatorType,otLess
      JMP SingleChar
    SelEqual:
      CMP AX,'='                       // "=" ?
      JNE SelGreaterEqual              // No!
      MOV OperatorType,otEqual
      JMP SingleChar
    SelGreaterEqual:
      CMP AX,'>'                       // ">" ?
      JNE SelParameter                 // No!
      CMP EAX,$003D003E                // ">=" ?
      JNE SelShiftRight                // No!
      MOV OperatorType,otGreaterEqual
      JMP DoubleChar
    SelShiftRight:
      CMP EAX,$003E003E                // ">>" ?
      JNE SelGreater                   // No!
      MOV OperatorType,otShiftRight
      JMP DoubleChar
    SelGreater:
      MOV OperatorType,otGreater
      JMP SingleChar
    SelParameter:
      CMP AX,'?'                       // "?" ?
      JNE SelAt                        // No!
      MOV OperatorType,otParameter
      JMP SingleChar
    SelAt:
      CMP AX,'@'                       // "@" ?
      JNE SelUnquotedIdentifier        // No!
      MOV TokenType,ttAt
      JMP SingleChar
    SelUnquotedIdentifier:
      CMP AX,'Z'                       // Up case character?
      JA SelDBIdentifier               // No!
      MOV TokenType,ttIdentifier
      JMP UnquotedIdentifier           // Yes!
    SelDBIdentifier:
      CMP AX,'['                       // "[" ?
      JNE SelBackslash                 // No!
      MOV TokenType,ttDBIdentifier
      MOV DX,']'                       // End Quoter
      JMP QuotedIdentifier
    SelBackslash:
      CMP AX,'\'                       // "\" ?
      JNE SelCloseSquareBracket        // No!
      MOV TokenType,ttBackslash
      JMP SingleChar
    SelCloseSquareBracket:
      CMP AX,']'                       // "]" ?
      JNE SelHat                       // Yes!
      JMP Incomplete
    SelHat:
      CMP AX,'^'                       // "^" ?
      JNE SelMySQLCharacterSet         // No!
      MOV OperatorType,otHat
      JMP SingleChar
    SelMySQLCharacterSet:
      CMP AX,'_'                       // "_" ?
      JE MySQLCharacterSet             // Yes!
    SelMySQLIdentifier:
      CMP AX,'`'                       // "`" ?
      JNE SelUnquotedIdentifierLower   // No!
      MOV TokenType,ttMySQLIdentifier
      MOV DX,'`'                       // End Quoter
      JMP QuotedIdentifier
    SelUnquotedIdentifierLower:
      CMP AX,'z'                       // Low case character?
      JA SelOpenCurlyBracket           // No!
      MOV TokenType,ttIdentifier
      JMP UnquotedIdentifier           // Yes!
    SelOpenCurlyBracket:
      CMP AX,'{'                       // "{" ?
      JNE SelPipe                      // No!
      MOV TokenType,ttOpenCurlyBracket
      CMP DWORD PTR [ESI + 2],$004A004F// "{OJ" ?
      JE SelOpenCurlyBracket2          // Yes!
      CMP DWORD PTR [ESI + 2],$006A004F// "{Oj" ?
      JE SelOpenCurlyBracket2          // Yes!
      CMP DWORD PTR [ESI + 2],$004A006F// "{oJ" ?
      JE SelOpenCurlyBracket2          // Yes!
      CMP DWORD PTR [ESI + 2],$006A006F// "{oj" ?
      JE SelOpenCurlyBracket2          // Yes!
      JMP SelOpenCurlyBracket3
    SelOpenCurlyBracket2:
      CMP ECX,4                        // Four characters in SQL?
      JB SelOpenCurlyBracket3          // No!
      PUSH EAX
      MOV AX,WORD PTR [ESI + 6]        // "{OJ " ?
      CALL Separator
      POP EAX
      JZ SingleChar                    // Yes!
    SelOpenCurlyBracket3:
      CMP WORD PTR [ESI + 2],' '       // "{ " ?
      JBE SingleChar                   // Yes!
      MOV TokenType,ttBRIdentifier
      MOV DX,'}'                       // End Quoter
      JMP QuotedIdentifier
    SelPipe:
      CMP AX,'|'                       // "|" ?
      JNE SelCloseCurlyBracket         // No!
      CMP EAX,$007C007C                // "||" ?
      JNE SelBitOR                     // No!
      MOV OperatorType,otPipes
      JMP DoubleChar
    SelBitOR:
      MOV OperatorType,otBitOr
      JMP SingleChar
    SelCloseCurlyBracket:
      CMP AX,'}'                       // "}" ?
      JNE SelTilde                     // No!
      MOV TokenType,ttCloseCurlyBracket
      JMP SingleChar
    SelTilde:
      CMP AX,'~'                       // "~" ?
      JNE SelE                         // No!
      MOV OperatorType,otInvertBits
      JMP SingleChar
    SelE:
      CMP AX,127                       // Chr(127) ?
      JNE UnquotedIdentifier           // No!
      JMP Syntax

    // ------------------------------

    BindVariable:
      MOV TokenType,ttBindVariable
      JMP UnquotedIdentifier

    // ------------------------------

    Colon:
      MOV TokenType,ttBindVariable
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      CMP ECX,0                        // End of SQL?
      JE Finish                        // Yes!
      MOV AX,[ESI]                     // One Character from SQL to AX
      CMP AX,'A'
      JB Finish
      CMP AX,'Z'
      JBE BindVariable
      CMP AX,'a'
      JB Finish
      CMP AX,'z'
      JBE BindVariable
      JMP Syntax

    // ------------------------------

    Comment:
      MOV TokenType,ttComment
      CMP AX,10                        // End of line?
      JE Finish                        // Yes!
      CMP AX,13                        // End of line?
      JE Finish                        // Yes!
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      CMP ECX,0                        // End of SQL?
      JE Finish                        // Yes!
      MOV AX,[ESI]                     // One Character from SQL to AX
      JMP Comment

    // ------------------------------

    Intger:
      MOV TokenType,ttInteger
    IntgerL:
      CMP AX,'.'                       // Dot?
      JE NumericDot                    // Yes!
      CMP AX,'E'                       // "E"?
      JE Numeric                       // Yes!
      CMP AX,'e'                       // "e"?
      JE Numeric                       // Yes!
      CMP AX,'0'                       // Digit?
      JB IntgerE                       // No!
      CMP AX,'9'
      JAE IntgerE                      // Yes!
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      CMP ECX,0                        // End of SQL?
      JE Finish                        // Yes!
      MOV AX,[ESI]                     // One Character from SQL to AX
      JMP IntgerL
    IntgerE:
      CALL Separator                   // SQL separator?
      JNE Syntax                       // No!
      MOV TokenType,ttInteger
      JMP Finish

    // ------------------------------

    MLComment:
      MOV TokenType,ttComment
      ADD ESI,4                        // Step over "/*" in SQL
      SUB ECX,2                        // Two characters handled
    MLCommentL:
      CMP ECX,2                        // Two characters left in SQL?
      JAE MLComment2                   // Yes!
      JMP Incomplete
    MLComment2:
      MOV EAX,[ESI]                    // Load two character from SQL
      CMP EAX,$002F002A
      JE DoubleChar
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      JMP MLCommentL

    // ------------------------------

    MySQLCharacterSet:
      MOV TokenType,ttCSString
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      MOV EDX,ESI
    MySQLCharacterSetL:
      MOV AX,[ESI]                     // One Character from SQL to AX
      CMP AX,'0'                       // Digit?
      JB MySQLCharacterSetE            // No!
      CMP AX,'9'
      JBE MySQLCharacterSetLE          // Yes!
      CMP AX,'A'                       // String character?
      JB MySQLCharacterSetE            // No!
      CMP AX,'Z'
      JBE MySQLCharacterSetLE          // Yes!
      CMP AX,'a'                       // String character?
      JB MySQLCharacterSetE            // No!
      CMP AX,'z'
      JBE MySQLCharacterSetLE          // Yes!
    MySQLCharacterSetLE:
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      JZ Incomplete                    // End of SQL!
      JMP MySQLCharacterSetL
    MySQLCharacterSetE:
      CMP ESI,EDX
      JE Incomplete
      MOV AX,[ESI]                     // One Character from SQL to AX
      CMP AX,''''                      // "'"?
      JNE Syntax
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      JZ Incomplete                    // End of SQL!
      MOV DX,''''                      // End Quoter
      JMP QuotedIdentifier

    // ------------------------------

    MySQLCondCode:
      MOV TokenType,ttMySQLCodeStart
      ADD ESI,4                        // Step over "/*" in SQL
      SUB ECX,2                        // Two characters handled
      MOV EAX,0
      MOV EDX,0
    MySQLCondCodeL:
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      CMP ECX,0                        // End of SQL?
      JE MySQLCondCodeE                // Yes!
      MOV AX,[ESI]                     // One Character from SQL to AX
      CMP AX,'0'                       // Digit?
      JB MySQLCondCodeE                // No!
      CMP AX,'9'                       // Digit?
      JA MySQLCondCodeE                // No!
      SUB AX,'0'                       // Str to Int
      PUSH EAX                         // EDX := EDX * 10
      MOV EAX,EDX
      MOV EDX,10
      MUL EDX
      MOV EDX,EAX
      POP EAX
      ADD EDX,EAX                      // EDX := EDX + Digit
      JMP MySQLCondCodeL
    MySQLCondCodeE:
      MOV MySQLVersion,EDX
      JMP Finish

    // ------------------------------

    Numeric:
      MOV DotFound,False               // One dot in a numeric value allowed only
      MOV EFound,False                 // One "E" in a numeric value allowed only
    NumericL:
      CMP AX,'.'                       // Dot?
      JE NumericDot                    // Yes!
      CMP AX,'E'                       // "E"?
      JE NumericExp                    // Yes!
      CMP AX,'e'                       // "e"?
      JE NumericExp                    // Yes!
      CMP AX,'0'                       // Digit?
      JB NumericE                      // No!
      CMP AX,'9'
      JA NumericE                      // No!
      JMP NumericLE
    NumericDot:
      CMP EFound,False                 // A 'e' before?
      JNE Syntax                       // Yes!
      CMP DotFound,False               // A dot before?
      JNE Syntax                       // Yes!
      MOV DotFound,True
      JMP NumericLE
    NumericExp:
      CMP DotFound,False               // A dot before?
      JE Syntax                        // No!
      CMP EFound,False                 // A 'e' before?
      JNE Syntax                       // Yes!
      MOV EFound,True
    NumericLE:
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      CMP ECX,0                        // End of SQL?
      JE Finish                        // Yes!
      MOV AX,[ESI]                     // One Character from SQL to AX
      JMP NumericL
    NumericE:
      CALL Separator                   // SQL separator?
      JNE Syntax                       // No!
      MOV TokenType,ttNumeric
      JMP Finish

    // ------------------------------

    QuotedIdentifier:
      // DX: End Quoter
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      CMP ECX,0                        // End of SQL?
      JE Incomplete                    // Yes!
    QuotedIdentifier2:
      MOV AX,[ESI]                     // One Character from SQL to AX
      CMP AX,'\'                       // Escaper?
      JE QuotedIdentifier
      CMP AX,DX                        // End Quoter (unescaped)?
      JNE QuotedIdentifier             // No!
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      JMP Finish

    // ------------------------------

    Return:
      MOV TokenType,ttReturn
      MOV EDX,EAX                      // Remember first character
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      JZ Finish                        // End of SQL!
      MOV AX,[ESI]                     // One Character from SQL to AX
      CMP AX,DX                        // Same character like before?
      JE Finish                        // Yes!
      CMP AX,10                        // Line feed?
      JE ReturnE                       // Yes!
      CMP AX,13                        // Carriadge Return?
      JNE Finish                       // No!
    ReturnE:
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      JMP Finish

    // ------------------------------

    Separator:
      // AX: Char
      PUSH ECX
      MOV EDI,[Terminators]
      MOV ECX,TerminatorsL
      REPNE SCASW                      // Character = SQL separator?
      POP ECX
      RET
      // ZF, if Char is in Terminators

    // ------------------------------

    Variable:
      MOV TokenType,ttVariable
      JMP UnquotedIdentifier

    // ------------------------------

    UnquotedIdentifier:
      CALL Separator                   // SQL separator?
      JE Finish
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      CMP ECX,0                        // End of SQL?
      JE Finish                        // Yes!
      MOV AX,[ESI]                     // One Character from SQL to AX
      CMP AX,'@'
      JE UnquotedIdentifier
      CMP AX,'0'
      JB Finish
      CMP AX,'9'
      JBE UnquotedIdentifier
      CMP AX,':'
      JE UnquotedIdentifierLabel
      CMP AX,'A'
      JB Finish
      CMP AX,'Z'
      JBE UnquotedIdentifier
      CMP AX,'_'
      JE UnquotedIdentifier
      CMP AX,'a'
      JB Finish
      CMP AX,'z'
      JBE UnquotedIdentifier
      CMP AX,128
      JAE UnquotedIdentifier
      JMP Finish
    UnquotedIdentifierLabel:
      MOV TokenType,ttBeginLabel
      JMP SingleChar

    // ------------------------------

    WhiteSpace:
      MOV TokenType,ttSpace
    WhiteSpaceL:
      CMP AX,9
      JE WhiteSpaceLE
      CMP AX,' '
      JE WhiteSpaceLE
      JMP Finish
    WhiteSpaceLE:
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      CMP ECX,0                        // End of SQL?
      JE Finish                        // Yes!
      MOV AX,[ESI]                     // One Character from SQL to AX
      JMP WhiteSpaceL

    // ------------------------------

    Empty:
      MOV ErrorCode,PE_EmptyText
      JMP Error
    Syntax:
      MOV ErrorCode,PE_Syntax
      MOV AX,[ESI]                     // One Character from SQL to AX
      CALL Separator
      JE Error
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
      CMP ECX,0                        // End of SQL?
      JNE Syntax
    Incomplete:
      MOV ErrorCode,PE_IncompleteToken
    Error:
      JMP Finish

    TrippelChar:
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
    DoubleChar:
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled
    SingleChar:
      ADD ESI,2                        // Next character in SQL
      DEC ECX                          // One character handled

    Finish:
      MOV EAX,Length
      SUB EAX,ECX
      MOV TokenLength,EAX

      POP EBX
      POP EDI
      POP ESI
      POP ES
  end;

  if (ErrorCode = PE_EmptyText) then
    Result := 0
  else
  begin
    if (Self is TMySQLSQLParser) then
    begin
      if (TMySQLSQLParser(Self).AnsiQuotes and (TokenType = ttMySQLIdentifier)
        or not TMySQLSQLParser(Self).AnsiQuotes and (TokenType = ttDQIdentifier)) then
        TokenType := ttUnknown;
      case (TokenType) of
        ttMySQLCodeStart:
          if (FMySQLVersion >= 0) then
          begin
            TokenType := ttUnknown;
            ErrorCode := PE_Syntax;
          end
          else
            FMySQLVersion := MySQLVersion;
        ttMySQLCodeEnd:
          if (FMySQLVersion < 0) then
          begin
            TokenType := ttUnknown;
            ErrorCode := PE_Syntax;
          end
          else
            FMySQLVersion := -1;
      end;
    end
    else if (TokenType in [ttMySQLCodeStart, ttMySQLCodeEnd]) then
    begin
      TokenType := ttUnknown;
      ErrorCode := PE_Syntax;
    end;

    if (OperatorType <> otUnknown) then
      TokenType := ttOperator;

    if (TokenType <> ttIdentifier) then
      KeywordIndex := -1
    else
    begin
      KeywordIndex := FKeywords.IndexOf(SQL, TokenLength);
      if (KeywordIndex >= 0) then
      begin
        TokenType := ttKeyword;
        OperatorType := OperatorTypeByKeywordIndex[KeywordIndex];
      end;
    end;

    Result := TToken.Create(Self, SQL, TokenLength, FParsePos.Origin, ErrorCode, FMySQLVersion, TokenType, OperatorType, KeywordIndex);

    if (Root^.FLastToken > 0) then
    begin
      TokenPtr(Result)^.FPriorToken := Root^.FLastToken;
    end;
    Root^.FLastToken := Result;

    FParsePos.Text := @SQL[TokenLength];
    Dec(FParsePos.Length, TokenLength);
    if (TokenType = ttReturn) then
    begin
      Inc(FParsePos.Origin.Y);
      FParsePos.Origin.X := 0;
    end
    else
      Inc(FParsePos.Origin.X, TokenLength);
  end;
end;

function TCustomSQLParser.ParseUnknownStmt(): ONode;
var
  Token: ONode;
begin
  Result := TStmt.Create(Self, stUnknown);

  Token := CurrentToken;
  if (Token > 0) then
    repeat
      Token := CurrentToken; ApplyCurrentToken();
    until ((Token = 0) or (TokenPtr(Token)^.TokenType = ttDelimiter));

  SetError(PE_UnkownStmt, CurrentToken);

  if (TokenPtr(Root^.FLastToken)^.TokenType = ttDelimiter) then
    StmtPtr(Result)^.FLastToken := TokenPtr(Root^.FLastToken)^.FPriorToken
  else
    StmtPtr(Result)^.FLastToken := Root^.FLastToken;
end;

function TCustomSQLParser.ParseUser(): ONode;
var
  Nodes: TUser.TNodes;
begin
  Result := 0;

  if (CurrentToken = 0) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCURRENT_USER) then
    if (((NextToken[1] = 0) or (TokenPtr(NextToken[1])^.TokenType <> ttOpenBracket))
      and ((NextToken[2] = 0) or (TokenPtr(NextToken[2])^.TokenType <> ttCloseBracket))) then
    begin
      Result := CurrentToken;
      ApplyCurrentToken();
    end
    else
      Result := ParseFunction()
  else if (not (TokenPtr(CurrentToken)^.TokenType in [ttIdentifier, ttString])) then
    SetError(PE_UnexpectedToken, CurrentToken)
  else
  begin
    FillChar(Nodes, SizeOf(Nodes), 0);

    Nodes.NameToken := CurrentToken;
    ApplyCurrentToken();

    if ((CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType = ttAt)) then
    begin
      Nodes.AtToken := CurrentToken;
      ApplyCurrentToken();

      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (not (TokenPtr(CurrentToken)^.TokenType in [ttIdentifier, ttString])) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
      begin
        Nodes.HostToken := CurrentToken;
        ApplyCurrentToken();
      end;
    end;

    if (not Error) then
      Result := TUser.Create(Self, Nodes);
  end;
end;

function TCustomSQLParser.ParseValue(const KeywordIndex: Integer): ONode;
var
  Nodes: TValue.TNodes;
begin
  if (CurrentToken = 0) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex) then
    SetError(PE_UnexpectedToken)
  else
  begin
    Nodes.KeywordToken := CurrentToken;
    ApplyCurrentToken();
  end;

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.OperatorType in [otEqual, otAssign])) then
      SetError(PE_UnexpectedToken, CurrentToken)
    else
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := CurrentToken;
      ApplyCurrentToken();
    end;

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else
    begin
      Nodes.ValueNode := CurrentToken;
      ApplyCurrentToken();
    end;

  if (Error) then
    Result := 0
  else
    Result := TValue.Create(Self, Nodes);
end;

function TCustomSQLParser.ParseWhileStmt(): ONode;
var
  BeginLabel: ONode;
  Condition: ONode;
begin
  if (TokenPtr(CurrentToken)^.TokenType <> ttBeginLabel) then
    BeginLabel := 0
  else
  begin
    BeginLabel := CurrentToken;
    TokenPtr(CurrentToken)^.FUsageType := utLabel;
    ApplyCurrentToken();
  end;

  Assert(TokenPtr(CurrentToken)^.KeywordIndex = kiWHILE);
  ApplyCurrentToken();

  Condition := ParseExpression();

  if (Error) then
    Result := 0
  else
    Result := TWhileStmt.Create(Self, Condition);

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiDO) then
      SetError(PE_UnexpectedToken)
    else
      ApplyCurrentToken();

  if (not Error) then
    repeat
      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiEnd) then
        PWhileStmt(NodePtr(Result))^.AddStmt(ParseStmt(True));

      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.TokenType <> ttDelimiter) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
      begin
        TokenPtr(CurrentToken)^.FUsageType := utSymbol;
        ApplyCurrentToken();
      end;
    until (Error or (CurrentToken = 0) or (TokenPtr(CurrentToken)^.KeywordIndex = kiEND));

  if (not Error) then
    if (CurrentToken = 0) then
      SetError(PE_IncompleteStmt)
    else
    begin
      ApplyCurrentToken();

      if (CurrentToken = 0) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiWHILE) then
        SetError(PE_UnexpectedToken, CurrentToken)
      else
        ApplyCurrentToken();

      if (not Error and (CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType = ttIdentifier)) then
        if ((BeginLabel = 0) or (StrIComp(PChar(TokenPtr(CurrentToken)^.AsString), PChar(TokenPtr(BeginLabel)^.AsString)) <> 0)) then
          SetError(PE_UnexpectedToken, CurrentToken)
        else
        begin
          TokenPtr(CurrentToken)^.FTokenType := ttEndLabel;
          TokenPtr(CurrentToken)^.FUsageType := utLabel;
          ApplyCurrentToken();
        end;
    end;
end;

function TCustomSQLParser.RangeNodePtr(const ANode: ONode): PRangeNode;
begin
  Assert(IsRangeNode(NodePtr(ANode)));

  Result := PRangeNode(NodePtr(ANode));
end;

procedure TCustomSQLParser.SaveToFile(const Filename: string; const FileType: TFileType = ftSQL);
var
  G: Integer;
  GenerationCount: Integer;
  Handle: THandle;
  HTML: string;
  LastTokenIndex: Integer;
  Node: PNode;
  ParentNodes: TList;
  Size: DWord;
  Stmt: PStmt;
  Token: PToken;
  Generation: Integer;
begin
  Handle := CreateFile(PChar(Filename),
                       GENERIC_WRITE,
                       FILE_SHARE_READ,
                       nil,
                       CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);

  HTML :=
    '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">' + #13#10 +
    '<html>' + #13#10 +
    '  <head>' + #13#10 +
    '  <meta http-equiv="content-type" content="text/html">' + #13#10 +
    '  <title>Debug - Free SQL Parser</title>' + #13#10 +
    '  <style type="text/css">' + #13#10 +
    '    body {' + #13#10 +
    '      font: 16px Verdana,Arial,Sans-Serif;' + #13#10 +
    '      color: #000;' + #13#10 +
    '    }' + #13#10 +
    '    td {' + #13#10 +
    '    }' + #13#10 +
    '    a {' + #13#10 +
    '      text-decoration: none;' + #13#10 +
    '    }' + #13#10 +
    '    a:link span { display: none; }' + #13#10 +
    '    a:visited span { display: none; }' + #13#10 +
//    '    a.error:hover {' + #13#10 +
//    '      display: block;' + #13#10 +
//    '      background-color: #F00;' + #13#10 +
//    '    }' + #13#10 +
    '    a:hover span {' + #13#10 +
    '      display: block;' + #13#10 +
    '      position: absolute;' + #13#10 +
    '      margin: 18px 0px 0px 0px;' + #13#10 +
    '      background-color: #FFC;' + #13#10 +
    '      padding: 2px 4px 2px 4px;' + #13#10 +
    '      border: 1px solid #000;' + #13#10 +
    '      color: #000;' + #13#10 +
    '    }' + #13#10 +
    '    .Node {' + #13#10 +
    '      font-size: 15px;' + #13#10 +
    '      text-align: center;' + #13#10 +
    '      background-color: #F4F4F4;' + #13#10 +
    '    }' + #13#10 +
    '    .SQL {' + #13#10 +
    '      font-size: 16px;' + #13#10 +
    '      background-color: #F4F4F4;' + #13#10 +
    '      text-align: center;' + #13#10 +
    '    }' + #13#10 +
    '    .StmtError {' + #13#10 +
    '      font-size: 16px;' + #13#10 +
    '      background-color: #FFC0C0;' + #13#10 +
    '      text-align: center;' + #13#10 +
    '    }' + #13#10 +
//    '    span a:visited { display: none; }' + #13#10 +
//    '    span.error a:hover {' + #13#10 +
//    '      background-color: #FDD;' + #13#10 +
//    '    }' + #13#10 +
//    '    span.plsql a:hover {' + #13#10 +
//    '      background-color: #CFC;' + #13#10 +
//    '    }' + #13#10 +
//    '    span.stmt a:hover {' + #13#10 +
//    '      background-color: #DDF;' + #13#10 +
//    '    }' + #13#10 +
    '  </style>' + #13#10 +
    '  </head>' + #13#10 +
    '  <body>' + #13#10;

  Stmt := Root^.FirstStmt;
  while (Assigned(Stmt)) do
  begin
    Token := Stmt^.FirstToken; GenerationCount := 0;
    while (Assigned(Token)) do
    begin
      GenerationCount := Max(GenerationCount, Token^.Generation);
      if (Token = Stmt^.LastToken) then
        Token := nil
      else
        Token := Token^.NextToken;
    end;

    ParentNodes := TList.Create();
    ParentNodes.Add(Root);

    HTML := HTML
      + '<table cellspacing="2" cellpadding="0" border="0">' + #13#10;

    if (not Stmt^.Error) then
      for Generation := 0 to GenerationCount - 1 do
      begin

        HTML := HTML
          + '<tr>' + #13#10;
        Token := Stmt^.FirstToken;
        LastTokenIndex := Token^.Index - 1;;
        while (Assigned(Token)) do
        begin
          Node := Token^.ParentNode; G := Token^.Generation;
          while (IsStmtNode(Node) and (G > Generation)) do
          begin
            Dec(G);
            if (G > Generation) then
              Node := PStmtNode(Node)^.ParentNode;
          end;

          if (IsStmtNode(Node) and (G = Generation) and (ParentNodes.IndexOf(Node) < 1)) then
          begin
            if (PStmtNode(Node)^.FirstToken^.Index - LastTokenIndex - 1 > 0) then
              HTML := HTML
                + '<td colspan="' + IntToStr(PStmtNode(Node)^.FirstToken^.Index - LastTokenIndex - 1) + '"></td>';
            HTML := HTML
              + '<td colspan="' + IntToStr(PStmtNode(Node)^.LastToken^.Index - PStmtNode(Node)^.FirstToken^.Index + 1) + '" class="Node">';
            HTML := HTML
              + '<a href="">'
              + HTMLEscape(NodeTypeToString[Node^.NodeType])
              + '<span><table cellspacing="2" cellpadding="0">';
            if (Assigned(PStmtNode(Node)^.ParentNode)) then
              HTML := HTML
                + '<tr><td>ParentNode Offset:</td><td>&nbsp;</td><td>' + IntToStr(PStmtNode(Node)^.ParentNode^.Offset) + '</td></tr>';
            HTML := HTML
              + '<tr><td>Offset:</td><td>&nbsp;</td><td>' + IntToStr(Node^.Offset) + '</td></tr>';
            if (IsStmt(Node)) then
            begin
              HTML := HTML + '<tr><td>StmtType:</td><td>&nbsp;</td><td>' + StmtTypeToString[PStmt(Node)^.StmtType] + '</td></tr>';
            end;
            if (Assigned(PNode(PStmtNode(Node)^.NextSibling))) then
              HTML := HTML
                + '<tr><td>NextSibling:</td><td>&nbsp;</td><td>' + IntToStr((PNode(PStmtNode(Node)^.NextSibling)^.Offset)) + '</td></tr>';
            case (Node^.NodeType) of
              ntDbIdentifier:
                HTML := HTML
                  + '<tr><td>DbIdentifierType:</td><td>&nbsp;</td><td>' + DbIdentifierTypeToString[PDbIdentifier(Node)^.DbIdentifierType] + '</td></tr>';
              ntBinaryOp:
                if (IsToken(PNode(PBinaryOperation(Node)^.Operator))) then
                  HTML := HTML
                    + '<tr><td>OperatorType:</td><td>&nbsp;</td><td>' + OperatorTypeToString[PToken(PBinaryOperation(Node)^.Operator)^.OperatorType] + '</td></tr>';
            end;
            HTML := HTML
              + '</table></span>'
              + '</a></td>' + #13#10;

            LastTokenIndex := PStmtNode(Node)^.LastToken^.Index;

            ParentNodes.Add(Node);
            Token := PStmtNode(Node)^.LastToken;
          end;

          if (Token <> Stmt^.LastToken) then
            Token := Token^.NextToken
          else
          begin
            if (Token^.Index - LastTokenIndex > 0) then
              HTML := HTML
                + '<td colspan="' + IntToStr(Token^.Index - LastTokenIndex) + '"></td>';
            Token := nil;
          end;
        end;
        HTML := HTML
          + '</tr>' + #13#10;
      end;

    ParentNodes.Free();


    HTML := HTML
      + '<tr class="SQL">' + #13#10;

    Token := Stmt^.FirstToken;
    while (Assigned(Token)) do
    begin
      HTML := HTML
        + '<td><a href="">';
      HTML := HTML
        + '<code>' + HTMLEscape(ReplaceStr(Token.Text, ' ', '&nbsp;')) + '</code>';
      HTML := HTML
        + '<span><table cellspacing="2" cellpadding="0">';
      if (not Stmt^.Error and Assigned(PStmtNode(Token)^.ParentNode)) then
        HTML := HTML + '<tr><td>ParentNode Offset:</td><td>&nbsp;</td><td>' + IntToStr(PStmtNode(Token)^.ParentNode^.Offset) + '</td></tr>';
      HTML := HTML + '<tr><td>Offset:</td><td>&nbsp;</td><td>' + IntToStr(PNode(Token)^.Offset) + '</td></tr>';
      HTML := HTML + '<tr><td>TokenType:</td><td>&nbsp;</td><td>' + HTMLEscape(TokenTypeToString[Token^.TokenType]) + '</td></tr>';
      if (Token^.KeywordIndex >= 0) then
        HTML := HTML + '<tr><td>KeywordIndex:</td><td>&nbsp;</td><td>ki' + HTMLEscape(FKeywords[Token^.KeywordIndex]) + '</td></tr>';
      if (Token^.OperatorType <> otUnknown) then
        HTML := HTML + '<tr><td>OperatorType:</td><td>&nbsp;</td><td>' + HTMLEscape(OperatorTypeToString[Token^.OperatorType]) + '</td></tr>';
      if (Token^.DbIdentifierType <> ditUnknown) then
        HTML := HTML + '<tr><td>DbIdentifierType:</td><td>&nbsp;</td><td>' + HTMLEscape(DbIdentifierTypeToString[Token^.DbIdentifierType]) + '</td></tr>';
      if ((Trim(Token^.AsString) <> '') and (Token^.KeywordIndex < 0)) then
        HTML := HTML + '<tr><td>AsString:</td><td>&nbsp;</td><td>' + HTMLEscape(Token^.AsString) + '</td></tr>';
      if (Token^.ErrorCode <> PE_Success) then
        HTML := HTML + '<tr><td>ErrorCode:</td><td>&nbsp;</td><td>' + IntToStr(Token^.ErrorCode) + '</td></tr>';
      if (Token^.UsageType <> utUnknown) then
        HTML := HTML + '<tr><td>UsageType:</td><td>&nbsp;</td><td>' + HTMLEscape(UsageTypeToString[Token^.UsageType]) + '</td></tr>';
      HTML := HTML
        + '</table></span>';
      HTML := HTML
        + '</a></td>' + #13#10;

      if (Token = Stmt^.LastToken) then
        Token := nil
      else
        Token := Token.NextToken;
    end;
    HTML := HTML
      + '</tr>' + #13#10;

    if (Stmt^.Error and Assigned(Stmt^.ErrorToken)) then
    begin
      HTML := HTML
        + '<tr class=""><td colspan="' + IntToStr(Stmt^.ErrorToken^.Index) + '"></td>'
        + '<td class="StmtError"><a href="">&uarr;'
        + '<span><table cellspacing="2" cellpadding="0">'
        + '<tr><td>ErrorCode:</td><td>' + IntToStr(Stmt.ErrorCode) + '</td></tr>'
        + '<tr><td>ErrorMessage:</td><td>' + HTMLEscape(Stmt.ErrorMessage) + '</td></tr>'
        + '</table></span>'
        + '</a></td>'
        + '<td colspan="' + IntToStr(Stmt^.LastToken.Index - Stmt^.ErrorToken^.Index) + '"></td>'
        + '</tr>' + #13#10;
    end;

    HTML := HTML
      + '</table>' + #13#10;

    Stmt := Stmt^.NextStmt;

    if (Assigned(Stmt)) then
    HTML := HTML
      + '<br><br>' + #13#10;
  end;

  HTML := HTML +
    '     <br>' + #13#10 +
    '     <br>' + #13#10 +
    '  </body>' + #13#10 +
    '</html>';

  WriteFile(Handle, PChar(BOM_UNICODE_LE)^, 2, Size, nil);

  WriteFile(Handle, PChar(HTML)^, Length(HTML) * SizeOf(Char), Size, nil);

  CloseHandle(Handle);
end;

procedure TCustomSQLParser.SetError(const AErrorCode: Integer; const AErrorNode: ONode = 0);
begin
  Assert(not Error);

  FErrorCode := AErrorCode;
  if (AErrorNode = 0) then
    FErrorToken := CurrentToken
  else
    FErrorToken := StmtNodePtr(AErrorNode)^.FFirstToken;
end;

procedure TCustomSQLParser.SetFunctions(AFunctions: string);
begin
  FFunctions.Text := AFunctions;
end;

procedure TCustomSQLParser.SetKeywords(AKeywords: string);

  function IndexOf(const Word: string): Integer;
  begin
    Result := FKeywords.IndexOf(PChar(Word), Length(Word));

    if (Result < 0) then
      raise ERangeError.CreateFmt(SKeywordNotFound, [Word]);
  end;

var
  Index: Integer;
begin
  FKeywords.Text := AKeywords;

  if (AKeywords <> '') then
  begin
    kiALL                 := IndexOf('ALL');
    kiAND                 := IndexOf('AND');
    kiAS                  := IndexOf('AS');
    kiALGORITHM           := IndexOf('ALGORITHM');
    kiASC                 := IndexOf('ASC');
    kiBEGIN               := IndexOf('BEGIN');
    kiBETWEEN             := IndexOf('BETWEEN');
    kiBINARY              := IndexOf('BINARY');
    kiBY                  := IndexOf('BY');
    kiCASCADED            := IndexOf('CASCADED');
    kiCASE                := IndexOf('CASE');
    kiCHECK               := IndexOf('CHECK');
    kiCOLLATE             := IndexOf('COLLATE');
    kiCREATE              := IndexOf('CREATE');
    kiCROSS               := IndexOf('CROSS');
    kiCURRENT_USER        := IndexOf('CURRENT_USER');
    kiDEFINER             := IndexOf('DEFINER');
    kiDESC                := IndexOf('DESC');
    kiDISTINCT            := IndexOf('DISTINCT');
    kiDISTINCTROW         := IndexOf('DISTINCTROW');
    kiDIV                 := IndexOf('DIV');
    kiDO                  := IndexOf('DO');
    kiELSE                := IndexOf('ELSE');
    kiELSEIF              := IndexOf('ELSEIF');
    kiEND                 := IndexOf('END');
    kiFORCE               := IndexOf('FORCE');
    kiFUNCTION            := IndexOf('FUNCTION');
    kiFROM                := IndexOf('FROM');
    kiFOR                 := IndexOf('FOR');
    kiGROUP               := IndexOf('GROUP');
    kiHAVING              := IndexOf('HAVING');
    kiHIGH_PRIORITY       := IndexOf('HIGH_PRIORITY');
    kiIGNORE              := IndexOf('IGNORE');
    kiIF                  := IndexOf('IF');
    kiIN                  := IndexOf('IN');
    kiINDEX               := IndexOf('INDEX');
    kiINNER               := IndexOf('INNER');
    kiINTERVAL            := IndexOf('INTERVAL');
    kiINVOKER             := IndexOf('INVOKER');
    kiIS                  := IndexOf('IS');
    kiJOIN                := IndexOf('JOIN');
    kiKEY                 := IndexOf('KEY');
    kiLIKE                := IndexOf('LIKE');
    kiLIMIT               := IndexOf('LIMIT');
    kiLOCAL               := IndexOf('LOCAL');
    kiLOOP                := IndexOf('LOOP');
    kiLEFT                := IndexOf('LEFT');
    kiMERGE               := IndexOf('MERGE');
    kiMOD                 := IndexOf('MOD');
    kiNATURAL             := IndexOf('NATURAL');
    kiNOT                 := IndexOf('NOT');
    kiNULL                := IndexOf('NULL');
    kiOFFSET              := IndexOf('OFFSET');
    kiOJ                  := IndexOf('OJ');
    kiON                  := IndexOf('ON');
    kiOPTION              := IndexOf('OPTION');
    kiOR                  := IndexOf('OR');
    kiORDER               := IndexOf('ORDER');
    kiOUTER               := IndexOf('OUTER');
    kiPARTITION           := IndexOf('PARTITION');
    kiPROCEDURE           := IndexOf('PROCEDURE');
    kiREGEXP              := IndexOf('REGEXP');
    kiREPEAT              := IndexOf('REPEAT');
    kiREPLACE             := IndexOf('REPLACE');
    kiRIGHT               := IndexOf('RIGHT');
    kiRLIKE               := IndexOf('RLIKE');
    kiROLLUP              := IndexOf('ROLLUP');
    kiSECURITY            := IndexOf('SECURITY');
    kiSELECT              := IndexOf('SELECT');
    kiSOUNDS              := IndexOf('SOUNDS');
    kiSQL                 := IndexOf('SQL');
    kiSQL_BIG_RESULT      := IndexOf('SQL_BIG_RESULT');
    kiSQL_BUFFER_RESULT   := IndexOf('SQL_BUFFER_RESULT');
    kiSQL_CACHE           := IndexOf('SQL_CACHE');
    kiSQL_CALC_FOUND_ROWS := IndexOf('SQL_CALC_FOUND_ROWS');
    kiSQL_NO_CACHE        := IndexOf('SQL_NO_CACHE');
    kiSQL_SMALL_RESULT    := IndexOf('SQL_SMALL_RESULT');
    kiSTRAIGHT_JOIN       := IndexOf('STRAIGHT_JOIN');
    kiTEMPTABLE           := IndexOf('TEMPTABLE');
    kiTHEN                := IndexOf('THEN');
    kiWHEN                := IndexOf('WHEN');
    kiWITH                := IndexOf('WITH');
    kiWHERE               := IndexOf('WHERE');
    kiUNDEFINED           := IndexOf('UNDEFINED');
    kiUNTIL               := IndexOf('UNTIL');
    kiUSE                 := IndexOf('USE');
    kiUSING               := IndexOf('USING');
    kiVIEW                := IndexOf('VIEW');
    kiWHILE               := IndexOf('WHILE');
    kiXOR                 := IndexOf('XOR');

    SetLength(OperatorTypeByKeywordIndex, FKeywords.Count);
    for Index := 0 to FKeywords.Count - 1 do
      OperatorTypeByKeywordIndex[Index] := otUnknown;
    OperatorTypeByKeywordIndex[kiAND]     := otAND;
    OperatorTypeByKeywordIndex[kiCASE]    := otCase;
    OperatorTypeByKeywordIndex[kiBETWEEN] := otBetween;
    OperatorTypeByKeywordIndex[kiBINARY]  := otBinary;
    OperatorTypeByKeywordIndex[kiCOLLATE] := otCollate;
    OperatorTypeByKeywordIndex[kiDIV]     := otDIV;
    OperatorTypeByKeywordIndex[kiELSE]    := otELSE;
    OperatorTypeByKeywordIndex[kiIS]      := otIS;
    OperatorTypeByKeywordIndex[kiIN]      := otIN;
    OperatorTypeByKeywordIndex[kiLIKE]    := otLike;
    OperatorTypeByKeywordIndex[kiMOD]     := otMOD;
    OperatorTypeByKeywordIndex[kiNOT]     := otNOT2;
    OperatorTypeByKeywordIndex[kiOR]      := otOR;
    OperatorTypeByKeywordIndex[kiREGEXP]  := otRegExp;
    OperatorTypeByKeywordIndex[kiRLIKE]   := otRegExp;
    OperatorTypeByKeywordIndex[kiSOUNDS]  := otSounds;
    OperatorTypeByKeywordIndex[kiWHEN]    := otWHEN;
    OperatorTypeByKeywordIndex[kiTHEN]    := otTHEN;
    OperatorTypeByKeywordIndex[kiXOR]     := otXOR;
  end;
end;

function TCustomSQLParser.SiblingsPtr(const ANode: ONode): PSiblings;
begin
  Assert(IsSiblings(NodePtr(ANode)));

  if (ANode = 0) then
    Result := nil
  else
    Result := @FNodes.Mem[ANode];
end;

function TCustomSQLParser.StmtNodePtr(const ANode: ONode): PStmtNode;
begin
  Assert(IsStmtNode(NodePtr(ANode)));

  Result := @FNodes.Mem[ANode];
end;

function TCustomSQLParser.StmtPtr(const ANode: ONode): PStmt;
begin
  Assert(IsStmtNode(NodePtr(ANode)));

  Result := @FNodes.Mem[ANode];
end;

function TCustomSQLParser.TokenPtr(const ANode: ONode): PToken;
begin
  Assert(NodePtr(ANode)^.FNodeType = ntToken);

  Result := PToken(NodePtr(ANode));
end;

{ TMySQLSQLParser *************************************************************}

constructor TMySQLSQLParser.Create(const MySQLVersion: Integer = 0; const LowerCaseTableNames: Integer = 0);
begin
  FMySQLVersion := MySQLVersion;
  FLowerCaseTableNames := LowerCaseTableNames;

  inherited Create(sdMySQL);

  FAnsiQuotes := False;

  Functions := MySQLFunctions;
  Keywords := MySQLKeywords;
end;

end.
