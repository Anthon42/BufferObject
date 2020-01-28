unit uObjectContainer;

interface

uses uTestableObject;

type
  TGenericObjectContainer<T> = class(TObject)
  strict private
    FSavedObject: T;
    FLastActionTime: TDateTime;
    procedure UpdateTime;
  public
    FGetObjectCount: Integer;
    function GetObject: T;

    constructor Create(AValueObject: T); reintroduce;

    procedure BeforeDestruction; override;

  end;

  TObjectContainer = TGenericObjectContainer<TExampleObject>;

implementation

uses System.SysUtils;

procedure TGenericObjectContainer<T>.BeforeDestruction;
begin
  FreeAndNil(FSavedObject);

  inherited;
end;

constructor TGenericObjectContainer<T>.Create(AValueObject: T);
begin
  inherited Create;
  FSavedObject := AValueObject;

  UpdateTime;

  FGetObjectCount := 0;
end;

function TGenericObjectContainer<T>.GetObject: T;
begin
  Inc(FGetObjectCount);
  UpdateTime;

  Result := FSavedObject;
end;

procedure TGenericObjectContainer<T>.UpdateTime;
begin
  FLastActionTime := Time;
end;

end.
