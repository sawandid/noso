unit NosoTime;

{
Nosotime 1.0
December 3th, 2022
Noso Time Unit for time synchronization on Noso project.
Requires indy package. (To-do: remove this dependancy)

Changes:
- Random use of NTP servers.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IdSNTP, DateUtils, strutils;

Type
   TThreadUpdateOffeset = class(TThread)
   private
     Hosts: string;
   protected
     procedure Execute; override;
   public
     constructor Create(const CreatePaused: Boolean; const THosts:string);
   end;

Function GetNetworkTimestamp(hostname:string):int64;
function TimestampToDate(timestamp:int64):String;
Function GetTimeOffset(NTPServers:String):int64;
Function UTCTime:Int64;
Function UTCTimeStr:String;
Procedure UpdateOffset(NTPServers:String);
function TimeSinceStamp(Lvalue:int64):string;

Var
  NosoT_TimeOffset : int64 = 0;
  NosoT_LastServer : string = '';
  NosoT_LastUpdate : int64 = 0;

IMPLEMENTATION

constructor TThreadUpdateOffeset.Create(const CreatePaused: Boolean; const THosts:string);
begin
  inherited Create(CreatePaused);
  Hosts := THosts;
end;

procedure TThreadUpdateOffeset.Execute;
var
  TimeToRun : int64;
  TFinished  : boolean = false;
Begin
GetTimeOffset(Hosts);
End;

Function GetNetworkTimestamp(hostname:string):int64;
var
  NTPClient: TIdSNTP;
begin
result := 0;
NTPClient := TIdSNTP.Create(nil);
   TRY
   NTPClient.Host := hostname;
   NTPClient.Active := True;
   NTPClient.ReceiveTimeout:=500;
   result := DateTimeToUnix(NTPClient.DateTime);
   if result <0 then result := 0;
   EXCEPT on E:Exception do
      result := 0;
   END; {TRY}
NTPClient.Free;
end;

function TimestampToDate(timestamp:int64):String;
begin
result := DateTimeToStr(UnixToDateTime(TimeStamp));
end;

Function GetTimeOffset(NTPServers:String):int64;
var
  Counter    : integer = 0;
  ThisNTP    : int64;
  MyArray    : array of string;
  RanNumber : integer;
Begin
Result := 0;
NTPServers := StringReplace(NTPServers,':',' ',[rfReplaceAll, rfIgnoreCase]);
NTPServers := Trim(NTPServers);
MyArray := SplitString(NTPServers,' ');
Rannumber := Random(length(MyArray));
For Counter := 0 to length(MyArray)-1 do
   begin
   ThisNTP := GetNetworkTimestamp(MyArray[Rannumber]);
   if ThisNTP>0 then
      begin
      Result := ThisNTP - DateTimeToUnix(Now);
      NosoT_LastServer := MyArray[Rannumber];
      NosoT_LastUpdate := UTCTime;
      break;
      end;
   Inc(RanNumber);
   If RanNumber >= length(MyArray)-1 then RanNumber := 0;
   end;
NosoT_TimeOffset := Result;
End;

Function UTCTime:Int64;
Begin
Result := DateTimeToUnix(Now, False) +NosoT_TimeOffset;
End;

{Implemented for easy compatibility with nosowallet}
Function UTCTimeStr:String;
Begin
Result := InttoStr(DateTimeToUnix(Now, False) +NosoT_TimeOffset);
End;

Procedure UpdateOffset(NTPServers:String);
var
  LThread : TThreadUpdateOffeset;
Begin
LThread := TThreadUpdateOffeset.Create(true,NTPservers);
LThread.FreeOnTerminate:=true;
LThread.Start;
End;

function TimeSinceStamp(Lvalue:int64):string;
var
  Elapsed : Int64 = 0;
Begin
Elapsed := UTCTime - Lvalue;
if Elapsed div 60 < 1 then result := '<1m'
else if Elapsed div 3600 < 1 then result := IntToStr(Elapsed div 60)+'m'
else if Elapsed div 86400 < 1 then result := IntToStr(Elapsed div 3600)+'h'
else if Elapsed div 2592000 < 1 then result := IntToStr(Elapsed div 86400)+'d'
else if Elapsed div 31536000 < 1 then result := IntToStr(Elapsed div 2592000)+'M'
else result := IntToStr(Elapsed div 31536000)+' Y';
end;

END. // END UNIT
