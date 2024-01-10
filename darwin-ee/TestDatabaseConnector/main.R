# Print environment variables and setup db connection if possible
library(DatabaseConnector)

ENV_VARS <- c("DATA_SOURCE_NAME",
              "DBMS_USERNAME",
              "DBMS_PASSWORD",
              "DBMS_TYPE",
              "CONNECTION_STRING",
              "CDM_SCHEMA",
              "WRITE_SCHEMA",
              "RESULT_SCHEMA",
              "COHORT_TARGET_TABLE",
              "BQ_KEYFILE",
              "ANALYSIS_ID",
              "DBMS_CATALOG",
              "DBMS_SERVER",
              "DBMS_NAME",
              "DBMS_PORT",
              "CDM_VERSION",
              "DATABASECONNECTOR_JAR_FOLDER")

envVars <- lapply(ENV_VARS, Sys.getenv)
names(envVars) <- ENV_VARS

print("Environment variables that are available")
for (i in seq_along(envVars)) {
  var   <- names(envVars)[i]
  value <- envVars[i]
  if (var != "DBMS_PASSWORD") {
    print(paste(var, ":", nchar(value)))
  } else {
    print(paste(var, ": *************"))
  }
}

# try to setup db connection
cdmSchema <- envVars[["CDM_SCHEMA"]]

if (envVars[["DBMS_CATALOG"]] != "") {
  cdmSchema <- paste(cdmSchema, envVars[["DBMS_CATALOG"]], sep = ".")
}

if (envVars[["DBMS_PORT"]] == "") {
  port = NULL
} else {
  port = envVars[["DBMS_PORT"]]
}

# write results to the /results folder

print("Setting up database connection")

connectionDetails <- createConnectionDetails(
  dbms = envVars[["DBMS_TYPE"]],
  # connectionString = envVars[["CONNECTION_STRING"]],
  user = envVars[["DBMS_USERNAME"]],
  password = envVars[["DBMS_PASSWORD"]],
  server = paste0(envVars[["DBMS_SERVER"]], "/", envVars[["DBMS_NAME"]]),
  port = port
)

conn <- connect(connectionDetails)

personCount <- dbGetQuery(conn, paste0("SELECT COUNT(*) AS n FROM ", cdmSchema, ".person"))[[1]]
readr::write_lines(paste("Number of persons:", personCount), "/results/output.txt")
disconnect(conn)
print("test complete")


