package com.snepo.givv.cardbrowser.managers
{
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.screens.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class ActionManager
	{
		protected static var actions : Dictionary = new Dictionary();
							 actions [ "showScreen" ] = showScreenActionHandler;

    	public static function performAction ( action : Object ) : void
    	{
    		if ( actions [ action.action ] != null )
    		{
    			actions [ action.action ] ( action );
    		}
    	}

    	protected static function showScreenActionHandler ( action : Object ) : void
    	{
    		var view : View = View.getInstance();
    			view.currentScreenKey = action.data;
    	}
	}

}