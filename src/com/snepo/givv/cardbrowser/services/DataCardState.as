package com.snepo.givv.cardbrowser.services
{
	public class DataCardState
	{
		public static const PREPARING 		: int = 0x0;
		public static const FEEDING   		: int = 0x1;
		public static const READING	  		: int = 0x2;
		public static const READ_SUCCESS  	: int = 0x3;
		public static const PRINTING  		: int = 0x4;
		public static const TIDYING	  		: int = 0x5;
		public static const FINISHED  		: int = 0x6;
	}
}