unit Indexes;

interface

uses
  Generics.Defaults,
  Generics.Collections, System.SyncObjs, System.SysUtils, Math;


type

  // -------------------------------------------------------------------------
  // ---------------------  Вспомогательные типы -----------------------------
  // -------------------------------------------------------------------------

  {$REGION 'Support Types'}
  // Массив integer
  TIntegerArray = TArray<integer>;
  // Массив строк
  TStringArray = TArray<string>;

  // Типы компаратора
  TCompareResult = (crLess,crEqual,crMore);
  TCompareMode = (cmAscending, cmDescending);
  // Типы функций пользовательского компаратора
  TCompareValue<T> = reference to function(const Item1,Item2: T): TCompareResult;
  TAction<T>       = reference to procedure(const Item: T);
  TPredicate<T>    = function(const Item: T): Boolean of object;

  TTypeCast = class
  public
    // ReinterpretCast does a hard type cast
    class function ReinterpretCast<ReturnT>(const Value): ReturnT;
    // StaticCast does a hard type cast but requires an input type
    class function StaticCast<T, ReturnT>(const Value: T): ReturnT;
  end;

  EIndexDuplicateKeyException = class(Exception);
  TRaiseMode = (rmSilentRaise,rmRaise,rmIgnore);
//  TRaiseMode = (rmIgnore,rmSilentRaise,rmRaise);

    {$ENDREGION}

  // -------------------------------------------------------------------------
  // -------------  THashTable (Индексированный массив) ----------------------
  // -------------------------------------------------------------------------

  {$REGION 'THashTable'}
  THashTable<TKey,TValue> = class(TEnumerable<TValue>)
  private
    procedure SetOnDuplicateKey(const Value: TRaiseMode);
    type
      // Структура данных
      TData = packed record
        Key   : TKey;
        Value : TValue;
      end;

      // enumerator class
      TEnumerator = class(TEnumerator<TValue>)
      private
        FHashTable: THashTable<TKey,TValue>;
        FIndex: Integer;
        function GetCurrent: TValue;
      protected
        function DoGetCurrent: TValue; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(const HashTable: THashTable<TKey,TValue>);
        property Current: TValue read GetCurrent;
        function MoveNext: Boolean;
      end;

      TNumById = function (const ID: TKey): integer of object;

    var
      FCount           : integer;
      FItems           : array of TData;               // Элементы массива с обвязкой
      FActive          : boolean;
      FFirstIndex      : integer;
      FLocked          : boolean;
      FIgnoreZeroIndex : boolean;
      FReturnDefValue  : Boolean;
      FDefaultValue    : TValue;
      FUniqueKeys      : Boolean;
      FOnDuplicateKey  : TRaiseMode;
      FIndexMod        : integer;
      FDeleteMark      : array of boolean;             // Метки удаленных записей
      FIndexArray      : array of array of integer;    // Структура индекса
      FOldIndexMod     : integer;
      FLock            : TCriticalSection;
      FComparer        : IEqualityComparer<TKey>;
      FComparerData    : IEqualityComparer<TValue>;
      FDoFreeData      : Boolean;
      FFilter          : TPredicate<TValue>;           // Фильтр для энумератора.

    procedure SetActive(const Value: Boolean); {$IFDEF Inline} inline; {$ENDIF}
    procedure HashClear(NewIndexMod: integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure HashRemove(const Data: TData; Index: integer = -1); {$IFDEF Inline} inline; {$ENDIF}
    procedure HashAdd(const Data: TData; Index: integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure HashMove(const Data: TData; Index: integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure reInitHashTable(Count: integer = -1);
    function  GetHash(const Data: TKey): integer; virtual;
    function  RecommendedDataSize(NewCount: integer = -1): integer; {$IFDEF Inline} inline; {$ENDIF}
    procedure onSetCount(Value: integer); {$IFDEF Inline} inline; {$ENDIF}
    function  Put(Index: Integer; const ID: TKey; const Data: TValue; isNew: Boolean): boolean;
    function  GetIdByNum(Num: Integer): TKey; {$IFDEF Inline} inline; {$ENDIF}
    procedure PutIdByNum(Num: Integer; const ID: TKey); {$IFDEF Inline} inline; {$ENDIF}
    function  GetValueByNum(Num: Integer): TValue; {$IFDEF Inline} inline; {$ENDIF}
    procedure PutValueByNum(Num: Integer; const Data: TValue); {$IFDEF Inline} inline; {$ENDIF}
    function  GetValueByID(ID: TKey): TValue; {$IFDEF Inline} inline; {$ENDIF}
    procedure PutValueByID(ID: TKey; Data: TValue); {$IFDEF Inline} inline; {$ENDIF}
    function  GetReturnDefaultValue: Boolean;
    function  onGetCount: integer;
    function  onGetHigh: integer;
    function  onGetLow: integer;
    procedure ExchangeItems(Index1, Index2: Integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure FreeElement(Num: integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure QuickSortKeyA(const Comparer: IComparer<TKey>; L, R: Integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure QuickSortKeyB(L, R: Integer; CompareEvt: TCompareValue<TKey>; Mode: TCompareMode); {$IFDEF Inline} inline; {$ENDIF}
    procedure QuickSortValueA(const Comparer: IComparer<TValue>; L, R: Integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure QuickSortValueB(L, R: Integer; CompareEvt: TCompareValue<TValue>; Mode: TCompareMode); {$IFDEF Inline} inline; {$ENDIF}
    procedure BaseInit(IndexMod: integer);
    procedure InitWithDefaultZeroIndex(ZeroKey: TKey; ZeroItem: TValue; IndexMod: integer = 1000);
    procedure Init(IndexMod: integer = 1000);
  protected
    function DoGetEnumerator: TEnumerator<TValue>; override;
  public
    // Пользовательский Тэг
    Tag : integer;

    // Создание стандартного массива
    constructor Create; overload;
    constructor Create(ExpectedCount: integer; DoFreeData: boolean = True); overload;
    // Создание массива со значением по умолчанию (ZeroKey и ZeroItem будут храниться в Item[0])
    constructor CreateWithDefaultZeroIndex(const ZeroKey: TKey; const ZeroItem: TValue; ExpectedCount: integer = 64);
    // Удичтожение массива
    destructor Destroy; override;

    // Получение энумератора
    function GetEnumerator: TEnumerator; reintroduce;
    // Получение массива значений
    function ToArray: TArray<TValue>; override;
    function KeysToArray: TArray<TKey>;

    // Признак завершенной иннициализации
    property  Active: Boolean read FActive write SetActive default False;
    // Признак автоматического очищения объектов - элементов массива.
    property  DoFreeData: Boolean read FDoFreeData write FDoFreeData;
    // Признак требования уникальных ключей.
    property  UniqueKeys: Boolean read FUniqueKeys write FUniqueKeys;
    // Процедура очистки массива
    procedure Clear(FullClear: boolean = False);
    // Принудительная смена размерности хэш-таблицы
    procedure ResetHashSize(IndexMod: integer);
    // Если значение не найдено - возвращять значение по умолчанию.
    property  ReturnDefaultValue: Boolean read GetReturnDefaultValue write FReturnDefValue;

    // Старт режима пакетных изменений.
    procedure BeginUpdates;
    // Завершение режима пакетных изменений.
    procedure EndUpdates;

    // Получение номера (первого) в массиве по ключу
    // Если элемент не найден возвращяет -1 или 0 в зависимости от использованного конструктора.
    function  NumById(ID: TKey): integer; {$IFDEF Inline} inline; {$ENDIF}

    // Добавление элемента массива (только ключ, без данных)
    function  Add(const ID: TKey):integer; overload; {$IFDEF Inline} inline; {$ENDIF}
    // Добавление элемента массива (Ключ + Данные)
    function  Add(const ID: TKey; const Value: TValue):integer; overload;

    // Добавление уникального элемента массива (только ключ, без данных)
    function  AddUnique(const ID: TKey):integer; overload; {$IFDEF Inline} inline; {$ENDIF}
    // Добавление уникального элемента массива (Ключ + Данные)
    function  AddUnique(const ID: TKey; const Value: TValue):integer; overload;
    function  AddOrSetValue(const ID: TKey; const Value: TValue):integer; {$IFDEF Inline} inline; {$ENDIF}

    // Вставка элемента массива на место с номером Num (только ключ, без данных)
    procedure Insert(Num: Integer; const ID: TKey); overload; {$IFDEF Inline} inline; {$ENDIF}
    // Вставка элемента массива на место с номером Num (Ключ + Данные)
    procedure Insert(Num: Integer; const ID: TKey; Value: TValue); overload; {$IFDEF Inline} inline; {$ENDIF}

    // Удаление элемента массива по номеру
    procedure Delete(Num: Integer); {$IFDEF Inline} inline; {$ENDIF}
    // Удаление элемента массива по ключу, возвращяет True если элемент найден
    function  DeleteByID(const ID: TKey): boolean; {$IFDEF Inline} inline; {$ENDIF}

    // Смена местами 2х элементов в массиве
    Procedure SwapItems(Num1,Num2: integer);

    // Получение ключа по номеру в массиве
    property  IdByNum[Num: Integer]: TKey read GetIdByNum write PutIdByNum;

    // Получение всех номеров в массиве по ключу
    function  NumsById(ID: TKey): TIntegerArray;

    // Доступ к элементу массива по номеру
    property  Item[Num: Integer]: TValue read GetValueByNum write PutValueByNum; default;
    property  DataByNum[Num: Integer]: TValue read GetValueByNum write PutValueByNum;

    // Доступ к элементу массива по ключу
    property  Item[ID: TKey]: TValue read GetValueByID write PutValueByID; default;
    property  DataByID[ID: TKey]: TValue read GetValueByID write PutValueByID;

    // Поиск элементов массива по ключу, True если элемент(ы) найдены.
    function FindId(const ID: TKey): boolean;  {$IFDEF Inline} inline; {$ENDIF}
    function Exists(const ID: TKey): boolean; overload; {$IFDEF Inline} inline; {$ENDIF}
    function Exists(const IDs: array of TKey; NeedAllValues: boolean = False): boolean; overload;
    function FindData(const Value: TValue): boolean;

    // Получение признака удаления элемента массива (в режиме пакетных изменений)
    function MarkedForDelete(Num: integer): boolean;

    // Функции пользовательской сортировки элементов массива
    procedure SortById(Comparer: IComparer<TKey> = nil); overload;
    procedure SortById(CompareEvt: TCompareValue<TKey>; Mode: TCompareMode = cmAscending); overload;
    procedure SortByData(Comparer: IComparer<TValue> = nil); overload;
    procedure SortByData(CompareEvt: TCompareValue<TValue>; Mode: TCompareMode = cmAscending); overload;

    // Нижняя граница массива (0 или 1 в зависимости от в зависимости от использованного конструктора)
    property  Low: integer read onGetLow;
    // Верхняя граница массива
    property  High: integer read onGetHigh;
    // Кол-во элементов в массиве
    property  Count: integer read onGetCount write onSetCount;

    // Блокировка массива от изменения(!) из других потоков, чтение не блокируется
    // Функция может быть не блокирующей в случае выставления параметра WaitForRelease в False
    // возвращяет True в случае успешного входа в критическую секцию
    function Lock(WaitForRelease: boolean = True): boolean;
    // Проверка на блокировку массива
    property Locked: boolean read FLocked;
    // Разблокировка массива
    procedure UnLock;

    // Произведение операций с массивом.
    procedure ForEach(const action: TAction<TValue>);

    // Функция импорта данных из внешнего массива
    procedure Assign(Source: THashTable<TKey,TValue>); reintroduce;

    // Фильтрующая функция для энумератора (только для энумератора!)
    property Filter: TPredicate<TValue> read FFilter write FFilter;

    // Правило реакции на дублирующиеся ключи экземпляра класса.
    // class var OnDuplicateRaiseRule - общее правило по умолчанию.
    property OnDuplicateKeyRule: TRaiseMode read FOnDuplicateKey write SetOnDuplicateKey;

    // Правило реакции на дублирующиеся ключи по умолчанию.
    class var DefaultDuplicateKeyRule: TRaiseMode;

    // Стандартные функции сравнения 2х значений
    class function CompareInteger(const Value1, Value2: Integer): TCompareResult;
    class function CompareInt64(const Value1, Value2: Int64): TCompareResult;
    class function CompareString(const Value1, Value2: String): TCompareResult;
    class function CompareVariant(const Value1, Value2: Variant): TCompareResult;
  end;
  {$ENDREGION}

  {$REGION 'THashTable Childs'}

  THashTable<TValue> = class(THashTable<integer,TValue>)
  private
    function GetHash(const Key: Integer): integer; override;
  public
    function GetIDArray: TIntegerArray; {$IFDEF Inline} inline; {$ENDIF}
    function GetMaxId: integer; {$IFDEF Inline} inline; {$ENDIF}
    procedure SortById(Mode: TCompareMode = cmAscending); overload;
  end;

  THashTableString<TValue> = class(THashTable<String,TValue>)
  private
    function  GetHash(const Key: String): integer; override;
  public
    function GetIDArray: TStringArray;
    procedure SortById(Mode: TCompareMode = cmAscending); overload;
  end;

  THashTableString = class(THashTableString<String>)
    procedure SortByData(Mode: TCompareMode = cmAscending); overload;
    procedure SortById(Mode: TCompareMode = cmAscending); overload;
    procedure SaveToFile(FileName: string; Delimeter: string = ';');
  end;

  THashTableKey<TKey> = class(THashTable<TKey,Integer>);

  THashTable = class(THashTable<Variant>)
    function GetIDArray: TIntegerArray;
    procedure SortByData(Mode: TCompareMode = cmAscending); overload;
  end;

  THashTableIntInt = class(THashTable<Integer>)
  private
    function  GetValueByNum(Num: Integer): integer; {$IFDEF Inline} inline; {$ENDIF}
    procedure PutValueByNum(Num: Integer; const Data: integer); {$IFDEF Inline} inline; {$ENDIF}
  public
    function GetIDArray: TIntegerArray;
    procedure SortByData(Mode: TCompareMode = cmAscending); overload;
    function Inc(ID: integer; Value: integer = 1): integer;

    property Item[Num: Integer]: integer read GetValueByNum write PutValueByNum; default;
  end;

  THashTableIntString = class(THashTable<String>)
    procedure SortByData(Mode: TCompareMode = cmAscending); overload;
    procedure SortById(Mode: TCompareMode = cmAscending); overload;
  end;

  THashTableStringInt = class(THashTableString<Integer>)
    function ToString: string; override;
    procedure SortByData(Mode: TCompareMode = cmAscending); overload;
  end;

  // Типы данных для стандартного справочника
  TNSIItem = record
    Name   : string;
    SName  : string;
    VName  : string;
    IType  : integer;
    IType2 : integer;
    IType3 : integer;
  end;
  TNSIItemArray = array of TNSIItem;

  THashTableNSI = class(THashTable<TNSIItem>)
  public
    function Add(ID: Integer;
                 Name: string;
                 SName: string = '';
                 VName: string = '';
                 IType: integer = 0;
                 IType2: integer = 0;
                 IType3: integer = 0):integer; overload;
  end;

  {$ENDREGION}

  // -------------------------------------------------------------------------
  // --------------------- TListEx (Расширенный лист) ------------------------
  // -------------------------------------------------------------------------

  {$REGION 'TListEx'}

  TListEx<T> = class(TList<T>)
  private
    FDoFreeData      : Boolean;
    FLock            : TCriticalSection;
    FLocked          : boolean;
    FSorted          : boolean;
    FComparer        : IComparer<T>;

    procedure FreeElement(Num: integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure QuickSortA(L, R: Integer; CompareEvt: TCompareValue<T>; Mode: TCompareMode); {$IFDEF Inline} inline; {$ENDIF}
    procedure QuickSortB(L, R: Integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure SetSorted(const Value: boolean); {$IFDEF Inline} inline; {$ENDIF}
  public
    // Пользовательский Тэг
    Tag : integer;
    // Создание стандартного списка
    constructor Create;
    // Удичтожение списка
    destructor Destroy; override;
    // Процедура очистки списка
    procedure Clear;
    // Признак автоматического очищения объектов - элементов списка
    property  DoFreeData: Boolean read FDoFreeData write FDoFreeData;
    // Функция пользовательской сортировки элементов списка
    procedure Sort(CompareEvt: TCompareValue<T>; Mode: TCompareMode = cmAscending);
    // Номер максимального элемента в списке.
    function High: integer; {$IFDEF Inline} inline; {$ENDIF}

    // Удаление элемента
    procedure Delete(Index: Integer);
    // Удаление элементов
    procedure DeleteRange(AIndex, ACount: Integer);

    // Добавление элемента
    function Add(const Value: T): Integer; {$IFDEF Inline} inline; {$ENDIF}

    // Поиск ближайшего значения
    function FindValue(const Value: T; StrictSeach: boolean = True): Integer;

    // Блокировка массива от изменения(!) из других потоков, чтение не блокируется
    // Функция может быть не блокирующей в случае выставления параметра WaitForRelease в False
    // возвращяет True в случае успешного входа в критическую секцию
    function Lock(WaitForRelease: boolean = True): boolean;
    // Проверка на блокировку массива
    property Locked: boolean read FLocked;
    // Разблокировка массива
    procedure UnLock;

    // Признак авто-сортированного листа
    property Sorted: boolean read FSorted write SetSorted;
  end;
  {$ENDREGION}

  {$REGION 'TListEx Childs'}
  TStringListEx = class(TListEx<string>)
    constructor Create;
  end;
  {$ENDREGION}

  // -------------------------------------------------------------------------
  // ------------------- TArrayEx (Расширенный массив) -----------------------
  // -------------------------------------------------------------------------

  {$REGION 'TArrayEx'}
  // {$DEFINE ArrayExEnumerator} // Могут быть глюки на сложных проектах и старых версиях компилятора
  {$IF CompilerVersion>27}
    {$DEFINE ArrayExEnumerator}
  {$ENDIF}

  TArrayEx<T> = record
  public
    // Доступ к элементам напрямую (unsafe)
    Items      : array of T;
    // Пользовательский Тэг
    Tag        : integer;
    // Признак необходимости освобождать элементы при удалении
    DoFreeData : Boolean;
  private
{$IFDEF ArrayExEnumerator}
    type
      TCollection = class;

      TEnumerator = class(TEnumerator<T>)
      private
        FParent : TCollection;
        FIndex  : Integer;
        function GetCurrent: T;
      protected
        function DoGetCurrent: T; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(Parent: TCollection);
        property Current: T read GetCurrent;
        function MoveNext: Boolean;
      end;

      TCollection = class(TEnumerable<T>)
      private
        FParent : pointer;
        function GetCount: Integer;
      protected
        function DoGetEnumerator: TEnumerator<T>; override;
      public
        constructor Create(const ArrayEx: TArrayEx<T>);
        function GetEnumerator: TEnumerator<T>; reintroduce;
        property Count: Integer read GetCount;
      end;
{$ENDIF}

    var
      FInitCapacity : string;                       // Признак иннициализации массива
      FEnumInit     : string;                       // Признак иннициализации итератора
      FIndexArray   : array of array of integer;    // Элементы индекса
      FComparer     : IEqualityComparer<T>;         // Компаратор
      FCapacity     : integer;                      // Кол-во выделенных элементов в памяти
      FArrayCount   : PNativeInt;
{$IFDEF ArrayExEnumerator}
      FCollection   : TCollection;                  // Коллекция для энуметратора
{$ENDIF}

    function GetElements(Index: integer): T; {$IFDEF Inline} inline; {$ENDIF}
    procedure SetElements(Index: integer; const Value: T); {$IFDEF Inline} inline; {$ENDIF}
    procedure QuickSortA(const Comparer: IComparer<T>; L, R: Integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure QuickSortB(L, R: Integer; CompareEvt: TCompareValue<T>; Less, More: TCompareResult); {$IFDEF Inline} inline; {$ENDIF}
    procedure HashClear(NewIndexMod: integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure HashAdd(const Value: T; Index: integer); {$IFDEF Inline} inline; {$ENDIF}
    function GetHash(const Value: T): integer; {$IFDEF Inline} inline; {$ENDIF}
    procedure SetIndex(Index: Integer; const Value: T); {$IFDEF Inline} inline; {$ENDIF}
    procedure SetCount(const Value: integer); {$IFDEF Inline} inline; {$ENDIF}
    function GetCount: integer; {$IFDEF Inline} inline; {$ENDIF}
    function GetHigh: integer; {$IFDEF Inline} inline; {$ENDIF}
    procedure SetHigh(const Value: integer); {$IFDEF Inline} inline; {$ENDIF}
    function GetLow: integer; {$IFDEF Inline} inline; {$ENDIF}
    procedure FreeElement(Num: integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure SetLengthFast(NewValue: integer); {$IFDEF Inline} inline; {$ENDIF}
  public
    // Конструкторы
    constructor Create(DoFreeData: boolean);

    // Доступ к элементам по умолчанию
    property Elements[Index: integer]: T read GetElements write SetElements; default;

    // Очистка массива
    procedure Clear; overload;

    // Добавление элемента(ов) в конец
    function Add(Value: T): integer; overload; {$IFDEF Inline} inline; {$ENDIF}
    function Add(Values: array of T): integer; overload;
    function AddUnique(Value: T): integer; {$IFDEF Inline} inline; {$ENDIF}

    // Вставка элемента по индексу
    procedure Insert(Index: integer; Value: T); overload; {$IFDEF Inline} inline; {$ENDIF}
    procedure Insert(Index: integer; Values: array of T); overload;

    // Удаление элемента по индексу
    procedure Delete(Index: integer); {$IFDEF Inline} inline; {$ENDIF}
    procedure DeleteRange(Index, Count: integer); {$IFDEF Inline} inline; {$ENDIF}

    // Создание индекса по массиву
    procedure CreateIndex(IndexMod: integer = -1);
    // Уничтожение индекса по массиву
    procedure DropIndex;

    // Кол-во элементов массива
    property Count: integer read GetCount write SetCount;
    // Индекс нижнего элемента массива
    property Low: integer read GetLow;
    // Индекс верхнего элемента массива
    property High: integer read GetHigh write SetHigh;

    // Поиск значения(ий) в массиве
    function Exists(Value: T): boolean; overload; {$IFDEF Inline} inline; {$ENDIF}
    function Exists(Values: array of T; NeedAllValues: boolean = False): boolean; overload;
    // Индекс(ы) значения в массиве
    function IndexOf(Value: T): integer; {$IFDEF Inline} inline; {$ENDIF}
    function IndexesOf(Value: T): TArrayEx<integer>; {$IFDEF Inline} inline; {$ENDIF}

    // Сортировка
    procedure Sort(Comparer: IComparer<T> = nil); overload;
    procedure Sort(CompareEvt: TCompareValue<T>; Mode: TCompareMode = cmAscending); overload;

    // Сериализатор в строку
    function ToString: string; overload;
    function ToString(Delimeter : string): string; overload;

{$IFDEF ArrayExEnumerator}
    function Collection: TCollection;
{$ENDIF}

    class operator Add(const A,B: TArrayEx<T>): TArrayEx<T>; overload;
    class operator Add(const A: TArrayEx<T>; const B: array of T): TArrayEx<T>; overload;
    class operator Add(const A: array of T; const B: TArrayEx<T>): TArrayEx<T>; overload;
    class operator Implicit(const A: TArrayEx<T>): TArray<T>; overload;
    class operator Implicit(A: TArray<T>): TArrayEx<T>; overload;
{$IF CompilerVersion>27}
    class operator In(const A,B: TArrayEx<T>): Boolean; overload;
    class operator In(const A: array of T; B: TArrayEx<T>): Boolean; overload;
{$ENDIF}
    class operator Equal(const A,B: TArrayEx<T>): Boolean;
    class operator NotEqual(const A,B: TArrayEx<T>): Boolean;
  end;
  {$ENDREGION}

  // -------------------------------------------------------------------------
  // ---------------------- TDateRanges (Диапозоны дат) ----------------------
  // -------------------------------------------------------------------------

  {$REGION 'TDateRanges'}

  TDateRanges<T> = class
  type
    TDateRange = packed record
      DateN : TDateTime;
      DateK : TDateTime;
      Value : T;
    end;

    function GetValue(Date: TDateTime): T;
    procedure SetValue(DateN, DateK: TDateTime; Value: T);
  public
    Ranges : TArrayEx<TDateRange>;

    // Создание стандартного списка
    constructor Create;
    // Процедура очистки списка
    procedure Clear;
    // Добавление диапозона.
    property Value[DateN,DateK: TDateTime]: T write SetValue; default;
    // Удаление данных в диапозоне
    procedure Delete(DateN,DateK: TDateTime);
    // Чтение значения
    property Value[Date: TDateTime]: T read GetValue; default;

    function Count: integer;

    function GetRanges(Value: T): TArrayEx<TDateRange>; overload;
    function GetRanges(DateN,DateK: TDateTime): TArrayEx<TDateRange>; overload;
    function GetRanges(DateN,DateK: TDateTime; Value: T): TArrayEx<TDateRange>; overload;
    function GetVoidSpaces(DateN,DateK: TDateTime): TArrayEx<TDateRange>;
  end;

  TDateRanges = class(TDateRanges<boolean>);

  {$ENDREGION}


implementation

uses TypInfo, RTTI;

{$REGION 'THashTable Implementation'}

{$REGION 'THashTable.TPairEnumerator Implementation'}
{ THashTable<TKey, TValue>.TPairEnumerator }

constructor THashTable<TKey, TValue>.TEnumerator.Create(const HashTable: THashTable<TKey, TValue>);
begin
  inherited Create;
  FHashTable:=HashTable;
  FIndex:=HashTable.Low-1;
end;

function THashTable<TKey, TValue>.TEnumerator.DoGetCurrent: TValue;
begin
  Result:=GetCurrent;
end;

function THashTable<TKey, TValue>.TEnumerator.DoMoveNext: Boolean;
begin
  Result:=MoveNext;
end;

function THashTable<TKey, TValue>.TEnumerator.GetCurrent: TValue;
begin
  Result:=FHashTable.FItems[FIndex].Value;
end;

function THashTable<TKey, TValue>.TEnumerator.MoveNext: Boolean;
begin
  if Assigned(FHashTable.FFilter) then begin
    repeat
      if FIndex>=FHashTable.High then
        Exit(False);
      inc(FIndex);
    until FHashTable.FFilter(GetCurrent);
    Result:=True;
  end else begin
    if FIndex>=FHashTable.High then
      Exit(False);
    inc(FIndex);
    Result:=True;
  end;
end;

{$ENDREGION}

{----------------------------------------------------}
{-------------- THashTable<TKey,TValue> -------------}
{----------------------------------------------------}

function THashTable<TKey,TValue>.NumById(ID: TKey): integer;
var
  i,m,Hash : integer;
begin
  if FActive then begin
    Hash:=GetHash(ID);
    m:=Abs(Hash mod FIndexMod);
    for i:=0 to System.High(FIndexArray[m]) do
      if FComparer.Equals(FItems[FIndexArray[m,i]].Key,ID) then
        Exit(FIndexArray[m,i]);
    Result:=FFirstIndex-1;
  end else begin
    for i:=FFirstIndex to FCount-1 do
      if FComparer.Equals(FItems[i].Key,ID) then
        Exit(i);
    Result:=FFirstIndex-1;
  end;
end;

function THashTable<TKey, TValue>.NumsById(ID: TKey): TIntegerArray;
var
  i,m,c,Hash : integer;
begin
  c:=0;
  SetLength(Result,c);
  if FActive then begin
    Hash:=GetHash(ID);
    m:=Abs(Hash mod FIndexMod);
    SetLength(Result,length(FIndexArray[m]));
    for i:=0 to System.High(FIndexArray[m]) do begin
      if FComparer.Equals(FItems[FIndexArray[m,i]].Key,ID) then begin
        inc(c);
        Result[c-1]:=FIndexArray[m,i];
      end;
    end;
    SetLength(Result,c);
  end else begin
    for i:=FFirstIndex to FCount-1 do begin
      if FComparer.Equals(FItems[i].Key,ID) then begin
        inc(c);
        setlength(Result,c);
        Result[c-1]:=i;
      end;
    end;
  end;
end;

function THashTable<TKey,TValue>.Add(const ID: TKey): integer;
begin
  Result:=Add(ID,Default(TValue));
end;

procedure THashTable<TKey, TValue>.BaseInit(IndexMod: integer);
begin
  FUniqueKeys:=True;
  FLocked:=False;
  FOnDuplicateKey:=DefaultDuplicateKeyRule;
  DoFreeData:=True;
  FIndexMod:=Max(IndexMod,1);
  FOldIndexMod:=FIndexMod;
  SetLength(FItems,FIndexMod);

  FComparer:=TEqualityComparer<TKey>.Default;
  FComparerData:=TEqualityComparer<TValue>.Default;

  if PTypeInfo(TypeInfo(TKey)).Kind=tkInteger then begin
    FComparer:=IEqualityComparer<TKey>(_LookupVtableInfo(giEqualityComparer, TypeInfo(TKey), SizeOf(TKey)));
  end;

  FReturnDefValue:=True;
  FLock:=nil;
  Clear;
end;

procedure THashTable<TKey, TValue>.Init(IndexMod: integer);
begin
  FIgnoreZeroIndex:=False;
  FFirstIndex:=0;

  BaseInit(IndexMod);

  Active:=True;
end;

procedure THashTable<TKey, TValue>.InitWithDefaultZeroIndex(ZeroKey: TKey; ZeroItem: TValue; IndexMod: integer);
begin
  FIgnoreZeroIndex:=True;
  FFirstIndex:=1;

  BaseInit(IndexMod);

  Put(0,ZeroKey,ZeroItem,True);
  FDefaultValue:=ZeroItem;
  Active:=True;
end;


procedure THashTable<TKey, TValue>.Insert(Num: Integer; const ID: TKey);
begin
  Insert(num,id,Default(TValue));
end;

procedure THashTable<TKey,TValue>.Insert(Num: Integer; const ID: TKey; Value: TValue);
var
  i            : integer;
  ForcedUpdate : boolean;
begin
  if length(FDeleteMark)>0 then raise Exception.Create('Denied. Batch Delete mode is active.');

  if (FIgnoreZeroIndex) and (Num=0) then Exit;

  if FActive and (abs(FCount-Num)>FCount div 4) then begin
    BeginUpdates;
    ForcedUpdate:=True;
  end;

  for i:=FCount-1 downto Num do begin
    Put(i+1,FItems[i].Key,FItems[i].Value,False);
  end;
  Put(Num,ID,Value,True);

  if ForcedUpdate then begin
    EndUpdates;
  end;
end;

function THashTable<TKey, TValue>.KeysToArray: TArray<TKey>;
var
  i : integer;
begin
  SetLength(Result, Count);
  for i:=Low to High do begin
    Result[i-FFirstIndex]:=FItems[i].Key;
  end;
end;

function THashTable<TKey, TValue>.Lock(WaitForRelease: boolean = True): boolean;
begin
  if FLock=nil then begin
    FLock:=TCriticalSection.Create;
  end;

  FLocked:=True;
  if WaitForRelease then begin
    FLock.Enter;
  end else begin
    FLocked:=FLock.TryEnter;
  end;
  Result:=FLocked;
end;

function THashTable<TKey, TValue>.MarkedForDelete(Num: integer): boolean;
begin
  if length(FDeleteMark)=0 then begin
    Result:=False;
  end else begin
    Result:=FDeleteMark[Num];
  end;
end;

function THashTable<TKey, TValue>.onGetCount: integer;
begin
  if FIgnoreZeroIndex then begin
    if FCount<1 then begin
      Result:=0;
    end else begin
      Result:=FCount-1;
    end;
  end else begin
    Result:=FCount;
  end;
end;

function THashTable<TKey, TValue>.onGetHigh: integer;
begin
  if FIgnoreZeroIndex and (FCount<1) then begin
    Result:=-1;
  end else begin
    Result:=FCount-1;
  end;
end;

function THashTable<TKey, TValue>.onGetLow: integer;
begin
  Result:=FFirstIndex;
end;

procedure THashTable<TKey,TValue>.onSetCount(Value: integer);
var
  NewVal : integer;
begin
  if FIgnoreZeroIndex then begin
    NewVal:=Value+FFirstIndex;
  end else begin
    NewVal:=Value;
  end;

  if FActive then begin
    SetLength(FItems,RecommendedDataSize(NewVal));
    FCount:=NewVal;
    FIndexMod:=length(FItems)+1;
    reInitHashTable;
  end else begin
    SetLength(FItems,RecommendedDataSize(NewVal));
    FCount:=NewVal;
  end;
end;

procedure THashTable<TKey,TValue>.Delete(Num: Integer);
var
  i            : integer;
  P            : PTypeInfo;
  PP           : Pointer;
  Obj          : TObject;
  ForcedUpdate : boolean;
begin
  if (FIgnoreZeroIndex) and (Num=0) then Exit;

  if FActive and (abs(FCount-Num)>FCount div 4) and (FCount>10) then begin
    ForcedUpdate:=True;
    BeginUpdates;
  end else begin
    ForcedUpdate:=False;
  end;

  if not FActive then begin
    if length(FDeleteMark)=0 then begin
      SetLength(FDeleteMark,FCount);
    end;
    FDeleteMark[num]:=True;
  end else begin
    HashRemove(FItems[num]);
    if FDoFreeData and (PTypeInfo(TypeInfo(TValue)).Kind=tkClass) then begin
      FreeElement(Num);
    end;
    for i:=Num+1 to FCount-1 do begin
      Put(i-1,FItems[i].Key,FItems[i].Value,False);
    end;
    FCount:=FCount-1;
  end;

  if ForcedUpdate then begin
    EndUpdates;
  end;
end;

function THashTable<TKey, TValue>.DeleteByID(const ID: TKey): boolean;
var
  n : integer;
begin
  n:=NumById(ID);

  if n>=FFirstIndex then begin
    Delete(n);
    Result:=True;
  end else begin
    Result:=False;
  end;
end;

destructor THashTable<TKey, TValue>.Destroy;
begin
  Clear(True);

  if FLock<>nil then begin
    FLock.Leave;
    FreeAndNil(FLock);
  end;

  Finalize(FItems);
  Finalize(FIndexArray);
end;

function THashTable<TKey, TValue>.DoGetEnumerator: TEnumerator<TValue>;
begin
  Result := GetEnumerator;
end;

function THashTable<TKey,TValue>.Add(const ID: TKey; const Value: TValue): integer;
begin
  if length(FDeleteMark)>0 then raise Exception.Create('Denied. Batch Delete mode is active.');

  if (FCount=0) and FIgnoreZeroIndex then begin
    Result:=1;
  end else begin
    Result:=FCount;
  end;
  if not Put(Result,ID,Value,True) then Exit(-1);
end;

function THashTable<TKey, TValue>.AddOrSetValue(const ID: TKey; const Value: TValue): integer;
begin
  Result:=NumById(ID);
  if Result<FFirstIndex then begin
    Result:=Add(Id,Value);
  end;
end;

function THashTable<TKey, TValue>.AddUnique(const ID: TKey): integer;
begin
  Result:=NumById(ID);
  if Result<FFirstIndex then begin
    Result:=Add(Id);
  end;
end;

function THashTable<TKey, TValue>.AddUnique(const ID: TKey; const Value: TValue): integer;
begin
  Result:=NumById(ID);
  if Result<FFirstIndex then begin
    Result:=Add(Id,Value);
  end;
end;

procedure THashTable<TKey, TValue>.Assign(Source: THashTable<TKey, TValue>);
var
  i,n1,n2   : integer;
  WasActive : boolean;
begin
  if Source.FIgnoreZeroIndex then begin
    InitWithDefaultZeroIndex(Source.IdByNum[0],Source[0],Source.FIndexMod);
    n1:=1;
    n2:=Source.Count;
  end else begin
    Init(Source.FIndexMod);
    n1:=0;
    n2:=Source.Count-1;
  end;

  WasActive:=FActive;
  if FActive then
    BeginUpdates;

  for i:=n1 to n2 do begin
    Add(Source.IdByNum[i],Source[i]);
  end;

  if WasActive then
    EndUpdates;
end;

procedure THashTable<TKey,TValue>.BeginUpdates;
var
  i : Integer;
begin
  if not FActive then Exit;

  Active:=False;
end;

procedure THashTable<TKey,TValue>.Clear(FullClear: boolean = False);
var
  i,n  : integer;
  PP   : Pointer;
  Obj  : TObject;
begin
  SetLength(FDeleteMark,0);
  Active:=True;

  if FIgnoreZeroIndex and not FullClear then begin
    n:=1;
  end else begin
    n:=0;
  end;

  try
    if DoFreeData and (PTypeInfo(TypeInfo(TValue)).Kind=tkClass) then begin
      for i:=n to FCount-1 do begin
        FreeElement(i);
      end;
    end;
    HashClear(FOldIndexMod);
  finally
    if FIgnoreZeroIndex then begin
      FCount:=1;
    end else begin
      FCount:=0;
    end;
    if FullClear then begin
      SetLength(FItems,FCount);
    end else begin
      SetLength(FItems,FIndexMod);
    end;
  end;
end;

class function THashTable<TKey, TValue>.CompareInteger(const Value1, Value2: integer): TCompareResult;
begin
  if Value1<Value2 then begin
    Result:=crLess;
  end else begin
    if Value1>Value2 then begin
      Result:=crMore;
    end else begin
      Result:=crEqual;
    end;
  end;
end;

class function THashTable<TKey, TValue>.CompareInt64(const Value1, Value2: int64): TCompareResult;
begin
  if Value1<Value2 then begin
    Result:=crLess;
  end else begin
    if Value1>Value2 then begin
      Result:=crMore;
    end else begin
      Result:=crEqual;
    end;
  end;
end;

class function THashTable<TKey, TValue>.CompareString(const Value1, Value2: String): TCompareResult;
begin
  if Value1<Value2 then begin
    Result:=crLess;
  end else begin
    if Value1>Value2 then begin
      Result:=crMore;
    end else begin
      Result:=crEqual;
    end;
  end;
end;

class function THashTable<TKey, TValue>.CompareVariant(const Value1, Value2: Variant): TCompareResult;
begin
  if Value1<Value2 then begin
    Result:=crLess;
  end else begin
    if Value1>Value2 then begin
      Result:=crMore;
    end else begin
      Result:=crEqual;
    end;
  end;
end;

constructor THashTable<TKey, TValue>.Create;
begin
  Create(64);
end;

constructor THashTable<TKey, TValue>.CreateWithDefaultZeroIndex(const ZeroKey: TKey; const ZeroItem: TValue; ExpectedCount: integer);
begin
  inherited Create;

  InitWithDefaultZeroIndex(ZeroKey,ZeroItem,ExpectedCount);
end;

constructor THashTable<TKey,TValue>.Create(ExpectedCount: integer; DoFreeData: boolean);
begin
  inherited Create;

  Init(ExpectedCount);
  Self.DoFreeData:=DoFreeData;
end;

procedure THashTable<TKey,TValue>.EndUpdates;
var
  i,n : integer;
begin
  if FActive then Exit;

  try
    if Length(FDeleteMark)>0 then begin
      if FDoFreeData and (PTypeInfo(TypeInfo(TValue)).Kind=tkClass) then begin
        for i:=0 to Length(FDeleteMark)-1 do begin
          if FDeleteMark[i] then begin
            FreeElement(i);
          end;
        end;
      end;
      n:=0;
      for i:=0 to Length(FDeleteMark)-1 do begin
        if not FDeleteMark[i] then begin
          if i<>n then begin
            Put(n,FItems[i].Key,FItems[i].Value,False);
          end;
          inc(n);
        end;
      end;
      FCount:=n;
    end;
  finally
    SetLength(FDeleteMark,0);
  end;

  Setlength(FItems,FCount);
  FIndexMod:=length(FItems)+1;
  ReInitHashTable;
  Active:=True;
end;


procedure THashTable<TKey, TValue>.ExchangeItems(Index1, Index2: Integer);
var
  Temp: TData;
begin
  Temp:=FItems[Index1];
  FItems[Index1]:=FItems[Index2];
  FItems[Index2]:=Temp;
end;

function THashTable<TKey, TValue>.Exists(const IDs: array of TKey; NeedAllValues: boolean): boolean;
var
  i: Integer;
begin
  Result:=NeedAllValues;

  for i:=0 to System.High(IDs) do begin
    if NeedAllValues then begin
      if not Exists(IDs[i]) then Exit(False);
    end else begin
      if Exists(IDs[i]) then Exit(True);
    end;
  end;
end;

function THashTable<TKey, TValue>.Exists(const ID: TKey): boolean;
begin
  Result:=NumById(ID)>=FFirstIndex;
end;

function THashTable<TKey, TValue>.FindData(const Value: TValue): boolean;
var
  i: Integer;
begin
  for i:=0 to High do begin
    if FComparerData.Equals(FItems[i].Value,Value) then begin
      Exit(True);
    end;
  end;
  Result:=False;
end;

function THashTable<TKey, TValue>.FindId(const ID: TKey): boolean;
begin
  Result:=NumById(ID)>=FFirstIndex;
end;

procedure THashTable<TKey, TValue>.ForEach(const Action: TAction<TValue>);
var
  Item: TValue;
begin
  for Item in Self do Action(item);
end;

procedure THashTable<TKey, TValue>.FreeElement(Num: integer);
begin
  try
    PObject(@FItems[num].Value)^.Free;
    FItems[num].Value:=Default(TValue);
  except
  end;
end;

function THashTable<TKey,TValue>.GetValueByID(ID: TKey): TValue;
var
  n   : integer;
begin
  n:=NumById(ID);
  if n<FFirstIndex then begin
    if FReturnDefValue then begin
      Result:=FDefaultValue;
    end else begin
      raise Exception.Create('Index Value Not Found!');
    end;
  end else begin
    Result:=FItems[n].Value;
  end;
end;


function THashTable<TKey,TValue>.GetValueByNum(Num: Integer): TValue;
begin
  Result:=FItems[Num].Value;
end;

function THashTable<TKey, TValue>.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

function THashTable<TKey, TValue>.GetHash(const Data: TKey): integer;
begin
  Result:=FComparer.GetHashCode(Data);
end;

function THashTable<TKey,TValue>.GetIdByNum(Num: Integer): TKey;
begin
  Result:=FItems[Num].Key;
end;

function THashTable<TKey, TValue>.GetReturnDefaultValue: Boolean;
begin
  Result:=FReturnDefValue or FIgnoreZeroIndex;
end;

procedure THashTable<TKey,TValue>.PutValueByID(ID: TKey; Data: TValue);
var
  n : integer;
  i,m : integer;
begin
  n:=NumById(ID);

  if n<FFirstIndex then begin
    Add(ID,Data);
  end else begin
    FItems[n].Value:=Data;
  end;
end;

procedure THashTable<TKey,TValue>.PutValueByNum(Num: Integer; const Data: TValue);
begin
  if (FIgnoreZeroIndex) and (Num=0) then Exit;

  FItems[Num].Value:=Data;
end;


procedure THashTable<TKey,TValue>.PutIdByNum(Num: Integer; const ID: TKey);
begin
  if (FIgnoreZeroIndex) and (Num=0) then Exit;

  if FActive then HashRemove(FItems[Num],Num);
  FItems[Num].Key:=ID;
  if FActive then HashAdd(FItems[Num],Num);
end;

procedure THashTable<TKey, TValue>.QuickSortKeyA(const Comparer: IComparer<TKey>; L, R: Integer);
var
  I, J: Integer;
  pivot: TKey;
  Temp: TData;
begin
  if (Length(FItems) = 0) or ((R - L) <= 0) then
    Exit;
  repeat
    I := L;
    J := R;
    pivot := FItems[L + (R - L) shr 1].Key;
    repeat
      while Comparer.Compare(FItems[I].Key, pivot) < 0 do
        Inc(I);
      while Comparer.Compare(FItems[J].Key, pivot) > 0 do
        Dec(J);
      if I <= J then
      begin
        if I <> J then
        begin
          temp := FItems[I];
          FItems[I] := FItems[J];
          FItems[J] := temp;
        end;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSortKeyA(Comparer, L, J);
    L := I;
  until I >= R;
end;

procedure THashTable<TKey, TValue>.QuickSortKeyB(L, R: Integer; CompareEvt: TCompareValue<TKey>; Mode: TCompareMode);
var
  I,J,P : Integer;
  Less  : TCompareResult;
  More  : TCompareResult;
begin
  if R<=L then Exit;

  case Mode of
    cmAscending: begin
      Less:=crLess;
      More:=crMore;
    end;
    cmDescending: begin
      Less:=crMore;
      More:=crLess;
    end;
  end;

  try
    repeat
      I:=L;
      J:=R;
      P:=(L+R) shr 1;
      repeat
        while CompareEvt(FItems[I].Key, FItems[P].Key) = Less do Inc(I);
        while CompareEvt(FItems[J].Key, FItems[P].Key) = More do Dec(J);
        if I<=J then
        begin
          if I<>J then
            ExchangeItems(I,J);
          if P=I then
            P:=J
          else if P=J then
            P:=I;
          Inc(I);
          Dec(J);
        end;
      until I>J;
      if L<J then QuickSortKeyB(L,J,CompareEvt,Mode);
      L:=I;
    until I>=R;
  except
  end;
end;

procedure THashTable<TKey, TValue>.QuickSortValueA(const Comparer: IComparer<TValue>; L, R: Integer);
var
  I, J: Integer;
  pivot: TValue;
  temp: TData;
begin
  if (Length(FItems) = 0) or ((R - L) <= 0) then
    Exit;
  repeat
    I := L;
    J := R;
    pivot := FItems[L + (R - L) shr 1].Value;
    repeat
      while Comparer.Compare(FItems[I].Value, pivot) < 0 do
        Inc(I);
      while Comparer.Compare(FItems[J].Value, pivot) > 0 do
        Dec(J);
      if I <= J then
      begin
        if I <> J then
        begin
          temp := FItems[I];
          FItems[I] := FItems[J];
          FItems[J] := temp;
        end;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSortValueA(Comparer, L, J);
    L := I;
  until I >= R;
end;

procedure THashTable<TKey, TValue>.QuickSortValueB(L, R: Integer; CompareEvt: TCompareValue<TValue>; Mode: TCompareMode);
var
  I,J,P : Integer;
  Less  : TCompareResult;
  More  : TCompareResult;
begin
  if R<=L then Exit;

  case Mode of
    cmAscending: begin
      Less:=crLess;
      More:=crMore;
    end;
    cmDescending: begin
      Less:=crMore;
      More:=crLess;
    end;
  end;

  try
    repeat
      I:=L;
      J:=R;
      P:=(L+R) shr 1;
      repeat
        while CompareEvt(FItems[I].Value, FItems[P].Value) = Less do Inc(I);
        while CompareEvt(FItems[J].Value, FItems[P].Value) = More do Dec(J);
        if I<=J then
        begin
          if (I<>J) and (CompareEvt(FItems[I].Value, FItems[J].Value)<>crEqual) then
            ExchangeItems(I,J);
          if P=I then
            P:=J
          else if P=J then
            P:=I;
          Inc(I);
          Dec(J);
        end;
      until I>J;
      if L<J then QuickSortValueB(L,J,CompareEvt,Mode);
      L:=I;
    until I>=R;
  except
  end;
end;

procedure THashTable<TKey,TValue>.HashClear(NewIndexMod: integer);
begin
  SetLength(FIndexArray,0);
  FIndexMod:=NewIndexMod;
  SetLength(FIndexArray,FIndexMod);
end;

procedure THashTable<TKey,TValue>.HashAdd(const Data: TData; Index: integer);
var
  n,m     : integer;
begin
  try
    m:=Abs(GetHash(Data.Key) mod FIndexMod);
    n:=length(FIndexArray[m]);
  except
  end;

  SetLength(FIndexArray[m],n+1);
  FIndexArray[m,n]:=Index;
end;

procedure THashTable<TKey,TValue>.HashMove(const Data: TData; Index: integer);
var
  n,m,i,p : integer;
begin
  m:=Abs(GetHash(Data.Key) mod FIndexMod);
  n:=length(FIndexArray[m]);

  p:=-1;
  for i:=0 to n-1 do begin
    if FComparer.Equals(FItems[FIndexArray[m,i]].Key,Data.Key) then begin
      p:=i;
      Break;
    end;
  end;
  if p<0 then begin
    p:=n;
    SetLength(FIndexArray[m],n+1);
  end;

  FIndexArray[m,p]:=Index;
end;

procedure THashTable<TKey,TValue>.HashRemove(const Data: TData; Index: integer);
var
  i,n,m,p : integer;
begin
  m:=Abs(GetHash(Data.Key) mod FIndexMod);
  n:=length(FIndexArray[m]);

  if Index=-1 then begin
    p:=-1;
    for i:=0 to n-1 do begin
      if FComparer.Equals(FItems[FIndexArray[m,i]].Key,Data.Key) then begin
        p:=i;
        Break;
      end;
    end;
  end else begin
    p:=-1;
    for i:=0 to n-1 do begin
      if FComparer.Equals(FItems[FIndexArray[m,i]].Key,Data.Key) and (FIndexArray[m,i]=Index) then begin
        p:=i;
        Break;
      end;
    end;
  end;
  if p>=0 then begin
    for i:=p to n-2 do begin
      FIndexArray[m,i]:=FIndexArray[m,i+1];
    end;
    SetLength(FIndexArray[m],n-1);
  end;
end;

function THashTable<TKey,TValue>.Put(Index: Integer; const ID: TKey; const Data: TValue; IsNew: Boolean): boolean;
var
  i        : integer;
  OldCount : integer;
begin
  Result:=False;
  if IsNew and FUniqueKeys and FActive and (FOnDuplicateKey<>rmIgnore) then begin
    if FindId(ID) then begin
      case FOnDuplicateKey of
        rmSilentRaise: begin
          try
            raise EIndexDuplicateKeyException.Create('HashTable duplicate key!');
          except
          end;
          Exit;
        end;
        rmRaise: raise EIndexDuplicateKeyException.Create('HashTable duplicate key!');
      end;
    end;
  end;

  OldCount:=FCount;

  if Index>=length(FItems) then begin
    SetLength(FItems,RecommendedDataSize);
  end;

  if Index>FCount then begin
    if FActive then begin
      for i:=FCount to Index do begin
        HashAdd(FItems[i],i);
      end;
    end;
    FCount:=Index+1;
  end;
  if Index>=FCount then begin
    FCount:=Index+1;
  end;

  FItems[Index].Key:=ID;
  FItems[Index].Value:=Data;

  if FActive then begin
    if Length(FItems)>FIndexMod then begin
      FIndexMod:=length(FItems)+1;
      reInitHashTable(OldCount);
    end;
    if isNew then begin
      HashAdd(FItems[Index],Index);
    end else begin
      HashMove(FItems[Index],Index);
    end;
  end;
  Result:=True;
end;

function THashTable<TKey,TValue>.RecommendedDataSize(NewCount: integer=-1): integer;
begin
  if NewCount=-1 then NewCount:=Length(FItems);
//  Result:=NewCount+trunc(Power(NewCount,0.9))+2;
  Result:=NewCount*2+2;
end;

procedure THashTable<TKey,TValue>.reInitHashTable(Count: integer = -1);
var
  i : integer;
begin
  HashClear(FIndexMod);

  if Count=-1 then Count:=FCount;

  for i:=0 to Count-1 do begin
    HashAdd(FItems[i],i);
  end;
end;

procedure THashTable<TKey, TValue>.ResetHashSize(IndexMod: integer);
begin
  FIndexMod:=IndexMod;
  FOldIndexMod:=FIndexMod;
  ReInitHashTable;
  Active:=True;
end;

procedure THashTable<TKey, TValue>.SetActive(const Value: Boolean);
begin
  FActive:=Value;
end;

procedure THashTable<TKey, TValue>.SetOnDuplicateKey(const Value: TRaiseMode);
begin
  FOnDuplicateKey := Value;
end;

procedure THashTable<TKey,TValue>.SortByData(CompareEvt: TCompareValue<TValue>; Mode: TCompareMode = cmAscending);
var
  WasActive : boolean;
begin
  if not Assigned(CompareEvt) then Exit;
  if length(FDeleteMark)>0 then raise Exception.Create('Denied. Batch Delete mode is active.');

  WasActive:=FActive;
  if FActive then
    BeginUpdates;

  QuickSortValueB(FFirstIndex,FCount-1,CompareEvt,Mode);

  if WasActive then
    EndUpdates;
end;

procedure THashTable<TKey, TValue>.SortByData(Comparer: IComparer<TValue>);
var
  OIndexMod : integer;
  WasActive : boolean;
begin
  if length(FDeleteMark)>0 then raise Exception.Create('Denied. Batch Delete mode is active.');

  WasActive:=FActive;
  if FActive then
    BeginUpdates;

  if Comparer=nil then Comparer:=TComparer<TValue>.Default;
  QuickSortValueA(Comparer, 0, High);

  if WasActive then
    EndUpdates;
end;

procedure THashTable<TKey, TValue>.SortById(Comparer: IComparer<TKey>);
var
  OIndexMod : integer;
  WasActive : boolean;
begin
  if length(FDeleteMark)>0 then raise Exception.Create('Denied. Batch Delete mode is active.');

  WasActive:=FActive;
  if FActive then
    BeginUpdates;

  if Comparer=nil then Comparer:=TComparer<TKey>.Default;
  QuickSortKeyA(Comparer, 0, High);

  if WasActive then
    EndUpdates;
end;

procedure THashTable<TKey, TValue>.SortById(CompareEvt: TCompareValue<TKey>; Mode: TCompareMode);
var
  WasActive : boolean;
begin
  if not Assigned(CompareEvt) then Exit;
  if length(FDeleteMark)>0 then raise Exception.Create('Denied. Batch Delete mode is active.');

  WasActive:=FActive;
  if FActive then
    BeginUpdates;

  QuickSortKeyB(FFirstIndex,FCount-1,CompareEvt,Mode);

  if WasActive then
    EndUpdates;
end;

procedure THashTable<TKey, TValue>.SwapItems(Num1, Num2: integer);
var
  Buff      : TData;
  WasActive : boolean;
begin
  if length(FDeleteMark)>0 then raise Exception.Create('Denied. Batch Delete mode is active.');

  WasActive:=FActive;
  if FActive then
    BeginUpdates;

  Buff:=FItems[Num1];
  FItems[Num1]:=FItems[Num2];
  FItems[Num2]:=Buff;

  if WasActive then
    EndUpdates;
end;

function THashTable<TKey, TValue>.ToArray: TArray<TValue>;
var
  i : integer;
begin
  SetLength(Result, Count);
  for i:=Low to High do begin
    Result[i-FFirstIndex]:=FItems[i].Value;
  end;
end;

procedure THashTable<TKey, TValue>.UnLock;
begin
  if FLock=nil then Exit;

  FLock.Release;
  FLocked:=False;
end;

class function TTypeCast.ReinterpretCast<ReturnT>(const Value): ReturnT;
begin
  Result := ReturnT(Value);
end;

class function TTypeCast.StaticCast<T, ReturnT>(const Value: T): ReturnT;
begin
  Result := ReinterpretCast<ReturnT>(Value);
end;
{$ENDREGION}

{$REGION 'THashTable Childs Implementation'}

{ THashTable }

function THashTable.GetIDArray: TIntegerArray;
var
  i,n : integer;
begin
  SetLength(Result,FCount);

  if FIgnoreZeroIndex then begin
    n:=1;
  end else begin
    n:=0;
  end;

  for i:=n to FCount-1 do begin
    Result[i]:=FItems[i].Key;
  end;
end;

procedure THashTable.SortByData(Mode: TCompareMode = cmAscending);
begin
  inherited SortByData(THashTable.CompareVariant,Mode);
end;

{ THashTableString }

procedure THashTableString.SaveToFile(FileName: string; Delimeter: string = ';');
var
  F : TextFile;
  i : integer;
begin
  AssignFile(F,FileName);
  try
    ReWrite(F);
    Writeln(F,'ID'+Delimeter+'Value');
    for i:=0 to High do begin
      Writeln(F,'"'+FItems[i].Key+'"'+Delimeter+'"'+FItems[i].Value+'"');
    end;
  finally
    CloseFile(f);
  end;
end;

procedure THashTableString.SortByData(Mode: TCompareMode = cmAscending);
begin
  inherited SortByData(THashTableString.CompareString,Mode);
end;

procedure THashTableString.SortById(Mode: TCompareMode);
begin
  inherited SortById(THashTable.CompareString,Mode);
end;

{ THashTable<TValue> }

function THashTable<TValue>.GetHash(const Key: Integer): integer;
begin
  Result:=Key;
end;

function THashTable<TValue>.GetIDArray: TIntegerArray;
var
  i,n : integer;
begin
  SetLength(Result,FCount);

  if FIgnoreZeroIndex then begin
    n:=1;
  end else begin
    n:=0;
  end;

  for i:=n to FCount-1 do begin
    Result[i]:=FItems[i].Key;
  end;
end;

function THashTable<TValue>.GetMaxId: integer;
var
  i: Integer;
begin
  Result:=0;
  for i:=Low to High do begin
    if i=Low then begin
      Result:=FItems[i].Key;
    end else begin
      if Result<FItems[i].Key then Result:=FItems[i].Key;
    end;
  end;
end;

procedure THashTable<TValue>.SortById(Mode: TCompareMode);
begin
  inherited SortById(THashTable.CompareInteger,Mode);
end;

{ THashTableNSI }

function THashTableNSI.Add(ID: Integer;
                           Name: string;
                           SName: string = '';
                           VName: string = '';
                           IType: integer = 0;
                           IType2: integer = 0;
                           IType3: integer = 0):integer;
var
  Item : TNSIItem;
begin
  Item.Name:=Name;
  Item.SName:=SName;
  Item.VName:=VName;
  Item.IType:=IType;
  Item.IType2:=IType2;
  Item.IType3:=IType3;
  result:=inherited Add(ID,Item);
end;


{ THashTableIntInt }

function THashTableIntInt.GetIDArray: TIntegerArray;
var
  i,n : integer;
begin
  SetLength(Result,FCount);

  if FIgnoreZeroIndex then begin
    n:=1;
  end else begin
    n:=0;
  end;

  for i:=n to FCount-1 do begin
    Result[i]:=FItems[i].Key;
  end;
end;

function THashTableIntInt.GetValueByNum(Num: Integer): integer;
begin
  Result:=inherited;
end;

function THashTableIntInt.Inc(ID, Value: integer): integer;
var
  n : integer;
begin
  n:=NumById(Id);
  if n<FFirstIndex then begin
    Add(id,Value);
    Result:=Value;
  end else begin
    Result:=Item[n]+Value;
    Item[n]:=Result;
  end;
end;

procedure THashTableIntInt.PutValueByNum(Num: Integer; const Data: integer);
begin
  inherited;
end;

procedure THashTableIntInt.SortByData(Mode: TCompareMode = cmAscending);
begin
  inherited SortByData(THashTableIntInt.CompareInteger,Mode);
end;

{ THashTableString<TValue> }

{$OverFlowChecks OFF}
function THashTableString<TValue>.GetHash(const Key: String): integer;
var
  a : Integer;
  i : Integer;
begin
  Result:=0;
  a:=63689;
  for i:=0 To Length(Key)-1 do begin
    Result:=Result*a+PWordArray(Key)[i];
    a:=a*378551;
  end;
end;
{$OverFlowChecks On}

function THashTableString<TValue>.GetIDArray: TStringArray;
var
  i,n : integer;
begin
  SetLength(Result,FCount);

  if FIgnoreZeroIndex then begin
    n:=1;
  end else begin
    n:=0;
  end;

  for i:=n to FCount-1 do begin
    Result[i]:=FItems[i].Key;
  end
end;

procedure THashTableString<TValue>.SortById(Mode: TCompareMode);
begin
  inherited SortById(THashTable.CompareString,Mode);
end;

{ THashTableIntString }

procedure THashTableIntString.SortByData(Mode: TCompareMode);
begin
  inherited SortByData(THashTableString.CompareString,Mode);
end;

procedure THashTableIntString.SortById(Mode: TCompareMode);
begin
  inherited SortById(THashTable.CompareInteger,Mode);
end;


{$ENDREGION}

{$REGION 'TListEx Implementation'}

{---------------------------------------------------}
{------------------ TListEx<TValue> -----------------}
{---------------------------------------------------}

function TListEx<T>.Add(const Value: T): Integer;
var
  nCount   : Integer;
  bFound   : Boolean;
  nResult  : Integer;
begin
  if FSorted then begin
     nCount := 0;
     bFound := False;
     // search the list of objects until we find the
     // correct position for the new object we are adding
     while (not bFound) and (nCount < Count) do begin
        if (FComparer.Compare(Items[nCount],Value) >= 0) then
           bFound := True
        else
           inc(nCount);
     end;
     if (bFound) then begin
       Insert(nCount,Value);
       nResult := nCount;
     end else
        nResult := inherited Add(Value);
     Add := nResult;
  end else begin
    Result:=inherited;
  end;
end;

procedure TListEx<T>.Clear;
var
  i   : integer;
begin
  if DoFreeData and (TTypeInfo(TypeInfo(T)^).Kind=tkClass) then begin
    for i:=0 to Count-1 do begin
      FreeElement(i);
    end;
  end;
  inherited;
end;

constructor TListEx<T>.Create;
begin
  inherited;

  DoFreeData:=True;
end;

procedure TListEx<T>.Delete(Index: Integer);
begin
  if DoFreeData and (TTypeInfo(TypeInfo(T)^).Kind=tkClass) then begin
    FreeElement(Index);
  end;

  inherited;
end;

procedure TListEx<T>.DeleteRange(AIndex, ACount: Integer);
var
  i   : integer;
begin
  if DoFreeData and (TTypeInfo(TypeInfo(T)^).Kind=tkClass) then begin
    for i:=AIndex to ACount do begin
      FreeElement(i);
    end;
  end;

  inherited;
end;

destructor TListEx<T>.Destroy;
begin
  Clear;

  inherited;
end;

function TListEx<T>.FindValue(const Value: T; StrictSeach: boolean = True): Integer;
var
   nResult   : Integer;
   nLow      : Integer;
   nHigh     : Integer;
   nCompare  : Integer;
   nCheckPos : Integer;
   i         : Integer;
begin
  if FSorted then begin
    nLow := 0;
    nHigh := Count-1;
    nResult := -1;
    while (nResult = -1) and (nLow <= nHigh) do begin
       nCheckPos := (nLow + nHigh) div 2;
       nCompare := FComparer.Compare(Value,Items[nCheckPos]);
       if (nCompare = -1) then                // less than
          nHigh := nCheckPos - 1
       else if (nCompare = 1) then            // greater than
          nLow := nCheckPos + 1
        else                                  // equal to
          nResult := nCheckPos;
    end;
    if (nResult<0) and not StrictSeach then begin
      nResult:=nLow;
    end;
    Result:=nResult;
  end else begin
    for i:=0 to High do begin
      if FComparer.Compare(Value,Items[nCheckPos])=0 then Exit(i);
    end;
  end;
end;

procedure TListEx<T>.FreeElement(Num: integer);
var
  Obj    : TObject;
  Item   : T;
begin
  try
    Item:=Items[num];
    Obj:=TObject((@Item)^);
    if Assigned(Obj) then begin
      Items[num]:=Default(T);
      Obj.Free;
    end;
  except
  end;
end;

function TListEx<T>.High: integer;
begin
  Result:=Count-1;
end;

function TListEx<T>.Lock(WaitForRelease: boolean): boolean;
begin
  if Self=nil then Exit;

  if FLock=nil then begin
    FLock:=TCriticalSection.Create;
  end;

  FLocked:=True;
  if WaitForRelease then begin
    FLock.Enter;
  end else begin
    FLocked:=FLock.TryEnter;
  end;
  Result:=FLocked;
end;

procedure TListEx<T>.QuickSortA(L, R: Integer; CompareEvt: TCompareValue<T>; Mode: TCompareMode);
var
  I,J,P : Integer;
  Temp  : T;
  Less  : TCompareResult;
  More  : TCompareResult;
begin
  if R<=L then Exit;

  case Mode of
    cmAscending: begin
      Less:=crLess;
      More:=crMore;
    end;
    cmDescending: begin
      Less:=crMore;
      More:=crLess;
    end;
  end;

  try
    repeat
      I:=L;
      J:=R;
      P:=(L+R) shr 1;
      repeat
        while CompareEvt(Items[I], Items[P]) = Less do Inc(I);
        while CompareEvt(Items[J], Items[P]) = More do Dec(J);
        if I<=J then
        begin
          if I<>J then begin
            Temp:=Items[I];
            Items[I]:=Items[J];
            Items[J]:=Temp;
          end;
          if P=I then
            P:=J
          else if P=J then
            P:=I;
          Inc(I);
          Dec(J);
        end;
      until I>J;
      if L<J then QuickSortA(L,J,CompareEvt,Mode);
      L:=I;
    until I>=R;
  except
  end;
end;

procedure TListEx<T>.QuickSortB(L, R: Integer);
var
  I, J: Integer;
  pivot, temp: T;
begin
  if (Count = 0) or ((R - L) <= 0) then
    Exit;
  repeat
    I := L;
    J := R;
    pivot := Items[L + (R - L) shr 1];
    repeat
      while FComparer.Compare(Items[I], pivot) < 0 do
        Inc(I);
      while FComparer.Compare(Items[J], pivot) > 0 do
        Dec(J);
      if I <= J then
      begin
        if I <> J then
        begin
          temp := Items[I];
          Items[I] := Items[J];
          Items[J] := temp;
        end;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSortB(L,J);
    L := I;
  until I >= R;
end;

procedure TListEx<T>.SetSorted(const Value: boolean);
begin
  if Value and not FSorted then begin
    FComparer:=TComparer<T>.Default;
    QuickSortB(0,High);
  end;
  FSorted:=Value;
end;

procedure TListEx<T>.Sort(CompareEvt: TCompareValue<T>; Mode: TCompareMode = cmAscending);
begin
  if not Assigned(CompareEvt) then Exit;

  QuickSortA(0,Count-1,CompareEvt,Mode);
end;

procedure TListEx<T>.UnLock;
begin
  if Self=nil then Exit;

  if FLock=nil then Exit;

  FLock.Release;
  FLocked:=False;
end;

{ THashTableStringInt }

procedure THashTableStringInt.SortByData(Mode: TCompareMode = cmAscending);
begin
  inherited SortByData(THashTableStringInt.CompareInteger,Mode);
end;

function THashTableStringInt.ToString: string;
var
  i  : Integer;
  SB : TStringBuilder;
begin
  SB:=TStringBuilder.Create;
  try
    for i:=0 to Count-1 do begin
      SB.Append(IdByNum[i]+'='+IntToStr(FItems[i].Value));
      SB.AppendLine;
    end;
    Result:=SB.ToString;
  finally
    SB.Free
  end;
end;
{$ENDREGION}

{$REGION 'TListEx Childs Implementation'}

{ TStringListEx }

constructor TStringListEx.Create;
begin
  inherited;

  FDoFreeData:=False;
end;
{$ENDREGION}

{$REGION 'TArrayEx Implementation'}

{ TArrayEx }

procedure TArrayEx<T>.SetCount(const Value: integer);
begin
  SetLengthFast(Value);

  if Length(FIndexArray)>0 then begin
    CreateIndex(Value);
  end;
end;

procedure TArrayEx<T>.SetHigh(const Value: integer);
begin
  SetCount(Value-1);
end;

procedure TArrayEx<T>.SetIndex(Index: Integer; const Value: T);
begin
  if Length(FIndexArray)=0 then Exit;

  if Index>=Length(FIndexArray) then begin
    CreateIndex(Index*2);
  end else begin
    HashAdd(Value,Index);
  end;
end;

//1. Benchmark TArrayEx<Integer>
//Add 10.000.000 integers. 328 msec. 78 msec (Alt Add). 32 msec (optimised).
//Add 10.000 integers in 10.000.000 iterations. 812 msec.
//Locate 10.000 integers in 10.000.000 iterations. 813 msec.

function TArrayEx<T>.Add(Value: T): integer;
begin
  Result:=Length(Items);
  SetLengthFast(Result+1);

  Items[Result]:=Value;
  SetIndex(Result,Value);
end;

function TArrayEx<T>.Add(Values: array of T): integer;
var
  i: Integer;
begin
  Result:=Length(Items);
  SetLengthFast(Result+Length(Values));
  for i:=0 to System.High(Values) do begin
    Items[Result]:=Values[i];
    SetIndex(Result,Values[i]);
  end;
end;

function TArrayEx<T>.AddUnique(Value: T): integer;
begin
  Result:=IndexOf(Value);
  if Result<0 then begin
    Result:=Add(Value);
  end;
end;

procedure TArrayEx<T>.Delete(Index: integer);
var
  i: Integer;
begin
  if (Index<0) or (Index>High) then Exit;

  if DoFreeData and (PTypeInfo(TypeInfo(TValue)).Kind=tkClass) then begin
    FreeElement(Index);
  end;

  for i:=Index+1 to High do begin
    Items[i-1]:=Items[i];
  end;
  SetLengthFast(Length(Items)-1);

  CreateIndex(Length(FIndexArray));
end;

procedure TArrayEx<T>.DeleteRange(Index, Count: integer);
var
  i: Integer;
begin
  if (Count<1) or (Index<0) or (Index+Count>High) then Exit;

  if DoFreeData and (PTypeInfo(TypeInfo(TValue)).Kind=tkClass) then begin
    for i:=Index to Index+Count-1 do begin
      FreeElement(i);
    end;
  end;

  for i:=Index+Count to High do begin
    Items[i-Count]:=Items[i];
  end;
  SetLengthFast(Length(Items)-Count);

  CreateIndex(Length(FIndexArray));
end;

procedure TArrayEx<T>.DropIndex;
begin
  HashClear(0);
end;


function TArrayEx<T>.IndexesOf(Value: T): TArrayEx<integer>;
var
  i,j,m    : integer;
begin
  m:=Length(FIndexArray);

  if m=0 then begin
    CreateIndex;
    m:=Length(FIndexArray);
  end;

  m:=Abs(GetHash(Value) mod m);

  Result.Clear;
  for i:=0 to System.High(FIndexArray[m]) do begin
    if FComparer.Equals(Items[FIndexArray[m,i]],Value) then begin
      Result.Add(FIndexArray[m,i]);
    end;
  end;
  Result.Sort;
end;

function TArrayEx<T>.IndexOf(Value: T): integer;
var
  i,j,m,Hash : integer;
begin
  if Length(FIndexArray)=0 then begin
    CreateIndex;
  end;

  Hash:=GetHash(Value);
  m:=Abs(Hash mod Length(FIndexArray));

  for i:=0 to System.High(FIndexArray[m]) do
    if FComparer.Equals(Items[FIndexArray[m,i]],Value) then begin
      Exit(FIndexArray[m,i]);
    end;

  Result:=-1;
end;


procedure TArrayEx<T>.Insert(Index: integer; Values: array of T);
var
  i: Integer;
begin
  if (Index<0) or (Index>Count) then Exit;

  SetLengthFast(Length(Items)+length(Values));
  for i:=High downto Index+length(Values) do begin
    Items[i]:=Items[i-length(Values)];
  end;

  for i:=Index to System.High(Values) do begin
    Items[Index+i]:=Values[i];
  end;

  CreateIndex(Length(FIndexArray));
end;

function TArrayEx<T>.GetElements(Index: integer): T;
begin
  Result:=Items[Index];
end;

function TArrayEx<T>.GetLow: integer;
begin
  Result:=0;
end;

procedure TArrayEx<T>.HashClear(NewIndexMod: integer);
begin
  System.SetLength(FIndexArray,0);
  SetLength(FIndexArray,NewIndexMod);
end;

function TArrayEx<T>.GetCount: integer;
begin
  Result:=Length(Items);
end;

function TArrayEx<T>.GetHash(const Value: T): integer;
begin
  Result:=TEqualityComparer<T>.Default.GetHashCode(Value);
end;

function TArrayEx<T>.GetHigh: integer;
begin
  Result:=System.High(Items);
end;

procedure TArrayEx<T>.HashAdd(const Value: T; Index: integer);
var
  n,m     : integer;
begin
  try
    m:=Abs(GetHash(Value) mod Length(FIndexArray));
    n:=length(FIndexArray[m]);
  except
  end;

  System.SetLength(FIndexArray[m],n+1);
  FIndexArray[m,n]:=Index;
end;

procedure TArrayEx<T>.FreeElement(Num: integer);
begin
  try
    PObject(@Items[num])^.Free;
    Items[num]:=Default(T);
  except
  end;
end;

procedure TArrayEx<T>.Clear;
var
  i: Integer;
begin
  FInitCapacity:='';
  FCapacity:=0;
  FArrayCount:=nil;

  if DoFreeData and (PTypeInfo(TypeInfo(TValue)).Kind=tkClass) then begin
    for i:=0 to High do begin
      FreeElement(i);
    end;
  end;
  SetLengthFast(0);
  HashClear(Length(FIndexArray));
end;

constructor TArrayEx<T>.Create(DoFreeData: boolean);
begin
  Clear;
  DoFreeData:=DoFreeData;
end;

procedure TArrayEx<T>.CreateIndex(IndexMod: integer = -1);
var
  i : integer;
const
  DefaultIndexSize = 64;
begin
  FComparer:=TEqualityComparer<T>.Default;

  if IndexMod=-1 then begin
    IndexMod:=DefaultIndexSize;
    if Count=0 then begin
      IndexMod:=DefaultIndexSize;
    end else begin
      IndexMod:=Count;
    end;
  end;
  HashClear(IndexMod);

  if IndexMod>0 then begin
    for i:=Low to High do begin
      HashAdd(Items[i],i);
    end;
  end;
end;

procedure TArrayEx<T>.Insert(Index: integer; Value: T);
var
  i: Integer;
begin
  if (Index<0) or (Index>Count) then Exit;

  SetLengthFast(Length(Items)+1);
  for i:=High downto Index+1 do begin
    Items[i]:=Items[i-1];
  end;
  Items[Index]:=Value;

  CreateIndex(Length(FIndexArray));
end;

procedure TArrayEx<T>.SetElements(Index: integer; const Value: T);
begin
  if (Index<0) or (Index>High) then Exit;
  Items[Index]:=Value;
end;

procedure TArrayEx<T>.SetLengthFast(NewValue: integer);
const
  GrowLimit = 64;
begin
  if FInitCapacity='' then begin
    FInitCapacity:='Y';
    FCapacity:=0;
  end;

  if NewValue<=0 then begin
    FCapacity:=0;
    SetLength(Items,0);
  end else begin
    if (NewValue>FCapacity) or (NewValue shl 1<FCapacity) then begin
      FCapacity:=Min(NewValue shl 1,NewValue+GrowLimit);
      SetLength(Items,FCapacity);
      FArrayCount:=PNativeInt(NativeInt(@Items[0])-SizeOf(NativeInt));
    end;
    FArrayCount^:=NewValue;
  end;
end;

procedure TArrayEx<T>.QuickSortA(const Comparer: IComparer<T>; L, R: Integer);
var
  I, J: Integer;
  pivot, temp: T;
begin
  if (Length(Items) = 0) or ((R - L) <= 0) then
    Exit;
  repeat
    I := L;
    J := R;
    pivot := Items[L + (R - L) shr 1];
    repeat
      while Comparer.Compare(Items[I], pivot) < 0 do
        Inc(I);
      while Comparer.Compare(Items[J], pivot) > 0 do
        Dec(J);
      if I <= J then
      begin
        if I <> J then
        begin
          temp := Items[I];
          Items[I] := Items[J];
          Items[J] := temp;
        end;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSortA(Comparer, L, J);
    L := I;
  until I >= R;
end;

procedure TArrayEx<T>.Sort(Comparer: IComparer<T> = nil);
var
  OIndexMod: integer;
begin
  OIndexMod:=Length(FIndexArray);
  if OIndexMod>0 then DropIndex;

  if Comparer=nil then Comparer:=TComparer<T>.Default;
  QuickSortA(Comparer, 0, High);

  if OIndexMod>0 then CreateIndex(OIndexMod);
end;

procedure TArrayEx<T>.QuickSortB(L, R: Integer; CompareEvt: TCompareValue<T>; Less, More: TCompareResult);
var
  I, J: Integer;
  pivot, temp: T;
begin
  if (Length(Items) = 0) or ((R - L) <= 0) then
    Exit;
  repeat
    I := L;
    J := R;
    pivot := Items[L + (R - L) shr 1];
    repeat
      while CompareEvt(Items[I], pivot) = crLess do
        Inc(I);
      while CompareEvt(Items[J], pivot) = crMore do
        Dec(J);
      if I <= J then
      begin
        if I <> J then
        begin
          temp := Items[I];
          Items[I] := Items[J];
          Items[J] := temp;
        end;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSortB(L, J, CompareEvt, Less, More);
    L := I;
  until I >= R;
end;

procedure TArrayEx<T>.Sort(CompareEvt: TCompareValue<T>; Mode: TCompareMode = cmAscending);
var
  OIndexMod: integer;
  Less,More: TCompareResult;
begin
  OIndexMod:=Length(FIndexArray);
  if OIndexMod>0 then DropIndex;

  if not Assigned(CompareEvt) then Exit;

  case Mode of
    cmAscending: begin
      Less:=crLess;
      More:=crMore;
    end;
    cmDescending: begin
      Less:=crMore;
      More:=crLess;
    end;
  end;

  QuickSortB(Low,High,CompareEvt,Less,More);

  if OIndexMod>0 then CreateIndex(OIndexMod);
end;

function TArrayEx<T>.ToString(Delimeter: string): string;
var
  i : Integer;
  n : integer;
  s : string;
begin
  Result:='';
  for i:=Low to High do begin
    if (Result<>'') then begin
      s:=Delimeter+TValue.From<T>(Items[i]).ToString;
    end else begin
      s:=TValue.From<T>(Items[i]).ToString;
    end;

    n:=Length(Result);
    SetLength(Result,n+length(s));
    Move(s[1],Result[n+1],Length(s)*SizeOf(Char));
  end;
end;

function TArrayEx<T>.ToString: string;
begin
  Result:=ToString(';');
end;

function TArrayEx<T>.Exists(Value: T): boolean;
begin
  Result:=IndexOf(Value)>=0;
end;

function TArrayEx<T>.Exists(Values: array of T; NeedAllValues: boolean = False): boolean;
var
  i: Integer;
begin
  Result:=NeedAllValues;

  for i:=0 to System.High(Values) do begin
    if NeedAllValues then begin
      if IndexOf(Values[i])<0 then Exit(False);
    end else begin
      if IndexOf(Values[i])>=0 then Exit(True);
    end;
  end;
end;

{$IFDEF ArrayExEnumerator}

function TArrayEx<T>.Collection: TCollection;

begin

  if FEnumInit<>'Y' then begin

    FCollection:=TCollection.Create(Self);
    FEnumInit:='Y';
  end;
  Result:=FCollection;
end;


{ TArrayEx<T>.TValueEnumerator }

constructor TArrayEx<T>.TEnumerator.Create(Parent: TCollection);
begin
  inherited Create;
  FIndex:=-1;
  FParent:=Parent;
end;


function TArrayEx<T>.TEnumerator.DoGetCurrent: T;
type
  TArrParent = TArrayEx<T>;
  PArrParent = ^TArrParent;
var
  n : integer;
begin
  n:=System.Length(PArrParent(FParent.FParent)^.Items);
  if n<=FIndex then begin
    raise Exception.Create('Error Message');
  end;

  Result:=PArrParent(FParent.FParent)^.Items[FIndex];
end;

function TArrayEx<T>.TEnumerator.DoMoveNext: Boolean;
type
  TArrParent = TArrayEx<T>;
  PArrParent = ^TArrParent;
var
  i : integer;
begin
  if FIndex<System.High(PArrParent(FParent.FParent)^.Items) then begin
    inc(FIndex);
    Result:=True;
  end else begin
    Result:=False;
  end;
end;

function TArrayEx<T>.TEnumerator.GetCurrent: T;
begin
  Result:=DoGetCurrent;
end;

function TArrayEx<T>.TEnumerator.MoveNext: Boolean;
begin
  Result:=DoMoveNext;
end;

{ TArrayEx<T>.TCollection }

constructor TArrayEx<T>.TCollection.Create(const ArrayEx: TArrayEx<T>);
begin
  inherited Create;
  FParent:=@ArrayEx;
end;

function TArrayEx<T>.TCollection.DoGetEnumerator: TEnumerator<T>;
begin
  Result:=GetEnumerator;
end;

function TArrayEx<T>.TCollection.GetCount: Integer;
type
  TArrParent = TArrayEx<T>;
  PArrParent = ^TArrParent;
begin
  Result:=System.Length(PArrParent(FParent)^.Items);
end;

function TArrayEx<T>.TCollection.GetEnumerator: TEnumerator<T>;
begin
  Result:=TEnumerator.Create(Self);
end;
{$ENDIF}

class operator TArrayEx<T>.Add(const A, B: TArrayEx<T>): TArrayEx<T>;
begin
  Result.Clear;

  SetLength(Result.Items,A.Count+B.Count);
  if A.Count>0 then begin
    Move(A.Items[0],Result.Items[0],A.Count*SizeOf(T));
  end;
  if B.Count>0 then begin
    Move(B.Items[0],Result.Items[A.Count],B.Count*SizeOf(T));
  end;
  if length(A.FIndexArray)>0 then begin
    Result.CreateIndex;
  end;
end;


class operator TArrayEx<T>.Add(const A: TArrayEx<T>; const B: array of T): TArrayEx<T>;
begin
  Result.Clear;

  SetLength(Result.Items,A.Count+length(B));
  if A.Count>0 then begin
    Move(A.Items[0],Result.Items[0],A.Count*SizeOf(T));
  end;
  if Length(B)>0 then begin
    Move(B[0],Result.Items[A.Count],length(B)*SizeOf(T));
  end;
  if length(A.FIndexArray)>0 then begin
    Result.CreateIndex;
  end;
end;

class operator TArrayEx<T>.Add(const A: array of T; const B: TArrayEx<T>): TArrayEx<T>;
begin
  Result.Clear;

  SetLength(Result.Items,length(A)+B.Count);
  Move(A[0],Result.Items[0],length(A)*SizeOf(T));
  Move(B.Items[0],Result.Items[length(A)],B.Count*SizeOf(T));
  if length(B.FIndexArray)>0 then begin
    Result.CreateIndex;
  end;
end;

class operator TArrayEx<T>.Implicit(const A: TArrayEx<T>): TArray<T>;
begin
  SetLength(Result,A.Count);
  if A.Count>0 then begin
    Move(A.Items[0],Result[0],A.Count*SizeOf(T));
  end;
end;

class operator TArrayEx<T>.Implicit(A: TArray<T>): TArrayEx<T>;
begin
  Result.Clear;
  SetLength(Result.Items,Length(A));
  if Length(A)>0 then begin
    Move(A[0],Result.Items[0],Length(A)*SizeOf(T));
  end;
end;


{$IF CompilerVersion>27}
class operator TArrayEx<T>.In(const A, B: TArrayEx<T>): Boolean;
begin
  Result:=B.Exists(A.Items,True);
end;

class operator TArrayEx<T>.In(const A: array of T; B: TArrayEx<T>): Boolean;
begin
  Result:=B.Exists(A,True);
end;
{$ENDIF}

class operator TArrayEx<T>.Equal(const A, B: TArrayEx<T>): Boolean;
var
  i        : integer;
  Comparer : IEqualityComparer<T>;
begin
  if length(A.Items)<>length(B.Items) then Exit(False);
  Comparer:=TEqualityComparer<T>.Default;

  for i:=0 to System.High(A.Items) do begin
    if Comparer.Equals(A.Items[i],B.Items[i]) then Exit(False);
  end;
  Result:=True;
end;

class operator TArrayEx<T>.NotEqual(const A, B: TArrayEx<T>): Boolean;
begin
  Result:=not (A=B);
end;
{$ENDREGION}

{$REGION 'TDateRanges Implementation'}

{ TDateRanges<TValue> }

procedure TDateRanges<T>.SetValue(DateN, DateK: TDateTime; Value: T);
var
  i,n  : Integer;
  Item : TDateRange;
  C    : IEqualityComparer<T>;
begin
  C:=TEqualityComparer<T>.Default;

  // delete
  for i:=Ranges.High downto 0 do begin
    if (Ranges[i].DateN>=DateN) and (Ranges[i].DateK<DateK) then Ranges.Delete(i);
  end;

  // cut
  n:=0;
  for i:=0 to Ranges.High do begin
    if (Ranges[i].DateN<=DateK) and (Ranges[i].DateK>=DateN) then begin
      if Ranges.Items[i].DateN<DateN then begin
        if Ranges.Items[i].DateK>DateN then begin
          Ranges.Items[i].DateK:=DateN;
        end;
      end;
      if Ranges.Items[i].DateK>DateK then begin
        if Ranges.Items[i].DateN<DateK then begin
          Ranges.Items[i].DateN:=DateK;
        end;
      end;
    end;
    if DateN>Ranges[i].DateN then begin
      n:=i+1;
    end;
  end;
  // Add
  Item.DateN:=DateN;
  Item.DateK:=DateK;
  Item.Value:=Value;
  if n<=Ranges.High then begin
    Ranges.Insert(n,Item);
  end else begin
    Ranges.Add(Item);
  end;

  // merge
  for i:=Ranges.High downto 1 do begin
    if (Ranges[i-1].DateK=Ranges[i].DateN) and C.Equals(Ranges[i-1].Value,Ranges[i].Value) then begin
      Ranges.Items[i-1].DateK:=Ranges[i].DateK;
      Ranges.Delete(i);
    end;
  end;
end;

procedure TDateRanges<T>.Clear;
begin
  Ranges.Clear;
end;

function TDateRanges<T>.Count: integer;
begin
  Result:=Ranges.Count;
end;

constructor TDateRanges<T>.Create;
begin
  Ranges.Clear;
end;

procedure TDateRanges<T>.Delete(DateN, DateK: TDateTime);
var
  i    : Integer;
  Item : TDateRange;
begin
  // delete
  for i:=Ranges.High downto 0 do begin
    if (Ranges[i].DateN>=DateN) and (Ranges[i].DateK<DateK) then Ranges.Delete(i);
  end;

  // cut
  for i:=0 to Ranges.High do begin
    if (Ranges[i].DateN<=DateK) and (Ranges[i].DateK>=DateN) then begin
      if Ranges.Items[i].DateN<DateN then begin
        if Ranges.Items[i].DateK>DateN then begin
          Ranges.Items[i].DateK:=DateN;
        end;
      end;
      if Ranges.Items[i].DateK>DateK then begin
        if Ranges.Items[i].DateN<DateK then begin
          Ranges.Items[i].DateN:=DateK;
        end;
      end;
    end;
  end;
end;

function TDateRanges<T>.GetRanges(Value: T): TArrayEx<TDateRange>;
var
  i : Integer;
  C : IEqualityComparer<T>;
begin
  C:=TEqualityComparer<T>.Default;

  Result.Clear;
  for i:=0 to Ranges.High do begin
    if C.Equals(Ranges[i].Value,Value) then begin
      Result.Add(Ranges[i]);
    end;
  end;
end;

function TDateRanges<T>.GetRanges(DateN, DateK: TDateTime): TArrayEx<TDateRange>;
var
  i : Integer;
  R : TDateRange;
begin
  Result.Clear;
  for i:=0 to Ranges.High do begin
    if (Ranges[i].DateN<=DateK) and (Ranges[i].DateK>=DateN) then begin
      R:=Ranges[i];
      if R.DateN<DateN then R.DateN:=DateN;
      if R.DateK>DateK then R.DateK:=DateK;
      Result.Add(R);
    end;
  end;
end;

function TDateRanges<T>.GetRanges(DateN, DateK: TDateTime; Value: T): TArrayEx<TDateRange>;
var
  i : Integer;
  C : IEqualityComparer<T>;
  R : TDateRange;
begin
  C:=TEqualityComparer<T>.Default;

  Result.Clear;
  for i:=0 to Ranges.High do begin
    if C.Equals(Ranges[i].Value,Value) and (Ranges[i].DateN<=DateK) and (Ranges[i].DateK>=DateN) then begin
      R:=Ranges[i];
      if R.DateN>DateN then R.DateN:=DateN;
      if R.DateK<DateK then R.DateK:=DateK;
      Result.Add(R);
    end;
  end;
end;

function TDateRanges<T>.GetValue(Date: TDateTime): T;
var
  i: Integer;
begin
  Result:=Default(T);
  for i:=0 to Ranges.High do begin
    if (Date>=Ranges.Items[i].DateN) and (Date<Ranges.Items[i].DateK) then begin
      Exit(Ranges.Items[i].Value);
    end;
  end;
end;

function TDateRanges<T>.GetVoidSpaces(DateN, DateK: TDateTime): TArrayEx<TDateRange>;
var
  i   : Integer;
  R   : TDateRange;
  Res : TArrayEx<TDateRange>;
  TM  : TDateTime;
  DN,DK : TDateTime;
begin
  Res:=GetRanges(DateN, DateK);

  Result.Clear;
  TM:=DateN;
  for i:=0 to Res.High do begin
    DN:=Res[i].DateN;
    DK:=Res[i].DateK;

    if i=0 then begin
      if Res[i].DateN=DateN then begin
        TM:=Res[i].DateK;
      end;
      if Res[i].DateN>DateN then begin
        R.DateN:=TM;
        R.DateK:=Res[i].DateN;
        R.Value:=Default(T);
        Result.Add(R);
        TM:=Res[i].DateK;
      end;
    end;

    if i>0 then begin
      if Res[i].DateN>TM then begin
        R.DateN:=TM;
        R.DateK:=Res[i].DateN;
        R.Value:=Default(T);
        Result.Add(R);
      end;
      TM:=Res[i].DateK;
    end;

    if i=Res.High then begin
      if Res[i].DateK<DateK then begin
        R.DateK:=Res[i].DateN;
        R.Value:=Default(T);
        Result.Add(R);
      end;

      if Res[i].DateK<DateK then begin
        R.DateN:=Res[i].DateN;
        R.DateK:=DateK;
        R.Value:=Default(T);
        Result.Add(R);
      end;
    end;
  end;
end;

{$ENDREGION}

end.


