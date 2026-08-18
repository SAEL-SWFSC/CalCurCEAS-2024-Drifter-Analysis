# =============================================================================
# match_detections_to_gps.R
#
# For each acoustic detection file (.xls/.xlsx), reads the "Detections" sheet,
# computes the midpoint time of each detection (Start time + End time) / 2,
# then finds the GPS fix closest in time from the matching deployment's GPS CSV,
# and interpolates lat/lon linearly between the two nearest GPS points.
#
# File naming convention assumed:
#   Detection files: <deployment_id>_*.xls or .xlsx  (e.g. CalCurCEAS_001_dolphins_AH_Final.xls)
#   GPS files:       <deployment_id>_GPS.csv          (e.g. CalCurCEAS_001_GPS.csv)
#
# The deployment ID is extracted from the filename as the first two underscore-
# delimited tokens (e.g. "CalCurCEAS_001"). Adjust DEPLOYMENT_ID_PATTERN below
# if your naming convention differs.
#
# Output: one CSV per deployment (in output_dir), plus a combined CSV of all
#         deployments.
# =============================================================================

library(readxl)   # read_xls / read_xlsx
library(dplyr)
library(lubridate)
library(tidyr)
library(purrr)

# ── USER SETTINGS ─────────────────────────────────────────────────────────────

detections_dir <- "C:\\Users\\annes\\Documents\\Github\\TethysSAEL\\Detection Worksheets\\Dolphins\\CalCurCEAS"   # folder containing .xls / .xlsx files
gps_dir        <- "C:\\Users\\annes\\Documents\\Github\\CalCurCEAS-2024-Drifter-Analysis\\_data\\GPS\\DASBRs"          # folder containing _GPS.csv files
output_dir     <- "C:\\Users\\annes\\Documents\\CalCurCEAS\\Detections_wGPS"       # folder where results will be written

# Regex to extract the deployment ID from a detection filename.
# Default: captures everything up to (but not including) the third underscore.
# e.g. "CalCurCEAS_001_dolphins_AH_Final.xls" → "CalCurCEAS_001"
DEPLOYMENT_ID_PATTERN <- "^([^_]+_[^_]+)"

# ── HELPER: linear interpolation of lat/lon ───────────────────────────────────

interpolate_position <- function(t, t1, t2, lat1, lat2, lon1, lon2) {
  # Returns a list(lat, lon) linearly interpolated at time t between t1 and t2.
  # If t1 == t2 (duplicate timestamps) just returns the first point.
  if (t1 == t2) return(list(lat = lat1, lon = lon1))
  frac <- as.numeric(difftime(t, t1, units = "secs")) /
    as.numeric(difftime(t2, t1, units = "secs"))
  list(
    lat = lat1 + frac * (lat2 - lat1),
    lon = lon1 + frac * (lon2 - lon1)
  )
}

# ── HELPER: process one detection file ───────────────────────────────────────

process_one_deployment <- function(det_file, gps_dir, output_dir) {
  
  # --- 1. Identify deployment ID ---
  base      <- basename(det_file)
  dep_match <- regmatches(base, regexpr(DEPLOYMENT_ID_PATTERN, base))
  if (length(dep_match) == 0) {
    warning("Could not extract deployment ID from: ", base, " — skipping.")
    return(NULL)
  }
  dep_id <- dep_match
  
  message("Processing deployment: ", dep_id)
  
  # --- 2. Load detections ---
  dets <- tryCatch(
    read_excel(det_file, sheet = "Detections"),
    error = function(e) {
      warning("Could not read Detections sheet in ", base, ": ", e$message)
      return(NULL)
    }
  )
  if (is.null(dets) || nrow(dets) == 0) {
    message("  No detections found — skipping.")
    return(NULL)
  }
  
  # Standardise column names (readxl preserves original case)
  names(dets) <- trimws(names(dets))
  
  required_cols <- c("Start time", "End time")
  missing <- setdiff(required_cols, names(dets))
  if (length(missing) > 0) {
    warning("Missing columns in ", base, ": ", paste(missing, collapse = ", "))
    return(NULL)
  }
  
  # Parse timestamps (readxl usually returns POSIXct already; coerce to be safe)
  dets <- dets %>%
    mutate(
      start_utc = as.POSIXct(`Start time`, tz = "UTC"),
      end_utc   = as.POSIXct(`End time`,   tz = "UTC"),
      mid_utc   = start_utc + difftime(end_utc, start_utc, units = "secs") / 2
    )
  
  # --- 3. Load matching GPS file ---
  gps_file <- file.path(gps_dir, paste0(dep_id, "_GPS.csv"))
  if (!file.exists(gps_file)) {
    warning("GPS file not found for ", dep_id, ": ", gps_file)
    return(NULL)
  }
  
  gps <- read.csv(gps_file, stringsAsFactors = FALSE)
  names(gps) <- trimws(names(gps))
  
  required_gps <- c("UTC", "Latitude", "Longitude")
  missing_gps  <- setdiff(required_gps, names(gps))
  if (length(missing_gps) > 0) {
    warning("GPS file for ", dep_id, " missing columns: ",
            paste(missing_gps, collapse = ", "))
    return(NULL)
  }
  
  gps <- gps %>%
    mutate(utc_parsed = as.POSIXct(UTC, tz = "UTC", format = "%Y-%m-%d %H:%M:%S")) %>%
    filter(!is.na(utc_parsed)) %>%
    arrange(utc_parsed)
  
  # --- 4. Interpolate lat/lon for each detection midpoint ---
  results <- map_dfr(seq_len(nrow(dets)), function(i) {
    
    t_mid <- dets$mid_utc[i]
    
    # Find the GPS rows immediately before and after the midpoint
    idx_after  <- which(gps$utc_parsed >= t_mid)
    idx_before <- which(gps$utc_parsed <= t_mid)
    
    if (length(idx_before) == 0 && length(idx_after) == 0) {
      # No GPS data at all (shouldn't happen but guard anyway)
      return(tibble(interp_lat = NA_real_, interp_lon = NA_real_,
                    gps_match_note = "no GPS data"))
    }
    
    if (length(idx_before) == 0) {
      # Detection is before all GPS fixes — use the earliest fix
      j <- min(idx_after)
      return(tibble(
        interp_lat     = gps$Latitude[j],
        interp_lon     = gps$Longitude[j],
        gps_match_note = paste0("extrapolated (before GPS track); ",
                                "nearest GPS fix: ", gps$utc_parsed[j])
      ))
    }
    
    if (length(idx_after) == 0) {
      # Detection is after all GPS fixes — use the latest fix
      j <- max(idx_before)
      return(tibble(
        interp_lat     = gps$Latitude[j],
        interp_lon     = gps$Longitude[j],
        gps_match_note = paste0("extrapolated (after GPS track); ",
                                "nearest GPS fix: ", gps$utc_parsed[j])
      ))
    }
    
    # Normal case: bracket the midpoint
    j1 <- max(idx_before)  # last fix <= t_mid
    j2 <- min(idx_after)   # first fix >= t_mid
    
    if (j1 == j2) {
      # Exact match on a GPS timestamp
      return(tibble(
        interp_lat     = gps$Latitude[j1],
        interp_lon     = gps$Longitude[j1],
        gps_match_note = paste0("exact GPS match: ", gps$utc_parsed[j1])
      ))
    }
    
    pos <- interpolate_position(
      t  = t_mid,
      t1 = gps$utc_parsed[j1], t2 = gps$utc_parsed[j2],
      lat1 = gps$Latitude[j1], lat2 = gps$Latitude[j2],
      lon1 = gps$Longitude[j1], lon2 = gps$Longitude[j2]
    )
    
    tibble(
      interp_lat     = pos$lat,
      interp_lon     = pos$lon,
      gps_match_note = paste0("interpolated between ",
                              gps$utc_parsed[j1], " and ",
                              gps$utc_parsed[j2])
    )
  })
  
  # --- 5. Combine and write per-deployment CSV ---
  out <- bind_cols(
    tibble(deployment_id = dep_id),
    dets,
    results
  ) %>%
    # Drop the helper columns added during processing
    select(-start_utc, -end_utc, -mid_utc) %>% 
    mutate(across(where(~ inherits(., "POSIXct")), 
                  ~ format(., "%Y-%m-%dT%H:%M:%SZ")))
  
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  out_file <- file.path(output_dir, paste0(dep_id, "_detections_with_GPS.csv"))
  write.csv(out, out_file, row.names = FALSE)
  message("  Written: ", out_file)
  
  out
}

# ── MAIN: loop over all detection files ──────────────────────────────────────

det_files <- list.files(
  detections_dir,
  pattern     = "(?i)final.*\\.(xls|xlsx)$",
  full.names  = TRUE,
  ignore.case = TRUE,
  recursive = TRUE
)

if (length(det_files) == 0) {
  stop("No .xls or .xlsx files found in: ", detections_dir)
}

message("Found ", length(det_files), " detection file(s).")

all_results <- map(det_files, process_one_deployment,
                   gps_dir    = gps_dir,
                   output_dir = output_dir)

# Drop any NULLs (deployments that were skipped due to errors)
all_results <- compact(all_results)

if (length(all_results) > 0) {
  combined <- bind_rows(all_results)
  combined_file <- file.path(output_dir, "ALL_deployments_detections_with_GPS.csv")
  write.csv(combined, combined_file, row.names = FALSE)
  message("\nDone! Combined file written to: ", combined_file)
  message("Total detections processed: ", nrow(combined))
} else {
  message("No results to combine.")
}