set.seed(10)
# the ones i didn't do
sample(c(48:53, 1:7),1)

# Doing week 5 of 2025.

library(tidyverse)

simpsons_characters <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-02-04/simpsons_characters.csv')
simpsons_episodes <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-02-04/simpsons_episodes.csv')
simpsons_locations <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-02-04/simpsons_locations.csv')
simpsons_script_lines <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-02-04/simpsons_script_lines.csv')

# what's the gender ratio in simpson's 150 episodes?

simpsons_characters <- simpsons_characters %>%
    mutate(gender = ifelse(is.na(gender), "unknown", gender),
           gender = factor(gender, levels = c("m", "unknown", "f"),
                           labels = c("Male", "Unknown", "Female")))

simpsons_gender_distribution <- simpsons_script_lines %>%
    filter(speaking_line == TRUE) %>%
    left_join(simpsons_characters, 
              by = c("character_id" = "id")) %>%
    filter(!is.na(character_id)) %>%
    group_by(episode_id, gender) %>%
    summarize(lines_by_gender = n(),
           representation_by_gender = length(unique(character_id))) %>%
    group_by(episode_id) %>%
    mutate(prop_lines_by_gender = lines_by_gender/sum(lines_by_gender),
           prop_representation_by_gender = representation_by_gender/sum(representation_by_gender))

episode_annotation <- simpsons_gender_distribution %>%
    filter(gender %in% c("Female","Unknown"), prop_lines_by_gender > 0.5) %>%
    left_join(simpsons_episodes, by = c("episode_id" = "id")) %>%
    mutate(text = paste0(title, "- ", gender, " had ", round(prop_lines_by_gender*100),"% lines"))

ggplot(simpsons_gender_distribution,
       aes(y = fct_rev(factor(episode_id)),
           x = prop_lines_by_gender, 
           fill = fct_rev(gender))) +
    geom_col() +
    geom_text(data = episode_annotation, aes(x = 1.2, label = str_wrap(text, 20)),
              size = 4, color = "gray30",
              lineheight = 0.8,
              family = "mono")+
    # Arrows from text to bars
    geom_curve(data = episode_annotation, 
                 aes(x = 1, 
                     xend = 0.6, 
                     y = fct_rev(factor(episode_id)), 
                     yend = fct_rev(factor(episode_id))), 
                 arrow = arrow(length = unit(0.1, "inches")),
                 curvature = 0.2, 
                 color = "gray70") +
    scale_x_continuous(expand = c(0,0),
                       limits = c(0, 1.4),
                       #labels = c(0, 0.5, 1)
                       )+
    scale_fill_manual(values = RColorBrewer::brewer.pal(3, "Pastel2")) +
    labs(
        x = "Proportion of Lines",
        y = "Episode",
        fill = "Gender",
        title = "Who Speaks the Most? Gender Breakdown of Dialogue in The Simpsons",
        subtitle = str_wrap("Across 150 episodes, male-coded characters dominated with 62% of the dialogue, while female-coded and unknown-coded characters accounted for 22% and 16% respectively.",80),
        caption = "Source: Nicolas Foss, Prashant Banerjee, TidyTuesday"
    ) +
    theme_minimal(10) +
    theme(
        text = element_text(color = "gray30",
                            family = "mono"),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(face = "italic"),
        legend.position = c(0.8, 0.95),
        axis.title.y = element_blank(),
        axis.text = element_text(size = 6, color = "gray30"),
        panel.grid = element_blank(),
        axis.title.x = element_text(hjust = 0),
        plot.caption = element_text(hjust = 0),
        plot.background = element_rect(fill = "gray90", color = NA),
    )

ggsave("products/tt_02042025_simpsons_gender.jpeg", height = 10, width = 7)
