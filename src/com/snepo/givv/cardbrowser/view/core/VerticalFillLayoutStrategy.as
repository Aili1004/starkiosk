package com.snepo.givv.cardbrowser.view.core
{	
	/**
	* @author Andrew Wright
	*/
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	public class VerticalFillLayoutStrategy extends LayoutStrategy implements ILayoutStrategy
	{

		public function VerticalFillLayoutStrategy ( baseWidth : Number = 100, baseHeight : Number = 100 )
		{
			super( baseWidth, baseHeight );
		}

		override public function layout ( target : Container, animated : Boolean = true, size : Point = null ) : void
		{
			var headerAllowance : Number = 0;
			
			var maximumWidth : Number = target.width - target.paddingLeft - target.paddingRight;
			var maximumHeight : Number = target.height - target.paddingTop - target.paddingBottom - headerAllowance - ( ( target.contentChildren.length - 1 ) * target.verticalSpacing );
			
			var perHeight : Number = ( maximumHeight / target.contentChildren.length );
			var perWidth : Number = maximumWidth;
			
			var i : int;
			var child : DisplayObject, last : DisplayObject;
			
			for ( i = 0; i < target.contentChildren.length; i++ )
			{
				child = target.contentChildren[i] as DisplayObject;
				child.width = perWidth
				child.height = perHeight;
			}
			
			for ( i = 0; i < target.contentChildren.length; i++ )
			{
				child = target.contentChildren[i] as DisplayObject;
				
				if ( i > 0 )
				{
					last = target.contentChildren[i-1] as DisplayObject;
					child.y = last.y + last.height + target.verticalSpacing;
				}
			}
		}

	}
}