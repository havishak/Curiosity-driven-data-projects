library(tidyverse)
library(ggsankey)
library(showtext)

font_add_google("Montserrat", "montserrat")
showtext_auto()

democracy_data <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-05/democracy_data.csv')

election_category_by_year <- democracy_data |>
    count(year, electoral_category) |>
    ungroup() |>
    filter(!is.na(electoral_category)) |>
    mutate(electoral_category = str_to_title(electoral_category),
           electoral_category = factor(electoral_category))

# text_df <- election_category_by_year |>
#     filter(year == 1950 | year == 2020) |>
#     mutate(
#         percent = n/lenght(unique(democracy_data$country_code)),
#         label = paste0(n_)
#     )
    
plot <- ggplot(election_category_by_year,
    aes(x = year,
        node = electoral_category,
        fill = electoral_category,
        group = electoral_category,
        value = n,
        label = n)) +
    geom_sankey_bump(space = 0,
                     type = "alluvial", 
                     color = "transparent", smooth = 4, alpha = 0.8) +
    #scale_fill_viridis_d(option = "A", alpha = .8) +
    scale_x_continuous(breaks = seq(1950, 2020, 10)) +
    theme_sankey_bump(base_size = 16) +
    theme(legend.position = "bottom") 

# Create labels at the starting point for each electoral category
g_labs_start <- ggplot_build(plot) %>% 
    .$data %>% 
    .[[1]] %>% 
    group_by(group) %>% 
    filter(x == min(x)) %>% 
    reframe(
        x,
        y = mean(y)
    ) %>% 
    distinct() %>%
    mutate(label = levels(election_category_by_year$electoral_category)) %>%
    left_join(election_category_by_year %>% filter(year == 1950), 
              by = c("label" = "electoral_category"))

# Create labels at the ending point for each electoral category
g_labs_end <- ggplot_build(plot) %>% 
    .$data %>% 
    .[[1]] %>% 
    group_by(group) %>% 
    filter(x == max(x)) %>% 
    reframe(
        x,
        y = mean(y)
    ) %>% 
    distinct() %>%
    mutate(label = levels(election_category_by_year$electoral_category)) %>%
    left_join(election_category_by_year %>% filter(year == 2020), 
              by = c("label" = "electoral_category"))


g_labs_end[g_labs_end$group == 2,]$y <- 20

# Final plot
ggplot() +
    # Sankey bumps
    geom_sankey_bump(data = election_category_by_year,
                     aes(x = year,
                         node = electoral_category,
                         fill = electoral_category,
                         group = electoral_category,
                         value = n,
                         label = electoral_category),
                     space = 0,
                     type = "alluvial", 
                     color = "transparent", smooth = 4, alpha = 0.8) +
    # Left-side labels
    geom_label(data = g_labs_start, aes(x, y, label = str_wrap(paste(label, "·", n),17), 
                                        color = label), hjust = 1, nudge_x = -0.1, fontface = "bold",  size = 5, family = "montserrat", lineheight = 0.3) +
    
    # Right-side labels
    geom_label(data = g_labs_end, aes(x, y, label = str_wrap(paste(label, "·", n),17), color = label), hjust = 0, nudge_x = 0.1, size = 5, family = "montserrat", lineheight = 0.3) +
    scale_fill_brewer(palette = "Dark2") +
    scale_color_brewer(palette = "Dark2") +
    coord_cartesian(clip = "off") +
    theme_sankey_bump(base_size = 18, base_family  = "montserrat") +
    labs(
        title = "Global Electoral Systems Over Time: The Shift Toward Democratic Elections",
        subtitle = str_wrap("In 1950, around 35% of countries held Non-Democratic Multi-Party Elections, while by 2020, two-thirds of the world had adopted Democratic elections.",100),
       caption = "Source: democracyData, C. Bjørnskov and M. Rode. (2020)"
    ) +
    scale_x_continuous(breaks = seq(1950, 2020, 10),
                       limits = c(1943, 2026)) +
    #guides(fill = guide_legend(nrow = 3, byrow = TRUE)) +
    theme(
        legend.position = "none",
        plot.background = element_rect(fill = "grey99", color = NA),
        axis.title = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        plot.title = element_text(face = "bold", size = 24),
        plot.subtitle = element_text(lineheight = 0.4, size = 20),
        plot.caption = element_text(margin = margin(10, 0, 0, 0), hjust = 0),
        plot.margin = margin(10, 40, 10, 20)
    )

ggsave("products/tt_nov4_electoral.jpeg")
