
# Use this script to run a single report so it will be generated with a unique 
# drift name

# default params
# mission: CRPGT_2019 # for report printing/building filenames
# drift: DS1
# channel: ch1
# pgver: PAM20210a # string e.g., pam20207b, doesn't need quotations, for making file names
# path_pg: 'R:/McCullough/KOGIA_DASBR_POST/2019_CRPGT' # must use drive letter (not //)
# path_dets: 'R:/McCullough/KOGIA_DASBR_POST/AcousticStudies/CRPGT_2019' # path to AcousticStudies
# path_code: 'Z:/LLHARP/processingCode/llamp' # path to code (if not using r proj/here package)
# path_to_refSpec: 'G:/GitHub/Kogia_DASBR/refSpec'
# refSpecList: !r c('Kogia_refSpec_HICEAS2023_DS12a') # use !r to call r then 
# refSpecSp: !r c('Pm-OnAxis','Pm_ALL') 

# MODIFY THESE
path_out <- 'F:/Pm_AcousticStudies/23 reprocess//'
mission <- 'CalCurCEAS'
drift <- '023'
channelStr <- 'ch1'
channelNum <- 1
path_pg <- 'F:/Binaries/rerun/CalCurCEAS_023/' 
path_dets <- 'F:/Pm_AcousticStudies/23 reprocess/'


# RUN THIS
rmarkdown::render(
  here::here('_code/SpermWhale_event_summary_report_drifter.Rmd'),
  params = list(
    mission = mission,
    drift = drift,
    channelStr = channelStr,
    channelNum = channelNum,
    path_pg = path_pg,
    path_dets = path_dets
  ),
  output_file = file.path(path_out, paste0("SpermWhale_event_summary_report_DASBR_", 
                                           mission, '_', drift, '_', Sys.Date(), ".html"))
)
