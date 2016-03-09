package com.snepo.givv.cardbrowser.view.controls
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;
	
	import com.greensock.easing.*;
	import com.greensock.*;
	
	import flash.display.*;
	import flash.filters.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.text.*;
		
	public class ImageButton extends Component
	{

		protected var content : DisplayObject;
		protected var _preserveAspectRatio : Boolean = true;
		protected var _heightBias : Boolean = false;
		protected var _aspectRatio : Number = 1;

		protected var _selected : Boolean = false;

		public function ImageButton ( ) 
		{
			super ( );

			buttonMode = true;
		}		

		override protected function render ( ) : void
		{
			if ( data.beforeProps ) applyItemProperties ( data.beforeProps );

			addChild ( ( content = new data.ImageClass() ) as DisplayObject );

			_heightBias = content.height > content.width;

			if ( _heightBias )
			{
				_aspectRatio = content.height / content.width;
			}else
			{
				_aspectRatio = content.width / content.height;
			}

			if ( data.afterProps ) applyItemProperties ( data.afterProps );

			_width = content.width;
			_height = content.height;
			
			invalidate();
		}

		public function set selected ( s : Boolean ) : void
		{
			_selected = s;
			applySelection();
		}

		public function get selected ( ) : Boolean
		{
			return _selected;
		}

		protected function applySelection ( ) : void
		{
		
		}

		public function set preserveAspectRatio ( p : Boolean ) : void
		{
			_preserveAspectRatio = p;
			invalidate();
		}

		public function get preserveAspectRatio ( ) : Boolean
		{
			return _preserveAspectRatio;
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();

			if ( !content ) return;

			if ( preserveAspectRatio )
			{
				if ( !_heightBias )
				{
					content.height = height;
					content.width = height * _aspectRatio;
				}else
				{
					content.width = width;
					content.height = height * _aspectRatio;
				}
			}else
			{
				content.width = width;
				content.height = height;		
			}

			content.x = width / 2 - content.width / 2;
			content.y = height / 2 - content.height / 2;

			trace ( content.height, height );
		}

		protected function applyItemProperties ( props : Object ) : void
		{
			for ( var i : String in props )
			{
				try
				{
					this[i] = props[i];
				}catch ( e : Error )
				{
					trace ( "Error setting component property '" + i + "' on " + this );
				}
			}
		}

	}
}
