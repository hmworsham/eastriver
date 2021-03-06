# Kueppers_Plot_GeophysGradient_Distribution
# Generates figures to depict the distribution of Kueppers et al. East River forest inventory plots along several geophysical gradients

# Author: Marshall Worsham
# Created: 10-06-20
# Revised: 06-29-21

#############################
# Set up workspace
#############################

## Install and load libraries
pkgs <- c('dplyr',
          'tidyverse',
          'ggplot2',
          'data.table')

# Name the packages you want to use here
load.pkgs <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
} # Function to install new packages if they're not already installed
load.pkgs(pkgs) # Runs the function on the list of packages defined in pkgs

# Set working directory.
setwd(file.path('~', 'Desktop', 'RMBL', 'Projects', fsep = '/'))
fidir <- file.path(getwd(), 'Forest_Inventory_Dataset', 'Output', fsep = '/')
wsdir <- file.path(getwd(), 'Watershed_Spatial_Dataset', 'Source', fsep = '/')

#############################
# Ingest source data
#############################

# Ingest 2020 Kueppers plot characteristics CSVs
siteinfo20 <-  read.csv(file.path(fidir, 'Kueppers_EastRiver_Final_Sites_2020.csv'), header = T)

# Ingest 2020-2021 Kueppers plot info
siteinfo21 <- read.csv(file.path(fidir, 'EastRiver_ProposedSites_2021_25.csv'), header = T)

# Refactor a couple of columns in siteinfo20 to row bind with 2021 data
siteinfo20 <- rename(siteinfo20, Site_ID = SFA_ID)
#siteinfo20$Established <- as.factor(siteinfo20$Established)
siteinfo20$Established <- 'Established'

# Specify whether site was fully or partially inventoried in 2020
siteinfo20$Inventory <- 'Full Inventory'
siteinfo20$Inventory[grepl('XX', siteinfo20$SFA_ID)] <- 'Partial Inventory'

###############################################
# Batch create plots for individual variables
###############################################

# Row bind 2020 and 2021 site info
zonnew$Site_ID <- rownames(zonnew)
zonnew$Established <- 'Proposed'
zonnew <- zonnew[c('Site_ID',
                   'Established',
                   'DTMf_ASO_free_snow_9m', 
                  'SlopeDeg_30m',
                  'Aspect_9m',
                  'TWI_9m_x5',
                  'TPI_9m_x5',
                  'TPI_9m_1000_std',
                  'TPI_9m_2000_std')]
names(zonnew) <- c('Site_ID',
                   'Established',
                   'Elevation_m',
                   'Slope',
                   'Aspect',
                   'TWI',
                   'TPI_45',
                   'TPI_1000',
                   'TPI_2000')

fullset <- bind_rows(siteinfo21, siteinfo20, zonnew)

# Select variables of interest from 2021 site info
topos <- fullset[c('Site_ID',
                   'Established',
                   'Elevation_m',
                   'Slope',
                   'Aspect',
                   'TWI',
                   'TPI_45',
                   'TPI_1000',
                   'TPI_2000')]


# Specify which plots to exclude
outs <- c('Carbon 15',
          'Carbon 21',
          'Carbon 6',
          'Cement Creek 8',
          'Cement Creek 9',
          'Coal Creek Valley North 1', 
          'Coal Creek Valley North 1B',
          'Coal Valley South 1',
          'Coal Valley South 2',
          'Coal Valley South 4',
          'Coal Valley South 5',
          #'dummy',
          'Point Lookout North 3',
          'Schuylkill North 2B',
          'Schuylkill North 5B', 
          'Schuylkill North 2',
          'Schuylkill North 5',
          'Snodgrass Convergent 4',
          'Snodgrass East Slope 2',
          'Snodgrass NE Slope 1',
          'Ute Gulch 2')

# Remove the cut sites from the dataframe
topos_cut <- topos[!topos$Site_ID %in% outs, ]
topos_cut

# Define a function to print figures
printfigs <- function(df){
  #'''
  # Function
  # Input: a dataframe of sites and topographic variables
  # Returns: a set of png files 
  #'''
  
  # Define colors
  colors = c('grey10', 'grey50', 'firebrick', 'darkblue', 'steelblue', 'forest green', 'chocolate1')
  varnames = c('Elevation [m]', 
               'Slope angle [º]', 
               'Aspect [º]', 
               'Topographic Wetness Index',
               'TPI (45m window)',
               'TPI (1000m window)', 
               'TPI (2000m window)')
  
  # Loop through variables
  for (t in seq(length(df))){
    clr = colors[t]
    varname = varnames[t]
    print(clr)
    print(df[,t+2])
    
    # Open the png quartz image
    png(file.path('Forest_Inventory_Dataset', 
                  'Production_Images', 
                  paste0(names(topos[t+2]),'.png')), 
        width = 15, height = 10, units = 'in', res = 180)
    
    # Print the plot to png
      print(
        ggplot(df, aes(x = reorder(Site_ID,  df[, t+2]), y = df[, t+2])) +
          geom_point(aes(color = Established, size = 4)) +
          scale_color_manual(values = c(clr, 'grey 70')) +
          scale_y_continuous(name = varname) +
          #                    limits = c(2600, 3600),
          #                    breaks = seq(2600, 3600, 100)
          # ) +
          labs(x = 'Plot ID', y = names(topos)[t+2]) +
          theme_light(base_size = 24) +
          theme(axis.text.x = element_text(angle = 90, hjust = 1),
                legend.position="bottom", legend.title = element_blank()) +
          guides(size = F)
      )
    dev.off()  
  }
}

printfigs(topos_cut)


############################
# Facet grid all variables
############################

# Select variables of interest
kplots_long <- siteinfo20[,c('Site_ID',
                           'TPI_1000',
                           'TPI_2000',
                           'Elevation_m',
                           'Radiation',
                           'Aspect',
                           'Slope',
                           'TWI')]

# Gather to format long
kplots_long <- gather(kplots_long, variable, value, -Site_ID)
kplots_long <- kplots_long %>%
  arrange(variable, value) %>%
  mutate(order = row_number())

# Set up facet grid with all variables
varsgrid <- ggplot(kplots_long, aes(x = order, y = value)) +
  geom_point(aes(color = variable, size=4)) +
  scale_color_manual(values = c('grey10', 'grey50', 'firebrick', 'darkblue', 'steelblue', 'forest green', 'chocolate1')) +
  facet_wrap(~variable, scales = 'free') +
  scale_x_continuous(breaks = kplots_long$order, labels = kplots_long$SFA_ID) +
  theme(legend.position = 'element_blank',
        axis.text.x = element_text(angle = 90))

# Print facet grid
varsgrid


########################################
# Create plots for individual variables
########################################

# define vars
ele = siteinfo20$Elevation_m
rad = siteinfo20$Radiation
tpi45 = siteinfo20$TPI_45
tpi1000 = siteinfo20$TPI_1000
tpi2000 = siteinfo20$TPI_2000
twi = siteinfo20$TWI
slo = siteinfo20$Slope
asp = siteinfo20$Aspect
topos = list(ele, tpi1000, tpi2000, tpi45, twi, slo, asp)

# plot elevation
png("ele.png",width=15,height=10,units="in",res=180)

feature = ele
ggplot(siteinfo20, aes((reorder(SFA_ID, Elevation_m)), Elevation_m)) +
#geom_point(aes(color = Established, size = 4)) +
#scale_color_manual(values = c('grey10', 'grey70')) +
geom_point(color = 'grey10', size = 18) +
scale_y_continuous(name = 'Elevation (m)', 
                   limits = c(2600, 3600), 
                   breaks = seq(2600, 3600, 100)
                   ) +
  labs(x = 'Plot ID', y = 'Elevation (m)') + 
  theme_light(base_size = 36) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="bottom", legend.title = element_blank()) +
  guides(size = F)

dev.off()


# plot radiation
png("rad.png",width=15,height=10,units="in",res=180)

feature = rad
ggplot(siteinfo20, aes((reorder(SFA_ID, feature)), feature)) +
  #geom_point(aes(color = Established, size = 4)) +
  #scale_color_manual(values = c('firebrick', 'grey70')) +
  geom_point(color = 'firebrick', size = 18) +
  scale_y_continuous(name = expression(paste('Radiation (WH', m^-2, ')')), 
                     limits = c(min(feature), max(feature)), 
                     breaks = seq(1.2e6, 1.9e6, 0.1e6),
                     labels = scales::scientific
  ) +
  labs(x = 'Plot ID', y = 'Radiation') + 
  theme_light(base_size = 36) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="bottom", legend.title = element_blank()) +
  guides(size = F)

dev.off()


# plot tpi-1k
png("tpi1k.png",width=15,height=10,units="in",res=180)

feature = tpi1
ggplot(siteinfo20, aes((reorder(SFA_ID, feature)), feature)) +
  #geom_point(aes(color = Established, size = 4)) +
  #scale_color_manual(values = c('darkblue', 'grey70')) +
  geom_point(color = 'darkblue', size = 18) +
  scale_y_continuous(name = 'TPI (1000m px window)', 
                     limits = c(min(feature), max(feature)), 
                     #breaks = seq(1.2e6, 1.9e6, 0.1e6),
                     #labels = scales::scientific
  ) +
  labs(x = 'Plot ID', y = 'TPI') + 
  theme_light(base_size = 36) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="bottom", legend.title = element_blank()
        ) +
  guides(size = F)

dev.off()

# plot tpi2k
png("tpi2k.png",width=15,height=10,units="in",res=180)

feature = tpi2
ggplot(siteinfo20, aes((reorder(SFA_ID, feature)), feature)) +
  #geom_point(aes(color = Established, size = 4)) +
  #scale_color_manual(values = c('darkblue', 'grey70')) +
  geom_point(color = 'grey50', size = 18) +
  scale_y_continuous(name = 'TPI (2000m px window)', 
                     limits = c(min(feature), max(feature)), 
                     #breaks = seq(1.2e6, 1.9e6, 0.1e6),
                     #labels = scales::scientific
  ) +
  labs(x = 'Plot ID', y = 'TPI') + 
  theme_light(base_size = 36) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="bottom", legend.title = element_blank()) +
  guides(size = F)

dev.off()

# plot tpi45
png("tpi45.png",width=15,height=10,units="in",res=180)

feature = tpi45
ggplot(siteinfo20, aes((reorder(SFA_ID, feature)), feature)) +
  #geom_point(aes(color = Established, size = 4)) +
  #scale_color_manual(values = c('darkblue', 'grey70')) +
  geom_point(color = 'darkblue', size = 18) +
  scale_y_continuous(name = 'TPI (45m px window)', 
                     limits = c(min(feature), max(feature)), 
                     #breaks = seq(1.2e6, 1.9e6, 0.1e6),
                     #labels = scales::scientific
  ) +
  labs(x = 'Plot ID', y = 'TPI') + 
  theme_light(base_size = 36) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="bottom", legend.title = element_blank()) +
  guides(size = F)

dev.off()


#plot twi
png("twi.png",width=15,height=10,units="in",res=180)

feature = twi
ggplot(siteinfo20, aes((reorder(SFA_ID, feature)), feature)) +
  #geom_point(aes(color = Established, size = 4)) +
  #scale_color_manual(values = c('steelblue', 'grey70')) +
  geom_point(color = 'steelblue', size = 18) +
  scale_y_continuous(name = 'Topographic Wetness Index', 
                     limits = c(min(feature), max(feature)), 
                     #breaks = seq(1.2e6, 1.9e6, 0.1e6),
                     #labels = scales::scientific
  ) +
  labs(x = 'Plot ID', y = 'TWI') + 
  theme_light(base_size = 36) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="bottom", legend.title = element_blank()) +
  guides(size = F)

dev.off()

#plot slope
png("slo.png",width=15,height=10,units="in",res=180)

feature = slo
ggplot(siteinfo20, aes((reorder(SFA_ID, feature)), feature)) +
  geom_point(color = 'forest green', size = 18) +
  #geom_point(aes(color = Established, size = 4)) +
  #scale_color_manual(values = c('forest green', 'grey70')) +
  scale_y_continuous(name = 'Slope (degrees)', 
                     limits = c(min(feature), max(feature)), 
                     #breaks = seq(1.2e6, 1.9e6, 0.1e6),
                     #labels = scales::scientific
  ) +
  labs(x = 'Plot ID', y = 'Slope') + 
  theme_light(base_size = 36) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position = 'bottom',
        legend.title = element_blank()) +
  guides(size = F)

dev.off()

#plot aspect
png("asp.png",width=15,height=10,units="in",res=180)

feature = asp
ggplot(siteinfo20, aes((reorder(SFA_ID, feature)), feature)) +
  #geom_point(aes(color = Established, size = 4)) +
  #scale_color_manual(values = c('chocolate1', 'grey70')) +
  geom_point(color = 'chocolate1', size = 18) +
  scale_y_continuous(name = 'Aspect (degrees)', 
                     limits = c(min(feature), max(feature)), 
                     #breaks = seq(1.2e6, 1.9e6, 0.1e6),
                     #labels = scales::scientific
  ) +
  labs(x = 'Plot ID', y = 'Aspect') + 
  theme_light(base_size = 36) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="bottom", legend.title = element_blank()) +
  guides(size = F)

dev.off()

