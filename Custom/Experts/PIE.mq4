//+------------------------------------------------------------------+
//|                                   _       FINWAZE TRADING SYSTEM |
//|                     Copyright 2023, FOR FINWAZE TRADERS USE ONLY |
//|                                         FINWAZE FOREX TRDERS HUB |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, FINWAZE TRADING SYSTEM."
#property link      "FINWAZE FOREX TRADERS HUB"
#property version   "1.00"
#property strict
#property script_show_inputs
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input int ii_magicNumber = 1212;
input double ii_lots = 0.01;
input int ii_slipage = 5;

datetime prevTime;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   prevTime = iTime(Symbol(),PERIOD_CURRENT,1);
   /* Print("MODE_LOTSIZE = ", MarketInfo(Symbol(), MODE_LOTSIZE));
   Print("MODE_MINLOT = ", MarketInfo(Symbol(), MODE_MINLOT));
   Print("MODE_LOTSTEP = ", MarketInfo(Symbol(), MODE_LOTSTEP));
   Print("MODE_MAXLOT = ", MarketInfo(Symbol(), MODE_MAXLOT));
   */
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int li_factor = 1;
   if(Digits ==5 || Digits == 3)
     { li_factor = 20;}

   double ld_rsiValue1 = iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE,0);
   double ld_rsiValue2 = iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE,1);

   if(ld_rsiValue1 >65  && ld_rsiValue2 <65 )
     {
      if(prevTime != iTime(_Symbol,PERIOD_CURRENT,0))
        {
         int li_ticket = OrderSend(_Symbol, OP_SELL, ii_lots, Bid, ii_slipage, Ask+(20*Point()*li_factor), Ask-(20*Point()*li_factor), NULL, ii_magicNumber, 0, clrRed);
         func_OrderClose(0);
         prevTime = iTime(_Symbol,PERIOD_CURRENT,0);
        }
     }

   if(ld_rsiValue1 < 35 && ld_rsiValue2 > 35)
     {
      if(prevTime != iTime(_Symbol,PERIOD_CURRENT,0))
        {
         int li_ticket = OrderSend(_Symbol, OP_BUY, ii_lots, Ask, ii_slipage, Bid-(20*Point()*li_factor), Bid+(20*Point()*li_factor), NULL, ii_magicNumber, 0, clrBlue);
         func_OrderClose(1);
         prevTime = iTime(_Symbol,PERIOD_CURRENT,0);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void func_OrderClose(int ordertype)
  {
   int li_totalOrder = OrdersTotal();
   for(int i=(li_totalOrder-1); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderMagicNumber() == ii_magicNumber && OrderType() == ordertype)
           {
            if(OrderCloseTime() == 0)
              {
               if(!OrderClose(OrderTicket(), ii_lots, OrderClosePrice(), ii_slipage))
                 {
                  Print("Order Not Close with Error! ",GetLastError());
                 }
              }

           }

        }
     }
  }





//+------------------------------------------------------------------+
