package com.snepo.givv.cardbrowser.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.view.core.*;
	
	import flash.display.MovieClip;
	import flash.events.*;
	
	public class ListEvent extends Event
	{
		public static const ITEM_INTERACTION : String = "ListItem.ITEM_INTERACTION";
		public static const REFRESH : String = "ListEvent.REFRESH";
		
		public var data : * = null;
		public var index : int = -1;
		public var action : String;
		public var listItem : Component;
		public var originator : MovieClip;
		
		public function ListEvent( type : String, listItem : Component, data : * = null, index : int = -1, originator : MovieClip = null, action : String = null )
		{
			super( type );
			
			this.data = data;
			this.index = index;
			this.action = action;
			this.listItem = listItem;
			this.originator = originator;
		}
		
		override public function toString() : String
		{
			var message : String = "[ListEvent({$})]";
			
			var props : Array = [ "type", "data", "index", "action", "listItem", "originator" ];
			var parts : Array = [];
			for each ( var i : String in props )
			{
				parts.push ( i + "=" + this[i] );
			}
			
			message = message.replace ( "{$}", parts.join(", " ) );
			
			return message;
		}

	}
}