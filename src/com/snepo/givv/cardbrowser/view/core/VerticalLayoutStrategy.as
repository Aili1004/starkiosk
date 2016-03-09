package com.snepo.givv.cardbrowser.view.core
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.greensock.easing.*;
	import com.greensock.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	public class VerticalLayoutStrategy extends LayoutStrategy implements ILayoutStrategy
	{
		
		public var fillHorizontally : Boolean = false;
		public var animated : Boolean = false;
		
		public function VerticalLayoutStrategy ( fillHorizontally : Boolean = false, animated : Boolean = false, size : Point = null ) 
		{
			if ( !size ) size = new Point ( 100, 100 );
			
			super ( size.x, size.y );
			
			this.fillHorizontally = fillHorizontally;
			this.animated = animated;
		}
		
		override public function layout ( target : Container, animated : Boolean = false, size : Point = null ) : void
		{
			animated = this.animated;
			
			var i : int;
			var child : DisplayObject;
			var last : DisplayObject;
			
			if ( !animated )
			{			
				for ( i = 0; i < target.contentChildren.length; i++ )
				{
					child = target.contentChildren[i] as DisplayObject;
					child.x = 0;
					child.y = 0;
				
					if ( i > 0 )
					{
						last = target.contentChildren[i-1] as DisplayObject;
						child.y = last.y + last.height + target.verticalSpacing;
					}
				
					if ( fillHorizontally ) child.width = target.width - target.paddingLeft - target.paddingRight;
				}
			}else
			{
				var lastX : Number = 0;
				var lastY : Number = 0;
				
				for ( i = 0; i < target.contentChildren.length; i++ )
				{
					child = target.contentChildren[i] as DisplayObject;
					
					TweenMax.to ( child, 0.5, { x : lastX, y : lastY, ease : Quint.easeInOut } );
				
					if ( i > 0 )
					{
						last = target.contentChildren[i-1] as DisplayObject;
						
						var newY : Number = lastY + last.height + target.verticalSpacing;
						
						TweenMax.to ( child, 0.5, { x : lastX, y : newY, ease : Quint.easeInOut } );
						
						lastY = newY;
					}
				
					if ( fillHorizontally ) child.width = target.width - target.paddingLeft - target.paddingRight;
				}
			}
		}

	}
}