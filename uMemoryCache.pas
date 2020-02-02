unit uMemoryCache;

interface

uses
  uCache, uTestableObject, uObjectContainer, uExUtils, Indexes,
  //
  System.Generics.Collections, System.SysUtils;

type
  TMemoryCache<TKey; T: class> = class(TObject)
  private
    FHashTable: THashTable<TKey, T>;
  public
    function AddObject(const AKey: TKey; const AValueObject: T;
      out AErrorStr: string): Boolean;
    function DeleteObject(const AKey: TKey; out AErrorStr: string): Boolean;
    function ExtractObject(const AKey: TKey; out AValueObject: T;
      out AErrorStr: string): Boolean;
    function Count: Integer;
    function GetLastValue(out AKey: TKey; out AValueObject: T;
      out AErrorStr: string): Boolean;
    procedure Clear;

    constructor Create(const ASizeCache: Integer); reintroduce;
    procedure BeforeDestruction; override;
  end;

implementation

function TMemoryCache<TKey, T>.AddObject(const AKey: TKey;
  const AValueObject: T; out AErrorStr: string): Boolean;
var
  lIndex: Integer;
begin
  Result := False;

  try
    FHashTable.AddUnique(AKey, AValueObject);
    Result := True;
  except
    on E: Exception do
      AErrorStr := E.ClassName + '.AddObject ' + E.Message;
  end;
end;

procedure TMemoryCache<TKey, T>.BeforeDestruction;
begin
  FreeAndNilEx(FHashTable);
  inherited;
end;

procedure TMemoryCache<TKey, T>.Clear;
begin
  FHashTable.Clear(True);
end;

function TMemoryCache<TKey, T>.Count: Integer;
begin
  Result := FHashTable.Count;
end;

constructor TMemoryCache<TKey, T>.Create(const ASizeCache: Integer);
begin
  FHashTable := THashTable<TKey, T>.Create(ASizeCache, False);
end;

function TMemoryCache<TKey, T>.DeleteObject(const AKey: TKey;
  out AErrorStr: string): Boolean;
begin
  try
    FHashTable.DeleteByID(AKey);
  except
    on E: Exception do
      AErrorStr := E.ClassName + '.DeleteObject ' + E.Message;
  end;
end;

function TMemoryCache<TKey, T>.GetLastValue(out AKey: TKey; out AValueObject: T;
  out AErrorStr: string): Boolean;
begin
  Result := False;
  AValueObject := nil;

  try
    AValueObject := FHashTable.DataByNum[0];

    AKey := FHashTable.IdByNum[0];
    Result := True;

    FHashTable.Delete(0);
  except
    on E: Exception do
      AErrorStr := E.ClassName + '.GetLastValue ' + E.Message;
  end;
end;

function TMemoryCache<TKey, T>.ExtractObject(const AKey: TKey;
  out AValueObject: T; out AErrorStr: string): Boolean;
begin
  Result := False;
  AValueObject := nil;

  try
    AValueObject := FHashTable.DataByID[AKey];
    if not Assigned(AValueObject) then
    begin
      AErrorStr := self.ClassName + '.ExtractObject ' + 'Объект не существует';
      Exit;
    end;
    FHashTable.DeleteByID(AKey);
    Result := True;
  except
    on E: Exception do
      AErrorStr := E.ClassName + '.ExtractObject ' + E.Message;
  end;

end;

end.
