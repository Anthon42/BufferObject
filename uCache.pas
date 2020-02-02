unit uCache;

interface

type
  ICache<TKey; T:class> = interface
    function AddObject(const AKey: TKey; const AValueObject: T; out AErrorStr: string): Boolean;
    function DeleteObject(const AKey: TKey; out AErrorStr: string): Boolean;
    function GetObject(const AKey: TKey; out AValueObject: T; out AErrorStr: string): Boolean;

    procedure Clear;
  end;

implementation

end.
