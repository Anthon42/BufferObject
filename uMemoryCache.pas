unit uMemoryCache;

interface

uses
  uCache, uTestableObject,
  //
  System.Generics.Collections, System.SysUtils;

type
  TMemoryCache = class(TInterfacedObject, TCache)
  strict private
    FObjectDictionary: TObjectDictionary<string, IBaseObject>;
  public
    function AddObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
    function DeleteObject(const AKey: string; out AErrorStr: string): Boolean;
    function ReplaceObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
    function GetObject(const AKey: string; out AObject: IBaseObject; out AErrorStr: string): Boolean;
    procedure Clear;

    constructor Create;
    procedure BeforeDestruction; override;
  end;

implementation

function TMemoryCache.AddObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
begin
  Result := False;
  try
    FObjectDictionary.Add(AKey, AObject);
    Result := True;
  except
    on E: Exception do
      AErrorStr := E.ClassName + '.AddObject ' + E.Message;
  end;
end;

procedure TMemoryCache.BeforeDestruction;
begin
  FreeAndNil(FObjectDictionary);
  inherited;
end;

procedure TMemoryCache.Clear;
begin
  FObjectDictionary.Clear;
end;

constructor TMemoryCache.Create;
begin
  inherited;

  FObjectDictionary := TObjectDictionary<string, IBaseObject>.Create;
end;

function TMemoryCache.DeleteObject(const AKey: string; out AErrorStr: string): Boolean;
begin
  Result := False;

  try
    FObjectDictionary.Remove(AKey);
    Result := True;
  except
    on E: Exception do
      AErrorStr := E.ClassName + '.DeleteObject ' + E.Message;
  end;
end;

function TMemoryCache.GetObject(const AKey: string; out AObject: IBaseObject; out AErrorStr: string): Boolean;
begin
  Result := False;

  try
    if FObjectDictionary.TryGetValue(AKey, AObject) then
    begin
      Result := True;
    end
    else
      AErrorStr := 'Элемент не найден';
  except
    on E: Exception do
      AErrorStr := E.ClassName + '.GetObject ' + E.Message;
  end;
end;

function TMemoryCache.ReplaceObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
begin
  Result := False;

  try
    if FObjectDictionary.ContainsKey(AKey) then
    begin
      FObjectDictionary.Remove(AKey);

      FObjectDictionary.Add(AKey, AObject);

      Result := True;
    end
    else
      AErrorStr := 'Объект не найден';
  except
    on E: Exception do
      AErrorStr := E.ClassName + '.ReplaceObject ' + E.Message;
  end;
end;

end.
