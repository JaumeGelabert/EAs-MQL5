//+------------------------------------------------------------------+
//|                                            GetSpreadInPoints.mqh |
//|                                                         Falsitus |
//|                                  https://www.gelabertcapital.com |
//+------------------------------------------------------------------+
#property copyright "Falsitus"
#property link      "https://www.gelabertcapital.com"
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
double GetSpreadInPips()
  {
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
   double Spread = Ask-Bid;
   double SpreadInPoints = NormalizeDouble(Spread, _Digits);
   double UnificarDigitos = MathPow(10,_Digits-1);
   double SpreadInPips = (NormalizeDouble(Spread, _Digits))*UnificarDigitos;
   Comment("Spread in POINTS for ", _Symbol,": ", SpreadInPoints, " [", SpreadInPips,"]");
   Alert("Spread in POINTS for ", _Symbol,": ", SpreadInPoints, " [", SpreadInPips,"]");
   return(SpreadInPips);

  }
//+------------------------------------------------------------------+
