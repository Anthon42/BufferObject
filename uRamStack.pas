unit uRamStack;

interface

uses System.Generics.Collections;

type
  TRamStuck<TKey, T: class> = class(TObject)
  private
    FRamACapacity: Integer;
    FRamDictionary: TDictionary<TKey, Integer>;
    FRamObjectList: TObjectList<T>;

    FFileDictionary: TDictionary<TKey, Integer>;
    FFileObjectList: TObjectList<T>;
  public
    function Add(const AKey: TKey; const AValueObject: T;
      out AErrorStr: string): Boolean;
    function GetObject(const AKey: TKey): T;
    function GetLastObject: T;

    constructor Create(const ARamCapacity: Integer); reintroduce;
  end;

implementation

uses System.SysUtils;

function TRamStuck<TKey, T>.Add(const AKey: TKey; const AValueObject: T;
  out AErrorStr: string): Boolean;
begin
  Result := False;
  try
    if FRamDictionary.Count >= FRamACapacity then
    begin
      AErrorStr := self.ClassName + '.Add ' + ' Буфер переполнен';
      Exit;
    end;

    FRamObjectList.Add(AValueObject);

    FRamDictionary.Add(AKey, FRamObjectList.Count - 1);
  except
    on E: Exception do
      AErrorStr := E.ClassName + '.DeleteObject ' + E.Message;
  end;

end;

constructor TRamStuck<TKey, T>.Create(const ARamCapacity: Integer);
begin
  FRamACapacity := ARamCapacity;
  FRamDictionary := TDictionary<TKey, Integer>.Create(FRamACapacity);
  FRamObjectList := TObjectList<T>.Create(True);
end;

function TRamStuck<TKey, T>.GetLastObject: T;
begin

end;

function TRamStuck<TKey, T>.GetObject(const AKey: TKey): T;
var
  lItemIndex: Integer;
begin
  Result := nil;

{  if FRamDictionary.TryGetValue(AKey, Result) then
  begin
  FRamDictionary.
  end;  }
end;

end.
