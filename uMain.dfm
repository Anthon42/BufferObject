object dfmMain: TdfmMain
  Left = 0
  Top = 0
  Caption = 's'
  ClientHeight = 300
  ClientWidth = 551
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
    Width = 424
    Height = 292
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object btnAddObject: TButton
    Left = 430
    Top = 267
    Width = 113
    Height = 25
    Caption = #1044#1086#1073#1072#1074#1080#1090#1100' '#1054#1073#1100#1077#1082#1090#1099
    TabOrder = 1
    OnClick = btnAddObjectClick
  end
  object btnLoadFromCache: TButton
    Left = 430
    Top = 236
    Width = 113
    Height = 25
    Caption = #1042#1099#1075#1088#1091#1079#1080#1090#1100' '#1054#1073#1098#1077#1082#1090#1099
    TabOrder = 2
    OnClick = btnLoadFromCacheClick
  end
  object btnClear: TButton
    Left = 430
    Top = 205
    Width = 113
    Height = 25
    Caption = #1054#1095#1080#1089#1090#1080#1090#1100
    TabOrder = 3
    OnClick = btnClearClick
  end
end
