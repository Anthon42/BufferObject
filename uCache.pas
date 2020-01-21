unit uCache;

interface

uses
  // user moduls
  uTestableObject
  //
    ;

type
  TCache = interface
    function AddObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
    function DeleteObject(const AKey: string; out AErrorStr: string): Boolean;
    function ReplaceObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
    function GetObject(const AKey: string; out AObject: IBaseObject; out AErrorStr: string): Boolean;

    procedure Clear;
  end;

implementation

end.
