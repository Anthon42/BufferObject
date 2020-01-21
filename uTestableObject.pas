unit uTestableObject;

interface

type
  IBaseObject = interface
    function GetMessage: string;
  end;

  TTestObject = class(TInterfacedObject, IBaseObject)
  public
    function GetMessage: string;
  end;

implementation

function TTestObject.GetMessage: string;
begin
  Result := 'Message Text';
end;

end.
