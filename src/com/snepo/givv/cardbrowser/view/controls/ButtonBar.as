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
	import flash.geom.*;
	import flash.text.*;

	public class ButtonBar extends Container
	{
		protected var _buttons : Array = [];
		protected var _ids : Array = [];
		protected var _selectedIndex : int = -1;
		protected var _dataProvider : Array = [];
		protected var _useHtml : Boolean = false;

		public var selectable : Boolean = true;

		protected var buttonHolder : Sprite;

		public function ButtonBar()
		{
			super();

			_layoutStrategy = new HorizontalLayoutStrategy();
			this.horizontalSpacing = 10;
			this.verticalSpacing = 10;
			this.padding = 0;
			this.unmask();

		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			nativeAddChild ( buttonHolder = new Sprite() );
		}

		public function set dataProvider ( d : Array ) : void
		{
			this._dataProvider = d;
			this.render();
		}

		public function get dataProvider ( ) : Array
		{
			return this._dataProvider;
		}

		public function get buttons ( ) : Array
		{
			return _buttons;
		}

		public function set useHtml ( b : Boolean ) : void
		{
			_useHtml = b;
		}

		public function set selectedIndex ( s : int ) : void
		{
			_selectedIndex = s;
			if ( _buttons[selectedIndex] )
			{
				toggleSelection( null, _buttons[selectedIndex ] );
			}
		}

		public function get selectedIndex ( ) : int
		{
			return _selectedIndex;
		}

		override protected function render ( ) : void
		{
			dispose();

			for ( var i : int = 0; i < dataProvider.length; i++ )
			{
				var button : Button = new Button();
					button.minWidth = 80;
					button.selectable = selectable;
					button.repeating = false;
					button.disableInteraction();
					button.selected = i == 0;
					button.useHtml = _useHtml;
					button.data = dataProvider[i];
					button.pack();
					button.addEventListener ( MouseEvent.CLICK, toggleSelection );

				if ( dataProvider[i].hasOwnProperty ( "id" ) )
					_ids.push( dataProvider[i].id );

				addChild ( button );
				_buttons.push ( button );
			}

			invalidate();
		}

		public function selectByLabel ( label : String ) : void
		{
			for ( var i : int = 0; i < buttons.length; i++ )
			{
				trace('testing button - ' + buttons[i].label.split('\n')[0] + ' at index ' + i.toString() )

				if ( buttons[i].label..split('\n')[0].toLowerCase() == label.toLowerCase() )
				{
					select ( i );
					break;
				}
			}
		}

		public function selectByLabelFuzzy ( label : String ) : void
		{
			var found : Boolean = false;

			for ( var i : int = 0; i < buttons.length; i++ )
			{
				if ( buttons[i].label.toLowerCase().indexOf ( label.toLowerCase() ) > -1 )
				{
					select ( i );
					found = true;
					break;
				}
			}

			if ( !found ) select ( 0 );
		}

		public function selectById ( id : int ) : void
		{
			if (_ids.length == buttons.length)
			{
				for ( var i : int = 0; i < buttons.length; i++ )
				{
					if ( _ids[i] == id )
					{
						select ( i );
						break;
					}
				}
			}
		}

		public function select ( index : int, silent : Boolean = false ) : void
		{
			_selectedIndex = index;
			if ( index < 0 )
			{
				toggleSelection ( null, null, silent );
			}else
			{
				toggleSelection ( null, buttons[index], silent );
			}
		}

		protected function toggleSelection ( evt : MouseEvent = null, forceItem : Button = null, silent : Boolean = false ) : void
		{
			if ( evt && _travelDistance > 4 ) return;
			if ( evt && selectable ) SoundUtil.playLibrary ( ButtonTick );

			var clicked : Button = evt ? evt.currentTarget as Button : forceItem;

			for ( var i : int = 0; i < _buttons.length; i++ )
			{
				_buttons[i].selected = _buttons[i] == clicked;
			}

			_selectedIndex = _buttons.indexOf ( clicked );

			if ( !silent ) dispatchEvent ( new Event ( Event.CHANGE ) );
		}

		override public function dispose ( ) : void
		{
			super.dispose()
			for ( var i : int = 0; i < buttons.length; i++ )
			{
				var b : Button = buttons[i];
					b.removeEventListener ( MouseEvent.MOUSE_DOWN, toggleSelection );

				DisplayUtil.remove ( b );
			}

			_buttons = [];
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();
			content.x = width / 2 - content.width / 2;
		}
	}
}