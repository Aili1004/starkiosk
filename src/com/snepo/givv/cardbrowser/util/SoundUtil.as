package com.snepo.givv.cardbrowser.util
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.media.*;
	import flash.net.*;
	
	public class SoundUtil
	{
		public static function playLibrary ( T : Class ) : SoundChannel
		{
			try
			{
				var instance : Sound = new T() as Sound;
				return instance.play();
			}catch ( e : Error )
			{
				
			}
			
			return null;
		}
	}
}