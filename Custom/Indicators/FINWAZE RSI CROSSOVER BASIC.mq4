//+------------------------------------------------------------------+
//| ````````````````````````````````````FINWAZE SYSTEM RSI CROSSOVER
//| ```````````````````````````````````````````FINWAZE COPYRIGHT 2023|
//|                                        FACE: FINWAZE TRADERS HUB |
//+------------------------------------------------------------------+
#property copyright ""
#property link ""

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Red
#property indicator_color2 Black

extern int RSI_Period = 14;
extern int finwaze_Period = 14;
extern double finwaze_Curvature = 0.618;

double finwazeArray[];
double rsiArray[];

double e1,e2,e3,e4,e5,e6;
double c1,c2,c3,c4;
double n,w1,w2,b2,b3;

//+------------------------------------------------------------------+
//|           Custom indicator initialization function               |
//+------------------------------------------------------------------+
int init()
{
//---- indicators setting
SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,Red);
SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,Gold);

IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));
IndicatorShortName("finwaze RSI "+finwaze_Period);

SetIndexBuffer(0,finwazeArray);
SetIndexLabel(0,"finwaze"+finwaze_Period);

SetIndexBuffer(1,rsiArray);
SetIndexLabel(1,"RSI "+finwaze_Period);


//---- variable reset
e1=0; e2=0; e3=0; e4=0; e5=0; e6=0;
c1=0; c2=0; c3=0; c4=0;
n=0;
w1=0; w2=0;
b2=0; b3=0;

b2=finwaze_Curvature*finwaze_Curvature;
b3=b2*finwaze_Curvature;
c1=-b3;
c2=(3*(b2+b3));
c3=-3*(2*b2+finwaze_Curvature+b3);
c4=(1+3*finwaze_Curvature+b3+3*b2);
n=finwaze_Period;

if (n<1) n=1;
n = 1 + 0.5*(n-1);
w1 = 2 / (n + 1);
w2 = 1 - w1;

//----
return(0);
}

//+------------------------------------------------------------------+
//|         Custom indicator iteration function                      |
//+------------------------------------------------------------------+
int start() {
    int limit=Bars;

//---- indicator calculation

    for(int i=limit; i>=0; i--) {
        rsiArray[i] = iRSI(NULL,0,finwaze_Period,PRICE_CLOSE,i);

        e1 = w1*rsiArray[i] + w2*e1;
        e2 = w1*e1 + w2*e2;
        e3 = w1*e2 + w2*e3;
        e4 = w1*e3 + w2*e4;
        e5 = w1*e4 + w2*e5;
        e6 = w1*e5 + w2*e6;
        finwazeArray[i]=c1*e6 + c2*e5 + c3*e4 + c4*e3;
    }
    //----
    return(0);
}
//+------------------------------------------------------------------+