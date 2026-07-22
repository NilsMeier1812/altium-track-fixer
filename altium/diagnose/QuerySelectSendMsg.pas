{..............................................................................}
{  Verbindungs-Check - DIAGNOSE: Maske + "Select All" via Client.SendMessage    }
{                                                                              }
{  Erkenntnis aus den bisherigen Laeufen:                                       }
{   - PCB:RunQuery MASKIERT korrekt, SELEKTIERT aber nicht.                     }
{   - "Select All" respektiert eine aktive Maske (Baseline lieferte ~132820).   }
{   - RunProcess(PCB:RunQuery) kollidiert mit der Skript-Engine                 }
{     ("Another script executing now") -> der Select-Teil bricht ab.           }
{                                                                              }
{  Idee hier: den Weg ueber Client.SendMessage gehen (umgeht die RunProcess-    }
{  Kollision) und in ZWEI Schritten arbeiten:                                   }
{     1. Maske setzen  (nur Tracks mit Net bleiben aktiv)                       }
{     2. "Select All"  (waehlt nur die nicht-maskierten = Tracks mit Net)       }
{  Dann die Selektion per Index durchgehen (schnell, kein 379k-Iterator).       }
{                                                                              }
{  Eigene Datei/eigenes Projekt: falls 'Client' in dieser DelphiScript-         }
{  Umgebung nicht existiert, gibt es beim Start "Undeclared identifier:         }
{  Client" - dann ist DIESER Weg hier nicht moeglich, die anderen Testdateien   }
{  bleiben aber lauffaehig.                                                     }
{                                                                              }
{  Bedienung: File -> Open -> QuerySelectSendMsg.PrjScr, dann Run Script ->     }
{             TestMaskThenSelect.                                               }
{                                                                              }
{  ACHTUNG: veraendert Auswahl + Filter/Maske. Am Ende wird beides             }
{  zurueckgesetzt; falls das Board doch gefiltert aussieht: unten rechts        }
{  "Clear" bzw. Shift+C.                                                        }
{..............................................................................}

const
  SAFELIMIT = 2000000;

procedure TestMaskThenSelect;
var
  Board : IPCB_Board;
  Prim  : IPCB_Primitive;
  q, sm, msg : String;
  cntSel, cntSelTracks, i : Integer;
  t0, t1 : TDateTime;
  iterSecs : Double;
  okSend : Boolean;
begin
  if PCBServer = nil then begin ShowMessage('PCBServer = nil'); Exit; end;
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then begin ShowMessage('Board = nil'); Exit; end;

  q := '(ObjectKind = ''Track'') And Not (Net = ''No Net'')';
  cntSel := -1;
  cntSelTracks := -1;
  iterSecs := 0.0;
  okSend := False;

  { --- 1) Auswahl leeren, 2) Maske setzen, 3) Select All (respektiert Maske) - }
  {     alles ueber Client.SendMessage (umgeht die RunProcess-Kollision).       }
  {     Expr steht bewusst als LETZTER Parameter, weil er selbst '=' enthaelt.  }
  try
    Client.SendMessage('PCB:DeSelect', 'Scope=All', 255, Client.CurrentView);
    Client.SendMessage('PCB:RunQuery',
      'Clear=True|Apply=True|Mask=True|Select=False|Expr=' + q,
      255, Client.CurrentView);
    Client.SendMessage('PCB:Select', 'Scope=All', 255, Client.CurrentView);
    okSend := True;
  except
    okSend := False;
  end;

  try cntSel := Board.SelectecObjectCount; except cntSel := -1; end;

  { --- Kreuzcheck: die Selektion per INDEX durchgehen und Tracks zaehlen ------ }
  {     (misst zugleich, wie schnell der indizierte Zugriff auf ~132k ist)      }
  if cntSel > 0 then
  begin
    cntSelTracks := 0;
    t0 := Now;
    for i := 0 to cntSel - 1 do
    begin
      if i >= SAFELIMIT then Break;
      try
        Prim := Board.SelectecObject(i);
        if Prim <> nil then
          if Prim.ObjectId = eTrackObject then
            cntSelTracks := cntSelTracks + 1;
      except
      end;
    end;
    t1 := Now;
    iterSecs := (t1 - t0) * 86400.0;
  end;

  { --- Aufraeumen: Maske loeschen + Auswahl leeren -------------------------- }
  try
    Client.SendMessage('PCB:RunQuery',
      'Clear=True|Apply=True|Mask=False|Select=False|Expr=' + q,
      255, Client.CurrentView);
    Client.SendMessage('PCB:DeSelect', 'Scope=All', 255, Client.CurrentView);
  except
  end;

  if okSend then sm := 'ja (keine Ausnahme)' else sm := 'NEIN - SendMessage warf';

  msg :=
    'Maske (Query) + "Select All" via SendMessage' + #13#10 + #13#10 +
    'SendMessage lief durch:   ' + sm + #13#10 +
    'SelectecObjectCount:      ' + IntToStr(cntSel) + #13#10 +
    'davon Tracks:             ' + IntToStr(cntSelTracks) + #13#10 +
    'Index-Durchlauf-Dauer:    ' + FloatToStr(iterSecs) + ' s' + #13#10 + #13#10 +
    'Ziel: "davon Tracks" ~132820 (Tracks mit Net).' + #13#10 +
    'Passt es -> Weg gefunden, wir bauen ihn in den Export ein.' + #13#10 +
    'Kam KEIN "Another script executing"-Fehler mehr? Bitte melden.';
  ShowMessage(msg);
end;
