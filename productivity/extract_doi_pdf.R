# Load relevant package
library(pdftools)
library(tidyverse)

# this function converts a pdf_path to pdf_text
# combines all pages
# and breaks each part starting with a new line into its own object
# returns a character vector

pdf_to_text <- function(pdf_path){
    # Extract text from the PDF
    pdf_text_content <- pdf_text(pdf_path)
    
    # Combine all pages into a single text
    all_text <- paste(pdf_text_content, collapse = "\n")
    
    all_paragraphs <- unlist(strsplit(all_text, "\n\n"))
    
    return(all_paragraphs)
}


# this function finds all dois in the pdf
journal_doi <- function(pdf_path){
    
    # get text
    pdf_text <- pdf_to_text(pdf_path)
    
    # define doi pattern
    doi_pattern <- "\\b10\\.[0-9]{4,}(?:\\.[0-9]+)*/[^\\s]+\\b"
    
    # find doi in pdf text
    doi_found <-str_extract_all(pdf_text, doi_pattern) %>%
        unlist()
    
    return(doi_found)
}

# this function finds some of the common pre-print identifiers in the pdf
preprint_id <- function(pdf_path){
    
    # get text
    pdf_text <- pdf_to_text(pdf_path)
    
    # dictionary for common preprint indentifier starters
    # add more per need
    
    pre_print_pattern <- c(
        "arXiv" = "arXiv:([0-9]{4}\\.[0-9]{5})(v[0-9]+)?", # arXiv pattern
        "ssrn" = "SSRN:[0-9]+",                                   # SSRN pattern
        "repec" = "RePEc:[a-z]+:[a-z]+:[0-9]+",                    # RePEc pattern
        "starts_with_10" = "10\\.\\d{4,9}/[-._;()/:A-Z0-9]+"       
    )
    
    # find doi in pdf text
    id_found <-str_extract_all(pdf_text, 
                    reduce(pre_print_pattern, paste, sep = "|")) %>%
        unlist()
    
    return(id_found)
}

# choose citation pattern
# reading excel there are additional backslashes throughout
get_citation_pattern <- function(citation_style){
    
    # citation styles in Zotero and their format
    all_citation_styles <- readxl::read_excel("citation_styles/journal_citation_styles.xlsx")
    
    chosen_citation_styles <- all_citation_styles %>%
        filter(style == citation_style)
    
    if(nrow(chosen_citation_styles) == 0)
        print("Citation style not found in meta data")
        return(NA)
    
    citation_pattern <- chosen_citation_styles$regex_extraction_format
    citation_year_pattern <- chosen_citation_styles$year_format
    
    return(list(citation_year_pattern, citation_pattern))
}

# get meta data from citations

citation_metadata <- function(pdf_path, citation_style){
    
    # get citation pattern  
    citation_pattern <- get_citation_pattern(citation_style)
    
    # get pdf
    pdf_text <- pdf_to_text(pdf_path)
    
    # flag lines which have the year pattern as in citation styles
    citation_text <- str_extract_all(pdf_text, pattern = citation_pattern[[1]])
    
    # additional test: length should be smaller than 400 characters
    citation_text <- citation_text[str_length(citation_text) < 400]
    
    citation_parts <- str_match_all(citation_text,
                                    pattern = citation_pattern[[2]])
    
    return(citation_parts)
}

# pdf_path
pdf_text_content <- here::here("test_files/multilingual_syllabus.pdf")
preprint_id(pdf_text_content)

citation_style <- "American Psychological Association 7th edition"

get_citation_pattern(citation_style)
