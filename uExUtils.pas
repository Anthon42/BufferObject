unit uExUtils;

interface

uses System.SysUtils;

procedure FreeAndNilEx(var Obj);

implementation

procedure FreeAndNilEx(var Obj);
begin
  if Assigned(TObject(Obj)) then
    FreeAndNil(Obj);
end;

end.
