unit downVideaCesky;
{$INCLUDE 'ytd.inc'}
{$DEFINE SUBTITLES}

interface

uses
  SysUtils, Classes,
  PCRE, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_VideaCesky = class(THttpDownloader)
    private
    protected
      YouTubeIDRegExp: IRegEx;
      {$IFDEF SUBTITLES}
      SubtitlesRegExp: IRegEx;
      {$ENDIF}
    protected
      function GetMovieInfoUrl: string; override;
    public
      class function Provider: string; override;
      class function UrlRegExp: string; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
    end;

implementation

uses
  uDownloadClassifier,
  uMessages;

// http://www.videacesky.cz/serialy/upoutavka-na-treti-radu-the-guild
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*videacesky\.cz/[^/]+/';
  URLREGEXP_ID =        '[^/?&]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_EXTRACT_TITLE = '<title>(?P<TITLE>[^<]*?)\s*-\s*Videa\s*�esky';
  REGEXP_EXTRACT_YOUTUBE_ID = '<param\s+name="flashvars"\s+value="file=https?://www\.youtube\.com/watch\?v=(?P<YOUTUBEID>[^&"]+)';
  {$DEFINE SUBTITLES}
  REGEXP_EXTRACT_SUBTITLES = '<param\s+name="flashvars"\s+value="[^"]*&amp;captions.file=(?P<SUBTITLES>[^&"]+)';
  {$ENDIF}

{ TDownloader_VideaCesky }

class function TDownloader_VideaCesky.Provider: string;
begin
  Result := 'VideaCesky.cz';
end;

class function TDownloader_VideaCesky.UrlRegExp: string;
begin
  Result := URLREGEXP_BEFORE_ID + '(?P<' + MovieIDParamName + '>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID;
end;

constructor TDownloader_VideaCesky.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  SetInfoPageEncoding(peUTF8);
  MovieTitleRegExp := RegExCreate(REGEXP_EXTRACT_TITLE, [rcoIgnoreCase, rcoSingleLine]);
  YouTubeIDRegExp := RegExCreate(REGEXP_EXTRACT_YOUTUBE_ID, [rcoIgnoreCase, rcoSingleLine]);
  {$DEFINE SUBTITLES}
  SubtitlesRegExp := RegExCreate(REGEXP_EXTRACT_SUBTITLES, [rcoIgnoreCase, rcoSingleLine]);
  {$ENDIF}
end;

destructor TDownloader_VideaCesky.Destroy;
begin
  MovieTitleRegExp := nil;
  YouTubeIDRegExp := nil;
  {$DEFINE SUBTITLES}
  SubtitlesRegExp := nil;
  {$ENDIF}
  inherited;
end;

function TDownloader_VideaCesky.GetMovieInfoUrl: string;
begin
  Result := 'http://www.videacesky.cz/dummy/' + MovieID;
end;

initialization
  RegisterDownloader(TDownloader_VideaCesky);

end.
