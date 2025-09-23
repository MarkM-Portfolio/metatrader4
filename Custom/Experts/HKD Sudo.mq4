#property copyright "HKD © 2024 All Rights Reserved."
#property link "https://hkdsolutionsfx.com/"
#property description "Author: MMM"
#property icon "hkd.ico"
#property strict
#define VERSION "1.0"

extern double VolumeSize = 0.10;
extern string OrderMode = "Select order modes";
extern bool MarketOrders = false;
extern bool StopOrders = true;
extern bool LimitOrders = false;
extern int SLPoints = 0;
extern int SLPointsNews = 0;
extern int SLPointsGold = 0;
extern int SLPointsNewsGold = 0;
extern bool ForceTP = false;
extern double ForceTPFactor = 1.3;
extern bool NewsCloseTrade = true;
extern bool NewsTradeOn = false;
extern bool StandardHrsTrade = false;
extern bool WindowHrsTrade = false;
extern bool NonStopTrade = true;
extern int OrderLimit = 4;
extern int Slippage = 0;
extern int MagicNumber = 1919;

string localTime = TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS);
string timeStamp = TimeToStr(TimeLocal(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
string symbol = Symbol();
int period = Period();
string symbol_str;
string period_str;

string channelTradeAction = NULL;
bool isSniper = false;
bool isRSI = false;
bool isStochRSI = false;
bool stopTrade = false;
bool orderDanger = false;
bool newsOrder = false;
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
string isNewsOn = NULL;
string filenameNewsOn;
int buyCount = 0;
int sellCount = 0;
int currencyBuyCount = 0;
int currencySellCount = 0;
int currencyTotalOrders = 0;
int buyLimitCounter = 0;
int sellLimitCounter = 0;
int orderLimitCounter = 0;

void OnTick() {
   localTime = TimeToStr(TimeLocal(), TIME_DATE | TIME_SECONDS);
   timeStamp = TimeToStr(TimeLocal(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
   symbol_str = RemoveTrailingSigns(symbol);
   period_str = PeriodToString(period);

   if (StandardHrsTrade) {
      if (TimeHour(TimeLocal()) >= 13) { // trading hours
         stopTrade = false;
      } else {
         stopTrade = true;
         if (TimeDayOfWeek(TimeLocal()) == 6) { // if after Friday close orders
            CloseOrders();
         }
      }
   }
   if (WindowHrsTrade) {
      if (TimeHour(TimeLocal()) >= 4 && TimeHour(TimeLocal()) <= 8) { // stop and close trade after 4AM until 9AM
         stopTrade = true;
         CloseOrders();
      } else { // start trade at 9AM
         stopTrade = false;
      }
   }

   if (NonStopTrade) {
      if (TimeDayOfWeek(TimeLocal()) == 6) { // if after Friday close orders
         CloseOrders();
      } else {
         stopTrade = false;
      }
   }
   
   if (isNewTick()) {
      // Print("----!!!!----- NEW TICK ----!!!!-----");
      OrderCounter();
      CheckNews();

      if (currencyTotalOrders != 0 && !stopTrade) {
         if (NewsCloseTrade) {
            // CheckNews();
            if (isNewsOn == "ONLINE" && orderDanger && !newsOrder) {
               // Force Close Order
               if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                  Print("Order Not Close with Error! ", GetLastError());
               }
               newsOrder = false;
            } else {
               isNewsOn = NULL;
               CheckOpenOrders();
            }
         } else {
            isNewsOn = NULL;
            CheckOpenOrders();
         }
      }

      // if (currencyTotalOrders == 0 && !stopTrade && orderLimitCounter <= OrderLimit) {
      if (currencyTotalOrders == 0 && !stopTrade) {
         if (NewsTradeOn) {
            if (isNewsOn == "ONLINE" && orderDanger) {
               newsOrder = true;
               PrepareOrder();
            } else {
               isNewsOn = NULL;
               newsOrder = false;
               PrepareOrder();
            }
            // if (NewsTradeOn && isNewsOn == "ONLINE" && !stopTrade) {
            //    FileDelete(filenameNewsOn);
            //    isNewsOn = NULL;
            // }
         } else {
            isNewsOn = NULL;
            newsOrder = false;
            PrepareOrder();
         }
      }
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

string ChannelTradeCheck() {
   double sniperResistance = iCustom(Symbol(), Period(), "\\Custom\\HKD Sniper", "", false, false, false, false, "alert.wav", "current", true, 1, 0);
   double sniperSupport = iCustom(Symbol(), Period(), "\\Custom\\HKD Sniper", "", false, false, false, false, "alert.wav", "current", true, 2, 0);
   double sniper = iCustom(Symbol(), Period(), "\\Custom\\HKD Sniper", "", false, false, false, false, "alert.wav", "current", true, 7, 0);

   double kijunRSI = iCustom(Symbol(), Period(), "\\Custom\\HKD RSI", Period(), 14, 25, 15.0, 14, false, false, false, false, false, false, "alert2.wav", 1, 0);

   string orderSignal;
   bool confirmOrder = false;
   channelTradeAction = NULL;

   if (sniper < sniperSupport && kijunRSI < -25) {
        orderSignal = "buy"; // Normal
        confirmOrder = SniperCheck(orderSignal);
    }

    if (sniper > sniperResistance && kijunRSI > 25) {
        orderSignal = "sell"; // Normal
        confirmOrder = SniperCheck(orderSignal);
    }

    if (!newsOrder && confirmOrder) {
        channelTradeAction = orderSignal;
    }

    return channelTradeAction;
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

                     newsOrder = false;

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

                           newsOrder = false;

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

                           newsOrder = false;

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

                        newsOrder = false;

                        break;
                     }
                     if (OrderType() == OP_SELL && barClose > barLow) {
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename1);

                        if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                           Print("Order Not Close with Error! ", GetLastError());
                        }

                        newsOrder = false;

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

void PrepareOrder() {
   /* TEST OFFLINE */
   // channelTradeAction = "buy";

   channelTradeAction = ChannelTradeCheck();
   
   Print("channelTradeAction: ", channelTradeAction);

   if (channelTradeAction != NULL && currencyTotalOrders == 0 && !stopTrade) {
      int orderType;
      double openPrice = (channelTradeAction == "buy" ? MarketInfo(Symbol(), MODE_ASK) : MarketInfo(Symbol(), MODE_BID));
      color orderColor = (channelTradeAction == "buy" ? clrBlue : clrRed);
      double sL = 0; double tP = 0; // initialize SL & TP to zero (0)
      string comment = TimeTo12HourFormat(timeStamp, false) + " " + symbol_str + "(" + period_str + ") HKD Sudo " + VERSION;
      string printOut;

      if (MarketOrders) {
         printOut = "Market Order: " + ToUpper(channelTradeAction) + " ...";
         orderType = (channelTradeAction == "buy" ? OP_BUY : OP_SELL);
         NewOrder(printOut, orderType, openPrice, orderColor, sL, tP, comment);
      }

      if (StopOrders) {
         printOut = "Pending Order: " + ToUpper(channelTradeAction) + "Stop ...";
         orderType = (channelTradeAction == "buy" ? OP_BUYSTOP : OP_SELLSTOP);
         NewOrder(printOut, orderType, openPrice, orderColor, sL, tP, comment);

      }

      if (LimitOrders) {
         printOut = "Pending Order: " + ToUpper(channelTradeAction) + "Limit ...";
         orderType = (channelTradeAction == "buy" ? OP_BUYLIMIT : OP_SELLLIMIT);
         NewOrder(printOut, orderType, openPrice, orderColor, sL, tP, comment);
      }
   }
}

void NewOrder(string printOut, int orderType, double openPrice, color orderColor, double sL, double tP, string comment) {
   if (!newsOrder) {
      if (SLPoints != 0) { // only catch non-zero inputs
         sL = (channelTradeAction == "buy" ? openPrice - (Point() * SLPoints) : openPrice + (Point() * SLPoints));
      }

      if (SLPointsGold != 0) { // only catch non-zero inputs
         if (symbol_str == "XAUUSD") { // SL for GOLD
            sL = (channelTradeAction == "buy" ? openPrice - (Point() * SLPointsGold) : openPrice + (Point() * SLPointsGold));
         }
      }
   } else {
      // temporary for news
      openPrice = (channelTradeAction == "buy" ? MarketInfo(Symbol(), MODE_ASK) : MarketInfo(Symbol(), MODE_BID));
      comment = "NEWS >> " + TimeTo12HourFormat(timeStamp, false) + ") HKD Sudo " + VERSION;

      if (SLPointsNews != 0) { // only catch non-zero inputs
         sL = (channelTradeAction == "buy" ? openPrice - (Point() * SLPointsNews) : openPrice + (Point() * SLPointsNews));
      }

      if (SLPointsNewsGold != 0) { // only catch non-zero inputs
         if (symbol_str == "XAUUSD") { // SL for GOLD
            sL = (channelTradeAction == "buy" ? openPrice - (Point() * SLPointsNewsGold) : openPrice + (Point() * SLPointsNewsGold));
         }
      }
   }

   int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slippage, sL, tP, comment, MagicNumber, 0, orderColor);

   Print(printOut);
   Print("Price +-----> ", openPrice);
   Print("SL +-----> ", sL);
   Print("TP +-----> ", tP);

   // No order limit for H1
   if (Period() != 60 && orderLimitCounter <= OrderLimit) {
      if (channelTradeAction == "buy") buyLimitCounter++;
      if (channelTradeAction == "sell") sellLimitCounter++;
      orderLimitCounter++;
   }
}

void CloseOrders() {
   Print("xxx Closing All Open Orders xxx");

   if (NonStopTrade) { // close only positive profit 
      stopTrade = true;
      for (int i=0; i<OrdersTotal(); i++ ) { 
         if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
               if (OrderProfit() + OrderSwap() + OrderCommission() > 0) {
                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }  
               }
            }
         }
      }
      string filename1 = StringConcatenate(symbol_str, Period(), "-takeProfit.txt");

      FileDelete(filename1);
   } else {
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
   }

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

bool CheckNews() {
   string base =  StringFormat("%.3s", symbol_str);
   string quote = StringSubstr(symbol_str, 3, StringLen(symbol_str)-2);

   // string localHour = IntegerToString(TimeHour(TimeLocal()));
   // string localMins = IntegerToString(TimeMinute(TimeLocal()));
   // string localNewsTime = StringConcatenate(localHour, ":", localMins);

   datetime currentLocalTime = TimeLocal();

   // check if past 30 minutes to resume trade (Continue this)
   // if (!NewsTradeOn && FileExist(filenameNewsOn) && isNewsOn == "ONLINE" && orderDanger) {
   //    stopTrade = true;
   // }

   datetime newTime = currentLocalTime - (15 * 60); // Subtract 15 minutes (15 * 60 seconds)
   int newHour = TimeHour(newTime);
   int newMinute = TimeMinute(newTime);
   string newHourString = IntegerToString(newHour);
   string newMinuteString = IntegerToString(newMinute);

   // Ensure minutes are formatted as two digits
   if (newMinute < 10)
      newMinuteString = "0" + newMinuteString;

   string localNewsTime = StringConcatenate(newHourString, ":", newMinuteString);
   filenameNewsOn = StringConcatenate(symbol_str, Period(), "-newsOn.txt");

   orderDanger = false;

   string fileBASE1 = StringConcatenate(base, "1", "-news.txt");
   string fileBASE2 = StringConcatenate(base, "2", "-news.txt");
   string fileBASE3 = StringConcatenate(base, "3", "-news.txt");
   string fileBASE4 = StringConcatenate(base, "4", "-news.txt");
   string fileBASE5 = StringConcatenate(base, "5", "-news.txt");
   string fileBASE6 = StringConcatenate(base, "6", "-news.txt");
   string fileBASE7 = StringConcatenate(base, "7", "-news.txt");
   string fileBASE8 = StringConcatenate(base, "8", "-news.txt");
   string fileBASE9 = StringConcatenate(base, "9", "-news.txt");
   string fileBASE10 = StringConcatenate(base, "10", "-news.txt");

   string fileQUOTE1 = StringConcatenate(quote, "1", "-news.txt");
   string fileQUOTE2 = StringConcatenate(quote, "2", "-news.txt");
   string fileQUOTE3 = StringConcatenate(quote, "3", "-news.txt");
   string fileQUOTE4 = StringConcatenate(quote, "4", "-news.txt");
   string fileQUOTE5 = StringConcatenate(quote, "5", "-news.txt");
   string fileQUOTE6 = StringConcatenate(quote, "6", "-news.txt");
   string fileQUOTE7 = StringConcatenate(quote, "7", "-news.txt");
   string fileQUOTE8 = StringConcatenate(quote, "8", "-news.txt");
   string fileQUOTE9 = StringConcatenate(quote, "9", "-news.txt");
   string fileQUOTE10 = StringConcatenate(quote, "10", "-news.txt");

   string filename1 = StringConcatenate(symbol_str, Period(), "-takeProfit.txt");

   // Stop News
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
            if (FileIsExist(fileBASE1) || FileIsExist(fileBASE2) || FileIsExist(fileBASE3) || FileIsExist(fileBASE4) || FileIsExist(fileBASE5) || FileIsExist(fileBASE6) || FileIsExist(fileBASE7) || FileIsExist(fileBASE8) || FileIsExist(fileBASE9) || FileIsExist(fileBASE10)) {
               int fileBASE1_r = FileOpen(fileBASE1, FILE_READ|FILE_TXT);
               int fileBASE2_r = FileOpen(fileBASE2, FILE_READ|FILE_TXT);
               int fileBASE3_r = FileOpen(fileBASE3, FILE_READ|FILE_TXT);
               int fileBASE4_r = FileOpen(fileBASE4, FILE_READ|FILE_TXT);
               int fileBASE5_r = FileOpen(fileBASE5, FILE_READ|FILE_TXT);
               int fileBASE6_r = FileOpen(fileBASE6, FILE_READ|FILE_TXT);
               int fileBASE7_r = FileOpen(fileBASE7, FILE_READ|FILE_TXT);
               int fileBASE8_r = FileOpen(fileBASE8, FILE_READ|FILE_TXT);
               int fileBASE9_r = FileOpen(fileBASE9, FILE_READ|FILE_TXT);
               int fileBASE10_r = FileOpen(fileBASE10, FILE_READ|FILE_TXT);

               string base1 = FileReadString(fileBASE1_r);
               string base2 = FileReadString(fileBASE2_r);
               string base3 = FileReadString(fileBASE3_r);
               string base4 = FileReadString(fileBASE4_r);
               string base5 = FileReadString(fileBASE5_r);
               string base6 = FileReadString(fileBASE6_r);
               string base7 = FileReadString(fileBASE7_r);
               string base8 = FileReadString(fileBASE8_r);
               string base9 = FileReadString(fileBASE9_r);
               string base10 = FileReadString(fileBASE10_r);

               FileClose(fileBASE1_r);
               FileClose(fileBASE2_r);
               FileClose(fileBASE3_r);
               FileClose(fileBASE4_r);
               FileClose(fileBASE5_r);
               FileClose(fileBASE6_r);
               FileClose(fileBASE7_r);
               FileClose(fileBASE8_r);
               FileClose(fileBASE9_r);
               FileClose(fileBASE10_r);

               if (localNewsTime == base1 || localNewsTime == base2 || localNewsTime == base3 || localNewsTime == base4 || localNewsTime == base5 || localNewsTime == base6 || localNewsTime == base7 || localNewsTime == base8 || localNewsTime == base9 || localNewsTime == base10) {
                  // if (!FileIsExist(filenameNewsOn) && isNewsOn != "ONLINE") {
                  //    if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                  //       Print("Order Not Close with Error! ", GetLastError());
                  //    }
                  // }

                  if (FileIsExist(filenameNewsOn)) {
                     int filenameNewsOn_r = FileOpen(filenameNewsOn, FILE_READ|FILE_TXT);
                     isNewsOn = FileReadString(filenameNewsOn_r);
                     FileClose(filenameNewsOn_r);

                     int filenameNewsOn_w = FileOpen(filenameNewsOn, FILE_WRITE|FILE_TXT);
                     FileWriteString(filenameNewsOn_w, "ONLINE");
                     FileClose(filenameNewsOn_w);
                  } else {
                     int filenameNewsOn_w = FileOpen(filenameNewsOn, FILE_WRITE|FILE_TXT);
                     FileWriteString(filenameNewsOn_w, "ONLINE");
                     FileClose(filenameNewsOn_w);
                  }

                  // stopTrade = true;
                  orderDanger = true;

                  break;
               }
            }

            if (FileIsExist(fileQUOTE1) || FileIsExist(fileQUOTE2) || FileIsExist(fileQUOTE3) || FileIsExist(fileQUOTE4) || FileIsExist(fileQUOTE5) || FileIsExist(fileQUOTE6) || FileIsExist(fileQUOTE7) || FileIsExist(fileQUOTE8) || FileIsExist(fileQUOTE9) || FileIsExist(fileQUOTE10)) {
               int fileQUOTE1_r = FileOpen(fileQUOTE1, FILE_READ|FILE_TXT);
               int fileQUOTE2_r = FileOpen(fileQUOTE2, FILE_READ|FILE_TXT);
               int fileQUOTE3_r = FileOpen(fileQUOTE3, FILE_READ|FILE_TXT);
               int fileQUOTE4_r = FileOpen(fileQUOTE4, FILE_READ|FILE_TXT);
               int fileQUOTE5_r = FileOpen(fileQUOTE5, FILE_READ|FILE_TXT);
               int fileQUOTE6_r = FileOpen(fileQUOTE6, FILE_READ|FILE_TXT);
               int fileQUOTE7_r = FileOpen(fileQUOTE7, FILE_READ|FILE_TXT);
               int fileQUOTE8_r = FileOpen(fileQUOTE8, FILE_READ|FILE_TXT);
               int fileQUOTE9_r = FileOpen(fileQUOTE9, FILE_READ|FILE_TXT);
               int fileQUOTE10_r = FileOpen(fileQUOTE10, FILE_READ|FILE_TXT);

               string quote1 = FileReadString(fileQUOTE1_r);
               string quote2 = FileReadString(fileQUOTE2_r);
               string quote3 = FileReadString(fileQUOTE3_r);
               string quote4 = FileReadString(fileQUOTE4_r);
               string quote5 = FileReadString(fileQUOTE5_r);
               string quote6 = FileReadString(fileQUOTE6_r);
               string quote7 = FileReadString(fileQUOTE7_r);
               string quote8 = FileReadString(fileQUOTE8_r);
               string quote9 = FileReadString(fileQUOTE9_r);
               string quote10 = FileReadString(fileQUOTE10_r);

               FileClose(fileQUOTE1_r);
               FileClose(fileQUOTE2_r);
               FileClose(fileQUOTE3_r);
               FileClose(fileQUOTE4_r);
               FileClose(fileQUOTE5_r);
               FileClose(fileQUOTE6_r);
               FileClose(fileQUOTE7_r);
               FileClose(fileQUOTE8_r);
               FileClose(fileQUOTE9_r);
               FileClose(fileQUOTE10_r);

               if (localNewsTime == quote1 || localNewsTime == quote2 || localNewsTime == quote3 || localNewsTime == quote4 || localNewsTime == quote5 || localNewsTime == quote6 || localNewsTime == quote7 || localNewsTime == quote8 || localNewsTime == quote9 || localNewsTime == quote10) {
                  // if (!FileIsExist(filenameNewsOn) && isNewsOn != "ONLINE") {
                  //    if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                  //       Print("Order Not Close with Error! ", GetLastError());
                  //    }
                  // }

                  if (FileIsExist(filenameNewsOn)) {
                     int filenameNewsOn_r = FileOpen(filenameNewsOn, FILE_READ|FILE_TXT);
                     isNewsOn = FileReadString(filenameNewsOn_r);
                     FileClose(filenameNewsOn_r);

                     int filenameNewsOn_w = FileOpen(filenameNewsOn, FILE_WRITE|FILE_TXT);
                     FileWriteString(filenameNewsOn_w, "ONLINE");
                     FileClose(filenameNewsOn_w);
                  } else {
                     int filenameNewsOn_w = FileOpen(filenameNewsOn, FILE_WRITE|FILE_TXT);
                     FileWriteString(filenameNewsOn_w, "ONLINE");
                     FileClose(filenameNewsOn_w);
                  }

                  // stopTrade = true;
                  orderDanger = true;

                  break;
               }
            }
         }
      }
   }

   if (!orderDanger) {
      FileDelete(filenameNewsOn);
      isNewsOn = NULL;
      newsOrder = false;
      stopTrade = false;
   }

   return orderDanger;
}

// void TradeNews() {
//    Print("+++ Trading News Now +++");
   
//    double buyTP = 0; double sellTP = 0;
//    double buySL = MarketInfo(Symbol(), MODE_ASK) - (Point() * 50);
//    double sellSL = MarketInfo(Symbol(), MODE_BID) + (Point() * 50);
   
//    if (currencyTotalOrders == 0) {
//       Print("Fully Hedged!!! ");

//       int ticketBuy = OrderSend(Symbol(), OP_BUY, VolumeSize, MarketInfo(Symbol(), MODE_ASK), Slippage, buySL, buyTP, symbol_str + period + " EH-NEWS_v9.6 " + timeStamp, MagicNumber, 0, clrBlue);

//       Print("**** NEWS BUYING NOW!!! ");
//       Print("Price +-----> ", MarketInfo(Symbol(), MODE_ASK));
//       Print("SL +-----> ", buySL);
//       Print("TP +-----> ", buyTP);

//       int ticketSell = OrderSend(Symbol(), OP_SELL, VolumeSize, MarketInfo(Symbol(), MODE_BID), Slippage, sellSL, sellTP, symbol_str + period + " EH-NEWS_v9.6 " + timeStamp, MagicNumber, 0, clrRed);

//       Print("**** NEWS SELLING NOW!!! ");
//       Print("Price +-----> ", MarketInfo(Symbol(), MODE_BID));
//       Print("SL +-----> ", sellSL);
//       Print("TP +-----> ", sellTP);
//    } else {

//       if (currencyBuyCount == 0 && currencySellCount != 0) {
//          int ticketBuy = OrderSend(Symbol(), OP_BUY, VolumeSize, MarketInfo(Symbol(), MODE_ASK), Slippage, buySL, buyTP, symbol_str + period + " EH-NEWS_v9.6 " + timeStamp, MagicNumber, 0, clrBlue);

//          Print("**** NEWS BUYING NOW!!! ");
//          Print("Price +-----> ", MarketInfo(Symbol(), MODE_ASK));
//          Print("SL +-----> ", buySL);
//          Print("TP +-----> ", buyTP);
//       }

//       if (currencySellCount == 0 && currencyBuyCount != 0) {
//          int ticketSell = OrderSend(Symbol(), OP_SELL, VolumeSize, MarketInfo(Symbol(), MODE_BID), Slippage, sellSL, sellTP, symbol_str + period + " EH-NEWS_v9.6 " + timeStamp, MagicNumber, 0, clrRed);

//          Print("**** NEWS SELLING NOW!!! ");
//          Print("Price +-----> ", MarketInfo(Symbol(), MODE_BID));
//          Print("SL +-----> ", sellSL);
//          Print("TP +-----> ", sellTP);
//       }
//    }

//    setNews = true;
// }

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
