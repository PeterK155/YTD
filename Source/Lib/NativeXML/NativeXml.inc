{ unit NativeXml.inc

  Nativexml a small-footprint implementation to read and write XML documents
  natively from Delpi code. NativeXml has very fast parsing speeds.

  Author: Nils Haeck M.Sc.
  Copyright (c) 2007 - 2010 Simdesign B.V.

  It is NOT allowed under ANY circumstances to publish, alter or copy this code
  without accepting the license conditions in accompanying LICENSE.txt
  first!

  This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
  ANY KIND, either express or implied.

  Please visit http://www.simdesign.nl/xml.html for more information.
}
// Delphi and BCB versions

// Freepascal (MK)
{$ifdef FPC}
  {$MODE DELPHI}
  {$define D7UP}
{$endif FPC}
//Delphi 7
{$ifdef VER150}
  {$define D7UP}
{$endif}
//Delphi 8
{$ifdef VER160}
  {$define D7UP}
{$endif}
// Delphi 2005
{$ifdef VER170}
  {$define D7UP}
{$endif}
// Delphi 2006
{$ifdef VER180}
  {$define D7UP}
{$endif}
// Delphi 2007 - NET
{$ifdef VER190}
  {$define D7UP}
{$endif}
// Delphi 2009
{$ifdef VER200}
  {$define D7UP}
  {$define D12UP}
{$endif}
// Delphi 2010
{$ifdef VER210}
  {$define D7UP}
  {$define D12UP}
{$endif}
// Delphi XE
{$ifdef VER220}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
{$endif}
// Delphi XE2
{$ifdef VER230}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
{$endif}
// Delphi XE3
{$ifdef VER240}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
{$endif}
// Delphi XE4
{$ifdef VER250}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
{$endif}
// Delphi XE5
{$ifdef VER260}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
{$endif}
// Delphi XE6
{$ifdef VER270}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
{$endif}
// Delphi XE7
{$ifdef VER280}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
{$endif}
// Delphi XE8
{$ifdef VER290}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
{$endif}
// Delphi 10 Seattle
{$ifdef VER300}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
  {$define D23UP}
{$endif}
// Delphi 10.1 Berlin
{$ifdef VER310}
  {$define D7UP}
  {$define D12UP}
  {$define D15UP}
  {$define D23UP}
{$endif}

// Uncomment to save memory space for large documents if you don't need tags.
// Tags are an additional integer field that can be used by the application.
{$define USETAGS}

// uncomment if you do not want to include the Graphics unit.
{$IFNDEF PEPAK}
{$define USEGRAPHICS}
{$ENDIF}

// uncomment if you do not want line number/position info from the source file
{$define SOURCEPOS}
