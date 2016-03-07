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
	
	public class HorizontalLayoutStrategy extends LayoutStrategy implements ILayoutStrategy
	{

		protected var fillVertically : Boolean = true;
		protected var animated : Boolean = false;

		public function HorizontalLayoutStrategy ( fillVertically : Boolean = true, animated : Boolean = false, size : Point = null )
		{
			if ( !size ) size = new Point ( 100, 100 );
			
			super ( size.x, size.y );
			
			this.fillVertically = fillVertically;
			this.animated = animated;
		}

		override public function layout ( target : Container, animated : Boolean = true, size : Point = null ) : void
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
						child.x = last.x + last.width + target.horizontalSpacing;
					}
				
					if ( fillVertically ) child.height = target.height - target.paddingTop - target.paddingBottom;
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

						var newX : Number = lastX + last.width + target.horizontalSpacing;

						TweenMax.to ( child, 0.5, { x : newX, y : lastY, ease : Quint.easeInOut } );

						lastX = newX;
					}

					if ( fillVertically ) child.height = target.height - target.paddingTop - target.paddingBottom;
				}
			}
		}

	}
}

