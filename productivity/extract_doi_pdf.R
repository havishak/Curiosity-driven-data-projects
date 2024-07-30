# Install the pdftools package
install.packages("pdftools")

# Load the pdftools package
library(pdftools)
library(stringr)
library(tidyr)

# Step 1 - get citations
# Step 2 - get bibtex: from google scholar or doi to bibtext converter?
# ISBN, DOI, PMID, arXiv, or ADS

b2b_results_url <- "https://search.worldcat.org"

# see rules for scraping on the page and other bots information
results_session <- bow(b2b_results_url,
                       user_agent = "HK result scraping",
                       force = TRUE)

results_session # we have the permission to scrape!

# Idea - get DOIs which can then me imported in Zotero. Other's can't be but you can get a list of citations

# Specify the path to your PDF file
pdf_path <- "C:/SDXC/University of Oregon Dropbox/Havi Khurana/Courses/2023_03_Spring/EDLD 631 Multilingual students/syllabus.pdf"

# Extract text from the PDF
pdf_text_content <- pdf_text(pdf_path)

# Combine all pages into a single text
all_text <- paste(pdf_text_content, collapse = "\n")

# Print the combined text
cat(all_text)


lines <- unlist(strsplit(all_text, "\n\n"))


# Define a regular expression pattern for APA citations
# This pattern matches common APA citation formats
citation_identifier <- "\\(\\d{4}[a-z]?\\)"

# Find all matches in the text
citations <- lines[stringr::str_detect(lines, citation_pattern)]

citations <- gsub(pattern = "\\s{2,}", "", citations)
citations <- gsub(pattern = "\n", " ", citations)

# Define a regular expression pattern for DOIs
doi_pattern <- "\\b10\\.[0-9]{4,}(?:\\.[0-9]+)*/[^\\s]+\\b"

# Find all matches in the text
dois <- stringr::str_extract_all(all_text, doi_pattern)

# Flatten the list of matches into a single vector
dois <- unlist(dois)

# Print the extracted DOIs
print(dois)

citation_doi  <- stringr::str_detect(citations, doi_pattern)

citation_df <- tibble(
    citations = citations,
    doi_found = citation_doi,
    doi = ifelse(doi_found == TRUE, 
                 str_extract(citations, doi_pattern), NA))
citation <- citation_df$citations[3]

author <- gsub("\\s*\\(\\d{4}\\).*", "", citation)
author <- gsub(" & ","", author)
# new name is after the even comma


# Add DOIs separated by comma
# For some reasons, it isn't able to find pdfs to download when entering DOI - check adn see.


library(stringr)

# Sample APA citations
citations <- c(
    "Smith, J. A. & Khurana, H. (2020). The study of something important. *Journal of Important Studies*, 10(2), 123-145. https://doi.org/10.1234/abcd.efghij",
    "Doe, J., & Roe, R. (2019). Another groundbreaking research. *Science Journal*, 15(3), 234-256. https://doi.org/10.5678/wxyz.abcd"
)

# Function to extract citation details
extract_citation_details <- function(citation) {
    # Regular expressions to extract different parts of the citation
    author_pattern <- "^([A-Za-z,\\. ]+)"
    year_pattern <- "\\((\\d{4})\\)"
    title_pattern <- "\\)\\. ([^\\.]+)\\. \\*([^\\*]+)\\*"
    journal_pattern <- "\\*([^\\*]+)\\*"
    doi_pattern <- "https://doi\\.org/([\\w\\./]+)"
    
    # Extracting details
    authors <- str_extract(citation, author_pattern)
    year <- str_extract(citation, year_pattern)
    year <- str_replace(year, "[()]", "") # Remove parentheses
    title <- str_extract(citation, title_pattern)
    title <- str_replace(title, "\\. \\*.*", "") # Remove journal part
    journal <- str_extract(citation, journal_pattern)
    doi <- str_extract(citation, doi_pattern)
    
    # Return as a named list
    list(
        Authors = authors,
        Year = year,
        Title = title,
        Journal = journal,
        DOI = doi
    )
}

# Apply the function to each citation
citation_details <- lapply(citations, extract_citation_details)

# Convert the list to a data frame
citation_df <- do.call(rbind, lapply(citation_details, as.data.frame))
rownames(citation_df) <- NULL

# Print the result
print(citation_df)

