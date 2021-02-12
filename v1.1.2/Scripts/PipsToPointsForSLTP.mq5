//+------------------------------------------------------------------+
//|                                          PipsToPointsForSLTP.mq5 |
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
  double sl = 5;
  double tp = 20;
  double UnificarDigitos = MathPow(10,_Digits-1);
  double sl_points = sl/UnificarDigitos;
  
  Alert("SL changed from PIPS [", sl, " pips] to POINTS: ", sl_points);
  }
//+------------------------------------------------------------------+
