library(tidyverse)

countries <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-12/countries.csv')
country_subdivisions <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-12/country_subdivisions.csv')
former_countries <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-12/former_countries.csv') |>
    mutate(
        date_withdrawn = ifelse(nchar(date_withdrawn) == 4, 
                                date_withdrawn,
                                str_sub(date_withdrawn, 1, 4)))

# An analysis of 31 changes into the codes
# Same numeric code but different names: 10 - change of name
# Some comments suggest split-ups: 7
# Different numeric code and names: 
# Integrated into other countries:
# Cease to exist

# renamed countries
same_numeric <- tibble(
    numeric = intersect(unique(former_countries$numeric), unique(countries$numeric))) |>
    left_join(former_countries, by = 'numeric') |>
    select(numeric, name, date_withdrawn) |>
    rename("former_name" = name) |>
    left_join(select(countries, numeric, name), by = "numeric") |>
    rename("curernt_name" = name) 

# became country_subdivision
same_name <- tibble(
    name = intersect(former_countries$name, 
                     country_subdivisions$name)) |>
    left_join(former_countries, by = 'name') |>
    select(numeric, alpha_3, name, date_withdrawn) |>
    rename("former_alpha3" = alpha_3) |>
    left_join(select(country_subdivisions,name, code), by = "name") |>
        rename("current_code" = code)
  
# countries that split  
split <- former_countries |>
    filter(!is.na(comment)) |>
    select(name, date_withdrawn)
            
# unaccounted
unaccounted <- former_countries |>
    filter(!name %in% c(same_numeric$former_name, 
                        same_name$name, split$name)) |>
    select(name, date_withdrawn)

# Some hand corrections - add countries that split
split <- split |>
    rbind(unaccounted[c(2:3,11),])

unaccounted <- unaccounted[-c(2:3,11),]

# Countries that merged with others
merged <-  unaccounted[c(2,3:4, 7:10),]

unaccounted <- unaccounted[-c(2,3:4, 7:10),]


ggplot(same_numeric) +
    geom_segment(aes(x = parse_number(date_withdrawn), 
                     y = 0.5, yend = 1), color = "violet") +
    scale_x_continuous(limits = c(1970, 2010),
                       breaks = seq(1970, 2010, 10)) +
    scale_y_continuous(limits = c(0.25,1),
                       breaks = 0.25)+
    coord_polar(start = 0) +
    theme_minimal() +
    theme(
        axis.title = element_blank(),
        axis.text.y = element_blank())
