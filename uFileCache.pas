unit uFileCache;

interface

uses
  // user moduls
  uCache, uTestableObject,
  //
  System.Generics.Collections, DBXJSONReflect, System.JSON, RTTI;

type
  TFileCache<TKey, T> = class(TObject)
  private
    FObjectDictionary: TObjectDictionary<TKey, string>;

    FMarshal: TJSONMarshal; // Сериализатор
    FUnMarshal: TJSONUnMarshal; // Десериализатор
    procedure DeleteAllFiles;
  public
    function AddObject(const AKey: TKey; const AValueObject: T;
      out AErrorStr: string): Boolean;
    function DeleteObject(const AKey: TKey; out AErrorStr: string): Boolean;
    function ExtractObject(const AKey: TKey; out AValueObject: T;
      out AErrorStr: string): Boolean;
    function Count: Integer;

    procedure Clear;

    constructor Create; reintroduce;
    procedure BeforeDestruction; override;
  end;

const
  constDefaultDir = '..\temp\';
  constDefaultFileExtension = '.json';

implementation

uses System.Classes, System.IOUtils, uObjectContainer, System.SysUtils,
  uExUtils;

function TFileCache<TKey, T>.AddObject(const AKey: TKey; const AValueObject: T;
  out AErrorStr: string): Boolean;
var
  lRTTIValue: TValue;
  lFullFileName: string;
  lSerializedObject: TJSONObject;
  lStringObject: TStringStream;
begin
  Result := False;
  lSerializedObject := nil;
  lStringObject := nil;

  if not ForceDirectories(constDefaultDir) then
  begin
    AErrorStr := self.ClassName + '.AddObject ' +
      'Невозможно создать директорию';
    Exit;
  end;

  lFullFileName := constDefaultDir + TValue.From<TKey>(AKey).AsString +
    constDefaultFileExtension;

  if TFile.Exists(lFullFileName) then
  begin
    AErrorStr := self.ClassName + '.AddObject ' + 'Объект уже добавлен';
    Exit;
  end;

  try
    try
      lRTTIValue := TValue.From<T>(AValueObject);

      if not lRTTIValue.IsObject then
      begin
        AErrorStr := self.ClassName + '.AddObject ' + 'Неизвестный тип';
        Exit;
      end;

      lSerializedObject := FMarshal.Marshal(lRTTIValue.AsType<TObject>)
        as TJSONObject;

      lStringObject := TStringStream.Create(lSerializedObject.ToString);

      lStringObject.SaveToFile(lFullFileName);

      FObjectDictionary.Add(AKey, lFullFileName);

      Result := True;
    except
      on E: Exception do
      begin
        AErrorStr := self.ClassName + '.GetObject ' + E.Message;
      end;
    end;

  finally
    FreeAndNilEx(lStringObject);
    FreeAndNilEx(lSerializedObject);
  end;
end;

procedure TFileCache<TKey, T>.BeforeDestruction;
begin
  FreeAndNilEx(FObjectDictionary);
  DeleteAllFiles;
  inherited;
end;

procedure TFileCache<TKey, T>.Clear;
begin
  FObjectDictionary.Clear;
  DeleteAllFiles;
end;

function TFileCache<TKey, T>.Count: Integer;
begin
  Result := FObjectDictionary.Count;
end;

constructor TFileCache<TKey, T>.Create;
begin
  inherited Create;

  FMarshal := TJSONMarshal.Create(TJSONConverter.Create);
  FUnMarshal := TJSONUnMarshal.Create;

  FObjectDictionary := TObjectDictionary<TKey, string>.Create;

  // Очищаем старые файлы, чтобы не мешали работе буфера
  DeleteAllFiles;
end;

procedure TFileCache<TKey, T>.DeleteAllFiles;
begin
  if TDirectory.Exists(constDefaultDir) then
    TDirectory.Delete(constDefaultDir, True);
end;

function TFileCache<TKey, T>.DeleteObject(const AKey: TKey;
  out AErrorStr: string): Boolean;
var
  lFileName: string;
begin
  Result := False;

  if not FObjectDictionary.TryGetValue(AKey, lFileName) then
  begin
    AErrorStr := self.ClassName + '.DeleteObject ' + 'Объект не существует';
    Exit;
  end;

  if not TFile.Exists(lFileName) then
  begin
    FObjectDictionary.Remove(AKey);
    AErrorStr := self.ClassName + '.DeleteObject ' +
      'Не найден Объект на диске';
  end;

  if not DeleteFile(lFileName) then
  begin
    FObjectDictionary.Remove(AKey);
    AErrorStr := self.ClassName + '.DeleteObject ' +
      'Невозможно удалить объект';
    Exit;
  end;

  FObjectDictionary.Remove(AKey);
  Result := True;
end;

function TFileCache<TKey, T>.ExtractObject(const AKey: TKey; out AValueObject: T;
  out AErrorStr: string): Boolean;
var
  lFileName: string;
  lStringObject: TStringStream;
  lUnSerializedObject: TJSONObject;
  lContainer: TObject;
  lRTTIValue: TValue;

  lPair: TPair<TKey, string>;
begin
  Result := False;

  if not FObjectDictionary.ContainsKey(AKey) then
  begin
    AErrorStr := self.ClassName + '.GetObject ' + 'Объект не существует';
    Exit;
  end;

  try
    try
      lPair := FObjectDictionary.ExtractPair(AKey);

      lFileName := lPair.Value;

      lStringObject := TStringStream.Create;

      lStringObject.LoadFromFile(lFileName);

      lUnSerializedObject := TJSONObject.ParseJSONValue
        (lStringObject.DataString) as TJSONObject;

      lContainer := FUnMarshal.Unmarshal(lUnSerializedObject) as TObject;

      lRTTIValue := TValue.From<TObject>(lContainer);

      AValueObject := lRTTIValue.AsType<T>;

      if not DeleteFile(lFileName) then
      begin
        AErrorStr := self.ClassName + '.DeleteObject ' +
          'Невозможно удалить объект';
        Exit;
      end;

      Result := True;
    except
      on E: Exception do
      begin
        AErrorStr := self.ClassName + '.GetObject ' + E.Message;
      end;
    end;

  finally
    FreeAndNil(lStringObject);
    FreeAndNil(lUnSerializedObject);
  end;
end;

end.
