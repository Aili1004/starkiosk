package com.snepo.givv.cardbrowser.managers
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.util.*;
	
	import flash.events.*;
	import flash.net.*;
	import flash.xml.*;
	
	public class ConfigManager extends EventDispatcher
	{
		
		protected static var instance : ConfigManager;
		
		public static function getInstance ( ) : ConfigManager
		{
			instance ||= new ConfigManager ( new Private() );
			return instance;
		}
		
		public static function get ( path : String ) : *
		{
			return getInstance().get ( path );
		}
		
		protected var rawXML : XML;
		protected var configMap : Object = {};
		
		public function ConfigManager( p : Private )
		{
			super ( this );
			
			if ( p == null ) throw new SingletonError ( "ConfigManager" );
		}
		
		public function load ( path : String ) : void
		{
			var loader : URLLoader = new URLLoader();
				loader.addEventListener ( Event.COMPLETE, parseConfiguration );
				loader.addEventListener ( IOErrorEvent.IO_ERROR, onConfigurationError );
				loader.load ( new URLRequest ( path ) );
		}
		
		protected function parseConfiguration ( evt : Event ) : void
		{
			try
			{
				rawXML = new XML ( evt.target.data );
				
				walkXML ( configMap, rawXML );
				
				notifyReady ( );
				
			}catch ( e : Error )
			{
				notifyError ( "Malformed Configuration => " + e.message );
			}
		}
		
		public function get ( path : String ) : *
		{
			var parts : Array = path.split(".");
			if ( parts.length == 0 ) return configMap [ path ] || null;
			
			try
			{
				var target : Object = configMap;
				for ( var i : int = 0; i < parts.length; i++ )
				{
					var part : String = parts[i];
					target = target[part];
				}
				
				return target;
			}catch ( e : Error )
			{
				trace ( "Error traversing config tree " + e );
			}
			
			return null;
			
		}
		
		protected function walkXML ( target : Object, rawXML : XML ) : void
		{
			var children : XMLList = rawXML.children();
			for ( var i : int = 0; i < children.length(); i++ )
			{
				var child : XML = children[i];
				var childName : String = child.name();
				var output : Object = {};
				
				if ( target.hasOwnProperty ( childName ) && !( target[childName] is Array ) ) target[childName] = [ target[childName] ];
				
				var numDescendents : int = child.children().length();
				var isTextNode : Boolean = numDescendents == 1 && child.children()[0].nodeKind() == "text";

				if ( child.attributes().length() > 0 )
				{
					output = {};
					if ( ( child.text() + "" ).length > 0 ) output.textValue = child.text();
					
					var attributes : XMLList = child.attributes()
					
					for ( var attr : int = 0; attr < attributes.length(); attr++ )
					{
						var attrName : String = attributes[attr].name();
						output [ attrName ] = attributes[attr];
					}
					
					if ( target [ childName ] is Array )
					{
						target [ childName ].push ( output );
					}else
					{						
						target [ childName ] = output;
					}
					
					if ( numDescendents > 0 && !isTextNode )
					{
						walkXML ( target [ childName ], child );
					}
					
				}else
				{
					if ( numDescendents > 0 && !isTextNode )
					{
						if ( target.hasOwnProperty ( childName ) )
						{
							target [ childName ] = [ target [ childName ]];
						}else
						{
							target [ childName ] = { };
						}
						
						walkXML ( target [ childName ], child );
					}else
					{
						if ( target [ childName ] is Array )
						{
							target [ childName ].push ( child.text() );
						}else
						{
							target [ childName ] = child.text();
						}
					}
				}
				
			}
		}
		
		protected function onConfigurationError ( evt : ErrorEvent ) : void
		{
			notifyError ( evt.text );
		}
		
		protected function notifyReady ( ) : void
		{
			dispatchEvent ( new ConfigEvent ( ConfigEvent.CONFIG_READY ) );
		}
		
		protected function notifyError ( reason : String ) : void
		{
			dispatchEvent ( new ConfigEvent ( ConfigEvent.CONFIG_ERROR, reason ) );
		}
		

	}
}

class Private{}