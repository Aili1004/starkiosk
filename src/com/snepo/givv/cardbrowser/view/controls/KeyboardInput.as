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
	
	public class KeyboardInput extends Keypad
	{
		protected var rows : Array = [];
		protected var rowWidths : Array = [1, 0.9, 0.8, 0.7, 0.6];

		public function KeyboardInput()
		{
			super();

			defaultValue = "";

			labelFunction = renderLabel;
			maxChars = 1000;
		}

		protected function renderLabel ( value : String ) : String
		{
			return value;
		}

		protected function backspace ( evt : MouseEvent ) : void
		{
			value = value.substring ( 0, value.length - 1 );
		}

		override protected function createUI ( ) : void
		{
			super.createUI();
		}

		override protected function handleConstrainedValues ( v : String ) : Boolean
		{
			return ( _isValidValue = StringUtil.isEmail ( v ) );	
		}
		
		override protected function createKeys ( ) : void
		{
			keys.layoutStrategy = new VerticalLayoutStrategy(true);
			keys.verticalSpacing = 5;
			keys.padding = 0;


			var buttonLines : Array = "0123456789|QWERTYUIOP|ASDFGHJKL|ZXCVBNM|,.-_@<".split("|");

			for ( var i : int = 0; i < buttonLines.length; i++ )
			{	
				var buttonLabels : Array = buttonLines[i].split("");
				var perButton : Number = ( this.width / buttonLabels.length );

				var row : Container = new Container();
					row.unmask();
					row.padding = 0;
					row.layoutStrategy = new HorizontalFillLayoutStrategy();
					row.verticalScrollEnabled = false;
					row.horizontalScrollEnabled = false;
					row.width = width;
					row.height = 40;

				for ( var j : int = 0; j < buttonLabels.length; j++ )
				{
					var kb : Button = new Button();
						FontUtil.applyTextFormat ( kb.labelField, { size : 22 } );
						kb.label = buttonLabels[j];
						if ( buttonLabels[j] == "<" )
						{
							kb.addEventListener ( MouseEvent.MOUSE_DOWN, backspace );
						}else
						{
							kb.addEventListener ( MouseEvent.MOUSE_DOWN, addToInput );
						}
						kb.onFillColor = 0x6c8e17;
						kb.offFillColor = 0xADAFB2;
						kb.onLabelColor = 0xFFFFFF;
						kb.offLabelColor = 0xFFFFFF;
						kb.width = 40;
						kb.height = 40;
						kb.applySelection();
						row.addChild ( kb );
						keyButtons.push ( kb );
				}

				row.redraw();

				keys.addChild ( row );
				rows.push ( row );
			}

			invalidate();

			value = "";
		}

		override protected function invalidate ( ) : void
		{	
			var i : int;
			for ( i = 0; i < rows.length; i++ )
			{
				rows[i].setSize ( width * rowWidths[i], 40 );
			}

			if ( keys )
			{
				keys.setSize ( width, height );	
				valueBtn.width = width;
			}

			for ( i = 0; i < rows.length; i++ )
			{
				rows[i].setSize ( width * rowWidths[i], 40 );
				rows[i].x = width / 2 - ( rows[i].width / 2 );
			}
		}
	}
}