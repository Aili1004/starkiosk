package com.snepo.givv.cardbrowser.view.core
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.geom.*;

	public interface ILayoutStrategy
	{
		function layout ( target : Container, animated : Boolean = true, size : Point = null ) : void;
	}
	
}