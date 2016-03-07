package com.snepo.givv.cardbrowser.view.screens
{
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.filters.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.text.*;

	public class StarKeyboardScreen extends Screen
	{

		var closeIcon : MovieClip = new CloseIcon();
    var starKeyboard : MovieClip = new StarKeyboard();
    var letterInputBox : MovieClip = new LetterInputBox();

		public function StarKeyboardScreen ( )
		{
			addChild(closeIcon);
      addChild(starKeyboard);
      addChild(letterInputBox);
			closeIcon.closeBtn.addEventListener ( MouseEvent.CLICK, closeCurrentPage );
      starKeyboard.addEventListener ( MouseEvent.CLICK, singleLetterClicked );
		}

		protected function closeCurrentPage(evt : MouseEvent) : void {
			View.getInstance().currentScreenKey = View.HOME_SCREEN;
		}

    protected function singleLetterClicked( evt : MouseEvent ) : void
		{
      var inputText : String = ((evt.target.overState as DisplayObjectContainer).getChildAt(1) as TextField).text;

      letterInputBox.unitNumber.text = letterInputBox.unitNumber.text.toString();

      if (inputText == "Del") {
        var lastChar = letterInputBox.unitNumber.text.charAt(letterInputBox.unitNumber.text.length-1);
        letterInputBox.unitNumber.text = letterInputBox.unitNumber.text.replace(lastChar, "");

      } else if (inputText == "NEXT") {


      } else if (inputText == "space") {
          letterInputBox.unitNumber.text += " ";
      } else {
          letterInputBox["unitNumber"].text += inputText;
      }

		}
  }
}
