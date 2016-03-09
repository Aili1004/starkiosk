package com.snepo.givv.cardbrowser.managers
{
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.ui.*;

	public class BarcodeManager extends EventDispatcher
	{
		protected static var target : DisplayObject;
		protected static var instance : BarcodeManager;
		public static var acceptingReads : Boolean = true;

		public static var forceAccept : Boolean = false;

		public static function init ( target : DisplayObject ) : BarcodeManager
		{
			BarcodeManager.target = target;
			return getInstance();
		}

		public static function getInstance ( ) : BarcodeManager
		{
			instance ||= new BarcodeManager ( new Private() );
			return instance;
		}

		protected var _rawBuffer : String = "";

		public function BarcodeManager ( p : Private ) : void
		{
			super ( this );
			if ( p == null ) throw new SingletonError ( "BarcodeManager" );
			if ( target == null ) throw new Error ( "BarcodeManager.init ( target : DisplayObject ) must be called." );

		}

		public function processBuffer ( buffer : String ) : void
		{
			dispatchEvent ( new BarcodeEvent ( BarcodeEvent.SCAN,StringUtil.trim(buffer,String.fromCharCode(27)) ) ); // remove escape character
			_rawBuffer = "";
		}

		public function get rawBuffer ( ) : String
		{
			return _rawBuffer;
		}

	}
}

class Private{};