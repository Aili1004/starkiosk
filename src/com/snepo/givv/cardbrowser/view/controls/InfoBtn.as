package com.snepo.givv.cardbrowser.view.controls
{
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


	public class InfoBtn extends Component
	{
		protected var _leftImageHolder : Sprite;
		protected var _leftImageMask : Sprite;
		protected var _leftImage : Bitmap;

		protected var _rightImageHolder : Sprite;
		protected var _rightImageMask : Sprite;
		protected var _rightImage : Bitmap;

		protected var _shadow : DropShadowFilter;
		protected var _icon : DisplayObject;

		public var buttonCount = 0;

		public function InfoBtn()
		{
			_shadow = new DropShadowFilter ( 5, 45, 0x000000, 0.5, 10, 10, 1, 3 )

			super();
		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			addChild ( _leftImageHolder = new Sprite() );
			addChild ( _leftImageMask = new Sprite() );
			addChild ( _rightImageHolder = new Sprite() );
			addChild ( _rightImageMask = new Sprite() );
		}

		public function set icon ( i : DisplayObject ) : void
		{
			if ( icon ) DisplayUtil.remove ( icon );
			if ( i ) addChild ( _icon = i );
			invalidate();
		}

		public function get icon ( ) : DisplayObject
		{
			return _icon;
		}

		public function set cardImages ( cards : Array ) : void
		{
			var g : Graphics;
			var imageScale : Number;

			if (cards.length == 1 || buttonCount == 1)
				imageScale = 0.6;
			else
				imageScale = 0.45;

			var xOffset : int;
			if (buttonCount == 1 && cards.length >=2)
				xOffset = 65;
			else
				xOffset = 10;

			if (cards.length >= 1)
			{
				// display left card image
				_leftImageHolder.addChild ( _leftImage = new Bitmap ( ImageCache.getInstance().getImage ( cards[0].id, imageScale ), PixelSnapping.AUTO, true ) );
				_leftImageHolder.filters = [_shadow];
				_leftImageHolder.y = 100;
				_leftImageHolder.x = (width/2) - (_leftImage.width/2) - xOffset;
				_leftImageHolder.rotation = -10
				DisplayUtil.smooth ( _leftImage );
				g = _leftImageMask.graphics;
				g.clear();
				g.beginFill ( 0xFF0000, 0.5 );
				g.drawRoundRectComplex ( 0, 0, _leftImage.width, _leftImage.height, 10, 10, 10, 10 );
				g.endFill();
				_leftImageMask.x = _leftImageHolder.x;
				_leftImageMask.y = _leftImageHolder.y;
				_leftImageMask.rotation = _leftImageHolder.rotation
				_leftImageHolder.mask = _leftImageMask;
			}

			if (cards.length >= 2)
			{
				// display right card image
				_rightImageHolder.addChild ( _rightImage = new Bitmap ( ImageCache.getInstance().getImage ( cards[1].id, imageScale ), PixelSnapping.AUTO, true ) );
				_rightImageHolder.filters = [_shadow];
				_rightImageHolder.y = 70;
				_rightImageHolder.x = (width + xOffset) - _rightImageHolder.width;
				_rightImageHolder.rotation = 12
				DisplayUtil.smooth ( _rightImage );
				g = _rightImageMask.graphics;
				g.clear();
				g.beginFill ( 0xFF0000, 0.5 );
				g.drawRoundRectComplex ( 0, 0, _rightImage.width, _rightImage.height, 10, 10, 10, 10 );
				g.endFill();
				_rightImageMask.x = _rightImageHolder.x;
				_rightImageMask.y = _rightImageHolder.y;
				_rightImageMask.rotation = _rightImageHolder.rotation
				_rightImageHolder.mask = _rightImageMask;

				// reposition left card
				_leftImageHolder.x = _leftImageMask.x = -xOffset;
			}
			invalidate();
		}

		public function set title ( title : String ) : void
		{
			titleField.text = title;
		}

		public function set description ( description : String ) : void
		{
			middleField.text = description;
		}

		public function set footer ( footer : String ) : void
		{
			if (footer.length == 0)
				middleField.y = 250;
			else
				middleField.y = Environment.homeButtonMiddleTextY;
			footerField.text = footer;
		}

		public function set textFieldsX ( x : int ) : void
		{
			titleField.x = middleField.x = footerField.x = x;
		}

		public function set textFieldsWidth ( width : int ) : void
		{
			titleField.width = middleField.width = footerField.width = width;
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();

			if ( icon )
			{
				icon.x = width / 2 - icon.width / 2;
				icon.y = height / 3 - icon.height / 2;
			}
		}
	}
}