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
      // ���������� ������ � ����������� ������
      if not FMemoryCache.AddObject(AKey, AValueObject, lErrorStr) then
      begin
        Log(lErrorStr);
        Exit;
      end;
      Log('����� ������ ��� ������� � ����������� ������');
    end
    else
    begin
      // ��������� ����� � �������� ����
      if FFileCache.Count = FFileCacheCapacity then
      begin
        Log(self.ClassName + '.AddObject ' + ' ��� ����������');
        Exit;
      end;
      // ���������� ����� ������ ������ �� ����������� ������ � �������� ���
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
        Log('������ ������ ��� ��������� � �������� ������');

      // ���������� ������ � ����������� ������
      if not FMemoryCache.AddObject(AKey, AValueObject, lErrorStr) then
      begin
        Log(lErrorStr);
        Exit;
      end;
      Log('����� ������ ��� ������� � ����������� ������');
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
  // ���� ������ � ���� �����
  // � ����������� ������
  if FMemoryCache.ExtractObject(AKey, AValueObject, lErrorStr) then
  begin
    Log('������ ��� �������� �� ���� � ����������� ������ ');
    Exit;
  end
  else
  begin
    Log(lErrorStr);
  end;
  // � �������� �������
  if FFileCache.ExtractObject(AKey, AValueObject, lErrorStr) then
  begin
    Log('������ ��� �������� �� ��������� ����');
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
