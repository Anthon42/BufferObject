unit uFileCache;

interface

uses
  // user moduls
  uCache, uTestableObject,
  //
  System.Generics.Collections, System.SysUtils, DBXJSONReflect, System.JSON, RTTI;

type

  TFileCache = class(TObject)
  strict private
    FObjectDictionary: TObjectDictionary<string, string>;

    FMarshal: TJSONMarshal; // Сериализатор
    FUnMarshal: TJSONUnMarshal; // Десериализатор
    procedure DeleteAllFiles;
  public
    function AddObject(const AKey: string; const AValueObject: TValue; out AErrorStr: string): Boolean;
    function DeleteObject(const AKey: string; out AErrorStr: string): Boolean;
    function GetObject(const AKey: string; out AValueObject: TValue; out AErrorStr: string): Boolean;
    procedure Clear;

    constructor Create; reintroduce;
    procedure BeforeDestruction; override;
  end;

const
  constDefaultDir = '..\temp\';
  constDefaultFileExtension = '.json';

implementation

uses System.Classes, System.IOUtils, uObjectContainer;

function TFileCache.AddObject(const AKey: string; const AValueObject: TValue; out AErrorStr: string): Boolean;
var
  lSerializedObject: TJSONObject;
  lContainer: TObjectContainer;
  lStringObject: TStringStream;
  lFullFileName: string;
begin
  lStringObject := nil;
  lSerializedObject := nil;
  lContainer := nil;
  lStringObject := nil;

  Result := False;

  if not AValueObject.IsObject then
  begin
    AErrorStr := self.ClassName + '.AddObject ' + 'Неизвестный тип';
    Exit;
  end;

  if not ForceDirectories(constDefaultDir) then
  begin
    AErrorStr := self.ClassName + '.AddObject ' + 'Невозможно создать директорию';
    Exit;
  end;

  lFullFileName := constDefaultDir + AKey + constDefaultFileExtension;

  if TFile.Exists(lFullFileName) then
  begin
    AErrorStr := self.ClassName + '.AddObject ' + 'Объект уже добавлен';
    Exit;
  end;

  try
    try
      lContainer := AValueObject.AsType<TObjectContainer>;

      lSerializedObject := FMarshal.Marshal(lContainer) as TJSONObject;

      lStringObject := TStringStream.Create(lSerializedObject.ToString);

      lStringObject.SaveToFile(lFullFileName);

      FObjectDictionary.Add(AKey, lFullFileName);

      Result := True;

      FreeAndNil(lContainer);
    except
      on E: Exception do
      begin
        AErrorStr := self.ClassName + '.AddObject ' + E.Message;
      end;
    end;
  finally
    FreeAndNil(lStringObject);
    FreeAndNil(lSerializedObject);
    FreeAndNil(lStringObject);
  end;
end;

procedure TFileCache.BeforeDestruction;
begin
  FreeAndNil(FObjectDictionary);
  inherited;
end;

procedure TFileCache.Clear;
begin
  FObjectDictionary.Clear;
  DeleteAllFiles;
end;

constructor TFileCache.Create;
begin
  inherited Create;

  FMarshal := TJSONMarshal.Create(TJSONConverter.Create);
  FUnMarshal := TJSONUnMarshal.Create;

  FObjectDictionary := TObjectDictionary<string, string>.Create;
end;

procedure TFileCache.DeleteAllFiles;
begin
  // Очищаем старые файлы, чтобы не мешали работе буфера
  if TDirectory.Exists(constDefaultDir) then
    TDirectory.Delete(constDefaultDir, True);
end;

function TFileCache.DeleteObject(const AKey: string; out AErrorStr: string): Boolean;
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
    AErrorStr := self.ClassName + '.DeleteObject ' + 'Не найден Объект на диске';
  end;

  if not DeleteFile(lFileName) then
  begin
    FObjectDictionary.Remove(AKey);
    AErrorStr := self.ClassName + '.DeleteObject ' + 'Невозможно удалить объект на диске';
    Exit;
  end;

  FObjectDictionary.Remove(AKey);
  Result := True;
end;

function TFileCache.GetObject(const AKey: string; out AValueObject: TValue; out AErrorStr: string): Boolean;
var
  lFileName: string;
  lContainer: TObjectContainer;
  lStringObject: TStringStream;
  lUnSerializedObject: TJSONObject;
begin
  Result := False;
  lStringObject := nil;
  lUnSerializedObject := nil;

  if not FObjectDictionary.TryGetValue(AKey, lFileName) then
  begin
    AErrorStr := self.ClassName + '.GetObject ' + 'Объект не существует';
    Exit;
  end;

  try
    try
      lStringObject := TStringStream.Create;

      lStringObject.LoadFromFile(lFileName);

      lUnSerializedObject := TJSONObject.ParseJSONValue(lStringObject.DataString) as TJSONObject;

      lContainer := FUnMarshal.Unmarshal(lUnSerializedObject) as TObjectContainer;

      AValueObject := TValue.From<TObjectContainer>(lContainer);
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
