#!/usr/bin/env Rscript

# Following the query_collection.R script developed by Ava Hoffman from the AnVIL_Collection:
# https://github.com/fhdsl/AnVIL_Collection/blob/main/scripts/query_collection.R

library(optparse) #need for option parsing
library(httr) #need for API requests
library(jsonlite) #need for fromJSON
library(dplyr) #need for bind_rows
library(readr) #need for write_tsv
library(tidyr) #need for unite, separate_longer_delim, separate_wider_delim
library(stringr) #need for str_detect and str_extract_all and str_replace


# -------- Get the GitHub Token -----------

option_list <- list(
  optparse::make_option(
    c("--git_pat"),
    type = "character",
    default = NULL,
    help = "GitHub personal access token",
  )
)

# Read the GH_PAT argument
opt_parser <- optparse::OptionParser(option_list = option_list)
opt <- optparse::parse_args(opt_parser)
git_pat <- opt$git_pat

#' Construct the raw content base URL for a specific course on GitHub
#'
#' @description This function uses the Github Link column (named `html_url` when/how used in `get_book_info()`) info in order to construct the raw content base URL
#' for a specific course. It does not include the end of the URL/a specific file.
#'
#' @param github_link Use the info from the github link column of the data for a course to switch the beginning of the link ("github.com") with the raw content part of the URL using str_replace from stringr
#'
#' @import stringr
#'
#' @return the base_url for raw content from GitHub after the str_replace action

make_raw_content_url <- function(github_link){
  return(str_replace(github_link,
                      "github.com",
                      "raw.githubusercontent.com"))
}

#' Extract the URL of interest for available Coursera and Leanpub course formats using grep and str_extract_all
#'
#' @description This function searches the relevant data for a specific pattern (e.g, "Coursera") and if found identifies line index (multiple?) where it is found (using grep).
#' If it is found more than once, that may be because it was mentioned without a URL, therefore we perform a grepl (returning TRUEs or FALSEs) to select specifically the line (from `relevant_lines`) where part of a url pattern is too
#' We then use the `relevant_line` index containing the url of interest to subset the `relevant_data`
#' And we use `str_extract_all` to extract all URLs in that line
#' Sometimes with the data, multiple URLs may be on the same line, so in those cases we have to check how many URLs were extracted and re grep our pattern of interest to select the correct url.
#'
#' @param pattern_to_search the relevant pattern we're searching for (e.g., Coursera and Leanpub) whose link we want
#' @param relevant_data the raw Rmd data from readLines
#' @param url_pattern default is a regex pattern identified from stack overflow (https://stackoverflow.com/a/26498790) adding on a noncapturing group as explained in another stack overflow post (https://stackoverflow.com/a/3926546) `(?=//))` which asserts that there is a parentheses immediately following the URL
#'
#' @import stringr
#'
#' @return extracted_string the relevant, extracted URL (or NA_character_ if URL not available)

get_linkOI <- function(pattern_to_search, relevant_data, url_pattern = "http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+(?=\\))"){
  if(sum(grepl(pattern_to_search, relevant_data)) >= 1){ #pattern found at least once in data
    relevant_lines <- grep(pattern_to_search, relevant_data)
    data_of_interest <- relevant_data[relevant_lines][grepl("https", relevant_data[relevant_lines])] #select only lines with a URL ... word may be mentioned without a URL
    extracted_string <- unlist(str_extract_all(data_of_interest, url_pattern))
    if (length(extracted_string) > 1){ #more than one URL extracted
      return(extracted_string[grep(tolower(pattern_to_search), extracted_string)]) #selecting relevant one
    } else if (length(extracted_string) == 1){ #only one URL extracted
      return(extracted_string)
    } else { return(NA_character_)} #empty link (e.g., commented out in the code)
  } else { return(NA_character_) } #pattern wasn't found in data
}

# ----------- Function to get book info (Course Name, Coursera Link, Leanpub Link) -------------

#' A function to traverse the GitHub queried data and extract book info (course name, coursera link, and leanpub link) for each course
#'
#' @description This function creates the relevant stand in columns and is meant for batches of github repos, dealing with each github repo in the batch individually
#' uses `make_raw_content_url()` with the `html_url` column to build the prefix of the raw content URL (`base_url`)
#' Then it uses this base_url together with `index.Rmd` on the main branch to try to read the file. If that file is there and can be read,
#' we read it in using `readLines()` and then goes about getting the course name from the book header
#' using `grep` to find the lines with `---` that surround that header material
#' and then using `grep` to find the line within that range of lines with the title info and does some wrangling to keep just the name.
#' These course names are a polished version of the course names (with capitalization, without underscores, etc.)
#' This follows the steps from the AnVIL Collection process.
#' Then it uses `get_linkOI()` to extract the Coursera and Leanpub links.
#' If trying the `index.Rmd` file wasn't successful, we assume it's a quarto course and so we check
#' the _quarto.yml file for the course name and the index.qmd file for the course formats, adapting the steps above.
#'
#' @param df an input dataframe with the GitHub queried data
#'
#' @import stringr
#'
#' @return df with 3 new columns (CourseName, CourseraLink, LeanpubLink) filled in with NAs or the relevant info

get_book_info <- function(df){
  # Create stand in columns
  df$CourseName <- ""
  df$CourseraLink <- ""
  df$LeanpubLink <- ""

  if (nrow(df) >=1){
    for (i in 1:nrow(df)) {

      # Make raw content url
      base_url <- make_raw_content_url(df[i,]$html_url)

      # Determine if the index.Rmd file can be read
      try_url <- try(readLines(paste0(base_url, "/main/index.Rmd")), silent = TRUE)

      # If try was ok, continue reading index file -- we'll get course formats from these
      if (class(try_url) != "try-error") {
        index_data <- readLines(paste0(base_url, "/main/index.Rmd"))

        # Get book metadata
        metadata_lines <- grep("---", index_data)
        book_metadata <-
          index_data[(metadata_lines[1] + 1):(metadata_lines[2] - 1)] #grab the line directly after the first `---` and the line right before the second `---`

        # Extract title
        CourseName <-
          book_metadata[grep("^title:",  book_metadata)] #may have a subtitle, so need `^` to find the title specifically

        # Strip extra characters
        CourseName <- str_replace(CourseName, 'title: \"', '')
        CourseName <- str_replace(CourseName, '\"', '')

        # Append
        df$CourseName[i] <- CourseName

        print(CourseName)

        # Get Available Course Format Links

        df$CourseraLink[i] <- get_linkOI("Coursera", index_data)
        df$LeanpubLink[i] <- get_linkOI("Leanpub", index_data)

      } else { #if try-error for `index.Rmd`, assume quarto course
        # Determine if the _quarto.yml file can be read
        try_url_quartoTitle <- try(readLines(paste0(base_url, "/main/_quarto.yml")), silent = TRUE)

        if (class(try_url_quartoTitle) != "try-error") {
          yml_data <- readLines(paste0(base_url, "/main/_quarto.yml"))

          #get title from _quarto.yml and strip extra characters
          CourseName <-
            str_trim(str_replace(yml_data[grep("title:",  yml_data)], "title:", ''))

          # Append
          df$CourseName[i] <- CourseName

        } else {
          message("No course title added to this last chunk after checking `index.Rmd` and `_quarto.yml`")
        }
        # Determine if the _index.qmd file can be read
        try_url_indexqmd <- try(readLines(paste0(base_url, "/main/index.qmd")), silent = TRUE)

        if (class(try_url_indexqmd) != "try-error") {
          index_qmd_data <- readLines(paste0(base_url, "/main/index.qmd"))

          # Get Available Course Format Links
         df$CourseraLink[i] <- get_linkOI("Coursera", index_qmd_data)
         df$LeanpubLink[i] <- get_linkOI("Leanpub", index_qmd_data)

        } else {
          message("No available course information added to this last chunk after checking `index.Rmd` and `index.qmd`")
        }
      } #end trying to find quarto information
    } #end for loop
  } else { message("No relevant resources, so no data added")} #end if not at least one row
  return(df)
}

#' This function is meant to identify which line in a code chunk has the ottrpal::include_slide function
#'
#' @description All courses have a relevant tag on the first line of the chunk. Most have the ottrpal::include_slide function on the line directly after this,
#' but at least one has a blank line between these two elements. This function specifically is meant to identify if the first line has the ottrpal function or
#' instead a blank line, returning a 1 or 2 respectively.
#'
#' @param char_vec this is a vector of characters from readLines
#' @param line_with_tag this is the numeric index of the line/element in char_vec that has the tag of interest (e.g., "for_individuals_who")
#'
#' @return 1 or 2, is it the first or second line in the chunk with the ottrpal function and slide link

find_line_of_interest <- function(char_vec, line_with_tag){
  data_of_interest <- char_vec[(line_with_tag+1):(line_with_tag+2)] #grab the first and second lines after the line with the tag
  return(grep("include_slide", data_of_interest)) #should return a 1 or 2, expecting 1 for nearly every course expect for Computing for Cancer Informatics
}

#' This function extracts the URL of a specific slide from an R code chunk
#'
#' @description All courses have a relevant tag on the first line of the chunk adding a visual/slide for audience, topics covered, learning objectives, or prereqs (if applicable)
#' This function uses grep with the relevant tag to find the chunk, `find_line_of_interest()`, and str_replace() to return the URL
#'
#' @param tag_of_interest a character used to tag the r code chunk and what we search to identify the code chunk (e.g., "for_individuals_who", "topics_covered", "learning_objectives" )
#' @param char_vec this is a vector of characters from readLines
#' @param first_url_replacement default is 'ottrpal::include_slide("' (with escapes "\\", "\" as necessary), string will be replaced with ""
#' @param second_url_replacement default is '")' (with escapes "\", "\\" as necessary), string will be replaced with ""
#'
#' @import stringr
#'
#' @return the slide URL

extract_slide_url <- function(tag_of_interest, char_vec, first_url_replacement = 'ottrpal::include_slide\\(\"', second_url_replacement = '\"\\)'){
  if(sum(grepl(tag_of_interest, char_vec)) >= 1){ #if data not available
    relevant_lines <- grep(tag_of_interest, char_vec)
    data_of_interest <- str_replace(char_vec[relevant_lines+find_line_of_interest(char_vec, relevant_lines)], first_url_replacement, "")
    return(str_replace(data_of_interest, second_url_replacement, ""))
  } else {return(NA_character_)}
}

# -------- Function to get slide URL info ----------

#' A function to traverse the GitHub queried data and extract visual/slide info (audience, concepts discussed, learning objectives, or prereqs if applicable) for each course
#'
#' @description This function parallels the get_book_info() function
#' This function creates the relevant stand in columns and is meant for batches of github repos, dealing with each github repo in the batch individually
#' uses `make_raw_content_url()` with the `html_url` column to build the prefix of the raw content URL (`base_url`)
#' If the course isn't one of 3 that uses less predictable ways to add this intro/background info ("AI for Decision Makers", "Data Management and Sharing for NIH Proposals", "AI for Efficient Programming")
#' Then it uses this base_url together with `01-intro.Rmd` on the main branch to try to read the file. If that file is there and can be read,
#' we read it in using `readLines()` and then goes about getting the slide URLs with extract_slide_url()
#' If trying the `index.Rmd` file wasn't successful, we assume it's a quarto course and so we check `01-intro.qmd`
#' For the 3 courses listed above, this function uses alternative approaches to check specific files for Data Management and Sharing and AI for Efficient Programming.
#' We use a completely different function after all the batches have been processed to add the slide URLs (in new rows) for AI for Decision Makers (add_rows_with_slides_AIDM())
#'
#' @param df an input dataframe with the GitHub queried data
#'
#' @return df with 4 new columns (concepts_slide, lo_slide, for_slide, prereq_slide) filled in with NAs or the relevant info

get_slide_info <- function(df){

  df$concepts_slide <- ""
  df$lo_slide <- ""
  df$for_slide <- ""
  df$prereq_slide <- ""

  if (nrow(df) >=1){
    for (i in 1:nrow(df)) {
      # Make raw content url
      message(paste0("Slides for ", df$CourseName[i]))
      base_url <- make_raw_content_url(df[i,]$html_url)
      if (!(df$CourseName[i] %in% c("AI for Decision Makers", "Data Management and Sharing for NIH Proposals", "AI for Efficient Programming"))){

        # Determine if the index.Rmd file can be read
        try_url <- try(readLines(paste0(base_url, "/main/01-intro.Rmd")), silent = TRUE)

        # If try was ok, continue reading index file -- we'll get slide URLs from these
        if (class(try_url) != "try-error") {
          intro_data <- readLines(paste0(base_url, "/main/01-intro.Rmd"))
        } else { #if 01-intro.Rmd doesn't exist
          try_urlQmd <- try(readLines(paste0(base_url, "/main/01-intro.qmd")), silent = TRUE) #try 01-intro.qmd (for Containers course)

          if (class(try_urlQmd) != "try-error") {
            intro_data <- readLines(paste0(base_url, "/main/01-intro.qmd"))
          } else {
            intro_data <- ""
            message("No available course information added to this last chunk after checking `01-intro.Rmd` and `01-intro.qmd`")
          }
        }

        if (sum(intro_data != "") > 1) { #if blank data, don't check it

          df$concepts_slide[i] <- extract_slide_url("topics_covered" , intro_data)
          df$lo_slide[i] <- extract_slide_url("learning_objectives", intro_data)
          df$for_slide[i] <- extract_slide_url("for_individuals_who", intro_data)
          df$prereq_slide[i] <- extract_slide_url("prereqs", intro_data)

        } else {
          df$concepts_slide[i] <- NA_character_
          df$lo_slide[i] <- NA_character_
          df$for_slide[i] <- NA_character_
          df$prereq_slide[i] <- NA_character_

          }#close if of making sure intro data has things to grep from
      } else {
        message("Employing alternative checking methods")
        #check NIH specific files, Efficient specific files
        if (df$CourseName[i] == "AI for Efficient Programming"){

          try_urlIndex <- try(readLines(paste0(base_url, "/main/index.Rmd")), silent = TRUE) #try index.Rmd

          if (class(try_urlIndex) != "try-error") {
            intro_data <- readLines(paste0(base_url, "/main/index.Rmd"))
            df$concepts_slide[i] <- extract_slide_url("topics_covered" , intro_data)
            df$lo_slide[i] <- extract_slide_url("learning_objectives", intro_data)
            df$for_slide[i] <- extract_slide_url("for_individuals_who", intro_data)
            df$prereq_slide[i] <- extract_slide_url("prereqs", intro_data)
          } else {
            message(paste0("No slide data found for ", df$CourseName[i]))
            df$concepts_slide[i] <- NA_character_
            df$lo_slide[i] <- NA_character_
            df$for_slide[i] <- NA_character_
            df$prereq_slide[i] <- NA_character_
          }
        } else if (df$CourseName[i] == "AI for Decision Makers"){
          message("Handling this course in another function that will add in rows")
          df$concepts_slide[i] <- NA_character_
          df$lo_slide[i] <- NA_character_
          df$for_slide[i] <- NA_character_
          df$prereq_slide[i] <- NA_character_
        } else { #NIH for Data Sharing course
          try_urlIndex <- try(readLines(paste0(base_url, "/main/index.Rmd")), silent = TRUE) #try index.Rmd
          try_urlLO <- try(readLines(paste0(base_url, "/main/Learning_objectives.Rmd")), silent = TRUE) #try LearningObjectives.Rmd

          if((class(try_urlIndex) != "try-error") & (class(try_urlLO) != "try-error")){
            intro_data <- c(readLines(paste0(base_url, "/main/index.Rmd")), readLines(paste0(base_url, "/main/Learning_objectives.Rmd")))
            df$concepts_slide[i] <- extract_slide_url("topics_covered" , intro_data)
            df$lo_slide[i] <- extract_slide_url("learning_objectives", intro_data)
            df$for_slide[i] <- extract_slide_url("for_individuals_who", intro_data)
            df$prereq_slide[i] <- extract_slide_url("prereqs", intro_data)
          } else {
            message(paste0("No slide data found for ", df$CourseName[i]))
            df$concepts_slide[i] <- NA_character_
            df$lo_slide[i] <- NA_character_
            df$for_slide[i] <- NA_character_
            df$prereq_slide[i] <- NA_character_
          }
        } #end the if else if and else chain for the specific coursers
      } #end else looking at specific courses
    } #end for loop
  } else { message("No relevant resources, so no data added")} #end if not at least one row
  return(df)
}

#' This function constructs the full URL for accessing the raw content of a specific file on a branch
#'
#' @description The AI for Decision Makers course has the tagged R code chunks grabbing intro slides/visuals on non-main branches
#' so this function takes in the info about the branch name and file of interest to get the URL of accessing the raw content of that file
#'
#' @param base_url This is the base url that is constructed with `make_raw_content_url()`
#' @param filename The name of the file we want to access
#' @param branch The name of the branch that we want to access
#'
#' @return the full URL for a specific file on a branch

make_branch_file_url <- function(base_url, filename, branch = "/main/"){
  return(paste0(base_url, "/refs/heads/", branch, filename))
}

#' This function tries to read the file on a specific branch and drives extracting the URLs and adding them to the input df
#'
#' @param base_url This is the base url that is constructed with `make_raw_content_url()`
#' @param i which row/which course index (the courses are already numbered, and these numbers are part of the file names)
#' @param subcourseName the subcourse name is also part of the overall file name
#' @param branch_name the name of the branch that the updated file with tags of interest is on
#' @param to_bind_df the dataframe where the info about these AI subcourses is being stored with the course index being aligned with the subcourse filename/number
#'
#' @return to_bind_df with the specific row (i) filled out

try_and_add_branch <- function(base_url, i, subcourseName, branch_name, to_bind_df){
  branch_file <- make_branch_file_url(base_url, paste0("0", i, "a-", subcourseName, "-intro.Rmd"), branch = branch_name)
  try_AI_url <- try(readLines(branch_file), silent = TRUE)

  if(class(try_AI_url) != "try-error"){
    intro_data <- readLines(branch_file)
    to_bind_df[i,]$lo_slide <- extract_slide_url("learning_objectives", intro_data)
    to_bind_df[i,]$for_slide <- extract_slide_url("for_individuals_who", intro_data)
    to_bind_df[i,]$concepts_slide <- extract_slide_url("topics_covered", intro_data)
  } else{
    to_bind_df[i,]$lo_slide <- NA_character_
    to_bind_df[i,]$for_slide <- NA_character_
    to_bind_df[i,]$concepts_slide <- NA_character_
  }

  return(to_bind_df)
}

#' This function drives making new rows to add to the overall dataframe for the AI subcourses
#'
#' @description create a new dataframe for the subcourse slides with matching column names as appropriate to the original df
#' For each subcourse use `try_and_add_branch()` to extract and store the slide info for each subcourse.
#' bins the rows the of new dataframe to the overall dataframe and returns thats
#'
#' @param df the overall dataframe with the processed Github API query info
#'
#' @import dplyr
#'
#' @return df with four new rows for the AI for Decision Makers subcourses and their intro slides/visual info

add_rows_with_slides_AIDM <- function(df){
  base_url <- make_raw_content_url(df[which(df$CourseName == "AI for Decision Makers"),]$html_url)
  to_bind_df <- data.frame(CourseName = c("AI for Decision Makers: Exploring AI Possibilities",
                                          "AI for Decision Makers: Avoiding AI Harm",
                                          "AI for Decision Makers: Determining AI Needs",
                                          "AI for Decision Makers: Developing AI Policy"),
                           lo_slide = c("", "", "", ""),
                           for_slide = c("", "", "", ""),
                           concepts_slide = c("", "", "", ""),
                           prereq_slide = NA_character_
                          )

  to_bind_df$name <- to_bind_df$CourseName

  #Exploring AI Possibilities: https://raw.githubusercontent.com/fhdsl/AI_for_Decision_Makers/refs/heads/ah/add-slides/01a-AI_Possibilities-intro.Rmd
  to_bind_df <- try_and_add_branch(base_url, 1, "AI_Possibilities", "ah/add-slides/", to_bind_df)

  #Avoiding AI Harm: https://raw.githubusercontent.com/fhdsl/AI_for_Decision_Makers/refs/heads/cw_add_slides/02a-Avoiding_Harm-intro.Rmd
  to_bind_df <- try_and_add_branch(base_url, 2, "Avoiding_Harm", "cw_add_slides/", to_bind_df)

  #Determining AI Needs: https://raw.githubusercontent.com/fhdsl/AI_for_Decision_Makers/refs/heads/ai_needs_slides/03a-Determining-AI-Needs-intro.Rmd
  to_bind_df <- try_and_add_branch(base_url, 3, "Determining-AI-Needs", "ai_needs_slides/", to_bind_df)

  #Developing AI Policy: https://raw.githubusercontent.com/fhdsl/AI_for_Decision_Makers/refs/heads/EMH-add-intro-to-policy-course/04a-AI_Policy-intro.Rmd
  to_bind_df <- try_and_add_branch(base_url, 4, "AI_Policy", "EMH-add-intro-to-policy-course/", to_bind_df)

  df <- dplyr::bind_rows(df, to_bind_df)
  return(df)
}

# Everything below here drives the process of querying GitHub
# keeping the repos we want,
# processing the topic tags from the repos,
# getting the book info (course name, coursera link, and leanpub link)
# getting the slide info for individual course pages (audience, concepts covered, learning objectives, etc.) (excluding AI for Decision Makers)
# The steps above are done for each page of the GitHub API query results
# after that, there's a full df for all the repos we want that undergoes a bit more wrangling to clean up the topics,
# adds the AI for Decision Makers slides
# and renames a few columns
# finally saves the collection
# --------- Set url and token ---------

message(paste("Querying Github API..."))

# Request search results specific to jhudsl + fhdsl organizations
# Also allows us to pull in repos forked into these organizations
url <-
  "https://api.github.com/search/repositories?q=user:jhudsl+user:fhdsl+fork:true&per_page=50"

# Provide the appropriate GH token & Make the request
req <-
  GET(url = url, config = add_headers(Authorization = paste("token", git_pat)))

if (!(httr::http_error(req))) {
  message(paste("API request successful!"))
} else {
  stop("API request failed!")
}

# --------- Traverse pages ---------

# Pull out the last page number of the request
last <-
  str_extract(req$headers$link, pattern = '.(?=>; rel=\"last\")')

full_repo_df <- tibble()
for (page in 1:last) {
  url <-
    paste0(
      "https://api.github.com/search/repositories?q=user:jhudsl+user:fhdsl+fork:true&per_page=50&page=",
      page
    )
  message(paste("Gathering results from:", url))
  req <-
    GET(url = url, config = add_headers(Authorization = paste("token", git_pat)))
  repo_dat <-
    jsonlite::fromJSON(httr::content(req, as = "text"), flatten = TRUE)
  message(paste("... Gathered", nrow(repo_dat$items), "repositories."))

  repo_df <-
    tibble(repo_dat$items) %>%
    select(full_name, homepage, html_url, description, private) %>%
    separate(full_name, into = c("org", "name"), sep = "/") %>%

    # Collapse topics so they can be printed
    bind_cols(tibble(topics = unlist(
      lapply(repo_dat$items$topics, paste, collapse = ", ")
    ))) %>%

    # Drop private repos and remove org column
    filter(!(private)) %>%
    select(!c(private, org)) %>%

    # Rearrange columns
    relocate(description, .before = topics) %>%

    # Keep only those with homepages and descriptions
    filter(!(is.na(homepage)), homepage != "",!(is.na(description))) %>%

    # Keep only ITN course related content
    # Exclude templates
    mutate(is_itn = str_detect(topics, "itn")) %>%
    mutate(is_course = str_detect(topics, "course")) %>%
    mutate(is_template = str_detect(topics, "template ")) %>% #add a space to the str_detect because a few topic tags are "templates"
    filter(is_itn) %>%
    filter(is_course) %>%
    filter(!is_template) %>%
    mutate(aud_sd = case_when(str_detect(topics, "audience-software-developers") ~ "Software Developers",
                              !str_detect(topics, "audience-software-developers") ~ NA_character_),
           aud_l = case_when(str_detect(topics, "audience-leaders") ~ "Leaders",
                             !str_detect(topics, "audience-leaders") ~ NA_character_),
           aud_r = case_when(str_detect(topics, "audience-researchers") ~ "Researchers",
                             !str_detect(topics, "audience-researchers") ~ NA_character_)
           ) %>%
    tidyr::unite(col = "BroadAudience", starts_with("aud_"), sep = ";", na.rm = TRUE) %>%
    mutate(cat_ftr = case_when(str_detect(topics, "category-fundamentals-") ~ "Tools & Resources",
                               !str_detect(topics, "category-fundamentals-") ~ NA_character_),
           cat_sd = case_when(str_detect(topics, "category-software-dev") ~ "Software Development",
                              !str_detect(topics, "category-software-dev") ~ NA_character_),
           cat_bp = case_when(str_detect(topics, "category-best-practices") ~ "Best Practices",
                              !str_detect(topics, "category-best-practices") ~ NA_character_),
           cat_hop = case_when(str_detect(topics, "category-hands-on-") ~ "Hands-on Practice",
                               !str_detect(topics, "category-hands-on-") ~ NA_character_)
           ) %>%
    tidyr::unite(col = "Category", starts_with("cat_"), sep=";", na.rm = TRUE) %>%
    mutate(hutch_funding = str_detect(topics, "hutch-course")) %>%
    mutate(launch_date = topics) %>%
    tidyr::separate_longer_delim(launch_date, delim = ", ") %>%
    filter(str_detect(launch_date, "launched-")) %>%
    mutate(launch_date = str_replace(launch_date, "launched-", "")) %>%
    mutate(launch_date = str_to_title(str_replace(launch_date, pattern = "(.{3})(.*)", replacement = "\\1 \\2"))) %>%

    get_book_info() %>%
    get_slide_info()


    full_repo_df <- rbind(full_repo_df, repo_df)
}

#batch processing of the github API results is above like the example from AnVIL collection
#below, once they've all been processed to extract itn courses, category, audience, funding, launch date, course name, available course formats, and intro slide/visual URLs
#then we clean up the topics column and create concepts and add the intro slide/visual information for the AI for Decision Makers subcourses and rename a couple of columns

full_repo_df <- full_repo_df %>%
  tidyr::separate_wider_delim(topics, delim=", ", names_sep = "_", too_few = "align_start") %>%
  mutate(across(starts_with("topics_"), ~replace(., str_detect(., "audience-|category-|course$|launched-|data4all|reproducible-research|^reproducibility$"), NA))) %>%
  tidyr::unite("Concepts", starts_with("topics_"), sep=';', na.rm = TRUE) %>%
  add_rows_with_slides_AIDM() %>%
  rename(GithubLink = html_url) %>%
  rename(BookdownLink = homepage) #already available from the API calls, so don't need to extract it in get_book_info, just renaming it

# ---------- Save the collection ---------

# Create an artifact file containing the repos, else write an empty file
if (!dir.exists("resources")){
  dir.create("resources")
}
if (nrow(full_repo_df) > 0){
  readr::write_tsv(full_repo_df, file.path('resources', 'collection.tsv'))
} else {
  readr::write_tsv(tibble(), file.path('resources', 'collection.tsv'))
}
