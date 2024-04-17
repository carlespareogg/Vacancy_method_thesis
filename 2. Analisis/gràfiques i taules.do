//Anàlisi de dades INE-POBLACIÓ

use "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\3. Clean data\ine_euv_vivienda_poblacion.dta"

sort codi_regio registro año
bysort codi_regio: gen poblacio_11_21= poblacion - poblacion[_n-1] if _n>1 & año==2021 & registro=="ine"

/*gen poblacion_2021 = poblacion if año == 2021
gen poblacion_2011 = poblacion if año == 2011
by codi_regio: egen poblacion_11_21 = poblacion_2021 - poblacion_2011
*/

sum viviendas_vacias if año==2011 & registro=="ine"
sum viviendas_vacias if año==2021 & registro=="ine"

gen vac_pop = viviendas_vacias/ poblacion
sum vac_pop
sum vac_pop if año==2011
sum vac_pop if año==2021


gen vac_vtot = viviendas_vacias/ viviendas_totales
sum vac_vtot 
sum vac_vtot if año==2011
sum vac_vtot if año==2021

//GRPAFIQUES

graph dot (mean) vac_vtot vac_pop if año == 2011|2021, over(año)
graph dot (mean) vac_vtot vac_pop if año == 2011|2021, over(año) over(registro)