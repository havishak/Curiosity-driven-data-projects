library(tidyverse)
#library(camcorder)
library(showtext)
library(ggtext)
library(ggridges)
library(patchwork)

font_add_google("Fira Sans", "fs")
showtext_auto()

individual_results_df <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-09-24/individual_results_df.csv')

individual_results_df <- individual_results_df %>%
    mutate(
        award_cat = case_when(
            is.na(award) ~ "No",
            grepl("Gold", award) ~ "Gold",
            grepl("Silver", award) ~ "Silver",
            grepl("Bronze", award) ~ "Bronze",
            grepl("Honourable|Special", award) ~ "Honorable\nMention"
        ),
        award_cat = factor(award_cat,
                           levels = c("Gold", "Silver", "Bronze", "Honorable\nMention", "No"))
        ) %>%
    pivot_longer(
        cols = c(p1:p6, total),
        names_to = "problem",
        values_to = "scores"
    ) 



create_density_plot <- function(df, label){
    
    line_width <- ifelse(grepl("Total", label), 0.9, 0.75)
    point_size <- ifelse(grepl("Total", label), 0.75, 0.25)
    
    df$problem <- label 
    plot <- ggplot(df, aes(y = fct_rev(award_cat), x = scores)) +
    # stat_interval(linewidth = 0.9,
    #               show_point = FALSE,
    #               .width = c(0.5, 0.8)) +
    geom_density_ridges(fill = "gray70", alpha = 0.6, color = "gray65") +
    stat_summary(geom = "linerange", fun.min = min,
                     fun.max = max, linewidth = line_width, color = "#FD8D3C")+
    stat_summary(geom = "linerange", fun.min = ~quantile(.x, probs = 0.1),
                 fun.max = ~quantile(.x, probs = 0.9), linewidth = line_width, color = "#FECC5C")+
    stat_summary(geom = "linerange", fun.min = ~quantile(.x, probs = 0.25),
                 fun.max = ~quantile(.x, probs = 0.75), linewidth = line_width, color = "#FFFFB2")+
    stat_summary(geom = "point", fun = median, size = point_size) +
    geom_vline(xintercept = median(df$scores, na.rm = T),
               col = "grey40", lty = "dashed") +
    theme_minimal() +
    scale_y_discrete(expand = c(0.1,0))+
    facet_wrap(~problem,
               scales = "free_x")+
    theme(
        panel.grid.minor = element_blank(),
        strip.text = element_text(face="bold", size = 20, family = "fs"),
        axis.text  = element_text(size = 18, family = "fs", lineheight = 0.3),
        axis.title = element_blank()
        #panel.grid.major.x = element_blank()
    )
    
    if(grepl("Problem", label)){
        plot <- plot +
            scale_x_continuous(
                breaks = c(0, seq(1,7,2)),
                expand = c(0,0)
            )
    }
    
    if(grepl("Total", label)){
        plot <- plot +
            scale_x_continuous(expand = c(0,0)) +
        annotate(geom = "text", x =  median(df$scores, na.rm = T) + 5,
                 label = "Median Score",
                 y = 5.6, family = "fs", size = 7, color = "gray40") +
            theme(
                strip.text = element_text(face="bold", size = 22, family = "fs"),
                axis.text  = element_text(size = 20, family = "fs", lineheight = 0.5),
                axis.title = element_blank()
                #panel.grid.major.x = element_blank()
            )
    }
    
    return(plot)
}
   
problems_df <- split(individual_results_df,individual_results_df$problem) 
problems_label <- c(paste0("Problem ",1:6), "Total Score")

plots <- map2(problems_df, problems_label, ~create_density_plot(.x, .y))

problem_plots <- wrap_plots(plots[1:6], ncol = 2, byrow = FALSE) +
    plot_layout(axes = "collect")

# create a legend (inside plot)
legend_plot <- problems_df[[7]] %>%
    filter(award_cat == "Silver") %>%
    ggplot(aes(y = award_cat, x = scores)) +
    # stat_interval(linewidth = 0.9,
    #               show_point = FALSE,
    #               .width = c(0.5, 0.8)) +
    geom_density_ridges(fill = "gray70", alpha = 0.6, color = "gray65") +
    stat_summary(geom = "linerange", fun.min = min,
                 fun.max = max, linewidth = 0.9, color = "#FD8D3C")+
    stat_summary(geom = "linerange", fun.min = ~quantile(.x, probs = 0.1),
                 fun.max = ~quantile(.x, probs = 0.9), linewidth = 0.9, color = "#FECC5C")+
    stat_summary(geom = "linerange", fun.min = ~quantile(.x, probs = 0.25),
                 fun.max = ~quantile(.x, probs = 0.75), linewidth = 0.9, color = "#FFFFB2")+
    stat_summary(geom = "point", fun = median, size = 1) +
    scale_x_continuous(
        expand = c(0,0),
        limits = c(16, 43)
    ) +
    theme_void() +
    annotate(
        "richtext",
        x = c(24, 30, 38, 26, 37),
        y = c(0.93, 0.93, 0.93, 1.15, 1.22),
        label = c("50% of scores<br>within this range", "80%", 
                  "100%", "Median", "Distribution<br>of scores"),
        fill = NA, label.size = 0, family = "fs", size = 5, vjust = 1,
        lineheight = 0.3
    ) +
    annotate(
        "richtext",
        x = 18.5,
        y = 1.3,
        label = "Legend",
        fill = NA, label.size = 0, family = "fs", size = 6, vjust = 1,
        lineheight = 0.5, fontface = "bold", color = "black"
    ) +
    # annotate(
    #     "rect", xmin = 15.1, xmax =42.9, ymin = 0.9, ymax = 1.2, color = "gray40",
    #     fill = NA
    # ) +
    geom_curve(
        data = data.frame(
            x = c(24, 30, 38, 26, 34),
            y = c(0.935, 0.935, 0.935, 1.08, 1.15),
            xend = c(25, 32, 38, 26, 30) , 
            yend = c(0.99, 0.99, 0.99, 1.02, 1.13)),
        aes(x = x, xend = xend, y = y, yend = yend),
        stat = "unique", curvature = 0.2, size = 0.2, color = "grey12",
        arrow = arrow(angle = 20, length = unit(1, "mm"))
    ) +
    theme(
        plot.title = element_blank(),
        axis.title = element_blank()
    )

total_score_plot <- plots[[7]] +
    inset_element(legend_plot, l = -0.2, r = 0.3,  t = 1.15, b = 0.65, 
                  clip = F)

combined_plot <- total_score_plot + problem_plots +
    plot_layout(
        widths = c(3, 2)
    ) +
    plot_annotation(
      title = "Score Distribution Based on Individual Medal Status",
      subtitle = "Performance on Problems 1 and 4 shows strong relation with winning any medal.",
      caption = "Source: International Mathematical Olympiad (IMO) Data" 
    ) &
    theme(
        plot.title = element_text(family = "fs", size = 30, face = "bold"),
        plot.subtitle = element_text(family = "fs", size = 28),
        plot.caption = element_text(family = "fs", size = 20)
        #panel.grid.major.x = element_blank()
    )

# Saving 6.76 x 5.04 in image
ggsave(plot = combined_plot,
       filename = "products/tt_sep2424_scores_distribution.png",
       width = 6.76, height = 5.04)

