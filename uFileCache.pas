unit uFileCache;

interface

uses
  // user moduls
  uCache, uTestableObject,
  //
  System.Generics.Collections, System.SysUtils, DBXJSONReflect, System.JSON;

type
  TFileCache = class(TInterfacedObject, TCache)
  strict private
    FObjectDictionary: TObjectDictionary<string, string>;

    FMarshal: TJSONMarshal; // Сериализатор
    FUnMarshal: TJSONUnMarshal; // Десериализатор

    FMarshalingObject: IBaseObject;
  public
    function AddObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
    function DeleteObject(const AKey: string; out AErrorStr: string): Boolean;
    function ReplaceObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
    function GetObject(const AKey: string; out AObject: IBaseObject; out AErrorStr: string): Boolean;
    procedure Clear;

    constructor Create;
    procedure BeforeDestruction; override;
  end;

implementation

{ TFileCache }

function TFileCache.AddObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
begin
  Result := False;
end;

procedure TFileCache.BeforeDestruction;
begin
  inherited;
end;

procedure TFileCache.Clear;
begin

end;

constructor TFileCache.Create;
begin
  inherited;

  FMarshal := TJSONMarshal.Create(TJSONConverter.Create);

  FObjectDictionary := TObjectDictionary<string, string>.Create;
end;

function TFileCache.DeleteObject(const AKey: string; out AErrorStr: string): Boolean;
begin
  Result := False;
end;

function TFileCache.GetObject(const AKey: string; out AObject: IBaseObject; out AErrorStr: string): Boolean;
begin
  Result := False;
end;

function TFileCache.ReplaceObject(const AKey: string; const AObject: IBaseObject; out AErrorStr: string): Boolean;
begin
  Result := False;
end;

end.
