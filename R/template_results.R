library(dplyr)
library(ggplot2)
library(readr)

df = read_rds("results/dice_ss.rds")
mdf = read_rds("results/dice_ss_median.rds")
df = bind_rows(df, mdf) %>% 
  arrange(desc(ind), img) %>% 
  mutate(avg = nii.stub(img, bn = TRUE),
         avg = recode(avg, "ss"= "mean", "ss_median" =  "median" )) %>% 
  select(-img)

transparent_legend =  theme(
  legend.background = element_rect(
    fill = "transparent"),
  legend.key = element_rect(
    fill = "transparent", 
    color = "transparent"),
  legend.position = c(0.5, 0.8),
  legend.direction = "horizontal",
  text = element_text(size = 30))

pngner = function(pngname, g) {
  png(pngname, height = 7, width = 14, units = "in", res = 300)
  print(g)
  dev.off()
}
g = df %>% 
  ggplot(aes(x = ind, colour = avg)) +
  transparent_legend + 
  guides(colour = guide_legend(title = "Averaging Mechanism")) + 
  xlab("Template Iteration")
gg = g +  geom_line(aes(y = rmse)) +  ylab("Root Mean Squared Error") 

pngner("results/RMSE.png", gg)

gg = g +  geom_line(aes(y = dice))+  ylab("Dice Coefficient") 
pngner("results/Dice.png", gg)

