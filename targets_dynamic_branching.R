# This is a targets workflow file which simulates a set of datasets given your parameters

# this is an attempt to do dynamic branching, but it does not work.

#load required libraries
library(targets)
library(tarchetypes)
library(terra)
library(STRIDER) #see https://github.com/BiologicalRecordsCentre/STRIDER for more details

#define the parameters for each stage of the workflow
#STATE
parameters_state <- expand.grid(
  filename_bg = "rasters/background.tif",
  filename_se = "rasters/state_env.tif",
  from = 1,
  to = 10,
  filename_sts = "rasters/state_target_suit.tif",
  filename_str = "rasters/state_target_realised.tif",
  stringsAsFactors = F
)

#give a human readable name, unique for each environment
parameters_state$name = "default_env"

#give each environment a unique name using a hash
if (is.null(parameters_state$name)){
  parameters_state$name <-
    apply(parameters_state, FUN = digest::digest, MARGIN = 1)
}

#SAMPLING
expand.grid.df <- function(...) Reduce(function(...) merge(..., by=NULL), list(...))

#Citizen science
parameters_effort_citsci <- expand.grid(n_samplers = c(10, 30, 100),
                             n_visits = c(10),
                             n_sample_units = c(1)) #effort
parameters_detect_citsci <- expand.grid(prob_detect = c(0.3, 0.7)) #detection
parameters_report_citsci <- expand.grid(prob_report = c(0.8, 1)) #reporting
#parameters_all_citsci_pre <- expand.grid.df(parameters_effort_citsci,parameters_detect_citsci,parameters_report_citsci)

#Automated trap
parameters_effort_ami <- expand.grid(n_samplers = c(1, 3, 10),
                                    n_visits = 1,
                                    n_sample_units = c(50,100))#effort
parameters_detect_ami <- expand.grid(prob = c(0.3, 0.7,1)) #detection
parameters_report_ami <- expand.grid(prob = c(0.8, 1)) #reporting
#parameters_all_ami_pre <- expand.grid.df(parameters_effort_ami,parameters_detect_ami,parameters_report_ami)



# nested tar_map approach
list(
  #tar_target(parameters_all_citsci,parameters_all_citsci_pre), #not used
  #tar_target(parameters_all_ami,parameters_all_ami_pre), #not used

  #STATE
  tar_map(
    values = parameters_state,
    names = name,

    #background
    tar_target(
      background,
      write_raster_return_filename(x = terra::rast(matrix(0, 1000, 1000)), filename =  filename_bg),
      format = "file"
    ),
    tar_target("so_background", SimulationObject(background = background)),
    #state-environment
    tar_target(
      "so_state_env",
      sim_state_env(
        so_background,
        fun="gradient",
        filename = filename_se,
        from = from,
        to = to
      )
    ),
    #state-target-suitability
    tar_target(
      "so_state_target_suit",
      sim_state_target_suitability(so_state_env,fun="uniform",filename = filename_sts, n_targets = 2)
    ),
    #state-target-realised
    tar_target(
      "so_state_target_realised",
      sim_state_target_realise(so_state_target_suit,fun="threshold", filename = filename_str)
    ),

    #sampling 1
    #EFFORT
    tar_group_by(grouped1,parameters_effort_citsci,n_samplers, n_visits,n_sample_units),
    tar_target(
      so_effort_citsci,
      sim_effort_uniform(
        so_state_target_realised,
        n_samplers = grouped1$n_samplers,
        n_visits = grouped1$n_visits,
        n_sample_units = grouped1$n_sample_units,
        replace = T
    ),
    pattern = map(grouped1)),

    #DETECTION
    tar_group_by(grouped2,parameters_detect_citsci,prob_detect),
    tar_target(
      so_detect_citsci,
      sim_detect_equal(so_effort_citsci[[1]], prob = grouped2$prob_detect),
      pattern = map(grouped2)),

    #REPORTING
    tar_group_by(grouped3,parameters_report_citsci,prob_report),
    tar_target(
      so_report_citsci,
      sim_report_equal(so_detect_citsci[[1]], prob = grouped3$prob_report),
      pattern = map(grouped3)
    )

    #sampling 2

  )
)
