library(tidyverse)
library(syuzhet)
#library(camcorder)
library(ggrepel)
library(showtext)
library(ggtext)

font_add_google("Cinzel Decorative", "rnj")
font_add_google("Baloo 2", "io")
showtext_auto()

romeo_juliet <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-09-17/romeo_juliet.csv') %>%
    filter(!is.na(line_number)) %>%
    mutate(act = factor(act))

line_sentiments_type <- get_nrc_sentiment(romeo_juliet$dialogue)

set.seed(1)
romeo_juliet <- romeo_juliet %>%
    cbind(line_sentiments_type) %>%
    pivot_longer(cols = anger:trust,
                 names_to = "emotions",
                 values_to = "value") %>%
    group_by(line_number) %>%
    mutate(
        max_value = max(value),
        rank = rank(desc(value), ties.method = "random"),
        max_emotion = ifelse(max_value == 0, "neutral", emotions[rank == 1])
    ) %>%
    mutate(binary = case_when(
        positive > negative ~ 1,
        negative > positive ~ -1,
        positive == negative ~ 0
    ))

# I want to get different emotions by act, and then place it circularly

romeo_juliet_circular_plot <- romeo_juliet %>% 
    filter(max_emotion != "neutral") %>%
    select(line_number, max_emotion, act) %>%
    distinct() %>%
    group_by(act,max_emotion) %>%
    count() %>%
    ungroup()

# add empty bars for spacing since 5 acts
empty_bar <- 5

# add lines to the initial dataset

to_add <- data.frame(matrix(NA, empty_bar*nlevels(romeo_juliet_circular_plot$act), ncol(romeo_juliet_circular_plot)))

colnames(to_add) <- colnames(romeo_juliet_circular_plot)

to_add$act <- rep(levels(romeo_juliet_circular_plot$act), each=empty_bar)

romeo_juliet_circular_plot <- rbind(romeo_juliet_circular_plot, to_add)

romeo_juliet_circular_plot <- romeo_juliet_circular_plot %>% arrange(act)

romeo_juliet_circular_plot$id <- seq(1, nrow(romeo_juliet_circular_plot))

# Get the name and the y position of each label

label_data <- romeo_juliet_circular_plot
number_of_bar <- nrow(label_data)
angle <- 90 - 360 * (label_data$id-0.5) /number_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)

label_data$hjust <- ifelse( angle < -90, 1, 0)
label_data$angle <- ifelse(angle < -90, angle+180, angle)


# prepare a data frame for base lines
base_data <- romeo_juliet_circular_plot %>% 
    group_by(act) %>% 
    summarize(start=min(id), end=max(id) - empty_bar) %>% 
    rowwise() %>% 
    mutate(title=mean(c(start, end)))

# prepare a data frame for grid (scales)
grid_data <- base_data
grid_data$end <- grid_data$end[ c( nrow(grid_data), 1:nrow(grid_data)-1)] + 1
grid_data$start <- grid_data$start - 1
grid_data <- grid_data[-1,]

extended_inside_out_colors <- c(
    "joy" = "#DAA520",        # Yellow
    "sadness" = "#1E90FF",    # Blue
    "anger" = "#FF0000",      # Red
    "fear" = "#800080",       # Purple
    "disgust" = "#556B2F",    # Green
    "anticipation" = "#FFA500", # Orange
    "trust" = "#228B22",      # Light Green
    "surprise" = "#FF69B4"    # Light Pink
)

set.seed(1)
# find most emotional dialogue
most_emotional_dialogue <- romeo_juliet %>%
    select(act, scene, character, line_number, dialogue, max_emotion, max_value) %>%
    distinct() %>%
    filter(max_emotion != "neutral") %>%
    group_by(max_emotion) %>%
    mutate(dialogue_rank = rank(desc(max_value), ties.method = "random")) %>%
    filter(dialogue_rank == 1) %>%
    ungroup() %>%
    arrange(act, scene) %>%
    mutate(print = paste0(str_to_title(max_emotion), ": ",dialogue, " - ", character, " ", act, ", ", scene),
           print = str_wrap(print, 30),
           xpos = seq(3,max(romeo_juliet_circular_plot$id),
                      max(romeo_juliet_circular_plot$id) %/% 8)[1:8],
           ypos = c(130, 167, 160, 180, 160, 150, 130, 130))


plot <- ggplot(romeo_juliet_circular_plot, 
            aes(x=as.factor(id), y=n, fill=max_emotion)) + 
    geom_bar(stat="identity", alpha=0.5) +
    
    # Add lines.
    # geom_segment(data=grid_data, aes(x = end, y = 120, xend = start, yend = 120), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
    geom_segment(data=grid_data, aes(x = end, y = 90, xend = start, yend = 90), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE) +
    geom_segment(data=grid_data, aes(x = end, y = 60, xend = start, yend = 60), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
    geom_segment(data=grid_data, aes(x = end, y = 30, xend = start, yend = 30), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE) +
    
    # Add text showing the value of each lines
    annotate("text", x = rep(max(romeo_juliet_circular_plot$id),3), y = c(30, 60, 90), label = c("30", "60", "90") , color="grey", size = 7 , angle=0, fontface="bold", hjust=1, family = "rnj") +
    ylim(-60,180) +
    # labs(
    #     caption = "Source: shakespeare.mit.edu via github/nrennie"
    # ) +
    # Add title
    annotate("text", x = 5, y = -50, label = "Romeo & Juliet" , color="#8A0303", size=12 , angle=0, fontface="bold", hjust=0.5, family = "rnj") +
    annotate("text", x = 20, y = -50, label = "Meets Inside Out" , color="#FF69B4", size=12 , angle=0, fontface="bold", hjust=.75, family = "io") +
    
    # Add caption
    annotate("text", x = 22, y = 170, label = str_wrap("Source: shakespeare.mit.edu via github/nrennie",30) , size = 7, angle=0, hjust=0.25, family = "rnj",
             lineheight = 0.3) +
    
    # Add subtitle
    # annotate("text", x = 30, y = -50, label = "Emotion-coded lines by Act" , color="#FF69B4", size = 5 , angle=0, fontface="italic", hjust=0.5, family = "io") +
    
    # Add most emotional dialogue
    geom_text(data = most_emotional_dialogue, aes(x = xpos, y = ypos, label = print, color = max_emotion), lineheight = 0.3, size = 10, family = "rnj", fontface = "bold") +
    #                  arrow = arrow(type = "closed", length = unit(0.05, "inches"))) +
    
    theme_minimal() +
    theme(
        text = element_text(family = "rnj"),
        axis.title = element_blank(),
        legend.position = "none",
        axis.text = element_blank(),
        panel.background = element_rect(fill = "gray90"),
        panel.grid = element_blank(),
        plot.margin = unit(rep(-2, 4), "cm") 
    ) +
    
    coord_polar() + 
    
    # Add bar labels
    geom_text(data=label_data, aes(x=id, y=n+5, label=max_emotion, hjust=hjust), color="gray20", fontface="bold",alpha=0.6, size = 8, angle= label_data$angle, inherit.aes = FALSE, family = "rnj") +
    
    # Add base line information
    geom_segment(data=base_data, aes(x = start, y = -5, xend = end, yend = -5), colour = "gray20", alpha=0.8, size=0.6 , inherit.aes = FALSE )  +
    
    geom_text(data=base_data, aes(x = title, y = -17, label=act), hjust= c(0.6, 0.5, 0.5, 0.3,0.4), colour = "gray20", alpha=0.8, size = 8, fontface="bold", inherit.aes = FALSE, family = "rnj") +
    
    scale_color_manual(
        values = extended_inside_out_colors
    ) +
    scale_fill_manual(
        values = extended_inside_out_colors
    )

plot

ggsave("products/tt_sep1724_romeo_juliet_emotions.png", width = 9, height = 8, units = "in")

abstract_art1 <- romeo_juliet %>%
    ungroup() %>%
    select(line_number, binary) %>%
    distinct() %>%
    mutate(index = row_number(),
           index = index %/% 100 + 1) %>%
    group_by(index) %>%
    mutate(line_number = line_number - min(line_number) + 1) %>%
    ungroup() %>%
    ggplot(aes(y = fct_rev(factor(index)), x = factor(line_number), fill = factor(binary))) +
    geom_raster(interpolate = TRUE,
                show.legend = F) +
    annotate("text", y = 1, x = 98, label = "The End.",
             color = "#8A0303" , family = "rnj", fontface = "italic", size = 8) +
    labs(
        title = "Presenting Romeo & Juliet",
        subtitle = "See left to right, top to botom: Each tile represents sequential dialogue.\nColor coded each dialogue as positive (orange), negative (blue), or neutral (beige)",
        caption = "Source: shakespeare.mit.edu via github/nrennie"
    ) +
    theme_void() +
    theme(
        plot.title = element_text(color = "#8A0303", size = 24),
        text = element_text(size = 14, family = "rnj"),
        plot.background = element_rect(fill = "#D8CFC4")
    ) +
    scale_fill_manual(
        values = c("#4862A3", "#D8CFC4", "#FF6700")
    )

abstract_art2 <- romeo_juliet %>%
    ungroup() %>%
    select(line_number, max_emotion) %>%
    distinct() %>%
    mutate(index = row_number(),
           index = index %/% 100 + 1) %>%
    group_by(index) %>%
    mutate(line_number = line_number - min(line_number) + 1) %>%
    ungroup() %>%
    filter(max_emotion != "neutral") %>%
    ggplot(aes(y = fct_rev(factor(index)), x = factor(line_number), fill = factor(max_emotion))) +
    geom_raster(interpolate = TRUE,
                show.legend = F) +
    annotate("text", y = 1, x = 98, label = "The End.",
             color = "#AA6FBF" , family = "io", fontface = "italic", size = 8) +
    labs(
        title = "Presenting Romeo & Juliet, Inside-Out style",
        subtitle = "See left to right, top to botom: Each tile represents sequential dialogue.\nColor coded each dialogue as joy, sadness, anger, disgust, fear, anticipation, trust, surprise.",
        caption = "Source: shakespeare.mit.edu via github/nrennie"
    ) +
    theme_void() +
    theme(
        plot.title = element_text(color = "#AA6FBF", size = 24, hjust = 0.5),
        plot.subtitle = element_text(color = "azure", hjust = 0.5),
        plot.caption = element_text(color = "azure"),
        text = element_text(size = 14, family = "io"),
        plot.background = element_rect(fill = "#3C4142")
    ) +
    scale_fill_manual(
        values = extended_inside_out_colors
    )
