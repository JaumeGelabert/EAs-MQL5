//+------------------------------------------------------------------+
//|                                                        3SMAs.mq5 |
//|                                          Copyright 2020,Falsitus |
//|                                          www.gelabertcapital.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020,Falsitus"
#property link      "http://www.gelabertcapital.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

#include <isTradingAllowed.mqh>
#include <optimalLotSize.mqh>
#include <getOrderID.mqh>

//--- Definiciones MQL4 --> MQL5
#define SELECT_BY_TICKET 1;

//--- Riesgo por operacion
//--- Expresar en base 1. Necesario para <optimalLotSize.mqh>
input double RiesgoPorOperacion = 0.02;

//--- Definicion de variables externas SMAs
input int periodoSMA_A = 9;
input int periodoSMA_B = 21;
input int periodoSMA_C = 65;

//--- Valor ADX necesario para entrar
input double Valor_ADX_Necesario = 10;

//--- Definicion de variables externas SL, TP originales segun dígitos
//--- 5 digitos
//--- Tambien se tiene en cuenta en <optimalLotSize.mqh>
input double SL_5digitos = 0.00250;
input double TP_5digitos = 0.00550;
//--- 4 digitos
input double SL_4digitos = 0.0250;
input double TP_4digitos = 0.0550;
//--- 3 digitos
input double SL_3digitos = 0.250;
input double TP_3digitos = 0.550;

//--- Trailing SL
input double PipsFromEntry = 0.00150;
input double ProfitParaTrailSL = 10;

//--- Definicion de variables globales
int OrderID;
double entryPrice;
int magicNumber_3SMA = 921;

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
   Alert("------------------------------------------------------------------");
   Alert("EA cerrándose.");
   Alert("------------------------------------------------------------------");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

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

//--- Valor del ADX en la vela actual
   double Valor_ADX = NormalizeDouble(ADX_Array[0],2);

//--- Logica para determinar entradas
   if(PositionsTotal() == 0) //--- Solo tomamos una operación a la vez. Si ya hay una posición habierta, no abrimos mas.
     {
      if(Digits() == 5) //--- 5 DIGITOS
        {
         if(((((SMA_Array_A[0]<SMA_Array_B[0]) && (SMA_Array_C[0]<SMA_Array_A[0])) && SMA_Array_A[1]>SMA_Array_B[1])) && (Valor_ADX > Valor_ADX_Necesario))   //--- SELL
           {

            //--- Definiciones necesarias para Comprobar Spread
            double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
            double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
            double Spread = (Ask-Bid);
            double SpreadInPips_5Digits = NormalizeDouble(Spread, _Digits)*10000;
            Comment("Spread: ", NormalizeDouble(Spread, _Digits), " [", SpreadInPips_5Digits,"]");

            //--- Comprobar Spread
            if(SpreadInPips_5Digits < spreadMaximo) //--- Podemos operar. Spread dentro de las condiciones aceptadas.
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
               request.magic = magicNumber_3SMA;
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
            else  //--- No operamos, Spread demasiado alto
              {
               Print("Spread demasiado alto. No operamos. Spread: ", SpreadInPips_5Digits,".");
              }

           }

         if((((SMA_Array_A[0]>SMA_Array_B[0]) && (SMA_Array_C[0]>SMA_Array_A[0])) && SMA_Array_A[1]<SMA_Array_B[1]) && (Valor_ADX > Valor_ADX_Necesario)) //--- BUY
           {

            //--- Definiciones necesarias para Comprobar Spread
            double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
            double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
            double Spread = (Ask-Bid);
            double SpreadInPips_5Digits = NormalizeDouble(Spread, _Digits)*10000;
            Comment("Spread: ", NormalizeDouble(Spread, _Digits), " [", SpreadInPips_5Digits,"]");

            //--- Comprobar Spread
            if(SpreadInPips_5Digits < spreadMaximo) //--- Podemos operar. Spread dentro de las condiciones aceptadas.
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
               request.sl = entryPrice - SL_5digitos;
               request.tp = entryPrice + TP_5digitos;
               request.deviation = 10; //Se expresa en puntos. 10 -> 1 pip
               request.type_filling = ORDER_FILLING_IOC; //---Se ejecutará el máximo volumen[optimalLotSize] posible teniendo en cuenta request.deviation. Se puede ejecutar parcialmente.
               request.magic = magicNumber_3SMA;
               request.comment = "BUY_5"; //--- IMPORTANTE: Sirve para optimizar parámetros. "BUY_5" o "SELL_5".

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
            else  //--- No operamos, Spread demasiado alto
              {
               Print("Spread demasiado alto. No operamos. Spread: ", SpreadInPips_5Digits,".");
              }
           }
         else
           {
            Print("Buscando operaciones");
           }
        }
      else
         if(Digits() == 4)
           {
            if(((SMA_Array_A[0]<SMA_Array_B[0]) && (SMA_Array_C[0]<SMA_Array_A[0])) && SMA_Array_A[1]>SMA_Array_B[1]) //Venta
              {

               entryPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);

               //---Detalles orden de venta
               MqlTradeRequest request= {0};
               MqlTradeResult result= {0};

               double Order_SL = entryPrice + 0.0300;
               double Order_TP = entryPrice - 0.0300;


               request.action = TRADE_ACTION_DEAL;
               request.type = ORDER_TYPE_SELL;
               request.symbol = _Symbol;
               request.volume = optimalLotSize();
               request.price = entryPrice;
               request.sl = Order_SL;
               request.tp = Order_TP;
               request.deviation = 10; //Se expresa en puntos. 10 -> 1 pip
               request.type_filling = ORDER_FILLING_IOC;
               request.magic = magicNumber_3SMA;

               OrderID = OrderSend(request,result); //---Enviamos operacion

               if(OrderID == -1)
                 {
                  Print("ERROR al enviar la orden. Order ID: ", OrderID);
                 }
               else
                 {
                  Print("Orden de compra enviada correctamente: ", OrderID);
                 }
              }

            if(((SMA_Array_A[0]>SMA_Array_B[0]) && (SMA_Array_C[0]>SMA_Array_A[0])) && SMA_Array_A[1]<SMA_Array_B[1]) //Compra
              {

               entryPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);

               //---Detalles orden de venta
               MqlTradeRequest request= {0};
               MqlTradeResult result= {0};

               double Order_SL = entryPrice - 0.00300;
               double Order_TP = entryPrice + 0.00300;

               request.action = TRADE_ACTION_DEAL;
               request.type = ORDER_TYPE_BUY;
               request.symbol = _Symbol;
               request.volume = optimalLotSize();
               request.price = entryPrice;
               request.sl = Order_SL;
               request.tp = Order_TP;
               request.deviation = 10; //Se expresa en puntos. 10 -> 1 pip
               request.type_filling = ORDER_FILLING_IOC;
               request.magic = magicNumber_3SMA;

               OrderID = OrderSend(request,result); //---Enviamos operacion

               if(OrderID == -1)
                 {
                  Print("Error al enviar la orden. Order ID: ", OrderID);
                 }
               else
                 {
                  Print("Orden de compra enviada correctamente: ", OrderID);
                 }
              }
            else
              {
               Print("Buscando operaciones");
              }
           }
         else
            if(Digits() == 3)
              {
               if(((SMA_Array_A[0]<SMA_Array_B[0]) && (SMA_Array_C[0]<SMA_Array_A[0])) && SMA_Array_A[1]>SMA_Array_B[1]) //Venta
                 {

                  entryPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);

                  //---Detalles orden de venta
                  MqlTradeRequest request= {0};
                  MqlTradeResult result= {0};

                  double Order_SL = entryPrice + 0.300;
                  double Order_TP = entryPrice - 0.300;


                  request.action = TRADE_ACTION_DEAL;
                  request.type = ORDER_TYPE_SELL;
                  request.symbol = _Symbol;
                  request.volume = optimalLotSize();
                  request.price = entryPrice;
                  request.sl = Order_SL;
                  request.tp = Order_TP;
                  request.deviation = 10; //Se expresa en puntos. 10 -> 1 pip
                  request.type_filling = ORDER_FILLING_IOC;
                  request.magic = magicNumber_3SMA;

                  OrderID = OrderSend(request,result); //---Enviamos operacion
                  if(OrderID == -1)
                    {
                     Print("ERROR al enviar la orden. Order ID: ", OrderID);
                    }
                  else
                    {
                     Print("Orden de compra enviada correctamente: ", OrderID);
                    }
                 }

               if(((SMA_Array_A[0]>SMA_Array_B[0]) && (SMA_Array_C[0]>SMA_Array_A[0])) && SMA_Array_A[1]<SMA_Array_B[1]) //Compra
                 {

                  entryPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);

                  //---Detalles orden de venta
                  MqlTradeRequest request= {0};
                  MqlTradeResult result= {0};

                  double Order_SL = entryPrice - 0.00300;
                  double Order_TP = entryPrice + 0.00300;

                  request.action = TRADE_ACTION_DEAL;
                  request.type = ORDER_TYPE_BUY;
                  request.symbol = _Symbol;
                  request.volume = optimalLotSize();
                  request.price = entryPrice;
                  request.sl = Order_SL;
                  request.tp = Order_TP;
                  request.deviation = 10; //Se expresa en puntos. 10 -> 1 pip
                  request.type_filling = ORDER_FILLING_IOC;
                  request.magic = magicNumber_3SMA;

                  OrderID = OrderSend(request,result); //---Enviamos operacion


                  if(OrderID == -1)
                    {
                     Print("Error al enviar la orden. Order ID: ", OrderID);
                    }
                  else
                    {
                     Print("Orden de compra enviada correctamente: ", OrderID);
                    }
                 }
               else
                 {
                  //Alert("Buscando operaciones");
                 }
              }

     }
   else
      if(PositionsTotal()!=0) //Modificar parámetros si es necesario
        {
         Alert("------------------------------------------------------------------");
         Alert("Se ha intentado enviar una orden. Ya hay posiciones abiertas");
         Alert("Se intentará optimizar posición abierta!");
         Alert("------------------------------------------------------------------");

         //--- Definiciones Precio Entrada, Precio Actual, Direccion de la operacion
         double OriginalEntryPoint = PositionGetDouble(POSITION_PRICE_OPEN);
         double ActualPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double PositionProfit = PositionGetDouble(POSITION_PROFIT);
         int ticket = PositionGetTicket(0);

         //--- Codigo que muestra en pantalla el resultado en PIPS y en EUROS de la operación
         if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) //--- Si es en direccion BUY
           {
            double ResultadoEnPips = (ActualPrice-OriginalEntryPoint);
            Comment("Resultado en PIPS: ",NormalizeDouble(ResultadoEnPips,6), "[", NormalizeDouble(PositionGetDouble(POSITION_PROFIT),3),"€]");
           }
         else
            if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) //--- Si es en direccion SELL
              {
               double ResultadoEnPips = (OriginalEntryPoint-ActualPrice);
               Comment("Resultado en PIPS: ",NormalizeDouble(ResultadoEnPips,6), "[", NormalizeDouble(PositionGetDouble(POSITION_PROFIT),3),"€]");
              }
            else
              {
               Alert("Comprobar 'POSITION_TYPE', funcion mostrar pips y beneficio en moneda");
              }

         if(PositionGetString(POSITION_COMMENT) == "BUY_5") //--- Si es una operacion BUY
           {
            Alert("Optimizar segun BUY_5 signal");

            //---Cambio de parámetros para BUY_5 signal
            if(PositionGetDouble(POSITION_PROFIT) > ProfitParaTrailSL) //--- Si PROFIT es mayor a INPUT --> Trailing SL
              {
               double new_SL = PositionGetDouble(POSITION_PRICE_OPEN) - PipsFromEntry; //--- Definimos nuevo SL
               Alert("Trailing SL...");
               Alert("New SL: ", new_SL,".");

               double Order_TP = PositionGetDouble(POSITION_TP);
               double entryPriceTrailing = PositionGetDouble(POSITION_PRICE_OPEN);

               //--- Preparamos para modificar datos de la operacion
               MqlTradeRequest request= {0};
               MqlTradeResult result= {0};

               request.action = TRADE_ACTION_SLTP;
               request.position = PositionGetTicket(0);
               request.symbol = _Symbol;
               request.sl = new_SL; //--- Si modificamos el SL
               request.tp = Order_TP; //--- No modificamos el TP
               request.magic = magicNumber_3SMA;
               request.comment = "Trailing SL BUY_5";

               OrderID = OrderSend(request,result); //--- Enviamos operacion modificada
              }
           }
         else
            if(PositionGetString(POSITION_COMMENT) == "SELL_5") //--- Si es una operacion SELL
              {
               Alert("Optimizar segun SELL_5 signal");

               //---Cambio de parámetros para SELL_5 signal
               if(PositionGetDouble(POSITION_PROFIT) > ProfitParaTrailSL) //--- Si PROFIT es mayor a INPUT --> Trailing SL
                 {
                  double new_SL = PositionGetDouble(POSITION_PRICE_OPEN) + PipsFromEntry; //--- Definimos nuevo SL
                  Alert("Trailing SL...");
                  Alert("New SL: ", new_SL,".");

                  double Order_TP = PositionGetDouble(POSITION_TP);

                  //--- Preparamos para modificar datos de la operacion
                  MqlTradeRequest request= {0};
                  MqlTradeResult result= {0};

                  request.action = TRADE_ACTION_SLTP;
                  request.position = PositionGetTicket(0);
                  request.symbol = _Symbol;
                  request.sl = new_SL; //--- Si modificamos el SL
                  request.tp = Order_TP; //--- No modificamos el TP
                  request.magic = magicNumber_3SMA;
                  request.comment = "Trailing SL SELL_5";

                  OrderID = OrderSend(request,result); //---Enviamos operacion modificada
                 }
              }

        }
      else //--- Si no hay operaciones...
        {
         //--- ... seguimos buscando entradas
        }
  }
//+------------------------------------------------------------------+
