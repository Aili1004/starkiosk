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
	
	public class List extends Component
	{
		protected var _touchGrabber : Sprite;
		protected var _list : Container;
		protected var ListItemClass : Class = CardListItem;
		
		protected var _dataProvider : Array = [];
		protected var _listItems : Array = [];

		public var defaultItemProperties : Object = {};
		
		public function List( renderer : Class = null )
		{
			if ( renderer != null ) ListItemClass = renderer;
			
			super();

			
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
		
		public function get listItems ( ) : Array
		{
			return this._listItems;
		}
		
		override protected function render ( ) : void
		{
			dispose();
			
			for ( var i : int = 0; i < dataProvider.length; i++ )
			{
				addItem ( dataProvider[i], false )	
				
			}
			
			this.postRender();
			_list.redraw();
		}
		
		public function refreshData ( ) : void
		{
			for ( var i : int = 0; i < listItems.length; i++ )
			{
				if ( listItems[i] is IListItem )
				{
					(listItems[i] as IListItem).refresh()
				}
			}
		}
		
		public function addItem ( data : Object, redraw : Boolean = true ) : void
		{
			var item : Component = new ListItemClass() as Component;
				item.data = data;
				item.addEventListener ( ListEvent.ITEM_INTERACTION, forwardItemInteractionMethod, false, 0, true );

				if ( listItems.length == 0 ) item.addEventListener ( Event.RESIZE, handleItemResize, false, 0, true );

				for ( var i : String in defaultItemProperties )
				{
					try
					{
						item[ i ] = defaultItemProperties[i];
					}catch ( e : Error )
					{
						
					}
				}
				
				_list.addChild ( item );
				_listItems.push ( item );
				
				if ( _dataProvider.indexOf ( data ) < 0 ) _dataProvider.push ( data );
				
				
			if ( redraw ) 
			{
				_list.redraw();
				dispatchEvent ( new ListEvent ( ListEvent.REFRESH, item ) );
			}
		}
		
		public function removeItem ( data : Object, redraw : Boolean = true ) : *
		{
			for ( var i : int = 0; i < _list.contentChildren.length; i++ )
			{
				if ( _list.contentChildren[i].data == data ) 
				{
					return removeItemAt ( i, redraw );
					break;
				}
			}

			return null;
		}
		
		public function removeAll ( ) : void
		{
			while ( listItems.length ) 
			{
				removeItemAt( 0, false );
			}
			
			_list.redraw();
			dispatchEvent ( new ListEvent ( ListEvent.REFRESH, null ) );
		}
		
		public function removeItemAt ( index : int, redraw : Boolean = true ) : *
		{
			var component : MovieClip = _list.contentChildren[index];
			if ( component )
			{
				_list.removeChild ( component );
				_listItems.splice ( index, 1 );
				_dataProvider.splice ( index, 1 );
			}
			
			if ( redraw ) 
			{
				_list.redraw();
				dispatchEvent ( new ListEvent ( ListEvent.REFRESH, component as Component ) );
			}

			return component;
		}
		
		
		protected function postRender ( ) : void
		{
			
		}
		
		protected function forwardItemInteractionMethod ( evt : ListEvent ) : void
		{
			var newEvent : ListEvent = new ListEvent ( ListEvent.ITEM_INTERACTION, evt.target as Component, evt.data, listItems.indexOf ( evt.target ), evt.originator, evt.action );
			dispatchEvent ( newEvent );
		}
		
		override public function dispose ( ) : void
		{
			for ( var i : int = 0; i < listItems.length; i++ )
			{
				var item : Component = listItems[i] as Component;
					item.removeEventListener ( ListEvent.ITEM_INTERACTION, forwardItemInteractionMethod );
					item.removeEventListener ( Event.RESIZE, handleItemResize );
				}
			
			list.dispose();
			
			_listItems = [];
			
		}
		
		public function get list ( ) : Container
		{
			return _list;
		}
		
		override protected function createUI ( ) : void
		{
			super.createUI ( );
			
			addChildAt ( _touchGrabber = new Sprite(), 0 );
			var g : Graphics = _touchGrabber.graphics;
				g.clear();
				g.beginFill ( 0x000000, 0 );
				g.drawRect ( 0, 0, 10, 10 );
				g.endFill();
			
			initList();
			
		}
		
		protected function initList ( ) : void
		{
			addChild ( _list = new Container() );
			list.padding = 0;
			list.verticalSpacing = 0;
			list.layoutStrategy = new VerticalLayoutStrategy();
			list.horizontalScrollEnabled = false;
			list.verticalScrollEnabled = true;
			list.setSize ( width, height );
			
			invalidate();
		}

		protected function handleItemResize ( evt : Event ) : void
		{
			invalidate();
		}
		
		override protected function invalidate ( ) : void
		{
			if ( list ) list.setSize ( width, height );
			
			if ( _touchGrabber )
			{
				_touchGrabber.width = width;
				_touchGrabber.height = height;
			}
		}

	}
}