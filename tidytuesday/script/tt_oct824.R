library(tidyverse)
library(ggraph)
library(igraph)
library(showtext)
library(RColorBrewer)

font_add_google("Oswald", "oswald")
showtext_auto()
# read data
most_visited_nps_species_data <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-10-08/most_visited_nps_species_data.csv') |>
    janitor::clean_names()

# code order names in a park in descending order
# connect rows
# top 15 most found 
visited_park_network_order <- most_visited_nps_species_data |>
  filter(record_status == "Approved", grepl("Present", occurrence)) |>
    count(park_code, park_name, category_name, order) |>
    filter(!is.na(order)) |>
  # if two same rows, then keep one randomly
    group_by(park_name) |>
    mutate(all_species = sum(n)) |>
    group_by(across(everything())) |>  # Group by all columns
    slice_sample(n = 1) |> 
    ungroup() |>
    group_by(park_code) |>
    arrange(desc(n)) |>
    slice_head(n = 15) |>
    arrange(category_name,order) |>
    mutate(from = order,
           to = lead(order),
           to = ifelse(is.na(to), order[1], to),
           prop_n = n/all_species) |>
    ungroup()

# create hierarchial structure
origin_group_df <- data.frame(
  from = "origin",
  to = unique(visited_park_network_order$category_name)
)

# category name for each order to name later
group_subgroup_df <-  visited_park_network_order |>
    distinct(category_name, order) |>
    filter(!is.na(category_name), !is.na(order)) |>
    rename(
        "from" = category_name,
        "to" = order
    )  |>
  group_by(to) |>  # Group by all columns
  slice_sample(n = 1) 

all_edges <- origin_group_df |>
  rbind(select(group_subgroup_df, c(from, to)))

# all connections
connect <- visited_park_network_order |>
  select(from, to, park_name, n, prop_n) |>
  mutate(
    value = runif(nrow((visited_park_network_order)))
  )

# all vertices
plot_vertices <- tibble(
    name = unique(c(all_edges$from, all_edges$to)), 
    value = runif(length(name))
) 

# vertices groups
plot_vertices <- plot_vertices |>
  left_join(group_subgroup_df, by = c("name" = "to")) |>
  mutate(
    group = from,
    group = ifelse(is.na(group), "origin", group),
    group = ifelse(name == "origin", NA_character_, group)
  ) |>
 select(-c(from)) 

#Let's add information concerning the label we are going to add: angle, horizontal adjustement and potential flip
#calculate the ANGLE of the labels
plot_vertices$id <- NA
myleaves <- which(is.na( match(plot_vertices$name, all_edges$from) ))
nleaves <- length(myleaves)
plot_vertices$id[ myleaves ] <- seq(1:nleaves)
#plot_vertices$angle <- 90 - 360 * plot_vertices$id / nleaves

# calculate the alignment of labels: right or left
# If I am on the left part of the plot, my labels have currently an angle < -90
#plot_vertices$hjust <- ifelse( plot_vertices$angle < -90, 1, 0)

# flip angle BY to make them readable
#plot_vertices$angle <- ifelse(plot_vertices$angle < -90, plot_vertices$angle+180, plot_vertices$angle)

plot_vertices <- plot_vertices |>
  group_by(group) |>
  mutate(group_name = ifelse(id == min(id), group, NA_character_)) |>
  ungroup()

# Create a graph object
mygraph <- igraph::graph_from_data_frame(all_edges, 
                                         vertices= plot_vertices)

# The connection object must refer to the ids of the leaves:
from  <-  match(connect$from, plot_vertices$name)
names(from) <- connect$park_name
attr(from, "count") <- connect$prop_n
to  <-  match(connect$to, plot_vertices$name)
 

ggraph(mygraph, layout = 'dendrogram', circular = TRUE) + 
  geom_conn_bundle(data = get_con(from = from, to = to, Parks = names(from), prop_count = attr(from, "count")), 
                   width=0.9, aes(colour=Parks, alpha = prop_count)) +
  scale_edge_colour_manual(values = c(brewer.pal(8, "Dark2"), brewer.pal(7, "Set1"))) +
  geom_node_point(aes(filter = leaf, x = x*1.07, y=y*1.07), 
                  color = "#d0bca2", size = 6, alpha=0.6, show.legend = FALSE)  +
  geom_node_text(aes(x = x*1.15, y=y*1.15, filter = leaf, label=name), size=7, color = "#3b342b", alpha=1, show.legend = FALSE, repel = TRUE, family = "oswald",max.overlaps = 200) +
  geom_node_text(aes(x = x*1.5, y=y*1.5, filter = leaf, label=group_name), color = "#324831", size=8, alpha=1, show.legend = FALSE, repel = TRUE, family = "oswald",max.overlaps = 200) +

  scale_edge_alpha(
    range = c(0.05, 0.18),
    breaks = c(0.5, 0.1, 0.15, 0.18),
    guide = "none") +
  labs(
    title = "Biodiversity Patterns in 15 US National Parks",
    subtitle = "This visual highlights the top 15 species in each park. Each node represents the species order and green labels show the beginning of a species category.\nOpacity indicates each species' proportion within the park's ecosystem.",
    caption = "Source: National Park Species via github/frankiethull"
  ) +
  theme_void(32) +
  theme(
    #legend.position="bottom",
    plot.margin=unit(c(0,0,0,0),"cm"),
    plot.background = element_rect(fill = "white", color = NA),
    text = element_text(family = "oswald", color = "gray40"),
    plot.subtitle = element_text(lineheight = 0.3),
    legend.text = element_text(size = 20),
    legend.spacing.y = unit(0.01, 'cm'),
    legend.spacing.x = unit(0.01, 'cm')
  ) +
  expand_limits(x = c(-1.3, 1.3), y = c(-1.3, 1.3))


ggsave("products/tt_oct0824_ecology.png", width = 8, height = 5)

 