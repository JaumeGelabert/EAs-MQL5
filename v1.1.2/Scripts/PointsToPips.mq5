//+------------------------------------------------------------------+
//|                                                 PointsToPips.mq5 |
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
   Alert(" ");
   double UnificarDigitos = MathPow(10,_Digits-1);
   Alert("Unificar Digitos: ", UnificarDigitos);


   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
   double Spread = (Ask-Bid);
   Alert("Spread in POINTS: ", NormalizeDouble(Spread,_Digits));
   double SpreadInPips = NormalizeDouble(Spread, _Digits)*UnificarDigitos;
   Alert("Spread in PIPS: ", NormalizeDouble(SpreadInPips, _Digits));
  }
//+------------------------------------------------------------------+
