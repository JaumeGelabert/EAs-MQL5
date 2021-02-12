//+------------------------------------------------------------------+
//|                                                   TrailingSL.mq5 |
//|                                                         Falsitus |
//|                                          www.gelabertcapital.com |
//+------------------------------------------------------------------+
#property copyright "Falsitus"
#property link      "www.gelabertcapital.com"
#property version   "1.00"

#include <getOrderID.mqh>

int OrderID;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---

   if(PositionsTotal() == 0)
     {
      Alert("NO HAY OPERACIONES ABIERTAS");
     }
   else
     {
      int ticket = PositionGetTicket(0); //Seleccionamos orden

      //--- Definimos todo lo necesario para hacer el Trailing SL
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);

      double step = 0; //--- Step
      double slBuy  = NormalizeDouble(Ask-0.0001,_Digits); //--- SL Buy
      double slSell = NormalizeDouble(Bid+0.0001,_Digits); //--- SL Sell
      double positionPriceOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),_Digits);; //--- Precio de entrada de la posición
      double positionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),_Digits); //--- SL en mercado de la posición

      double Order_TP = PositionGetDouble(POSITION_TP);
      Alert(" ");
      Alert("Bid: ", Bid);
      Alert("Ask: ", Ask);
      Alert("Position Price Open: ", positionPriceOpen);
      Alert("SL: ", positionSL);
      Alert("step: ", step);
      Alert("slBuy: ", slBuy);
      Alert("slSell: ",slSell);

      if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)   //--- Si es en direccion BUY
        {
         Alert("BUY");
         if(Bid > positionPriceOpen)
            Alert("Se cumple condicion 1: ", Bid, ">", positionPriceOpen);
         else
            Alert("NO se cumple condicion 1. Estamos en PÉRDIDA!: ", Bid, "<", positionPriceOpen);

         if((positionSL + step) < slBuy)
            Alert("Se cumple condicion 2: ", (positionSL + step), "<", slBuy);
         else
            Alert("NO se cumple la condicion 2");

         if(Bid > positionPriceOpen && ((positionSL + step) < slBuy))  //--- Si Bid es mayor al precio de entrada, y SL en mercado + 'step' es menor al SL*,...
           {
            //--- Preparamos para modificar datos de la operacion
            MqlTradeRequest request= {0};
            MqlTradeResult result= {0};

            request.action = TRADE_ACTION_SLTP;
            request.position = ticket;
            request.symbol = _Symbol;
            request.sl = slBuy; //--- Si modificamos el SL
            request.tp = Order_TP; //--- No modificamos el TP
            request.magic = 123;
            request.comment = "Trailing SL BUY_5";

            OrderID = OrderSend(request,result); //--- Enviamos operacion modificada
           }
        }
      else
         if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)   //--- Si es en direccion SELL
           {
            Alert("SELL");

            if(Ask < positionPriceOpen)
               Alert("Se cumple condicion 1: ", Ask, "<", positionPriceOpen);
            else
               Alert("No se cumple condicion 1. Estamos en PÉRDIDA!: ", Ask, ">", positionPriceOpen);

            if((positionSL-step) > slSell)
               Alert("Se cumple condicion 2: ", (positionSL-step), ">", slSell);
            else
               Alert("NO se cumple la condicion 2", (positionSL-step), "<", slSell);

            if(Ask < positionPriceOpen && ((positionSL-step) > slSell))
              {
               //--- Preparamos para modificar datos de la operacion
               MqlTradeRequest request= {0};
               MqlTradeResult result= {0};

               request.action = TRADE_ACTION_SLTP;
               request.position = ticket;
               request.symbol = _Symbol;
               request.sl = slSell; //--- Si modificamos el SL
               request.tp = Order_TP; //--- No modificamos el TP
               request.magic = 123;
               request.comment = "Trailing SL SELL_5";

               OrderID = OrderSend(request,result); //---Enviamos operacion modificada
              }
           }
     }
  }
//+------------------------------------------------------------------+
