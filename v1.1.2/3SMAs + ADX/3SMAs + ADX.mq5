//+------------------------------------------------------------------+
//|                                                 new3SMAs+ADX.mq5 |
//|                                                         Falsitus |
//|                                          www.gelabertcapital.com |
//+------------------------------------------------------------------+
#property copyright "Falsitus"
#property link      "www.gelabertcapital.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include Files & Others                                           |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

#include <isTradingAllowed.mqh>
#include <optimalLotSize.mqh>
#include <getOrderID.mqh>

//--- Definiciones MQL4 --> MQL5
#define SELECT_BY_TICKET 1;

//+------------------------------------------------------------------+
//| Risk Management & Trailing SL                                    |
//+------------------------------------------------------------------+
//--- Expresar en base 1. Necesario para <optimalLotSize.mqh>
input double RiesgoPorOperacion = 0.02;
//--- Spread máximo con el que es posible tomar posiciones
input double spreadMaximo = 3.00; //--- Expresado en Pips

//--- Pasar de Pips a Points teniendo en cuenta los digitos del activo
double UnificarDigitos = MathPow(10,_Digits-1);
//--- SL & Trailing SL
input double input_SL_pips = 25;
double sl_points = input_SL_pips/UnificarDigitos;
input double step = 0;
input double pipsFromPriceBuy = 0.001;
input double pipsFromPriceSell = 0.001;
double pointsFromPriceBuy = pipsFromPriceBuy/UnificarDigitos;
double pointsFromPriceSell = pipsFromPriceSell/UnificarDigitos;
//--- TP
input double riskRewardRatio = 2;
double TP_pips = riskRewardRatio * input_SL_pips;
double tp_points = TP_pips/UnificarDigitos;

//+------------------------------------------------------------------+
//| Definicion SMAs & ADX                                            |
//+------------------------------------------------------------------+
//--- SMAs
input int periodoSMA_A = 9;
input int periodoSMA_B = 21;
input int periodoSMA_C = 65;

//--- ADX
//--- Valor necesario para entrar en una posicion
input double Valor_ADX_Necesario = 10;

//+------------------------------------------------------------------+
//| Definicion Variables Globales                                    |
//+------------------------------------------------------------------+
int OrderID;
double entryPrice;
int magicNumber_3SMA = 921;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   MqlDateTime STime;
   datetime time_current=TimeCurrent(STime);
   datetime time_local=TimeLocal(STime);

   string moneda = AccountInfoString(ACCOUNT_CURRENCY);
   string loginCuenta = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   string broker = AccountInfoString(ACCOUNT_COMPANY);
   int tradeMode = AccountInfoInteger(ACCOUNT_TRADE_MODE);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   Print(" ");
   Print("EA iniciada a fecha de: ", time_current,". [Hora Local --> ", time_local,"]");
   Print("Balance de la cuenta: ", balance," ", moneda);
   Print("Login de la cuenta: ", loginCuenta," [Broker: ", broker, "]");
   if(tradeMode == 0)
     {
      Alert(" ");
      Alert("Cuenta DEMO");
      Alert("**EA en proceso BETA. No apta para operar en REAL!**");
     }
   else
      if(tradeMode == 1)
        {
         Alert(" ");
         Alert("Cuenta LIVE");
         Alert("**EA en proceso BETA. No apta para operar en REAL!**");
         Alert("Se procede a apagar EA. Comprobar codigo.");
         ExpertRemove(); //--- Desabilitamos Autotrading
        }
      else
        {
         Alert("Comprobar en que tipo de cuenta estamos operando");
        }
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
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   Alert("Balance final: ", balance);
   Alert("--> EA Cerrada! <--");

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(PositionsTotal() == 0) //--- Si no hay operaciones abiertas, buscamos posibles entradas
     {
      //--- Codigo que hace que solo se corra el código una vez cada vela
      static datetime prevTime=0;
      datetime lastTime[1];
      if(CopyTime(_Symbol,_Period,0,1,lastTime)==1 && prevTime!=lastTime[0])
        {
         prevTime=lastTime[0];

         //+------------------------------------------------------------------+
         //| Definicion de indicadores necesarios (SMA, ADX)                  |
         //+------------------------------------------------------------------+

         //--- Arrays de SMAs para los tres periodos
         double SMA_Array_A[],SMA_Array_B[],SMA_Array_C[];

         //--- Definicion SMAs
         double SMA_A = iMA(_Symbol, 0, periodoSMA_A, 0, MODE_SMA, PRICE_CLOSE); //--- SMA Rapida
         double SMA_B = iMA(_Symbol, 0, periodoSMA_B, 0, MODE_SMA, PRICE_CLOSE); //--- SMA Lenta
         double SMA_C = iMA(_Symbol, 0, periodoSMA_C, 0, MODE_SMA, PRICE_CLOSE); //--- SMA Filtro

         //--- Datos de SMA_A (Rapida)
         ArraySetAsSeries(SMA_Array_A, true);
         CopyBuffer(SMA_A, 0, 0, 5, SMA_Array_A);

         //--- Datos de SMA_B (Lenta)
         ArraySetAsSeries(SMA_Array_B, true);
         CopyBuffer(SMA_B, 0, 0, 5, SMA_Array_B);

         //--- Datos de SMA_C (Filtro)
         ArraySetAsSeries(SMA_Array_C, true);
         CopyBuffer(SMA_C, 0, 0, 5, SMA_Array_C);

         //--- Array ADX
         double ADX_Array[];

         //--- Definicion ADX
         int ADX = iADX(_Symbol, _Period, 14);

         //--- Datos de ADX
         ArraySetAsSeries(ADX_Array, true);
         CopyBuffer(ADX, 0, 0, 3, ADX_Array);

         //--- Valor del ADX según su índice, normalizado a dos dígitos
         double Valor_ADX_0 = NormalizeDouble(ADX_Array[0],2);
         double Valor_ADX_1 = NormalizeDouble(ADX_Array[1],2);
         double Valor_ADX_2 = NormalizeDouble(ADX_Array[2],2);

         //+------------------------------------------------------------------+
         //| Lógica para determinar entradas                                  |
         //+------------------------------------------------------------------+

         if(((((SMA_Array_A[0]<SMA_Array_B[0]) && (SMA_Array_C[0]<SMA_Array_A[0])) && ((SMA_Array_A[1]>SMA_Array_B[1]) && (SMA_Array_C[1]<SMA_Array_B[1])))) && (Valor_ADX_0 > Valor_ADX_Necesario))   //--- SELL
           {

            //--- Definiciones necesarias para Comprobar Spread
            double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
            double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
            double Spread = (Ask-Bid);
            double SpreadInPips = NormalizeDouble(Spread, _Digits)*UnificarDigitos;

            //--- Comprobar Spread
            if(SpreadInPips < spreadMaximo)   //--- Podemos operar. Spread dentro de las condiciones aceptadas.
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
               request.sl = entryPrice + sl_points;
               request.tp = entryPrice - tp_points;
               request.deviation = 10; //--- Se expresa en puntos. 10 -> 1 pip
               request.type_filling = ORDER_FILLING_IOC; //---Se ejecutará el máximo volumen[optimalLotSize] posible teniendo en cuenta request.deviation. Se puede ejecutar parcialmente.
               request.magic = magicNumber_3SMA;
               request.comment = "COMENTARIO SELL";

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
            else     //--- No operamos, Spread demasiado alto
              {
               Print("Spread demasiado alto. No operamos. Spread: ", SpreadInPips,".");
              }
           }

         else
            if((((SMA_Array_A[0]>SMA_Array_B[0]) && (SMA_Array_C[0]>SMA_Array_A[0])) && ((SMA_Array_A[1]<SMA_Array_B[1]) && (SMA_Array_C[1]>SMA_Array_B[1]))) && (Valor_ADX_0 > Valor_ADX_Necesario))//--- COMPRA
              {
            //--- Definiciones necesarias para Comprobar Spread
            double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
            double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
            double Spread = (Ask-Bid);
            double SpreadInPips = NormalizeDouble(Spread, _Digits)*UnificarDigitos;

               //--- Comprobar Spread
               if(SpreadInPips < spreadMaximo)   //--- Podemos operar. Spread dentro de las condiciones aceptadas.
                 {
                  //---Detalles orden BUY
                  MqlTradeRequest request= {0};
                  MqlTradeResult result= {0};

                  entryPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

                  request.action = TRADE_ACTION_DEAL;
                  request.type = ORDER_TYPE_BUY; //--- Direccion de la operacion
                  request.symbol = _Symbol;
                  request.volume = optimalLotSize(); //--- Calculado en <optimalLotSize.mqh>
                  request.price = entryPrice;
                  request.sl = entryPrice - sl_points;
                  request.tp = entryPrice + tp_points;
                  request.deviation = 10; //Se expresa en puntos. 10 -> 1 pip
                  request.type_filling = ORDER_FILLING_IOC; //---Se ejecutará el máximo volumen[optimalLotSize] posible teniendo en cuenta request.deviation. Se puede ejecutar parcialmente.
                  request.magic = magicNumber_3SMA;
                  request.comment = "COMENTARIO BUY";

                  OrderID = OrderSend(request,result); //---Enviamos operacion BUY

                  //--- MEJORAR ERROR HANDLE
                  if(OrderID == -1)
                    {
                     Print("Error al enviar la orden. Order ID: ", OrderID);
                    }
                  else
                    {
                     Print("Orden de compra enviada correctamente: ", OrderID);
                    }
                 }
               else     //--- No operamos, Spread demasiado alto
                 {
                  Print("Spread demasiado alto. No operamos. Spread: ", SpreadInPips,".");
                 }
              }
        }
      else
        {
         Alert("Buscando operaciones...");
        }
     }
   else
      if(PositionsTotal()!=0)
        {
         //+------------------------------------------------------------------+
         //| Optimizacion de la posición. TRAILING SL                         |
         //+------------------------------------------------------------------+
         int ticket = PositionGetTicket(0); //Seleccionamos orden

         //--- Definimos todo lo necesario para hacer el Trailing SL
         double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
         double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
         double Spread = (Ask-Bid);

         double slBuy  = NormalizeDouble(Ask-pointsFromPriceBuy,_Digits); //--- SL Buy
         double slSell = NormalizeDouble(Bid+pointsFromPriceSell,_Digits); //--- SL Sell
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
               request.magic = magicNumber_3SMA;
               request.comment = "Trailing SL BUY";

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
                  Alert("NO se cumple la condicion 2: ", (positionSL-step), "<", slSell);

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
                  request.magic = magicNumber_3SMA;
                  request.comment = "Trailing SL SELL";

                  OrderID = OrderSend(request,result); //---Enviamos operacion modificada
                 }
              }
        }
      else//--- Si no hay operaciones...
        {
         //--- ... seguimos buscando entradas
        }
  }
//+------------------------------------------------------------------+
