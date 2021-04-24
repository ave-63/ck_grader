args <- commandArgs(trailingOnly = TRUE)

INPUT_DIRECTORY <- args[1]
OUTPUT_DIRECTORY <- args[2]
MAX_POINTS <- strtoi(args[3])
INCORRECT_CREDIT <- as.double(args[4])
GRACE <- as.double(args[5])

if(!require("stringi", quietly = TRUE, character.only = TRUE)){
    install.packages("stringi", character.only = TRUE)
}
library("stringi", quietly = TRUE, character.only = TRUE)

options(stringsAsFactors=FALSE)

## inverse of make.names: make.headings("X10.5to10.9_12.18") gives "10.5to10.9_12-18"
make.headings <- function(name){
    parts <- stri_match_first_regex(name,
        "X((?:\\d+\\.\\d+to\\d+\\.\\d+_\\d+)|(?:\\d+\\.\\d+(?:and\\d+\\.\\d+)+_\\d+))\\.(\\d+)")
    paste0(parts[,2], "-", parts[,3])
}

## Returns vector of strings, headings of df,
## converted from "Page.1.3...complete" to "Page.1.3" as necessary
strip_headings <- function(df){
    headings <- colnames(df)
    matches <- stri_match_first_regex(headings, "(.*)\\.\\.\\.complete")
    for(i in 1:length(headings)){
        if(!is.na(matches[i,2])){
            headings[i] <- matches[i,2]
        }
    }
    headings
}

## Grade a page detail, given row name in pd (link).
## Returns a vector. First entry is the number of questions (max possible score for page).
grade_pd <- function(link){
    heading <- paste0("Page.", pd$page[link])
    pd_df <- read.csv(file = paste0(INPUT_DIRECTORY, pd[link, "file_name"]))
    ## get total number of questions for page
    pd_result = rep(0, nrow(pd_df))
    for(i in 1:ncol(pd_df)){
        ## Assumptions: Each problem is worth one point. Row 1 contains either integer 1
        ## for questions automatically scored, and "-" for written answers where scores are blank.
        if(!is.na(pd_df[1,i]) && pd_df[1,i] == 1){
            pd_result[1] <- pd_result[1] + 1
            for(k in 2:nrow(pd_df)){
                if(!is.na(pd_df[k,i])){
                    if(pd_df[k,i] == 0){
                        pd_result[k] <- pd_result[k] + INCORRECT_CREDIT
                    }
                    if(pd_df[k,i] == 1){
                        pd_result[k] <- pd_result[k] + 1 # 1 pt for correct answer
                    }
                }
            }
        }
        if(!is.na(pd_df[1,i]) && pd_df[1,i] == "-"){
            pd_result[1] <- pd_result[1] + 1
            for(k in 2:nrow(pd_df)){
                ## Written answer is in column after "-". Giving point for at least 2 characters.
                if(!is.na(pd_df[k,i+1]) && nchar(pd_df[k,i+1]) > 2){
                    pd_result[k] <- pd_result[k] + 1
                }
            }
        }
    }
    pd_result
}

## Parse file names
input_filenames = list.files(path = INPUT_DIRECTORY, pattern = ".+\\.csv")
output_filenames = list.files(path = OUTPUT_DIRECTORY, pattern = ".+\\.csv")
## assignments with page ranges
asgn_matches <- stri_match_first_regex(input_filenames,
   '(\\w+)_(\\d+\\.\\d+to\\d+\\.\\d+|\\d+\\.\\d+(?:and\\d+\\.\\d+)+)_(\\d+-\\d+)\\.csv$')
## single page detail results
page_matches <- stri_match_first_regex(input_filenames,
                                     '(\\w+)_(\\d+\\.\\d+)_(\\d+-\\d+)\\.csv$')
output_matches <- stri_match_first_regex(output_filenames, 'ck_grades_(\\w+)\\.csv$')
if(length(input_filenames) == 0){
    stop(paste("Error: there are no csv files in INPUT_DIRECTORY:", INPUT_DIRECTORY))
}
for(i in 1:length(input_filenames)){
    if(is.na(asgn_matches[i,1]) && is.na(page_matches[i,1])){
        print("The following file will not be treated as input, because its name does not match assignment or page detail syntax:", quote = FALSE)
        print(input_filenames[[i]], quote = FALSE)
    }
}

## Populate asgn dataframe with asgn_matches (assignments)
file_name <- c()
course_id <- c()
page_range <- c()
dl_date <- c()
col_name <- c()
for(i in 1:nrow(asgn_matches)){
    if(!is.na(asgn_matches[i,1])){
        chapters <- stri_match_first_regex(asgn_matches[i,3], "(\\d+)\\.\\d+to(\\d+).\\d+")
        ## chapters[1,] entries are NA for "and" assignments
        if(!is.na(chapters[1,1]) && chapters[1,2] != chapters[1,3]){
            print("The following file is being ignored because assignments with \"to\" range must be in one chapter:", quote = FALSE)
            print(asgn_matches[i,1], quote = FALSE)
        } else{
            file_name <- append(file_name, asgn_matches[i,1])
            course_id <- append(course_id, asgn_matches[i,2])
            page_range <- append(page_range, asgn_matches[i,3])
            dl_date <- append(dl_date, asgn_matches[i,4])
            col_name <- append(col_name, make.names(paste0(asgn_matches[i,3], "_", asgn_matches[i,4])) )
        }
    }
}
asgn <- data.frame(file_name=file_name, course_id=course_id, page_range=page_range, dl_date=dl_date, col_name=col_name)

## If output files don't exist, create them
duped = duplicated(asgn$course_id)
keepers <- rep(TRUE, nrow(asgn))
for(i in 1:nrow(asgn)){
    if(!duped[i]){
        output_exists <- FALSE
        if(nrow(output_matches > 0)){
            for(j in 1:nrow(output_matches)){
               if(!is.na(output_matches[j,2]) && asgn$course_id[i] == output_matches[j,2]){
                    output_exists <- TRUE
                    ## Remove rows from asgn that are already in output file w/ same page_range, dl_date
                    existing_asgn <- colnames(read.csv(paste0(OUTPUT_DIRECTORY, output_matches[j,1])))
                    for(k in 1:nrow(asgn)){
                        if(asgn$course_id[k] == output_matches[j,2] &&
                           asgn$col_name[k] %in% existing_asgn){
                            keepers[k] <- FALSE
                        }
                    }
                }
            }
        }
        if(!output_exists){
            new_file_name <- paste0("ck_grades_", asgn$course_id[i], ".csv")
            print(paste("creating output file", new_file_name), quote = FALSE)
            file.create(new_file_name)
            # Get student names from this asgn csv, put them in new file
            df <- read.csv(paste0(INPUT_DIRECTORY, asgn$file_name[i]))
            new_df <- data.frame(name = paste0(df$last_name, ", ", df$first_name))
            write.table(new_df, file = paste0(OUTPUT_DIRECTORY, new_file_name), row.names = FALSE)
        }
    }
}
asgn <- asgn[keepers,] # keep a row iff keepers is TRUE

## Populate pd dataframe with page_matches
file_name <- c()
course_id <- c()
page <- c()
dl_date <- c()
if(nrow(page_matches) > 0){
    for(i in 1:nrow(page_matches)){
        if(!is.na(page_matches[i,1])){
            file_name <- append(file_name, page_matches[i,1])
            course_id <- append(course_id, page_matches[i,2])
            page <- append(page, page_matches[i,3])
            dl_date <- append(dl_date, page_matches[i,4])
        }
    }
}
pd <- data.frame(file_name=file_name, course_id=course_id, page=page, dl_date=dl_date)
## print(pd)

## This creates page_list, a list of vectors of page names eg "10.1" "10.2" "10.3"
## Because 3D data frames are not allowed, page_list must be separate from asgn.
## Like pd_links below, page_list is indexed by asgn$file_name
page_list <- list()
for(i in 1:nrow(asgn)){
    one_page_list <- c()
    tos <- stri_match_first_regex(asgn[i,"page_range"], "(\\d+)\\.(\\d+)to(\\d+)\\.(\\d+)")
    if(!is.na(tos[1,1])){ ## We have a "to" style range
        start <- strtoi(tos[1,3])
        end <- strtoi(tos[1,5])
        one_page_list <- c()
        for(j in start:end){
            one_page_list <- append(one_page_list, paste0(tos[1,2], ".", j))
        }
    }
    else{ ## We have an "and" style range
        one_page_list <- stri_split(asgn[i,"page_range"], regex="and")[[1]]
    }
    page_list[[asgn$file_name[i]]] <- one_page_list
}
#print(asgn)
#print(page_list)

## The following creates pd_links, a list of vectors.
## pd_links is indexed by the corresponding asgn$filename.
## The elements in each vector are the rownames of pd that contain page details for that assignment.
## Tip: to access pd's for asgn row 2:
## for(key in pd_links[[asgn$file_name[1]]]){
##   print(pd[key,])
## }                                        
pd_links <- list()
if(nrow(pd) > 0){
    for(i in 1:nrow(pd)){
        for(j in 1:nrow(asgn)){
            if(pd$course_id[i] == asgn$course_id[j] &&
               pd$page[i] %in% page_list[[j]] &&
               pd$dl_date[i] == asgn$dl_date[j]){
                pd_links[[asgn$file_name[j]]] <- append(pd_links[[asgn$file_name[j]]], rownames(pd)[i])
            }
        }
    }
}

## Now that all the data structures and files are set up, it's time to grade.
for(a in 1:nrow(asgn)){
    asgn_df <- read.csv(paste0(INPUT_DIRECTORY, asgn[a, "file_name"]))
    colnames(asgn_df) <- strip_headings(asgn_df) # added 2021-04 to deal with new " - complete" headings
    these_links <- pd_links[[asgn[a, "file_name"]]]
    print(paste("Grading assignment:",
                asgn[a, "file_name"]), quote = FALSE)
    ## vector of column names in format "Page.5.1":
    these_headers <- paste0(rep("Page.", length(page_list[[asgn[a, "file_name"]]])),
                            page_list[[asgn[a, "file_name"]]])
    ## Some pages have no questions and thus no column in asgn csv.
    ## Remove them to avoid errors:
    keepers <- these_headers %in% colnames(asgn_df)
    these_headers <- these_headers[keepers] ## keep a header iff it's in colnames(asgn_df)
    if(length(these_headers) == 0){
        print(paste("WARNING: skipping", asgn[a,"file_name"],
                    "because it doesn't include the page columns it should!"), quote = FALSE)
    } else {
        ## Grade all linked pd's for this assignment:
        for(l in these_links){
            this_header <- paste0("Page.", pd[l,"page"])
            asgn_df[this_header] <- grade_pd(l)
        }
        ## Compute grades for this asgn:
        max <- sum(asgn_df[1,these_headers])
        asgn_result <- rep(0,nrow(asgn_df))
        asgn_result[1] <- max
        if(max == 0){
            print(paste("WARNING: skipping", asgn[a,"file_name"],
                        "because its maximum points is zero."), quote = FALSE)
        }else{
            for(i in 2:nrow(asgn_df)){
                if(MAX_POINTS == "NUM_QUESTIONS"){
                    ## This is where assignment grades are totalled. Feel free to mess with it:
                    asgn_result[i] <- sum(asgn_df[i,these_headers])/(1 - GRACE)
                    if(asgn_result[i] > asgn_result[1]){
                        asgn_result[i] <- asgn_result[1]
                    }
                }else{
                    ## This is where assignment grades are totalled. Feel free to mess with it:
                    asgn_result[i] <-  sum(asgn_df[i,these_headers]) /
                        ((1 - GRACE)*max) * MAX_POINTS
                    if(asgn_result[i] > MAX_POINTS){
                        asgn_result[i] <- MAX_POINTS
                    }
                }
            }
            ## Read output csv, add asgn column to data frame, and re-write.
            ## Someday, I could make this a little faster by saving all asgn
            ## columns and then read/write once.
            output_file <- paste0("ck_grades_", asgn$course_id[a], ".csv")
            output_df <- read.csv(paste0(OUTPUT_DIRECTORY, output_file))
            output_df[make.names(asgn$col_name[a])] <- round(asgn_result, 2)
            headings <- c(" ", make.headings(colnames(output_df))[2:length(colnames(output_df))])
            write.table(output_df, file = paste0(OUTPUT_DIRECTORY, output_file), sep = ",",
                        row.names = FALSE, col.names = headings)
        }
    }
}

