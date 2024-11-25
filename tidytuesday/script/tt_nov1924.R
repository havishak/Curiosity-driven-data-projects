# load library
library(tidyverse)

# read data
episode_metrics <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-19/episode_metrics.csv')


# curious about how dialogue_density and sentiment_variance is related with combinatio of high/low question and exclamation ratio episodes, and those where both go in different directions

# episodes with lower 10% and top 10% dialogue_density, avg_length, sentiment_variance, unique_words

make_df <- function(df, column){
    # middle 50, and top 10, bottom 10
    decile_df <- df |>
        mutate(
            rank = ntile(!!sym(column), 10)
        )  |>
        filter(rank %in% c(1, 10)) |>
        mutate(rank = factor(rank,
                                       levels = c(1, 10)))
    
    return(decile_df)
}

make_base_plot <- function(df, column) {
    
    # create plot with bottom and top deciles
    plot_df <- make_df(df, column)

    # clean column name
    column_name <- gsub("_"," ", column)
    
    # get annotation position
    annotate_position_x <- (plot_df$question_ratio[which.max(plot_df$question_ratio)]) - 0.06
    
    # plot
    plot <- ggplot(plot_df, aes(y = fct_rev(fct_reorder(
        factor(interaction(season, episode)), !!sym(column)
    )), alpha = rank == 10)) +
        geom_segment(aes(x = 0, xend = question_ratio),
                     linewidth = 2,
                     color = "#ff69b4") +
        geom_segment(aes(x = 0, xend = -exclamation_ratio),
                     linewidth = 2,
                     color = "#1abc9c") +
        geom_vline(
            xintercept = 0,
            linetype = "dotted",
            color = "gray10",
            linewidth = 1
        ) +
        geom_hline(
            yintercept = 27.5,
            linetype = "dashed",
            color = "gray40",
            linewidth = 0.5
        ) +
        scale_alpha_manual(values = c(0.5, 0.8)) +
        scale_x_continuous(
            breaks = c(-0.2, -0.1, -0.04, 0.04, 0.1, 0.2),
            labels = c(
                "0.2",
                "0.1",
                "\u2190 Exclamation\nProp",
                "Question\nProp \u2192",
                "0.1",
                "0.2"
            )
        ) +
        annotate(
            x = annotate_position_x,
            y = 29.5,
            geom = "label",
            label = str_wrap(paste0("Bottom 10% Episodes on ", str_to_title(column_name), "\u2191"), 25),
            lineheight = 0.8,
            alpha = 0.6,
            fill = "azure"
        ) +
        annotate(
            x = annotate_position_x,
            y = 26.5,
            geom = "label",
            label = "Top 10% \u2193",
            alpha = 0.6,
            fill = "azure"
        ) +
        theme(
            text = element_text(#family = "ComicSans"
                size = 16),
            legend.position = "none",
            panel.grid = element_blank(),
            axis.title = element_blank(),
            axis.text.y = element_blank(),
            axis.ticks = element_blank(),
            plot.background = element_rect(fill = "gray90"),
            panel.background = element_rect(fill = "gray90")
        )
    
    return(plot)
}

describe_columns <- c("unique_words", "avg_length", "dialogue_density", "sentiment_variance")

base_plots <- map(describe_columns, ~make_base_plot(episode_metrics, .x))

plot_titles <- c("Unique Words: More Exclamation Points in Episodes with Less Unique Words",
                 "Avg Character: More of both Exclamation Points and question marks in Episodes with Higher Avg. Characters, but more pronounces for Exclamation points",
                 "Dialogue Density: Lower exclamation points in episodes with lower dialogue density",
                 "Sentiment Variance: More exclamation points in episodes with higher sentiment variance")

# add titles

base_plots <- map2(base_plots, plot_titles, ~.x +
         labs(subtitle = .y))
