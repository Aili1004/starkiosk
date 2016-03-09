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
		public static var COMPANY_LINX : String = 'Linx';

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
			else if (stage.loaderInfo.url.toLowerCase().indexOf ( "linxkiosk." ) > -1)
				_company = COMPANY_LINX;
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

		public static function get isLinx ( ) : Boolean
		{
			return _company == COMPANY_LINX;
		}

		public static function get isDevelopment ( ) : Boolean
		{
			return _isDevelopment;
		}

		public static function get font( ) : Font
		{
			/*if (isLinx)
				return new GothamMedium();
			else
				return new Museo500();*/
				return new VAGRounded();
		}

		public static function get buttonFont( ) : Font
		{
			/*if (isLinx)
				return new GothamMedium();
			else
				return new VAGRounded();*/
				return new VAGRounded();
		}

		public static function get blueButtonColor( ) : int
		{
			if (isLinx)
				return 0x65A8BE;
			else
				return 0x169CD4;
		}

		public static function get blueButtonFooterColor( ) : int
		{
			if (isLinx)
				return 0xFFFFFF;
			else
				return 0x1D3265;
		}

		public static function get blueButtonSelectColor( ) : int
		{
			if (isLinx)
				return 0x8AA929; //0xA1DDB7;
			else
				return 0x169CD4;
		}

		public static function get blueButtonSelectText( ) : String
		{
			if (isLinx)
				return "PURCHASE";
			else
				return "SELECT";
		}

		public static function get yellowButtonColor( ) : int
		{
			if (isLinx)
				return 0x717171;
			else
				return 0xFFD435;
		}

		public static function get yellowButtonMiddleColor( ) : int
		{
			if (isLinx)
				return 0xFFFFFF;
			else
				return 0x7E2013;
		}

		public static function get yellowButtonFooterColor( ) : int
		{
			if (isLinx)
				return 0xFFFFFF;
			else
				return 0xA42321;
		}

		public static function get yellowButtonSelectColor( ) : int
		{
			if (isLinx)
				return 0x8AA929; //0xA1DDB7;
			else
				return 0xFFD435;
		}

		public static function get yellowButtonSelectText( ) : String
		{
			if (isLinx)
				return "RELOAD";
			else
				return "SELECT";
		}

		public static function get homeButtonMiddleTextY( ) : int
		{
			if (isLinx)
				return 250;
			else
				return 225;
		}

		public static function get selectButtonCorner( ) : int
		{
			if (isLinx)
				return 70;
			else
				return 10;
		}

		public static function get selectButtonFontSize( ) : int
		{
			if (isLinx)
				return 24;
			else
				return 38;
		}

		public static function get selectButtonFontLetterSpacing( ) : int
		{
			if (isLinx)
				return 5;
			else
				return 0;
		}

		public static function get forwardButtonColor( ) : int
		{
			if (isLinx)
				return 0x6c8e17; //0xA1DDB7
			else
				return 0x6c8e17;
		}

		public static function get chooseScreenInstructionText( ) : String
		{
			if (isLinx)
				return '';
			else
				/*return 'Touch Card To Select'*/
				return '';
		}

		public static function get overlayTextColor( ) : int
		{
			if (isLinx)
				return 0xffffff;
			else
				return 0x000000;
		}

		public static function get hostAddress( ) : String
		{
			if (isLinx)
				return "https://cms.linxkiosk.com";
			else
				return "https://cms.givvkiosk.com";
		}

		public static function get dropboxPath( ) : String
		{
			// Build path
			var rootDirName : String = null;
			if (isLinx)
				rootDirName = "linx-kiosk-cms";
			else
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
			if (isLinx)
				return 'CASH';
			else
				return 'NOTES'
		}

		public static function get noteDenominations( ) : Array
		{
			if (isLinx)
				return [5, 10, 20, 50, 100];
			else
				return [5, 10, 20, 50, 100];
		}

		public static function get printingScreenPrompt( ) : String
		{
			if (isLinx)
				return "Loading Your Linx Card";
			else
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
