library(tidyverse)
#library(camcorder)
library(ggrepel)
library(showtext)
library(ggtext)
library(cowplot)
library(ggridges)
library(ggdist)
library(patchwork)

font_add_google("Cinzel Decorative", "rnj")
font_add_google("Baloo 2", "io")
showtext_auto()


individual_results_df <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-09-24/individual_results_df.csv')

individual_results_df <- individual_results_df %>%
    mutate(
        award_cat = case_when(
            is.na(award) ~ "No",
            grepl("Gold", award) ~ "Gold",
            grepl("Silver", award) ~ "Silver",
            grepl("Bronze", award) ~ "Bronze",
            grepl("Honourable|Special", award) ~ "Honorable Mention"
        ),
        award_cat = factor(award_cat,
                           levels = c("Gold", "Silver", "Bronze", "Honorable Mention", "No"))
        ) %>%
    pivot_longer(
        cols = c(p1:p6, total),
        names_to = "problem",
        values_to = "scores"
    ) 



create_density_plot <- function(df, label){
    
    df$problem <- label 
    plot <- ggplot(df, aes(y = fct_rev(award_cat), x = scores)) +
    geom_density_ridges(fill = "gray70", color = NA, alpha = 0.7) +
    # stat_interval(linewidth = 1,
    #               show_point = FALSE,
    #               .width = c(0.5, 0.8)) +
    stat_summary(geom = "linerange", fun.min = min,
                     fun.max = max, linewidth = 1, color = "#FD8D3C")+
    stat_summary(geom = "linerange", fun.min = ~quantile(.x, probs = 0.1),
                 fun.max = ~quantile(.x, probs = 0.9), linewidth = 1, color = "#FECC5C")+
    stat_summary(geom = "linerange", fun.min = ~quantile(.x, probs = 0.25),
                 fun.max = ~quantile(.x, probs = 0.75), linewidth = 1, color = "#FFFFB2")+
    stat_summary(geom = "point", fun = median, size = 1) +
    # geom_vline(xintercept = median(individual_results_df$total), 
    #            col = "grey30", lty = "dashed") +
    theme_minimal() +
    scale_color_brewer(palette = "Pastel2", direction = -1) +
    labs(x = "",
         y = "") +
    facet_wrap(~problem,
               scales = "free_x")+
    theme(
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank()
    )
    
    if(grepl("Problem", label)){
        plot <- plot +
            scale_x_continuous(
                breaks = 0:9
            )
    }
    
    return(plot)
}
   
problems_df <- split(individual_results_df,individual_results_df$problem) 
problems_label <- c(paste0("Problem ",1:6), "Total Score")

plots <- map2(problems_df, problems_label, ~create_density_plot(.x, .y))

problem_plots <- wrap_plots(plots[1:6], nrow = 3)

plots[[7]] + problem_plots
