//+------------------------------------------------------------------+
//|                                               optimalLotSize.mqh |
//|                                                         Falsitus |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Falsitus"
#property link      ""
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
double optimalLotSize()
  {
   double lotSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE); //--- Miramos el tamaño de contrato
   double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY); //--- Miramos la Equidad de la cuenta
   double maxLossPercent = RiesgoPorOperacion; //--- Definimos el porcentaje que queremos perder. Variable INPUT declarada en el documento principal
   int maxLossInPips = SL_5digitos; //--- Esta linea da error, pero la variable esta definida en el documento principal (Ignorar Error)
   double maxLossEuros = (accountEquity * maxLossPercent); //--- Cantidad máxima que queremos perder en la moneda base
   double tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE); //--- Valor de cada Tick del simbolo
   double maxLossInQuoteCurrency = (maxLossEuros / tickValue);
   double optimalLotSize = (maxLossInQuoteCurrency/(maxLossInPips * 0.0001)/lotSize);
   double normalizedOptimalLotSize = NormalizeDouble(optimalLotSize,2);
   return normalizedOptimalLotSize;
  }
