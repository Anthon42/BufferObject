unit uObjectContainer;

interface

type
  TObjectContainer<T> = class(TObject)
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

//  TObjectContainer = TGenericObjectContainer<TestableObject>;

implementation

uses System.SysUtils;

procedure TObjectContainer<T>.BeforeDestruction;
begin
  FreeAndNil(FSavedObject);

  inherited;
end;

constructor TObjectContainer<T>.Create(AValueObject: T);
begin
  inherited Create;
  FSavedObject := AValueObject;

  UpdateTime;

  FGetObjectCount := 0;
end;

function TObjectContainer<T>.GetObject: T;
begin
  Inc(FGetObjectCount);
  UpdateTime;

  Result := FSavedObject;
end;

procedure TObjectContainer<T>.UpdateTime;
begin
  FLastActionTime := Time;
end;

end.
