# halloween tt
# read data

library(tidyverse)
library(ggbeeswarm)
library(showtext)

# Add the Creepster font
font_add_google("Creepster", "Creepster")
showtext_auto() 

monster_movie_genres <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-10-29/monster_movie_genres.csv')

# place eyes data
eyes_data <- data.frame(
    cont_col = rep(c("year", "runtime_minutes", "average_rating"),2),
    val = rep(0.4, 6)
)

# theta <- seq(pi, 2*pi, length.out = 100) 
# smiley_shape1 <- data.frame(
#     cont_col = "year",
#     x = 0.3*cos(theta),
#     y = 0.3*sin(theta)
# )
# 
# smiley_shape2 <- data.frame(
#     cont_col = "runtime_minutes",
#     x = seq(-2,2.5,0.5),
#     y = rep(c(0, 1),5)
# )
# 
# 
# # Plot the semi-circle using ggplot2
# plot_smiley1 <- ggplot(smiley_shape1, aes(x, y)) +
#     geom_polygon(fill = "gray30") +
#     coord_fixed()  +  # Set limits
#     theme_void()  # Remove axes

ggplot() +
    geom_polygon(data = smiley, aes(x = x, y = y), fill = "orange", color = "black") +
    geom_point(data = eyes, aes(x = x, y = y), size = 5, shape = 21, fill = "white") +
    geom_curve(aes(x = 1.3, y = 0.8, xend = 1.7, yend = 0.8), curvature = -0.5, size = 1, color = "black") +
    xlim(0, 2) + ylim(0, 2) +
    theme_void()

# I want to show all continuous variables as pumpkins
set.seed(1)
monster_movies |>
    mutate(across(c(year, runtime_minutes, average_rating, num_votes), ~(.x - mean(.x, na.rm = T))/sd(.x, na.rm = T))) |>
    pivot_longer(
        cols = c(year, runtime_minutes, average_rating),
        names_to = "cont_col",
        values_to = "val"
    ) |>
    filter(val > -5 , val < 5) |>
    ggplot(aes(x = cont_col, y = val, size = val)) +
    scale_size_continuous(range = c(1,6),
                          breaks = c(-2, -1, 0, 1, 2, 3))+
    geom_quasirandom(method = "smiley", aes(color = val > 0.9)) +
    # add eyes
    geom_quasirandom(data = eyes_data, 
               aes(x = cont_col, y = val, shape = cont_col), method = "tukeyDense", size = 11, color = "black", fill = "gray50")+
    # add nose
    geom_point(aes(x = cont_col, y = -0.2), size = 8, 
               color = "gray20", fill = "gray20", shape = 18)+
    scale_shape_manual(
        values = c(8, 21, 24)
    ) +
    scale_color_manual(values = c("#FF7518", "#286848")) +   
    theme_void() +
    labs(title = "TRICK OR TREAT?",
         caption = "Source: IMBD Halloween data from TidyTuesday") +
    theme(
        legend.position = "none",
        text = element_text(family = "Creepster"),
        plot.title = element_text(hjust = 0.5, size = 100, color = "gray90"),
        plot.caption = element_text(color = "gray90", size = 50),
        plot.background = element_rect(fill = 'gray15')
    )

ggsave("products/tt_oct29_halloween.png")
