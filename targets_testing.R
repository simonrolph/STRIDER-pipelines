library(targets)
library(tarchetypes)
#setup


#here a user sets out what parameters they want to generate data using
#each parameter as a separate dataframe
par1 <- data.frame(par1_col = c(1, 2))
par2 <- data.frame(par2_col= c(10, 20))
par3 <- data.frame(par3_col = c(1, 2, 3))

#combined into one expanded grid dataframe
all_pars <- expand.grid(par1$par1,par2$par2,par3$par3)
names(all_pars) <- c("par1_col","par2_col","par3_col")

#the data generation processes
data_generation_process1 <- function(obj,par){
  obj*par
}
data_generation_process2 <- function(obj,par){
  obj/par
}
data_generation_process3 <- function(obj,par){
  obj+par
}

#select one of the different pipelines
pipeline_number <- 6

if(pipeline_number == 1){
  #version1
  #readable pipeline but lots of wasted computation time
  #easier to reduce
  pipeline <- list(
    tar_target(init_val,4),
    tar_map(values = all_pars,
            tar_target(step1,data_generation_process1(init_val,par1_col)),
            tar_target(step2,data_generation_process2(step1,par2_col)),
            tar_target(step3,data_generation_process3(step2,par3_col))
    )
  )
}

if(pipeline_number == 2){
#version2
# not readable, but doesn't waste computation
  pipeline <- list(
    tar_target(init_val,4),

    tar_map(
      values = par1,
      tar_target(step1,data_generation_process1(init_val,par1_col)),

      tar_map(
        values = par2,
        tar_target(step2,data_generation_process2(step1,par2_col)),

        tar_map(
          values = par3,
          tar_target(step3,data_generation_process3(step2,par3))
        )
      )
    )
  )
}

if(pipeline_number == 3){
  #version 3
  #mapping predefined, somewhat more readable, but it's in reverse which seems counter intuitive
  map3 <- tar_map(
    values = par3,
    tar_target(step3,data_generation_process3(step2,par3))
  )
  map2 <- tar_map(
    values = par2,
    tar_target(step2,data_generation_process2(step1,par2_col)),
    map3)
  map1 <- tar_map(
    values = par1,
    tar_target(step1,data_generation_process1(init_val,par1_col)),
    map2)

  pipeline <- list(
    tar_target(init_val,4),
    map1
    )


  #or
  # mapping <-
  #   tar_map(
  #     values = par3,
  #     tar_target(step3,data_generation_process3(step2,par3))
  #   ) %>%
  #   tar_map(
  #     values = par2,
  #     tar_target(step2,data_generation_process2(step1,par2_col)),
  #     .) %>%
  #   tar_map(
  #     values = par1,
  #     tar_target(step1,data_generation_process1(init_val,par1_col)),
  #   .)
  #
  # pipeline <- list(
  #   tar_target(init_val,4),
  #   mapping
  # )
}

if(pipeline_number == 4){
  #version 4, using dynamic branching
  #grouped by each stage
  pipeline <- list(
    tar_target(init_val,4),

    tar_group_by(grouped1,all_pars,par1_col),
    tar_target(step1,data_generation_process1(init_val, grouped1$par1_col),pattern = map(grouped1)),

    tar_group_by(grouped2,all_pars,par2_col),
    tar_target(step2,data_generation_process2(step1, grouped2$par2_col),pattern = map(grouped2)),

    tar_group_by(grouped3,all_pars,par3_col),
    tar_target(step3,data_generation_process3(step2, grouped3$par3_col),pattern = map(grouped3))
  )
}

if(pipeline_number == 5){
  #version 5, using dnamic branching
  #lots of redundancy, like in version 1
  pipeline <- list(
    tar_target(init_val,4),

    tar_group_by(grouped1,all_pars,par1_col,par2_col,par3_col),
    tar_target(step1,data_generation_process1(init_val, grouped1$par1_col),pattern = map(grouped1)),
    tar_target(step2,data_generation_process2(step1, grouped1$par2_col),pattern = map(grouped1)),
    tar_target(step3,data_generation_process3(step2, grouped1$par3_col),pattern = map(grouped1))
  )
}


if(pipeline_number == 6){
  #dynamic branching using map
  pipeline <- list(
    tar_target(init_val,4),

    tar_target(par_all, all_pars),
    tar_target(step1,data_generation_process1(init_val, par_all$par1_col),pattern = map(par_all))

  )
}





pipeline




