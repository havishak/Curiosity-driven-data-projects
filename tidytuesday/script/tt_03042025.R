library(tidyverse)
longbeach <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-03-04/longbeach.csv')

intake_outcome <- longbeach %>%
    select(animal_type, intake_date, intake_condition, intake_type, outcome_date, outcome_type) %>%
    mutate(
        time_diff = as.numeric(outcome_date - intake_date)
    ) %>%
    drop_na(intake_condition, outcome_type) %>%
    group_by(intake_condition, outcome_type) %>%
    summarize(
        q25_time = quantile(time_diff, 0.25, na.rm = T),
        median_time = median(time_diff, na.rm = T),
        q75_time = quantile(time_diff, 0.75, na.rm = T),
        total = n()
    ) %>%
    arrange(desc(total)) %>%
    mutate(row = row_number()) %>%
    filter(row < 4) %>%
    ungroup() %>%
    mutate(
        outcome_type = factor(outcome_type,
                              levels = c("adoption", "return to owner", "rescue", "transfer", "shelter, neuter, return", "euthanasia", "died"))
    )

color_palette <- rev(RColorBrewer::brewer.pal(11,"Spectral")[c(1:3,7,9:11)])
ggplot(intake_outcome, aes(y = intake_condition,
               color = outcome_type)) +
    geom_errorbar(aes(xmin = q25_time, xmax = q75_time, color = outcome_type),
                  position = "dodge") +
    geom_point(aes(x = median_time),
               position = position_dodge(width = 0.9)) +
    scale_y_discrete(lim = rev) +
    scale_color_manual(values = color_palette) +
    theme_minimal()
