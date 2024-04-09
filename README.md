# STRIDER Pipelines

Building {targets} pipelines for simulating biodiversity data using {STRIDER}.

## Overview

{STRIDER} (https://github.com/BiologicalRecordsCentre/STRIDER) is an R package for simulating biodiversity data such as those collected via citizen science or surveys. STRIDER has been designed to work with the targets R package. targets is a pipeline tool for R.

This is motivated that data simultion for method development/validation usually requires lots of iterationsa nd combinations of parameters. This can get unwieldly to handle. This repo aims to provide example data simulation pipelines to enable users to get started with it.

## Status

This is early work. An example pipeline using 'static branching' is functional but limited in flexibility and computational efficiency. You can find this pipeline in `targets_static_branching.R`. I am trying to use 'dynamic branching' instead to improve readability but I have encountered some challenges in implementing this. My current progress on this is in`targets_dynamic_branching.R`.

You can run the pipeline using `run_pipeline.R`

