package com.snepo.givv.cardbrowser.view.core
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	public class FillLayoutStrategy extends LayoutStrategy implements ILayoutStrategy
	{

		public function FillLayoutStrategy ( baseWidth : Number = 100, baseHeight : Number = 100 )
		{
			super( baseWidth, baseHeight );
		}

		override public function layout ( target : Container, animated : Boolean = true, size : Point = null ) : void
		{
			var headerAllowance : Number = 0;
			
			var maximumWidth : Number = target.width - target.paddingLeft - target.paddingRight;
			var maximumHeight : Number = target.height - target.paddingTop - target.paddingBottom - headerAllowance;
			
			var perWidth : Number = maximumWidth;
			var perHeight : Number = maximumHeight;
						
			var i : int;
			var child : DisplayObject, last : DisplayObject;
			
			for ( i = 0; i < target.contentChildren.length; i++ )
			{
				child = target.contentChildren[i] as DisplayObject;
				child.width = perWidth;
				child.height = perHeight;
			}
		}

	}
}