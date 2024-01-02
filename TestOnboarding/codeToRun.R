library(DatabaseConnector)

# Settings -------------------

# DBMS Connection Details
dbms <- Sys.getenv("DBMS_TYPE")
connectionString <- Sys.getenv("CONNECTION_STRING")
user <- Sys.getenv("DBMS_USERNAME")
password <- Sys.getenv("DBMS_PASSWORD")
cdmDatabaseSchema <- Sys.getenv("CDM_SCHEMA")
resultsDatabaseSchema <- Sys.getenv("WRITE_SCHEMA")
vocabDatabaseSchema <- cdmDatabaseSchema  # TODO?
cdmVersion <- Sys.getenv("CDM_VERSION")
numThreads <- 1 # TODO?


print(paste0("SELECT COUNT(*) AS n FROM ", cdmDatabaseSchema, ".person"))


print("Setting up db connection")
conn <- DatabaseConnector::connect(dbms = dbms,
                                   connectionString = connectionString,
                                   user = user,
                                   password = password,
                                   pathToDriver = "/opt/hades/jdbc_drivers")
personCount <- dbGetQuery(conn, paste0("SELECT COUNT(*) AS n FROM ", cdmDatabaseSchema, ".person"))[[1]]
readr::write_lines(paste("Number of persons:", personCount), "/results/output.txt")
disconnect(conn)
print("test 1 complete")


print("Setting up db connection")
conn <- DatabaseConnector::connect(dbms = dbms,
                                   connectionString = connectionString,
                                   user = user,
                                   password = password)

personCount <- dbGetQuery(conn, paste0("SELECT COUNT(*) AS n FROM ", cdmDatabaseSchema, ".person"))[[1]]
readr::write_lines(paste("Number of persons:", personCount), "/results/output.txt")
disconnect(conn)
print("test 2 complete")


connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = dbms,
  connectionString = connectionString,
  user = user,
  password = password,
  pathToDriver = "/opt/hades/jdbc_drivers"
)

print("Setting up db connection")
conn <- DatabaseConnector::connect(connectionDetails)
personCount <- dbGetQuery(conn, paste0("SELECT COUNT(*) AS n FROM ", cdmDatabaseSchema, ".person"))[[1]]
readr::write_lines(paste("Number of persons:", personCount), "/results/output.txt")
disconnect(conn)
print("test 3 complete")

# User entered parameters
databaseId <- Sys.getenv("DATA_SOURCE_NAME")

# CdmOnboarding
authors <- strsplit(Sys.getenv("AUTHORS"), ',')  # TODO: get from cdmSource.cdmHolder?
baseUrl <- Sys.getenv("WEBAPI_BASEURL")

# Hard coded parameters
smallCellCount <- 5
verboseMode <- FALSE
resultsFolder <- '/results'
sqlOnly <- FALSE

achillesOutputFolder <- file.path(resultsFolder, 'achilles')
dqdOutputFolder <- file.path(resultsFolder, 'dqd')
dqdOutputFile <- sprintf("%s-%s.json", tolower(databaseId), format(Sys.time(), "%Y%m%d%H%M%S"))
cdmOnboardingOutputFolder <- file.path(resultsFolder, 'cdmOnboarding')
dashboardExportOutputFolder <- file.path(resultsFolder, 'dashboardExport')

# Achilles -------------------

executeAchilles <- as.logical(Sys.getenv("EXECUTE_ACHILLES"))
if (!executeAchilles) {
  # TODO: check if Achilles results are avaiable. If not, print message and execute Achilles anyway OR exit.
  # DashboardExport:::.checkAchillesTablesExist()
}

if (executeAchilles) {
  library(Achilles)
  Achilles::achilles(
    connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = cdmDatabaseSchema,
    scratchDatabaseSchema = resultsDatabaseSchema,
    vocabDatabaseSchema = vocabDatabaseSchema,
    tempEmulationSchema = resultsDatabaseSchema,
    sourceName = databaseId,
    smallCellCount = smallCellCount,
    cdmVersion = cdmVersion,
    numThreads = numThreads,
    sqlOnly = sqlOnly,
    outputFolder = achillesOutputFolder,
    verboseMode = verboseMode
    # createTable = TRUE,
    # createIndices = TRUE,
    # tempAchillesPrefix = "tmpach",
    # dropScratchTables = TRUE,
    # optimizeAtlasCache = FALSE,
    # defaultAnalysesOnly = TRUE,
    # updateGivenAnalysesOnly = FALSE,
    # sqlDialect = NULL
  )
}

# DQD ------------------------
library(DataQualityDashboard)
results <- DataQualityDashboard::executeDqChecks(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  vocabDatabaseSchema = vocabDatabaseSchema,
  resultsDatabaseSchema = resultsDatabaseSchema,
  cdmSourceName = databaseId,
  numThreads = numThreads,
  sqlOnly = sqlOnly,
  outputFolder = dqdOutputFolder,
  outputFile = dqdOutputFile,
  verboseMode = verboseMode
  # writeToTable = FALSE,
  # writeTableName = "dqdashboard_results",
  # writeToCsv = FALSE,
  # csvFile = "",
  # checkLevels = c("TABLE", "FIELD", "CONCEPT"),
  # tablesToExclude = c("CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
  # checkNames = c(),
  # cohortDefinitionId = c(),
  # cohortDatabaseSchema = resultsDatabaseSchema,
  # cohortTableName = "cohort",
  # tableCheckThresholdLoc = "default",
  # fieldCheckThresholdLoc = "default",
  # conceptCheckThresholdLoc = "default"
)


# CdmOnboarding --------------
library(CdmOnboarding)
CdmOnboarding::cdmOnboarding(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  resultsDatabaseSchema = resultsDatabaseSchema,
  vocabDatabaseSchema = vocabDatabaseSchema,
  oracleTempSchema = oracleTempSchema,
  databaseId = databaseId,
  authors = authors,
  smallCellCount = smallCellCount,
  runWebAPIChecks = FALSE,
  baseUrl = "",
  outputFolder = cdmOnboardingOutputFolder,
  dqdJsonPath = dqdOutputFolder
)

# DashboardExport ------------
library(DashboardExport)
DashboardExport::dashboardExport(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    achillesDatabaseSchema = resultsDatabaseSchema,
    vocabDatabaseSchema = vocabDatabaseSchema,
    databaseId = databaseId,
    smallCellCount = smallCellCount,
    outputFolder = dashboardExportOutputFolder,
    verboseMode = verboseMode
)
