library(DBI)
library(RSQLite)
library(dplyr)
library(purrr)



read_pg_events <- function(db_file, event_table_pattern = "OfflineEvents") {
  deployment_code <- paste0(
    "CalCurCEAS_",
    stringr::str_pad(
      stringr::str_extract(basename(db_file), "[0-9]+"),
      width = 3,
      pad = "0"
    )
  )
  
  con <- DBI::dbConnect(RSQLite::SQLite(), db_file)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  
  event_tables <- DBI::dbListTables(con) |>
    grep(event_table_pattern, x = _, value = TRUE)
  
  if (length(event_tables) == 0) return(NULL)
  
  purrr::map_dfr(event_tables, function(tbl) {
    events <- DBI::dbReadTable(con, tbl)
    
    events |>
      dplyr::mutate(
        dplyr::across(dplyr::everything(), as.character),
        deployment_code = deployment_code,
        db_file = db_file,
        table = tbl,
        .before = 1
      )
  })
}


