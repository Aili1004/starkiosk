package com.snepo.givv.cardbrowser.services
{

	public class DataCardError
	{
		public static const NO_ERROR   : int = -1;
		public static const NO_PRINTER : int = 0x0;
		public static const INVALID_PRINTER : int = 0x1;
		public static const NO_HANDLE : int = 0x2;
		public static const INTERACTIVE_MODE_FAILED : int = 0x3;
		public static const START_DOC_FAILED : int = 0x4;
		public static const START_PAGE_FAILED : int = 0x5;
		public static const IMAGE_NOT_FOUND : int = 0x6;
		public static const FEED_CARD_FAILED : int = 0x7;
		public static const TRACK_READ_FAILED : int = 0x8;
		public static const PRINT_FAILED : int = 0x9;
		public static const END_PAGE_FAILED : int = 0xA;
		public static const END_DOC_FAILED : int = 0xB;
		public static const CANT_SET_MAGSTRIPE : int = 0xC;
		public static const INVALID_PARAMETERS : int = 0xD;
		public static const TRACK_WRITE_FAILED : int = 0xE;

		public static function toString( error : int ) : String
		{
			switch(error)
			{
				case NO_ERROR:
					return "No Error";
				case NO_PRINTER:
					return "No Printer";
				case INVALID_PRINTER:
					return "Invalid Printer";
				case NO_HANDLE:
					return "No Handle";
				case INTERACTIVE_MODE_FAILED:
					return "Interactive Mode Failed";
				case START_DOC_FAILED:
					return "Start Document Failed";
				case START_PAGE_FAILED:
					return "Start Page Failed";
				case IMAGE_NOT_FOUND:
					return "Image Not Found";
				case FEED_CARD_FAILED:
					return "Feed Card Failed";
				case TRACK_READ_FAILED:
					return "Card Read Failed";
				case PRINT_FAILED:
					return "Print Failed";
				case END_PAGE_FAILED:
					return "End Page Failed";
				case END_DOC_FAILED:
					return "End Document Failed";
				case CANT_SET_MAGSTRIPE:
					return "Set Magstripe Failed";
				case INVALID_PARAMETERS:
					return "Invalid Parameters";
				case TRACK_WRITE_FAILED:
					return "Card Write Failed";
				default:
					return "Unknown Error";
			}
		}
	}
}