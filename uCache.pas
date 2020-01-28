unit uCache;

interface

uses

  // user moduls
  RTTI
  //
    ;
//type
 { TCache<TKey, TValue> = interface
    function AddObject(const AKey: TKey; const AValueObject: TValue; out AErrorStr: string): Boolean;
    function DeleteObject(const AKey: TKey; out AErrorStr: string): Boolean;
    function ReplaceObject(const AKey: TKey; const AValueObject: TValue; out AErrorStr: string): Boolean;
    function GetObject(const AKey: TKey; out AValueObject: TValue; out AErrorStr: string): Boolean;

    procedure Clear;  }
 // end;

implementation

end.
