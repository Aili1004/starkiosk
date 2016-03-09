package com.snepo.givv.cardbrowser.view.controls
{

	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class PredefinedValueBox extends Component
	{
		protected var buttonBar : ButtonBar;
		protected var _values : Array = [];
		protected var buttonMask : Sprite;
		protected var maxButtonHeight : Number = 70;

    	public function PredefinedValueBox()
		{
			super ( ); 
		}

		public function set values ( v : Array ) : void
		{
			buttonBar.dataProvider = v;
			updateButtonStyles();
			selectDefault();
			TweenMax.to ( buttonBar.content, 0.4, { y : 0, ease : Quint.easeInOut } );
			_values = v;
		}

		public function get values ( ) : Array
		{
			return _values;
		}

		protected function selectDefault ( ) : void
		{
			for ( var i : int = 0; i < buttonBar.dataProvider.length; i++ )
			{
				var item : Object = buttonBar.dataProvider[i];
				if ( item.isDefault ) 
				{
					buttonBar.select ( i );
					return;
				}

			}

			buttonBar.select(0);
		}

		public function selectButtonByValue ( value : String ) : void
		{
			for ( var i : int = 0; i < buttonBar.buttons.length; i++ )
			{
				if ( buttonBar.buttons[i].label == value )
				{
					buttonBar.selectedIndex = i;
					break;
				}
			}
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			addChild ( buttonBar = new ButtonBar() );
			buttonBar.padding = 0;
			buttonBar.horizontalSpacing = 6;
			buttonBar.verticalSpacing = 6;
			buttonBar.layoutStrategy = new GridFlowLayoutStrategy();
			buttonBar.addEventListener ( Event.CHANGE, forwardChangeEvent );

			addChild ( buttonMask = new Sprite() );
			var g : Graphics = buttonMask.graphics;
				g.clear();
				g.beginFill ( 0xFF0000, 0.6 );
				g.drawRect ( 0, 0, 10, 10 );
				g.endFill();

			invalidate();

			buttonBar.mask = buttonMask;
		}

		protected function forwardChangeEvent ( evt : Event ) : void
		{
			dispatchEvent ( new Event ( Event.CHANGE ) );
		}

		public function get selectedValue ( ) : *
		{
			if ( buttonBar.selectedIndex < 0 ) return null;
			return buttonBar.buttons [ buttonBar.selectedIndex ].data;
		}

		protected function updateButtonStyles ( ) : void
		{
			var maxCols : int = ( this.height - ( buttonBar.buttons.length - 1 ) * buttonBar.verticalSpacing ) / 50;
			var perWidth : Number = buttonBar.buttons.length > maxCols ? width / 2 - 6 : width;
			var perHeight : Number = 50;

			if ( perWidth == width )
			{
				perHeight = ( this.height - ( buttonBar.buttons.length - 1 ) * buttonBar.verticalSpacing ) / buttonBar.buttons.length;
			}
			
			if ( perHeight > maxButtonHeight ) perHeight = maxButtonHeight;		

			for ( var i :int = 0; i < buttonBar.buttons.length; i++ )
			{
				var button : Button = buttonBar.buttons[i];
					button.onLabelColor = 0xFFFFFF;
					button.offLabelColor = 0xFFFFFF;
					button.width = perWidth;
					button.height = perHeight;
					button.applySelection();

			}
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate ( );

			updateButtonStyles();
			buttonBar.setSize ( width, height );
			updateButtonStyles();

			buttonBar.horizontalScrollEnabled = false;
			buttonBar.verticalScrollEnabled = buttonBar.content.height > buttonBar.height;

			buttonMask.width = width;
			buttonMask.height = height;
		}
	}


}