# This is a targets workflow file which simulates a set of datasets given your parameters

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
parameters_state$name = "default"

#give each environment a unique name using a hash
if (is.null(parameters_state$name)){
  parameters_state$name <-
    apply(parameters_state, FUN = digest::digest, MARGIN = 1)
}


#SAMPLING TYPE1
#effort
values_effort_citsci <- expand.grid(
  funct = "uniform",
  n_samplers = c(10, 30, 100),
  n_visits = c(10),
  n_sample_units = c(1),
  stringsAsFactors = F)

#detection
values_detect_citsci <- expand.grid(
  funct="equal",
  prob = c(0.3, 0.7),
  stringsAsFactors = F
  )

#reporting
values_report_citsci <- expand.grid(
  funct="equal",
  prob = c(0.8, 1),
  stringsAsFactors = F
  )





### PIPELINE










# nested tar_map approach
list(
  # background
  tar_target(
    background,
    write_raster_return_filename(x = terra::rast(matrix(0, 1000, 1000)), filename =  parameters_state$filename_bg),
    format = "file"
  ),
  tar_target("so_background", SimulationObject(background = background)),

  #STATE
  tar_map(
    values = parameters_state,
    names = name,

    tar_target(
      so_state_env,
      sim_state_env(
        so_background,
        fun="gradient",
        filename = filename_se,
        from = from,
        to = to
      )
    ),
    tar_target(
      so_state_target_suit,
      sim_state_target_suitability(
        so_state_env,
        fun="uniform",
        filename = filename_sts,
        n_targets = 2)
    ),
    tar_target(
      so_state_target_realised,
      sim_state_target_realise(
        so_state_target_suit,
        fun="threshold",
        filename = filename_str,
        threshold = 0.5)
    ),


    #SAMPLING 1
    #effort
    tar_map(
      values = values_effort_citsci,
      tar_target(
        so_effort_citsci,
        sim_effort(
          so_state_target_realised,
          fun=funct,
          n_samplers = n_samplers,
          n_visits = n_visits,
          n_sample_units = n_sample_units,
          replace = T
        )
      ),

      #detect
      tar_map(
        values = values_detect_citsci,
        tar_target(
          so_detect_citsci,
          sim_detect(
            so_effort_citsci,
            fun=funct,
            prob = prob)
          ),

        #reporting
        tar_map(
          values = values_report_citsci,
          tar_target(
            so_report_citsci,
            sim_report(
              so_detect_citsci,
              fun=funct,
              prob = prob)
            ),

          #save output
          tar_target(
            so_output_citsci,
            saveRDS(
              so_report_citsci,
              file = paste0("data/output_", so_report_citsci@hash, ".rds")
              ),
            format = "file"
          )
        )
      )
    )
  )
)
