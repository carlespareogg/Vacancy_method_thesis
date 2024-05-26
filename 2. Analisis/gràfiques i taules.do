//Anàlisi de dades INE-POBLACIÓ

use "$data\ine_euv_vivienda_poblacion.dta", clear

*FER RESHAPE WIDE PER A FER EL CÀLCUL CORRECTE

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
replace segmento = 6 if (poblacion > 100000 & poblacion < 175000)
replace segmento = 7 if (poblacion > 175000 & poblacion < 250000)
replace segmento = 8 if (poblacion > 250000 & poblacion < 500000)
replace segmento = 9 if (poblacion > 500000)
replace segmento = . if regexm(nom_regio, "^Resto de.*$") | codi_regio < 52 | codi_regio == .

**Clean population data
drop if poblacion == .

la variable segmento 		"Segmento poblacional del municipio"

**# Estadísticas básicas
	
sum viviendas_vacias if año==2021 & registro=="ine" & codi_regio >52

*******************************************************************************************************************************************************



**# VACANCY WEIGHTED TABLE
* Calcular estadísticas para 2021, registro "ine", no ponderado
summarize viviendas_vacias if año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999"
matrix vv21un = r(N), r(mean), r(sd), r(min), r(max)

* Calcular estadísticas para 2021, registro "ine", ponderado
summarize viviendas_vacias [aw=poblacion] if año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999"
matrix vv21aw = r(N), r(mean), r(sd), r(min), r(max)

* Calcular estadísticas para 2011, registro "ine", no ponderado
summarize viviendas_vacias if año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999"
matrix vv11un = r(N), r(mean), r(sd), r(min), r(max)

* Calcular estadísticas para 2011, registro "ine", ponderado
summarize viviendas_vacias [aw=poblacion] if año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999"
matrix vv11aw = r(N), r(mean), r(sd), r(min), r(max)

* Combinar matrices en una sola matriz
matrix results = (vv21un \ vv21aw \ vv11un \ vv11aw)

* Añadir nombres de filas y columnas
matrix rownames results = "Unweighted 2021" "Weighted 2021" "Unweighted 2011" "Weighted 2011"
matrix colnames results = "count" "mean" "sd" "min" "max"

* Mostrar la matriz en formato de tabla
matlist results, format(%9.2f)

* Exportar la tabla a un archivo RTF
esttab matrix(results, fmt(%9.3f)) using "descriptives_table_vvweights.rtf", replace ///
    cells("count mean sd min max") ///
    title("Unweighted and Weighted Statistics of vacancy dwellings") ///
    nonumbers nomtitles note("Data: INE")
	
****************************************************************************************************************************************************************************
**# VACANCY RATE AND VACANCY/POPULATION TABLE
* Calcular vacancy/population para 2021, registro "ine", ponderado
summarize vac_pop [aw=poblacion] if año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999"
matrix vv21un = r(N), r(mean), r(sd), r(min), r(max)

* Calcular vacancy rate para 2021, registro "ine", ponderado
summarize vac_vtot [aw=poblacion] if año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999"
matrix vv21aw = r(N), r(mean), r(sd), r(min), r(max)

* Calcular estadísticas para 2011, registro "ine", no ponderado
summarize vac_pop [aw=poblacion] if año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999"
matrix vv11un = r(N), r(mean), r(sd), r(min), r(max)

* Calcular estadísticas para 2011, registro "ine", ponderado
summarize vac_vtot [aw=poblacion] if año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999"
matrix vv11aw = r(N), r(mean), r(sd), r(min), r(max)

* Combinar matrices en una sola matriz
matrix results = (vv21un \ vv21aw \ vv11un \ vv11aw)

* Añadir nombres de filas y columnas
matrix rownames results = "Vacancy/pop 2021" "Vacancy rate 2021" "Vacancy/pop 2011" "Vacancy rate 2011"
matrix colnames results = "count" "mean" "sd" "min" "max"

* Mostrar la matriz en formato de tabla
matlist results, format(%9.2f)

* Exportar la tabla a un archivo RTF
esttab matrix(results, fmt(%9.3f)) using "descriptives_table_rates_ine.rtf", replace ///
    cells("count mean sd min max") ///
    title("Vacancy controlled by size of the municipality") ///
    nonumbers nomtitles note("Data: INE")



	

************************************************************************************************************************************************************
**# Metodologica EUV-INE. Porcentaje de vivienda vacía de cada segmento poblacional

foreach año in 2011 2021 {
    foreach registro in ine euv {
        display "Procesando año: `año', registro: `registro'"

        // Calcular el total de viviendas vacías por segmento de población
        bysort segmento: egen vac_tot`año'_`registro'_s_pb = total(viviendas_vacias) if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999))

        // Calcular total de viviendas totales por año y registro
        bysort segmento: egen viv_tot`año'_`registro'_s_pb = total(viviendas_totales) if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999))

        // Calcular la ratio de viviendas totales de cada segmento de población por año y registro
        bysort segmento: gen vac_vtot`año'_`registro'_s_pb = vac_tot`año'_`registro'_s_pb / viv_tot`año'_`registro'_s_pb if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999))
    }
}

******************TABULATION

* Crear una lista de segmentos
levelsof segmento, local(segments)

* Crear una matriz temporal para almacenar los resultados
local rows = 4
local cols = `: word count `segments''  // Número de segmentos
local total_cols = `cols' + 1  // Número de segmentos más una columna para la media ponderada

matrix results = J(`rows', `total_cols', .)

* Añadir nombres de filas y columnas a la matriz
matrix rownames results = "2011 INE" "2011 EUV" "2021 INE" "2021 EUV"
local colnames = ""
foreach seg of local segments {
    local colnames = "`colnames' seg`seg'"
}
local colnames = "`colnames' mean"  // Añadir columna media
matrix colnames results = `colnames'

* Llenar la matriz con los valores de vac_vtot_s
local i = 1
foreach año in 2011 2021 {
    foreach registro in ine euv {
        local j = 1
        foreach seg of local segments {
            summarize vac_vtot`año'_`registro'_s_pb [aw=poblacion] if segmento == `seg'
            if r(N) > 0 {
                matrix results[`i', `j'] = r(mean)
            } 
			else {
                matrix results[`i', `j'] = 0
            }
            local j = `j' + 1
        }
        summarize vac_vtot if año == `año' & registro == "`registro'" & codi_regio > 52 & (substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999))
        if r(N) > 0 {
            matrix results[`i', `total_cols'] = r(mean)
        } 
		else {
            matrix results[`i', `total_cols'] = 0
        }
        local i = `i' + 1
    }
}

* Mostrar la matriz en formato de tabla con 3 decimales
matlist results, format(%9.3f)

* Exportar la tabla a un archivo RTF con formato de 3 decimales
esttab matrix(results, fmt(%9.3f)) using "vivienda_vacía_por_segmento_vtot_s_pb.rtf", replace ///
    title("Vacancy rate for population segment, comparing Basque Country's results using INE or EUB data") ///
    nonumbers nomtitles note("Data: INE & EUV. Mean computed with analitical weights using population. Segments' codification: 1 if poblacion < 10000; 2 if 10000 < population < 25000; 3 if 25000 < population < 50000; 4 if 50000 < population < 75000; 5 if 75000 < population < 100000; 6 if 100000 < population < 175000; 7 if 175000 < population < 250000; 8 if  250000 < population < 500000; 9 if population > 500000")





******************************************************************************************************************************************************************************************************************************************
**# Porcentaje de vivienda vacía por segmento poblacional
foreach año in 2011 2021 {
    foreach registro in ine euv {
        // Calcular el total de viviendas vacías por año y registro
        egen vac_tot`año'_`registro' = total(viviendas_vacias) if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != .

        // Calcular total de viviendas vacías por segmento, año y registro
        bysort segmento: egen vac_tot`año'_`registro'_s = total(viviendas_vacias) if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != .

        // Calcular la ratio de viviendas vacías totales de cada segmento de población por año y registro
        gen vac_vtot`año'_`registro' = vac_tot`año'_`registro'_s / vac_tot`año'_`registro' if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != .
		
    }
}

* Crear una lista de segmentos
levelsof segmento, local(segments)

* Crear una matriz temporal para almacenar los resultados
local rows = 4
local cols = `: word count `segments''  // Número de segmentos
local total_cols = `cols' + 1  // Número de segmentos más una columna para la suma total

matrix results = J(`rows', `total_cols', .)

* Añadir nombres de filas y columnas a la matriz
matrix rownames results = "2011 INE" "2011 EUV" "2021 INE" "2021 EUV"
local colnames = ""
foreach seg of local segments {
    local colnames = "`colnames' seg`seg'"
}
local colnames = "`colnames' total"  // Añadir columna total
matrix colnames results = `colnames'

* Llenar la matriz con los valores de vac_vtot
local i = 1
foreach año in 2011 2021 {
    foreach registro in ine euv {
        local j = 1
        local row_sum = 0
        foreach seg of local segments {
            summarize vac_vtot`año'_`registro' if segmento == `seg'
            if r(N) > 0 {
                matrix results[`i', `j'] = r(mean)
                local row_sum = `row_sum' + r(mean)
            } 
			else {
                matrix results[`i', `j'] = 0
            }
            local j = `j' + 1
        }
        matrix results[`i', `total_cols'] = `row_sum'  // Asignar suma a la columna total
        local i = `i' + 1
    }
}

* Mostrar la matriz en formato de tabla
matlist results, format(%9.3f)

* Exportar la tabla a un archivo RTF
esttab matrix(results, fmt(%9.3f)) using "vivienda_vacía_por_segmento.rtf", replace ///
    title("Percentage of vacancy for population segment") ///
    nonumbers nomtitles note("Data: INE & EUV. Segments' codification: 1 if poblacion < 10000; 2 if 10000 < population < 25000; 3 if 25000 < population < 50000; 4 if 50000 < population < 75000; 5 if 75000 < population < 100000; 6 if 100000 < population < 175000; 7 if 175000 < population < 250000; 8 if  250000 < population < 500000; 9 if population > 500000")
	
	

************************************************************************************************************************************************************
**# Porcentaje de vivienda vacía de cada segmento poblacional

foreach año in 2011 2021 {
    foreach registro in ine euv {
        display "Procesando año: `año', registro: `registro'"
/*
        // Calcular el total de viviendas vacías por segmento de población
        bysort segmento: egen vac_tot`año'_`registro'_s = total(viviendas_vacias) if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != .
*/
        // Calcular total de viviendas totales por año y registro
        bysort segmento: egen viv_tot`año'_`registro'_s = total(viviendas_totales) if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != .

        // Calcular la ratio de viviendas totales de cada segmento de población por año y registro
        bysort segmento: gen vac_vtot`año'_`registro'_s = vac_tot`año'_`registro'_s / viv_tot`año'_`registro'_s if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != .
    }
}

*____________________________________________________________________

* Crear una lista de segmentos
levelsof segmento, local(segments)

* Crear una matriz temporal para almacenar los resultados
local rows = 4
local cols = `: word count `segments''  // Número de segmentos
local total_cols = `cols' + 1  // Número de segmentos más una columna para la media ponderada

matrix results = J(`rows', `total_cols', .)

* Añadir nombres de filas y columnas a la matriz
matrix rownames results = "2011 INE" "2011 EUV" "2021 INE" "2021 EUV"
local colnames = ""
foreach seg of local segments {
    local colnames = "`colnames' seg`seg'"
}
local colnames = "`colnames' mean"  // Añadir columna media
matrix colnames results = `colnames'

* Llenar la matriz con los valores de vac_vtot_s
local i = 1
foreach año in 2011 2021 {
    foreach registro in ine euv {
        local j = 1
        foreach seg of local segments {
            summarize vac_vtot`año'_`registro'_s [aw=poblacion] if segmento == `seg'
            if r(N) > 0 {
                matrix results[`i', `j'] = r(mean)
            } 
			else {
                matrix results[`i', `j'] = 0
            }
            local j = `j' + 1
        }
        summarize vac_vtot if año == `año' & registro == "`registro'" & codi_regio > 52 & (substr(string(codi_regio), -3, 3) != "999") & codi_regio != .
        if r(N) > 0 {
            matrix results[`i', `total_cols'] = r(mean)
        } 
		else {
            matrix results[`i', `total_cols'] = 0
        }
        local i = `i' + 1
    }
}

* Mostrar la matriz en formato de tabla con 3 decimales
matlist results, format(%9.3f)

* Exportar la tabla a un archivo RTF con formato de 3 decimales
esttab matrix(results, fmt(%9.3f)) using "vivienda_vacía_por_segmento_vtot_s.rtf", replace ///
    title("Vacancy rate for population segment") ///
    nonumbers nomtitles note("Data: INE & EUV. Mean computed with analitical weights using population. Segments' codification: 1 if poblacion < 10000; 2 if 10000 < population < 25000; 3 if 25000 < population < 50000; 4 if 50000 < population < 75000; 5 if 75000 < population < 100000; 6 if 100000 < population < 175000; 7 if 175000 < population < 250000; 8 if  250000 < population < 500000; 9 if population > 500000")


*____________________________________________________________________

**# GRPAFIQUES
////Agregada
graph dot (mean) vac_vtot vac_pop [aw=poblacion] if año == 2011|2021 & (codi_regio >52 & substr(string(codi_regio), -3, 3) != "999" & codi_regio != .), over(año) over(registro) 

graph export "$figures\vacancies_spain_weighted.png", replace

////Agafant només el País Vasc, comparar dades de INE i EUV 


graph dot (mean) vac_vtot vac_pop if (codi_regio >= 1000 & codi_regio < 1999 | codi_regio >= 20000 & codi_regio < 20999 | codi_regio >= 48000 & codi_regio < 48999) & (substr(string(codi_regio), -3, 3) != "999" & codi_regio != .) [aw=poblacion], over(año) over(registro)

graph export "$figures\vacancies_PB_weighted.png", replace

//graph dot (mean) vac_11_21 viv_11_21 if año == 2011|2021 & codi_regio >52 & (registro == "ine" & ((año == 2011 & codi_regio == codi_regio[_n-1]) | (año == 2021 & codi_regio == codi_regio[_n-2]))) | registro == "euv", over(año) over(registro)



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








