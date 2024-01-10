

cdm_from_environment <- function(write_prefix = "") {
  
  connection_string <- Sys.getenv("CONNECTION_STRING") 
  
  if (connection_string == "") {
    stop("CONNECTION_STRING environment variable not set.")
  }
  
  parts <- stringr::str_split(connection_string, ":")[[1]]
  port_db <- stringr::str_split(parts[4], "/")[[1]]
  
  # required args that need to be passed in
  dbms <- Sys.getenv("DBMS_TYPE")
  server <- stringr::str_remove(parts[3], "^//+")
  port <- port_db[1]
  dbname <- port_db[2]
  username <- Sys.getenv("DBMS_USERNAME")
  password <- Sys.getenv("DBMS_PASSWORD")
  cdm_schema <- Sys.getenv("DBMS_SCHEMA")
  write_schema <- Sys.getenv("RESULT_SCHEMA")
  
  
  vars <- c(dbms, server, port, dbname, password, cdm_schema, write_schema)
  names_vars <- c("dbms", "server", "port", "dbname", "password", "cdm_schema", "write_schema")
  
  for (i in seq_along(vars)) {
    if (nchar(vars[i]) < 1) stop(paste(names_vars[i], "is not required but not available!"))
  }
  
  supported_db <- c("postgresql", "sql server", "redshift", "duckdb", "snowflake")
  
  if (!(dbms %in% supported_db)) {
    cli::cli_abort("The environment variable DBMS_TYPE must be on one of {paste(supported_db, collapse = ', ')} not `{Sys.getenv('DBMS_TYPE')}`.")
  }
  
  if (dbms == "duckdb") {
    db <- dbname
    if (db == "") {
      db <- "GiBleed"
    }
    
    checkmate::assert_choice(db, CDMConnector::example_datasets())
    con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomia_dir(db))
    cdm <- CDMConnector::cdm_from_con(con, "main", "main", cdm_version = "5.3", cdm_name = db)
    return(cdm)
  }
  
  cdm_schema <- stringr::str_split(cdm_schema, "\\.")[[1]]
  write_schema <- stringr::str_split(write_schema, "\\.")[[1]]

  
  print(write_schema)
  print(sapply(write_schema, nchar))
  
  if (dbms %in% c("postgresql", "redshift")) {
    
    drv <- switch (dbms,
                   "postgresql" = RPostgres::Postgres(),
                   "redshift" = RPostgres::Redshift()
    )
    
    con <- DBI::dbConnect(drv = drv,
                          dbname   = dbname,
                          host     = server,
                          user     = username,
                          password = password,
                          port     = port)
    
    if (!DBI::dbIsValid(con)) {
      cli::cli_abort("Database connection failed!")
    }
    
  } else if (dbms == "sql server") {
    
    con <- DBI::dbConnect(odbc::odbc(),
                          Driver   = "ODBC Driver 17 for SQL Server",
                          Server   = server,
                          Database = dbname,
                          UID      = username,
                          PWD      = password,
                          TrustServerCertificate="yes",
                          Port     = port)
    
    if (!DBI::dbIsValid(con)) {
      cli::cli_abort("Database connection failed!")
    }
    
    
  } else if (dbms == "snowflake") {
    con <- DBI::dbConnect(odbc::odbc(),
                          DRIVER    = "SnowflakeDSIIDriver",
                          SERVER    = server,
                          DATABASE  = dbname,
                          UID       = username,
                          PWD       = password,
                          WAREHOUSE = "COMPUTE_WH_XS") # don't hardcode this
    
    if (!DBI::dbIsValid(con)) {
      cli::cli_abort("Database connection failed!")
    }
    
  } else {
    cli::cli_abort("{dbms} is not a supported database type!")
  }
  
  # split schemas. If write schema has a dot we need to interpret it as catalog.schema
  # cdm schema should not have a dot
  
  # if (stringr::str_detect(Sys.getenv("WRITE_SCHEMA"), "\\.")) {
  #   write_schema <- stringr::str_split(write_schema, "\\.")[[1]]
  #   if (length(write_schema) != 2) {
  #     cli::cli_abort("write_schema can have at most one period (.)!")
  #   }
  #   
  #   stopifnot(nchar(write_schema[1]) > 0, nchar(write_schema[2]) > 0)
  #   write_schema <- c(catalog = write_schema[1], schema = write_schema[2])
  # } else {
  #   write_schema <- c(schema = Sys.getenv("WRITE_SCHEMA"))
  # }
  # 
  # if (write_prefix != "") {
  #   if (dbms != "snowflake") {
  #     write_schema <- c(write_schema, prefix = write_prefix)
  #   }
  # }
  
  # add prefix
  if (write_prefix != "") {
    if (length(write_schema) == 1) {
      write_schema <- c(schema = write_schema, prefix = write_prefix)
    } else if (length(write_schema) == 2) {
      write_schema <- c(catalog = write_schema[1], 
                        schema = write_schema[2], 
                        prefix = write_prefix)
    }
  } else if (length(write_schema) == 2) {
    write_schema <- c(catalog = write_schema[1], schema = write_schema[2])
  }
    
  cdm <- CDMConnector::cdm_from_con(
    con = con,
    cdm_schema = cdm_schema,
    write_schema = write_schema,
    cdm_version = "5.3",
    cdm_name = Sys.getenv("DATA_SOURCE_NAME", unset = "unnamed_cdm"))
  
  if (length(names(cdm)) == 0) {
    cli::cli_abort("CDM object creation failed!")
  }
  
  return(cdm)
}
