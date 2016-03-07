package com.snepo.givv.cardbrowser.util
{
	import com.snepo.givv.cardbrowser.view.*;

	import flash.system.*;
	import flash.display.*;
	import flash.text.*;
	import flash.net.*;

	public class Environment
	{
		public static var SERVICE : String = "localhost";
		public static var DEBUG : Boolean = true;
		public static const VERSION : String = "1.7.5";

		public static const WINDOWS : String = "WINDOWS";
		public static const MACOSX  : String = "MACOSX";

		public static var FIRST_USER : Boolean = true;
		public static var DEFAULT_KIOSK_UNIQUE_ID : String = "default_kiosk";
		public static var KIOSK_UNIQUE_ID : String = DEFAULT_KIOSK_UNIQUE_ID;

		public static var COMM_TIMEOUT : int = 30;
		public static var SESSION_TIMEOUT : int = 45;
		public static var SESSION_EXTENSION_TIMEOUT : int = 45;

		public static var COMPANY_GIVV : String = 'GiVV';

		public static var RELEASE_PATH : String = "P:\\givv-frontend\\Release\\";
		public static var RELEASE : String;
		public static var RELEASE_DESCRIPTION : String;

		private static var _company : String = null;
		private static var _operatingSystem : String;
		private static var _isDevelopment : Boolean;

		public static function init ( stage : Stage ) : void
		{
			// Initialise static variables
			if (stage.loaderInfo.url.toLowerCase().indexOf ( "givvkiosk." ) > -1)
				_company = COMPANY_GIVV;
			_operatingSystem = Capabilities.os.toLowerCase().indexOf ( "win" ) > -1 ? WINDOWS : MACOSX;
			_isDevelopment = stage.loaderInfo.url.indexOf ( "/Documents/source/flash/givvkiosk/bin/" ) > -1;
		}

		public static function get operatingSystem ( ) : String
		{
			return _operatingSystem;
		}

		public static function get isWindows ( ) : Boolean
		{
			return operatingSystem == WINDOWS;
		}

		public static function get isMacosx ( ) : Boolean
		{
			return operatingSystem == MACOSX;
		}

		public static function get companyName ( ) : String
		{
			return _company;
		}

		public static function get isGivv ( ) : Boolean
		{
			return _company == COMPANY_GIVV;
		}

		public static function get isDevelopment ( ) : Boolean
		{
			return _isDevelopment;
		}

		public static function get font( ) : Font
		{
			return new Museo500();
		}

		public static function get buttonFont( ) : Font
		{
			return new VAGRounded();
		}

		public static function get blueButtonColor( ) : int
		{
			return 0x169CD4;
		}

		public static function get blueButtonFooterColor( ) : int
		{
			return 0x1D3265;
		}

		public static function get blueButtonSelectColor( ) : int
		{
			return 0x169CD4;
		}

		public static function get blueButtonSelectText( ) : String
		{
			return "SELECT";
		}

		public static function get yellowButtonColor( ) : int
		{
			return 0xFFD435;
		}

		public static function get yellowButtonMiddleColor( ) : int
		{
			return 0x7E2013;
		}

		public static function get yellowButtonFooterColor( ) : int
		{
			return 0xA42321;
		}

		public static function get yellowButtonSelectColor( ) : int
		{
			return 0xFFD435;
		}

		public static function get yellowButtonSelectText( ) : String
		{
			return "SELECT";
		}

		public static function get homeButtonMiddleTextY( ) : int
		{
			return 225;
		}

		public static function get selectButtonCorner( ) : int
		{
			return 10;
		}

		public static function get selectButtonFontSize( ) : int
		{
			return 38;
		}

		public static function get selectButtonFontLetterSpacing( ) : int
		{
			return 0;
		}

		public static function get forwardButtonColor( ) : int
		{
			return 0x6c8e17;
		}

		public static function get chooseScreenInstructionText( ) : String
		{
			return '';
		}

		public static function get overlayTextColor( ) : int
		{
			return 0x000000;
		}

		public static function get hostAddress( ) : String
		{
			return "https://cms.givvkiosk.com";
		}

		public static function get dropboxPath( ) : String
		{
			// Build path
			var rootDirName : String = null;

			rootDirName = "givv-kiosk-cms";

			// Exit now if unknown application name
			if (rootDirName == null)
				return null;

			if (Environment.isWindows)
				return "P:\\" + rootDirName + "\\";
			else
				return rootDirName + "/";
		}

		public static function get noteTitle( ) : String
		{
			return 'NOTES';
		}

		public static function get noteDenominations( ) : Array
		{
			return [5, 10, 20, 50, 100];
		}

		public static function get printingScreenPrompt( ) : String
		{
			return "Printing your gift card";
		}

		public static function forceGC ( ) : void
		{
			try
			{
				new LocalConnection().connect("__GC__");
				new LocalConnection().connect("__GC__");
			}catch ( e : Error )
			{

			}
		}
	}
}
