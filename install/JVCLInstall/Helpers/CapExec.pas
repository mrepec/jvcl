{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: CapExec.pas, released on 2003-11-28.

The Initial Developer of the Original Code is Andreas Hausladen
(Andreas dott Hausladen att gmx dott de)
Portions created by Andreas Hausladen are Copyright (C) 2003 Andreas Hausladen.
All Rights Reserved.

Contributor(s): -

You may retrieve the latest version of this file at the Project JEDI's JVCL
home page, located at http://jvcl.sourceforge.net

Known Issues:
-----------------------------------------------------------------------------}
// $Id$

unit CapExec;

{$I jvcl.inc}
{$I windowsonly.inc}

interface

uses
  Windows, SysUtils, Classes;

type
  TCaptureLine = procedure(const Line: string; var Aborted: Boolean) of object;

var
  CaptureStatusLine: TCaptureLine = nil;

function CaptureExecute(const App, Args, Dir: string; CaptureLine: TCaptureLine;
  OnIdle: TNotifyEvent = nil; CtrlCAbort: Boolean = False; const EnvPath: string = '';
  InjectDll: Boolean = False): Integer;

implementation

{uses
  InjectDll, SharedMMFMem;}

function GetEnvironmentVariable(const Name: string): string;
begin
  SetLength(Result, 8 * 1024);
  SetLength(Result, Windows.GetEnvironmentVariable(PChar(Name), PChar(Result), Length(Result)));
end;

function Oem2Ansi(const Text: string): string;
begin
  Result := Text;
  OemToCharBuff(PChar(Result), PChar(Result), Length(Result));
end;

function CaptureExecute(const App, Args, Dir: string; CaptureLine: TCaptureLine;
  OnIdle: TNotifyEvent; CtrlCAbort: Boolean; const EnvPath: string; InjectDll: Boolean): Integer;
var
  Aborted: Boolean;

  procedure ProcessInput(hRead: THandle; var Line: string; CaptureLine: TCaptureLine);
  var
    BytesInPipe, n: Cardinal;
    S: string;
    i: Integer;
    Found: Boolean;
  begin
    BytesInPipe := 0;
    if not PeekNamedPipe(hRead, nil, 0, nil, @BytesInPipe, nil) then
      BytesInPipe := 0;
    SetLength(S, BytesInPipe);
    if S <> '' then
    begin
      ReadFile(hRead, S[1], BytesInPipe, n, nil);
      SetLength(S, n);
      Line := Line + S;
      repeat
        Found := False;
        for i := 1 to Length(Line) do
          if Line[i] in [#10, #13] then
          begin
            if Assigned(CaptureLine) then
              CaptureLine(Oem2Ansi(Copy(Line, 1, i - 1)), Aborted);
            if (Line[i] = #13) and (Line[i + 1] = #10) then
            begin
              if (i + 2 <= Length(Line)) and (Line[i + 2] = #13) then
                Delete(Line, 1, i + 2)
              else
                Delete(Line, 1, i + 1);
            end
            else
              Delete(Line, 1, i);
            Found := True;
            Break;
          end;
      until Aborted or not Found;
    end;
  end;

var
  ProcessInfo: TProcessInformation;
  StartupInfo: TStartupInfo;
  SecAttrib: TSecurityAttributes;
  hRead, hWrite: THandle;
  hAbortRead, hAbortWrite: THandle;
  ReadStatusPipe, WriteStatusPipe: THandle;
  Line: string;
  StatusLine: string;
  OrgEnvPath: string;
//  PipeP: ^THandle;
begin
  Result := -2;
  if not Assigned(CaptureLine) then
    Exit;

  FillChar(SecAttrib, SizeOf(SecAttrib), 0);
  with SecAttrib do
  begin
    nLength := SizeOf(SecAttrib);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end; // with

  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  StartupInfo.cb := SizeOf(TStartupInfo);

  Aborted := False;
  if not CreatePipe(hRead, hWrite, @SecAttrib, 0) then
    Exit;
  try
    if not CreatePipe(hAbortRead, hAbortWrite, @SecAttrib, 0) then
      Exit;
    if not CreatePipe(ReadStatusPipe, WriteStatusPipe, @SecAttrib, 0) then
    begin
      WriteStatusPipe := 0;
      ReadStatusPipe := 0;
    end;

    try
      StartupInfo.wShowWindow := SW_HIDE;
      StartupInfo.hStdInput := hAbortRead;
      StartupInfo.hStdOutput := hWrite;
      StartupInfo.hStdError := StartupInfo.hStdOutput; // redirect
      StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;

      OrgEnvPath := GetEnvironmentVariable('PATH');
      if EnvPath <> '' then
        SetEnvironmentVariable('PATH', Pointer(EnvPath));
      try
        if CreateProcess(nil, PChar(App + ' ' + Args), @SecAttrib, nil, True,
          CREATE_SUSPENDED, nil, PChar(Dir), StartupInfo, ProcessInfo) then
        begin
          {if InjectDll then
          begin
            SharedGetMem(PipeP, 'Local\dcc32Hook_StatusPipe' + IntToStr(ProcessInfo.dwProcessId), SizeOf(THandle));
            if Assigned(PipeP) then
            begin
              try
                PipeP^ := WriteStatusPipe;
                InjectHookDll(ProcessInfo.dwProcessId, ExtractFilePath(ParamStr(0)) + 'dcc32Hook.dll', False);
              finally
                SharedFreeMem(PipeP);
              end;
            end;
          end;}
          ResumeThread(ProcessInfo.hThread);

          CloseHandle(ProcessInfo.hThread);
          try
            while (WaitForSingleObject(ProcessInfo.hProcess, 80) = WAIT_TIMEOUT) and (not Aborted) do
            begin
              ProcessInput(hRead, Line, CaptureLine);
              if ReadStatusPipe <> 0 then
                ProcessInput(ReadStatusPipe, StatusLine, CaptureStatusLine);
              if Assigned(OnIdle) then
                OnIdle(nil);
            end;
            ProcessInput(hRead, Line, CaptureLine);
            if (Line <> '') and Assigned(CaptureLine) then
              CaptureLine(Line, Aborted);
            if ReadStatusPipe <> 0 then
              ProcessInput(ReadStatusPipe, StatusLine, CaptureStatusLine);
            if (StatusLine <> '') and Assigned(CaptureStatusLine) then
              CaptureStatusLine(StatusLine, Aborted);
            if Aborted then
            begin
              if CtrlCAbort then
              begin
                GenerateConsoleCtrlEvent(CTRL_C_EVENT, ProcessInfo.dwProcessId);
                if WaitForSingleObject(ProcessInfo.hProcess, 500) = WAIT_TIMEOUT then
                  TerminateProcess(ProcessInfo.hProcess, Cardinal(1));
              end
              else
                TerminateProcess(ProcessInfo.hProcess, Cardinal(1));
            end;
            GetExitCodeProcess(ProcessInfo.hProcess, Cardinal(Result));
          finally
            CloseHandle(ProcessInfo.hProcess);
          end;
        end
        else
          Result := -1;
      finally
        if EnvPath <> '' then
          SetEnvironmentVariable('PATH', Pointer(OrgEnvPath));
      end;
    finally
      if WriteStatusPipe <> 0 then
        CloseHandle(WriteStatusPipe);
      if ReadStatusPipe <> 0 then
        CloseHandle(ReadStatusPipe);
      CloseHandle(hAbortRead);
      CloseHandle(hAbortWrite);
    end;
  finally
    CloseHandle(hRead);
    CloseHandle(hWrite);
  end;
end;

procedure NoHooking;
begin
end;

exports
  NoHooking; // prevent DllInjection to hook this process

end.