//+------------------------------------------------------------------+
//|                                                Engulfing+RSI.mq5 |
//|                                                         Falsitus |
//|                                  https://www.gelabertcapital.com |
//+------------------------------------------------------------------+
#property copyright "Falsitus"
#property link      "https://www.gelabertcapital.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

#include <isTradingAllowed.mqh>
#include <optimalLotSize.mqh>
#include <getOrderID.mqh>
#include <getSpreadInPoints.mqh>

//--- Definiciones MQL4 --> MQL5
#define SELECT_BY_TICKET 1;

//--- Riesgo por operacion
//--- Expresar en base 1. Necesario para <optimalLotSize.mqh>
input double RiesgoPorOperacion = 0.02;
input double SL_5digitos = 0.00250;
input double TP_5digitos = 0.00500;

//--- Definicion de variables globales
int OrderID;
double entryPrice;
int magicNumber_EngRSI = 1005;

//--- Spread máximo con el que tomaremos la posición
input double spreadMaximo = 3.00;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Alert(" ");
//--- Comprobar que se puede operar
   isTradingAllowed();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   static datetime prevTime=0;
   datetime lastTime[1];
   if(CopyTime(_Symbol,_Period,0,1,lastTime)==1 && prevTime!=lastTime[0])
     {
      prevTime=lastTime[0];
      //--- EL CODIGO DENTRO DE ESTA FUNCIÓN if, CORRE UNA VEZ POR VELA. DEPENDE DEL "_Period".

      //--- CALCULAMOS DATOS NECESARIOS PARA DETERMINAR SI HAY ENTRADA
      //--- Velas
      double open1 = NormalizeDouble(iOpen(_Symbol, _Period, 1), _Digits);
      double open2 = NormalizeDouble(iOpen(_Symbol, _Period, 2), _Digits);
      double close1 = NormalizeDouble(iClose(_Symbol, _Period, 1), _Digits);
      double close2 = NormalizeDouble(iClose(_Symbol, _Period, 2), _Digits);
      double low1 = NormalizeDouble(iLow(_Symbol, _Period, 1), _Digits);
      double low2 = NormalizeDouble(iLow(_Symbol, _Period, 2), _Digits);
      double high1 = NormalizeDouble(iHigh(_Symbol, _Period, 1), _Digits);
      double high2 = NormalizeDouble(iHigh(_Symbol, _Period, 2), _Digits);
      //--- Ask, Bid & Spread
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
      double Spread = (Ask-Bid);
      double SpreadInPips_5Digits = NormalizeDouble(Spread, _Digits)*10000;


      if(low1 < low2 &&// First bar's Low is below second bar's Low
         high1 > high2 &&// First bar's High is above second bar's High
         close1 < open2 && //First bar's Close price is below second bar's Open
         open1 > close1 && //First bar is a bearish bar
         open2 < close2)   //Second bar is a bullish bar
        {
         //--- VELA ENVOLVENTE BAJISTA
         if(GetSpreadInPips() < spreadMaximo)   //--- Podemos operar. Spread dentro de las condiciones aceptadas.
           {
            //--- Detalles operacion SELL
            MqlTradeRequest request= {0};
            MqlTradeResult result= {0};

            entryPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

            request.action = TRADE_ACTION_DEAL;
            request.type = ORDER_TYPE_SELL; //--- Direccion de la operacion
            request.symbol = _Symbol;
            request.volume = optimalLotSize(); //--- Calculado en <optimalLotSize.mqh>
            request.price = entryPrice;
            request.sl = entryPrice + SL_5digitos;
            request.tp = entryPrice - TP_5digitos;
            request.deviation = 10; //--- Se expresa en puntos. 10 -> 1 pip
            request.type_filling = ORDER_FILLING_IOC; //---Se ejecutará el máximo volumen[optimalLotSize] posible teniendo en cuenta request.deviation. Se puede ejecutar parcialmente.
            request.magic = magicNumber_EngRSI;
            request.comment = "SELL_5"; //--- IMPORTANTE: Sirve para optimizar parámetros. "BUY_5" o "SELL_5".

            OrderID = OrderSend(request,result); //--- Enviamos operacion SELL

            //--- MEJORAR ERROR HANDLE
            if(OrderID == -1)
              {
               Print("Error al enviar la orden. Order ID: ", OrderID);
              }
            else
              {
               Print("Orden de venta enviada correctamente. ORDER ID --> ", OrderID);
              }
           }
         else
           {
            Alert(GetSpreadInPips());
           }
        }
     }
   else
     {
      //--- AÑADIR AQUÍ EL MENSAJE "WE ALREADY OPENED A TRADE FOR THIS CANDLE"
     }
  }
//+------------------------------------------------------------------+
