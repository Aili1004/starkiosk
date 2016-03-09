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

	public class Keypad extends Component
	{

		protected var keys : Container;
		protected var keyButtons : Array = []

		protected var _value : String = "";
		protected var valueBtn : Button;

		public var firstTouch : Boolean = false;
		public var labelFunction : Function;
		public var defaultValue : String = "";
		protected var _maxChars : int = 3;

		protected var _isValidValue : Boolean = false;

		public var minValue : Number = -1;
		public var maxValue : Number = -1;

		public function Keypad()
		{
			super();
		}

		override protected function createUI ( ) : void
		{
			addChild ( keys = new Container() );

			addChild ( valueBtn = new Button() );

			FontUtil.applyTextFormat ( valueBtn.labelField, { size : 30 } );

			valueBtn.onFillColor = 0xFFFFFF;
			valueBtn.offFillColor = 0xFFFFFF;
			valueBtn.onLabelColor = 0x000000;
			valueBtn.offLabelColor = 0x000000;
			valueBtn.setSize ( width, 50 );
			valueBtn.label = "$0";
			valueBtn.mouseEnabled = false;
			valueBtn.hideTextShadow();
			valueBtn.applySelection();

			keys.padding = 0;
			keys.y = valueBtn.y + valueBtn.height + keys.verticalSpacing + 5;
			keys.verticalScrollEnabled = false;
			keys.horizontalScrollEnabled = false;
			keys.layoutStrategy = new GridFlowLayoutStrategy();
			keys.unmask();
			keys.horizontalSpacing = 8;
			keys.verticalSpacing = 8;
			keys.setSize ( width, height );

			createKeys();

			keys.redraw();
		}

		protected function createKeys ( ) : void
		{
			for ( var i : int = 0; i < 11; i++ )
			{
				var kb : Button = new Button();
					FontUtil.applyTextFormat ( kb.labelField, { size : 28 } );
					kb.label = i < 9 ? (i+1) + "" : 0 + "";
					if ( i == 10 ) kb.label = "CLEAR";
					kb.addEventListener ( MouseEvent.MOUSE_DOWN, addToInput );
					kb.minWidth = 5;
					kb.minHeight = 5;
					kb.onLabelColor = 0xFFFFFF;
					kb.offLabelColor = 0xFFFFFF;
					kb.width = 60;
					kb.applySelection();
					keys.addChild ( kb );
					keyButtons.push ( kb );
			}
		}

		public function set maxChars ( i : int ) : void
		{
			_maxChars = i;
		}

		public function get maxChars ( ) : int
		{
			return _maxChars;
		}

		public function get isValidValue ( ) : Boolean
		{
			return _isValidValue;
		}

		public function set isPassword ( p : Boolean ) : void
		{
			valueBtn.labelField.displayAsPassword = p;
		}

		protected function addToInput ( evt : MouseEvent ) : void
		{
			var clicked : Button = evt.currentTarget as Button;
			if ( clicked.label == "CLEAR" )
			{
				value = defaultValue;
			}else
			{
				if ( value == defaultValue || firstTouch )
				{
					value = clicked.label;
				}else
				{
					value += clicked.label;
				}
			}

			firstTouch = false;
		}

		public function set value ( v : String ) : void
		{
			if ( v.length > maxChars && v.indexOf ( "." ) < 0 ) return;

			if ( minValue > -1 && maxValue > -1 ) handleConstrainedValues ( v );

			_value = v;
			valueBtn.label = ( labelFunction != null ) ? labelFunction.apply ( null, [ v ] ) : StringUtil.currencyLabelFunction ( Number ( v ) );
			valueBtn.redraw();

			dispatchEvent ( new Event ( Event.CHANGE ) );x
		}

		public function get value ( ) : String
		{
			return this._value;
		}

		public function invalidateValue()
		{
			value = value;
		}

		protected function handleConstrainedValues ( v : String ) : Boolean
		{
			var vv : Number = Number ( v );
			if ( isNaN ( vv ) )
			{
				return _isValidValue = false;
			}

			if ( vv < minValue ) return _isValidValue = false;
			if ( vv > maxValue ) return _isValidValue = false;

			return _isValidValue = true;
		}

		override protected function invalidate ( ) : void
		{
			valueBtn.width = width;

			var numRows : int = 4;
			var maximumHeight : Number = ( height - 1 - keys.y ) - ( ( numRows - 1 ) * keys.verticalSpacing );
			var perHeight : Number = maximumHeight / numRows;

			var numCols : int = 3;
			var maximumWidth : Number = ( width - 1 ) - ( ( numCols - 1 ) * keys.horizontalSpacing );
			var perWidth : Number = maximumWidth / numCols;

			for ( var i : int = 0; i < keyButtons.length; i++ )
			{
				// clear button is double-wide
				if ( i == keyButtons.length - 1 )
				{
					keyButtons[i].setSize ( perWidth * 2 + keys.horizontalSpacing, perHeight );
				}else
				{
					keyButtons[i].setSize ( perWidth, perHeight );
				}

			}

			if ( keys )
			{
				keys.setSize ( width, height );
			}
		}
	}
}