unit uMain;

interface

uses

  uTestableObject, uFileCache, uMemoryCache, uExUtils,
  uMainCache,
  //
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TdfmMain = class(TForm)
    meLog: TMemo;
    btnAddObject: TButton;
    btnLoadFromCache: TButton;
    btnClear: TButton;

    procedure btnAddObjectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnLoadFromCacheClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);

  private
    FFileCache: TFileCache<string, TTestObject>;
    FMemoryCache: TMemoryCache<string, TTestObject>;

    FMainCache: TMainCache<string, TTestObject>;

  public
    { Public declarations }
  end;

const
  constMemoryCacheSize = 10;
  constFileMemoryCache = 5;

var
  dfmMain: TdfmMain;

implementation

uses RTTI;
{$R *.dfm}

procedure TdfmMain.btnAddObjectClick(Sender: TObject);
var
  lTestObject: TTestObject;

  lKey: string;
  lCurrentItem: Integer;
begin
  for lCurrentItem := 0 to 16 do
  begin
    lTestObject := nil;
    lKey := 'Test' + IntToStr(lCurrentItem);
    lTestObject := TTestObject.Create(lKey);

    FMainCache.AddObject(lKey, lTestObject);

  end;
end;

procedure LogMessage(const AErrorStr: string);
begin
  dfmMain.meLog.Lines.Add(AErrorStr);
end;

procedure TdfmMain.btnClearClick(Sender: TObject);
begin
  meLog.Clear;
end;

procedure TdfmMain.btnLoadFromCacheClick(Sender: TObject);
var
  lTestObject: TTestObject;

  lKey: string;
  lCurrentItem: Integer;
begin
  for lCurrentItem := 0 to 16 do
  begin
    lTestObject := nil;

    lKey := 'Test' + IntToStr(lCurrentItem);

    FMainCache.ExtractObject(lKey, lTestObject);
    if Assigned(lTestObject) then
    begin
      LogMessage(lTestObject.GetMessage);
      FreeAndNilEx(lTestObject);
    end;
  end;
end;

procedure TdfmMain.FormCreate(Sender: TObject);
begin
  FFileCache := TFileCache<string, TTestObject>.Create;

  FMemoryCache := TMemoryCache<string, TTestObject>.Create
    (constMemoryCacheSize);

  FMainCache := TMainCache<string, TTestObject>.Create(constMemoryCacheSize,
    constFileMemoryCache);

  FMainCache.OnLogingMethod := LogMessage;
end;

end.
