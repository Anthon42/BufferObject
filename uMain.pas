unit uMain;

interface

uses
  // useser moduls
  uCache,uTestableObject,
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
    FMemoryCache: TMemoryCache;
  public
    { Public declarations }
  end;

var
  dfmMain: TdfmMain;

implementation

{$R *.dfm}

procedure TdfmMain.btnAddObjectClick(Sender: TObject);
var
  lTestObject: IBaseObject;
  lErrorStr: string;
begin
  lTestObject := TTestObject.Create;

  if not FMemoryCache.AddObject('Test', lTestObject, lErrorStr) then
    LogMessage(lErrorStr);

  lTestObject := nil;

  if not FMemoryCache.GetObject('Test1', lTestObject, lErrorStr) then
    LogMessage(lErrorStr);

  LogMessage(lTestObject.GetMessage);
end;

procedure TdfmMain.FormCreate(Sender: TObject);
begin
  FMemoryCache := TMemoryCache.Create;
end;

procedure TdfmMain.LogMessage(const AErrorStr: string);
begin
  meLog.Lines.Add(AErrorStr);
end;

end.
