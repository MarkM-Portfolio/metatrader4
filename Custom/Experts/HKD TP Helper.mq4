#property copyright "HKD © 2024 All Rights Reserved."
#property link "https://hkdsolutionsfx.com/"
#property description "Author: MMM"
#property icon "hkd.ico"
#property strict
#define VERSION "1.0"

extern double VolumeSize = 0.10;
extern bool ForceTP = false;
extern double ForceTPFactor = 1.3;
extern int Slippage = 0;
extern int MagicNumber = 123;

string localTime = TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS);
string timeStamp = TimeToStr(TimeLocal(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
string symbol = Symbol();
int period = Period();
string symbol_str;
string period_str;

bool isSniper = false;
bool stopTrade = false;
string currentSniper = NULL;
// string currentBlackRSI = NULL;
// string currentRedRSI = NULL;
// string currentBlackStochRSI = NULL;
// string currentRedStochRSI = NULL;
string prevSniper = NULL;
// string prevBlackRSI = NULL;
// string prevRedRSI = NULL;
// string prevBlackStochRSI = NULL;
// string prevRedStochRSI = NULL;
int buyCount = 0;
int sellCount = 0;
int currencyBuyCount = 0;
int currencySellCount = 0;
int currencyTotalOrders = 0;

void OnTick() {
   localTime = TimeToStr(TimeLocal(), TIME_DATE | TIME_SECONDS);
   timeStamp = TimeToStr(TimeLocal(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
   symbol_str = RemoveTrailingSigns(symbol);
   period_str = PeriodToString(period);
   
   if (isNewTick()) {
      // Print("----!!!!----- NEW TICK ----!!!!-----");
      OrderCounter();
      CheckOpenOrders();
   }

   if (IsNewCandle()) {
      // Print("----++++----- NEW CANDLE ----++++-----");
      double sniper = iCustom(Symbol(), Period(), "\\Custom\\HKD Sniper", "", false, false, false, false, "alert.wav", "current", true, 7, 0);
      double black_rsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE RSI CROSSOVER BASIC", 14, 14, 0.618, 1, 0); //RSI 14
      double red_rsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE RSI CROSSOVER BASIC", 14, 14, 0.618, 0, 0); //finwaze 14  
      double black_stochrsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE STOCHRSI VER 3", 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
      double red_stochrsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE STOCHRSI VER 3", 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D

      string filenameSniper = StringConcatenate(Symbol(), Period(), "-prevSniper.txt");
      // string filenameBlackRSI = StringConcatenate(symbol, Period(), "-prevBlackRSI.txt");
      // string filenameRedRSI = StringConcatenate(symbol, Period(), "-prevRedRSI.txt");
      // string filenameBlackStochRSI = StringConcatenate(symbol, Period(), "-prevBlackStochRSI.txt");
      // string filenameRedStochRSI = StringConcatenate(symbol, Period(), "-prevRedStochRSI.txt");

      currentSniper = DoubleToString(sniper);
      // currentBlackRSI = DoubleToString(black_rsi);
      // currentRedRSI = DoubleToString(red_rsi);
      // currentBlackStochRSI = DoubleToString(black_stochrsi);
      // currentRedStochRSI = DoubleToString(red_stochrsi);
      prevSniper = NULL;
      // prevBlackRSI = NULL;
      // prevRedRSI = NULL;
      // prevBlackStochRSI = NULL;
      // prevRedStochRSI = NULL;
      
      if (FileIsExist(filenameSniper)) {
         int filenameSniper_r = FileOpen(filenameSniper, FILE_READ|FILE_TXT);
         prevSniper = FileReadString(filenameSniper_r);
         FileClose(filenameSniper_r);

         int filenameSniper_w = FileOpen(filenameSniper, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameSniper_w, currentSniper);
         FileClose(filenameSniper_w);
      } else {
         int filenameSniper_w = FileOpen(filenameSniper, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameSniper_w, currentSniper);
         FileClose(filenameSniper_w);
      }

      // if (FileIsExist(filenameBlackRSI)) {
      //    int filenameBlackRSI_r = FileOpen(filenameBlackRSI, FILE_READ|FILE_TXT);
      //    prevBlackRSI = FileReadString(filenameBlackRSI_r);
      //    FileClose(filenameBlackRSI_r);

      //    int filenameBlackRSI_w = FileOpen(filenameBlackRSI, FILE_WRITE|FILE_TXT);
      //    FileWriteString(filenameBlackRSI_w, currentBlackRSI);
      //    FileClose(filenameBlackRSI_w);
      // } else {
      //    int filenameBlackRSI_w = FileOpen(filenameBlackRSI, FILE_WRITE|FILE_TXT);
      //    FileWriteString(filenameBlackRSI_w, currentBlackRSI);
      //    FileClose(filenameBlackRSI_w);
      // }

      // if (FileIsExist(filenameRedRSI)) {
      //    int filenameRedRSI_r = FileOpen(filenameRedRSI, FILE_READ|FILE_TXT);
      //    prevRedRSI = FileReadString(filenameRedRSI_r);
      //    FileClose(filenameRedRSI_r);

      //    int filenameRedRSI_w = FileOpen(filenameRedRSI, FILE_WRITE|FILE_TXT);
      //    FileWriteString(filenameRedRSI_w, currentRedRSI);
      //    FileClose(filenameRedRSI_w);
      // } else {
      //    int filenameRedRSI_w = FileOpen(filenameRedRSI, FILE_WRITE|FILE_TXT);
      //    FileWriteString(filenameRedRSI_w, currentRedRSI);
      //    FileClose(filenameRedRSI_w);
      // }

      // if (FileIsExist(filenameBlackStochRSI)) {
      //    int filenameBlackStochRSI_r = FileOpen(filenameBlackStochRSI, FILE_READ|FILE_TXT);
      //    prevBlackStochRSI = FileReadString(filenameBlackStochRSI_r);
      //    FileClose(filenameBlackStochRSI_r);

      //    int filenameBlackStochRSI_w = FileOpen(filenameBlackStochRSI, FILE_WRITE|FILE_TXT);
      //    FileWriteString(filenameBlackStochRSI_w, currentBlackStochRSI);
      //    FileClose(filenameBlackStochRSI_w);
      // } else {
      //    int filenameBlackStochRSI_w = FileOpen(filenameBlackStochRSI, FILE_WRITE|FILE_TXT);
      //    FileWriteString(filenameBlackStochRSI_w, currentBlackStochRSI);
      //    FileClose(filenameBlackStochRSI_w);
      // }

      // if (FileIsExist(filenameRedStochRSI)) {
      //    int filenameRedStochRSI_r = FileOpen(filenameRedStochRSI, FILE_READ|FILE_TXT);
      //    prevRedStochRSI = FileReadString(filenameRedStochRSI_r);
      //    FileClose(filenameRedStochRSI_r);

      //    int filenameRedStochRSI_w = FileOpen(filenameRedStochRSI, FILE_WRITE|FILE_TXT);
      //    FileWriteString(filenameRedStochRSI_w, currentRedStochRSI);
      //    FileClose(filenameRedStochRSI_w);
      // } else {
      //    int filenameRedStochRSI_w = FileOpen(filenameRedStochRSI, FILE_WRITE|FILE_TXT);
      //    FileWriteString(filenameRedStochRSI_w, currentRedStochRSI);
      //    FileClose(filenameRedStochRSI_w);
      // }
   }
}

bool isNewTick() {
   static datetime lastTime = 0;
   datetime tickTime = TimeCurrent();
   int seconds = (int)(tickTime-lastTime);
   lastTime = tickTime;
   bool result = (seconds != 0);

   return(result);
}

bool IsNewCandle() {
   static datetime currentTime =	0;
	bool result	= (currentTime != Time[0]);

	if (result) currentTime	= Time[0];

	return(result);
}

// For Close Order Confirmation <Sniper Trailing Stop>
bool SniperCheck(string orderString) {
    double sniper = iCustom(Symbol(), Period(), "\\Custom\\HKD Sniper", "", false, false, false, false, "alert.wav", "current", true, 7, 0);
    double black_rsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE RSI CROSSOVER BASIC", 14, 14, 0.618, 1, 0); //RSI 14
    double red_rsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE RSI CROSSOVER BASIC", 14, 14, 0.618, 0, 0); //finwaze 14  
    double black_stochrsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE STOCHRSI VER 3", 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
    double red_stochrsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE STOCHRSI VER 3", 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D

    string filenameSniper = StringConcatenate(Symbol(), Period(), "-prevSniper.txt");

    isSniper = false;

    Print("orderString ---> ", orderString);
    Print("Sniper ---> ", sniper);

    if (FileIsExist(filenameSniper)) {
        if (orderString == "buy") {        
            if (StringToDouble(prevSniper) < sniper) {
                isSniper = false;
            } else {
                if (black_rsi < red_rsi && black_stochrsi < red_stochrsi) {
                    isSniper = true;
                }
            } 
        }

        if (orderString == "sell") {        
            if (StringToDouble(prevSniper) > sniper) {
                isSniper = false;
            } else {
                if (black_rsi > red_rsi && black_stochrsi > red_stochrsi) {
                    isSniper = true;
                }
            } 
        }
    }

    return isSniper;
}

void CheckOpenOrders() {
   RefreshRates();

   string takeProfit;
   string orderType;
   double currencyProfit;
   bool getProfit;

   double barClose = iClose(symbol_str, Period(), 0);
   double barOpen = iOpen(symbol_str, Period(), 0);
   double barHigh = iHigh(symbol_str, Period(), 0);
   double barLow = iLow(symbol_str, Period(), 0);

   string filename1 = StringConcatenate(symbol_str, Period(), "-takeProfit.txt");

   if (FileIsExist(filename1)) {
      int filehandle1_r = FileOpen(filename1, FILE_READ|FILE_TXT);
      takeProfit = FileReadString(filehandle1_r);
      FileClose(filehandle1_r);
   }

   // close per currency
   for (int i=0; i<OrdersTotal(); i++) { 
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
            currencyProfit = OrderProfit() + OrderSwap() + OrderCommission();

            if (OrderType() == OP_BUY) orderType = "buy";
            if (OrderType() == OP_SELL) orderType = "sell";

            getProfit = SniperCheck(orderType);

            Print(">>> CURRENCY PROFIT (BASIS) +-----> ", currencyProfit);

            // set trailing stop from profit
            if (currencyProfit > 0 && getProfit) {
               if (ForceTP) {
                  // force take profit
                  if ((currencyProfit >= VolumeSize * ForceTPFactor)) {
                     Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                     FileDelete(filename1);

                     if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        Print("Order Not Close with Error! ", GetLastError());
                     }

                     break;
                  }
               }

               if (!FileIsExist(filename1)) {
                  int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
                  FileWriteString(filehandle1_w, DoubleToStr(currencyProfit, 2));
                  FileClose(filehandle1_w);

                  break;
                  // break if takeprofit value is not in memory
               } else {
                  // get profit now
                  if (currencyProfit > StringToDouble(takeProfit)) {
                     Print("currencyProfit > StringToDouble(takeProfit) +++++MORE+++++");

                     int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle1_w, DoubleToStr(currencyProfit, 2));
                     FileClose(filehandle1_w);

                     if (OrderType() == OP_BUY) {
                        // if (bearsPowerCheckValue() >= 0) { // nearest trailing stop
                        if (barClose > barOpen) { // nearest trailing stop 
                           break;
                        } else {
                           Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                           FileDelete(filename1);

                           if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                              Print("Order Not Close with Error! ", GetLastError());
                           }

                           break;
                        }
                     }

                     if (OrderType() == OP_SELL) {
                        // if (bullsPowerCheckValue() <= 0) { // nearest trailing stop 
                        if (barClose < barOpen) { // nearest trailing stop 
                           break;
                        } else {
                           Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                           FileDelete(filename1);

                           if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                              Print("Order Not Close with Error! ", GetLastError());
                           }

                           break;
                        }
                     }
                  }

                  if (currencyProfit <= StringToDouble(takeProfit)) {
                     Print("currencyProfit <= StringToDouble(takeProfit) +++++LESS+++++");

                     int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle1_w, DoubleToStr(currencyProfit, 2));
                     FileClose(filehandle1_w);

                     // int filehandle1_r = FileOpen(filename1, FILE_READ|FILE_TXT);
                     // newTakeProfit = FileReadString(filehandle1_r);
                     // FileClose(filehandle1_r);

                     if (OrderType() == OP_BUY && barClose < barHigh) {
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename1);

                        if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                           Print("Order Not Close with Error! ", GetLastError());
                        }

                        break;
                     }
                     if (OrderType() == OP_SELL && barClose > barLow) {
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename1);

                        if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                           Print("Order Not Close with Error! ", GetLastError());
                        }

                        break;
                     }
                  }
               }
            } else {
               // if currencyProfit is less.. reset all
               FileDelete(filename1);
            }
         }
      }
   }
} 

void CloseOrders() {
   Print("xxx Closing All Open Orders xxx");

    for (int i=0; i<OrdersTotal(); i++ ) { 
        if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
            if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                Print("Order Not Close with Error! ", GetLastError());
            }  
        }
        }
    }

    string filename1 = StringConcatenate(symbol_str, Period(), "-takeProfit.txt");

    FileDelete(filename1);

   OrderCounter();
}

void OrderCounter() {
   int buyCounter = 0;
   int sellCounter = 0;
   int currencyBuyCounter = 0;
   int currencySellCounter = 0;

   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderType() == OP_BUY) buyCounter++;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) currencyBuyCounter++;
         if (OrderType() == OP_SELL) sellCounter++;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) currencySellCounter++;
      } 
   }

   buyCount = buyCounter;
   sellCount = sellCounter;
   currencyBuyCount = currencyBuyCounter;
   currencySellCount = currencySellCounter;
   currencyTotalOrders = currencyBuyCount + currencySellCount;
}

double ATRCheck() {
   double atr = iATR(Symbol(), Period(), 14, 1);

   return atr;
}

string TimeTo12HourFormat(string _time, bool _showsec) {
   datetime dtValue = StringToTime(_time);
   MqlDateTime timeStruct;
   TimeToStruct(dtValue, timeStruct);

   int hour = timeStruct.hour;
   int minute = timeStruct.min;
   int second = timeStruct.sec;
   string ampm = "am";

   if (hour >= 12) {
      ampm = "pm";
      if (hour > 12) hour -= 12;
      else if (hour == 0) hour = 12;
   }

   if (!_showsec) return StringFormat("%02d:%02d%s", hour, minute, ampm);
   else return StringFormat("%02d:%02d:%02d%s", hour, minute, second, ampm);
}

string RemoveTrailingSigns(string _symbol) {
    int len = StringLen(_symbol);

    if (len > 6) _symbol = StringSubstr(_symbol, 0, len - 1);

    return _symbol;
}

string PeriodToString(int _period) {
   switch(_period) {
      case PERIOD_M1:   return "M1";
      case PERIOD_M5:   return "M5";
      case PERIOD_M15:  return "M15";
      case PERIOD_M30:  return "M30";
      case PERIOD_H1:   return "H1";
      case PERIOD_H4:   return "H4";
      case PERIOD_D1:   return "D1";
      case PERIOD_W1:   return "W1";
      case PERIOD_MN1:  return "MN1";
      default:          return "??";
   }
}

string ToUpper(string text) { 
   StringToUpper(text);
   return text; 
}
