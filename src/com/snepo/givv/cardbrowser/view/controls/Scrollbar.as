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
	import flash.events.*;
	import flash.geom.*;
	
	public class Scrollbar extends Component
	{
		
		public static const VERTICAL 	: String = "Scrollbar.VERTICAL";
		public static const HORIZONTAL 	: String = "Scrollbar.HORIZONTAL";
		
		protected var _value : Number = 0;
		protected var dragging : Boolean = false;
		protected var touchPoint : Point = new Point();
		
		protected var _orientation : String = VERTICAL;
		
		public function Scrollbar()
		{
			super();
		}
		
		public function set orientation ( s : String ) : void
		{
			this._orientation = s;
			this.applyOrientation();
		}
		
		public function get orientation ( ) : String
		{
			return this._orientation;
		}
		
		protected function applyOrientation ( ) : void
		{
			switch ( orientation )
			{
				case HORIZONTAL : 
				{
					setSize ( height, width );
					break;
				}
				
				default :
				case VERTICAL :
				{
					setSize ( height, width );
					break;
				}
				
			}
			
			invalidate();
			silentValue = value;
		}
		
		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );
			
			thumb.buttonMode = true;
			thumb.mouseChildren = false;

			thumb.addEventListener ( MouseEvent.MOUSE_DOWN, startDragging );
			stage.addEventListener ( MouseEvent.MOUSE_UP, stopDragging );
			
			track.addEventListener ( MouseEvent.MOUSE_DOWN, slideToValue );
		}
		
		protected function slideToValue ( evt : MouseEvent ) : void
		{
			var ratio : Number;
			
			if ( orientation == VERTICAL )
			{
				ratio = this.mouseY / track.height;
			}else
			{
				ratio = this.mouseX / track.width;
			}
			
			TweenMax.to ( this, 0.6, { silentValue : ratio, ease : Quint.easeOut } );

			dispatchEvent ( new ScrollEvent ( ScrollEvent.SNAP, ratio ) );
		}
		
		
		protected function startDragging ( evt : MouseEvent ) : void
		{
			touchPoint = new Point ( thumb.mouseX, thumb.mouseY );
			addEventListener ( Event.ENTER_FRAME, handleDragging );
			
			dragging = true;
		}
		
		protected function stopDragging ( evt : MouseEvent ) : void
		{
			var wasDragging : Boolean = dragging;
			
			removeEventListener ( Event.ENTER_FRAME, handleDragging );
			
			dragging = false;
		}
		
		protected function handleDragging ( evt : Event ) : void
		{
			var ratio : Number;
			
			if ( orientation == HORIZONTAL )
			{
				ratio = ( this.mouseX ) / ( track.width );
				value = ratio;
			}else
			{
				ratio = ( this.mouseY ) / ( track.height );
				value = ratio;
			}
		}
		
		public function set value ( v : Number ) : void
		{
			if ( v < 0 ) v = 0;
			if ( v > 1 ) v = 1;
			
			var changed : Boolean = value != v;
			
			this._value = v;
			this.applyValue( !changed );
		}
		
		public function get value ( ) : Number
		{
			return this._value;
		}
		
		public function set silentValue ( v : Number ) : void
		{
			_value = v;
			this.applyValue( true );
		}
		
		public function get silentValue ( ) : Number
		{
			return _value;
		}
		
		protected function applyValue ( silent : Boolean = false ) : void
		{
			var oldValue : Number = value;
			
			if ( orientation == HORIZONTAL )
			{
				applyValueHorizontal();
			}else
			{
				applyValueVertical();
			}
			
			
			if ( !silent ) dispatchEvent ( new ScrollEvent ( ScrollEvent.SCROLL ) );
		}
		
		protected function applyValueHorizontal ( ) : void
		{
			thumb.x = 2 + value * ( ( track.width + 6 ) - thumb.width );
		}

		protected function applyValueVertical ( ) : void
		{
			thumb.y = 2 + value * ( ( track.height - 4 ) - thumb.height );
		}
		
		override protected function invalidate ( ) : void
		{
			// common invalidation points.
			
			if ( orientation == HORIZONTAL )
			{
				invalidateHorizontal();
			}else
			{
				invalidateVertical();
			}
		}
		
		protected function invalidateVertical ( ) : void
		{
			track.height = height;
			track.width = width;

			thumb.x = 2;
			thumb.width = 24;
			thumb.height = 76;
		}
		
		protected function invalidateHorizontal() : void
		{
			track.width = width;
			track.height = height;
			
			thumb.y = 2;
			thumb.width = 76;
			thumb.height = 24;
		}

	}
}