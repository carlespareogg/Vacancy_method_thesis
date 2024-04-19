//Anàlisi de dades INE-POBLACIÓ

use "$data\ine_euv_vivienda_poblacion.dta"

//Generating change variables with values from 2011 to 2021
sort codi_regio registro año
bysort codi_regio: gen poblacio_11_21 = poblacion - poblacion[_n-1] if _n>1 & año==2021 & registro=="ine"
bysort codi_regio: gen vac_11_21_ine = viviendas_vacias - viviendas_vacias[_n-1] if _n>1 & año==2021 & registro=="ine"
bysort codi_regio: gen viv_11_21_ine = viviendas_totales - viviendas_totales[_n-1] if _n>1 & año==2021 & registro=="ine"

bysort codi_regio: gen vac_11_21_euv = viviendas_vacias - viviendas_vacias[_n-5] if _n>1 & año==2021 & registro=="euv"
bysort codi_regio: gen viv_11_21_euv = viviendas_totales - viviendas_totales[_n-5] if _n>1 & año==2021 & registro=="euv"

//Generating change variables for every 2 years with EUV data
bysort codi_regio: gen vac_change_euv = viviendas_vacias - viviendas_vacias[_n-1] if _n>1 & registro=="euv"
bysort codi_regio: gen viv_change_euv = viviendas_totales - viviendas_totales[_n-1] if _n>1 & registro=="euv"
bysort codi_regio: gen poblacio_change_euv = poblacion - poblacion[_n-1] if _n>1 & registro=="euv"

gen vac_11_21 = vac_11_21_ine + vac_11_21_euv
gen viv_11_21 = viv_11_21_euv + viv_11_21_ine


gen vac_pop = viviendas_vacias / poblacion
gen vac_vtot = viviendas_vacias / viviendas_totales

la variable	viv_11_21		"Diferencia de viviendas totales entre 2011 y 2021"
la variable	vac_11_21		"Diferencia de viviendas vacías entre 2011 y 2021"
la variable	poblacio_11_21	"Diferencia de población entre 2011 y 2021"
la variable	vac_vtot		"Vacancy rate"
la variable	vac_pop			"vacancy controlado por población"

	
sum viviendas_vacias if año==2021 & registro=="ine" & codi_regio >52

sum vac_pop if codi_regio >52
sum vac_pop if año==2011 & codi_regio >52
sum vac_pop if año==2021 & codi_regio >52


sum vac_vtot if codi_regio >52
sum vac_vtot if año==2011 & codi_regio >52
sum vac_vtot if año==2021 & codi_regio >52

//GRPAFIQUES
////Agregades
graph dot (mean) vac_vtot vac_pop if año == 2011|2021 & codi_regio >52, over(año)
graph dot (mean) vac_vtot vac_pop if año == 2011|2021 & codi_regio >52, over(año) over(registro)


////Agafant només el País Vasc, comparar dades de INE i EUV 
//graph dot (mean) vac_vtot vac_pop if año == 2011|2021 & codi_regio >52 & (registro == "ine" & ((año == 2011 & codi_regio == codi_regio[_n-1]) | (año == 2021 & codi_regio == codi_regio[_n-2]))) | registro == "euv", over(año) over(registro)

graph dot (mean) vac_vtot vac_pop if codi_regio >= 1000 & codi_regio < 1999 | codi_regio >= 20000 & codi_regio < 20999 | codi_regio >= 48000 & codi_regio < 48999, over(año) over(registro)


//graph dot (mean) vac_11_21 viv_11_21 if año == 2011|2021 & codi_regio >52 & (registro == "ine" & ((año == 2011 & codi_regio == codi_regio[_n-1]) | (año == 2021 & codi_regio == codi_regio[_n-2]))) | registro == "euv", over(año) over(registro)






