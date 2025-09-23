#property version "8.1"
#property strict

input double VolumeSize = 0.01;
input double ForceTakeProfit = 1.30;
input bool NewsCloseTrade = true;
input bool CloseSetEnable = false;
input int OrderLimit = 3;
input int MagicNumber = 1212;

string localTime = TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS);
string timeStamp = TimeToStr(TimeLocal(), TIME_SECONDS);
string channelTradeAction = NULL;
bool isRSI = false;
bool isStochRSI = false;
bool isTechAnalysis = false;
bool isRSIOver = false;
bool isStochOver = false;
bool isOverTrade = false;
bool isReversalOrder = false;
bool isStochOverCheck = false;
bool stopTrade = false;
string currentBlackRSI = NULL;
string currentRedRSI = NULL;
string prevBlackRSI = NULL;
string prevRedRSI = NULL;
string currentBlackStochRSI = NULL;
string currentRedStochRSI = NULL;
string prevBlackStochRSI = NULL;
string prevRedStochRSI = NULL;
string currentDate = NULL;
int buyCount = 0;
int sellCount = 0;
int currencyBuyCount = 0;
int currencySellCount = 0;
int currencyTotalOrders = 0;
int buyLimitCounter = 0;
int sellLimitCounter = 0;
double closeSet = 0;
// for Pro Spread currency names with "+"
string symbol = Symbol();
int replace = StringReplace(symbol, "+", "");
string period = IntegerToString(Period());
string closeSetMode = DoubleToString(closeSet);

void OnTick() {

   localTime = TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS);
   timeStamp = TimeToStr(TimeLocal(), TIME_SECONDS);

   if (IsNewDay()) { 
      Print("----!!!!----- NEW DAY ----!!!!-----");
      Print("Local Time (PH): ", localTime);
      buyLimitCounter = 0; 
      sellLimitCounter = 0;
   }
   
   if (isNewTick()) {
      // Print("----!!!!----- NEW TICK ----!!!!-----");
      OrderCounter();

      if (currencyTotalOrders != 0) {
         if (NewsCloseTrade) {
            CheckNews();
         }
         CheckOpenOrders();
      }

      if (currencyTotalOrders == 0 && !stopTrade && prevBlackRSI != NULL && prevRedRSI != NULL && prevBlackStochRSI != NULL && prevRedStochRSI != NULL && buyLimitCounter <= OrderLimit && sellLimitCounter <= OrderLimit) {
         if (NewsCloseTrade) {
            CheckNews();
         }
         if (!stopTrade) {
            PrepareOrder();
            NewOrder();
         }
      }
   }

   if (IsNewCandle()) {
      // Print("----++++----- NEW CANDLE ----++++-----");
      double red_rsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE RSI CROSSOVER BASIC", 14, 14, 0.618, 0, 0); //finwaze 14  
      double black_rsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE RSI CROSSOVER BASIC", 14, 14, 0.618, 1, 0); //RSI 14

      double black_stochrsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE STOCHRSI VER 3", 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
      double red_stochrsi = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE STOCHRSI VER 3", 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D

      string filenameBlackRSI = StringConcatenate(symbol, Period(), "-prevBlackRSI.txt");
      string filenameRedRSI = StringConcatenate(symbol, Period(), "-prevRedRSI.txt");
      string filenameBlackStochRSI = StringConcatenate(symbol, Period(), "-prevBlackStochRSI.txt");
      string filenameRedStochRSI = StringConcatenate(symbol, Period(), "-prevRedStochRSI.txt");

      currentBlackRSI = DoubleToString(black_rsi);
      currentRedRSI = DoubleToString(red_rsi);
      prevBlackRSI = NULL;
      prevRedRSI = NULL;
      currentBlackStochRSI = DoubleToString(black_stochrsi);
      currentRedStochRSI = DoubleToString(red_stochrsi);
      prevBlackStochRSI = NULL;
      prevRedStochRSI = NULL;

      if (FileIsExist(filenameBlackRSI)) {
         int filenameBlackRSI_r = FileOpen(filenameBlackRSI, FILE_READ|FILE_TXT);
         prevBlackRSI = FileReadString(filenameBlackRSI_r);
         FileClose(filenameBlackRSI_r);

         int filenameBlackRSI_w = FileOpen(filenameBlackRSI, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameBlackRSI_w, currentBlackRSI);
         FileClose(filenameBlackRSI_w);
      } else {
         int filenameBlackRSI_w = FileOpen(filenameBlackRSI, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameBlackRSI_w, currentBlackRSI);
         FileClose(filenameBlackRSI_w);
      }

      if (FileIsExist(filenameRedRSI)) {
         int filenameRedRSI_r = FileOpen(filenameRedRSI, FILE_READ|FILE_TXT);
         prevRedRSI = FileReadString(filenameRedRSI_r);
         FileClose(filenameRedRSI_r);

         int filenameRedRSI_w = FileOpen(filenameRedRSI, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameRedRSI_w, currentRedRSI);
         FileClose(filenameRedRSI_w);
      } else {
         int filenameRedRSI_w = FileOpen(filenameRedRSI, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameRedRSI_w, currentRedRSI);
         FileClose(filenameRedRSI_w);
      }

      if (FileIsExist(filenameBlackStochRSI)) {
         int filenameBlackStochRSI_r = FileOpen(filenameBlackStochRSI, FILE_READ|FILE_TXT);
         prevBlackStochRSI = FileReadString(filenameBlackStochRSI_r);
         FileClose(filenameBlackStochRSI_r);

         int filenameBlackStochRSI_w = FileOpen(filenameBlackStochRSI, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameBlackStochRSI_w, currentBlackStochRSI);
         FileClose(filenameBlackStochRSI_w);
      } else {
         int filenameBlackStochRSI_w = FileOpen(filenameBlackStochRSI, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameBlackStochRSI_w, currentBlackStochRSI);
         FileClose(filenameBlackStochRSI_w);
      }

      if (FileIsExist(filenameRedStochRSI)) {
         int filenameRedStochRSI_r = FileOpen(filenameRedStochRSI, FILE_READ|FILE_TXT);
         prevRedStochRSI = FileReadString(filenameRedStochRSI_r);
         FileClose(filenameRedStochRSI_r);

         int filenameRedStochRSI_w = FileOpen(filenameRedStochRSI, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameRedStochRSI_w, currentRedStochRSI);
         FileClose(filenameRedStochRSI_w);
      } else {
         int filenameRedStochRSI_w = FileOpen(filenameRedStochRSI, FILE_WRITE|FILE_TXT);
         FileWriteString(filenameRedStochRSI_w, currentRedStochRSI);
         FileClose(filenameRedStochRSI_w);
      }
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

bool IsNewDay() {
   static int reset;
   bool result = (Hour() == 0 && reset == 1);

   if (Hour() != 0) reset = 1;

   if (result) reset = 0;

   return result;   
}

string IchimokuCheck() {
   double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
   double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue

   // Print("Tenkan (red): ", Tenkan, " Kijun (blue): ", Kijun);

   if (Tenkan > Kijun) {
      channelTradeAction = "buy";
   } else if (Tenkan < Kijun) {
      channelTradeAction = "sell";
   } else { // if equal
      channelTradeAction = NULL;
   }

   return channelTradeAction;
}

bool RSICheck() {
   string indicatorName = "\\Custom\\FINWAZE RSI CROSSOVER BASIC";
   double red = iCustom(Symbol(), Period(), indicatorName, 14, 14, 0.618, 0, 0); //finwaze 14  
   double black = iCustom(Symbol(), Period(), indicatorName, 14, 14, 0.618, 1, 0); //RSI 14
   isRSI = false;
   isRSIOver = false;

   string filenameBlackRSI = StringConcatenate(symbol, Period(), "-prevBlackRSI.txt");
   string filenameRedRSI = StringConcatenate(symbol, Period(), "-prevRedRSI.txt");
   string filenameBlackStochRSI = StringConcatenate(symbol, Period(), "-prevBlackStochRSI.txt");
   string filenameRedStochRSI = StringConcatenate(symbol, Period(), "-prevRedStochRSI.txt");

   // Print("RSI Red (finwaze14) ---> ", red);
   // Print("RSI Black (RSI14) ---> ", black);

   if (channelTradeAction == "buy" && (black - 1) > red) {
      if (!isReversalOrder) {
         // if black is greater thank red = BUY
         if (black >= 70 && red >= 65) {  // Overbought
            // Print("RSI OVERBOUGHT !!");
            isRSIOver = true;
         } else {
            isRSIOver = false;
         }
         
         if (FileIsExist(filenameBlackRSI) && FileIsExist(filenameRedRSI) && FileIsExist(filenameBlackStochRSI) && FileIsExist(filenameRedStochRSI)) {
            if (StringToDouble(prevBlackRSI) < StringToDouble(prevRedRSI)) {
               isRSI = true;
            }

            if (StringToDouble(prevBlackStochRSI) < StringToDouble(prevRedStochRSI)) {
               isRSI = true;
            }
         }         
      } else {
         isRSI = true;
      }
   }

   if (channelTradeAction == "sell" && (black + 1) < red) {
      if (!isReversalOrder) {
         // if black is less thank red = SELL
         if (black <= 30 && red <= 35) {   // Oversold
            // Print("RSI OVERSOLD !!");
            isRSIOver = true;
         } else {
            isRSIOver = false;
         }

         if (FileIsExist(filenameBlackRSI) && FileIsExist(filenameRedRSI) && FileIsExist(filenameBlackStochRSI) && FileIsExist(filenameRedStochRSI)) {
            if (StringToDouble(prevBlackRSI) > StringToDouble(prevRedRSI)) {
               isRSI = true;
            }

            if (StringToDouble(prevBlackStochRSI) > StringToDouble(prevRedStochRSI)) {
               isRSI = true;
            }
         }
      } else {
         isRSI = true;
      }
   }

   return isRSI;
}

bool StochRSICheck() {
   string indicatorName = "\\Custom\\FINWAZE STOCHRSI VER 3";
   double black = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
   double red = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D
   isStochRSI = false;
   isStochOver = false;

   string filenameBlackRSI = StringConcatenate(symbol, Period(), "-prevBlackRSI.txt");
   string filenameRedRSI = StringConcatenate(symbol, Period(), "-prevRedRSI.txt");
   string filenameBlackStochRSI = StringConcatenate(symbol, Period(), "-prevBlackStochRSI.txt");
   string filenameRedStochRSI = StringConcatenate(symbol, Period(), "-prevRedStochRSI.txt");

   // Print("Stoch RSI Red (D) ---> ", red);
   // Print("Stoch RSI Black (K) ---> ", black);

   if (channelTradeAction == "buy" && (black - 1) > red) {
      if (!isReversalOrder) {
         // if black is greater thank red = BUY
         if (black >= 80 && red >= 75) {  // Overbought
            // Print("StochRSI OVERBOUGHT !!");
            isStochOver = true;
         } else {
            isStochOver = false;
         }

         if (FileIsExist(filenameBlackRSI) && FileIsExist(filenameRedRSI) && FileIsExist(filenameBlackStochRSI) && FileIsExist(filenameRedStochRSI)) {
            if (StringToDouble(prevBlackRSI) < StringToDouble(prevRedRSI)) {
               isStochRSI = true;
            }

            if (StringToDouble(prevBlackStochRSI) < StringToDouble(prevRedStochRSI)) {
               isStochRSI = true;
            }
         }
      } else {
         isStochRSI = true;
      }
   }

   if (channelTradeAction == "sell" && (black + 1) < red) {
      if (!isReversalOrder) {
         // if black is less thank red = SELL
         if (black <= 20 && red <= 25) {   // Oversold
            // Print("StochRSI OVERSOLD !!");
            isStochOver = true;
         } else {
            isStochOver = false;
         }

         if (FileIsExist(filenameBlackRSI) && FileIsExist(filenameRedRSI) && FileIsExist(filenameBlackStochRSI) && FileIsExist(filenameRedStochRSI)) {
            if (StringToDouble(prevBlackRSI) > StringToDouble(prevRedRSI)) {
               isStochRSI = true;
            }

            if (StringToDouble(prevBlackStochRSI) > StringToDouble(prevRedStochRSI)) {
               isStochRSI = true;
            }
         }  
      } else {
         isStochRSI = true;
      }
   }

   return isStochRSI;
}

bool StochRSIOverCheck() {
   string indicatorName = "\\Custom\\FINWAZE STOCHRSI VER 3";
   double black = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
   double red = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D
   isStochOverCheck = false;

   // Print("StochRSIOverCheck Red (D) ---> ", red);
   // Print("StochRSIOverCheck Black (K) ---> ", black);

   if (!isReversalOrder) {
      if (channelTradeAction == "buy" && black >= 80 && red >= 75) {
         // Print("StochRSI OVERBOUGHT !!");
         isStochOverCheck = true;
         // Print("OVERBUY Stoch RSI Check --> ", isStochOverCheck);
      }

      if (channelTradeAction == "sell" && black <= 20 && red <= 25) {
         // Print("StochRSI OVERSOLD !!");
         isStochOverCheck = true;
         // Print("OVERSELL Stoch RSI Check --> ", isStochOverCheck);
      }
   }

   return isStochOverCheck;
}

bool TechnicalAnalysisCheck() {
   string techAnalysisAction = NULL;
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

   string indicatorName = "\\Custom\\FINWAZE STOCHRSI VER 3";
   double black = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
   double red = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D
   double totalProfit = NULL;
   double currencyProfit = NULL;
   int factor = 0;
   int Slippage = 0;
   isStochOverCheck = StochRSIOverCheck();
   
   if (Period() > 60) { // H1 above
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 200;
      } else { // sleeping hours 10PM-12PM
         factor = 160;
      }

      if (isStochOver || isStochOverCheck) {
         factor = 120;
      }
      if (isOverTrade) {
         factor = 100;
      }
      // if ((buyLimitCounter == 2 || sellLimitCounter == 2) && !isOverTrade) {
      //    factor = 120;
      // }
      // if ((buyLimitCounter == 3 || sellLimitCounter == 3) && !isOverTrade) {
      //    factor = 80;
      // }
   } else if (Period() == 60) {  // H1
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 100;
      } else { // sleeping hours 10PM-12PM
         factor = 80;
      }

      if (isStochOver || isStochOverCheck) {
         factor = 60;
      }
      if (isOverTrade) {
         factor = 50;
      }
      // if ((buyLimitCounter == 2 || sellLimitCounter == 2) && !isOverTrade) {
      //    factor = 60;
      // }
      // if ((buyLimitCounter == 3 || sellLimitCounter == 3) && !isOverTrade) {
      //    factor = 40;
      // }
   } else { // H1 below
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 50;
      } else { // sleeping hours 10PM-12PM
         factor = 25;
      }

      if (isStochOver || isStochOverCheck) {
         factor = 20;
      }
      if (isOverTrade) {
         factor = 15;
      }
      // if ((buyLimitCounter == 2 || sellLimitCounter == 2) && !isOverTrade) {
      //    factor = 20;
      // }
      // if ((buyLimitCounter == 3 || sellLimitCounter == 3) && !isOverTrade) {
      //    factor = 15;
      // }
   }

   /* TEST OFFLINE */
   // factor = -15; // test and comment out closeSet

   double getProfit = VolumeSize * factor;
   string takeProfit = NULL;
   string initFactor = NULL;
   string newFactor = NULL;
   string borderFactor = NULL;

   long barVolume = iVolume(symbol, Period(), 0);
   double barClose = iClose(symbol, Period(), 0);
   double barOpen = iOpen(symbol, Period(), 0);
   double barHigh = iHigh(symbol, Period(), 0);
   double barLow = iLow(symbol, Period(), 0);
   double barLine = (channelTradeAction == "buy") ? barHigh : barLow;
   bool barPower = (channelTradeAction == "buy") ? bullsPowerCheck() > bearsPowerCheck() : bearsPowerCheck() > bullsPowerCheck();

   string filename0 = StringConcatenate(symbol, Period(), "-initFactor.txt");
   string filename1 = StringConcatenate(symbol, Period(), "-takeProfit.txt");
   string filename2 = StringConcatenate(symbol, Period(), "-newFactor.txt");
   string filename3 = StringConcatenate(symbol, Period(), "-borderFactor.txt");

   // store initialized
   int filehandle0_w = FileOpen(filename0, FILE_WRITE|FILE_TXT);
   FileWriteString(filehandle0_w, IntegerToString(factor));
   FileClose(filehandle0_w);

   int filehandle0_r = FileOpen(filename0, FILE_READ|FILE_TXT);
   initFactor = FileReadString(filehandle0_r);
   FileClose(filehandle0_r);

   if (FileIsExist(filename1)) {
      int filehandle1_r = FileOpen(filename1, FILE_READ|FILE_TXT);
      takeProfit = FileReadString(filehandle1_r);
      FileClose(filehandle1_r);
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
               // force take profit
               if ((currencyProfit >= getProfit * ForceTakeProfit)) {
                  Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);

                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }

                  isReversalOrder = false;

                  break;
               }

               Print("INCREMENTING +-----> ", currencyProfit);
               int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
               FileWriteString(filehandle1_w, DoubleToStr(currencyProfit, 2));
               FileClose(filehandle1_w);

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
                  if (OrderType() == OP_BUY && bearsPowerCheckValue() >= 0 && black > red) { // nearest trailing stop
                     factor += 1;

                     Print("BULL POWER !! INCREASING FACTOR...", factor);
                     int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle2_w, IntegerToString(factor));
                     FileClose(filehandle2_w);

                     break;
                  } else if (OrderType() == OP_SELL && bullsPowerCheckValue() <= 0 && black < red) { // nearest trailing stop 
                     factor += 1;

                     Print("BEAR POWER !! INCREASING FACTOR...", factor);
                     int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle2_w, IntegerToString(factor));
                     FileClose(filehandle2_w);

                     break;
                  } else {
                     Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);

                     if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        Print("Order Not Close with Error! ", GetLastError());
                     }

                     isReversalOrder = false;

                     break;
                  }
               }

                if (currencyProfit <= StringToDouble(takeProfit) && takeProfit != NULL) {
                  Print("currencyProfit < StringToDouble(takeProfit) +++++LESS+++++");
                  if (currencyProfit >= StrToInteger(borderFactor)) {
                     if (OrderType() == OP_BUY && barClose < barHigh) {
                     // if (OrderType() == OP_BUY && black < red) {   
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename0);
                        FileDelete(filename1);
                        FileDelete(filename2);
                        FileDelete(filename3);

                        if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                           Print("Order Not Close with Error! ", GetLastError());
                        }

                        isReversalOrder = false;

                        break;
                     }
                     if (OrderType() == OP_SELL && barClose > barLow) {
                     // if (OrderType() == OP_SELL && black > red) { 
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename0);
                        FileDelete(filename1);
                        FileDelete(filename2);
                        FileDelete(filename3);

                        if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                           Print("Order Not Close with Error! ", GetLastError());
                        }

                        isReversalOrder = false;

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
         FileDelete(filename1);
         FileDelete(filename2);
         FileDelete(filename3);

         isReversalOrder = false;
      }
   }

   double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
   double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue

   // cut loss
   for (int i=0; i<OrdersTotal(); i++) { 
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if(OrderSymbol() == Symbol()) {
            // BUY - Close is Below Tenkan = CLOSED
            if (OrderType() == OP_BUY) {
                  channelTradeAction = "buy";
               if (!isReversalOrder && isStochOverCheck && (black + 5) < red) {
                  Print("StochOver and RSI reversed On Tick !!");
                  Print("Trend Changed Now Closing!!");
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);

                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }

                  // Re-order during reversal
                  if (NewsCloseTrade) {
                     CheckNews();
                  }
                  if (!stopTrade) {
                     Print("Re-opening Reversal Order On Tick !!");
                     channelTradeAction = "sell";
                     isReversalOrder = true;
                     isStochOverCheck = false;

                     PrepareOrder();
                     NewOrder();
                  }

                  break;
               }

               // Reversal order cut loss when lost 100 points
               if (isReversalOrder && barClose > barOpen && (barClose + 0.001 < barHigh) && (black + 1) < red) {
                  Print("Reversal Order CLOSED On Tick !!");
                  Print("Trend Changed Now Closing!!");
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);

                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }

                  isReversalOrder = false;

                  break;
               }

               if (!isReversalOrder && (black + 5) < red) {
                  Print("ReOpen Order CLOSED On Tick !!");
                  Print("Trend Changed Now Closing!!");
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);

                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }

                  break;
               }
               
               if (!isReversalOrder && Tenkan > barClose) {
                  // Print("Close Bar HIT On Tick !!");
                  if ((black + 3) < red || !isTechAnalysis) {
                     Print("Trend Changed Now Closing!!");
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);

                     if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        Print("Order Not Close with Error! ", GetLastError());
                     }

                     break;
                  }
               }
               // close if crossed on tick
               if (!isReversalOrder && Tenkan <= Kijun) {
                  if ((black + 3) < red || !isTechAnalysis) {
                     Print("CLOSE IF CROSSED ON TICK!!");
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);

                     if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        Print("Order Not Close with Error! ", GetLastError());
                     }

                     break;
                  }
               }
            }

            // SELL - Close is Above Tenkan = CLOSED
            if (OrderType() == OP_SELL) {
               channelTradeAction = "sell";
               if (!isReversalOrder && isStochOverCheck && (black - 5) > red) {
                  Print("StochOver and RSI reversed On Tick !!");
                  Print("Trend Changed Now Closing!!");
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);
                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }

                  // Re-order during reversal
                  if (NewsCloseTrade) {
                     CheckNews();
                  }
                  if (!stopTrade) {
                     Print("Re-opening Reversal Order On Tick !!");
                     channelTradeAction = "buy";
                     isReversalOrder = true;
                     isStochOverCheck = false;

                     PrepareOrder();
                     NewOrder();
                  }

                  break;
               }

               // Reversal order cut loss when lost 100 points
               if (isReversalOrder && barClose < barOpen && (barClose - 0.001 > barLow) && (black - 1) > red) {
                  Print("Reversal Order CLOSED On Tick !!");
                  Print("Trend Changed Now Closing!!");
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);

                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }

                  isReversalOrder = false;

                  break;
               }

               if (!isReversalOrder && (black - 5) > red) {
                  Print("ReOpen Order CLOSED On Tick !!");
                  Print("Trend Changed Now Closing!!");
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);

                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }

                  break;
               }

               if (!isReversalOrder && Tenkan < barClose) {
                  // Print("Close Bar HIT On Tick !!");
                  if ((black - 3) > red || !isTechAnalysis) {
                     Print("Trend Changed Now Closing!!");
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);
                     if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        Print("Order Not Close with Error! ", GetLastError());
                     }

                     break;
                  }
               }
               // close if crossed on tick
               if (!isReversalOrder && Tenkan >= Kijun) {
                  if ((black - 3) > red || !isTechAnalysis) {
                     Print("CLOSE IF CROSSED ON TICK!!");
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);
                     
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

   // Comment("Local Time (PH): ", localTime, " TOTAL Orders +-----> ", OrdersTotal(), " Currency TOTAL Orders: ", currencyTotalOrders, " @ ", symbol, ", BUY +-----> ", buyCount, ", SELL +-----> ", sellCount, " IS OVER TRADE? +-----> ", isOverTrade, " CLOSE SET +-----> ", closeSet, " SINGLE CLOSE  +-----> ", getProfit);
   // Comment("Reversal Order: ", isReversalOrder, " isTrendReversed: ", isTrendReversed, " Re-OrderReversal: ", ReOrderReversal, " Bears: ", bearsPowerCheckValue(), " Bulls: ", bullsPowerCheckValue(), " isStochOver: ", isStochOver, " isOverTrade: ", isOverTrade, " isCloseSet: ", (CloseSetEnable) ? closeSetMode : ToUpper("Disabled"), " || INIT FACTOR: ", initFactor, " FACTOR: ", factor, " BORDER FACTOR: ", borderFactor, " GETPROFIT: ", getProfit, " TAKEPROFIT: ", takeProfit, " CURRENCYPROFIT: ", currencyProfit);
   Comment("Stop Trade(News): ", stopTrade, " Reversal Order: ", isReversalOrder, " isStochOverCheck: ", isStochOverCheck, " isStochOver: ", isStochOver, " isOverTrade: ", isOverTrade, " isCloseSet: ", (CloseSetEnable) ? closeSetMode : ToUpper("Disabled"), " || INIT FACTOR: ", initFactor, " FACTOR: ", factor, " BORDER FACTOR: ", borderFactor, " GETPROFIT: ", getProfit, " TAKEPROFIT: ", takeProfit, " CURRENCYPROFIT: ", currencyProfit, " BUY LIMIT: ", buyLimitCounter, " SELL LIMIT: ", sellLimitCounter);
} 

void PrepareOrder() {
   if (!isReversalOrder) {
      channelTradeAction = IchimokuCheck();
   }

   double black = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE STOCHRSI VER 3", 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
   double red = iCustom(Symbol(), Period(), "\\Custom\\FINWAZE STOCHRSI VER 3", 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D
   isStochOverCheck = StochRSIOverCheck();
   if (!isReversalOrder && isStochOverCheck && (black + 5) < red) {
      Print("Reversal Order !!");
      channelTradeAction = "sell";
      isReversalOrder = true;
      isStochOverCheck = false;

      NewOrder();
   }
   if (!isReversalOrder && isStochOverCheck && (black - 5) > red) {
      Print("Reversal Order !!");
      channelTradeAction = "buy";
      isReversalOrder = true;
      isStochOverCheck = false;

      NewOrder();
   }

   isRSI = RSICheck();
   isStochRSI = StochRSICheck();

   if (!isRSI || !isStochRSI) {
      // Print("RSI Indicators are WRONG +-----> ", isRSI, " | ", isStochRSI);
      isReversalOrder = false;
   }

   if (isRSI && isStochRSI) {
      // Print("RSI Indicators are CORRECT +-----> ", isRSI, " | ", isStochRSI);
      if (!isReversalOrder) {
            isTechAnalysis = TechnicalAnalysisCheck();
            // Print("Proceeding to Technical Analysis Check +-----> ", isTechAnalysis);
         if (isRSIOver && isStochOver) {  // check overbought & oversold
            isOverTrade = true;
            // Print("Overbought/Oversold...");
         } else {
            isOverTrade = false;
         }
      }
   }
}

void NewOrder() {
   /* TEST OFFLINE */
   // channelTradeAction = "buy";
   // isRSI = true;
   // isStochRSI = true;
   // isTechAnalysis = true;
   // isOverTrade = false;

   if (isReversalOrder) {
      isTechAnalysis = true;
      buyLimitCounter = 0;
      sellLimitCounter = 0;
   }

   if (channelTradeAction != NULL && currencyTotalOrders == 0 && !stopTrade && isRSI && isStochRSI) {
   // if (channelTradeAction != NULL && currencyTotalOrders == 0 && !stopTrade && isRSI && isStochRSI && isTechAnalysis) {
      Print("Ready to " + ToUpper(channelTradeAction) + " ...");

      int orderType = (channelTradeAction == "buy" ? OP_BUY : OP_SELL);
      double openPrice = (channelTradeAction == "buy" ? Ask : Bid);
      color orderColor = (channelTradeAction == "buy" ? clrBlue : clrRed);
      double buySL; double buyTP; double sellSL; double sellTP;

      int Slipage = 5;

      if (channelTradeAction == "buy") {
         int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slipage, 0, 0, symbol + period + " EAGLE_v8.1 " + timeStamp, MagicNumber, 0, orderColor);

         Print("**** BUYING NOW!!! ");
         Print("Price +-----> ", openPrice);
         Print("SL +-----> ", buySL);
         Print("TP +-----> ", buyTP);

         if (buyLimitCounter <= OrderLimit) {
            buyLimitCounter++;
         }
      }

      if (channelTradeAction == "sell") {
         int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slipage, 0, 0, symbol + period + " EAGLE_v8.1 " + timeStamp, MagicNumber, 0, orderColor);

         Print("**** SELLING NOW!!! ");
         Print("Price +-----> ", openPrice);
         Print("SL +-----> ", sellSL);
         Print("TP +-----> ", sellTP);

         if (sellLimitCounter <= OrderLimit) {
            sellLimitCounter++;
         }
      }
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

   isReversalOrder = false;
   OrderCounter();
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

bool CheckNews() {
   string base =  StringFormat("%.3s", symbol);
   string quote = StringSubstr(symbol, 3, StringLen(symbol)-2);
   string localHour = IntegerToString(TimeHour(TimeLocal()));
   int Slippage = 0;

   stopTrade = false;

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

   string filename0 = StringConcatenate(symbol, Period(), "-initFactor.txt");
   string filename1 = StringConcatenate(symbol, Period(), "-takeProfit.txt");
   string filename2 = StringConcatenate(symbol, Period(), "-newFactor.txt");
   string filename3 = StringConcatenate(symbol, Period(), "-borderFactor.txt");

   // Stop News
   for (int i=0; i<OrdersTotal(); i++) { 
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if(OrderSymbol() == Symbol()) {
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

               if (localHour == base1 || localHour == base2 || localHour == base3 || localHour == base4 || localHour == base5 || localHour == base6 || localHour == base7 || localHour == base8 || localHour == base9 || localHour == base10) {
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);

                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }

                  stopTrade = true;
                  isReversalOrder = false;

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

               if (localHour == quote1 || localHour == quote2 || localHour == quote3 || localHour == quote4 || localHour == quote5 || localHour == quote6 || localHour == quote7 || localHour == quote8 || localHour == quote9 || localHour == quote10) {
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);

                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }

                  stopTrade = true;
                  isReversalOrder = false;

                  break;
               }
            }
         }
      }
   }

   return stopTrade;;
}

double ATRCheck() {
   double atr = iATR(Symbol(), Period(), 14, 1);

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

string ToUpper(string text) { 
   StringToUpper(text);
   return text; 
}
