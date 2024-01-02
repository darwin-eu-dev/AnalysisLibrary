# print(Sys.getenv())

vars <- c("DBMS_TYPE",
          "DATA_SOURCE_NAME",
          "CDM_VERSION",
          "DBMS_CATALOG",
          "DBMS_SERVER",
          "DBMS_NAME",
          "DBMS_PORT",
          "DBMS_USERNAME",
          "DBMS_PASSWORD",
          "CDM_SCHEMA",
          "WRITE_SCHEMA"
)

for (v in vars) {
  if (v != "DBMS_PASSWORD") {
    print(paste0(v, ": ", Sys.getenv(v, unset = "{variable not set}")))
  }
}


source("cdm_from_environment.R")

library(CDMConnector)
library(dplyr, warn.conflicts = F)

print(sessionInfo())

print("Connection to the database using environment variables")
cdm <- cdm_from_environment()

print(paste("database connection class:", paste(class(attr(cdm, "dbcon")), collapse = ", ")))

print("Querying the CDM with dplyr")

personCount <- cdm$person %>%
  count(name = "n") %>%
  pull(n)

message(paste("Number of persons:", personCount))

readr::write_lines(paste("Number of persons:", personCount), "/results/output.txt")

CDMConnector::cdm_disconnect(cdm)

cli::cat_rule("CDMConnector test complete!")


