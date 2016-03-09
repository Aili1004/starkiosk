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

	public class Button extends Component implements IListItem
	{
		/*public static const DEFAULT_OFFCOLOR : uint = 0x0E447F; // dark blue  0xADAFB2; //grey    //*/
		/*public static const DEFAULT_ONCOLOR : uint = 0x169CD4; // light blue*/

		public static const DEFAULT_OFFCOLOR : uint;
		public static const DEFAULT_ONCOLOR : uint;

		protected var _label : String = "";
		protected var _selected : Boolean = false;
		protected var _selectable : Boolean = false;
		protected var _repeating : Boolean = false;
		protected var _useHtml : Boolean = false;

		protected var _cornerRadii : Object = { tl : 6, tr : 6, bl : 6, br : 6 };

		public var repeatRate : int = 200;

		public var offFillColor : uint = DEFAULT_OFFCOLOR;
		public var onFillColor : uint = DEFAULT_ONCOLOR;

		public var offLabelColor : uint = 0xFFFFFF;
		public var onLabelColor : uint = 0xFFFFFF;

		public var minWidth : Number = 50;
		public var minHeight : Number = 30;

		protected var _icon : DisplayObject;

		protected var labelHolder : Sprite;
		protected var repeatTimer : Timer;
		protected var initedRepeatingEvents : Boolean = false;
		protected var highlightMask : Sprite;
		protected var promotionLabel : MovieClip;

		public var textFormat : TextFormat;
		public var iconPlacement : String = "left";

		public function Button()
		{
			super();

			buttonMode = true;
			mouseChildren = false;

			this.filters = [ buttonFill.filters[0] ];
			buttonFill.filters = [];

			addChild ( labelHolder = new Sprite() );
			labelHolder.addChild ( labelField );

			labelHolder.filters = [ labelField.filters[0] ];
			labelField.filters = [];

			TweenMax.to ( buttonFill, 0, { tint : offFillColor } );
			TweenMax.to ( labelField, 0, { tint : offLabelColor } );

			selectable = false;

		}

		public function set cornerRadii ( r : Object ) : void
		{
			_cornerRadii = r;
			invalidate();
		}

		public function get cornerRadii ( ) : Object
		{
			return _cornerRadii;
		}

		public function refresh ( ) : void
		{

		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			buttonFill.removeChildAt ( 0 );

			addChild ( highlightMask = new Sprite() );
			bottomHighlight.mask = highlightMask;

			if (Environment.isLinx)
			{
				topHighlight.visible = bottomHighlight.visible = false;
				var corner : int = Environment.selectButtonCorner;
				cornerRadii = { tl : corner, tr : corner, bl : corner, br : corner };
			}

			invalidate();

		}

		public function set icon ( i : DisplayObject ) : void
		{
			if ( _icon ) DisplayUtil.remove ( _icon );
			addChild ( _icon = i );
			invalidate();
		}

		public function get icon ( ) : DisplayObject
		{
			return _icon;
		}

		public function hideTextShadow ( ) : void
		{
			labelHolder.filters = [];
		}

		public function hideButtonShadow ( ) : void
		{
			this.filters = [];
		}

		override protected function render ( ) : void
		{
			if ( data is String )
			{
				label = data as String
			}else if ( data.hasOwnProperty ( "label" ) )
			{
				label = data.label;
				if ( data.hasOwnProperty ( "subtitle" ) )
				{
					if ( _useHtml )
						label = label + '\n<font size=\"16\">' + data.subtitle + '</font>'
					else
						label = label + '\n' + data.subtitle
				}
			}

			if ( data.hasOwnProperty("promotion") && data.promotion )
			{
				addChildAt ( promotionLabel = new PromotionTab(), 0 );
				promotionLabel.valueField.text = StringUtil.currencyLabelFunction ( data.value ) + " value";
			}

			if ( data.hasOwnProperty("enabled" ) && !data.enabled )
			{
				this.enabled = data.enabled;
			}
		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents( evt );

			if ( repeating && !initedRepeatingEvents )
			{
				repeating = true;
				initedRepeatingEvents = true;
				removeEventListener ( MouseEvent.MOUSE_DOWN, playTouchAnimation );
			}
		}

		public function set selectable ( s : Boolean ) : void
		{
			_selectable = s;
			if ( s ) repeating = false;

			if ( !s )
			{
				addEventListener ( MouseEvent.MOUSE_DOWN, playTouchAnimation );
			}else
			{
				removeEventListener ( MouseEvent.MOUSE_DOWN, playTouchAnimation );
			}

		}

		public function get selectable ( ) : Boolean
		{
			return _selectable;
		}


		public function set repeating ( r : Boolean ) : void
		{
			_repeating = r;
			if ( r )
			{
				selectable = false;
				selected = false;
				removeEventListener ( MouseEvent.MOUSE_DOWN, playTouchAnimation );
			}

			if ( r )
			{
				if ( stage )
				{
					addEventListener ( MouseEvent.MOUSE_DOWN, startRepeating );
					stage.addEventListener ( MouseEvent.MOUSE_UP, stopRepeating );
				}
			}else
			{
				if ( stage )
				{
					removeEventListener ( MouseEvent.MOUSE_DOWN, startRepeating );
					stage.removeEventListener ( MouseEvent.MOUSE_UP, stopRepeating );
				}
			}
		}

		public function get repeating ( ) : Boolean
		{
			return _repeating;
		}

		public function set useHtml ( b : Boolean ) : void
		{
			_useHtml = b;
		}

		public function disableInteraction ( ) : void
		{
			removeEventListener ( MouseEvent.MOUSE_DOWN, startRepeating );
		}

		protected function startRepeating ( evt : MouseEvent ) : void
		{
			stopRepeatTimer();

			repeatTimer = new Timer ( repeatRate );
			repeatTimer.addEventListener ( TimerEvent.TIMER, tick );
			repeatTimer.start();

			TweenMax.to ( buttonFill, 0.3, { tint : onFillColor } );
			TweenMax.to ( labelField, 0.3, { tint : onLabelColor } );

			tick();
		}

		protected function stopRepeating ( evt : MouseEvent ) : void
		{
			var wasRepeating : Boolean = repeatTimer && repeatTimer.running;
			stopRepeatTimer();

			if ( wasRepeating )
			{
				TweenMax.to ( buttonFill, 0.3, { tint : offFillColor } );
				TweenMax.to ( labelField, 0.3, { tint : offLabelColor } );
			}
		}

		protected function tick ( evt : TimerEvent = null ) : void
		{
			SoundUtil.playLibrary ( ButtonTick );

			dispatchEvent ( new ButtonEvent ( ButtonEvent.REPEAT ) );
		}

		protected function stopRepeatTimer ( ) : void
		{
			if ( repeatTimer )
			{
				repeatTimer.stop();
				repeatTimer.removeEventListener ( TimerEvent.TIMER, tick );
				repeatTimer = null;
			}
		}

		protected function playTouchAnimation ( evt : MouseEvent ) : void
		{
			SoundUtil.playLibrary ( ButtonTick );
			TweenMax.to ( buttonFill, 0.3, { tint : onFillColor } );
			TweenMax.to ( buttonFill, 0.3, { tint : offFillColor, delay : 0.35 } );

			TweenMax.to ( labelField, 0.3, { tint : onLabelColor } );
			TweenMax.to ( labelField, 0.3, { tint : offLabelColor, delay : 0.35 } );
		}

		override protected function applyEnabled ( ) : void
		{
			mouseEnabled = enabled;
			var alpha : Number = enabled ? 1 : 0.3;
			TweenMax.to ( this, 0.4, { alpha : alpha } );
		}

		public function set selected ( s : Boolean ) : void
		{
			_selected = s;
			if ( selectable ) applySelection();
		}

		public function get selected ( ) : Boolean
		{
			return _selected;
		}

		public function applySelection ( ) : void
		{
			var color : uint = selected ? onFillColor : offFillColor;
			var tColor : uint = selected ? onLabelColor : offLabelColor;

			TweenMax.to ( buttonFill, 0.3, { tint : color } );
			TweenMax.to ( labelField, 0.3, { tint : tColor } );
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

		public function pack ( ) : void
		{
			setSize ( labelField.width + 18, labelField.height + 12 );

		}

		override protected function invalidate ( ) : void
		{

			if ( width < minWidth ) _width = minWidth;
			if ( height < minHeight ) _height = minHeight;

			//buttonFill.width = width;
			//buttonFill.height = height;

			var actualButtonHeight : Number = promotionLabel ? ( height + promotionLabel.height - 2 ) : height;

			var g : Graphics = buttonFill.graphics;
				g.clear();
				g.beginFill ( 0xFFFFFF, 1 );
				g.drawRoundRectComplex(0, 0, width, height, cornerRadii.tl || 0, cornerRadii.tr || 0, cornerRadii.bl || 0, cornerRadii.br || 0 );
				g.endFill();

			g = highlightMask.graphics;
			g.clear();
			g.beginFill ( 0xFF0000, 0.5 );
			g.drawRoundRectComplex(0, 0, width, height, cornerRadii.tl || 0, cornerRadii.tr || 0, cornerRadii.bl || 0, cornerRadii.br || 0 );
			g.endFill();

			bottomHighlight.width = width;
			bottomHighlight.y = height - bottomHighlight.height;

			topHighlight.width = width - 4;

			labelField.x = width / 2 - labelField.width / 2;
			labelField.y = height / 2 - labelField.height / 2 + (Environment.isLinx ? 2 : -2);

			if ( icon )
			{
				if ( !label || label.length < 1 )
				{
					icon.x = width / 2 - icon.width / 2;
					icon.y = height / 2 - icon.height / 2;
				}else
				{
					icon.y = height / 2 - icon.height / 2;
					icon.x = icon.width / 2 + 5;
					labelField.x = icon.x + icon.width + 3;
				}

				if ( iconPlacement == "right" )
				{
					labelField.x = width / 2 - labelField.width / 2 - 5;
					labelField.y = height / 2 - labelField.height / 2 + 2;
					icon.y = height / 2 - icon.height / 2;
					icon.x = width - icon.width - 15;
				}

			}

			if ( promotionLabel )
			{
				var prefix : String = ""
				if ( width > 150 ) prefix = "Includes ";

				promotionLabel.backing.width = width;
				promotionLabel.valueField.width = width - 10;
				promotionLabel.valueField.x = 5;
				promotionLabel.valueField.text = prefix + StringUtil.currencyLabelFunction ( data.value ) + " value";
				promotionLabel.y = height - 2;
			}

			_height = actualButtonHeight;
		}
	}
}
