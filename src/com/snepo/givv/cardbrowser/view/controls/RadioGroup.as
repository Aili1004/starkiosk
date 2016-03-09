package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class RadioGroup extends Container
	{
		protected var RendererClass : Class;
	
		protected var _items : Array = [];
		protected var _selectedItem : Object;

		protected var _dataProvider : Array = [];

    	public function RadioGroup ( RendererClass : Class )
		{
			this.RendererClass = RendererClass;
			super(); 

			this._layoutStrategy = new HorizontalLayoutStrategy(false);
		}

		public function get items ( ) : Array
		{
			return _items;
		}

		public function get selectedItem ( ) : Object
		{
			return _selectedItem;
		}

		public function set dataProvider ( d : Array ) : void
		{
			_dataProvider = d;
			this.render();
		}

		public function get dataProvider ( ) : Array
		{
			return _dataProvider;
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );
		}

		override protected function render ( ) : void
		{
			for ( var i : int = 0; i < dataProvider.length; i++ )
			{
				var item : Component = new RendererClass() as Component;
					item.data = dataProvider[i];
					item.addEventListener ( MouseEvent.MOUSE_DOWN, toggleSelection, false, 0, true );
					items.push ( item );

				addChild ( item );
			}

			invalidate();
		}

		protected function toggleSelection ( evt : MouseEvent ) : void
		{
			var clicked : MovieClip = evt.currentTarget as MovieClip;
			
			if ( clicked.data == selectedItem ) return;

			for ( var i : int = 0; i < items.length; i++ )
			{
				var item : MovieClip = items[i] as MovieClip;
					item.selected = item == clicked;
			}

			_selectedItem = clicked.data;
			dispatchEvent ( new Event ( Event.CHANGE ) );
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();
		}
	}

}