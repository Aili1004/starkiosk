package com.snepo.givv.cardbrowser.util
{
	public class BitUtil
	{
		public static function match ( mask : int, flag : int ) : Boolean
		{
			return ( flag & mask ) != 0;
		}
	}

}