package com.snepo.givv.cardbrowser.util
{
	import flash.utils.ByteArray;

	public class ObjectUtil
	{
		public static function clone ( object : Object ) : Object
		{
			var ba : ByteArray = new ByteArray();
				ba.writeObject ( object );
				ba.position = 0;

			return ba.readObject();
		}
	}
}