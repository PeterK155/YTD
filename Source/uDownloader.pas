unit uDownloader;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils,
  HttpSend, synautil;

type
  EDownloaderError = class(Exception);

  TDownloaderProgressEvent = procedure(Sender: TObject; TotalSize, DownloadedSize: int64; var DoAbort: boolean) of object;
  TDownloaderFileNameValidateEvent = procedure(Sender: TObject; var FileName: string; var Valid: boolean) of object;
  TDownloaderMoreUrlsEvent = procedure(Sender: TObject; const Url: string) of object;

  TDownloaderClass = class of TDownloader;
  TDownloader = class
    private
      fPrepared: boolean;
      fName: string;
      fLastErrorMsg: string;
      fOnProgress: TDownloaderProgressEvent;
      fHttp: THttpSend;
      fDestinationPath: string;
      fMovieID: string;
      fFileName: string;
      fOnFileNameValidate: TDownloaderFileNameValidateEvent;
      fOnMoreUrls: TDownloaderMoreUrlsEvent;
    protected
      function GetName: string; virtual;
      procedure SetName(const Value: string); virtual;
      procedure SetPrepared(Value: boolean); virtual;
      procedure SetLastErrorMsg(const Value: string); virtual;
      procedure SetMovieID(const Value: string); virtual;
    protected
      function GetDefaultFileName: string; virtual;
      function GetFileName: string; virtual;
      procedure SetFileName(const Value: string); virtual;
      function GetFileNameExt: string; virtual;
      function GetTotalSize: int64; virtual;
      function GetDownloadedSize: int64; virtual;
      procedure DoProgress; virtual;
      function CreateHttp: THttpSend; virtual;
      function CheckRedirect(Http: THttpSend; var Url: string): boolean; virtual;
      function DownloadPage(Http: THttpSend; Url: string; UsePost: boolean = False): boolean; overload; virtual;
      function DownloadPage(Http: THttpSend; Url: string; out Page: string; UsePost: boolean = False): boolean; overload; virtual;
      function ValidateFileName(var FileName: string): boolean; overload; virtual;
      procedure AddUrlToDownloadList(const Url: string); virtual;
    public
      class function Provider: string; virtual; abstract;
      class function UrlRegExp: string; virtual; abstract;
      class function MovieIDParamName: string; virtual; abstract;
    public
      constructor Create(const AMovieID: string); virtual;
      destructor Destroy; override;
      function Prepare: boolean; virtual; abstract;
      function ValidateFileName: boolean; overload; virtual;
      function Download: boolean; virtual;
      procedure AbortTransfer; virtual;
      {$IFDEF MULTIDOWNLOADS}
      function First: boolean; virtual;
      function Next: boolean; virtual;
      {$ENDIF}
    public
      property Prepared: boolean read fPrepared;
      property Name: string read GetName;
      property FileName: string read GetFileName;
      property LastErrorMsg: string read fLastErrorMsg;
      property TotalSize: int64 read GetTotalSize;
      property DownloadedSize: int64 read GetDownloadedSize;
      property DefaultHttp: THttpSend read fHttp;
    published
      property MovieID: string read fMovieID write SetMovieID;
      property DestinationPath: string read fDestinationPath write fDestinationPath;
      property OnProgress: TDownloaderProgressEvent read fOnProgress write fOnProgress;
      property OnFileNameValidate: TDownloaderFileNameValidateEvent read fOnFileNameValidate write fOnFileNameValidate;
      property OnMoreUrls: TDownloaderMoreUrlsEvent read fOnMoreUrls write fOnMoreUrls;
    end;

implementation

uses
  uStringUtils;
  
{ TDownloader }

constructor TDownloader.Create(const AMovieID: string);
begin
  inherited Create;
  SetLastErrorMsg('');
  SetPrepared(False);
  fHttp := THttpSend.Create;
  fHttp.UserAgent := 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3 (.NET CLR 3.5.30729)';
  MovieID := AMovieID;
end;

destructor TDownloader.Destroy;
begin
  SetPrepared(False);
  FreeAndNil(fHTTP);
  inherited;
end;

procedure TDownloader.SetPrepared(Value: boolean);
begin
  fPrepared := Value;
end;

procedure TDownloader.SetLastErrorMsg(const Value: string);
begin
  fLastErrorMsg := Value;
end;

function TDownloader.GetName: string;
begin
  if Prepared then
    Result := fName
  else
    Raise EDownloaderError.Create('Downloader is not prepared!');
end;

procedure TDownloader.SetName(const Value: string);
begin
  fName := Value;
end;

function StrTr(const Kde, Co, Cim: string): string;
var i, j: integer;
begin
  Result := Kde;
  if Kde <> '' then
    for i := 1 to Length(Co) do
      repeat
        j := Pos(Co[i], Result);
        if j > 0 then
          Result[j] := Cim[i];
      until j <= 0;
end;

function TDownloader.GetDefaultFileName: string;
begin
  Result := {AnsiToOem}(StrTr(Name, '\/:*?"<>|', '--;..''--!') + GetFileNameExt);
  if DestinationPath <> '' then
    Result := IncludeTrailingBackslash(DestinationPath) + Result;
end;

function TDownloader.GetFileName: string;
begin
  if fFileName <> '' then
    Result := fFileName
  else
    Result := GetDefaultFileName;
end;

procedure TDownloader.SetFileName(const Value: string);
begin
  fFileName := Value;
end;

function TDownloader.GetFileNameExt: string;
begin
  Result := '';
end;

function TDownloader.GetTotalSize: int64;
begin
  Result := -1;
end;

function TDownloader.GetDownloadedSize: int64;
begin
  Result := 0;
end;

procedure TDownloader.DoProgress;
var DoAbort: boolean;
begin
  if Assigned(OnProgress) then
    begin
    DoAbort := False;
    OnProgress(Self, TotalSize, DownloadedSize, DoAbort);
    if DoAbort then
      AbortTransfer;
    end;
end;

function TDownloader.Download: boolean;
begin
  SetLastErrorMsg('Can''t download this kind of content.');
  if Prepared then
    Result := False
  else
    Raise EDownloaderError.Create('Downloader is not prepared!');
end;

function TDownloader.CreateHttp: THttpSend;
begin
  Result := THttpSend.Create;
  Result.UserAgent := DefaultHttp.UserAgent;
  Result.ProxyHost := DefaultHttp.ProxyHost;
  Result.ProxyPort := DefaultHttp.ProxyPort;
  Result.ProxyUser := DefaultHttp.ProxyUser;
  Result.ProxyPass := DefaultHttp.ProxyPass;
end;

function TDownloader.CheckRedirect(Http: THttpSend; var Url: string): boolean;
const Location = 'Location:';
var i: integer;
    Redirect: string;
    RedirProtocol, RedirUser, RedirPass, RedirHost, RedirPort, RedirPath, RedirPara: string;
    OldURL, UrlProtocol, UrlUser, UrlPass, UrlHost, UrlPort, UrlPath, UrlPara: string;
begin
  Result := False;
  if (Http.ResultCode >= 300) and (Http.ResultCode < 400) then
    for i := 0 to Pred(Http.Headers.Count) do
      if AnsiCompareText(Location, Copy(Http.Headers[i], 1, Length(Location))) = 0 then
        begin
        OldUrl := Url;
        Redirect := Trim(Copy(Http.Headers[i], Length(Location)+1, MaxInt));
        ParseUrl(Redirect, RedirProtocol, RedirUser, RedirPass, RedirHost, RedirPort, RedirPath, RedirPara);
        if (RedirHost = '') or (AnsiCompareText(RedirHost, 'localhost') = 0) then
          begin
          ParseUrl(Url, UrlProtocol, UrlUser, UrlPass, UrlHost, UrlPort, UrlPath, UrlPara);
          if RedirProtocol = '' then
            RedirProtocol := UrlProtocol;
          if RedirUser = '' then
            RedirUser := UrlUser;
          if RedirPass = '' then
            RedirPass := UrlPass;
          if (RedirHost = '') or (AnsiCompareText(RedirHost, 'localhost') = 0) then
            RedirHost := UrlHost;
          if RedirPort = '' then
            RedirPort := UrlPort;
          Url := RedirProtocol + '://';
          if RedirUser <> '' then
            begin
            Url := Url + RedirUser;
            if RedirPass <> '' then
              Url := Url + ':' + RedirPass;
            Url := Url + '@';
            end;
          Url := Url + RedirHost + ':' + RedirPort + RedirPath;
          if RedirPara <> '' then
            Url := Url + '?' + RedirPara ;
          end
        else
          Url := Redirect;
        Result := Url <> OldUrl;
        Break;
        end;
end;

function TDownloader.DownloadPage(Http: THttpSend; Url: string; UsePost: boolean): boolean;
var Method: string;
begin
  repeat
    Http.Clear;
    if UsePost then
      Method := 'POST'
    else
      Method := 'GET';
    Result := Http.HttpMethod(Method, Url);
  until (not Result) or (not CheckRedirect(Http, Url));
end;

function TDownloader.DownloadPage(Http: THttpSend; Url: string; out Page: string; UsePost: boolean): boolean;
begin
  Page := '';
  Result := DownloadPage(Http, Url, UsePost);
  if Result then
    begin
    SetLength(Page, Http.Document.Size);
    Http.Document.Seek(0, 0);
    Http.Document.ReadBuffer(Page[1], Http.Document.Size);
    end;
end;

procedure TDownloader.AbortTransfer;
begin
end;

{$IFDEF MULTIDOWNLOADS}
function TDownloader.First: boolean;
begin
  Result := Prepared;
end;

function TDownloader.Next: boolean;
begin
  Result := False;
end;
{$ENDIF}

procedure TDownloader.SetMovieID(const Value: string);
begin
  fMovieID := Value;
  SetPrepared(False);
end;

function TDownloader.ValidateFileName(var FileName: string): boolean;
begin
  Result := (FileName <> '') and (not FileExists(FileName));
  if Assigned(OnFileNameValidate) then
    OnFileNameValidate(Self, FileName, Result);
end;

function TDownloader.ValidateFileName: boolean;
var FN: string;
begin
  Result := False;
  if Prepared then
    begin
    SetFileName('');
    FN := GetFileName;
    Result := ValidateFileName(FN);
    if Result then
      SetFileName(FN)
    else
      SetLastErrorMsg(Format('Forbidden to download to file "%s".', [FN]));
    end;
end;

procedure TDownloader.AddUrlToDownloadList(const Url: string);
begin
  if Assigned(OnMoreUrls) then
    OnMoreUrls(Self, Url);
end;

end.
