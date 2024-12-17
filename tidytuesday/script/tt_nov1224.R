library(tidyverse)
library(gt)
library(gtExtras)
library(ggcirclepack)
library(grid)

countries <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-12/countries.csv')
country_subdivisions <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-12/country_subdivisions.csv')
former_countries <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-12/former_countries.csv') |>
    mutate(
        date_withdrawn = ifelse(nchar(date_withdrawn) == 4, 
                                date_withdrawn,
                                str_sub(date_withdrawn, 1, 4)))

# An analysis of 31 changes into the codes
# Same numeric code but different names: 10 - change of name
# Some comments suggest split-ups: 7
# Different numeric code and names: 
# Integrated into other countries:
# Cease to exist

# renamed countries
same_numeric <- tibble(
    numeric = intersect(unique(former_countries$numeric), unique(countries$numeric))) |>
    left_join(former_countries, by = 'numeric') |>
    select(numeric, name, date_withdrawn) |>
    rename("former_name" = name) |>
    left_join(select(countries, numeric, name), by = "numeric") |>
    rename("current_name" = name) |>
  select(former_name, current_name, date_withdrawn) |>
  rename("Former Name" = former_name, 
         "New Name" = current_name,
         "Date Withdrawn" = date_withdrawn)

# became country_subdivision
same_name <- tibble(
    name = intersect(former_countries$name, 
                     country_subdivisions$name)) |>
    left_join(former_countries, by = 'name') |>
    select(numeric, alpha_3, name, date_withdrawn) |>
    rename("former_alpha3" = alpha_3) |>
    left_join(select(country_subdivisions,name, code), by = "name") |>
        rename("current_code" = code)|>
  select(name, former_alpha3, current_code, date_withdrawn) |>
  rename("Name" = name,
         "Former Code" = former_alpha3,
         "New Code" = current_code,
         "Date Withdrawn" = date_withdrawn)
  
# countries that split  
split <- former_countries |>
    filter(!is.na(comment)) |>
    select(name, date_withdrawn) |>
    filter(!name %in% c(same_numeric$`Former Name`, 
                      same_name$Name)) 
            
# unaccounted
unaccounted <- former_countries |>
    filter(!name %in% c(same_numeric$`Former Name`, 
                        same_name$Name, split$name)) |>
    select(name, date_withdrawn)

# Some hand corrections - add countries that split
split <- split |>
    rbind(unaccounted[c(2:3,11),]) |>
    rename("Former Name" = name,
           "Date Withdrawn" = date_withdrawn
    )

unaccounted <- unaccounted[-c(2:3,11),]

# Countries that merged with others
merged <-  unaccounted[c(2,3:4, 7:10),] |>
  mutate(
    merged_into = c("Kiribati", "Germany", "France",  "Marshall Islands","Panama", "Viet Nam", "Yemen")
  ) |>
  select(name, merged_into, date_withdrawn) |>
  rename("Former Name" = name,
         "Country Merged Into" = merged_into,
         "Date Withdrawn" = date_withdrawn) 

unaccounted <- unaccounted[-c(2,3:4, 7:10),] |>
  rename("Former Name" = name,
         "Date Withdrawn" = date_withdrawn) 

get_year_plot <- function(date_withdrawn){
  # create year data
  year_data <- tibble(
    year = 1970:2015,
    x = 0
  ) |>
    mutate(x = ifelse(year == parse_number(date_withdrawn), 0.1, x))
  
  # crearw plot
  year_plot <- ggplot(year_data) +
    geom_line(aes(x = year, y = x), color = "gray40", linewidth = 2) +
    geom_text(aes(x = year, y = x, label = year, color = x == 0.1), nudge_x = 5, size = 7) +
    scale_color_manual(values = c("transparent", "gray20"))+
    annotate("text", x = 1970, y = -0.01, label = "1970", color = "gray50", size = 4.5) +
    annotate("text", x = 2015, y = -0.01, label = "2015", color = "gray50", size = 4.5) +  
    theme_void() +
    theme(legend.position = "none") 

  return(year_plot)
}

get_gt_table <- function(data, table_color, reason){
  gt_table <- data |> 
    arrange(`Date Withdrawn`) |>
    # rowwise() |>
    # mutate(plot = map(`Date Withdrawn`, get_year_plot)) |>
    # ungroup() |>
    gt() |>
    text_transform(
      locations = cells_body(columns = 'Date Withdrawn'),
      fn = function(column) {
        map(column, get_year_plot) |> 
          # Save images manually bc ggplot_img() seems to lose some imgs
          walk2(1:nrow(data), \(x, y) {
            ggsave(
              filename = paste0('imgs/', reason, '_',y, '.jpeg'),
              plot = x,
              device = 'jpeg',
              height = 6,
              width = 10,
              unit = 'cm'
            )
          })
        
        glue::glue(
          '<img src="imgs/{reason}_{seq_along(column)}.jpeg" style="height:75px"></img>'
        )
      } 
    ) |>
    tab_options(
      #column_labels.hidden = TRUE,
      table.font.names = 'Source Sans Pro',
      table_body.border.top.style = 'none',
      table.border.top.style = 'none',
      table_body.border.bottom.style = 'none',
      table.border.bottom.style = 'none',
      column_labels.background.color = table_color,
      column_labels.border.top.style = 'none'
    )
  
  return(gt_table)
}

table_panel_colors <- RColorBrewer::brewer.pal(5, "Pastel1")

# get table in one

df_list <- list(same_numeric, split, merged, same_name, unaccounted)
names(df_list) <- c("Changed Country Name", "Country Splitted",
                    "Country Merged", "Became a Subdivision","Reason Unclear")

all_tables <- pmap(list(df_list, 
     table_panel_colors,
     names(df_list)),
     ~get_gt_table(..1, ..2,..3))

tables_tib <- tibble(
  level = c("Changed Country Name", "Country Splitted", "Country Merged", "Became a Subdivision","Reason Unclear"),
  table = map_chr(all_tables, as_raw_html)
) |>
  pivot_wider(names_from = level, values_from = table)



levels_text_size <- px(20)

former_country_table <- tables_tib |>
  gt(id = 'former table') |>
  fmt_markdown(columns = everything()) |>
  cols_align(align = 'left') |>
  tab_header(
    title = 'The Case of Former Countries',
    subtitle = 'An Examination of 31 Countries that no longer have an ISO Country Code'
  ) |>
  tab_footnote(
    footnote = 'Source: ISO Country Code, #TidyTuesday',
    placement = 'right'
  ) |>
  tab_style(
    style = list(
      cell_fill(color = table_panel_colors[1]),
      cell_text(color = 'gray30', weight = 'bold')
    ),
    locations = list(
      cells_body(columns = 'Changed Country Name', rows = 1),
      cells_column_labels(column = 'Changed Country Name')
    )
  ) |>
  tab_style(
    style = list(
      cell_fill(color = table_panel_colors[2]),
      cell_text(color = 'gray30', weight = 'bold')
    ),
    locations = list(
      cells_body(columns = 'Country Splitted', rows = 1),
      cells_column_labels(column = 'Country Splitted')
    )
  ) |>
  tab_style(
    style = list(
      cell_fill(color = table_panel_colors[3]),
      cell_text(color = 'gray30', weight = 'bold')
    ),
    locations = list(
      cells_body(columns = 'Country Merged', rows = 1),
      cells_column_labels(column = 'Country Merged')
    )
  ) |> 
  tab_style(
    style = list(
      cell_fill(color = table_panel_colors[4]),
      cell_text(color = 'gray30', weight = 'bold')
    ),
    locations = list(
      cells_body(columns = 'Became a Subdivision', rows = 1),
      cells_column_labels(column = 'Became a Subdivision')
    )
  ) |> 
  tab_style(
    style = list(
      cell_fill(color = table_panel_colors[5]),
      cell_text(color = 'gray30', weight = 'bold')
    ),
    locations = list(
      cells_body(columns = 'Reason Unclear', rows = 1),
      cells_column_labels(column = 'Reason Unclear')
    )
  ) |>
  tab_style(
    style = cell_text(size = levels_text_size),
    locations = cells_column_labels()
  ) |>
  tab_style(
    style = cell_text(size = px(30), color = 'gray10', weight = 'bold', align = 'center'),
    locations = cells_title('title')
  ) |>
  tab_style(
    style = cell_text(size = px(25), color = 'gray20', weight = 'bold', align = 'center'),
    locations = cells_title('subtitle')
  ) |>
  tab_options(
    table_body.border.top.style = 'none',
    table.border.top.style = 'none',
    table_body.border.bottom.style = 'none',
    table.border.bottom.style = 'none',
    table_body.hlines.style = 'none',
    table_body.vlines.style = 'solid',
    column_labels.border.top.style = 'none',
    column_labels.border.bottom.style = 'none',
    column_labels.border.lr.width = px(1),
    column_labels.padding = px(1),
    data_row.padding = px(2),
    table.font.names = 'Source Sans Pro',
    heading.title.font.size = px(60),
    heading.title.font.weight = 'bold',
    heading.subtitle.font.size = px(45),
    heading.subtitle.font.weight = 'bold',
    heading.border.bottom.style = 'none'
  ) 

former_country_table

# Make a circle plot using ggcirclepack

# make data
merged_df <- map2_dfr(df_list, 1:length(df_list), ~.x |>
                          mutate(category = names(df_list)[.y])) |>
    janitor::clean_names() |>
    mutate(former_name = ifelse(is.na(former_name), name, former_name),
           n = 1) 

category_df <- merged_df |>
    count(category) |>
    mutate(former_name = category)

category_merged_df <- merged_df |>
    bind_rows(category_df) |>
    mutate(
        label = ifelse(!is.na(date_withdrawn),
                       paste(str_wrap(former_name,10), date_withdrawn, sep = "\n"),
                       paste(str_wrap(former_name,10), n, sep = "\n")
        )
    )

plot <- ggplot() +
    geom_circlepack(data = category_merged_df, 
                    aes(id = former_name, 
                        fill = category,
                        area = n),
                    show.legend = FALSE) +
    geom_circlepack_text(data = category_merged_df,
                         aes(id = former_name,
                             area = n,
                             label = label,
                             size = is.na(date_withdrawn),
                             color = is.na(date_withdrawn)
                         ),
                         lineheight = 0.8,
                         fontface = "bold",
                         show.legend = FALSE) +
    scale_color_manual(values = c("gray50", "gray30")) +
    scale_size_manual(values = c(5, 10)) +
    scale_fill_manual(values = RColorBrewer::brewer.pal(5, "Pastel1"))+
    facet_wrap(~category, scales = "free") + 
    labs(caption = "Source: ISO Country Code, #TidyTuesday")+
    theme_minimal(30) +
    theme(
        strip.text = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_blank(),
        panel.background = element_rect(fill = "gray90", color = "transparent"),
        plot.background = element_rect(fill = "gray90", color = "transparent")
    ) 


grid.newpage()  # Start a new drawing page
grid.draw(ggplotGrob(plot))  # Draw the saved ggplot object

# Place the custom text
grid.text(str_wrap("The Case of Former Countries: 
                   An analysis of 31 nations that no longer hold an ISO country code, revealing that changes in country names are the most common contributing factor.", 22),
          x = 0.8, y = 0.3,  # Position (normalized coordinates: 0 to 1)
          gp = gpar(fontsize = 36, fontface = "bold", col = "gray20", lineheight = 0.9))

dev.print(png, filename = "products/tt_nov1124_country_codes.png", width = 1400, height = 1000)
dev.off()
