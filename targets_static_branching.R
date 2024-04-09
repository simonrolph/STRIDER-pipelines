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
  from = 0,
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
values_effort_citsci <- expand.grid(n_samplers = c(10, 30, 100),
                             n_visits = c(10),
                             n_sample_units = c(1))

#detection
values_detect_citsci <- expand.grid(prob = c(0.3, 0.7))

#reporting
values_report_citsci <- expand.grid(prob = c(0.8, 1))


#SAMPLING TYPE2
values_effort_ami <- expand.grid(n_samplers = c(1, 3, 10),
                                    n_visits = 1,
                                    n_sample_units = c(50,100))

#detection
values_detect_ami <- expand.grid(prob = c(0.3, 0.7,1))

#reporting
values_report_ami <- expand.grid(prob = c(0.8, 1))








# nested tar_map approach
list(
  #STATE
  tar_map(
    values = parameters_state,
    names = name,

    tar_target(
      background,
      write_raster_return_filename(x = terra::rast(matrix(0, 1000, 1000)), filename =  filename_bg),
      format = "file"
    ),
    tar_target("so_background", SimulationObject(background = background)),
    tar_target(
      "so_state_env",
      sim_state_env_gradient(
        so_background,
        filename = filename_se,
        from = from,
        to = to
      )
    ),
    tar_target(
      "so_state_target_suit",
      sim_state_target_suitability_uniform(so_state_env, filename = filename_sts, n_targets = 2)
    ),
    tar_target(
      "so_state_target_realised",
      sim_state_target_realise_threshold(so_state_target_suit, filename = filename_str)
    ),


    #SAMPLING 1
    #effort
    tar_map(
      values = values_effort_citsci,
      tar_target(
        "so_effort_citsci",
        sim_effort_uniform(
          so_state_target_realised,
          n_samplers = n_samplers,
          n_visits = n_visits,
          n_sample_units = n_sample_units,
          replace = T
        )
      ),

      #detect
      tar_map(
        values = values_detect_citsci,
        tar_target("so_detect_citsci", sim_detect_equal(so_effort_citsci, prob = prob)),

        #reporting
        tar_map(
          values = values_report_citsci,
          tar_target("so_report_citsci", sim_report_equal(so_detect_citsci, prob = prob))#,

          #save output
          # tar_target("so_output_citsci", saveRDS(so_report_citsci, file = paste0(
          #   "data/", names(so_report), ".rds"
          # )), format = "file")
        )
      )
    ),


    #SAMPLING 2
    tar_map(
      values = values_effort_ami,
      tar_target(
        "so_effort_ami",
        sim_effort_uniform(
          so_state_target_realised,
          n_samplers = n_samplers,
          n_visits = n_visits,
          n_sample_units = n_sample_units,
          replace = T
        )
      ),

      #detect
      tar_map(
        values = values_detect_ami,
        tar_target("so_detect_ami", sim_detect_equal(so_effort_ami, prob = prob)),

        #reporting
        tar_map(
          values = values_report_ami,
          tar_target("so_report_ami", sim_report_equal(so_detect_ami, prob = prob))#,

          #save output
          # tar_target("so_output_ami", saveRDS(so_report_ami, file = paste0(
          #   "data/", names(so_report), ".rds"
          # )), format = "file")
        )
      )
    )
  )
)
