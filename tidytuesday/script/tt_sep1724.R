library(tidyverse)
library(syuzhet)
library(camcorder)
library(ggrepel)

gg_record(
    dir = file.path(tempdir(), "recording_tt_sep17"), # where to save the recording
    device = "png", # device to use to save images
    width = 8,      # width of saved image
    height = 6,     # height of saved image
    units = "in",   # units for width and height
    dpi = 300       # dpi to use when saving image
)

set.seed(1)

romeo_juliet <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-09-17/romeo_juliet.csv') %>%
    filter(!is.na(line_number)) %>%
    mutate(act = factor(act))

line_sentiments_type <- get_nrc_sentiment(romeo_juliet$dialogue)

romeo_juliet <- romeo_juliet %>%
    cbind(line_sentiments_type) %>%
    pivot_longer(cols = anger:positive,
                 names_to = "emotions",
                 values_to = "value") %>%
    group_by(line_number) %>%
    mutate(
        max_value = max(value),
        rank = rank(desc(value), ties.method = "random"),
        max_emotion = ifelse(max_value == 0, "neutral", emotions[rank == 1])
    )

# I want to get different emotions by act, and then place it circularly

romeo_juliet_circular_plot <- romeo_juliet %>% 
    filter(max_emotion != "neutral") %>%
    select(line_number, max_emotion, act, sentiment_score) %>%
    distinct() %>%
    group_by(act,max_emotion) %>%
    count() %>%
    ungroup()

# find most emotional dialogue
most_emotional_dialogue <- romeo_juliet %>%
    select(act, scene, character, line_number, dialogue, max_emotion, max_value) %>%
    distinct() %>%
    filter(max_emotion != "neutral") %>%
    group_by(max_emotion) %>%
    mutate(dialogue_rank = rank(desc(max_value), ties.method = "random")) %>%
    filter(dialogue_rank == 1) %>%
    mutate(print = paste0(dialogue, " - ", character),
           print = str_wrap(print, 30))


# add empty bars for spacing since 5 acts
empty_bar <- 5

# add lines to the initial dataset

to_add <- data.frame(matrix(NA, empty_bar*nlevels(romeo_juliet_circular_plot$act), ncol(romeo_juliet_circular_plot)))

colnames(to_add) <- colnames(romeo_juliet_circular_plot)

to_add$act <- rep(levels(romeo_juliet_circular_plot$act), each=empty_bar)

romeo_juliet_circular_plot <- rbind(romeo_juliet_circular_plot, to_add)

romeo_juliet_circular_plot <- romeo_juliet_circular_plot %>% arrange(act, desc(n))

romeo_juliet_circular_plot$id <- seq(1, nrow(romeo_juliet_circular_plot))

# Get the name and the y position of each label

label_data <- romeo_juliet_circular_plot
number_of_bar <- nrow(label_data)
angle <- 90 - 360 * (label_data$id-0.5) /number_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)

label_data$hjust <- ifelse( angle < -90, 1, 0)
label_data$angle <- ifelse(angle < -90, angle+180, angle)

# add dialogue placement

most_emotional_dialogue <- most_emotional_dialogue %>%
left_join(label_data) %>%
    # position
    mutate(pos = n + 10,
           curve_x = id,
           curve_y = n + 60,
           curve_x_end = id, 
           curve_y_end = pos - 40) 

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

emotion_colors <- c(
    "anger" = "#FF0000",
    "anticipation" = "#FFD700",
    "disgust" = "#556B2F",
    "fear" = "#800080",
    "joy" = "#FFFF00",
    "sadness" = "#1E90FF",
    "surprise" = "#FF4500",
    "trust" = "#008000",
    "negative" = "#A9A9A9",
    "positive" = "#00FF7F"
)

plot <- ggplot(romeo_juliet_circular_plot, 
            aes(x=as.factor(id), y=n, fill=max_emotion)) + 
    geom_bar(stat="identity", alpha=0.5) +
    
    # Add lines.
    geom_segment(data=grid_data, aes(x = end, y = 120, xend = start, yend = 120), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
    geom_segment(data=grid_data, aes(x = end, y = 90, xend = start, yend = 90), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
    geom_segment(data=grid_data, aes(x = end, y = 60, xend = start, yend = 60), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
    geom_segment(data=grid_data, aes(x = end, y = 30, xend = start, yend = 30), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE) +
    
    # Add text showing the value of each lines
    annotate("text", x = rep(max(romeo_juliet_circular_plot$id),4), y = c(30, 60, 90, 120), label = c("30", "60", "90", "120") , color="grey", size=3 , angle=0, fontface="bold", hjust=1) +
    ylim(-100,180) +
    
    # Add most emotional dialogue
    geom_text_repel(data = most_emotional_dialogue, aes(x = id, y = pos, label = print, color = max_emotion), lineheight = 0.7, size = 2) +

    # and joining segment
    geom_segment(data = most_emotional_dialogue, 
               aes(x = curve_x, y =curve_y, yend = curve_y_end, xend = curve_x_end, color = max_emotion), size = 0.3, inherit.aes = FALSE,
               arrow = arrow(type = "closed", length = unit(0.05, "inches"))) +
    theme_minimal() +
    theme(
        legend.position = "none",
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_blank(),
        plot.margin = unit(rep(-1,4), "cm") 
    ) +
    
    coord_polar() + 
    
    # Add bar labels
    geom_text(data=label_data, aes(x=id, y=n+10, label=max_emotion, hjust=hjust), color="black", fontface="bold",alpha=0.6, size=2.5, angle= label_data$angle, inherit.aes = FALSE ) +
    
    # Add base line information
    geom_segment(data=base_data, aes(x = start, y = -5, xend = end, yend = -5), colour = "black", alpha=0.8, size=0.6 , inherit.aes = FALSE )  +
    geom_text(data=base_data, aes(x = title, y = -18, label=act), hjust=c(1, 1,1,0,0), colour = "black", alpha=0.8, size=4, fontface="bold", inherit.aes = FALSE) +
    
    scale_color_manual(
        values = emotion_colors
    ) +
    scale_fill_manual(
        values = emotion_colors
    )

plot
gg_stop_recording()
