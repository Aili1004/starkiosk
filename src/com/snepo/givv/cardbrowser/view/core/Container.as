package com.snepo.givv.cardbrowser.view.core
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.util.*;
	
	import com.greensock.easing.*;
	import com.greensock.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	public class Container extends Component
	{	
		protected var _layoutStrategy : ILayoutStrategy;
		protected var _contentChildren : Array = [];
		protected var _paddingTop : int = 10;
		protected var _paddingLeft : int = 10;
		protected var _paddingRight : int = 10;
		protected var _paddingBottom : int = 10;
		protected var _verticalSpacing : Number = 4;
		protected var _horizontalSpacing : Number = 4;
		protected var _content : Sprite;
		protected var _mask : Sprite;
		protected var _travelDistance : Number = 0;
				
		public var verticalScrollEnabled : Boolean = true;
		public var horizontalScrollEnabled : Boolean = true;		
				
		protected var touchPoint : Point = new Point();
		protected var savedPoint : Point = new Point();
		protected var lastPoint  : Point = new Point();
		protected var dragging   : Boolean = false;
		protected var frameTick	 : int = 0;		
		
		protected var unmasked : Boolean = false;
	
		public function Container()
		{
			_width = 100;
			_height = 100;
			
			super();
			
			_layoutStrategy = null;
		}
		
		override protected function createUI ( ) : void
		{
			super.createUI ();
			
			super.addChild ( _content = new Sprite() );
			super.addChild ( _mask = new Sprite() );
			
			createMask ( );
			
			var constrained : Point = constrainContent ( Number.MAX_VALUE, Number.MAX_VALUE );
				content.x = 0; //constrained.x;
				content.y = 0; //constrained.y;
		}
		
		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );
			
			addEventListener ( MouseEvent.MOUSE_DOWN, startDragging );
			stage.addEventListener ( MouseEvent.MOUSE_UP, stopDragging );
		}
		
		protected function startDragging ( evt : MouseEvent ) : void
		{
			touchPoint = new Point ( stage.mouseX, stage.mouseY );
			savedPoint = new Point ( content.x, content.y );
			lastPoint  = new Point ( stage.mouseX, stage.mouseY );

			_travelDistance = 0;
			
			if ( !requiresDrag ) return;
			
			dragging = true;
			
			addEventListener ( Event.ENTER_FRAME, handleDragging );
		}
		
		public function get requiresDrag ( ) : Boolean
		{
			return requiresVerticalDrag || requiresHorizontalDrag;
		}
		
		public function get requiresVerticalDrag ( ) : Boolean
		{
			if ( !verticalScrollEnabled ) return false;
			return content.height > height;
		}
		
		public function get requiresHorizontalDrag ( ) : Boolean
		{
			if ( !horizontalScrollEnabled ) return false;
			return content.width > width;
		}
		
		protected function stopDragging ( evt : MouseEvent ) : void
		{
			var wasDragging : Boolean = dragging;
			dragging = false;
			
			if ( wasDragging )
			{
				removeEventListener ( Event.ENTER_FRAME, handleDragging );
				
				var velX : Number = ( stage.mouseX - lastPoint.x ) * 0.90;
				var velY : Number = ( stage.mouseY - lastPoint.y ) * 0.90;
				
				var deltaX : Number = stage.mouseX - touchPoint.x;
				var deltaY : Number = stage.mouseY - touchPoint.y;
				
				this._travelDistance = Math.sqrt ( deltaX * deltaX + deltaY * deltaY );
				
				processThrow ( velX, velY );
			}
			
		}
		
		protected function handleDragging ( evt : Event ) : void
		{
			if ( !dragging ) return;

			var deltaX : Number = stage.mouseX - touchPoint.x;
			var deltaY : Number = stage.mouseY - touchPoint.y;
			
			var signX : int = deltaX > 0 ? 1 : -1;
			var signY : int = deltaY > 0 ? 1 : -1;
			
			var progressX : Number = savedPoint.x + deltaX;
			var progressY : Number = savedPoint.y + deltaY;
			
			var constrainedAxes : Object = getConstrainedAxes( progressX, progressY );
			
			var xCoefficient : Number = constrainedAxes.x ? 1 : 1;
			var yCoefficient : Number = constrainedAxes.y ? 1 : 1;
			
			var overhang : Object = getAxisOverhang ( progressX, progressY );
						
			if ( horizontalScrollEnabled ) content.x = savedPoint.x + ( deltaX * xCoefficient ) + ( overhang.x * ( Math.abs ( overhang.x ) / width ) );
			if ( verticalScrollEnabled ) content.y = savedPoint.y + ( deltaY * yCoefficient ) + ( overhang.y * ( Math.abs ( overhang.y ) / height ) );;
			
			if ( ++frameTick % 2 == 0 )
			{
				lastPoint = new Point ( stage.mouseX, stage.mouseY );
				frameTick = 0;
			}
		}
		
		override public function dispose ( ) : void
		{
			for ( var i : int = 0; i < contentChildren.length; i++ )
			{
				var item : DisplayObject = contentChildren[i] as DisplayObject;
				if ( item is Component )
				{
					( item as Component ).dispose();
					( item as Component ).destroy();
				}else
				{
					DisplayUtil.remove ( item );
				}
			}
			
			_contentChildren = [];
		}
		
		protected function createMask ( ) : void
		{
			var g : Graphics = _mask.graphics;
				g.clear();
				g.beginFill ( 0xFFFF00, 1 );
				g.drawRect ( 0, 0, 10, 10 );
				g.endFill();
				
			_content.mask = mask;
		}
		
		public function unmask ( ) : void
		{
			_mask.visible = false;
			_content.mask = null;
			unmasked = true;
		}
		
		public function get contentChildren ( ) : Array
		{
			return _contentChildren;
		}
		
		public function get content ( ) : Sprite
		{
			return _content;
		}

		public function get tapVoided ( ) : Boolean
		{
			return _travelDistance > 4;
		}

		override public function addChild ( i : DisplayObject ) : DisplayObject
		{
			if ( contentChildren.indexOf ( i ) < 0 ) contentChildren.push ( i );
			
			content.addChild ( i );
			invalidate();
			
			return i;
		}
		
		override public function removeChild ( i : DisplayObject ) : DisplayObject
		{
			if ( contentChildren.indexOf ( i ) > -1 ) contentChildren.splice ( contentChildren.indexOf ( i ), 1 );

			content.removeChild ( i );
			invalidate();
			
			return i;
		}
		
		public function addRogueChild ( i : DisplayObject ) : DisplayObject
		{
			return super.addChild ( i );
		}
		
		public function removeRogueChild ( i : DisplayObject ) : DisplayObject
		{
			return super.removeChild ( i );
		}
		
		public function set padding ( p : Number ) : void { _paddingTop = p; _paddingLeft = p; _paddingRight = p; _paddingBottom = p; invalidate() };
		public function set paddingTop ( p : Number ) : void { _paddingTop = p; invalidate() };
		public function set paddingLeft ( p : Number ) : void { _paddingLeft = p; invalidate() };
		public function set paddingRight ( p : Number ) : void { _paddingRight = p; invalidate() };
		public function set paddingBottom ( p : Number ) : void { _paddingBottom = p; invalidate() };
		public function set verticalSpacing ( p : Number ) : void { _verticalSpacing = p; invalidate() };
		public function set horizontalSpacing ( p : Number ) : void { _horizontalSpacing = p; invalidate() };
		
		public function get padding ( ) : Number { return _paddingTop };
		public function get paddingTop ( ) : Number { return _paddingTop };
		public function get paddingLeft ( ) : Number { return _paddingLeft };
		public function get paddingRight ( ) : Number { return _paddingRight };
		public function get paddingBottom ( ) : Number { return _paddingBottom };
		public function get verticalSpacing ( ) : Number { return _verticalSpacing };
		public function get horizontalSpacing ( ) : Number { return _horizontalSpacing };
		
		public function set layoutStrategy ( l : ILayoutStrategy ) : void
		{
			if ( this._layoutStrategy ) this._layoutStrategy = null;
			this._layoutStrategy = l;
			this.invalidate();
		}
		
		public function get layoutStrategy ( ) : ILayoutStrategy
		{
			return this._layoutStrategy;
		}
		
		protected function constrainContent ( fx : Number, fy : Number ) : Point
		{
			var constrained : Point = new Point ( fx, fy );
			
			var widthToUse : Number = content.width;
			var heightToUse : Number = content.height;
			
			if ( fy > paddingTop ) constrained.y = paddingTop;
			if ( fy < -content.height + height - paddingBottom ) constrained.y = -content.height + height - paddingBottom;
			
			if ( fx > paddingLeft ) constrained.x = paddingLeft;
			if ( fx < -content.width + width - paddingRight ) constrained.x = -content.width + width - paddingRight;
			
			return constrained;
			
		}
		
		public function reset ( ) : void
		{
			dispose();
		}
		
		protected function getConstrainedAxes ( xValue : Number = NaN, yValue : Number = NaN ) : Object
		{
			if ( isNaN ( xValue ) ) xValue = content.x;
			if ( isNaN ( yValue ) ) yValue = content.y;
			
			var constrained : Point = constrainContent ( xValue, yValue );
			return { x : constrained.x != xValue, y : constrained.y != yValue };
		}
		
		protected function getAxisOverhang ( xValue : Number = NaN, yValue : Number = NaN ) : Object
		{
			if ( isNaN ( xValue ) ) xValue = content.x;
			if ( isNaN ( yValue ) ) yValue = content.y;
			
			var constrained : Point = constrainContent ( xValue, yValue );
			
			return { x : constrained.x - xValue, y : constrained.y - yValue };
		}

		public function applyConstrain ( ) : void
		{
			var constrained : Point = constrainContent ( content.x, content.y );
			if ( !requiresHorizontalDrag ) constrained.x = paddingLeft;
			if ( !requiresVerticalDrag ) constrained.y = paddingTop;

			var tweenParams : Object = {};
				tweenParams.ease = Back.easeOut;

			if ( horizontalScrollEnabled ) tweenParams.x = constrained.x;
			if ( verticalScrollEnabled ) tweenParams.y = constrained.y;

			TweenMax.to ( content, 0.6, tweenParams );
		}
		
		override protected function invalidate ( ) : void
		{
			super.invalidate();
			
			if ( !_mask ) return;
			
			if ( !content.mask && !unmasked ) content.mask = _mask;
			
			_mask.width = width - paddingLeft - paddingRight;
			_mask.height = height - paddingTop - paddingBottom;
			_mask.x = paddingLeft;
			_mask.y = paddingTop;
			
			if ( layoutStrategy ) layoutStrategy.layout ( this );
		}
		
		protected function processThrow ( velX : Number, velY : Number ) : void
		{
			velX *= 10;
			velY *= 10;
			
			var constrained : Point = constrainContent ( content.x + velX, content.y + velY );
			var tweenParams : Object = {};
				tweenParams.ease = Quint.easeOut;
			
			if ( horizontalScrollEnabled ) tweenParams.x = constrained.x;
			if ( verticalScrollEnabled ) tweenParams.y = constrained.y;
			
			TweenMax.killTweensOf ( content );
			TweenMax.to ( content, 0.8, tweenParams );
			
			dispatchEvent ( new ScrollEvent ( ScrollEvent.THROW, { velX : velX, velY : velY } ) );
			
			
		}

	}
}