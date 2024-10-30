#bubble map of internet users

library(tidyverse)
library(sf)
library(rnaturalearth)
library(stringdist)

cia_factbook <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-10-22/cia_factbook.csv') |>
    mutate(internet_per = internet_users/population*100) |>
    filter(!is.na(internet_per))

# get map
worldmap <- ne_countries(scale = 'medium', type = 'map_units',
                         returnclass = 'sf') |>
    select(name, geometry)

# dataset of country mapping

country_mapping <- data.frame(
    cia_name =  intersect(cia_factbook$country, worldmap$name),
    worldmap_name = intersect(cia_factbook$country, worldmap$name)
)

# fuzzy-match other countries

find_country_matches <- setdiff(cia_factbook$country, worldmap$name)
reference_countries <- setdiff(worldmap$name, cia_factbook$country)

# Fuzzy matching using Levenshtein distance
matches <- sapply(find_country_matches, function(x) {
    reference_countries[which.min(stringdist(x, reference_countries))]
})

fuzzy_matches <- data.frame(
    cia_name = names(matches),
    worldmap_name = unname(matches)
)

fuzzy_matches <- fuzzy_matches |>
    mutate(worldmap_name = case_when(
        cia_name == "United States"  ~ "United States of America",
        cia_name == "Burma"  ~ "Myanmar",
        cia_name == "Congo, Republic of the" ~ "Congo",
        cia_name == "United Kingdom" ~ "England",
        cia_name == "Korea, South" ~ "South Korea",
        cia_name == "Bosnia and Herzegovina" ~ "Rep. Srpska",
        cia_name == "Belgium" ~ "Brussels",
        cia_name == "Gibraltar" ~ NA_character_,
        TRUE ~ worldmap_name
    ))

country_mapping <- rbind(country_mapping, fuzzy_matches)

# joined dataset

plot_df <- country_mapping |>
    left_join(cia_factbook, by = c("cia_name" = "country")) |>
    left_join(worldmap, by = c("worldmap_name" = "name")) |>
    mutate(
        top_10 = rank(desc(internet_per)),
        bottom_5 = rank(internet_per),
        text_label = ifelse(top_10 < 11 | bottom_5 < 6,1,0),
        text_label = ifelse(text_label == 1, paste(cia_name, "\n", round(internet_per,1), "%"), 
                            NA_character_)
    )

plot_df$centroid <- st_centroid(plot_df$geometry)
plot_df$longitude <- unlist(plot_df$centroid)[seq(1, 426, 2)]
plot_df$latitude <- unlist(plot_df$centroid)[seq(2, 426, 2)]


ggplot(plot_df) +
    geom_sf(aes(geometry=geometry), fill='gray95', colour=NA) +
    geom_point(aes(x=longitude, y=latitude, size=internet_per, color=internet_per, alpha=internet_per),
               shape=20, stroke=FALSE) +
    ggrepel::geom_text_repel(aes(x=longitude, y=latitude, label = text_label),
               size = 2.5, max.overlap = 20, color = "gray30", family = "Helvetica",
               lineheight = 0.8) +
    scale_size_continuous(name='% Population\nUsing Internet',
                          range=c(3,8), breaks= c(1, 10, 25, 50, 90)) +
    scale_alpha_continuous(name='% Population\nUsing Internet',
                           range=c(0.3, .5), breaks= c(1, 10, 25, 50, 90)) +
    viridis::scale_color_viridis(option="magma", trans="log", breaks=c(1, 10, 25, 50, 90),
                        name='% Population\nUsing Internet') +
    theme_void() + coord_sf() + 
    guides( colour = guide_legend()) +
    labs(
        title = "Looking Back: World Internet Usage in 2014",
        subtitle = str_wrap("In 2014, 25% of the global population had internet access. By 2023, nearly two-thirds of the world’s population was online, reflecting the rapid growth of internet adoption.",70),
        caption = "Source: CIA Factbook for 2014"
    ) +
    theme(
        legend.position = c(0.8, 1.01),
        legend.direction = "horizontal",
        legend.title = element_text(size = 8, family = "Helvetica"),
        text = element_text(color = '#22211d', family = "Helvetica"),
        plot.background = element_rect(fill = 'azure', color = NA), 
        panel.background = element_rect(fill = 'azure', color = NA), 
        legend.background = element_rect(fill = 'azure', color = NA),
        plot.title = element_text(size= 16, color = '#2e2d27',face = 'bold'),
        plot.margin = margin(0, .1, 0, .1, "cm"),
    )

ggsave("products/tt_oct2224_ciadata.png", width = 9, height = 5)
