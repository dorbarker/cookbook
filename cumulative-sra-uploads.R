# This script will generate cumulative uploads for a group of species to
# NCBI SRA. Some extra manipulation of the data is necessary to properly 
# calcualte the cumulative sums of the uploads

library(here)
library(readr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(magrittr)
library(stringr)
library(tidyr)
library(purrr)

campy <-
    # specifying the here package is needed 
    # to avoid collision with lubridate::here
    here::here('data/campylobacter_runinfo.csv') %>%  
    read_csv()

salmy <-
    here::here('data/salmonella_runinfo.csv') %>%
    read_csv()

# Partially apply gsub to convert long, overly specific names to
# binomial "Genus species" names
full_name_to_binomial <- partial(gsub, pattern = '(\\w+)\\s(\\w+).*',
                                      replacement = "\\1 \\2")

bugs <- 
    bind_rows(campy, salmy) %>%
    
    # In this case, we don't care about metagenmes
    filter(LibrarySource == 'GENOMIC') %>%  
    
    # We'll lump all the sub-species taxonomies together, and round the
    # upload times to the day, since we don't care about the minute-by-minute
    # rate
    mutate(genus_species = full_name_to_binomial(ScientificName),
           LoadDate = round_date(LoadDate, "day")) %>%
    
    # We'll discard anything that isn't one of the three
    # species we're interested in (there's some Vibrio lurking in the data) 
    filter(genus_species %in% c('Salmonella enterica',
                                'Campylobacter jejuni', 
                                'Campylobacter coli')) %>%
    arrange(LoadDate) %>%
    drop_na(LoadDate) 

# We need to spread the data out so that each organism is a column
# so that we can calculate the cumulative sums of these independently
bugs_date_counts <-
    bugs %>%
    group_by(LoadDate, genus_species) %>%
    summarise(upload_count = n()) %>%
    pivot_wider(names_from = genus_species,
                values_from = upload_count,
                values_fill = list(upload_count = 0))

# After calculating the cumulative sums, reorganize the data back into 
# long form for easy plotting
cumulative_sums <-
    bugs_date_counts %>%
    ungroup() %>% 
    select(-LoadDate) %>%  # Must temporarily remove the dates ...
    map(cumsum) %>% 
    bind_cols() %>%
    mutate(
        LoadDate = bugs_date_counts$LoadDate  # ... and then add them back on
    ) %>%
    pivot_longer(-LoadDate, names_to = "genus_species")

# Now that the data re in the right format, plotting is straightforward
ggplot(cumulative_sums, aes(x = LoadDate, 
                            y = value, 
                            colour = genus_species)) +
    geom_line(size = 2) +
    scale_y_continuous('Cumulative Uploaded', 
                       labels = scales::comma) +
    labs(x = "Upload Date",
         colour = "Organism") +
    theme_bw(base_size = 16) +
    theme(legend.position = 'bottom')
