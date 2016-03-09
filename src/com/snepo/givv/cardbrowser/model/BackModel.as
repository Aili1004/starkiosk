package com.snepo.givv.cardbrowser.model
{
	import com.snepo.givv.cardbrowser.view.core.ImageCache;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class BackModel extends EventDispatcher
	{

		protected var _backs : Array = [];

		public function BackModel()
		{
			super( this );
		}

		public function populate ( source : XML ) : void
		{
			var list : XMLList = source..back_design;

			var backs : Array = [];
			var i : int, j : int;

			for ( i = 0; i < list.length(); i++ )
			{
				var item : XML = list[i];
				var id : int = item.@id;
				var name : String = item.name;
				var images : Object = { };
				var imageList : XMLList = item.graphics.children();
				for ( j = 0; j < imageList.length(); j++ )
				{
					var imagePath : String = imageList[j].text();
					if ( imagePath.charAt(0) == "/" ) imagePath = "assets" + imagePath;
					images [ imageList[j].name() + "" ] = imagePath;
				}
				var card_id_x : int             = item.card_id_text.toString().length > 0 ? int(item.card_id_x.text()) : -1;
				var card_id_y : int             = item.card_id_text.toString().length > 0 ? int(item.card_id_y.text()) : -1;
				var card_id_barcode_x : int     = item.card_id_barcode_text.toString().length > 0 ? int(item.card_id_barcode_x.text()) : -1;
				var card_id_barcode_y : int     = item.card_id_barcode_text.toString().length > 0 ? int(item.card_id_barcode_y.text()) : -1;
				var card_number_x : int         = item.card_number_text.toString().length > 0 ? int(item.card_number_x.text()) : -1;
				var card_number_y : int         = item.card_number_text.toString().length > 0 ? int(item.card_number_y.text()) : -1;
				var card_number_barcode_x : int = item.card_number_barcode_text.toString().length > 0 ? int(item.card_number_barcode_x.text()) : -1;
				var card_number_barcode_y : int = item.card_number_barcode_text.toString().length > 0 ? int(item.card_number_barcode_y.text()) : -1;
				var serial_x : int              = item.serial_text.toString().length > 0 ? int(item.serial_x.text()) : -1;
				var serial_y : int              = item.serial_text.toString().length > 0 ? int(item.serial_y.text()) : -1;
				var pin_x : int                 = item.pin_text.toString().length > 0 ? int(item.pin_x.text()) : -1;
				var pin_y : int                 = item.pin_text.toString().length > 0 ? int(item.pin_y.text()) : -1;
				var issue_date_x : int          = item.issue_date_text.toString().length > 0 ? int(item.issue_date_x.text()) : -1;
				var issue_date_y : int          = item.issue_date_text.toString().length > 0 ? int(item.issue_date_y.text()) : -1;
				var value_x : int               = item.value_text.toString().length > 0 ? int(item.value_x.text()) : -1;
				var value_y : int               = item.value_text.toString().length > 0 ? int(item.value_y.text()) : -1;

				trace("BackModel#populate() - Name: " + name +
	    				", Card_id_x: " + card_id_x.toString() + ", Card_id_y: " + card_id_y.toString() +
	    				", Card_id_barcode_x: " + card_id_barcode_x.toString() + ", Card_id_barcode_y: " + card_id_barcode_y.toString());

				backs.push ( { id : id, name : name, images : images,
											 card_id_x : card_id_x, card_id_y : card_id_y,
											 card_id_barcode_x : card_id_barcode_x, card_id_barcode_y : card_id_barcode_y,
											 card_number_x : card_number_x, card_number_y : card_number_y,
											 card_number_barcode_x : card_number_barcode_x, card_number_barcode_y : card_number_barcode_y,
											 serial_x : serial_x, serial_y : serial_y,
											 pin_x : pin_x, pin_y : pin_y,
											 issue_date_x : issue_date_x, issue_date_y : issue_date_y,
											 value_x : value_x, value_y : value_y
										  } );
			}
			this._backs = backs;
		}

		public function getBackByID ( id : int ) : Object
		{
			for ( var i : int = 0; i < _backs.length; i++ )
			{
				var back : Object = _backs[i];
				if ( back.id == id ) return back;
			}

			return { id : -1, name : "Unknown Back" };
		}

		public function get backs () : Array
		{
			return _backs;
		}

		public function getPrintURL ( id : String ) : String
		{
			for ( var i : int = 0; i < _backs.length; i++ )
			{
				var back : Object = _backs[i];
				if ( back.id  == id )
				{
					return (Environment.isDevelopment ? Model.DROPBOX_DEV_PATH : Model.DROPBOX_PATH) + back.images.print.replace(/\//g, "\\" );
				}
			}
			return "";
		}

	}
}