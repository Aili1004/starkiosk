package com.snepo.givv.cardbrowser.util
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.text.*;
	
	public class FontUtil
	{
		public static function applyTextFormat ( field : TextField, keys : Object ) : void
		{
			var tf : TextFormat = field.getTextFormat();
			
			for ( var i : String in keys )
			{
				try
				{
					tf[i] = keys[i]
				}catch ( e : Error )
				{
					
				}
			}
			
			field.defaultTextFormat = tf;
			field.setTextFormat ( tf );
		}
		
		public static function applyProperties ( field : TextField, keys : Object ) : void
		{
			for ( var i : String in keys )
			{
				try
				{
					field[i] = keys[i]
				}catch ( e : Error )
				{
					
				}
			}
		}
	}
}