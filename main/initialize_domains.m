%**************************************************************************************************************
% FUNCTION initialize_domains.m
% Initial conditions
% - Set the initial biomass spectrum dfish
% - Set the initial effort (if needed)
%**************************************************************************************************************
function initial = initialize_domains(boats)
  
  %---------------------------------
  % Aliases for variables category for readability
  MAIN=boats.param.main;
  CONV=boats.param.conversion;
  ENVI=boats.param.environment;
  ECOL=boats.param.ecology;
  FORC=boats.forcing;
  STRU=boats.structure;
  
  switch boats.param.main.sim_init     
  %--------------------------------------------------------------------------------------------------------
  % Initial dfish is set by analytical primary-production regime
  %--------------------------------------------------------------------------------------------------------
  case 'PP'            
  
     disp('initialize biomass assuming primary production growth regime');

     %---------------------------------
     % Set npp and temperature maps for dfish initial state   
     % Use annual averages
     npp          = squeeze(nanmean(FORC.npp,3));                          % mmolC m-2 s-1
     npp_ed       = squeeze(nanmean(FORC.npp_ed,3));                       % mmolC m-3 d-1
     temp_phyto   = squeeze(nanmean(FORC.temperature,3));                  % degC
     temp_fish    = squeeze(nanmean(FORC.temperature_K,3));                % degK

     %---------------------------------
     % Calculate quantities required for dfish 
     s_over_p   = ( -1.0 + ( 1.0 + 4.0 .* npp_ed ./ (exp(ENVI.kappa_eppley.*temp_phyto) .* ...
                    ENVI.Prod_star) ).^0.5) .* 0.5;
     frac_lg_du = s_over_p ./ (1.0 + s_over_p);                            % large fraction of PP as in Dunne et al. (2005)
     mphyto     = (ENVI.mc_phy_l.^frac_lg_du) .* (ENVI.mc_phy_s.^(1.0 - frac_lg_du));
  
     temp_dep_A = exp( (-ENVI.E_activation_A/ENVI.k_Boltzmann) .* (1./temp_fish - 1./ENVI.temp_ref_A));
     A          = (ECOL.A00/CONV.spery)*temp_dep_A;                        % growth rate of Andersen and Beyer (2013, p. 18)
     mortality0 = (exp(ECOL.zeta1)/3)*A;

     %---------------------------------
     % Calculate initial dfish
     dfish      = (1/ECOL.nfish) * (1 - ECOL.tro_sca) .* repmat(npp,[1 1 ECOL.nfish ECOL.nfmass]) ./ ...
     ( repmat(mortality0,[1 1 ECOL.nfish ECOL.nfmass]) .* repmat(mphyto.^(ECOL.tro_sca),[1 1 ECOL.nfish ECOL.nfmass]) .* ...
     STRU.minf_4d.^(ECOL.h_allo + ECOL.b_allo - 1)) .* STRU.fmass_4d.^(ECOL.tro_sca + ECOL.h_allo - 1);
 
     %---------------------------------
     % Make non existent cells NaNs
     dfish(STRU.mask_notexist_4d) = NaN;
     initial.dfish = dfish;

     %---------------------------------
     % Economic harvesting (set effort to zero in each group)
     if strcmp(MAIN.sim_type,'h')
       initial.effort = zeros(FORC.nlat,FORC.nlon,ECOL.nfish);
     end

  %--------------------------------------------------------------------------------------------------------
  % Initial dfish is set by a restart file  
  %--------------------------------------------------------------------------------------------------------
  otherwise
     %---------------------------------
     % Restart file
     boats_version = boats.param.main.sim_name;
     outdir     = boats.param.path.outdir;
     path_lname_rest = [outdir '/' 'restart_' boats_version '_nh' boats.param.main.sname_rest];

     %---------------------------------
     % Error if specified restart file lname_rest IS NOT IN in the working directory
     if ~exist([path_lname_rest '.mat'],'file')
       error(['Error: restart file ' path_lname_rest '.mat not found']);
     
     %---------------------------------
     % Initial dfish if specified restart file lname_rest IS IN the working directory
     else
       disp(['loading restart file: ' path_lname_rest '.mat']);
       
       %---------------------------------
       % Load restart file
       tmp = load([path_lname_rest '.mat']);
       restart = tmp.restart;
       
       %---------------------------------
       % Use dfish from restart
       initial.dfish  = restart.dfish;
       
       %---------------------------------
       % Economic harvesting
       if strcmp(MAIN.sim_type,'h')
         % Use effort there is a field named effort in the restart file
         if isfield(restart,'effort')
           initial.effort  = restart.effort;
         else
         % Set effort to zero in each group
           initial.effort = zeros(FORC.nlat,FORC.nlon,ECOL.nfish);
         end              
       end
     end
  end
  
%**************************************************************************************************************
% END OF SCRIPT
