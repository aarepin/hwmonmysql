unit Unit1;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  Vcl.SvcMgr,
  Vcl.Dialogs,
  Data.DBXMySQL,
  Data.DB,
  Data.SqlExpr,
  shellapi,
  System.Classes,
  shfolder, IdBaseComponent, IdComponent, IdIPWatch, Data.Win.ADODB,
  activex,
  nb30;

type
  Tazurehwmon = class(TService)
    SQLC: TSQLConnection;

  procedure ServiceExecute(Sender: TService);

  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  azurehwmon: Tazurehwmon;
    CPUTotal,CPUPackage,Memory,UsMem,AvailMem,Usspace,checkmy:integer;
  xdate,pmssql,ip,mac,path,logfile:string;
  mbtemp,cpuload,cputemp,cpuwt,fan1,fan2,memload,memus,memavail,hddspace,hddtemp:string;
  fL : TStringList;
  procedure log(aStr: string);
  procedure tosql;
  procedure clearlog;
  procedure loadparam;
  function GetMACAdress: string;
  procedure parseohmreport(fil:string);
  function  wrd(var s:string;j:integer):string;
  function GetFileDate(FileName: string): string;
  procedure runohmreport;
implementation

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  azurehwmon.Controller(CtrlCode);
end;

function Tazurehwmon.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;



procedure Tazurehwmon.ServiceExecute(Sender: TService);
const
  SecBetweenRuns = 5;
var
  Count: Integer;
begin
  path:=ExtractFileDir(ParamStr(0))+'\';
  chdir(pchar(path));
  clearlog;
  log('Старт сервиса, текущая папка '+path);
  loadparam;
  checkmy:=1;
  try
    azurehwmon.SQLC.Connected:=true;
  except on E: exception do
    begin
      log('Error connect to MySQL:'+e.Message);
      checkmy:=0
    end;

  end;

  Count := 0;

  while not Terminated do
    begin
    try
     if mac='' then
        try
          mac:=GetMACAdress;
          except on E: exception do log('get mac:'+e.Message);
        end;
     Inc(Count);
     if Count >= SecBetweenRuns then
       begin
        runohmreport;
        sleep(5000);
        parseohmreport('ohmreport.txt');
        tosql;
        Count := 0;
       end;
     sleep(59166);

     ServiceThread.ProcessRequests(False);
    except on E: exception do log('while not term: '+e.Message);
    end;
  end;
end;

procedure loadparam;
begin
  {for MS-SQL connection}
  try
      azurehwmon.SQLC.Params.LoadFromFile(path+'parammysql.ini');
     except on E: exception do
         begin
             log('Error open parammysql.ini:'+e.Message);
             azurehwmon.DoStop;
         end;
  end;
end;

procedure tosql;
begin
   try
     CoInitialize(nil);
      try
        azurehwmon.SQLC.ExecuteDirect('INSERT INTO repin.ohmrep'+
        '(datet'+
        ',mac'+
        ',mbtemp'+
        ',cpuload'+
        ',cputemp'+
        ',cpuwt'+
        ',fan1'+
        ',fan2'+
        ',memload'+
        ',memus'+
        ',memavail'+
        ',hddspace'+
        ',hddtemp)'+
        ' VALUES('+#39+xdate+#39+','+#39+ mac +#39+','+#39+ mbtemp +#39+','+#39+cpuload+#39+','+#39+cputemp+#39+','+#39+cpuwt+#39+','+#39+fan1+#39+','+#39+fan2+#39+','+#39+memload+#39+','+#39+memus+#39+','+#39+memavail+#39+','+#39+hddspace+#39+','+#39+hddtemp+#39+')');
//        mbtemp,cpuload,cputemp,cpuwt,fan1,fan2,memload,memus,memavail,hddspace,hddtemp
        except on E: exception do
        begin
          log('Insert into ohm: '+e.Message);
        end;
      end;
      finally  CoUninitialize;
   end;
end;


procedure parseohmreport(fil:string);
var
f:textfile;
str,str1:string;
begin
  try
    path:=ExtractFileDir(ParamStr(0))+'\';
    chdir(pchar(path));
  except on e:Exception do log('Ошибка path '+ e.Message);
  end;
  try
    xdate:=GetFileDate(path+fil);
    assignfile(f,path+fil);
    reset(f);
  except on e:Exception do log('Ошибка открытия файла'+ e.Message);
  end;
  mbtemp:='-1';
  cpuload:='-1';
  cputemp:='-1';
  cpuwt:='-1';
  fan1:='-1';
  fan2:='-1';
  memload:='-1';
  memus:='-1';
  memavail:='-1';
  hddspace:='-1';
  hddtemp:='-1';
  str1:='';
 try
  while not EOF(f) do
    begin
       readln(f,str);
       if pos(':',str)<>0 then  str1:=copy(str,pos(':',str),length(str)); // если есть двоеточие, то сохраняем все что после него в отдельную переменную

       if (pos('CPU Core       :',str)<>0)and(pos('temperature',str)<>0)and(pos(':',str)<>0) and(pos('/',wrd(str,7))=0)
        then mbtemp:=wrd(str1,2);

       if (pos('CPU Total',str)<>0)and(pos('load',str)<>0)and(pos(':',str)<>0)and(pos('/',wrd(str,7))=0)
        then cpuload:=wrd(str1,2);

       if (pos('CPU Package',str)<>0)and(pos('temperature',str)<>0)and(pos(':',str)<>0)and(pos('/',wrd(str,7))=0)
        then cputemp:=wrd(str1,2);

       if (pos('CPU Package',str)<>0)and(pos('power',str)<>0)and(pos(':',str)<>0)and(pos('/',wrd(str,7))=0)
        then cpuwt:=wrd(str1,2);

       if (pos('Fan #1',str)<>0)and(pos('fan',str)<>0)and(pos(':',str)<>0)and(pos('/',wrd(str,7))=0)
        then fan1:=wrd(str1,2);

       if (pos('Fan #2',str)<>0)and(pos('fan',str)<>0)and(pos(':',str)<>0)and(pos('/',wrd(str,7))=0)
        then fan2:=wrd(str1,2);

       if (pos('Memory',str)<>0)and(pos('load',str)<>0)and(pos(':',str)<>0)and(pos('/',wrd(str,7))=0)
        then memload:=wrd(str1,2);

       if (pos('Used Memory',str)<>0)and(pos('data',str)<>0)and(pos(':',str)<>0)and(pos('/',wrd(str,7))=0)
        then memus:=wrd(str1,2);

       if (pos('Available Memory',str)<>0)and(pos('data',str)<>0)and(pos(':',str)<>0)and(pos('/',wrd(str,7))=0)
        then memavail:=wrd(str1,2);

       if (pos('Used Space',str)<>0)and(pos('/hdd/0/load',str)<>0)and(pos(':',str)<>0)and(pos('/',wrd(str,7))=0)
        then hddspace:=wrd(str1,2);

       if (pos('Temperature',str)<>0)and(pos('/hdd/0/temperature',str)<>0)and(pos(':',str)<>0) and(pos('/',wrd(str,7))=0)
        then hddtemp:=wrd(str1,2);
    end;
 except on e:Exception do log('Ошибка при чтении файла '+ e.Message);

 end;
  closefile(f);

end;

function wrd; //функция возвращает нужное по счету слово, разделитель - пробел(ы)
var
i:integer;
st:array of string;
begin
// убираем лишние пробелы
    while pos('  ',s)<>0 do s:=stringreplace(s,'  ',' ',[rfreplaceall]);
    i:=0;
    setlength(st,length(s)); // максимальный размер массива слов ограничим количеством символов в строке
//добавляем нужный пробел в конце строки
    s:=s+' ';
//закидываем в массив слово и тут же удаляем это слово из строки
    while pos(' ',s)<>0 do
      begin
        st[i]:=copy(s,0,pos(' ',s)-1);
        delete(s,1,pos(' ',s));
        i:=i+1;
      end;
    result:=st[j-1];
end;


function GetMACAdress: string;
var
  NCB: PNCB;
  Adapter: PAdapterStatus;
  RetCode: char;
  I: integer;
  Lenum: PlanaEnum;
  _SystemID: string;
begin
  Result    := '';
  _SystemID := '';
  Getmem(NCB, SizeOf(TNCB));
  Fillchar(NCB^, SizeOf(TNCB), 0);

  Getmem(Lenum, SizeOf(TLanaEnum));
  Fillchar(Lenum^, SizeOf(TLanaEnum), 0);

  Getmem(Adapter, SizeOf(TAdapterStatus));
  Fillchar(Adapter^, SizeOf(TAdapterStatus), 0);

  Lenum.Length    := chr(0);
  NCB.ncb_command := chr(NCBENUM);
  NCB.ncb_buffer  := Pointer(Lenum);
  NCB.ncb_length  := SizeOf(Lenum);
  RetCode         := char(Netbios(NCB));

  i := 0;
  repeat
    Fillchar(NCB^, SizeOf(TNCB), 0);
    Ncb.ncb_command  := chr(NCBRESET);
    Ncb.ncb_lana_num := lenum.lana[I];
    RetCode          := char(Netbios(Ncb));

    Fillchar(NCB^, SizeOf(TNCB), 0);
    Ncb.ncb_command  := chr(NCBASTAT);
    Ncb.ncb_lana_num := lenum.lana[I];
    // Must be 16
   Ncb.ncb_callname := '*               ';

    Ncb.ncb_buffer := Pointer(Adapter);

    Ncb.ncb_length := SizeOf(TAdapterStatus);
    RetCode        := char(Netbios(Ncb));
    //---- calc _systemId from mac-address[2-5] XOR mac-address[1]...
   if (RetCode = chr(0)) or (RetCode = chr(6)) then
    begin
      _SystemId := IntToHex(Ord(Adapter.adapter_address[0]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[1]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[2]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[3]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[4]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[5]), 2);
    end;
    Inc(i);
  until (I >= Ord(Lenum.Length)) or (_SystemID <> '00-00-00-00-00-00');
  FreeMem(NCB);
  FreeMem(Adapter);
  FreeMem(Lenum);
  GetMacAdress := _SystemID;
end;

function GetFileDate(FileName: string): string;
var
  FHandle: Integer;
begin
  FHandle := FileOpen(FileName, 0);
  try
    Result := FormatDateTime('yyyy-mm-dd hh:mm:ss',FileDateToDateTime(FileGetDate(FHandle)));
  finally
    FileClose(FHandle);
  end;
end;


procedure log(aStr: string);
var
  Ts: TstringList;
begin
  Ts := TstringList.Create;
  try
    If FileExists(ExtractFilePath(ParamStr(0)) + 'Log.txt') then
      Ts.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Log.txt');
    Ts.Add(FormatDateTime('dd/mm/yy hh:mm:ss', now)+' '+aStr);
    Ts.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Log.txt');
  finally
    FreeAndNil(Ts);
  end;
end;

procedure clearlog;
var
f:textfile;
begin
  assign(f,path+'log.txt');
  rewrite(f);
  closefile(f);
end;

procedure runohmreport;
var
param:string;
begin
  param:='E:ON /K '+path+'OpenHardwareMonitorReport.exe > '+path+'ohmreport.txt  &&exit';
  ShellExecute(0, nil, Pchar('cmd.exe'),Pchar(param),'',SW_HIDE);
  sleep(5000);
  param:='conhost.exe';
  ShellExecute(0, nil, Pchar('taskkill'),Pchar(param),'',SW_HIDE);
end;


end.
