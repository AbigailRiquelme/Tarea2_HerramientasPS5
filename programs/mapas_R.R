#########################################
#                                       #
#     Herramientas computacionales      #
#         para la investigación         #
#                                       #
#       Profesora: Amelia Gibbons       #
#      Alumnos: Pacheco y Riquelme      #
#                                       #
#           MAE UdeSA 2022              #
#                                       #  
#               Tarea 2                 #
#########################################

# Definimos los strings para que luego definir el directorio
main = "C:\\Users\\Abi\\Documents\\GitHub\\Herramientas-PS5"
input = paste(main, "\\input", sep = "")
output = paste(main, "\\output", sep = "")


#### Mapa con ggplot2 #### 

# Comenzaremos haciendo el mapa con ggplot2

# Importamos las librerías necesarias para hacer el gráfico en ggplot

library(rgdal)
library(dplyr)
library(ggplot2)
library(RColorBrewer)
library(ggrepel)

# Importamos el archivo shp
setwd(input)
london_data <- readOGR(dsn = "london_sport.shp")

# Chequeamos las clases de las variables en una base de datos espacial
sapply(london_data@data, class)

# Ahora importamos los datos de la cantidad de crímenes
crime_data <- read.csv("mps-recordedcrime-borough.csv",
                       stringsAsFactors = FALSE)

# Vemos los tipos de crímenes que hay 
head(crime_data$CrimeType) 

# Nos quedamos solo con aquellos crímenes que son "Theft & Handling":
crime_theft <- crime_data[crime_data$CrimeType == "Theft & Handling",]

# Calculamos la suma de los crímenes por robo para cada uno de los distritos:
crime_ag <- aggregate(CrimeCount ~ Borough, FUN = sum, data = crime_theft)

# Ahora lo que vamos a hacer es juntar los datos
london_data@data <- left_join(london_data@data, crime_ag, by = c('name' = 'Borough'))

# A los datos espaciales les damos formato de data frame
lnd_f <- broom::tidy(london_data)

# Ahora tenemos que juntar la información de ambos dfs.
# Le ponemos un id a cada observación
london_data$id <- row.names(london_data) 

# Hacemos el merge con la data de crímenes y los polígonos
lnd_f <- left_join(lnd_f, london_data@data) 

# Tenemos que hacer que la variable sea spatially intensive. Vamos a generar una variable
# que sea la cantidad de robos cada 1000 habitantes.

lnd_f$crime_spatial<- lnd_f$CrimeCount/as.double(lnd_f$Pop_2001)*1000

# Ya tenemos la variable de interés. Para poner las leyendas de la cantidad de crímenes
# cada 1000 habitantes, vamos a calcular los centroides de cada uno de los polígonos.

centroids <- as.data.frame(coordinates(london_data))
centroids$label <- london_data@data$name
names(centroids) <- c("c.long", "c.lat", "name") 

# Vamos a juntar la base original y la base de centroides en un nuevo df
# que se llama lnd_f2

lnd_f2 <- merge(centroids, lnd_f, by = c("name"))

# Generamos una nueva variable para las labels dentro del gráfico. Esta será la cantidad
# de crímenes redondeada.
lnd_f2$label <- as.character(round(lnd_f2$crime_spatial, 0))

# Para el barrio que no hay datos, le decimos que la label sea "NA"
lnd_f2$label[is.na(lnd_f2$label)] <- "NA"

# Hacemos el gráfico:

map1 <- ggplot(lnd_f2, aes(long, lat, group = group, fill = crime_spatial)) +
  geom_polygon() + coord_equal() +
  geom_path(data = lnd_f2, aes(x = long, y = lat, group = group), 
            color = "black", size = 0.3) + # Graficamos los polígonos
  labs(x = "", y = "",
       fill = "Robos cada \n1000 habitantes") +  # Título de la leyenda 
  scale_fill_distiller(palette = "YlOrBr", trans = "reverse") + # Colores de la leyenda
  geom_text(aes(label = label, x = c.long, y = c.lat), size = 2.5) + # Texto con los valores
  ggtitle("Robos cada 1000 habitantes en cada barrio de Londres") + # Título
  theme(axis.text = element_blank(), 
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        plot.background = element_rect(fill="white"), # Fondo blanco
        panel.background=element_blank(), # Fondo blanco
        plot.title = element_text(hjust = 0.5)) # Centramos el título
map1
# Exportamos el mapa

setwd(output)
ggsave(file = "mapa_ggplot.eps", width = 6.5, height = 4, dpi = 300)



#### Mapa con tmap #### 

# En esta parte haremos el mapa usando la libreria "tmap". La importamos

library(tmap)

# Importamos la data de crimen
crime_data <- read.csv("mps-recordedcrime-borough.csv",
                       stringsAsFactors = FALSE)

# Nuevamente solo nos quedamos con los datos de robos
crime_theft <- crime_data[crime_data$CrimeType == "Theft & Handling", ]

# Calculamos la cantidad de crimenes por barrio
crime_ag <- aggregate(CrimeCount ~ Borough, FUN = sum, data = crime_theft)

# Mergeamos la base 

head(lnd$name,100) 
head(crime_ag$Borough,100)

head(left_join(lnd@data, crime_ag)) 
lnd@data <- left_join(lnd@data, crime_ag, by = c('name' = 'Borough'))

# Creamos la variable de interés

lnd$Crime100 <- lnd$CrimeCount/as.double(lnd$Pop_2001)*1000

# Generamos variable para la leyenda

lnd$label <- as.character(round(lnd$crime100,0))

# Hacemos el mapa

library(tmap) # load tmap package 

qtm(shp = lnd, fill = "Crime100", 
    fill.title = "Robos cada \n1000 habitantes",
    fill.palette = "Oranges") +
  tm_borders() +
  tm_scale_bar(position= c("left", "bottom"), breaks = c(0,5,10,15),text.size = 0.5) +
  tm_layout(
    main.title = "Robos cada 1000 habitantes en cada barrio de Londres", 
    main.title.position = "center",
    legend.outside = F, legend.outside.position = "right",
    legend.position = c("right", "bottom")) +
    tm_text("label", size = 0.7)

# Exportamos

setwd(output)
ggsave(file = "mapa_tmap.eps", width = 6.5, height = 4, dpi = 300)


