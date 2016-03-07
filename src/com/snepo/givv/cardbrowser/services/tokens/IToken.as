package com.snepo.givv.cardbrowser.services.tokens
{
	import flash.events.*;
	import flash.net.*;

	public interface IToken extends IEventDispatcher
	{
    	function start ( data : * = null ) : void;
    	function get status ( ) : Object;
    	function get response ( ) : *;
    	function dispose ( ) : void;
    	function notifyComplete ( ) : void;
    	function notifyError ( reason : String = "" ) : void;
	}

}