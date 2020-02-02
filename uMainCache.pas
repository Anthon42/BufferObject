unit uMainCache;

interface

uses uCache, uMemoryCache, uFileCache;

type
  TLogMethod = procedure(const lMessage: string);

  TMainCache<TKey; T: class> = class(TObject)
  private
    FMemoryCacheCapacity: Integer;
    FFileCacheCapacity: Integer;

    FFileCache: TFileCache<TKey, T>;
    FMemoryCache: TMemoryCache<TKey, T>;

    FLogMethod: TLogMethod;
    procedure Log(const lMessage: string);

    procedure FindObject(const AKey: TKey; out AValueObject: T);
  public
    property OnLogingMethod: TLogMethod read FLogMethod write FLogMethod;
    procedure AddObject(const AKey: TKey; const AValueObject: T);
    procedure ExtractObject(const AKey: TKey; out AValueObject: T);

    constructor Create(const AMemoryCacheCapacity, AFileCacheCapacity: Integer);
      reintroduce;
  end;

implementation

uses uObjectContainer;

procedure TMainCache<TKey, T>.AddObject(const AKey: TKey;
  const AValueObject: T);
var
  lLastObject: T;
  lKey: TKey;
  lErrorStr: string;
begin
  try
    if FMemoryCache.Count < FMemoryCacheCapacity then
    begin
      // Записываем объект в оперативную память
      if not FMemoryCache.AddObject(AKey, AValueObject, lErrorStr) then
      begin
        Log(lErrorStr);
        Exit;
      end;
      Log('Новый объект был записан в оперативную память');
    end
    else
    begin
      // Проверяем место в файловом кеше
      if FFileCache.Count = FFileCacheCapacity then
      begin
        Log(self.ClassName + '.AddObject ' + ' Кеш переполнен');
        Exit;
      end;
      // Перемещаем самый старый обьект из оперативной памяти в файловый кеш
      if not FMemoryCache.GetLastValue(lKey, lLastObject, lErrorStr) then
      begin
        Log(lErrorStr);
        Exit;
      end;

      if not FFileCache.AddObject(lKey, lLastObject, lErrorStr) then
      begin
        Log(lErrorStr);
        Exit;
      end
      else
        Log('Старый объект был перемещен в файловую память');

      // Записываем объект в оперативную память
      if not FMemoryCache.AddObject(AKey, AValueObject, lErrorStr) then
      begin
        Log(lErrorStr);
        Exit;
      end;
      Log('Новый объект был записан в оперативную память');
    end;
  except

  end;
end;

constructor TMainCache<TKey, T>.Create(const AMemoryCacheCapacity,
  AFileCacheCapacity: Integer);
begin
  FMemoryCacheCapacity := AMemoryCacheCapacity;

  FFileCacheCapacity := AFileCacheCapacity;

  FFileCache := TFileCache<TKey, T>.Create;

  FMemoryCache := TMemoryCache<TKey, T>.Create(AMemoryCacheCapacity);
end;

procedure TMainCache<TKey, T>.FindObject(const AKey: TKey; out AValueObject: T);
var
  lErrorStr: string;
begin
  AValueObject := nil;
  // Ищем обьект в двух кешах
  // В оперативной памяти
  if FMemoryCache.ExtractObject(AKey, AValueObject, lErrorStr) then
  begin
    Log('Объект был загружен из кеша в оперативной памяти ');
    Exit;
  end
  else
  begin
    Log(lErrorStr);
  end;
  // В файловой системе
  if FFileCache.ExtractObject(AKey, AValueObject, lErrorStr) then
  begin
    Log('Объект был загружен из файлового кеша');
    Exit;
  end
  else
  begin
    Log(lErrorStr);
  end;
end;

procedure TMainCache<TKey, T>.ExtractObject(const AKey: TKey;
  out AValueObject: T);
begin
  FindObject(AKey, AValueObject);
end;

procedure TMainCache<TKey, T>.Log(const lMessage: string);
begin
  if Assigned(FLogMethod) then
  begin
    FLogMethod(lMessage);
  end;

end;

end.
