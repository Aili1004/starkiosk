package com.snepo.givv.cardbrowser.model
{
	import com.snepo.givv.cardbrowser.view.core.ImageCache;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class PartnerModel extends EventDispatcher
	{
		protected var _partners : Array = [];
		protected var model : Model;

		public function PartnerModel()
		{
			super( this );
		}

		public function populate ( source : XML ) : void
		{
			model = Model.getInstance();

			var list : XMLList = source..partner;

			for ( var i : int = 0; i < list.length(); i++ )
			{
				var item : XML = list[i];
				var id : String = item.@id + "";
				var name : String = item.name.text() + "";
				var receiptInfo : String = item.receiptinfo.text() + "";

				var coinCommission : Number = Number ( item.coin_commission.text() ) || 0;
				var coinFees : Number = Number ( item.coin_fees.text() ) || 0;

				var noteCommission : Number = Number ( item.note_commission.text() ) || 0;
				var noteFees : Number = Number ( item.note_fees.text() ) || 0;

				var cardCommission : Number = Number ( item.card_commission.text() ) || 0;
				var cardFees : Number = Number ( item.card_fees.text() ) || 0;

				_partners.push ( { id : id, name : name, receiptInfo : receiptInfo, coins : { commission : coinCommission, fees : coinFees } , notes : { commission : noteCommission, fees : noteFees } , cards : { commission : cardCommission, fees : cardFees } } );
			}

			dispatchEvent ( new Event ( Event.COMPLETE ) );
		}

		public function getCommissionAndFees ( id : String, paymentMethod : String ) : Object
		{
			var partner : Object = getPartnerByID ( id );

			if ( !partner ) return { fees : 0, commission : 0 };

			switch ( paymentMethod )
			{
				case CartModel.COINS :
				{
					return partner.coins;
					break;
				}

				case CartModel.NOTES :
				{
					return partner.notes;
					break;
				}

				case CartModel.CARDS :
				{
					return partner.cards;
					break;
				}
			}

			return { fees : 0, commission : 0 };
		}

		public function getCommissionedPrice ( id : String, paymentMethod : String, card : Object ) : Number
		{
			var price : Number = card.price;
			var comms : Object = getCommissionAndFees ( id, paymentMethod );

			if ( comms.fees == 0 && comms.commission == 0 ) return price;
			if ( comms.commission == 0 ) return price + comms.fees;

			return ( price + comms.fees ) * ( 1 + ( comms.commission / 100 ) );
		}

		public function getMaxValueForBalanceWithCommission ( id : String, paymentMethod : String, balance : Number ) : Number
		{
			balance -= Model.getInstance().cart.commissionedEstimateTotal;

			var comms : Object = getCommissionAndFees ( id, paymentMethod );

			if ( comms.fees == 0 && comms.commission == 0 ) return balance;
			if ( comms.commission == 0 && comms.fees != 0 ) return balance - comms.fees;

			var cardQty : int = 1;
			var net : Number = ( balance ) * ( 1 - ( comms.commission / 100 ) ); // % of balance (not card value)
			var remainder : Number = net;
			while ( remainder - comms.fees > model.host.maxCardValue )
			{
				remainder -= model.host.maxCardValue + comms.fees;
				cardQty += 1;
			}

			var maxValue : Number = net - ( comms.fees * cardQty );
			return ( Math.round(maxValue * 10000) / 10000 ); // 4 decimal places
		}

		public function getPartnerByID ( id : String ) : Object
		{
			for ( var i : int = 0; i < partners.length; i++ )
			{
				var partner : Object = partners[i];
				if ( ( partner.id + "") == id ) return partner;
			}

			return null;
		}

		public function getReceiptText ( id : String ) : String
		{
			var lineBreak : String = "----------------------------------------------";
			var totalLength : int = lineBreak.length;

			var partner : Object = getPartnerByID ( id );
			if ( !partner ) return "========= UNKNOWN PARTNER =======\n\n";
			if ( partner.receiptInfo.length == 0 ) return "";

			var dashesToAdd : int = lineBreak.length - partner.name.length - 5;

			var receipt : String = "--- " + partner.name + " " + new Array ( dashesToAdd+1 ).join("-") + "\n\n";
				receipt += partner.receiptInfo + "\n\n";
				receipt += lineBreak + "\n\n";

			return receipt;
		}

		public function get partners ( ) : Array
		{
			return _partners;
		}
	}
}