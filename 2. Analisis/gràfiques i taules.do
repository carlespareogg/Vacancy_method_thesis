//Anàlisi de dades INE-POBLACIÓ

use "$data\ine_euv_vivienda_poblacion.dta", clear


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

**Generar variables de segmento poblacional
g segmento = .
replace segmento = 1 if poblacion < 10000
replace segmento = 2 if (poblacion > 10000 & poblacion < 25000)
replace segmento = 3 if (poblacion > 25000 & poblacion < 50000)
replace segmento = 4 if (poblacion > 50000 & poblacion < 75000)
replace segmento = 5 if (poblacion > 75000 & poblacion < 100000)
replace segmento = 6 if (poblacion > 100000 & poblacion < 150000)
replace segmento = 7 if (poblacion > 150000 & poblacion < 200000)
replace segmento = 8 if (poblacion > 200000 & poblacion < 250000)
replace segmento = 9 if (poblacion > 250000 & poblacion < 500000)
replace segmento = 10 if (poblacion > 500000 & poblacion < 1000000)
replace segmento = . if regexm(nom_regio, "^Resto de.*$")

la variable segmento 		"Segmento poblacional del municipio"

**Estadísticas básicas
	
sum viviendas_vacias if año==2021 & registro=="ine" & codi_regio >52

sum vac_pop if codi_regio >52
sum vac_pop if año==2011 & codi_regio >52
sum vac_pop if año==2021 & codi_regio >52


sum vac_vtot if codi_regio >52
sum vac_vtot if año==2011 & codi_regio >52
sum vac_vtot if año==2021 & codi_regio >52

save "$data\ine_euv_vivienda_poblacion_withvariables.dta", replace

*____________________________________________________________________
*EN CONSTRUCCIÓ
**# Porcentaje de vivienda vacía por segmento poblacional
	foreach año in 2011 2021 {
    foreach registro in "ine" "euv" {
        // Calcular el total de viviendas vacías por segmento de población
        bysort segmento: egen vac_tot`año'`registro' = total(viviendas_vacias) if (año == `año' & registro == "`registro'")
		//Calcular total de viviendas vacias por año y registro
		egen viv_tot`año'`registro' = total(viviendas_totales) if (año == `año' & registro == "`registro'")
		//Calcular la ratio de viviendas totales de cada segmento de población por año y registro
		bysort segmento: gen vac_vtot`año'`registro' = vac_tot`año'`registro'/ viv_tot`año'`registro' if (año == `año' & registro == "`registro'")

		table segmento vac_vtot`año'`registro'
        
    }
}


// Mostrar la tabla de porcentajes de viviendas vacías por segmento de población
table segmento, c(sum seg_vac_vactot)


*aquí tinc creat la variable 

la variable vac_vactot  	"Porcentaje de vivienda vacía sobre el total de vivenda vacía"
egen seg_vac_vactot = 
estpost sum vac_vtot, by(segmento)
estimates title: Vacancy rate por segmento poblacional
estimates store seg_vac_vtot

*____________________________________________________________________

**# GRPAFIQUES
////Agregades
graph dot (mean) vac_vtot vac_pop if año == 2011|2021 & codi_regio >52, over(año)
graph dot (mean) vac_vtot vac_pop if año == 2011|2021 & codi_regio >52, over(año) over(registro)

//Per tamany de població
graph dot (mean) vac_vtot vac_pop if poblacion < 10000 & (año == 2011 | año == 2021) & (codi_regio >52) & registro == "ine" & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion],over(año) over(registro) title(población < 10000) name(graph1, replace)

graph dot (mean) vac_vtot vac_pop if (poblacion > 10000 & poblacion < 25000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(10000 < población < 25000) name(graph2, replace)

graph dot (mean) vac_vtot vac_pop if (poblacion > 25000 & poblacion < 100000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(25000 < población < 100000) name(graph3, replace)

graph dot (mean) vac_vtot vac_pop if (poblacion > 100000 & poblacion < 250000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(100000 < población < 250000) name(graph4, replace)


graph dot (mean) vac_vtot vac_pop if (poblacion > 250000 & poblacion < 500000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(250000 < población < 500000) name(graph5, replace)


graph dot (mean) vac_vtot vac_pop if poblacion > 500000 & (año == 2011 | año == 2021) & (codi_regio > 52 & (substr(string(codi_regio), -3, 3) != "999")) & registro == "ine" [aw=poblacion], over(año) over(registro) title(500000 < población) name(graph6, replace)

graph combine graph1 graph2 graph3 graph4 graph5 graph6, rows(3) cols(2)

graph export "$figures\GridPobl_ine-euv.png", replace


//Per tamany de població només agafant País Basc 

graph dot (mean) vac_vtot vac_pop if ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & (año == 2011 | año == 2021) & (poblacion > 10000 & poblacion < 25000) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(10000 < población < 25000) name(graph1, replace)

graph dot (mean) vac_vtot vac_pop if ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & (año == 2011 | año == 2021) & (poblacion > 25000 & poblacion < 50000) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(25000 < población < 50000) name(graph2, replace)

graph dot (mean) vac_vtot vac_pop if ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & (año == 2011 | año == 2021) & (poblacion > 50000 & poblacion < 100000) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(50000 < población < 100000) name(graph3, replace) 


graph dot (mean) vac_vtot vac_pop if ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & (año == 2011 | año == 2021) & (poblacion > 100000) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(poblacion > 100000) name(graph4, replace)


graph combine graph1 graph2 graph3 graph4, rows(2) cols	(2) 

graph export "$figures\GridPoblPB_ine-euv.png", replace

////Agafant només el País Vasc, comparar dades de INE i EUV 
//graph dot (mean) vac_vtot vac_pop if año == 2011|2021 & codi_regio >52 & (registro == "ine" & ((año == 2011 & codi_regio == codi_regio[_n-1]) | (año == 2021 & codi_regio == codi_regio[_n-2]))) | registro == "euv", over(año) over(registro)

graph dot (mean) vac_vtot vac_pop if (codi_regio >= 1000 & codi_regio < 1999 | codi_regio >= 20000 & codi_regio < 20999 | codi_regio >= 48000 & codi_regio < 48999) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro)

graph export "$figures\PB_ine-euv.png", replace

//graph dot (mean) vac_11_21 viv_11_21 if año == 2011|2021 & codi_regio >52 & (registro == "ine" & ((año == 2011 & codi_regio == codi_regio[_n-1]) | (año == 2021 & codi_regio == codi_regio[_n-2]))) | registro == "euv", over(año) over(registro)


//Threshold quan vacancy es manté
*Per a vacancy/població
graph dot (mean) vac_vtot vac_pop if (poblacion > 20000 & poblacion < 27000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(20000 < población < 27000) name(graph3, replace)

*Per a vacancy rate
graph dot (mean) vac_vtot vac_pop if (poblacion > 6000 & poblacion < 10000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(6000 < población < 10000) name(graph3, replace)


************************Scatter plolts************************

//vacancy rate-població per any, INE i estimació

capture separate vac_vtot, by(año) 
colorpalette tableau, nograph intensity(0.8)
twoway (scatter vac_vtot poblacion if registro == "ine" & ((año == 2011) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999"), sort color(blue)) (scatter vac_vtot poblacion if registro == "ine" & ((año == 2021) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999"), sort color(red)) (lfit vac_vtot poblacion if registro == "ine" & ((año == 2011) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], color(navy)) (lfit vac_vtot poblacion if registro == "ine" & ((año == 2021) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], color("cranberry")), legend(order(1 "2011" 2 "2021" 3 "fitted 2011" 4 "fitted 2021") pos(1) ring(0)) ytitle("vacancy rate") scheme(white_w3d)

graph export "$figures\ccaa_vacrate.png", replace

///COMENTARI Veiem com el pendent de la línia de tendència baixa, perquè als municipis més poblats ha baixat més la vacancy.

*____________________________________________________________________
*EN CONSTRUCCIÓ
***Gràfic amb la diferència 
*ARREGLAR-LOS PER A PODER FER EL GRID
twoway (scatter vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion < 10000)) & (substr(string(codi_regio), -3, 3) != "999"), sort) (lfit vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion < 10000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion]), legend(order(1 "2021-2011" 2 "fitted 2021-2011") pos(1) ring(0)) ytitle("Diferencia de viviendas vacías entre 2011 y 2021") title(población < 10000) name(graph1, replace)

twoway (scatter vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 10000 & poblacion < 25000) & (substr(string(codi_regio), -3, 3) != "999")), sort) (lfit vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 10000 & poblacion < 25000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion]), legend(order(1 "2021-2011" 2 "fitted 2021-2011") pos(1) ring(0)) ytitle("Diferencia de viviendas vacías entre 2011 y 2021") title(población < 10000) name(graph1, replace) title(10000 < población < 25000) name(graph2, replace)

twoway (scatter vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 25000 & poblacion < 100000)) & (substr(string(codi_regio), -3, 3) != "999"), sort) (lfit vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 25000 & poblacion < 100000))& (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion]), legend(order(1 "2021-2011" 2 "fitted 2021-2011") pos(1) ring(0)) ytitle("Diferencia de viviendas vacías entre 2011 y 2021") title(población < 10000) name(graph1, replace) title(25000 < población < 100000) name(graph3, replace)

twoway (scatter vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 100000 & poblacion < 250000)) & (substr(string(codi_regio), -3, 3) != "999"), sort) (lfit vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 100000 & poblacion < 250000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion]), legend(order(1 "2021-2011" 2 "fitted 2021-2011") pos(1) ring(0)) ytitle("Diferencia de viviendas vacías entre 2011 y 2021") title(población < 10000) name(graph1, replace) title(100000 < población < 250000) name(graph4, replace)

twoway (scatter vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 250000 & poblacion < 500000)) & (substr(string(codi_regio), -3, 3) != "999"), sort) (lfit vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 250000 & poblacion < 500000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion]), legend(order(1 "2021-2011" 2 "fitted 2021-2011") pos(1) ring(0)) ytitle("Diferencia de viviendas vacías entre 2011 y 2021") title(población < 10000) name(graph1, replace)title(250000 < población < 500000) name(graph5, replace)

twoway (scatter vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 500000)) & (substr(string(codi_regio), -3, 3) != "999"), sort) (lfit vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 500000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion]), legend(order(1 "2021-2011" 2 "fitted 2021-2011") pos(1) ring(0)) ytitle("Diferencia de viviendas vacías entre 2011 y 2021") title(población < 10000) name(graph1, replace)title(500000 < población) name(graph6, replace)

graph combine graph1 graph2 graph3 graph4 graph5 graph6, rows(3) cols(2)

graph export "$figures\Dif_pob_viv_scatter_grid.png", replace


*____________________________________________________________________


///COMENTARI: sembla que la relació no és gaire forta i a més és la contrària a l'esperada: si la població va a centres més poblats i allà la vivenda buida es redueix hauriem de veure una línia descendent, no és el cas. El que sí que veiem és que la vivenda buida s'ha reduit, perquè la tendència es troba sempre en valros negatius, però s'ha reduit més en municipis on s'ha reduit més la poblacio

twoway (scatter vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 50000 & poblacion < 500000)) & (substr(string(codi_regio), -3, 3) != "999"), sort) (lfit vac_11_21_ine poblacio_11_21 if registro == "ine" & ((año == 2021) & (poblacion > 50000 & poblacion < 500000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion]), legend(order(1 "2021-2011" 2 "fitted 2021-2011") pos(1) ring(0)) ytitle("Diferencia de viviendas vacías entre 2011 y 2021")

graph export "$figures\Dif_pob_viv_scatter.png", replace



****************Graphs over territory******************

graph dot (mean) vac_vtot if registro == "ine" & ((año == 2011) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], o(com_autonoma, sort(1)) name(ccaa1, replace)

graph dot (mean) vac_vtot if registro == "ine" & ((año == 2021) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], o(com_autonoma, sort(1)) marker(1, mcolor(red)) name(ccaa2, replace)

graph box vac_vtot if registro == "ine" & ((año == 2011) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], o(com_autonoma, sort(1)) 

graph box (mean) vac_vtot if registro == "ine" & ((año == 2021) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], o(com_autonoma, sort(1)) marker(1, mcolor(red)) 


graph combine ccaa1 ccaa2, rows(1)

graph export "$figures\ccaa_viv_ordered_grid.png", replace








