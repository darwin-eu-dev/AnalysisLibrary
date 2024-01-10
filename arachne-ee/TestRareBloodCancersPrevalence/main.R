library(CDMConnector)
library(IncidencePrevalence)
library(dplyr)
library(log4r)
setwd(file.path(getwd(), "TestRareBloodCancersPrevalence"))
print(getwd())
print(list.files())
# source("arachne-ee/TestRareBloodCancersPrevalence/cdm_from_environment.R")
source("cdm_from_environment.R")

# database metadata and connection details -----
# The name/ acronym for the database
db_name <- Sys.getenv("DATA_SOURCE_NAME") %>%
  tolower() %>%
  stringr::str_replace_all(" ", "_") %>%
  stringr::str_replace_all("\\(|\\)", "")

# Set output folder location -----
# the path to a folder where the results from this analysis will be saved
# output_folder <- here::here("results") # does not work with execution engine
output_folder <- "/results"

# create cdm reference ----
# con <- DBI::dbConnect(duckdb::duckdb(), eunomia_dir())
# cdm <- cdm_from_con(con, "main", "main")

# cdm <- cdm_from_environment(write_prefix = "dw_")
prefix <- paste0("tmp", as.integer(Sys.time()) %% 1000, "_")
cdm <- cdm_from_environment(prefix)

# check database connection
# running the next line should give you a count of your person table
n <- cdm$person %>%
  tally() %>%
  pull(n)

print(paste(n, "persons in the CDM person table"))

print(paste("Database connection class:", class(attr(cdm, "dbcon"))))

# create directory if it does not already exist ----
if (!file.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}

# start log ----
log_file <- paste0(output_folder, "/log.txt")
logger <- create.logger()
logfile(logger) <- log_file
level(logger) <- "INFO"

# tables ---
table_outcome <-"outcome"
table_dpop_sex <- "dpop_sex"
table_ph <- "dpop_ph"
table_age <- "dpop_age"
table_point_prev <- "point_prev"
table_period_prev <- "period_prev"

# instantiate outcome cohorts ----
info(logger, "INSTANTIATE OUTCOME COHORTS")

outcome_cohorts <- readCohortSet(here::here("outcomeCohorts")) %>% 
  slice(1:2) # for testing

info(logger, "- getting outcomes")

cdm <- generateCohortSet(cdm,
                         outcome_cohorts,
                         name = table_outcome,
                         overwrite = TRUE)

total_subjects <- cohort_count(cdm[[table_outcome]]) %>%
  summarise(total = sum(number_subjects)) %>%
  pull(total)

print(paste("total subjects with outcomes:", total_subjects))

# get denominator cohorts -----
info(logger, "GETTING DENOMINATOR COHORTS")
info(logger, "- getting denominator - primary and sex")

cdm <- generateDenominatorCohortSet(
  cdm = cdm,
  name = table_dpop_sex,
  cohortDateRange = c(as.Date("2010-01-01"), as.Date("2024-01-01")),
  sex = c("Male", "Female", "Both"),
  daysPriorObservation = 365,
  overwrite = TRUE
)

info(logger, "- getting denominator - prior history")

cdm <- generateDenominatorCohortSet(
  cdm = cdm,
  name = table_ph,
  cohortDateRange = c(as.Date("2010-01-01"), as.Date("2024-01-01")),
  daysPriorObservation = c(0, 1095),
  overwrite = TRUE
)

info(logger, "- getting denominator - age_gr")

cdm <- generateDenominatorCohortSet(
  cdm = cdm,
  name = table_age,
  cohortDateRange = c(as.Date("2010-01-01"), as.Date("2024-01-01")),
  ageGroup = list(
    # age_gr_1
    c(0, 9), c(10, 19), c(20, 29), c(30, 39), c(40, 49),
    c(50, 59), c(60, 69), c(70, 79), c(80, 89),
    c(90, 99), c(100, 150),
    # age_gr_2
    c(0, 44), c(45, 64), c(65, 150)
  ),
  daysPriorObservation = 365,
  overwrite = TRUE
)

# estimate prevalence -----
denominators <- c(
  table_dpop_sex,
  table_ph,
  table_age
)

prevalence_estimates <- list()

for (i in seq_along(denominators)) {

  info(logger, paste0("- getting point prevalence for ", denominators[i]))
  # debugonce(estimatePointPrevalence)
  prevalence_estimates[[paste0("point_prevalence_", denominators[[i]])]]  <- estimatePointPrevalence(
    cdm = cdm,
    denominatorTable = denominators[i],
    outcomeTable = table_outcome,
    interval = "years",
    temporary = FALSE
  )

  info(logger, paste0("- getting period prevalence for ", denominators[i]))


  prevalence_estimates[[paste0("period_prevalence_", denominators[[i]])]] <- estimatePeriodPrevalence(
    cdm = cdm,
    denominatorTable = denominators[i],
    outcomeTable = table_outcome,
    completeDatabaseIntervals = TRUE,
    fullContribution = c(TRUE, FALSE),
    interval = "years",
    temporary = FALSE
  )
}

# gather results and export -----
info(logger, "ZIPPING RESULTS")
exportIncidencePrevalenceResults(
  result = prevalence_estimates,
  zipName = paste0(c(db_name, "C1_001_Results", format(Sys.Date(), format="%Y%m%d")), collapse = "_"),
  outputFolder = output_folder
)

cdm_disconnect(cdm)

print("-- Thank you for running the study!")
print("-- If all has worked, there should now be a zip folder with your results in the output folder to share")


