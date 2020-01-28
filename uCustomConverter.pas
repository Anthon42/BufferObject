unit uCustomConverter;

interface

uses
  DBXJSONReflect, uTestableObject;

var
  ExampleObjectConverter: TObjectsConverter;

implementation

uses
  SysUtils, RTTI, DateUtils, Classes;

initialization

ExampleObjectConverter := function(Data: TObject; Field: string)
  begin
  end;

end.
