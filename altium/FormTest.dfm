object FormTestForm: TFormTestForm
  Left = 300
  Top = 200
  BorderStyle = bsDialog
  Caption = 'Form-Test (Live-Modus-Vorpruefung)'
  ClientHeight = 150
  ClientWidth = 380
  Position = poScreenCenter
  PixelsPerInch = 96
  object LabelInfo: TLabel
    Left = 16
    Top = 16
    Width = 348
    Height = 70
    AutoSize = False
    Caption = 'Warte auf ersten Timer-Tick (alle 2 s) ...'
    WordWrap = True
  end
  object ButtonClose: TButton
    Left = 16
    Top = 104
    Width = 150
    Height = 30
    Caption = 'Schliessen'
    OnClick = ButtonCloseClick
  end
  object TimerTest: TTimer
    Interval = 2000
    OnTimer = TimerTestTimer
    Left = 320
    Top = 100
  end
end
