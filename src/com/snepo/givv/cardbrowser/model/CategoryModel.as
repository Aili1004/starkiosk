package com.snepo.givv.cardbrowser.model
{

	import com.snepo.givv.cardbrowser.managers.*;
	import flash.events.*;

	public class CategoryModel extends EventDispatcher
	{

		public static var ALL_CATEGORIES : int = 0;

		protected var _categories : Array = [];

		public function CategoryModel ( ) 
		{
			super();
		}		

		public function populate ( source : XML ) : void
		{
			var list : XMLList = source..category;

			var host : HostModel = Model.getInstance().host;
			if ( host.hasHost )
				host.orderCategories ( list );
			_categories = [];
			for ( var i : int = 0; i < list.length(); i++ )
			{
				var category : XML = list[i];
				var name : String = category.name.text();
				var subtitle : String = category.subtitle.text();
				var flag : int = int ( category.inclusionflag.text() );
				var id : int = category.@id;
				var index : int = (category.hasOwnProperty("index") ? category.index : 9999);
				
				trace ( "ADDING " + name + ' (' + id.toString() + ')');

				_categories.push ( { id : id, label : name.toUpperCase(), subtitle : subtitle, flag : flag, index : index } );

				ALL_CATEGORIES |= flag;
			}

			ALL_CATEGORIES = 10000000;
			_categories.sortOn ( "index", Array.NUMERIC | Array.DESCENDING );
			_categories.reverse();			
		}

		public function removeEmptyCategories ( cards : CardModel ) : void
		{
			var keep : Array = [];

			for ( var i : int = 0; i < _categories.length; i++ )
			{
				if ( !cards.isEmptyCategory ( _categories[i].flag ) ) keep.push ( _categories[i] );
			}

			_categories = keep;
		}

		public function getCategoryById ( id : int ) : Object
		{
			for ( var i : int = 0; i < _categories.length; i++ )
			{
				if ( _categories[i].id == id ) return _categories[i];
			}
			return null;
		}

		public function getCategoryByFlag ( flag : int ) : Object
		{
			for ( var i : int = 0; i < _categories.length; i++ )
			{
				if ( _categories[i].flag & flag ) return _categories[i];
			}
			return null;
		}
		
		public function get categories ( ) : Array
		{
			return _categories;
		}
	}
}