program Cache;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {dfmMain},
  uTestableObject in 'uTestableObject.pas',
  uFileCache in 'uFileCache.pas',
  uMemoryCache in 'uMemoryCache.pas',
  uExUtils in 'uExUtils.pas',
  uMainCache in 'uMainCache.pas',
  Indexes in 'Indexes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TdfmMain, dfmMain);
  Application.Run;
end.
