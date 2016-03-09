package com.snepo.givv.cardbrowser.model
{
	/**
	* @author Andrew Wright
	*/

	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.events.*;
	import flash.net.*;

	public class Model extends EventDispatcher
	{

		/*protected*/public static var instance : Model;

		public static var DROPBOX_ROOT : String = "";
		public static var DROPBOX_PATH : String = "";
		public static var DROPBOX_DEV_PATH : String = "";

		public static function getInstance ( ) : Model
		{
			instance ||= new Model ( new Private() );
			return instance;
		}

		public var cart : CartModel;
		public var cards : CardModel;
		public var backs : BackModel;
		public var user : UserModel;
		public var partners : PartnerModel;
		public var host : HostModel;
		public var categories : CategoryModel;
		private var storedConfig : SharedObject;
		protected var _loaded : Boolean;

		protected var controller : Controller;

		public function Model ( p : Private )
		{
			super( this );

			if ( p == null ) throw new SingletonError ( "Model" );

			cart = new CartModel();
			cards = new CardModel();
			backs = new BackModel();
			user = new UserModel();
			host = new HostModel();
			partners = new PartnerModel();
			categories = new CategoryModel();
			storedConfig = SharedObject.getLocal("GiVVKiosk");
			controller = Controller.getInstance();
			_loaded = false;
		}

		public function loadModel( ) : void
		{
			// Load release info first
			var loader : URLLoader = new URLLoader();
			loader.addEventListener ( Event.COMPLETE, onReleaseInfoLoaded, false, 0, true );
			loader.addEventListener ( IOErrorEvent.IO_ERROR, onReleaseInfoError, false, 0, true );
			loader.load ( new URLRequest ( "release.txt" ) );
		}

		protected function onReleaseInfoLoaded ( evt : Event ) : void
		{
			if ( evt.target.data && evt.target.data.length > 0 )
			{
				Environment.RELEASE = evt.target.data.split(/\n/)[0];
				Environment.RELEASE_DESCRIPTION = evt.target.data;
				Logger.log ( "SOFTWARE RELEASE: " + Environment.RELEASE, Logger.LOG );
			}else
			{
				controller.report ( 50, "Release.txt loaded but invalid" );
			}

			loadGUID();
		}

		protected function onReleaseInfoError ( evt : Event ) : void
		{
			controller.report ( 50, "Release.txt File not found" );
			Logger.log ( "Error Loading Release.txt", Logger.ERROR );

			loadGUID();
		}

		public function loadGUID ( ) : void
		{
			// Use config setting if it exists
			var dropboxPath = ConfigManager.get('dropboxPath');
			DROPBOX_ROOT = (dropboxPath != null && dropboxPath != '' ? dropboxPath : Environment.dropboxPath);

			Logger.log("Dropbox: " + DROPBOX_ROOT, Logger.LOG);

			var commTimeout = ConfigManager.get ("commTimeout" );
			if (commTimeout != null && commTimeout != "")
				Environment.COMM_TIMEOUT = Number(commTimeout);
			Logger.log("Communication Timeout: " + Environment.COMM_TIMEOUT.toString() + " seconds");

			var sessionTimeout = ConfigManager.get ("sessionTimeout" );
			if (sessionTimeout != null && sessionTimeout != "")
				Environment.SESSION_TIMEOUT = Number(sessionTimeout);
			Logger.log("Session Timeout: " + Environment.SESSION_TIMEOUT.toString() + " seconds");

			var sessionExtensionTimeout = ConfigManager.get ("sessionExtensionTimeout" );
			if (sessionExtensionTimeout != null && sessionExtensionTimeout != "")
				Environment.SESSION_EXTENSION_TIMEOUT = Number(sessionExtensionTimeout);
			Logger.log("Session Extension Timeout: " + Environment.SESSION_EXTENSION_TIMEOUT.toString() + " seconds");

			var releasePath = ConfigManager.get("releasePath");
			if (releasePath != null && releasePath.length() > 0)
				Environment.RELEASE_PATH = releasePath;
			Logger.log("Release Path: " + Environment.RELEASE_PATH);

			var loader : URLLoader = new URLLoader();
			loader.addEventListener ( Event.COMPLETE, onGUIDLoaded, false, 0, true );
			loader.addEventListener ( IOErrorEvent.IO_ERROR, onGUIDError, false, 0, true );
			if (Environment.isWindows)
				loader.load ( new URLRequest ( "file://c:/guid.txt" ) );
			else
				loader.load ( new URLRequest ( "guid.txt" ) );

		}

		protected function onGUIDLoaded ( evt : Event ) : void
		{

			var response : String = evt.target.data;
				response = response.replace (/\n/g, "" );

			var parts : Array = response.split("-");
			if ( parts.length > 0 )
			{
				parts[0] = parts[0].toUpperCase();
				if ( parts.length > 1 )
				{
					for ( var i : int = 1; i < parts.length; i++ )
					{
						parts[i] = StringUtil.titleCase ( parts[i] );
					}
				}
			}

			if ( response && response.length > 6 )
			{
				Environment.KIOSK_UNIQUE_ID = parts.join(" ").replace ( /\n/g, "" ).replace ( /\r/g, "" );
				Environment.KIOSK_UNIQUE_ID = Environment.KIOSK_UNIQUE_ID.toLowerCase();
				Environment.KIOSK_UNIQUE_ID = StringUtil.trim ( Environment.KIOSK_UNIQUE_ID );
				controller.report ( 0, "GUID Loaded : " + Environment.KIOSK_UNIQUE_ID );
				Logger.log ( "KIOSK ID: " + Environment.KIOSK_UNIQUE_ID, Logger.LOG );
			}else
			{
				controller.report ( 50, "GUID Error. Loaded but invalid" );
			}

			loadHostInformation();
		}

		protected function onGUIDError ( evt : Event ) : void
		{
			Environment.KIOSK_UNIQUE_ID = "default_kiosk";

			controller.report ( 10, "GUID Error. GUID File not found" );
			Logger.log ( "Error Loading Guid", Logger.ERROR );

			loadHostInformation();
		}

		protected function loadHostInformation ( ) : void
		{
			var hostToken : HostGroupToken = controller.getHostGroupInfo();
				hostToken.addEventListener ( TokenEvent.COMPLETE, onHostInfoComplete, false, 0, true );
				hostToken.addEventListener ( TokenEvent.ERROR, onHostInfoError, false, 0, true );
		}

		protected function onHostInfoComplete ( evt : TokenEvent ) : void
		{
			load();
		}

		protected function onHostInfoError ( evt : TokenEvent ) : void
		{
			trace('Model = onDataError()')
			controller.report ( 50, "Error loading host data => " + evt.data );
			if (evt.data == null)
				dispatchEvent ( new ModelEvent (ModelEvent.ERROR, "Unable to load host data.\nPlease check the internet connection." ));
			else
				dispatchEvent ( new ModelEvent (ModelEvent.ERROR, evt.data ) );
		}

		public function load ( ) : void
		{
			var prefixLoader : URLLoader = new URLLoader();
				prefixLoader.addEventListener ( Event.COMPLETE, onPrefixLoaded );
				prefixLoader.addEventListener ( IOErrorEvent.IO_ERROR, onPrefixError );
			if ( Environment.isWindows )
			{
				prefixLoader.load ( new URLRequest ( DROPBOX_ROOT + "stock\\latest.xml"))
			}else
			{
				prefixLoader.load ( new URLRequest ( DROPBOX_ROOT + "stock/latest.xml"))
			}

		}

		protected function onPrefixError ( evt : ErrorEvent ) : void
		{
			trace('Model = onPrefixError()')
			controller.report(50, 'Could not open Dropbox files');
			Logger.log('Could not open Dropbox files', Logger.ERROR);
			dispatchEvent ( new ModelEvent (ModelEvent.ERROR, "Error loading local stock prefix." ));
		}

		protected function onPrefixLoaded ( evt : Event ) : void
		{
			var data : XML = new XML ( evt.target.data );
			var folder : String = data.path.text();
			var filename : String = data.stockFile.text();
			var path : String;

			DROPBOX_PATH = DROPBOX_ROOT + folder;

			// Load dev remote dropbox directory
			if (ConfigManager.get('dev') != null && ConfigManager.get('dev').serviceHostDropboxPath != null)
			{
				DROPBOX_DEV_PATH = ConfigManager.get('dev').serviceHostDropboxPath + folder;
				Logger.log('Service Host Dropbox Path: ' + DROPBOX_DEV_PATH, Logger.LOG);
			}

			if (filename == "")
				filename = 'stock.xml';
			path = DROPBOX_PATH + (Environment.isWindows ? "data\\" : 'data/') + filename;

			controller.report (0, "Latest stock file loaded. Using " + path);
			Logger.log("Latest stock file loaded. Using " + path);
			loadData(path);
		}

		protected function loadData ( path : String ) : void
		{
			var dataLoader : URLLoader = new URLLoader();
				dataLoader.addEventListener ( Event.COMPLETE, onDataLoaded );
				dataLoader.addEventListener ( IOErrorEvent.IO_ERROR, onDataError );
				dataLoader.load ( new URLRequest ( path ) );
		}

		protected function onDataError ( evt : ErrorEvent ) : void
		{
			controller.report ( 50, "Error loading stock data." );
			trace('Model = onDataError()')
			dispatchEvent ( new ModelEvent (ModelEvent.ERROR, "Unable to load local stock data.\nPlease check the dropbox configuration." ));
		}

		protected function onDataLoaded ( evt : Event ) : void
		{
			var source : XML = new XML ( evt.target.data );

			categories.populate ( source.categories[0] );
			cards.populate ( source.products[0] );
			backs.populate ( source.back_designs[0] );
			partners.populate ( source.partners[0] );

			controller.report ( 0, "Stock data loaded" );

			categories.removeEmptyCategories ( cards );

			_loaded = true;
			dispatchEvent ( new ModelEvent ( ModelEvent.READY ) );
		}

		public function createPassword ( ) : void
		{
			storedConfig.data.id = new Date().time.toString().slice(-8);
			storedConfig.flush(1000);
		}

		public function getPassword ( ) : String
		{
			return storedConfig.data.id;
		}

		public function set outOfOrder ( state : Boolean )
		{
			storedConfig.data.outOfOrder = state;
			storedConfig.flush(1000);
		}

		public function get outOfOrder ( ) : Boolean
		{
			return (storedConfig.data.hasOwnProperty("outOfOrder") ? storedConfig.data.outOfOrder : false);
		}

		public function get loaded ( ) : Boolean
		{
			return _loaded;
		}
	}
}

class Private{}