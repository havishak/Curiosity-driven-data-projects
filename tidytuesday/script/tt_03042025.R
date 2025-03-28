library(tidyverse)
library(waffle)
library(showtext)
library(ggtext)
library(RColorBrewer)
library(gridtext)

font_add_google("Outfit", "title_font")
font_add_google("Cabin", "body_font")
showtext_auto()

title_font <- "title_font"
body_font <- "body_font"

title <- "Long Beach Animal Shelter: Distribution of Outcome by Intake Condition"
subtitle <- "Each square represents 10 cases:<br>
  <b><span style='color:#D53E4F;'>Euthanasia ,</span></b> 
  <b><span style='color:#F46D43;'>Died,</span></b> 
  <b><span style='color:#FDAE61;'>Transfer ,</span></b> 
  <b><span style='color:#FEE08B;'>Rescue ,</span></b> <br>
  <b><span style='color:#FFFFBF;'>Shelter, neuter, return ,</span></b>
  <b><span style='color:#E6F598;'>Return to wild ,</span></b> <br>
  <b><span style='color:#ABDDA4;'>Community cat ,</span></b>
  <b><span style='color:#66C2A5;'>Adoption ,</span></b> 
  <b><span style='color:#3288BD;'>Return to owner ,</span></b> <br> or 
  <b><span style='color:#7f7f7f;'>Other</span></b>."

longbeach <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-03-04/longbeach.csv')

# data on intake_condition and outcome
intake_outcome_count <- longbeach %>%
    filter(!is.na(outcome_type)) %>%
    count(intake_condition, outcome_type) %>%
    filter(intake_condition != "intakeexam") %>%
    group_by(intake_condition) %>%
    mutate(total = sum(n)) %>%
    filter(total > 900) %>%
    ungroup() %>%
    mutate(outcome_type = ifelse(n < 100, "other", outcome_type)) %>%
    group_by(intake_condition, outcome_type, total) %>%
    summarize(n = sum(n)/10) %>%
    ungroup() %>%
    mutate(intake_condition = str_wrap(str_to_title(intake_condition),10),
           intake_condition = fct_reorder(factor(intake_condition), desc(total)),
           outcome_type = factor(outcome_type,
                                 levels = c("euthanasia", "died", "transfer", "rescue", 
                                            "shelter, neuter, return", "return to wild habitat",
                                            "community cat", "adoption", "return to owner", "other"),
                                 ordered = T)) %>%
    arrange(outcome_type)

# plot_text <- intake_outcome_count %>%
#     filter(intake_condition == "Normal") %>%
#     arrange(outcome_type) %>%
#     mutate(position = cumsum(n),
#            position_lag = lag(position),
#            position_lag = ifelse(is.na(position_lag), 0, position),
#            text_position = (position + position_lag)/2,
#            show_text = n > 20)

waffle_plot <- ggplot(intake_outcome_count) +
    geom_waffle(aes(fill = outcome_type, values = n),
                color = "gray30", size = 0.25, n_rows = 10, flip = TRUE) +
    facet_wrap(~intake_condition, nrow = 1, strip.position = "bottom") +
    theme_void(16) +
    scale_y_continuous(expand = c(0,0)) +
    scale_fill_manual(values = c(brewer.pal(9, "Spectral"), "gray50")) +
    guides(fill = "none",
           color = "none") +
    theme(
        text = element_text(family = body_font, color = "gray70"),
        strip.text.x = element_text(face = "bold", size = 15, lineheight = 0.5),
        plot.background = element_rect(fill ="gray30", color = "gray30")
    ) +
    labs(caption = "Source: {animalshelter} via TidyTuesday")

# Display the plot
print(waffle_plot)

# Add custom text using gridtext in a fixed position
grid.text(str_wrap(title, 30), 
          x = unit(0.7, "npc"),  # Relative x position (0 to 1 scale)
          y = unit(0.8, "npc"),  # Relative y position (0 to 1 scale)
          gp = gpar(col = "gray70", 
                    fontsize = 40, fontface = "bold", family = title_font, lineheight = 0.5))

grid.draw(richtext_grob(subtitle,
          x = unit(0.7, "npc"),  # Relative x position (0 to 1 scale)
          y = unit(0.62, "npc"),  # Relative y position (0 to 1 scale)
          gp = gpar(col = "gray70", 
                    fontsize = 20, fontface = "italic", family = body_font, lineheight = 0.5)))

#saved using the export feature.

