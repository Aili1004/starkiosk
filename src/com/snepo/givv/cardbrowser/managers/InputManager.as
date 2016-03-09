package com.snepo.givv.cardbrowser.managers
{

	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.screens.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.ui.*;

	public class InputManager extends EventDispatcher
	{
		protected static var target : DisplayObject;
		protected static var instance : InputManager;
		
		public static function init ( target : DisplayObject ) : InputManager
		{
			InputManager.target = target;
			return getInstance();
		}

		public static function getInstance ( ) : InputManager
		{
			instance ||= new InputManager ( new Private() );
			return instance;
		}

		protected var _rawBuffer : String = "";
		
		public function InputManager ( p : Private ) : void
		{
			super ( this );
			if ( p == null ) throw new SingletonError ( "InputManager" );
			if ( target == null ) throw new Error ( "InputManager.init ( target : DisplayObject ) must be called." );

			target.addEventListener ( KeyboardEvent.KEY_UP, trapInputEvents, false, 0, true );
		}

		protected function trapInputEvents ( evt : KeyboardEvent ) : void
		{
			var charCode : * = evt.charCode;
			var keyCode : * = evt.keyCode;
			var character : String = String.fromCharCode ( evt.charCode );
			var charKey : String = String.fromCharCode ( evt.keyCode ); 

			if ( charCode != 0 )
			{
				if ( charCode == 13 )
				{
					processBuffer ( _rawBuffer );
					_rawBuffer = "";
				}else
				{
					_rawBuffer += character;
				}
				
			}
		}

		public function get acceptingInput ( ) : Boolean
		{
			if ( BarcodeManager.forceAccept ) return true;
			var view : View = View.getInstance();

			var ok : Boolean = ( [ View.HOME_SCREEN, View.CHOOSE_SCREEN, View.OOO_SCREEN ].indexOf ( view.currentScreenKey ) > -1 );

			if ( view.modalOverlay.currentContent is MarketPlaceOverlay ) ok = true;

			return ok;
		}

		protected function processBuffer ( buffer : String ) : void
		{
			if ( !acceptingInput ) return;

			var isCardSwipe : Boolean = /!=(.+)=!/.test( buffer );

			if ( isCardSwipe )
			{
				var parts : Array = buffer.match( /!=(.+)=!/ );
				if ( parts && parts.length > 1 )
				{
					SwipeManager.getInstance().processBuffer ( parts[1] );
				}
			}else
			{
				BarcodeManager.getInstance().processBuffer ( buffer );
			}
		}
	}
}

class Private{}