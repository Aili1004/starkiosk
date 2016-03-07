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
	import flash.media.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.net.*;
	
	public class VideoPlayer extends Component
	{
		protected var conn  : NetConnection;
		protected var strm  : NetStream;
		protected var video : Video;

		protected var lastSource : String;

		public function VideoPlayer()
		{
			super();
		}

		override protected function createUI():void
		{
			super.createUI();

			addChild ( video = new Video(320, 240) );
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();
			video.width = width;
			video.height = height;
		}

		override public function dispose ( ) : void
		{
			closeStreams();
		}

		public function playVideo ( path : String ) : void
		{
			lastSource = path;
			
			closeStreams();

			conn = new NetConnection();
			conn.addEventListener ( NetStatusEvent.NET_STATUS, handleConnStatus, false, 0, true );
			conn.addEventListener ( AsyncErrorEvent.ASYNC_ERROR, handleAsyncError, false, 0, true );
			conn.connect ( null );

			strm = new NetStream ( conn );
			strm.addEventListener ( NetStatusEvent.NET_STATUS, handleStreamStatus, false, 0, true );
			strm.addEventListener ( AsyncErrorEvent.ASYNC_ERROR, handleAsyncError, false, 0, true );
			strm.play ( path );

			video.attachNetStream ( strm );
		}

		public function stopVideo ( ) : void
		{
			performComplete();
		}

		protected function handleConnStatus ( evt : NetStatusEvent ) : void
		{
			
		}

		protected function handleAsyncError ( evt : AsyncErrorEvent ) : void
		{
			
		}

		protected function handleStreamStatus ( evt : NetStatusEvent ) : void
		{
			switch ( evt.info.code )
			{
				case "NetStream.Play.Stop" :
				{
					playVideo ( lastSource );
					break;
				}
			}			
		}

		protected function performComplete ( ) : void
		{
			closeStreams();
			dispatchEvent ( new Event ( Event.COMPLETE ) );
		}

		protected function closeStreams ( ) : void
		{
			if ( conn )
			{
				conn.removeEventListener ( NetStatusEvent.NET_STATUS, handleConnStatus );
				conn.removeEventListener ( AsyncErrorEvent.ASYNC_ERROR, handleAsyncError );
				conn.close();
				conn = null;
			}

			if ( strm )
			{
				strm.removeEventListener ( NetStatusEvent.NET_STATUS, handleStreamStatus );
				strm.removeEventListener ( AsyncErrorEvent.ASYNC_ERROR, handleAsyncError );
				strm.close();
				strm = null;
			}

			video.attachNetStream ( null );
		}




	}
}