package com.snepo.givv.cardbrowser.view.core
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	public class GridFlowLayoutStrategy extends LayoutStrategy implements ILayoutStrategy
	{
		
		public function GridFlowLayoutStrategy ( baseWidth : Number = 100, baseHeight : Number = 100 )
		{
			super( baseWidth, baseHeight );
		}

		override public function layout ( target : Container, animated : Boolean = true, size : Point = null ) : void
		{
			var i : int;
			var child : DisplayObject, last : DisplayObject;
			
			var startX : Number = 0;
			var startY : Number = 0;
			var lastLargestHeight : Number = 0;
						
			for ( i = 0; i < target.contentChildren.length; i++ )
			{
				child = target.contentChildren[i] as DisplayObject;
				child.x = startX;
				child.y = startY;
				
				if ( i > 0 )
				{
					last = target.contentChildren[i-1] as DisplayObject;
					lastLargestHeight = last.height;

					if ( i > 1 && target.contentChildren[i-2].height > lastLargestHeight && last.width < 120 ) lastLargestHeight = target.contentChildren[i-2].height;
					
					var nextX : Number = last.x + last.width + target.horizontalSpacing;
					if ( nextX + child.width > target.width )
					{
						startX = 0;
						startY += ( lastLargestHeight + target.verticalSpacing );
					}else
					{
						startX = nextX;
					}
					
					child.x = startX;
					child.y = startY;
				}
			}
			
		}

	}
}