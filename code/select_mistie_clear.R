library(readr)
library(dplyr)
library(tidyr)
setwd(here::here())

reads = read_csv("data/reads.csv")
wide = reads
rs = wide %>% 
  select(-name, -Category) %>% 
  rowSums()
table(rs)
no_path = wide[rs == 0, ]


reads = reads %>% 
  gather(var, value, -name, -Category) %>% 
  separate(var, into = c("reader", "type"), sep = ":") %>% 
  spread(type, value = value)


bleeds = reads %>% 
  filter(IPH > 0 | IVH > 0)
bleeds = bleeds %>% 
  select(name, Category) %>% 
  distinct()

bleeds = bleeds %>% 
  select(name) %>% 
  arrange(name) %>% 
  distinct()
  
