unit uMain;

interface

uses
  // useser moduls
  uCache, uTestableObject, uFileCache,
  //
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TdfmMain = class(TForm)
    meLog: TMemo;
    btnAddObject: TButton;

    procedure btnAddObjectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LogMessage(const AErrorStr: string);
  private
    FFileCache: TFileCache;
  public
    { Public declarations }
  end;

var
  dfmMain: TdfmMain;

implementation

uses RTTI, uObjectContainer;
{$R *.dfm}

procedure TdfmMain.btnAddObjectClick(Sender: TObject);
var
  lTestObject: TExampleObject;

  lResultObject: TValue;

  lObjectContainer: TObjectContainer;

  lErrorStr: string;
begin
  lTestObject := TExampleObject.Create;

  lObjectContainer := TObjectContainer.Create(lTestObject);
  lTestObject := nil;

  if not FFileCache.AddObject('Test2', lObjectContainer, lErrorStr) then
  begin
    FreeAndNil(lObjectContainer);
    LogMessage(lErrorStr);
  end;

  if not FFileCache.GetObject('Test2', lResultObject, lErrorStr) then
  begin
    LogMessage(lErrorStr);
  end;

  lObjectContainer := lResultObject.AsType<TObjectContainer>;
  lTestObject := lObjectContainer.GetObject;
  LogMessage(lTestObject.GetMessage + IntToStr(lObjectContainer.FGetObjectCount));
end;

procedure TdfmMain.FormCreate(Sender: TObject);
begin
  FFileCache := TFileCache.Create;
end;

procedure TdfmMain.LogMessage(const AErrorStr: string);
begin
  meLog.Lines.Add(AErrorStr);
end;

end.
