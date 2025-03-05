set.seed(100)
# the ones i didn't do
sample(c(48:53, 1:4, 6:7),1)

# Doing water insecurity visualization
library(tidyverse)
library(usmap)
library(tigris)
library(patchwork)
library(showtext)

# Load Google Font
font_add_google("Quicksand", "qs")
showtext_auto()

# get us counties
us_counties <- counties(cb = TRUE,
                        resolution = "20m",
                        class = "sf") %>%
    janitor::clean_names() %>%
    count(state_name)

# read data
water_insecurity_2022 <- readr::read_csv(
    'https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-01-28/water_insecurity_2022.csv'
) %>%
    mutate(
        with_plumbing = 100 - percent_lacking_plumbing,
        state = gsub("(.*),\\s(.*)", "\\2", name)
    ) %>%
    
    # join with counties for proportion of counties in dataset
    left_join(us_counties, by = c("state" = "state_name")) %>%
    group_by(state) %>%
    mutate(counties_state = n(),
           avg_plumbing = mean(with_plumbing, na.rm = T),
           per_counties = counties_state/n)

states <- water_insecurity_2022 %>%
    distinct(n, state, per_counties, avg_plumbing)

states %>%
    arrange(desc(per_counties), desc(avg_plumbing))

states_max <- "New Jersey"
states_min <- "Arizona"

plot_max <- plot_usmap(regions = "counties",  include = states_max, 
           data = water_insecurity_2022 %>% rename("fips" = "geoid"), values = "with_plumbing",
           color = "gray80") +
    scale_fill_viridis_c(option = "mako", na.value = "transparent",
                         limits = c(96,100), direction = -1) +
    theme_void() +
    labs(title = states_max,
         fill = "Avg Plumbing") +
    theme(
        text = element_text(family = "qs", size =16),
        plot.title = element_text(hjust = 0.5),
        #legend.position = "bottom",
        plot.background = element_rect(fill = "gray90", color = "transparent")
    )

plot_min <- plot_usmap(regions = "counties",  include = states_min, 
           data = water_insecurity_2022 %>% rename("fips" = "geoid"), values = "with_plumbing",
           color = "gray80") +
    scale_fill_viridis_c(option = "mako", na.value = "transparent",
                         limits = c(96,100),
                         direction = -1) +
    theme_void() +
    labs(title = states_min,
         fill = "Avg Plumbing")+
    theme(
        plot.title = element_text(hjust = 0.5),
        text = element_text(family = "qs", size = 16),
        #legend.position = "bottom",
        plot.background = element_rect(fill = "gray90", color = "transparent")
    )

final_plot <- plot_max + plot_min +
    plot_layout(guides = "collect") +
    plot_annotation(
        title = str_wrap("A Water Tale of Two States: Plumbing Access in the Most and Least Access States", 60),
        subtitle = str_wrap("In New Jersey, nearly 99.96% of county residents had plumbing, while in Arizona, this number dropped to around 99.27%."),
        caption = "Data from tidycensus for 2022, curated by Niha Pereira."
    ) &
    theme(
        text = element_text(color = "gray20", family = "qs", size = 20),
        legend.position = "bottom",
        plot.background = element_rect(fill = "gray90", color = "transparent"),
        plot.title = element_text(face = "bold", lineheight = 0.3),
        plot.subtitle = element_text(face = "italic", lineheight = 0.3),
        #plot.margin = margin(t = 10, r = 0, b = 10, l = -10)
    )

ggsave(plot = final_plot,"products/tt_01282025_water_insecurity.jpeg",
       width = 4.5, height = 4)

# fine, change text style