# load libraries
library(tidyverse)
library(sf)
library(rnaturalearth)

orcas <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-10-15/orcas.csv')

# Clean orcas: I want to visualize monthly spotting path patterns

orcas <- orcas |>
    mutate(encounter_month = month(date),
           encounter_day = day(date),
           duration_sec = (parse_number(duration)),
           encounter_month = factor(encounter_month,
                                    levels = 1:12,
                                    labels = month.name)) |>
    # removing negative encounters
    filter(duration_sec > 0) |>
    drop_na(date, duration_sec, begin_latitude) |>
    group_by(encounter_month) |>
    mutate(
        longest_encounter = ifelse(duration_sec == max(duration_sec), 1, 0),
        longest_encounter_text = ifelse(longest_encounter == 1, 
                                        paste0(duration_sec, " sec on day ", encounter_day, ", ", year), NA)
    ) |>
    ungroup()

# get map
worldmap <- ne_countries(scale = 'medium', type = 'map_units',
                         returnclass = 'sf')

#, shape = "🦈", size = 2
plot <- ggplot(orcas) +

geom_rect(aes(xmin = min(orcas$begin_longitude, na.rm = T)*1.01, 
              xmax = max(orcas$begin_longitude, na.rm = T)*0.99, 
              ymin = min(orcas$begin_latitude, na.rm = T)*0.99, 
              ymax = max(orcas$begin_latitude, na.rm = T)*1.01),  # Global background
              fill = "lightblue") +
geom_sf(data = worldmap, color = "gray90", fill = "gray96") +
    coord_sf(xlim = range(orcas$begin_longitude, na.rm = T)*c(1.01, 0.99), 
             ylim = range(orcas$begin_latitude, na.rm = T)*c(0.99, 1.01), expand = FALSE) +
    theme_void(12) +
    geom_segment(aes(x = begin_longitude, y= begin_latitude, xend = end_longitude, yend = end_latitude
                                   , alpha = duration_sec > 6400, color = longest_encounter == 1
                                   )) +
    geom_point(data = filter(orcas, longest_encounter == 1) |> distinct(encounter_month, longest_encounter, .keep_all = TRUE), aes(x = begin_longitude, y= begin_latitude), shape = "🦈", size = 2)+
    geom_text(data = filter(orcas, longest_encounter == 1) |> distinct(encounter_month, longest_encounter, .keep_all = TRUE), 
              aes(x = -125.4, y= 47.7, label = str_wrap(longest_encounter_text,15), color = longest_encounter == 1), size = 2.5, family = "Noto Sans", fontface = "bold")+
    scale_color_manual(
        values = c("purple4", "orange2")
    )+
    scale_alpha_manual(values = c(0.3, 0.7))+
    labs(
        title = "Monthly Orca Encounters in the Salish Sea (2017-2024)",
        subtitle = str_wrap("The straight lines represent orca encounter paths, with bolder lines marking encounters lasting over two hours and colors highlighting the longest one. September stands out as the peak month, featuring both more frequent and longer encounters.", 100),
        caption = "Source: Center for Whale Research (CWR)"
    ) +
    facet_wrap(~encounter_month) +
    theme(
        legend.position = "none",
        text = element_text(family = "Noto Sans"),
        plot.margin = margin(.5, .5, .5, .5, "cm"),
        plot.background = element_rect(fill = "azure", color = NA)
    )

ggsave("products/tt_oct1524_orca.jpeg", width = 8, height = 6)
