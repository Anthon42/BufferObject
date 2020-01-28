program Cache;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {dfmMain},
  uCache in 'uCache.pas',
  uTestableObject in 'uTestableObject.pas',
  uFileCache in 'uFileCache.pas',
  uObjectContainer in 'uObjectContainer.pas',
  uMemoryCache in 'uMemoryCache.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TdfmMain, dfmMain);
  Application.Run;
end.
