//+------------------------------------------------------------------+
//|                                            oneTradePerCandle.mq5 |
//|                                                         Falsitus |
//|                                          www.gelabertcapital.com |
//+------------------------------------------------------------------+
#property copyright "Falsitus"
#property link      "www.gelabertcapital.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---

//--- INICIO CODIGO AÑADIR A ONTICK() EN EXPERT ADVISOR
   static datetime prevTime=0;
   datetime lastTime[1];
   if(CopyTime(_Symbol,_Period,0,1,lastTime)==1 && prevTime!=lastTime[0])
     {
      prevTime=lastTime[0];

      //--- AÑADIR AQUÍ EL CODIGO QUE QUIERES QUE CORRA AL FINAL DE CADA VELA
     }
   else
     {
      //--- AÑADIR AQUÍ EL MENSAJE "WE ALREADY OPENED A TRADE FOR THIS CANDLE"
     }
//--- FINAL CODIGO AÑADIR A ONTICK() EN EXPERT ADVISOR


  }
//+------------------------------------------------------------------+
