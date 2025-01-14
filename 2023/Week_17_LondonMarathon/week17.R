library(tidyverse)
library(purrr)
library(rnaturalearth)
library(patchwork)
library(ggtext)
library(showtext)
library(showtextdb)
library(paletteer)
library(packcircles)
library(lubridate)
tuesdata <- tidytuesdayR::tt_load(2023, week = 17)

winners <- tuesdata$winners
london_marathon <- tuesdata$london_marathon
world <- ne_countries(returnclass = "sf")

font_add_google("Fraunces", family = "plottitle")
font_add_google("Outfit", family = "title")
font_add_google("Saira", family = "caption")


font_add('fa-reg', 'fonts/Font Awesome 6 Free-Regular-400.otf')
font_add('fa-brands', 'fonts/Font Awesome 6 Brands-Regular-400.otf')
font_add('fa-solid', 'fonts/Font Awesome 6 Free-Solid-900.otf')

showtext_auto()

winners <- winners %>%
  mutate(Year = ymd(Year, truncated = 2L))
  # mutate(Year = as.Date(as.character(Year), format = "%Y")) 

# Facetted Graph
p1 <- ggplot(winners) +
  geom_line(aes(x = Year, y = Time), color = "#99C5E3FF") +
  geom_point(data = winners %>% filter (Year == "1981-01-01" | Year == "2022-01-01"), 
             aes(x = Year, y = Time), color = "#99C5E3FF", size = 1.5) +
  geom_point(data = winners %>% filter ((Category == "Wheelchair Men" | Category == "Wheelchair Women") & 
                                          (Year == "1983-01-01" | Year == "2021-01-01")), 
             aes(x = Year, y = Time), color = "#99C5E3FF", size = 1.5) +
  facet_wrap(~ Category) +
  labs(title = "Duration for each year's winner to complete the parcour",
       x = "",
       y = "Duration in H/M/S") +
  theme(plot.background = element_rect(fill = "#F0F0F2", color = NA),
        plot.title = element_markdown(size = 70, family = "title", color = "#4A7BA8FF", hjust = 0.5),
        axis.title.y = element_markdown(color="#76A7CCFF", size = 55, face="bold"),
        axis.text.y= element_markdown(color="#4A7BA8FF", size = 45, face="bold"),
        axis.text.x = element_markdown(color="#4A7BA8FF", size = 55, face="bold"),
        strip.text.x = element_markdown(color="#76A7CCFF", size = 55, face="bold"))

# Map
winners_nationality <- winners %>%
  group_by(Nationality) %>%
  summarize(winners_n = n()) %>%
  mutate(Nationality = case_when(Nationality == "Soviet Union" ~ "Russia",
                                 Nationality == "United States" ~ "United States of America",
                                 .default = as.character(Nationality)))


winners_data <- world %>%
  left_join(winners_nationality, by = c("sovereignt" = "Nationality")) %>%
  mutate(winners_n = if_else(is.na(winners_n), 0, winners_n)) %>%
  filter(sovereignt != "Antarctica") %>%
  select(sovereignt, winners_n, geometry)

p2 <- ggplot(winners_data, aes(fill = log(winners_n))) +
  geom_sf(colour = "grey", lwd = 0.1) +
  scale_fill_paletteer_c("ggthemes::Blue") +
  labs(title = "Where do winners' come from?") +
  theme_void() +
  theme(legend.position = "none",
        plot.title = element_markdown(size = 70, family = "title", color = "#4A7BA8FF", hjust = 0.5))

 
# Circle Plot

circle_plot <- winners_data %>%
  group_by(winners_n) %>%
  arrange(desc(winners_n)) %>%
  head(29) %>%
  as.data.frame()

circle_plot <- circle_plot[!duplicated(circle_plot$sovereignt), ]

circle_plot <- circle_plot %>%
  mutate(sovereignt = case_when(sovereignt == "United Kingdom" ~ "UK",
                                sovereignt == "United States of America" ~ "USA",
                                .default = as.character(sovereignt)),
         rounded = round(winners_n, 2),
         label = paste0(sovereignt ,"\n",rounded))


packing <- circleProgressiveLayout(circle_plot$rounded, sizetype='area')
circle_plot <- cbind(circle_plot, packing)
dat.gg <- circleLayoutVertices(packing, npoints=50)
dat.gg$value <- rep(circle_plot$winners_n, each=51)


p3 <- ggplot() + 
  geom_polygon(data = dat.gg, aes(x, y, group = id, fill= value), colour = "black", alpha = 0.6) +
  geom_text(data = circle_plot, aes(x, y, label = label, lineheight = 0.1), size = 15, family = "mono") +
  # scale_size_continuous(range = c(1,4)) +
  scale_fill_paletteer_c("ggthemes::Blue") +
  theme_void() + 
  coord_equal() +
  labs(title = "Winners' Nationalities") +
  theme(legend.position = "none",
        plot.title = element_markdown(size = 70, family = "title",  hjust = 0.5, color = "#4A7BA8FF"))
  

plot <- p1 + p3 +
  plot_layout(widths = c(1, 1.5), 
              heights = c(1, 3),
              ncol = 2, nrow = 1) 

plot / p2 +
  plot_layout(ncol = 1, nrow = 2, heights = c(1, 1)) +
  plot_annotation(
    title = "London Marathon Winners",
    subtitle = "This week's #TidyTuesday data presents details on the London Marathon, which has been organized since 1981.",
    caption = "Source: {LondonMarathon} | Plot: <span style='font-family:fa-brands'>&#xf09b;</span> muhammetozkaraca  <span style='font-family:fa-brands'>&#xf099;</span> muhammetozkrca | #TidyTuesday-Week 17",
    theme = theme(plot.background = element_rect(fill = "#F0F0F2", color = NA),
                  panel.background = element_rect(fill = "#F0F0F2", color = NA),
                  plot.title = element_markdown(color = "#4A7BA8FF", size = 175, family = "plottitle", hjust = 0.5),
                  plot.subtitle = element_markdown(color = "#4A7BA8FF", size = 110, family = "title", hjust = 0.5),
                  plot.caption = element_markdown(color = "black", size = 55, family = "caption", hjust = 0.5)))

ggsave("/Users/muhammetozkaraca/Desktop/london-marathon.png", width = 10, height = 8, dpi = 720)








