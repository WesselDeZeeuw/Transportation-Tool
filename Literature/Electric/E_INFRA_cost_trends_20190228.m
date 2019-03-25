% Script E_INFRA_cost_trends_10190211.m
% From: E.J. (Edwin) Wiggelinkhuizen, ECN part of TNO, Wind Energy
% Date: 2019-02-27
% ----------------------------------------------------------------------
% Costs include investments and installation costs of:
% - WF collection system
% - Offshore and onshore platforms
% - Offshore cable system (both HVAC and HVDC options)
%
% The costs are based on linear fits of one or two input parameters, based
% on data of various public an properiatary sources (EeFarm database)
% The costs are in kEuro(2012) and consider the copper prices of 2012
%
% The cable costs include installation, which are modelled as a fixed
% amount per km (so independent of the cable type.
% For HVDC cables it is assumed that a cable pair can be installed in one go,
% so installation costs are comparable to athat ofa single HVAC cable
% ----------------------------------------------------------------------
% Notes on energy losses:
% In this script transport losses and outage losses are not calculated
%
% Transport losses
% For the wind farm collection system these losses are typically in the order of 1% of the annual energy production
% note: the losses of the wind turbine transformer are usually already included in the wind turbine power curve 
% The losses in the transmission system can be split into a fixed and per-km part:
% For HVAC these losses are typically in the order of 1% + 3%/100km
% For HVDC these losses are typically in the order of 2% + 2%/100km
%
% The outage losses very much depend on the maintenance strategy (preventive maintenance
% preferrably during low-wind periods, corrective maintenance requires fast response times and sufficient spares, personnel and equipment like ships),
% and on the level of redundancy (e.g. parallel cables) and technology.^%
% therefor no generic/typical figure canbe given here.

%% 
clear
clc
% %%% USER-INPUTS %%%
InpFilenameMAT = 'E_INFRA_trends_20190228';
load(InpFilenameMAT)        % struct that contains fitted cost data of components

E_INFRA_INPUTS  = struct(); % struct to store the user-inputs
E_INFRA_OUTPUTS = struct(); % struct to store the resulting costs and 

%% WF collection grid
% Please note that a WF developer usually optimizes the layout within the
% wind farm and also uses several different cable diameters, which increases with the power level
% Here only the costs for a given cable section are given per km.
% A straightforward way to make a rough cost estimate costs of a WF collection grid is to apply:
% a rectangular wind farm layout with WT interspacing of at least 6x rotor diameter
% a central collection platform
% a limited number of cable types (2 or 3 different core diameters)
% calculate the lengths and the the costs of all cable sections
%
% %%% USER-INPUTS %%%
E_INFRA_INPUTS.WF_string_cables.PMW      =  50;
E_INFRA_INPUTS.WF_string_cables.kVeffpp  =  66; % nominal voltage [kV]
E_INFRA_INPUTS.WF_string_cables.PF       =   0.95; %estimate
E_INFRA_INPUTS.WF_string_cables.areas    = [95 150 240 400 630 800]; % standard conductor diameters

WF_string_cables_SMVA = E_INFRA_INPUTS.WF_string_cables.PMW/E_INFRA_INPUTS.WF_string_cables.PF;

WF_string_cables_area_min = [];
WF_string_cables_NumParallel      = 0;
WF_string_cables_MaxNumParallel   = 3;
% select required cable core diameter and # parallel cables
while (WF_string_cables_NumParallel < WF_string_cables_MaxNumParallel) && (isempty(WF_string_cables_area_min) || (WF_string_cables_area_min > max(E_INFRA_INPUTS.WF_string_cables.areas))),
       WF_string_cables_NumParallel = WF_string_cables_NumParallel + 1;

       WF_string_cables_area_min = polyval(E_INFRA.WF_string_cables_model.SMVA_to_area,WF_string_cables_SMVA/E_INFRA_INPUTS.WF_string_cables.kVeffpp/WF_string_cables_NumParallel);
       area_idx = find(WF_string_cables_area_min  <= E_INFRA_INPUTS.WF_string_cables.areas,1,'first');
       E_INFRA_OUTPUTS.WF_string_cables_area       = E_INFRA_INPUTS.WF_string_cables.areas(area_idx);
end
E_INFRA_OUTPUTS.WF_string_cables_NumParallel       = WF_string_cables_NumParallel;

E_INFRA_OUTPUTS.WF_string_cables_Invcost_km  = round(WF_string_cables_NumParallel *...
 polyval(E_INFRA.WF_string_cables_model.Invcost_km_area,    E_INFRA_OUTPUTS.WF_string_cables_area  ) +...
 polyval(E_INFRA.WF_string_cables_model.Invcost_km_kVeffpp ,E_INFRA_INPUTS.WF_string_cables.kVeffpp));

%% HVAC transmission grid
% %%% USER-INPUTS %%%
E_INFRA_INPUTS.HVAC_cables.length_km = 150;
E_INFRA_INPUTS.HVAC_cables.PMW       = 1000; % total transported active power [MW]
E_INFRA_INPUTS.HVAC_cables.kVeffpp   = 220; % nominal voltage [kV]
E_INFRA_INPUTS.HVAC_cables.areas     = [95 150 240 400 630 800 1000 1200]; % Common cable core diameters

% Please take note of HVAC cable limits (see references):
%
% Evaluation of Electrical Transmission Concepts for Large Offshore Wind Farms
% T. Ackermann, N. Barberis Negra, J. Todorovic, L. Lazaridis
% Proc. Copenhagen Offshore Wind, 2005
% https://www.researchgate.net/publication/228887928_Evaluation_of_electrical_transmission_concepts_for_large_offshore_wind_farms
%
% CIGRE Working Group B1.40. O?shore generation cable Connection. Cigre report 610 , February 2015, ISBN : 978-2-85873-311-8

% initial estimate of cable reactive power production
E_INFRA_OUTPUTS.HVAC_cables_C_km = ...
 polyval(E_INFRA.HVAC_cables_model.Ckm_area, mean(E_INFRA_INPUTS.HVAC_cables.areas) ) +...
 polyval(E_INFRA.HVAC_cables_model.Ckm_kVeffpp   ,E_INFRA_INPUTS.HVAC_cables.kVeffpp);
HVAC_cables_MVAr = E_INFRA_INPUTS.HVAC_cables.length_km * 2*pi*50*E_INFRA_OUTPUTS.HVAC_cables_C_km*(E_INFRA_INPUTS.HVAC_cables.kVeffpp)^2;

HVAC_cables_area_min       = [];
HVAC_cables_NumParallel    = 0;
HVAC_cables_MaxNumParallel = 4;
% select required cable core diameter and # parallel cables
while (HVAC_cables_NumParallel < HVAC_cables_MaxNumParallel) && (isempty(HVAC_cables_area_min) || (HVAC_cables_area_min > max(E_INFRA_INPUTS.HVAC_cables.areas))),
       HVAC_cables_NumParallel = HVAC_cables_NumParallel + 1;

       %Assume 100% reactive power compensation (50% offshore and 50% onshore) => calculate cable rating 
       HVAC_cables_SMVA = sqrt((E_INFRA_INPUTS.HVAC_cables.PMW/HVAC_cables_NumParallel)^2 + (0.5*HVAC_cables_MVAr)^2);
       
       HVAC_cables_area_min = polyval(E_INFRA.HVAC_cables_model.SMVA_to_area,HVAC_cables_SMVA/E_INFRA_INPUTS.HVAC_cables.kVeffpp);
       area_idx = find(HVAC_cables_area_min  <= E_INFRA_INPUTS.HVAC_cables.areas,1,'first');
end
if isempty(area_idx),
    error('Number of max parallel HVAC cables reached')
end
E_INFRA_OUTPUTS.HVAC_cables_area        = E_INFRA_INPUTS.HVAC_cables.areas(area_idx);
E_INFRA_OUTPUTS.HVAC_cables_NumParallel = HVAC_cables_NumParallel;

E_INFRA_OUTPUTS.HVAC_cables_Invcost_km  = round(HVAC_cables_NumParallel *...
 polyval(E_INFRA.HVAC_cables_model.Invcost_km_area,    E_INFRA_OUTPUTS.HVAC_cables_area  ) +...
 polyval(E_INFRA.HVAC_cables_model.Invcost_km_kVeffpp ,E_INFRA_INPUTS.HVAC_cables.kVeffpp));

% Recalculate of cable reactive power production and apparent power
E_INFRA_OUTPUTS.HVAC_cables_C_km = ...
 polyval(E_INFRA.HVAC_cables_model.Ckm_area,    E_INFRA_OUTPUTS.HVAC_cables_area  ) +...
 polyval(E_INFRA.HVAC_cables_model.Ckm_kVeffpp ,E_INFRA_INPUTS.HVAC_cables.kVeffpp);
HVAC_cables_MVAr = E_INFRA_INPUTS.HVAC_cables.length_km * 2*pi*50*E_INFRA_OUTPUTS.HVAC_cables_C_km*(E_INFRA_INPUTS.HVAC_cables.kVeffpp)^2;
% Assume 100% reactive power compensation (50% offshore and 50% onshore) => calculate cable rating 
HVAC_cables_SMVA = sqrt((E_INFRA_INPUTS.HVAC_cables.PMW/HVAC_cables_NumParallel)^2 + (0.5*HVAC_cables_MVAr)^2);

if (0.5 * HVAC_cables_MVAr) >= E_INFRA_INPUTS.HVAC_cables.PMW/HVAC_cables_NumParallel
    warning('HVAC cable length approaches critical tranmission distance');
end

% Costs of inductors, with a pair of inductors for each cable
% The inductor sizing is based on 100% reactive power compensation, equally divided: 50% offshore and 50% onshore
E_INFRA_OUTPUTS.HVAC_inductors_Invcost = HVAC_cables_NumParallel * round(polyval(E_INFRA.HVAC_inductors_model.Invcost_SMVA,HVAC_cables_MVAr),1);

% Transformers
% Each cable is connected to one offshore and one onshore transformer
% Transformer rating estimated to be 125% of the cable rated apparent power
% %%% USER-INPUTS %%%
E_INFRA_INPUTS.HVAC_trafo_SMVA_per_MW  = 1.25;

E_INFRA_OUTPUTS.HVAC_trafo_NumParallel = HVAC_cables_NumParallel;
E_INFRA_OUTPUTS.HVAC_trafo_SMVA        = E_INFRA_INPUTS.HVAC_trafo_SMVA_per_MW * HVAC_cables_SMVA;
E_INFRA_OUTPUTS.HVAC_trafo_Invcost     = 2 * HVAC_cables_NumParallel * polyval(E_INFRA.HVAC_trafo_model.Invcost_SMVA,HVAC_cables_SMVA*E_INFRA_INPUTS.HVAC_trafo_SMVA_per_MW);

% Platforms
E_INFRA_OUTPUTS.HVAC_OffshorePlatform_Invcost = polyval(E_INFRA.HVAC_platf_model.Invcost_SMVA,E_INFRA_OUTPUTS.HVAC_trafo_NumParallel*E_INFRA_OUTPUTS.HVAC_trafo_SMVA);

E_INFRA_OUTPUTS.HVAC_OnshoreStation_Invcost   = polyval(E_INFRA.HVAC_OSS_model.Invcost_SMVA,  E_INFRA_OUTPUTS.HVAC_trafo_NumParallel*E_INFRA_OUTPUTS.HVAC_trafo_SMVA);

% Total costs HVAC transmission system
E_INFRA_OUTPUTS.HVAC_TOTAL_Invcost =  E_INFRA_INPUTS.HVAC_cables.length_km   * E_INFRA_OUTPUTS.HVAC_cables_Invcost_km +...
                                      E_INFRA_OUTPUTS.HVAC_inductors_Invcost + E_INFRA_OUTPUTS.HVAC_trafo_Invcost     + ...
                                      E_INFRA_OUTPUTS.HVAC_OffshorePlatform_Invcost + E_INFRA_OUTPUTS.HVAC_OnshoreStation_Invcost;
%% HVDC transmission grid
% %%% USER-INPUTS %%% -> HVAC inputs are now being copied to the HVDC case
E_INFRA_INPUTS.HVDC_cables.length_km = E_INFRA_INPUTS.HVAC_cables.length_km;
E_INFRA_INPUTS.HVDC_cables.PMW       = E_INFRA_INPUTS.HVAC_cables.PMW; % total transported active power [MW]
E_INFRA_INPUTS.HVDC_cables.kVdc      = 320; % nominal voltage [kV]
E_INFRA_INPUTS.HVDC_cables.areas     = [95 150 240 400 630 800 1000 1200]; % common cable core diameters

HVDC_cables_area_min       = [];
HVDC_cables_NumParallel    = 0;
HVDC_cables_MaxNumParallel = 4;
% select required cable core diameter and # parallel cables
while (HVDC_cables_NumParallel < HVDC_cables_MaxNumParallel) && (isempty(HVDC_cables_area_min) || (HVDC_cables_area_min > max(E_INFRA_INPUTS.HVDC_cables.areas))),
       HVDC_cables_NumParallel = HVDC_cables_NumParallel + 2; % Assume bi-polar cable (or similar) configuration

       HVDC_cables_area_min = polyval(E_INFRA.HVDC_cables_model.PMW_to_area,E_INFRA_INPUTS.HVDC_cables.PMW/E_INFRA_INPUTS.HVDC_cables.kVdc);
       area_idx = find(HVDC_cables_area_min  <= E_INFRA_INPUTS.HVDC_cables.areas,1,'first');
end
if isempty(area_idx),
    error('Number of max parallel HVDC cables reached')
end

E_INFRA_OUTPUTS.HVDC_cables_area        = E_INFRA_INPUTS.HVDC_cables.areas(area_idx);
E_INFRA_OUTPUTS.HVDC_cables_NumParallel = HVDC_cables_NumParallel;

E_INFRA_OUTPUTS.HVDC_cables_Invcost_km  = round(HVDC_cables_NumParallel *...
 polyval(E_INFRA.HVDC_cables_model.Invcost_km_area, E_INFRA_OUTPUTS.HVDC_cables_area) +...
 polyval(E_INFRA.HVDC_cables_model.Invcost_km_kVdc ,E_INFRA_INPUTS.HVDC_cables.kVdc ));

% HVDC converters: Costs of a pair of identical converters, includes transformers
E_INFRA_OUTPUTS.HVDC_rectPWM_Invcost = 2* ...
        (polyval(E_INFRA.HVDC_rectPWM_model.Invcost_SMVA,E_INFRA_INPUTS.HVDC_cables.PMW )+...
         polyval(E_INFRA.HVDC_rectPWM_model.Invcost_kVdc,E_INFRA_INPUTS.HVDC_cables.kVdc));

% Platforms
E_INFRA_OUTPUTS.HVDC_OffshorePlatform_Invcost = polyval(E_INFRA.HVDC_platf_model.Invcost_MW,E_INFRA_INPUTS.HVDC_cables.PMW);

E_INFRA_OUTPUTS.HVDC_OnshoreStation_Invcost   = polyval(E_INFRA.HVAC_OSS_model.Invcost_SMVA,E_INFRA_INPUTS.HVDC_cables.PMW);

% Total costs HVDC transmission system
E_INFRA_OUTPUTS.HVDC_TOTAL_Invcost =  E_INFRA_INPUTS.HVDC_cables.length_km   * E_INFRA_OUTPUTS.HVDC_cables_Invcost_km +...
                                      E_INFRA_OUTPUTS.HVDC_rectPWM_Invcost + ...
                                      E_INFRA_OUTPUTS.HVDC_OffshorePlatform_Invcost + E_INFRA_OUTPUTS.HVDC_OnshoreStation_Invcost;

% Print results
% %%% USER-INPUTS %%%
OutFilenameTXT = '';
OutFilenameMAT = InpFilenameMAT;
if isstring(OutFilenameTXT),
    fid = fopen(OutFilenameTXT,'s');
    if fid <= 1, fid = 1; end
else
    fid = 1;
end
fprintf(fid,'Resulting costs\n');
fprintf(fid,'WF collection grid costs: %0.2f [MEuro/km]\n',E_INFRA_OUTPUTS.WF_string_cables_Invcost_km/1e3);
fprintf(fid,'HVAC tranmission option:  %0.1f [MEuro]\n',E_INFRA_OUTPUTS.HVAC_TOTAL_Invcost/1e3);
fprintf(fid,'HVDC tranmission option:  %0.1f [MEuro]\n',E_INFRA_OUTPUTS.HVDC_TOTAL_Invcost/1e3);

% Save all data to file "E_INFRA_trends.mat"
save(OutFilenameMAT,'E_INFRA*');

%cleanup
clear *_idx HVAC_cables* HVDC_cables* WF_string_cables* Outfilename fid

%% Optional: plot cable cost data versus nominal voltage and conductor size

% %%% USER-INPUTS %%%
PlotFlag = 0; %1;

if PlotFlag
    figPos  = [360   279];       % user-entry: X-Y position
    figSize = [560   420];       % user-entry: X-Y size
    winSize = figSize + [16 92]; % Include borders of windows
    figPos1 = [figPos(1)             figPos(2)              figSize];
    figPos2 = [figPos(1)+winSize(1)  figPos(2)              figSize];
    figPos3 = [figPos(1)             figPos(2)-winSize(2)   figSize];
    figPos4 = [figPos(1)+winSize(1)  figPos(2)-winSize(2)   figSize];
    
    figure(1); set(gcf,'position',figPos1)
%     plotdata  = round([E_INFRA.WF_string_cables.area;E_INFRA.WF_string_cables.kVeffpp;E_INFRA.WF_string_cables.Invcost_km]);
    plotdata2 = round([E_INFRA.WF_string_cables.area;E_INFRA.WF_string_cables.kVeffpp;...
        polyval(E_INFRA.WF_string_cables_model.Invcost_km_area,    [E_INFRA.WF_string_cables.area]   )+...
        polyval(E_INFRA.WF_string_cables_model.Invcost_km_kVeffpp ,[E_INFRA.WF_string_cables.kVeffpp])]);
%     hold off;  plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)'  ,'r.')
%     hold on;   plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)*0','bx')
    plot3(plotdata2(1,:)',plotdata2(2,:)',plotdata2(3,:)' ,'go')
%     title(sprintf('EeFarm string cable costs incl. installation\n (red: actual costs, green: parameterized costs)'))
    title(sprintf('EeFarm string cable costs incl. installation\n (green: parameterized costs)'))
    xlabel('cable conductor size [mm^2]')
    ylabel('cable voltage rating [kV]')
    zlabel('cable investments - incl. laying [kEuro/km]')
    grid on
    
    figure(11); set(gcf,'position',figPos1)
%     plotdata  = round([E_INFRA.WF_string_cables.SMVA;E_INFRA.WF_string_cables.kVeffpp;E_INFRA.WF_string_cables.area]);
    plotdata2 = round([E_INFRA.WF_string_cables.SMVA;E_INFRA.WF_string_cables.kVeffpp;...
        polyval(E_INFRA.WF_string_cables_model.SMVA_to_area,[E_INFRA.WF_string_cables.SMVA]./[E_INFRA.WF_string_cables.kVeffpp])]);
%     hold off;  plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)'  ,'r.')
%     hold on;   plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)*0','bx')
    plot3(plotdata2(1,:)',plotdata2(2,:)',plotdata2(3,:)' ,'go')
%     title(sprintf('EeFarm string cable area\n (red: actual , green: parameterized)'))
    title(sprintf('EeFarm string cable area\n (green: parameterized)'))
    xlabel('cable power rating [SMVA]')
    ylabel('cable voltage rating [kV]')
    zlabel('cable conductor size [mm2]')
    grid on
    
    figure(2); set(gcf,'position',figPos2)
%     plotdata  = round([E_INFRA.HVAC_cables.area;E_INFRA.HVAC_cables.kVeffpp;E_INFRA.HVAC_cables.Invcost_km]);
    plotdata2 = round([E_INFRA.HVAC_cables.area;E_INFRA.HVAC_cables.kVeffpp;...
        polyval(E_INFRA.HVAC_cables_model.Invcost_km_area,    [E_INFRA.HVAC_cables.area]   ) +...
        polyval(E_INFRA.HVAC_cables_model.Invcost_km_kVeffpp ,[E_INFRA.HVAC_cables.kVeffpp])]);
%     hold off;  plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)'  ,'r.')
%     hold on;   plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)*0','bx')
    plot3(plotdata2(1,:)',plotdata2(2,:)',plotdata2(3,:)' ,'go')
    title(sprintf('EeFarm HVAC transmission cable costs incl. installation\n (red: actual costs, green: parameterized costs)'))
    xlabel('cable conductor size [mm^2]')
    ylabel('cable voltage rating [kV]')
    zlabel('cable investments - incl. laying [kEuro]')
    grid on
    
    figure(3); set(gcf,'position',figPos3)
%     plotdata  = round([E_INFRA.HVDC_cables.area;E_INFRA.HVDC_cables.kVdc;E_INFRA.HVDC_cables.Invcost_km]);
    plotdata2 = round([E_INFRA.HVDC_cables.area;E_INFRA.HVDC_cables.kVdc;...
        polyval(E_INFRA.HVDC_cables_model.Invcost_km_area, [E_INFRA.HVDC_cables.area])  +...
        polyval(E_INFRA.HVDC_cables_model.Invcost_km_kVdc ,[E_INFRA.HVDC_cables.kVdc])]);
%     hold off;  plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)'  ,'r.')
%     hold on;   plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)*0','bx')
    plot3(plotdata2(1,:)',plotdata2(2,:)',plotdata2(3,:)' ,'go')
    title(sprintf('EeFarm HVDC transmission cable costs incl. installation\n (red: actual costs, green: parameterized costs)'))
    xlabel('cable conductor size [mm^2]')
    ylabel('cable voltage rating [kV]')
    zlabel('cable investments - excl. laying [kEuro]')
    grid on
    
    figure(4); set(gcf,'position',figPos4)
%     plotdata  = round([E_INFRA.HVDC_rectPWM.SMVA;      E_INFRA.HVDC_rectPWM.kVdc;      E_INFRA.HVDC_rectPWM.kEuroInvest]);
%     plotdata2 = round([E_INFRA.HVDC_rectPWM_ISLES.SMVA;E_INFRA.HVDC_rectPWM_ISLES.kVdc;E_INFRA.HVDC_rectPWM_ISLES.kEuroInvest]);
    plotdata3 = round([E_INFRA.HVDC_rectPWM.SMVA;E_INFRA.HVDC_rectPWM.kVdc;...
        polyval(E_INFRA.HVDC_rectPWM_model.Invcost_SMVA,[E_INFRA.HVDC_rectPWM.SMVA])  +...
        polyval(E_INFRA.HVDC_rectPWM_model.Invcost_kVdc,[E_INFRA.HVDC_rectPWM.kVdc])]);
    plotdata4 = round([E_INFRA.HVDC_rectPWM_ISLES.SMVA;E_INFRA.HVDC_rectPWM_ISLES.kVdc;...
        polyval(E_INFRA.HVDC_rectPWM_model.Invcost_SMVA,[E_INFRA.HVDC_rectPWM_ISLES.SMVA])  +...
        polyval(E_INFRA.HVDC_rectPWM_model.Invcost_kVdc,[E_INFRA.HVDC_rectPWM_ISLES.kVdc])]);
%     hold off;  plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)'   ,'r.')
%     hold on;   plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)*0' ,'bx')
%     plot3(plotdata2(1,:)',plotdata2(2,:)',plotdata2(3,:)'  ,'r+')
%     plot3(plotdata2(1,:)',plotdata2(2,:)',plotdata2(3,:)*0','b+')
    plot3(plotdata3(1,:)',plotdata3(2,:)',plotdata3(3,:)'  ,'go')
    plot3(plotdata4(1,:)',plotdata4(2,:)',plotdata4(3,:)'  ,'gsq')
    title(sprintf('EeFarm HVDC converter costs \n (red: actual costs, green: parameterized costs)'))
    xlabel('HVDC converter power rating [MVA]')
    ylabel('HVDC converter nominal voltage [kV]')
    zlabel('HVDC converter investment costs [kEuro]')
    grid on
    
    figure(5); set(gcf,'position',figPos4)
%     plotdata  = round([E_INFRA.HVAC_platf.SMVA; E_INFRA.HVAC_platf.Weight_to_support; E_INFRA.HVAC_platf.Invcost]);
%     plotdata2 = round([E_INFRA.HVDC_platf.MW;   E_INFRA.HVDC_platf.Weight_to_support; E_INFRA.HVDC_platf.Invcost]);
    plotdata3 = round([E_INFRA.HVAC_platf.SMVA; E_INFRA.HVAC_platf.Weight_to_support;...
        polyval(E_INFRA.HVAC_platf_model.Invcost_SMVA,[E_INFRA.HVAC_platf.SMVA])+...
        polyval(E_INFRA.HVAC_platf_model.Invcost_Mass,[E_INFRA.HVAC_platf.Weight_to_support])]);
    plotdata4 = round([E_INFRA.HVDC_platf.MW;   E_INFRA.HVDC_platf.Weight_to_support;...
        polyval(E_INFRA.HVDC_platf_model.Invcost_MW  ,[E_INFRA.HVDC_platf.MW])+...
        polyval(E_INFRA.HVDC_platf_model.Invcost_Mass,[E_INFRA.HVDC_platf.Weight_to_support])]);
%     hold off;  plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)'   ,'r.')
%     hold on;   plot3(plotdata(1,:)' ,plotdata(2,:)' ,plotdata(3,:)*0' ,'bx')
%     plot3(plotdata2(1,:)',plotdata2(2,:)',plotdata2(3,:)'  ,'m+')
%     plot3(plotdata2(1,:)',plotdata2(2,:)',plotdata2(3,:)*0','b+')
    plot3(plotdata3(1,:)',plotdata3(2,:)',plotdata3(3,:)'  ,'go')
    plot3(plotdata4(1,:)',plotdata4(2,:)',plotdata4(3,:)'  ,'gsq')
    title(sprintf('EeFarm platform costs \n (red: HVAC, magenta: HVDC, green: parameterized costs)'))
    xlabel('Platform power rating [MVA]')
    ylabel('Platform weight to support [tonnes]')
    zlabel('Platform investment costs [kEuro]')
    grid on

end % if PlotFlag == 1
% cleanup
clear figPos* *Size Plot* plot*