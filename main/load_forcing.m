%**************************************************************************************************************
% FUNCTION load_forcing.m
% Load forcings preprocessed by "preprocess.m" for the simulation :
% Ecology.mat
% Economy.mat
%**************************************************************************************************************
function forcing = load_forcing(boats,forcing_ecology,forcing_economy)

%---------------------------------
% Forcing ecology:
if exist(forcing_ecology,'file')
    load(forcing_ecology);
else
    disp('Hum, double-check the path for ecology forcing:')
    disp(forcing_ecology)
end
forcing.mask=repmat(Ecology.mask,[1 1 size(Ecology.npp,3)]);
forcing.nlat=size(forcing.mask,1);
forcing.nlon=size(forcing.mask,2);
forcing.npp=Ecology.npp;
forcing.npp(find(forcing.mask==1))=NaN;
forcing.npp_ed=Ecology.npp_ed;
forcing.npp_ed(find(forcing.mask==1))=NaN;
forcing.temperature=Ecology.temperature;
forcing.temperature_K=Ecology.temperature+boats.param.conversion.C_2_K;
forcing.surf=Ecology.surface;

%--------------------------------- 
% Forcing economy
if strcmp(boats.param.main.sim_type,'h')
    if exist(forcing_economy,'file')
        load(forcing_economy);
    else
        disp('Hum, double-check the path for economy forcing:')
        disp(forcing_economy)
    end
    load(forcing_economy)
    forcing.price=Economy.price;
    forcing.cost=Economy.cost;
    forcing.catchability=Economy.catchability;
end
 
%**************************************************************************************************************
% END FUNCTION

