
*-------------------------------------------
* GAMS Electricity Dispatch Optimization Model
* Repository: GAMS-Electricity-Dispatch-Optimization
* Description: This model integrates thermal, nuclear, photovoltaic,
* wind, and hydraulic generation with different formulations:
*   - Base Model (Model 1)
*   - Model 1 without Hydraulic Energy (Water Value Calculation)
*   - Price-based Model (Model 2)
*   - Start-up/Shutdown Cost Model (Model 3)
*   - Stochastic Model (Model 4)
*-------------------------------------------

Sets
    i   Thermal Unit Group  /GAL, ARAG, CAT, 'EXT-AND', MUR, VAL, CAST, 'PV-NAV'/
    h   Time Block          /1,2,3,4/
    j   Hydraulic Group     /Tajo, Duero, Sil/
* For Model 4 (Stochastic)
    s   Possible Scenarios  /s1,s2,s3,s4/
    ss(s) Auxiliary Scenarios  /s1,s2,s3,s4/
;

Parameters
    p_max(i) Maximum power of unit i [MW] 
        /GAL 3000, ARAG 2600, CAT 5200, 'EXT-AND' 7000, MUR 3500, VAL 4000, CAST 2000, 'PV-NAV' 4000/
    p_min(i) Minimum power of unit i [MW] 
        /GAL 300, ARAG 300, CAT 400, 'EXT-AND' 500, MUR 300, VAL 400, CAST 250, 'PV-NAV' 200/
    rs(i)    Ramp-up limit of unit i [MWh] 
        /GAL 1500, ARAG 1500, CAT 1700, 'EXT-AND' 2500, MUR 1100, VAL 1700, CAST 1000, 'PV-NAV' 1700/
    rb(i)    Ramp-down limit of unit i [MWh] 
        /GAL 1500, ARAG 1500, CAT 1700, 'EXT-AND' 2500, MUR 1100, VAL 1700, CAST 1000, 'PV-NAV' 1700/
    b(i)     Unit cost [€MWh] 
        /GAL 6, ARAG 5.1, CAT 4, 'EXT-AND' 3.5, MUR 5.5, VAL 4.5, CAST 3, 'PV-NAV' 5/
    Pn       Nuclear power [MW] /7200/
    Pf(h)    Photovoltaic power [MW] /1 0, 2 4000, 3 6000, 4 0/
    Pe(h)    Wind power in each block [MW] /1 7000, 2 7000, 3 7000, 4 7000/
    d(h)     Demand [MW] /1 23000, 2 30000, 3 28000, 4 32000/
    pot_max_turb(j) Maximum hydraulic reserve power [MW] /Tajo 3000, Duero 4400, Sil 3500/
    Rh_max(j) Maximum hydraulic reserve [GWh] /Tajo 4180, Duero 6790, Sil 2600/
    Rh_min(j) Minimum hydraulic reserve [GWh] /Tajo 4175, Duero 6785, Sil 2595/
    Ri(j)    Initial hydraulic reserve [GWh] /Tajo 4179, Duero 6789, Sil 2599/
    F(j)     Flow for hydraulic group j [MW] /Tajo 160, Duero 440, Sil 200/
    ind(i)   Fixed cost term [€] /GAL 50, ARAG 30, CAT 40, 'EXT-AND' 80, MUR 60, VAL 70, CAST 90, 'PV-NAV' 55/
    ca(i)    Start-up cost [€] /GAL 2000, ARAG 1800, CAT 3600, 'EXT-AND' 4000, MUR 1600, VAL 1800, CAST 3000, 'PV-NAV' 1200/
    cp(i)    Shutdown cost [€] /GAL 400, ARAG 360, CAT 720, 'EXT-AND' 800, MUR 320, VAL 500,  CAST 600, 'PV-NAV' 440/
;

Table a(j,h) Hydraulic contributions in block h [MWh]
          1      2      3      4
Tajo    1140   1200   1500   1080
Duero   3000   3300   3600   2820
Sil     1320   1500   1800   1200
;

TABLE PeSt(s,h) Wind power production for each scenario s in block h [MW] 
         1      2      3     4
    s1  7000  7000  7200  7400
    s2  7000  7000  7200  7000
    s3  7000  7000  6800  7000
    s4  7000  7000  6800  6600
;

TABLE Prob(s,h) Probability for block h in each scenario s 
        1   2   3    4
    s1  1   1   0.6  0.36
    s2  0   0   0    0.24
    s3  0   0   0.4  0.24
    s4  0   0   0    0.16
;

TABLE matSt(s,h) Stochastic matrix
        1   2   3   4
    s1  1   1   1   1
    s2  1   1   1   2
    s3  1   1   3   3  
    s4  1   1   3   4
;

* Convert reserves to MWh (1 GWh = 1000 MWh; 1 MWh = 6 MWh Block)
Rh_max(j) = Rh_max(j) * 1000;
Rh_min(j) = Rh_min(j) * 1000;
Ri(j)     = Ri(j) * 1000;

* Convert unit costs to block values (6-hour blocks)
b(i)    = b(i) * 6;
ind(i)  = ind(i) * 6;

*-------------------------------------------
* Variables Declaration
*-------------------------------------------
Variables
    X(i,h)     Thermal generation of unit i in block h [MW]
    y(i,h)     Unit commitment (ONOFF) for unit i in block h (binary)
    Z(j,h)     Hydraulic generation of group j in block h [MW]
    ResF(j,h)  Final hydraulic reserve of group j in block h [MWh]
    TOTAL      Total cost [€]
    
* For Model 2
    Precio(h)  Electricity price [€MWh]
    
* For Model 3
    u(i,h)     Binary variable: unit i starts up in block h
    v(i,h)     Binary variable: unit i shuts down in block h
    
* For Model 4 (Stochastic)
    Xs(i,h,s)    Thermal generation for unit i in block h in scenario s [MW]
    Ys(i,h,s)    Commitment status for unit i in block h in scenario s (binary)
    Zs(j,h,s)    Hydraulic generation for group j in block h in scenario s [MW]
    ResFs(j,h,s) Final hydraulic reserve for group j in block h in scenario s [MWh]
    Us(i,h,s)    Binary variable: unit i starts up in block h in scenario s
    Vs(i,h,s)    Binary variable: unit i shuts down in block h in scenario s
    TOTALs       Total cost in Model 4 [€]
;

Binary Variable y, u, v, Ys, Us, Vs;
Positive Variable X, Z, ResF, Precio, Xs, Zs, ResFs;

*-------------------------------------------
* Equations Declaration
*-------------------------------------------
Equations
    SatisfacerDemanda1(h)
    ReservaRodante(h)
    RampaSubida(i,h)
    RampaUno(i,h)
    RampaBajada(i,h)
    LimitePmin(i,h)
    LimitePmax(i,h)
    BalanceHidro(j,h)
    BalanceUno(j,h)
    LimiteTurb(j,h)
    LimiteReservaMin(j,h)
    LimiteReservaMax(j,h)
    Objetivo1
* Model 1 Without Hydraulic Energy (for water cost calculation)
    SatisfacerDemandaSinAgua(h)
* Model 2
    MaxPrecio(i,h)
    Objetivo2
* Model 3
    ArranqueParadaUno(i,h)
    ArranqueParada(i,h)
    Objetivo3
* Model 4 (Stochastic)
    SatisfacerDemandaSS(h,s)
    ReservaRodanteSS(h,s)
    RampaSubidaSS(i,h,s,ss)
    RampaUnoSS(i,h,s)
    RampaBajadaSS(i,h,s,ss)
    LimitePminSS(i,h,s)
    LimitePmaxSS(i,h,s)
    BalanceHidroSS(j,h,s,ss)
    BalanceUnoSS(j,h,s)
    LimiteTurbSS(j,h,s)
    LimiteReservaMinSS(j,h,s)
    LimiteReservaMaxSS(j,h,s)
    ArranqueParadaUnoSS(i,h,s)
    ArranqueParadaSS(i,h,s,ss)
    ObjetivoSS
;

*-------------------------------------------
* Model 1: Base Model
*-------------------------------------------
SatisfacerDemanda1(h).. 
    Sum(i, X(i,h)) + Pn + Pf(h) + Pe(h) + Sum(j, Z(j,h)) =E= d(h);

ReservaRodante(h).. 
    Sum(i, p_max(i)*y(i,h)) * 0.8 =G=  Sum(i, X(i,h));

RampaSubida(i,h)$(ord(h) > 1).. 
    X(i,h) - X(i,h-1) =L= rs(i);

RampaUno(i,h)$(ord(h)=1).. 
    X(i,h) =L= rs(i);

RampaBajada(i,h)$(ord(h) > 1).. 
    X(i,h-1) - X(i,h) =L= rb(i);

LimitePmin(i,h).. 
    X(i,h) =G= p_min(i) * y(i,h);

LimitePmax(i,h).. 
    X(i,h) =L= p_max(i) * y(i,h);

BalanceUno(j,h)$(ord(h)=1).. 
    ResF(j,h) =E= Ri(j) + a(j,h) - (Z(j,h)*6);

BalanceHidro(j,h)$(ord(h)>1).. 
    ResF(j,h) =E= ResF(j,h-1) + a(j,h) - (Z(j,h)*6);

LimiteTurb(j,h).. 
    Z(j,h) + F(j) =L= pot_max_turb(j);

LimiteReservaMin(j,h).. 
    ResF(j,h) =G= Rh_min(j);

LimiteReservaMax(j,h).. 
    ResF(j,h) =L= Rh_max(j);

Objetivo1.. 
    TOTAL =E= Sum((i,h), X(i,h) * b(i));

* Model 1 Without Hydraulic Energy
SatisfacerDemandaSinAgua(h).. 
    Sum(i, X(i,h)) + Pn + Pf(h) + Pe(h) =E= d(h);

*-------------------------------------------
* Model 2: Price-Based Optimization
*-------------------------------------------
MaxPrecio(i,h).. 
    Precio(h) =G= b(i) * y(i,h);

Objetivo2.. 
    TOTAL =E= Sum(h, Precio(h)*d(h));
     
*-------------------------------------------
* Model 3: Incorporating Start-up/Shutdown Costs
*-------------------------------------------
ArranqueParadaUno(i,h)$(ord(h)=1).. 
    u(i,h) - v(i,h) =E= y(i,h);

ArranqueParada(i,h)$(ord(h)>1).. 
    u(i,h) - v(i,h) =E= y(i,h) - y(i,h-1);

Objetivo3.. 
    TOTAL =E= Sum((i,h), ind(i)*y(i,h) + X(i,h)*b(i) + ca(i)*u(i,h) + cp(i)*v(i,h));

*-------------------------------------------
* Model 4: Stochastic Optimization
*-------------------------------------------
SatisfacerDemandaSS(h,s)$(ord(s)=matSt(s,h)).. 
    Sum(i, Xs(i,h,s)) + Pn + Pf(h) + PeSt(s,h) + Sum(j, Zs(j,h,s)) =E= d(h);

ReservaRodanteSS(h,s)$(ord(s)=matSt(s,h)).. 
    Sum(i, p_max(i)*Ys(i,h,s)) * 0.8 =G= Sum(i, Xs(i,h,s));

LimitePminSS(i,h,s)$(ord(s)=matSt(s,h)).. 
    Xs(i,h,s) =G= p_min(i) * Ys(i,h,s);

LimitePmaxSS(i,h,s)$(ord(s)=matSt(s,h)).. 
    Xs(i,h,s) =L= p_max(i) * Ys(i,h,s);

RampaSubidaSS(i,h,s,ss)$(ord(s)=matSt(s,h) and ord(ss)=matSt(s,h-1) and ord(h)>1).. 
    Xs(i,h,s) - Xs(i,h-1,ss) =L= rs(i);

RampaUnoSS(i,h,s)$(ord(s)=matSt(s,h) and ord(h)=1).. 
    Xs(i,h,s) =L= rs(i);

RampaBajadaSS(i,h,s,ss)$(ord(s)=matSt(s,h) and ord(ss)=matSt(s,h-1) and ord(h)>1).. 
    Xs(i,h-1,ss) - Xs(i,h,s) =L= rb(i);

LimiteTurbSS(j,h,s)$(ord(s)=matSt(s,h)).. 
    Zs(j,h,s) + F(j) =L= pot_max_turb(j);

LimiteReservaMinSS(j,h,s)$(ord(s)=matSt(s,h)).. 
    ResFs(j,h,s) =G= Rh_min(j);

LimiteReservaMaxSS(j,h,s)$(ord(s)=matSt(s,h)).. 
    ResFs(j,h,s) =L= Rh_max(j);

BalanceUnoSS(j,h,s)$(ord(s)=matSt(s,h) and ord(h)=1).. 
    ResFs(j,h,s) =E= Ri(j) + a(j,h) - (Zs(j,h,s)*6);

BalanceHidroSS(j,h,s,ss)$(ord(s)=matSt(s,h) and ord(ss)=matSt(s,h-1) and ord(h)>1).. 
    ResFs(j,h,s) =E= ResFs(j,h,s) - (Zs(j,h,s)*6) + a(j,h);

ArranqueParadaUnoSS(i,h,s)$(ord(s)=matSt(s,h) and ord(h)=1).. 
    Us(i,h,s) - Vs(i,h,s) =E= Ys(i,h,s);

ArranqueParadaSS(i,h,s,ss)$(ord(s)=matSt(s,h) and ord(ss)=matSt(s,h-1) and ord(h)>1).. 
    Us(i,h,s) - Vs(i,h,s) =E= Ys(i,h,s) - Ys(i,h-1,ss);

ObjetivoSS.. 
    TOTAL =E= Sum((i,h,s), Prob(s,h)*(ind(i)*Ys(i,h,s) + Xs(i,h,s)*b(i) + ca(i)*Us(i,h,s) + cp(i)*Vs(i,h,s)));

*-------------------------------------------
* Solve and Display Models Sequentially
*-------------------------------------------

* Solve Model 1: Base Model
Model Modelo1 /SatisfacerDemanda1, ReservaRodante, RampaSubida, RampaUno, RampaBajada,
    LimitePmin, LimitePmax, BalanceUno, BalanceHidro, LimiteTurb, LimiteReservaMin, LimiteReservaMax, Objetivo1/;
Solve Modelo1 Minimizing TOTAL Using MIP;
Display X.l, y.l, Z.l, ResF.l, TOTAL.l;

* Solve Model 1 Without Hydraulic Energy
Model Modelo1SinAgua /SatisfacerDemandaSinAgua, ReservaRodante, RampaSubida, RampaUno, RampaBajada,
    LimitePmin, LimitePmax, Objetivo1/;
Solve Modelo1SinAgua Minimizing TOTAL Using MIP;
Display TOTAL.l;

* Solve Model 2: Price-Based Model
Model Modelo2 /SatisfacerDemanda1, ReservaRodante, RampaSubida, RampaUno, RampaBajada, LimitePmin,
    LimitePmax, BalanceUno, BalanceHidro, LimiteTurb, LimiteReservaMin, LimiteReservaMax, MaxPrecio, Objetivo2/;
Solve Modelo2 Minimizing TOTAL Using MIP;
Display X.l, y.l, Z.l, ResF.l, Precio.l, TOTAL.l;

* Solve Model 3: Start-up/Shutdown Cost Model
Model Modelo3 /SatisfacerDemanda1, ReservaRodante, RampaSubida, RampaUno, RampaBajada, LimitePmin,
    LimitePmax, BalanceUno, BalanceHidro, LimiteTurb, LimiteReservaMin, LimiteReservaMax,
    ArranqueParadaUno, ArranqueParada, Objetivo3/;
Solve Modelo3 Minimizing TOTAL Using MIP;
Display X.l, y.l, Z.l, ResF.l, u.l, v.l, TOTAL.l;

* Solve individual scenarios for Model 3 with different wind power values
Loop(s,
    Pe(h) = PeSt(s,h);
    Solve Modelo3 Minimizing TOTAL Using MIP;
    Display TOTAL.l;
);

* Solve Model 3 with the expected value of wind power
Pe(h) = Sum(s, Prob(s,h)*PeSt(s,h));
Solve Modelo3 Minimizing TOTAL Using MIP;
Display TOTAL.l;

* Solve Model 4: Stochastic Optimization
Model Modelo4Est /SatisfacerDemandaSS, ReservaRodanteSS, RampaSubidaSS, RampaUnoSS, RampaBajadaSS, LimitePminSS,
    LimitePmaxSS, BalanceUnoSS, BalanceHidroSS, LimiteTurbSS, LimiteReservaMinSS, LimiteReservaMaxSS,
    ArranqueParadaUnoSS, ArranqueParadaSS, ObjetivoSS/;
Solve Modelo4Est Minimizing TOTAL Using MIP;
Display Xs.l, Ys.l, Zs.l, ResFs.l, Us.l, Vs.l, TOTAL.l;
