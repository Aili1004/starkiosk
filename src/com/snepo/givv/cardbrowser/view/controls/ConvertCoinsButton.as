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

	public class ConvertCoinsButton extends Component
	{
		public static const DEFAULT_OFFCOLOR : uint = 0x0E447F; // dark blue  0xADAFB2; //grey    //
		public static const DEFAULT_ONCOLOR : uint = 0x169CD4; // light blue

		public var offFillColor : uint = DEFAULT_OFFCOLOR;
		public var onFillColor : uint = DEFAULT_ONCOLOR;

		protected var _label : String = "";
		protected var _valid : Boolean = true;
		protected var subLabelField : TextField;
		public var helpIcon : MovieClip;
		protected var _bigIcon : MovieClip;
		protected var _useHtml : Boolean = false;

		protected var textFormat : TextFormat;
		protected var iconSize : Point = new Point();

		public function ConvertCoinsButton ( )
		{
			super();

			this.filters = [ backing.filters[0] ];
			backing.filters = [];

			buttonMode = true;
			mouseChildren = true;
			highlight.mouseEnabled = false;
			labelField.mouseEnabled = false;
			TweenMax.to ( backing, 0, { tint : offFillColor } );
		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			labelField.mouseEnabled = false;

			addChild ( helpIcon = new HelpIcon() );
			helpIcon.buttonMode = true;
			helpIcon.mouseChildren = false;

			backing.addEventListener ( MouseEvent.MOUSE_DOWN, playTouchAnimation );
		}

		protected function playTouchAnimation ( evt : MouseEvent ) : void
		{
			SoundUtil.playLibrary ( ButtonTick );
			TweenMax.to ( backing, 0.3, { tint : onFillColor } );
			TweenMax.to ( backing, 0.3, { tint : offFillColor, delay : 0.35 } );
		}

		protected function performHelp ( evt : MouseEvent ) : void
		{
			evt.stopImmediatePropagation();
		}

		public function set label ( l : String ) : void
		{
			this._label = l;
			this.renderLabel();
		}

		public function get label ( ) : String
		{
			return this._label;
		}

		public function set useHtml ( b : Boolean ) : void
		{
			_useHtml = b;
		}

		public function applySelection ( ) : void
		{
			TweenMax.to ( backing, 0.3, { tint : offFillColor } );
		}

		protected function renderLabel ( ) : void
		{
			if ( textFormat )
			{
				labelField.setTextFormat ( textFormat );
				labelField.defaultTextFormat = textFormat;
			}
			if ( _useHtml )
				labelField.htmlText = label;
			else
				labelField.text = label;
			labelField.width = labelField.textWidth + 4;
			labelField.height = labelField.textHeight + 4;
		}

		override protected function render ( ) : void
		{
			var tf : TextFormat = labelField.getTextFormat();
				tf.leading = -1;

			textFormat = tf;

			if ( data is String )
			{
				label = data as String
			}else if ( data.hasOwnProperty ( "label" ) )
			{
				label = data.label;
			}

			if ( data.hasOwnProperty("enabled" ) && !data.enabled )
			{
				this.enabled = data.enabled;
			}

			if ( _bigIcon ) DisplayUtil.remove ( _bigIcon );

			addChild ( _bigIcon = new data.icon() as MovieClip );
			_bigIcon.mouseEnabled = _bigIcon.mouseChildren = false;

			iconSize.x = _bigIcon.width;
			iconSize.y = _bigIcon.height;

			_bigIcon.addChild ( labelField );
			_bigIcon.filters = [ this.filters[0] ];

			if ( data.hasOwnProperty("comingSoon" ) && data.comingSoon )
			{
				var banner : MovieClip = new ComingSoonBanner();
				addChild ( banner );
				banner.mouseEnabled = false;
				backing.mouseEnabled = false;
			}

			redraw();
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();

			backing.width = width;
			backing.height = height;
			highlight.width = width - 17;
			highlight.height = height / 2 + 10;

			if ( labelField )
			{
				helpIcon.x = width - helpIcon.width + 3;
				helpIcon.y = 12;

				labelField.width = labelField.width = width - 10;
				labelField.wordWrap = true;
				labelField.multiline = true;
				labelField.height = labelField.textHeight + 5;

				if (_bigIcon == null)
				{
					labelField.x = width / 2 - labelField.width / 2;
					labelField.y = height / 2 - labelField.height / 2;
				}
				else
				{
					labelField.x = iconSize.x / 2 - labelField.width / 2;
					labelField.y = iconSize.y + 8;
				}
			}

			if ( _bigIcon )
			{
				var xOff : Number = 0;
				var wToUse : Number = labelField.textWidth > iconSize.x ? labelField.textWidth : iconSize.x;
					xOff = wToUse != labelField.textWidth ? ( -labelField.x / 2 ) : 0;

				_bigIcon.x = -labelField.x + 5;
				_bigIcon.y = backing.height / 2 - _bigIcon.height / 2 + 5;
			}
		}
	}
}