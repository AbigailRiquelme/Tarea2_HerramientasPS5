
/**********************************************************************
                          Universidad de San Andrés
                 Herramientas computacionales para la investigación
                                  Tarea 5
						      Data Visualization
				   Tomás Pacheco y Abigail Riquelme
***********************************************************************/


* Definimos el global con el directorio a utilizar
global main = "/Users/tomaspacheco/Desktop/Herramientas-PS5/Tarea 2"
gl input = "$main/input"
gl output = "$main/output"

* Seteamos el directorio 
cd "$input"

* Instalamos los paquetes necesarios para poder hacer el mapa 

ssc install spmap
ssc install shp2dta

* Ahora lo que vamos a hacer es importar los datos geográficos, es decir, el shapefile

shp2dta using london_sport.shp, database(ls) coord(coord_ls) genc(c) genid(id) replace

* Ahora abrimos la base con datos de crimen

import delimited "mps-recordedcrime-borough.csv", clear 
rename borough name

* Solo nos quedamos con los crimenes que son robos

keep if crimetype == "Theft & Handling"

* Hacemos un collapse para obtener la cantidad de crimenes por barrio
* Con este comando lo que hacemos es sumar la cantidad de crimenes por barrio

collapse (sum) crimecount, by(name)
rename crimecount theftcount
save "theft.dta", replace

* Ahora juntamos ambas bases utilizando el comando merge. Primero abrimos la base ls.dta

use ls, clear 

* Hacemos el merge

merge 1:1 name using theft.dta

* Nos quedamos solo con aquellas observaciones que se matchearon

drop if _m==2

* Borramos la variable que genera el comando merge

drop _m

* Guardamos esta base de datos

save london_theft_shp.dta, replace

* La volvemos a abrir

use london_theft_shp.dta, clear

* Tal como hicimos con los mapas anteriores, vamos a generar la base de crímenes cada 1000 habitantes con el objetivo de que sea spacially intensive.

gen thefts1000 = theftcount/ Pop_2001*1000

* Generamos una variable con las labels, en la que redondeamos el valor de la cantidad de robos

gen thefts1000round = round(thefts1000)

* Cambiamos el formato de la variable que tiene la cantidad de crimenes. De esta forma, en las leyendas no aparecerán los decimales

format thefts1000 %12.0f


* Hacemos el mapa

spmap thefts1000 using coord_ls, id(id) clmethod(q) cln(6) title("Robos cada 1000 habitantes") subtitle("Por barrio de Londres")  legend(size(medium) position(5) xoffset(15.05)) fcolor(YlGn) plotregion(margin(b+15)) ndfcolor(gray) label(xcoord(x_c) ycoord(y_c) label(thefts1000round)) name(map1,replace)  

* Exportamos
 
graph export "$output/mapa_stata.eps", as(eps) name("map1") replace

