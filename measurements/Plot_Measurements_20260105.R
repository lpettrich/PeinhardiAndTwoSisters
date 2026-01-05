# --- CLEAN START ---
rm(list = ls())
library(tidyverse)
library(ggbreak)

# --- Working directory ---
setwd("/Users/laupe/Documents/Uni-Köln/PhD/PanaGenomeReport/Zaii_SpeciesDescription/")

# --- Read data ---
d <- read.csv("measurements.csv", sep = ";", na.strings = "NA")

# --- Only rename the three target strains ---
d$Strain <- recode(d$Strain,
                   "ES5" = "einhardi",
                   "wwl072" = "nebliphilus",
                   "wwl115" = "shuimeiren"
)

# --- Characters as factors (reverse order) ---
d$Characters <- factor(d$Characters, levels = rev(unique(d$Characters)))

# --- Quick structure check ---
str(d)
unique(d$Strain)

# --- Quick plot to test ---
d %>%
  ggplot(aes(y = Characters, x = Female, fill = Strain)) +
  geom_col(position = position_dodge())

# --- Reshape long for main plotting ---
d_long <- d %>%
  pivot_longer(cols = c(Female, Male),
               names_to = "Sex",
               values_to = "Length") %>%
  pivot_longer(cols = c(FemaleSD, MaleSD),
               names_to = "SD_Sex",
               values_to = "SD") %>%
  filter(Sex == sub("SD", "", SD_Sex)) %>%
  select(-SD_Sex)

write.csv(d_long, file = "measurements_long-format.csv", row.names = FALSE)

# --- Set fixed colors for Sex ---
sex_colors <- c(
  "Female" = "#E69F00",  # orange
  "Male"   = "#56B4E9"   # blue
)

# --- Filter for selected strains ---
d_small <- d_long %>%
  filter(Strain %in% c("einhardii", "nebliphilus", "shuimeiren"))

# --- Define colors for strains ---
strain_colors <- c(
  "shuimeiren"    = "#E69F00",
  "nebliphilus"   = "#56B4E9",
  "einhardii"     = "#CC79A7"
)

# --- Plot small subset ---
p <- d_small %>%
  ggplot(aes(x = Characters, y = Length, fill = Sex)) +
  geom_col(position = position_dodge(width = 0.9)) +
  geom_errorbar(aes(ymin = Length - SD, ymax = Length + SD),
                position = position_dodge(width = 0.9),
                width = 0.2) +
  facet_wrap(~Sex, ncol = 2) +
  coord_flip() +
  scale_fill_manual(values = sex_colors) +
  labs(x = "Characters", y = "Length") +
  theme(
    axis.text.x = element_text(size = 14, color = "black"),
    axis.text.y = element_text(size = 14, color = "black"),
    axis.title.y = element_text(size = 14, face = "bold", color = "black"),
    axis.title.x = element_text(size = 14, face = "bold", color = "black"),
    title = element_text(size = 12, color = "black"),
    panel.background = element_rect(fill="white"),
    panel.grid.major = element_line("lightgrey"),
    panel.grid.minor = element_line("white"),
    panel.border = element_rect("black", fill = NA),
    plot.background = element_rect(fill="white"),
    legend.background = element_rect(fill="white"),
    legend.position="right"
  )

print(p)
ggsave("plot_small_morph.png", plot = p, width = 8, height = 5)
ggsave("plot_small_morph.svg", plot = p, width = 8, height = 5)

# --- Loop over each character (subset) ---
for (char in unique(d_small$Characters)) {
  d_char <- d_small %>% filter(Characters == char)
  
  p <- ggplot(d_char, aes(x = Strain, y = Length, fill = Sex)) +
    geom_col(position = position_dodge(width = 0.9)) +
    geom_errorbar(aes(ymin = Length - SD, ymax = Length + SD),
                  position = position_dodge(width = 0.9),
                  width = 0.2) +
    facet_wrap(~Sex) +
    coord_flip() +
    scale_fill_manual(values = sex_colors) +
    labs(title = paste("Character:", char),
         x = "Strain", y = "Length") +
    theme(
      axis.text.x = element_text(size = 14, color = "black"),
      axis.text.y = element_text(size = 14, color = "black"),
      axis.title.y = element_text(size = 14, face = "bold", color = "black"),
      axis.title.x = element_text(size = 14, face = "bold", color = "black"),
      title = element_text(size = 12, color = "black"),
      panel.background = element_rect(fill = "white"),
      panel.grid.major = element_line("lightgrey"),
      panel.grid.minor = element_line("white"),
      panel.border = element_rect("black", fill = NA),
      plot.background = element_rect(fill = "white"),
      legend.background = element_rect(fill="white"),
      legend.position="right"
    )
  
  print(p)
  file_base <- paste0("plot_subset_", gsub(" ", "_", char))
  ggsave(paste0(file_base, ".png"), plot = p, width = 6, height = 4)
  ggsave(paste0(file_base, ".svg"), plot = p, width = 6, height = 4)
}

# --- Reshape full dataset ---
d_long_all <- d %>%
  pivot_longer(cols = c(Female, Male), names_to = "Sex", values_to = "Length") %>%
  pivot_longer(cols = c(FemaleSD, MaleSD), names_to = "SD_Sex", values_to = "SD") %>%
  filter(Sex == sub("SD", "", SD_Sex)) %>%
  select(-SD_Sex) %>%
  filter(!is.na(Length), !is.na(SD))

# --- Compute mean Length per Strain ---
strain_order <- d_long_all %>%
  group_by(Strain) %>%
  summarise(mean_length = mean(Length, na.rm = TRUE)) %>%
  arrange(mean_length) %>%
  pull(Strain)

# --- Set global Strain order ---
d$Strain <- factor(d$Strain, levels = strain_order)

# --- Loop over Characters and plot ---
for (char in unique(d$Characters)) {
  d_char <- d %>% filter(Characters == char)
  
  d_long <- d_char %>%
    pivot_longer(cols = c(Female, Male), names_to = "Sex", values_to = "Length") %>%
    pivot_longer(cols = c(FemaleSD, MaleSD), names_to = "SD_Sex", values_to = "SD") %>%
    filter(Sex == sub("SD", "", SD_Sex)) %>%
    select(-SD_Sex) %>%
    filter(!is.na(Length), !is.na(SD)) %>%
    mutate(Strain = factor(Strain, levels = strain_order))
  
  p <- ggplot(d_long, aes(x = Strain, y = Length, fill = Sex)) +
    geom_col(position = position_dodge(width = 0.9)) +
    geom_errorbar(aes(ymin = Length - SD, ymax = Length + SD),
                  position = position_dodge(width = 0.9),
                  width = 0.2) +
    facet_wrap(~Sex) +
    coord_flip() +
    scale_fill_manual(values = sex_colors) +
    labs(title = paste("Character:", char),
         x = "Strain (sorted by body length)", y = "Length") +
    theme(axis.text.x = element_text(size = 14, color = "black"),
          axis.text.y = element_text(size = 14, color = "black"),
          axis.title.y = element_text(size = 14, face = "bold", color = "black"),
          axis.title.x = element_text(size = 14, face = "bold", color = "black"),
          title = element_text(size = 12, color = "black"),
          panel.background = element_rect(fill="white"),
          panel.grid.major = element_line("lightgrey"),
          panel.grid.minor = element_line("white"),
          panel.border = element_rect("black", fill = NA),
          plot.background = element_rect(fill="white"),
          legend.background = element_rect(fill="white"),
          legend.position="right") 
  
  print(p)
  ggsave(paste0("plot_", char, ".png"), plot = p, width = 8, height = 4)
  ggsave(paste0("plot_", char, ".svg"), plot = p, width = 8, height = 4)
}

# --- Pairwise overlap check ---
overlap_df <- d_long_all %>%
  mutate(
    lower = Length - SD,
    upper = Length + SD
  ) %>%
  group_by(Characters, Sex) %>%
  summarise(
    pairwise = list({
      combn(Strain, 2, simplify = FALSE, FUN = function(pair) {
        A <- filter(cur_data(), Strain == pair[1])
        B <- filter(cur_data(), Strain == pair[2])
        
        overlap <- (A$lower <= B$upper) & (B$lower <= A$upper)
        
        tibble(
          Strain1 = pair[1],
          Strain2 = pair[2],
          overlap_flag = ifelse(overlap, "overlap", "no_overlap")
        )
      }) %>% bind_rows()
    }),
    .groups = "drop"
  ) %>%
  unnest(pairwise)

no_overlap_df <- overlap_df %>%
  filter(Strain1 %in% c("einhardi", "nebliphilus", "shuimeiren")) %>%
  filter(overlap_flag %in% c("no_overlap"))

write.csv(no_overlap_df, "no_overlap.csv", row.names = FALSE)
