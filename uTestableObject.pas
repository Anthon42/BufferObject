unit uTestableObject;

interface

type
  TTestObject = class(TObject)
  strict private
    FContent: string;
  public
    constructor Create(const AMessage: string); reintroduce;

    function GetMessage: string;
    procedure AfterConstruction; override;
  end;

implementation

procedure TTestObject.AfterConstruction;
begin
  inherited;
end;

constructor TTestObject.Create(const AMessage: string);
begin
  FContent := AMessage;
end;

function TTestObject.GetMessage: string;
begin
  Result := FContent;
end;

end.
