# November 26
# Week 48

library(tidyverse)
library(patchwork)

cbp_resp <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2024/2024-11-26/cbp_resp.csv')
cbp_state <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2024/2024-11-26/cbp_state.csv')

color <- RColorBrewer::brewer.pal(8, "Pastel2")

cbp_resp_citizenship_summary <- cbp_resp %>%
  count(citizenship, encounter_type) %>%
  group_by(citizenship) %>%
  mutate(
    total = sum(n),
    per_total = n/total
  )

# plot of encounters by citizenship
plot_encounters <- ggplot(distinct(cbp_resp_citizenship_summary, citizenship, total),
       aes(y = fct_reorder(factor(citizenship),total), x = total)) +
  geom_col(fill = color[1]) +
  scale_x_reverse() +
  geom_text(aes(label = total),
            nudge_x = -210,
            color = "gray30",
            size = 3) +
  theme_void() +
  ggtitle("#Encounters") +
  theme(plot.title =element_text(hjust = 1, face = "bold.italic"))

encounter_types <- unique(cbp_resp_citizenship_summary$encounter_type)

plot_encounter_proportion <- map2(encounter_types,
                                  2:4,
                                 ~ggplot(filter(cbp_resp_citizenship, encounter_type == .x),
                          aes(y = fct_reorder(factor(citizenship),total),
                              x = per_total)) +
  geom_col(fill = color[.y]) +
    geom_text(aes(label = round(per_total*100)),
              nudge_x = .01,
              color = "gray30",
              size = 3) +
    theme_void() +
    ggtitle(paste0("Percent ",str_to_title(.x))) +
    theme(plot.title =element_text(hjust = 0, face = "bold.italic"),
          axis.text.y = element_text(color = "gray20", size = 8)))

plot_encounters + plot_encounter_proportion[[2]]
