# load library
library(tidyverse)
library(ggbeeswarm)

# read data
episode_metrics <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-19/episode_metrics.csv')


# curious about how dialogue_density and sentiment_variance is related with combinatio of high/low question and exclamation ratio episodes, and those where both go in different directions

# episodes with lower 10% and top 10% dialogue_density, avg_length, sentiment_variance, unique_words

make_df <- function(df, column){
    # middle 80, and top 10, bottom 10
    quantile_df <- df |>
        mutate(
            rank = ntile(!!sym(column), 4),
            criteria = column,
            rank = ifelse(!rank %in% c(1,4), 2, rank)
        )  |>
        #filter(rank %in% c(1, 4)) |>
        mutate(rank = factor(rank, levels = c(1,2,4), labels = c("Bottom 25%", "Middle 50%", "Top 25%")))
    
    return(quantile_df)
}

# make_base_plot <- function(df, column) {
#     
#     # create plot with bottom and top deciles
#     plot_df <- make_df(df, column)
# 
#     # clean column name
#     column_name <- gsub("_"," ", column)
#     
#     # get annotation position
#     annotate_position_x <- (plot_df$question_ratio[which.max(plot_df$question_ratio)]) - 0.06
#     
#     # plot
#     plot <- ggplot(plot_df, aes(y = fct_rev(fct_reorder(
#         factor(interaction(season, episode)), !!sym(column)
#     )), alpha = rank == 10)) +
#         geom_segment(aes(x = 0, xend = question_ratio),
#                      linewidth = 2,
#                      color = "#ff69b4") +
#         geom_segment(aes(x = 0, xend = -exclamation_ratio),
#                      linewidth = 2,
#                      color = "#1abc9c") +
#         geom_vline(
#             xintercept = 0,
#             linetype = "dotted",
#             color = "gray10",
#             linewidth = 1
#         ) +
#         geom_hline(
#             yintercept = 27.5,
#             linetype = "dashed",
#             color = "gray40",
#             linewidth = 0.5
#         ) +
#         scale_alpha_manual(values = c(0.5, 0.8)) +
#         scale_x_continuous(
#             breaks = c(-0.2, -0.1, -0.04, 0.04, 0.1, 0.2),
#             labels = c(
#                 "0.2",
#                 "0.1",
#                 "\u2190 Exclamation\nProp",
#                 "Question\nProp \u2192",
#                 "0.1",
#                 "0.2"
#             )
#         ) +
#         annotate(
#             x = annotate_position_x,
#             y = 29.5,
#             geom = "label",
#             label = str_wrap(paste0("Bottom 10% Episodes on ", str_to_title(column_name), "\u2191"), 25),
#             lineheight = 0.8,
#             alpha = 0.6,
#             fill = "azure"
#         ) +
#         annotate(
#             x = annotate_position_x,
#             y = 26.5,
#             geom = "label",
#             label = "Top 10% \u2193",
#             alpha = 0.6,
#             fill = "azure"
#         ) +
#         theme(
#             text = element_text(#family = "ComicSans"
#                 size = 16),
#             legend.position = "none",
#             panel.grid = element_blank(),
#             axis.title = element_blank(),
#             axis.text.y = element_blank(),
#             axis.ticks = element_blank(),
#             plot.background = element_rect(fill = "gray90"),
#             panel.background = element_rect(fill = "gray90")
#         )
#     
#     return(plot)
# }

describe_columns <- c("unique_words", "avg_length", "dialogue_density", "sentiment_variance")
quantile_df <- map_dfr(describe_columns, ~make_df(episode_metrics, .x)) |>
    rename(
        "Prop of Non-Blank Lines" = "dialogue_density",
        "Average character/Line" = "avg_length",
        "Sentiment (higher suggests positive)" = "sentiment_variance",
        "Unique lower-case words" = "unique_words",
        "Prop of lines with question mark" = "question_ratio",
        "Prop of lines with exclamation mark" = "exclamation_ratio"
    ) |>
    pivot_longer(
        cols = 3:8,
        names_to = "metric",
        values_to = "val"
    ) 

metric_plot <- function(plot_criteria, plot_metric, plot_title){
 
    plot_df <- quantile_df |>
        filter(criteria == plot_criteria) 
    
    plot_text_df <- plot_df |>
        group_by(rank, metric) |>
        summarize(min = min(val),
                  max = max(val),
                  mean = mean(val)) |>
        mutate(
            pos = case_when(
                rank == "Bottom 25%" ~ min*(1+0.02),
                rank == "Top 25%" ~ max,
                TRUE ~ mean),
            label = ifelse(metric == plot_metric, levels(rank)[rank], NA))
    
       
    plot <- ggplot(plot_df) +
        geom_quasirandom(aes(y = 1, x = val, color = rank),
                         varwidth = TRUE,
                         #method  = "tukeyDense",
                         #groupOnX = FALSE, 
                         alpha = 0.6) +
        geom_text(data = plot_text_df,
                  aes(y = 1, x = pos, label = label),
                  color = "gray10", size = 4, nudge_y = 0.2, fontface = "bold") +
        facet_wrap(~metric, scales = "free_x",
                   ncol = 1) +
        scale_color_manual(values = c("#D73027", "#BDBDBD",
                                      "#4575B4"))+
        theme_minimal(14) +
        theme(
            panel.grid = element_blank(),
            axis.text.y = element_blank(),
            axis.title = element_blank(),
            axis.line.x = element_line(color = "gray70"),
            axis.ticks.x = element_line(color = "gray80"),
            axis.text.x = element_text(color = "gray40", size = 9),
            panel.background = element_rect(fill = "gray95", color = "transparent"),
            plot.background = element_rect(fill = "gray95", color = "transparent"),
            legend.position = "top"
        ) +
        labs(title = str_wrap(plot_title, 70),
             caption = "Source: Bob's Burger curated by Steven Ponce.",
             color = "")
    
    return(plot)
}

# add titles
plot_titles <- paste0("Comparing Episode Metrics Across Bottom and Top Quarters Based on ", c("Unique Words",
                                                                                              "Average character length/line",
                                                                                              "Prop. of Non-Blank Lines",
                                                                                              "Sentiment Variance"))


plot_list <- pmap(list(
    # criteria
    unique(quantile_df$criteria),
    # name of metric
    unique(quantile_df$metric)[c(4, 2, 1, 3)],
    # plot title
    plot_titles
), ~metric_plot(..1, ..2, ..3))

walk2(plot_list,
      unique(quantile_df$criteria),
      ~ggsave(plot = .x, 
              paste0("products/tt_nov1924_",.y,".png"), 
              height = 10.5, width = 9))
