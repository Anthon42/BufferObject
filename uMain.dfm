object dfmMain: TdfmMain
  Left = 0
  Top = 0
  Caption = 'Mian'
  ClientHeight = 300
  ClientWidth = 322
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object meLog: TMemo
    Left = 0
    Top = 0
    Width = 193
    Height = 292
    TabOrder = 0
  end
  object btnAddObject: TButton
    Left = 199
    Top = 267
    Width = 113
    Height = 25
    Caption = #1044#1086#1073#1072#1074#1080#1090#1100' '#1054#1073#1100#1077#1082#1090
    TabOrder = 1
    OnClick = btnAddObjectClick
  end
end
