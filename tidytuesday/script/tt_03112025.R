# Tidy tuesday Week 10 on Pixar films
library(tidyverse)
library(showtext)

# Load Google Font
font_add_google("Cinzel", "cinzel")
showtext_auto()
pixar_films <- readr::read_csv(
    'https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-03-11/pixar_films.csv'
)
public_response <- readr::read_csv(
    'https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-03-11/public_response.csv'
)

public_response_ranked <- public_response %>%
    select(-cinema_score) %>%
    mutate(across(rotten_tomatoes:critics_choice, ~ dense_rank(-.x))) %>%
    rowwise() %>%
    mutate(
        diff_12 = abs(rotten_tomatoes - metacritic),
        # Difference between Rank1 & Rank2
        diff_13 = abs(metacritic - critics_choice),
        # Difference between Rank1 & Rank3
        diff_23 = abs(critics_choice - rotten_tomatoes),
        # Difference between Rank2 & Rank3
        mean_disagreement = mean(c(diff_12, diff_13, diff_23))  # Mean of pairwise differences
    ) %>%
    ungroup() %>%
    pivot_longer(rotten_tomatoes:critics_choice,
                 names_to = "ranking_system",
                 values_to = "rank") %>%
    mutate(ranking_system = factor(
        ranking_system,
        levels = c("rotten_tomatoes", "metacritic", "critics_choice"),
        labels = c("Rotten Tomatoes", "Metacritic", "Critics Choice")
    )) %>%
    group_by(ranking_system, rank) %>%
    arrange(film) %>%
    mutate(new_rank = ifelse(!is.na(rank), paste0(rank, ".", row_number()), NA_character_)) %>%
    ungroup() %>%
    mutate(new_rank = fct_reorder(factor(new_rank), rank))

plot_text_rt <- public_response_ranked %>%
    filter(ranking_system == "Rotten Tomatoes") %>%
    select(new_rank, rank, film, mean_disagreement)

main_plot <- ggplot(public_response_ranked, aes(x = ranking_system, y = new_rank)) +
    geom_line(aes(group = film, color = film), alpha = 0.4) +
    geom_point(aes(group = film, color = film),
               size = 2,
               alpha = 0.6) +
    geom_point(color = "gray80", size = 0.5) +
    geom_text(
        data = plot_text_rt,
        aes(x = 0.5, label = film, color = film),
        family = "cinzel",
        size = 8,
        fontface = "bold"
    ) +
    scale_x_discrete(expand = expansion(add = c(0.7, 0), mult = c(0.1, 0.1))) +
    scale_color_manual(values = rep(RColorBrewer::brewer.pal(8, "Dark2"), 3)) +
    #scale_color_manual(values = c("black", "transparent"))+
    scale_y_discrete(limits = rev, labels = rev(c(gsub(
        "(.*)\\.\\d", "\\1", levels(public_response_ranked$new_rank)
    ), NA))) +
    guides(color = "none", alpha = "none") +
    theme_minimal(25) +
    labs(
        x = NULL,
        y = NULL,
        title = "Ranking of Pixar Movies by Review Aggregators",
        caption = "Source: {pixarfilms} R package; curated by Jon Harmon."
    ) +
    theme(
        text = element_text(family = "cinzel"),
        axis.text = element_text(
            color = "gray30",
            size = 20,
            face = "bold"
        ),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.title = element_text(
            color = "gray10",
            face = "bold",
            hjust = 0.5
        ),
        plot.caption = element_text(color = "gray10", size = 15),
        plot.background = element_rect(color = "transparent", fill = "#b0c4de")
    )

most_agreement <- ggplot(
    public_response_ranked,
    aes(x = ranking_system, y = new_rank, color = mean_disagreement < 2.1)
) +
    geom_line(aes(group = film), alpha = 0.4) +
    geom_point(aes(group = film),
               size = 2,
               alpha = 0.6) +
    geom_point(data = filter(public_response_ranked, mean_disagreement < 2.1),
               color = "gray80", size = 0.5) +
    geom_text(
        data = filter(plot_text_rt, mean_disagreement < 2.1),
        aes(x = 0.5, label = film),
        family = "cinzel",
        size = 8,
        fontface = "bold"
    ) +
    scale_x_discrete(expand = expansion(add = c(0.7, 0), mult = c(0.1, 0.1))) +
    scale_color_manual(values = c("gray70", "#E7298A"),
                       na.value = "gray70") +
    #scale_color_manual(values = c("black", "transparent"))+
    scale_y_discrete(limits = rev, labels = rev(c(gsub(
        "(.*)\\.\\d", "\\1", levels(public_response_ranked$new_rank)
    ), NA))) +
    guides(color = "none", alpha = "none") +
    theme_minimal(20) +
    labs(
        x = NULL,
        y = NULL,
        title = "Ranking of Pixar Movies by Review Aggregators",
        subtitle = "Highlighted Movies had most agreement in rating across reviewers.",
        caption = "Source: {pixarfilms} R package; curated by Jon Harmon."
    ) +
    theme(
        text = element_text(family = "cinzel"),
        axis.text = element_text(
            color = "gray30",
            size = 20,
            face = "bold"
        ),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.title = element_text(
            color = "gray10",
            face = "bold",
            hjust = 0.5
        ),
        plot.caption = element_text(color = "gray10", size = 15),
        plot.subtitle = element_text(hjust = 0.5),
        plot.background = element_rect(color = "transparent", fill = "#b0c4de")
    )

most_disagreement <- ggplot(
    public_response_ranked,
    aes(x = ranking_system, y = new_rank, color = mean_disagreement > 3.9)
)   +
    geom_line(aes(group = film), alpha = 0.4) +
    geom_point(aes(group = film),
               size = 2,
               alpha = 0.6) +
    geom_point(data = filter(public_response_ranked, mean_disagreement > 3.9),
               color = "gray80", size = 0.5) +
    geom_text(
        data = filter(plot_text_rt, mean_disagreement > 3.9),
        aes(x = 0.5, label = film),
        family = "cinzel",
        size = 8,
        fontface = "bold"
    ) +
    scale_x_discrete(expand = expansion(add = c(0.7, 0), mult = c(0.1, 0.1))) +
    scale_color_manual(values = c("gray70", "#D95F02"),
                       na.value = "gray70") +
    #scale_color_manual(values = c("black", "transparent"))+
    scale_y_discrete(limits = rev, labels = rev(c(gsub(
        "(.*)\\.\\d", "\\1", levels(public_response_ranked$new_rank)
    ), NA))) +
    guides(color = "none", alpha = "none") +
    theme_minimal(20) +
    labs(
        x = NULL,
        y = NULL,
        title = "Ranking of Pixar Movies by Review Aggregators",
        subtitle = "Highlighted Movies had most disagreement in rating across reviewers.",
        caption = "Source: {pixarfilms} R package; curated by Jon Harmon."
    ) +
    theme(
        text = element_text(family = "cinzel"),
        axis.text = element_text(
            color = "gray30",
            size = 20,
            face = "bold"
        ),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.title = element_text(
            color = "gray10",
            face = "bold",
            hjust = 0.5
        ),
        plot.subtitle = element_text(hjust = 0.5),
        plot.caption = element_text(color = "gray10", size = 15),
        plot.background = element_rect(color = "transparent", fill = "#b0c4de")
    )

ggsave("products/tt_03112025_pixar_reviews.png",
       main_plot, width = 5.1, height = 5.5)

ggsave("products/tt_03112025_pixar_reviews_agreements.png",
       most_agreement, width = 5.1, height = 5.5)

ggsave("products/tt_03112025_pixar_reviews_disagreements.png",
       most_disagreement, width = 5.1, height = 5.5)
