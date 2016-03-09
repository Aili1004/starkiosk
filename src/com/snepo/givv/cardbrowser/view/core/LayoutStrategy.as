package com.snepo.givv.cardbrowser.view.core
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.*;

	public class LayoutStrategy implements ILayoutStrategy
	{
		public var baseWidth : Number = 100;
		public var baseHeight : Number = 100;
		
		public function LayoutStrategy ( baseWidth : Number, baseHeight : Number )
		{
			super();
			
			this.baseWidth  = baseWidth;
			this.baseHeight = baseHeight;
		}
				
		public function layout ( target : Container, animated : Boolean = true, size : Point = null ) : void
		{
			if ( size ) size = new Point ( baseWidth, baseHeight );
		}
	}
}