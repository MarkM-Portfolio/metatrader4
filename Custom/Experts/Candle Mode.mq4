#property version "4.02"
#property strict

input double VolumeSize = 0.01;
input bool ReOrderReversal = true;
input bool CloseSetEnable = false;
input int ATRPeriod = 14;
input int MagicNumber = 1212;

string localTime = TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS);
string timeStamp = TimeToStr(TimeLocal(), TIME_SECONDS);

string channelTradeAction;
string reOpenTradeAction = NULL;
string prevChannelTradeAction = NULL;
string techAnalysisAction = NULL;
string initValue = NULL;
string triggerValue = NULL;
bool stopCheckPoint = false;
bool isStartTrade = false;
bool reOpenOrder = false;
bool isRSI = false;
bool isStochRSI = false;
bool isTechAnalysis = false;
bool isRSIOver = false;
bool isStochOver = false;
bool isOverTrade = false;
bool isTrendReversed = false;
bool isReversalOrder = false;
int buyCount = 0;
int sellCount = 0;
int currencyBuyCount = 0;
int currencySellCount = 0;
int currencyTotalOrders = 0;
int barOpenCounter = 0;
double closeSet = 0;
// for Pro Spread currency names with "+"
string symbol = Symbol();
int replace = StringReplace(symbol, "+", "");
string period = IntegerToString(Period());
string closeSetMode = DoubleToString(closeSet);

void OnTick() {

   localTime = TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS);
   timeStamp = TimeToStr(TimeLocal(), TIME_SECONDS);
   
   if (isNewTick()) {
      // Print("----!!!!----- NEW TICK ----!!!!-----");
      OrderCounter();

      if (currencyTotalOrders != 0) {
         CheckOpenOrders();  
      }
   }

   if (IsNewCandle()) {
      Print("----++++----- NEW CANDLE ----++++-----");

      Print("BUY Orders Total +-----> ", buyCount);
      Print("SELL Orders Total +-----> ", sellCount);

      if (!stopCheckPoint && currencyTotalOrders == 0) {
         CheckPoint();
      }

      if (stopCheckPoint && !isStartTrade && currencyTotalOrders == 0) {
         isStartTrade = CheckStartTrade();
      }

      if (isStartTrade && currencyTotalOrders == 0) {
         channelTradeAction = IchimokuCheck();
         isRSI = RSICheck();
         isStochRSI = StochRSICheck();

         if (!isRSI || !isStochRSI) {
            Print("RSI Indicators are WRONG +-----> ", isRSI, " | ", isStochRSI);
         }

         if (isRSI && isStochRSI) {
            Print("RSI Indicators are CORRECT +-----> ", isRSI, " | ", isStochRSI);
            isTechAnalysis = TechnicalAnalysisCheck();
            Print("Proceeding to Technical Analysis Check +-----> ", isTechAnalysis);
            if (isRSIOver && isStochOver) {  // check overbought & oversold
               isOverTrade = true;
               Print("Overbought/Oversold...");
            } else {
               isOverTrade = false;
            }
         }
      }

      NewOrder();

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

string CheckPoint() {
   Print("CheckPoint()");
   double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
   double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue

   if (Tenkan > Kijun) {
      initValue = "buy";
   } else if (Tenkan < Kijun) {
      initValue = "sell";
   } else {
      initValue = "equal";
   }

   stopCheckPoint = true;
   Print("initValue 1 --> ", initValue);
   return initValue;
}

bool CheckStartTrade() {
   Print("CheckStartTrade()");
   double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
   double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue
   reOpenOrder = false;
   double barOpen = iOpen(symbol, Period(), 0);
   double barClose = iClose(symbol, Period(), 0);
   isTrendReversed = false;

   if (Tenkan > Kijun) {
      triggerValue = "buy";
   } else if (Tenkan < Kijun) {
      triggerValue = "sell";
   } else {
      triggerValue = "equal";
   }

   if (triggerValue == "equal" && initValue == "equal") {
      isStartTrade = false;
   } else if (triggerValue != initValue) {
      isStartTrade = true;
   } else if (triggerValue == initValue) {
      // BUY - Close is Below Tenkan = CLOSED (Open is Above Tenkan confirm twice)
      if (triggerValue == "buy") {
         if (Tenkan < barOpen) {
            isStartTrade = true;
            reOpenOrder = true;
         }
      }
      // SELL - Close is Above Tenkan = CLOSED (Open is Below Tenkan confirm twice)
      if (triggerValue == "sell") {
         if (Tenkan > barOpen) {
            isStartTrade = true;
            reOpenOrder = true;
         }
      }
   } else {
      isStartTrade = false;
   }

   Print("initValue 2 --> ", initValue);
   Print("triggerValue --> ", triggerValue);
   Print("channelTradeAction --> ", channelTradeAction);
   Print("prevChannelTradeAction --> ", prevChannelTradeAction);
   Print("isStartTrade --> ", isStartTrade);

   bool barPower = (channelTradeAction == "buy") ? bullsPowerCheck() > bearsPowerCheck() : bearsPowerCheck() > bullsPowerCheck();

   // BUY - Close is Below Tenkan = CLOSED
   if (channelTradeAction == "buy" && currencyTotalOrders != 0) {
      if (Tenkan > barClose) {
         Print("Close Bar HIT!!");
         isTrendReversed = TrendReversedCheck();
         if (isTrendReversed) {
            Print("Trend Changed Now Closing!!");
            CloseOrders(); 
            stopCheckPoint = false;
            isStartTrade = false;
         }
      }
   }
   // SELL - Close is Above Tenkan = CLOSED
   if (channelTradeAction == "sell" && currencyTotalOrders != 0) {
      if (Tenkan < barClose) {
         Print("Close Bar HIT!!");
         isTrendReversed = TrendReversedCheck();
         if (isTrendReversed) {
            Print("Trend Changed Now Closing!!");
            CloseOrders(); 
            stopCheckPoint = false;
            isStartTrade = false;
         }
      }
   }

   if (channelTradeAction != initValue && currencyTotalOrders != 0) {
      // close if crossed
      Print("CLOSE IF CROSSED!!");
      CloseOrders();
      stopCheckPoint = false;
      isStartTrade = false;
   }

   return isStartTrade;
}

string IchimokuCheck() {
   Print("IchimokuCheck()");
   string filename = StringConcatenate(symbol, Period(), "-orderType.txt");
   double barOpen = iOpen(symbol, Period(), 0);
   double barClose = iClose(symbol, Period(), 0);
   isTrendReversed = false;

   if (FileIsExist(filename)) {
      int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
      prevChannelTradeAction = FileReadString(filehandle_r);
      FileClose(filehandle_r);
   }

   double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
   double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue

   // Comment("Tenkan (red): ", Tenkan, " Kijun (blue): ", Kijun);

   Print("BEFORE initValue +-----> ", initValue);
   Print("BEFORE isStartTrade +-----> ", isStartTrade);
   Print("BEFORE currencyTotalOrders +-----> ", currencyTotalOrders);
   Print("BEFORE channelTradeAction +-----> ", channelTradeAction);
   Print("BEFORE prevChannelTradeAction +-----> ", prevChannelTradeAction);

   bool barPower = (channelTradeAction == "buy") ? bullsPowerCheck() > bearsPowerCheck() : bearsPowerCheck() > bullsPowerCheck();

   if (reOpenOrder && currencyTotalOrders == 0) {
      if (Tenkan > Kijun) {
         reOpenTradeAction = "buy";
      } else if (Tenkan < Kijun) {
         reOpenTradeAction = "sell";
      } else {
         // if equal after init
         Print("IF EQUAL AFTER INIT ...");
         reOpenTradeAction = NULL;
         channelTradeAction = NULL;
         stopCheckPoint = false;
         isStartTrade = false;
         barOpenCounter = 0;
         reOpenOrder = false;
      }
   }

   if (reOpenOrder && reOpenTradeAction != NULL && currencyTotalOrders == 0) {
      // BUY - Close is Below Tenkan = CLOSED (Open is Above Tenkan confirm twice)
      if (reOpenTradeAction == "buy") {
         if (Tenkan < barOpen) {
            barOpenCounter++;
            if (barOpenCounter == 3 && barPower) {
               Print("Re-opening Order!!!");
               channelTradeAction = "buy";
               barOpenCounter = 0;
               reOpenOrder = false;
            }
         }
      }
      // SELL - Close is Above Tenkan = CLOSED (Open is Below Tenkan confirm twice)
      if (reOpenTradeAction == "sell") {
         if (Tenkan > barOpen) {
            barOpenCounter++;
            if (barOpenCounter == 3  && barPower) {
               Print("Re-opening Order!!!");
               channelTradeAction = "sell";
               barOpenCounter = 0;
               reOpenOrder = false;
            }
         }
      }
   }

   if (!reOpenOrder && currencyTotalOrders == 0) {
      Print("IF currencyTotalOrders EQUAL 0 --->", currencyTotalOrders);
      if (Tenkan > Kijun) {
         channelTradeAction = "buy";
      } else if (Tenkan < Kijun) {
         channelTradeAction = "sell";
      } else {
         // if equal after init
         Print("IF EQUAL AFTER INIT ...");
         channelTradeAction = NULL;
         stopCheckPoint = false;
         isStartTrade = false;
      }
   } else {
      Print("ELSE currencyTotalOrders NOT EQUAL OR GREATER 0 --->", currencyTotalOrders);
      if (Tenkan > Kijun) {
         channelTradeAction = "buy";
      } else if (Tenkan < Kijun) {
         channelTradeAction = "sell";
      } else {
         // if equal after init
         Print("IF EQUAL AFTER INIT ...");
         channelTradeAction = NULL;
         stopCheckPoint = false;
         isStartTrade = false;

         CloseOrders();
      }
   }

   Print("START currencyTotalOrders +-----> ", currencyTotalOrders);
   Print("START initValue +-----> ", initValue);
   Print("START isStartTrade +-----> ", isStartTrade);
   Print("START channelTradeAction +-----> ", channelTradeAction);
   Print("START prevChannelTradeAction +-----> ", prevChannelTradeAction);
   Print("START techAnalysisAction +-----> ", techAnalysisAction);

   if (channelTradeAction != NULL) {
      int filehandle_w = FileOpen(filename, FILE_WRITE|FILE_TXT);
      FileWriteString(filehandle_w, channelTradeAction);
      FileClose(filehandle_w);

      int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
      prevChannelTradeAction = FileReadString(filehandle_r);
      FileClose(filehandle_r);

      // BUY - Close is Below Tenkan = CLOSED
      if (channelTradeAction == "buy" && currencyTotalOrders != 0) {
         if (Tenkan > barClose) {
            Print("Close Bar HIT!!");
            isTrendReversed = TrendReversedCheck();
            if (isTrendReversed) {
               Print("Trend Changed Now Closing!!");
               CloseOrders(); 
            }
         }
      }
      // SELL - Close is Above Tenkan = CLOSED
      if (channelTradeAction == "sell" && currencyTotalOrders != 0) {
         if (Tenkan < barClose) {
            Print("Close Bar HIT!!");
            isTrendReversed = TrendReversedCheck();
            if (isTrendReversed) {
               Print("Trend Changed Now Closing!!");
               CloseOrders(); 
            }
         }
      }

      if (channelTradeAction != initValue && currencyTotalOrders != 0) {
         // close if crossed
         Print("CLOSE IF CROSSED!!");
         CloseOrders();
      }
   } else {
      Print("NO VALUE for channelTradeAction.. TEST ");
   }

   Print("FINAL initValue +-----> ", initValue);
   Print("FINAL isStartTrade +-----> ", isStartTrade);
   Print("FINAL currencyTotalOrders +-----> ", currencyTotalOrders);
   Print("FINAL channelTradeAction +-----> ", channelTradeAction);
   Print("FINAL prevChannelTradeAction +-----> ", prevChannelTradeAction);

   return channelTradeAction;
}

double ATRCheck() {
   double atr = iATR(Symbol(), Period(), ATRPeriod, 1);

   return atr;
}

double bullsPowerCheckValue() {
   double bullsPower = iBullsPower(NULL, 0, 13, PRICE_CLOSE, 0);

   return bullsPower;
}

double bearsPowerCheckValue() {
   double bearsPower = iBearsPower(NULL, 0, 13, PRICE_CLOSE, 0);

   return bearsPower;
}

double bullsPowerCheck() {
   double bullsPower = iBullsPower(NULL, 0, 13, PRICE_CLOSE, 0);

   if (bullsPower < 0) bullsPower *= -1;

   return bullsPower;
}

double bearsPowerCheck() {
   double bearsPower = iBearsPower(NULL, 0, 13, PRICE_CLOSE, 0);

   if (bearsPower < 0) bearsPower *= -1;

   return bearsPower;
}

bool RSICheck() {
   string indicatorName = "\\Custom\\FINWAZE RSI CROSSOVER BASIC";
   double red = iCustom(Symbol(), Period(), indicatorName, 14, 14, 0.618, 0, 0); //finwaze 14  
   double black = iCustom(Symbol(), Period(), indicatorName, 14, 14, 0.618, 1, 0); //RSI 14
   isRSI = false;
   isRSIOver = false;

   Print("RSI Red (finwaze14) ---> ", red);
   Print("RSI Black (RSI14) ---> ", black);

   if (channelTradeAction == "buy" && black > red) {
   // if black is greater thank red = BUY
      if (black >= 70 && red >= 65) {  // Overbought
         Print("RSI OVERBOUGHT !!");
         isRSIOver = true;
      } else {
         isRSIOver = false;
      }
      isRSI = true;
      // Print("BUY RSI Check --> ", isRSI);
   }

   if (channelTradeAction == "sell" && black < red) {
   // if black is less thank red = SELL
      if (black <= 30 && red <= 35) {   // Oversold
         Print("RSI OVERSOLD !!");
         isRSIOver = true;
      } else {
         isRSIOver = false;
      }
      isRSI = true;
      // Print("SELL RSI Check --> ", isRSI);
   }

   return isRSI;
}

bool StochRSICheck() {
   string indicatorName = "\\Custom\\FINWAZE STOCHRSI VER 3";
   double black = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
   double red = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D
   isStochRSI = false;
   isStochOver = false;

   Print("Stoch RSI Red (D) ---> ", red);
   Print("Stoch RSI Black (K) ---> ", black);

   if (channelTradeAction == "buy" && black > red) {
      // if black is greater thank red = BUY
      if (black >= 80 && red >= 75) {  // Overbought
         Print("StochRSI OVERBOUGHT !! Won't Trade.");
         isStochOver = true;
      } else {
         isStochOver = false;
      }
      isStochRSI = true;
      // Print("BUY Stoch RSI Check --> ", isStochRSI);
   }

   if (channelTradeAction == "sell" && black < red) {
      // if black is less thank red = SELL
      if (black <= 20 && red <= 25) {   // Oversold
         Print("StochRSI OVERSOLD !! Won't Trade.");
         isStochOver = true;
      } else {
         isStochOver = false;
      }
      isStochRSI = true;
      // Print("SELL Stoch RSI Check --> ", isStochRSI);
   }

   return isStochRSI;
}

bool TrendReversedCheck() {
   string indicatorName = "\\Custom\\FINWAZE STOCHRSI VER 3";
   double black = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
   double red = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D
   isTrendReversed = false;

   if (channelTradeAction == "buy" && black < red) {
      // if black is less thank red during BUY order
      isTrendReversed = true;
   }

   if (channelTradeAction == "sell" && black > red) {
      // if black is greater thank red during SELL order
      isTrendReversed = true;
   }

   return isTrendReversed;
}

bool TechnicalAnalysisCheck() {
   techAnalysisAction = NULL;
   string filename = StringConcatenate(symbol, Period(), "-technical.txt");

   int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
   techAnalysisAction = FileReadString(filehandle_r);
   FileClose(filehandle_r);
   
   isTechAnalysis = false;

   if (channelTradeAction == techAnalysisAction) {
      isTechAnalysis = true;
   } else {
      isTechAnalysis = false;
   }

   return isTechAnalysis;
}

void CheckOpenOrders() {
   RefreshRates();

   double totalProfit = NULL;
   double currencyProfit = NULL;
   int factor = 0;
   int Slippage = 0;
   isTrendReversed = TrendReversedCheck();
   
   if (Period() > 60) { // H1 above
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 200;
      } else { // sleeping hours 10PM-12PM
         factor = 160;
      }
      if (isStochOver) {
         factor = 120;
      }
      if (isOverTrade) {
         factor = 100;
      }
   } else if (Period() == 60) {  // H1
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 100;
      } else { // sleeping hours 10PM-12PM
         factor = 80;
      }
      if (isStochOver) {
         factor = 60;
      }
      if (isOverTrade) {
         factor = 50;
      }
   } else { // H1 below
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 50;
      } else { // sleeping hours 10PM-12PM
         factor = 25;
      }
      if (isStochOver) {
         factor = 20;
      }
      if (isOverTrade) {
         factor = 15;
      }
   }

   /* TEST OFFLINE */
   // factor = -15; // test and comment out closeSet

   double getProfit = VolumeSize * factor;
   bool isClosing = false;
   string takeProfit = NULL;
   string initFactor = NULL;
   string newFactor = NULL;
   string borderFactor = NULL;

   long barVolume = iVolume(symbol, Period(), 0);
   double barOpen = iOpen(symbol, Period(), 0);
   double barClose = iClose(symbol, Period(), 0);
   double barHigh = iHigh(symbol, Period(), 0);
   double barLow = iLow(symbol, Period(), 0);
   double barLine = (channelTradeAction == "buy") ? barHigh : barLow;
   bool barPower = (channelTradeAction == "buy") ? bullsPowerCheck() > bearsPowerCheck() : bearsPowerCheck() > bullsPowerCheck();

   string filename0 = StringConcatenate(symbol, Period(), "-initFactor.txt");
   string filename = StringConcatenate(symbol, Period(), "-takeProfit.txt");
   string filename2 = StringConcatenate(symbol, Period(), "-newFactor.txt");
   string filename3 = StringConcatenate(symbol, Period(), "-borderFactor.txt");
   string filename1 = StringConcatenate(symbol, Period(), "-orderType.txt");

   // store initialized
   int filehandle0_w = FileOpen(filename0, FILE_WRITE|FILE_TXT);
   FileWriteString(filehandle0_w, IntegerToString(factor));
   FileClose(filehandle0_w);

   int filehandle0_r = FileOpen(filename0, FILE_READ|FILE_TXT);
   initFactor = FileReadString(filehandle0_r);
   FileClose(filehandle0_r);

   if (FileIsExist(filename)) {
      int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
      takeProfit = FileReadString(filehandle_r);
      FileClose(filehandle_r);
   }

   if (FileIsExist(filename2)) {
      int filehandle2_r = FileOpen(filename2, FILE_READ|FILE_TXT);
      newFactor = FileReadString(filehandle2_r);
      FileClose(filehandle2_r);
   }

   if (FileIsExist(filename3)) {
      int filehandle3_r = FileOpen(filename3, FILE_READ|FILE_TXT);
      borderFactor = FileReadString(filehandle3_r);
      FileClose(filehandle3_r);
   }

   if (newFactor != NULL) {
      factor = StrToInteger(newFactor);
   }

   getProfit = VolumeSize * factor;

   // close per currency
   for (int i=0; i<OrdersTotal(); i++) { 
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if(OrderSymbol() == Symbol()) {
            currencyProfit = OrderProfit() + OrderSwap() + OrderCommission();

            // Print(">>> CURRENCY PROFIT (BASIS) +-----> ", currencyProfit);
            // Print(">>> TAKE PROFIT (BASIS) +-----> ", StringToDouble(takeProfit));
            // Print(">>> GET PROFIT (BASIS) +-----> ", getProfit);
            // Print(">>> INIT FACTOR (BASIS) +-----> ", StringToInteger(initFactor));
            // Print(">>> FACTOR (BASIS) +-----> ", factor);
            // Print(">>> NEW FACTOR (BASIS) +-----> ", StrToInteger(newFactor));
            // Print(">>> BORDER FACTOR (BASIS) +-----> ", StrToInteger(borderFactor));

            // set trailing stop
            if (currencyProfit > getProfit) {
               Print("INCREMENTING +-----> ", currencyProfit);
               int filehandle_w = FileOpen(filename, FILE_WRITE|FILE_TXT);
               FileWriteString(filehandle_w, DoubleToStr(currencyProfit, 2));
               FileClose(filehandle_w);
               isClosing = true;

               // set factor border
               if (factor == StrToInteger(initFactor) + 5 && borderFactor == NULL) {
                  int filehandle3_w = FileOpen(filename3, FILE_WRITE|FILE_TXT);
                  FileWriteString(filehandle3_w, IntegerToString(factor));
                  FileClose(filehandle3_w);
               }

               if (factor == StrToInteger(borderFactor) + 5 && borderFactor != NULL) {
                  int filehandle3_w = FileOpen(filename3, FILE_WRITE|FILE_TXT);
                  FileWriteString(filehandle3_w, IntegerToString(factor));
                  FileClose(filehandle3_w);

                  int filehandle3_r = FileOpen(filename3, FILE_READ|FILE_TXT);
                  borderFactor = FileReadString(filehandle3_r);
                  FileClose(filehandle3_r);
               }

               // get profit now
               if (currencyProfit > StringToDouble(takeProfit) && takeProfit != NULL) {
                  Print("currencyProfit > StringToDouble(takeProfit) +++++MORE+++++");
                  if (channelTradeAction == "buy" && bearsPowerCheckValue() >= 0) { // nearest trailing stop     
                     factor += 1;

                     Print("BULL POWER !! INCREASING FACTOR...", factor);
                     int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle2_w, IntegerToString(factor));
                     FileClose(filehandle2_w);

                     break;
                  } else if (channelTradeAction == "sell" && bullsPowerCheckValue() <= 0) { // nearest trailing stop 
                     factor += 1;

                     Print("BEAR POWER !! INCREASING FACTOR...", factor);
                     int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle2_w, IntegerToString(factor));
                     FileClose(filehandle2_w);

                     break;
                  } else {
                     Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                     FileDelete(filename0);
                     FileDelete(filename);
                     FileDelete(filename2);
                     FileDelete(filename3);
                     isClosing = false;

                     if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        Print("Order Not Close with Error! ", GetLastError());
                     }

                     break;
                  }
               }

               if (currencyProfit < StringToDouble(takeProfit) && takeProfit != NULL) {
                  Print("currencyProfit < StringToDouble(takeProfit) +++++LESS+++++");
                  if (currencyProfit >= StrToInteger(borderFactor)) {
                     if (channelTradeAction == "buy" && barClose < barHigh) {
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename0);
                        FileDelete(filename);
                        FileDelete(filename2);
                        FileDelete(filename3);
                        isClosing = false;

                        if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                           Print("Order Not Close with Error! ", GetLastError());
                        }

                        break;
                     }
                     if (channelTradeAction == "sell" && barClose > barLow) {
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename0);
                        FileDelete(filename);
                        FileDelete(filename2);
                        FileDelete(filename3);
                        isClosing = false;

                        if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                           Print("Order Not Close with Error! ", GetLastError());
                        }

                        break;
                     }
                  }
               }
            }
         }
      }
   }

   closeSet = getProfit * 2;

   if (CloseSetEnable) {
      // get orders total profit 
      for (int i=0; i<OrdersTotal(); i++) { 
         if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
            totalProfit += OrderProfit() + OrderSwap() + OrderCommission();
         }
      }
      // close set from total profit
      if (totalProfit >= closeSet) {
         Print("SET CLOSE PROFIT +-----> ", totalProfit);
         CloseOrders();
         FileDelete(filename0);
         FileDelete(filename);
         FileDelete(filename2);
         FileDelete(filename3);
      }
   }

   double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
   double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue

   if (channelTradeAction != NULL) {
      isTrendReversed = TrendReversedCheck();
      // BUY - Close is Below Tenkan = CLOSED
      if (channelTradeAction == "buy" && currencyTotalOrders != 0) {
         if (isStochOver && isTrendReversed) {
            Print("StochOver and RSI reversed On Tick !!");
            Print("Trend Changed Now Closing!!");
            CloseOrders();
            FileDelete(filename0);
            FileDelete(filename);
            FileDelete(filename2);
            FileDelete(filename3);

            //Re-order during reversal
            // if (ReOrderReversal) {
            // Print("Re-opening Reversal Order On Tick !!");
            // channelTradeAction = "sell";

            // int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
            // FileWriteString(filehandle1_w, channelTradeAction);
            // FileClose(filehandle1_w);

            // isRSI = RSICheck();
            // isStochRSI = StochRSICheck();
            // isTechAnalysis = true;
            // NewOrder();
            // }
         }
         
         if (Tenkan > barClose) {
            Print("Close Bar HIT On Tick !!");
            if (isTrendReversed) {
               Print("Trend Changed Now Closing!!");
               CloseOrders();
               FileDelete(filename0);
               FileDelete(filename);
               FileDelete(filename2);
               FileDelete(filename3);
            }
         }
         // close if crossed on tick
         if (Tenkan <= Kijun) {
            if (isTrendReversed) {
               Print("CLOSE IF CROSSED ON TICK!!");
               CloseOrders();
               FileDelete(filename0);
               FileDelete(filename);
               FileDelete(filename2);
               FileDelete(filename3);
            }
         }
      }
      // SELL - Close is Above Tenkan = CLOSED
      if (channelTradeAction == "sell" && currencyTotalOrders != 0) {
         if (isStochOver && isTrendReversed) {
            Print("StochOver and RSI reversed On Tick !!");
            Print("Trend Changed Now Closing!!");
            CloseOrders();
            FileDelete(filename0);
            FileDelete(filename);
            FileDelete(filename2);
            FileDelete(filename3);

            //Re-order during reversal
            // if (ReOrderReversal) {
            // Print("Re-opening Reversal Order On Tick !!");
            // channelTradeAction = "buy";

            // int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
            // FileWriteString(filehandle1_w, channelTradeAction);
            // FileClose(filehandle1_w);

            // isRSI = RSICheck();
            // isStochRSI = StochRSICheck();
            // isTechAnalysis = true;
            // NewOrder();
            // }
         }

         if (Tenkan < barClose) {
            Print("Close Bar HIT On Tick !!");
            if (isTrendReversed) {
               Print("Trend Changed Now Closing!!");
               CloseOrders();
               FileDelete(filename0);
               FileDelete(filename);
               FileDelete(filename2);
               FileDelete(filename3);
            }
         }
         // close if crossed on tick
         if (Tenkan >= Kijun) {
            if (isTrendReversed) {
               Print("CLOSE IF CROSSED ON TICK!!");
               CloseOrders();
               FileDelete(filename0);
               FileDelete(filename);
               FileDelete(filename2);
               FileDelete(filename3);
            }
         }
      }
   }

   // Comment("Local Time (PH): ", localTime, " TOTAL Orders +-----> ", OrdersTotal(), " Currency TOTAL Orders: ", currencyTotalOrders, " @ ", symbol, ", BUY +-----> ", buyCount, ", SELL +-----> ", sellCount, " IS OVER TRADE? +-----> ", isOverTrade, " CLOSE SET +-----> ", closeSet, " SINGLE CLOSE  +-----> ", getProfit);
   // Comment("OrderType: ", channelTradeAction, " Re-OpenOrder: ", reOpenOrder, " Tech-Analysis: ", TechnicalAnalysisCheck(), " BarPower: ", barPower, " isStochOver: ", isStochOver, " isOverTrade: ", isOverTrade, " isCloseSet: ", (CloseSetEnable) ? closeSetMode : ToUpper("Disabled"), " GetProfit ", getProfit, " || TakeProfit: ", takeProfit, " CurrencyProfit: ", currencyProfit, " isCLosing: ", isClosing, " ATR: ", ATRCheck());
   Comment("Re-OpenOrder: ", reOpenOrder, " isTrendReversed: ", isTrendReversed, " Re-OrderReversal: ", ReOrderReversal, " Bears: ", bearsPowerCheckValue(), " Bulls: ", bullsPowerCheckValue(), " isStochOver: ", isStochOver, " isOverTrade: ", isOverTrade, " isCloseSet: ", (CloseSetEnable) ? closeSetMode : ToUpper("Disabled"), " || INIT FACTOR: ", initFactor, " FACTOR: ", factor, " BORDER FACTOR: ", borderFactor, " GETPROFIT: ", getProfit, " TAKEPROFIT: ", takeProfit, " CURRENCYPROFIT: ", currencyProfit);
} 

void NewOrder() {
   /* TEST OFFLINE */
   // channelTradeAction = "buy";
   // isRSI = true;
   // isStochRSI = true;
   isTechAnalysis = true;
   // isOverTrade = false;

   if (channelTradeAction != NULL && currencyTotalOrders == 0 && isRSI && isStochRSI && isTechAnalysis && isStartTrade) {
      Print("Ready to " + ToUpper(channelTradeAction) + " ...");

      int orderType = (channelTradeAction == "buy" ? OP_BUY : OP_SELL);
      double openPrice = (channelTradeAction == "buy" ? Ask : Bid);
      color orderColor = (channelTradeAction == "buy" ? clrBlue : clrRed);
      double buySL; double buyTP; double sellSL; double sellTP;

      int Slipage = 5;

      if (channelTradeAction == "buy") {
         int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slipage, 0, 0, symbol + period + " CANDLE_v4.0 " + timeStamp, MagicNumber, 0, orderColor);

         Print("**** BUYING NOW!!! ");
         Print("Price +-----> ", openPrice);
         Print("SL +-----> ", buySL);
         Print("TP +-----> ", buyTP);
      }
      if (channelTradeAction == "sell") {
         int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slipage, 0, 0, symbol + period + " CANDLE_v4.0 " + timeStamp, MagicNumber, 0, orderColor);

         Print("**** SELLING NOW!!! ");
         Print("Price +-----> ", openPrice);
         Print("SL +-----> ", sellSL);
         Print("TP +-----> ", sellTP);
      }

      stopCheckPoint = false;
      isStartTrade = false;

      Print("END channelTradeAction +-----> ", channelTradeAction);
      Print("END prevChannelTradeAction +-----> ", prevChannelTradeAction);
      Print("END techAnalysisAction +-----> ", techAnalysisAction);
   }
}

void CloseOrders() {
   Print("xxx Closing All Open Orders xxx");

   int Slippage = 0;

   for (int i=0; i<OrdersTotal(); i++ ) { 
      if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if (OrderSymbol() == Symbol()) {
            if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
               Print("Order Not Close with Error! ", GetLastError());
            }  
         }
      }
   }

   reOpenOrder = false;
   isReversalOrder = false;
   stopCheckPoint = false;
   isStartTrade = false;
}

void OrderCounter() {
   int buyCounter = 0;
   int sellCounter = 0;
   int currencyBuyCounter = 0;
   int currencySellCounter = 0;

   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderType() == OP_BUY) { // buy orders
            buyCounter++;
            if(OrderSymbol() == Symbol()) {
               currencyBuyCounter++;
            }
         }
         if (OrderType() == OP_SELL) { // sell orders
            sellCounter++;
            if (OrderSymbol() == Symbol()) {
               currencySellCounter++;
            }
         }
      } 
   }

   buyCount = buyCounter;
   sellCount = sellCounter;
   currencyBuyCount = currencyBuyCounter;
   currencySellCount = currencySellCounter;
   currencyTotalOrders = currencyBuyCount + currencySellCount;
}

string ToUpper(string text) { 
   StringToUpper(text);
   return text; 
}
