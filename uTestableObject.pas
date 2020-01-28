unit uTestableObject;

interface

type
  TExampleObject = class(TObject)
  strict private
    FContent: string;
  public
    function GetMessage: string;
    procedure AfterConstruction; override;
  end;

implementation

procedure TExampleObject.AfterConstruction;
begin
  inherited;
  FContent := 'TestMessage';
end;

function TExampleObject.GetMessage: string;
begin
  Result := FContent;
end;

end.
