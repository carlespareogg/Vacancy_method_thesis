//Anàlisi de dades INE-POBLACIÓ

use "$data\ine_euv_vivienda_poblacion.dta", clear

drop if año==.

*FER RESHAPE WIDE PER A FER EL CÀLCUL CORRECTE

//Generating change variables with values from 2011 to 2021
*____________________________________________
g lnpoblacion = ln(poblacion)
g lnviviendas_vacias = ln(viviendas_vacias)
g lnviviendas_totales = ln(viviendas_totales)

sort codi_regio registro año
bysort codi_regio: gen lnpoblacio_11_21 = lnpoblacion - lnpoblacion[_n-1] if _n>1 & año==2021 & registro=="ine"
bysort codi_regio: gen lnvac_11_21_ine = lnviviendas_vacias - lnviviendas_vacias[_n-1] if _n>1 & año==2021 & registro=="ine"
bysort codi_regio: gen lnviv_11_21_ine = lnviviendas_totales - lnviviendas_totales[_n-1] if _n>1 & año==2021 & registro=="ine" 

bysort codi_regio: gen ln_poblacio_11_21 = ln(poblacion - poblacion[_n-1]) if _n>1 & año==2021 & registro=="ine"
bysort codi_regio: gen ln_vac_11_21_ine = ln(viviendas_vacias - viviendas_vacias[_n-1]) if _n>1 & año==2021 & registro=="ine"
bysort codi_regio: gen ln_viv_11_21_ine = ln(viviendas_totales - viviendas_totales[_n-1]) if _n>1 & año==2021 & registro=="ine" 

*__________________________________

sort codi_regio registro año
bysort codi_regio: gen poblacio_11_21 = poblacion - poblacion[_n-1] if _n>1 & año==2021 & registro=="ine"
bysort codi_regio: gen vac_11_21_ine = viviendas_vacias - viviendas_vacias[_n-1] if _n>1 & año==2021 & registro=="ine"
bysort codi_regio: gen viv_11_21_ine = viviendas_totales - viviendas_totales[_n-1] if _n>1 & año==2021 & registro=="ine" 

bysort codi_regio: gen vac_11_21_euv = viviendas_vacias - viviendas_vacias[_n-5] if _n>1 & año==2021 & registro=="euv"
bysort codi_regio: gen viv_11_21_euv = viviendas_totales - viviendas_totales[_n-5] if _n>1 & año==2021 & registro=="euv"

//Generating change variables for every 2 years with EUSTAT data
bysort codi_regio: gen vac_change_euv = viviendas_vacias - viviendas_vacias[_n-1] if _n>1 & registro=="euv"
bysort codi_regio: gen viv_change_euv = viviendas_totales - viviendas_totales[_n-1] if _n>1 & registro=="euv"
bysort codi_regio: gen poblacio_change_euv = poblacion - poblacion[_n-1] if _n>1 & registro=="euv"

gen vac_11_21 = vac_11_21_ine + vac_11_21_euv
gen viv_11_21 = viv_11_21_euv + viv_11_21_ine


gen vac_pop = viviendas_vacias / poblacion
gen lnvac_pop = ln(viviendas_vacias / poblacion)
gen ln_vac_pop = ln(viviendas_vacias)/ln(poblacion)
gen vac_vtot = viviendas_vacias / viviendas_totales
gen lnvac_vtot = ln(viviendas_totales / poblacion)
gen ln_vac_vtot = ln(viviendas_totales) / ln(poblacion)


la variable	viv_11_21		"Diferencia de viviendas totales entre 2011 y 2021"
la variable	vac_11_21		"Diferencia de viviendas vacías entre 2011 y 2021"
la variable	poblacio_11_21	"Diferencia de población entre 2011 y 2021"
la variable	vac_vtot		"Vacancy rate"
la variable	vac_pop			"Vacancy/population"
la variable poblacion				"population"

**Generar variables de segmento poblacional
g segmento = .
replace segmento = 1 if poblacion < 10000
replace segmento = 2 if (poblacion > 10000 & poblacion < 25000)
replace segmento = 3 if (poblacion > 25000 & poblacion < 50000)
replace segmento = 4 if (poblacion > 50000 & poblacion < 100000)
replace segmento = 5 if (poblacion > 100000 & poblacion < 250000)
replace segmento = 6 if (poblacion > 250000 & poblacion < 500000)
replace segmento = 7 if (poblacion > 500000)
replace segmento = . if regexm(nom_regio, "^Resto de.*$") | codi_regio < 52 | codi_regio == .

**Clean population data
drop if poblacion == .

la variable segmento 		"Segmento poblacional del municipio"

**Crear variable de número de construcciones nuevas
egen newconstruc_11_21 = rowtotal(construccion_2011-construccion_2020)

g lnnewconstruc_11_21 = ln(newconstruc_11_21)

**# Estadísticas básicas

*******************************************************************************************************************************************************

**# CORRELATION POPULATION CHANGE AND NEW CONSTRUCTIONS
corr lnnewconstruc_11_21 ln_poblacio_11_21 [aw=poblacion]
corr lnnewconstruc_11_21 ln_poblacio_11_21 

twoway (scatter ln_poblacio_11_21 lnnewconstruc_11_21, mcolor(blue)) /// 
       (scatter ln_poblacio_11_21 lnnewconstruc_11_21 [aw=poblacion], mcolor(cranberry)) ///
       , legend(order(1 "unweighted, corr = 0.63" 2 "weighted, corr = 0.78") pos(3) ring(0)) ///
         ytitle("logarithm of change of population 2011-2021") ///
		 xtitle("logarithm of constructions made between 2011 and 2020") ///
         scheme(white_w3d) ///
         title("Correlation of population change and constructions") ///
		 note("Data: INE")

graph export "$figures\correlations.png", replace


*____________________________________________________________________
**# VACANCY WEIGHTED TABLE
* Calcular estadísticas para 2021, registro "ine", no ponderado
summarize viviendas_vacias if año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv21un = r(N), r(mean), r(sd), r(min), r(max)

* Calcular estadísticas para 2021, registro "ine", ponderado
summarize viviendas_vacias [aw=poblacion] if año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv21aw = r(N), r(mean), r(sd), r(min), r(max)

* Calcular estadísticas para 2011, registro "ine", no ponderado
summarize viviendas_vacias if año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv11un = r(N), r(mean), r(sd), r(min), r(max)

* Calcular estadísticas para 2011, registro "ine", ponderado
summarize viviendas_vacias [aw=poblacion] if año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv11aw = r(N), r(mean), r(sd), r(min), r(max)

* Combinar matrices en una sola matriz
matrix results = (vv21un \ vv21aw \ vv11un \ vv11aw)

* Añadir nombres de filas y columnas
matrix rownames results = "Unweighted 2021" "Weighted 2021" "Unweighted 2011" "Weighted 2011"
matrix colnames results = "count" "mean" "sd" "min" "max"

* Mostrar la matriz en formato de tabla
matlist results, format(%9.2f)

* Exportar la tabla a un archivo RTF
esttab matrix(results) using "$tables/descriptives_table_vvweights.rtf", replace ///
    cells("count mean sd min max") ///
    title("Unweighted and Weighted Statistics of vacancy dwellings") ///
    nonumbers nomtitles note("Data: INE")
	
****************************************************************************************************************************************************************************
**# VACANCY RATE AND VACANCY/POPULATION TABLE
* Calcular vacancy/population para 2021, registro "ine", ponderado
summarize vac_pop [aw=poblacion] if año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv21un = r(N), r(mean), r(sd), r(p10), r(p90)

* Calcular vacancy rate para 2021, registro "ine", ponderado
summarize vac_vtot [aw=poblacion] if año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv21aw = r(N), r(mean), r(sd), r(p10), r(p90)

* Calcular estadísticas para 2011, registro "ine", no ponderado
summarize vac_pop [aw=poblacion] if año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv11un = r(N), r(mean), r(sd), r(p10), r(p90)

* Calcular estadísticas para 2011, registro "ine", ponderado
summarize vac_vtot [aw=poblacion] if año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv11aw = r(N), r(mean), r(sd), r(p10), r(p90)
* Combinar matrices en una sola matriz
matrix results = (vv21un \ vv21aw \ vv11un \ vv11aw)

* Añadir nombres de filas y columnas
matrix rownames results = "Vacancy/pop 2021" "Vacancy rate 2021" "Vacancy/pop 2011" "Vacancy rate 2011"
matrix colnames results = "count" "mean" "sd" "p10" "p90"

* Mostrar la matriz en formato de tabla
matlist results, format(%9.2f)

* Exportar la tabla a un archivo RTF
esttab matrix(results, fmt(%9.3f)) using "$tables/descriptives_table_rates_ine.rtf", replace ///
    cells("count mean sd min max") ///
    title("Vacancy controlled by the size of the municipality") ///
    nonumbers nomtitles note("Data: INE. Values weighted by population")
	
**TRIMMED RATIOS**

summarize vac_pop [aw=poblacion] if poblacion > 5000 & año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv21un = r(N), r(mean), r(sd), r(p10), r(p90)

* Calcular vacancy rate para 2021, registro "ine", ponderado
summarize vac_vtot [aw=poblacion] if poblacion > 5000 & año == 2021 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv21aw = r(N), r(mean), r(sd), r(p10), r(p90)

* Calcular estadísticas para 2011, registro "ine", no ponderado
summarize vac_pop [aw=poblacion] if poblacion > 5000 & año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv11un = r(N), r(mean), r(sd), r(p10), r(p90)

* Calcular estadísticas para 2011, registro "ine", ponderado
summarize vac_vtot [aw=poblacion] if poblacion > 5000 & año == 2011 & registro == "ine" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999", detail
matrix vv11aw = r(N), r(mean), r(sd), r(p10), r(p90)

* Combinar matrices en una sola matriz
matrix results = (vv21un \ vv21aw \ vv11un \ vv11aw)

* Añadir nombres de filas y columnas
matrix rownames results = "Vacancy/pop 2021" "Vacancy rate 2021" "Vacancy/pop 2011" "Vacancy rate 2011"
matrix colnames results = "count" "mean" "sd" "p10" "p90"

* Mostrar la matriz en formato de tabla
matlist results, format(%9.2f)

* Exportar la tabla a un archivo RTF
esttab matrix(results, fmt(%9.3f)) using "$tables/descriptives_table_rates_ine_trimmedsample.rtf", replace ///
    cells("count mean sd min max") ///
    title("Vacancy controlled by the size of the municipality. Trimmed sample: population > 5000") ///
    nonumbers nomtitles note("Data: INE. Values weighted by population")




	

************************************************************************************************************************************************************
**# Methodology EUSTAT-INE. % of vacancy in every population segment

foreach año in 2011 2021 {
    foreach registro in ine euv {
        display "Procesando año: `año', registro: `registro'"

        // Calcular el total de viviendas vacías por segmento de población
        bysort segmento: egen vac_tot`año'_`registro'_s_pb = total(viviendas_vacias) if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & poblacion > 10000

        // Calcular total de viviendas totales por año y registro
        bysort segmento: egen viv_tot`año'_`registro'_s_pb = total(viviendas_totales) if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & poblacion > 10000

        // Calcular la ratio de viviendas totales de cada segmento de población por año y registro
        bysort segmento: gen vac_vtot`año'_`registro'_s_pb = vac_tot`año'_`registro'_s_pb / viv_tot`año'_`registro'_s_pb if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & poblacion > 10000
    }
}


* Crear una lista de segmentos
levelsof segmento, local(segments)

* Crear una matriz temporal para almacenar los resultados
local rows = 4
local cols = `: word count `segments''  // Número de segmentos
local total_cols = `cols' + 1  // Número de segmentos más una columna para la media ponderada

matrix results = J(`rows', `total_cols', .)

* Añadir nombres de filas y columnas a la matriz
matrix rownames results = "2011 INE" "2011 EUSTAT" "2021 INE" "2021 EUSTAT"
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
        summarize vac_vtot [aw=poblacion] if año == `año' & registro == "`registro'" & codi_regio > 52 & (substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999))
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
esttab matrix(results, fmt(%9.3f)) using "$tables/vivienda_vacía_por_segmento_vtot_s_pb.rtf", replace ///
    title("Vacancy rate for population segment, comparing Basque Country's results using INE or EUSTAT data") ///
    nonumbers nomtitles note("Data: INE & EUSTAT. Mean computed with analytical weights using population. Segments' codification: 1 if population < 10000; 2 if 10000 < population < 25000; 3 if 25000 < population < 50000; 4 if 50000 < population < 100000; 5 if 100000 < population < 250000; 6 if 250000 < population < 500000; 7 if population > 500000")

******************************************************************************************************************************************************************************************************************************************
**# Methodology EUSTAT-INE. % of vacancy/populaiton in every population segment

foreach año in 2011 2021 {
    foreach registro in ine euv {
        display "Procesando año: `año', registro: `registro'"

        // Calcular el total de viviendas vacías por segmento de población
		////Calculado en la anterior tabla

        // Calcular total de poblacion por año y registro
        bysort segmento: egen pop`año'_`registro'_s_pb = total(poblacion) if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & poblacion > 10000

        // Calcular la ratio de viviendas/poblacion de cada segmento de población por año y registro
        bysort segmento: gen vac_pop`año'_`registro'_s_pb = vac_tot`año'_`registro'_s_pb / pop`año'_`registro'_s_pb if (año == `año' & registro == "`registro'" & codi_regio > 52 & substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & poblacion > 10000
    }
}


* Crear una lista de segmentos
levelsof segmento, local(segments)

* Crear una matriz temporal para almacenar los resultados
local rows = 4
local cols = `: word count `segments''  // Número de segmentos
local total_cols = `cols' + 1  // Número de segmentos más una columna para la media ponderada

matrix results = J(`rows', `total_cols', .)

* Añadir nombres de filas y columnas a la matriz
matrix rownames results = "2011 INE" "2011 EUSTAT" "2021 INE" "2021 EUSTAT"
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
            summarize vac_pop`año'_`registro'_s_pb [aw=poblacion] if segmento == `seg'
            if r(N) > 0 {
                matrix results[`i', `j'] = r(mean)
            } 
			else {
                matrix results[`i', `j'] = 0
            }
            local j = `j' + 1
        }
        summarize vac_pop [aw=poblacion] if año == `año' & registro == "`registro'" & codi_regio > 52 & (substr(string(codi_regio), -3, 3) != "999") & codi_regio != . & ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999))
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
esttab matrix(results, fmt(%9.3f)) using "$tables/vivienda_vacía_por_segmento_pop_s_pb.rtf", replace ///
    title("Vacancy/population for population segment, comparing Basque Country's results using INE or EUSTAT data") ///
    nonumbers nomtitles note("Data: INE & EUSTAT. Mean computed with analytical weights using population. Segments' codification: 1 if population < 10000; 2 if 10000 < population < 25000; 3 if 25000 < population < 50000; 4 if 50000 < population < 100000; 5 if 100000 < population < 250000; 6 if 250000 < population < 500000; 7 if population > 500000")

	
******************************************************************************************************************************************************************************************************************************************

**# Ratio of weighted difference by segments
// Extract values for each registro and year

// Reshape the data to wide format to have all necessary values in the same observation
preserve

bysort segmento: egen vac_pop2011_ine = mean(vac_pop2011_ine_s_pb)
bysort segmento: egen vac_pop2021_ine = mean(vac_pop2021_ine_s_pb)
bysort segmento: egen vac_pop2011_euv = mean(vac_pop2011_euv_s_pb)
bysort segmento: egen vac_pop2021_euv = mean(vac_pop2021_euv_s_pb)
duplicates drop vac_pop2011_ine, force
duplicates drop vac_pop2021_ine, force
duplicates drop vac_pop2011_euv, force
duplicates drop vac_pop2011_euv, force


keep registro segmento vac_pop2011_ine vac_pop2021_ine vac_pop2011_euv vac_pop2021_euv
reshape wide vac_pop2011_ine vac_pop2021_ine vac_pop2011_euv vac_pop2021_euv, i(segmento) j(registro, string)

// Calculate the ratios
gen ine_s_pb_21_11 = (vac_pop2021_ine - vac_pop2011_ine) / vac_pop2011_ine
gen euv_s_pb_21_11 = (vac_pop2021_euv - vac_pop2011_euv) / vac_pop2011_euv

// Compute the final ratio_method
gen ratio_method = ine_s_pb_21_11 / euv_s_pb_21_11

// Verify the results
list segmento ine_s_pb_21_11 euv_s_pb_21_11 ratio_method if !missing(ratio_method) 

save "$dataoutput/ratio_method.dta", replace



* Crear una lista de segmentos
levelsof segmento, local(segments)

* Crear una matriz temporal para almacenar los resultados
local rows = 1
local cols = `: word count `segments''  // Número de segmentos
local total_cols = `cols' + 1  // Número de segmentos más una columna para la media ponderada

matrix results = J(`rows', `total_cols', .)

* Añadir nombres de filas y columnas a la matriz
matrix rownames results = "r"
local colnames = ""
foreach seg of local segments {
    local colnames = "`colnames' seg`seg'"
}
local colnames = "`colnames' mean"  // Añadir columna media
matrix colnames results = `colnames'

* Llenar la matriz con los valores de vac_vtot_s
local i = 1
        local j = 1
        foreach seg of local segments {
            summarize ratio_method if segmento == `seg'
            if r(N) > 0 {
                matrix results[`i', `j'] = r(mean)
            } 
			else {
                matrix results[`i', `j'] = 0
            }
            local j = `j' + 1
        }
        summarize ratio_method  
        if r(N) > 0 {
            matrix results[`i', `total_cols'] = r(mean)
        } 
		else {
            matrix results[`i', `total_cols'] = 0
        }
        local i = `i' + 1
    

* Mostrar la matriz en formato de tabla con 3 decimales
matlist results, format(%9.3f)

* Exportar la tabla a un archivo RTF con formato de 3 decimales
esttab matrix(results, fmt(%9.3f)) using "$tables/ratio_dif_ine_eustat_s_pb.rtf", replace ///
    title("Ratio of weighted differences between INE and EUSTAT results") ///
    nonumbers nomtitles note("Data: INE & EUSTAT. Mean computed with analytical weights using population. Segments' codification: 1 if population < 10000; 2 if 10000 < population < 25000; 3 if 25000 < population < 50000; 4 if 50000 < population < 100000; 5 if 100000 < population < 250000; 6 if 250000 < population < 500000; 7 if population > 500000")

restore

******************************************************************************************************************************************************************************************************************************************
**# % of vacancy by population segment
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
matrix rownames results = "2011 INE" "2011 EUSTAT" "2021 INE" "2021 EUSTAT"
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
            summarize vac_vtot`año'_`registro' [aw=poblacion] if segmento == `seg'
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
esttab matrix(results, fmt(%9.3f)) using "$tables/vivienda_vacía_por_segmento.rtf", replace ///
    title("Percentage of vacancy for population segment") ///
    nonumbers nomtitles note("Data: INE & EUSTAT. Segments' codification: 1 if population < 10000; 2 if 10000 < population < 25000; 3 if 25000 < population < 50000; 4 if 50000 < population < 100000; 5 if 100000 < population < 250000; 6 if 250000 < population < 500000; 7 if population > 500000")
	
	

************************************************************************************************************************************************************
**# % of vacancy in every population segment

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
local rows = 2
local cols = `: word count `segments''  // Número de segmentos
local total_cols = `cols' + 1  // Número de segmentos más una columna para la media ponderada

matrix results = J(`rows', `total_cols', .)

* Añadir nombres de filas y columnas a la matriz
matrix rownames results = "2011 INE" "2021 INE" 
local colnames = ""
foreach seg of local segments {
    local colnames = "`colnames' seg`seg'"
}
local colnames = "`colnames' mean"  // Añadir columna media
matrix colnames results = `colnames'

* Llenar la matriz con los valores de vac_vtot_s
local i = 1
foreach año in 2011 2021 {
        local j = 1
        foreach seg of local segments {
            summarize vac_vtot`año'_ine_s [aw=poblacion] if segmento == `seg' & registro == "ine"
            if r(N) > 0 {
                matrix results[`i', `j'] = r(mean)
            } 
			else {
                matrix results[`i', `j'] = 0
            }
            local j = `j' + 1
        }
        summarize vac_vtot [aw=poblacion] if año == `año' & registro == "ine" & codi_regio > 52 & (substr(string(codi_regio), -3, 3) != "999") & codi_regio != .
        if r(N) > 0 {
            matrix results[`i', `total_cols'] = r(mean)
        } 
		else {
            matrix results[`i', `total_cols'] = 0
        }
        local i = `i' + 1
    }


* Mostrar la matriz en formato de tabla con 3 decimales
matlist results, format(%9.3f)

* Exportar la tabla a un archivo RTF con formato de 3 decimales
esttab matrix(results, fmt(%9.3f)) using "$tables/vivienda_vacía_por_segmento_vtot_s.rtf", replace ///
    title("Vacancy rate for population segment") ///
    nonumbers nomtitles note("Data: INE. Mean computed with analytical weights using population. Segments' codification: 1 if population < 10000; 2 if 10000 < population < 25000; 3 if 25000 < population < 50000; 4 if 50000 < population < 100000; 5 if 100000 < population < 250000; 6 if 250000 < population < 500000; 7 if population > 500000")


*____________________________________________________________________

**# GRAPHS

**# Agregated
////AGREGATE________________________________________________________

graph dot (mean) vac_vtot vac_pop [aw=poblacion] if año == 2011|2021 & (codi_regio >52 & substr(string(codi_regio), -3, 3) != "999" & codi_regio != .), over(año) over(registro) scheme(white_w3d) marker(1, mcolor(blue))     legend(order(1 "Vacancy rate" 2 "Vacancy/population")) title("Weighted vacancy rate and vacancy/population ratios") subtitle("Using data for all Spain") note("Data: INE and EUSTAT") 

graph export "$figures\vacancies_spain_weighted.png", replace

graph dot (mean) vac_vtot vac_pop if año == 2011|2021 & (codi_regio >52 & substr(string(codi_regio), -3, 3) != "999" & codi_regio != .), over(año) over(registro) scheme(white_w3d) marker(1, mcolor(blue)) legend(order(1 "Vacancy rate" 2 "Vacancy/population")) title("Unweighted vacancy rate and vacancy/population ratios") subtitle("Using data for all Spain") note("Data: INE and EUSTAT") 

graph export "$figures\vacancies_spain_unweighted.png", replace

////TAKING ONLY BASQUE COUNTRY DATA, COMPARING INE AND EUSTAT________________________________________________________ 

graph dot (mean) vac_vtot vac_pop [aw=poblacion] if (año == 2011 | año == 2021) & (codi_regio >= 1000 & codi_regio < 1999 | codi_regio >= 20000 & codi_regio < 20999 | codi_regio >= 48000 & codi_regio < 48999) & (substr(string(codi_regio), -3, 3) != "999" & codi_regio != .), over(año) over(registro) scheme(white_w3d) marker(1, mcolor(blue)) legend(order(1 "Vacancy rate" 2 "Vacancy/population")) title("Weighted vacancy rate and vacancy/population ratios") subtitle("For Basque municipalities only") note("Data: INE and EUSTAT") 

graph export "$figures\vacancies_PB_weighted.png", replace

graph dot (mean) vac_vtot vac_pop if (codi_regio >= 1000 & codi_regio < 1999 | codi_regio >= 20000 & codi_regio < 20999 | codi_regio >= 48000 & codi_regio < 48999) & (substr(string(codi_regio), -3, 3) != "999" & codi_regio != .), over(año) over(registro) scheme(white_w3d) marker(1, mcolor(blue))     legend(order(1 "Vacancy rate" 2 "Vacancy/population")) title("Unweighted vacancy rate and vacancy/population ratios") subtitle("For Basque municipalities only") note("Data: INE and EUSTAT") 

graph export "$figures\vacancies_PB_unweighted.png", replace

graph dot (mean) vac_vtot vac_pop [aw=poblacion] if (año == 2011 | año == 2021) & (poblacion > 10000) & (codi_regio >= 1000 & codi_regio < 1999 | codi_regio >= 20000 & codi_regio < 20999 | codi_regio >= 48000 & codi_regio < 48999) & (substr(string(codi_regio), -3, 3) != "999" & codi_regio != .), over(año) over(registro) scheme(white_w3d) marker(1, mcolor(blue)) legend(order(1 "Vacancy rate" 2 "Vacancy/population")) title("Weighted vacancy rate and vacancy/population ratios") subtitle("For Basque municipalities only. Sample of municipalities > 10.000 inhabitants") note("Data: INE and EUSTAT") 

graph export "$figures\vacancies_PB_weighted_trimmedsample.png", replace



**# By populaiton size

///FOR POPULATION SIZE________________________________________________________

// Gráfico para población < 10000
graph dot (mean) vac_vtot vac_pop if poblacion < 10000 & (año == 2011 | año == 2021) & (codi_regio >52) & registro == "ine" & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) marker(1, mcolor(blue)) title("pop < 10000") name(graph1, replace) scheme(white_w3d) legend(order(1 "Vacancy rate" 2 "Vacancy/population")) leg(off)

// Gráfico para 10000 < población < 25000
graph dot (mean) vac_vtot vac_pop if (poblacion > 10000 & poblacion < 25000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title("10000 < pop < 25000") name(graph2, replace) scheme(white_w3d) marker(1, mcolor(blue)) leg(off)

// Gráfico para 25000 < población < 100000
graph dot (mean) vac_vtot vac_pop if (poblacion > 25000 & poblacion < 100000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title("25000 < pop < 100000") name(graph3, replace) scheme(white_w3d) marker(1, mcolor(blue)) leg(off)

// Gráfico para 100000 < población < 250000
graph dot (mean) vac_vtot vac_pop if (poblacion > 100000 & poblacion < 250000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title("100000 < pop < 250000") name(graph4, replace) scheme(white_w3d) marker(1, mcolor(blue)) leg(off)

// Gráfico para 250000 < población < 500000
graph dot (mean) vac_vtot vac_pop if (poblacion > 250000 & poblacion < 500000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title("250000 < pop < 500000") name(graph5, replace) scheme(white_w3d) marker(1, mcolor(blue)) leg(off)

// Gráfico para población > 500000
graph dot (mean) vac_vtot vac_pop if poblacion > 500000 & (año == 2011 | año == 2021) & (codi_regio > 52 & (substr(string(codi_regio), -3, 3) != "999")) & registro == "ine" [aw=poblacion], over(año) over(registro) title("500000 < pop") name(graph6, replace) scheme(white_w3d) marker(1, mcolor(blue)) leg(off)

grc1leg2 graph1 graph2 graph3 graph4 graph5 graph6, rows(3) cols(2) name(combined, replace) scheme(white_w3d) title("Vacancy rate and vacancy/population rate") note("Data: INE & EUSTAT")

graph export "$figures\GridPobl_ine-eustat.png", replace


//By populaiton size taking only Basque Country data

graph dot (mean) vac_vtot vac_pop if ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & (año == 2011 | año == 2021) & (poblacion > 10000 & poblacion < 25000) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(10000 < población < 25000) name(graph1, replace) legend(order(1 "Vacancy rate" 2 "Vacancy/population")) marker(1, mcolor(blue)) leg(off) scheme(white_w3d)

graph dot (mean) vac_vtot vac_pop if ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & (año == 2011 | año == 2021) & (poblacion > 25000 & poblacion < 50000) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(25000 < población < 50000) name(graph2, replace) marker(1, mcolor(blue)) leg(off) scheme(white_w3d)

graph dot (mean) vac_vtot vac_pop if ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & (año == 2011 | año == 2021) & (poblacion > 50000 & poblacion < 100000) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(50000 < población < 100000) name(graph3, replace) marker(1, mcolor(blue)) leg(off) scheme(white_w3d)


graph dot (mean) vac_vtot vac_pop if ((codi_regio >= 1000 & codi_regio < 1999) | (codi_regio >= 20000 & codi_regio < 20999) | (codi_regio >= 48000 & codi_regio < 48999)) & (año == 2011 | año == 2021) & (poblacion > 100000) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(poblacion > 100000) name(graph4, replace) marker(1, mcolor(blue)) leg(off) scheme(white_w3d)


grc1leg2 graph1 graph2 graph3 graph4, rows(2) cols(2) scheme(white_w3d) title("Vacancy rate and vacancy/population rate") subtitle("Comparing Basque Country's results") note("Data: INE & EUSTAT")

graph export "$figures\GridPoblPB_ine-eustat.png", replace


*____________________________________________________________________
***********************************************************************************************************EN CONSTRUCCIÓ 
**# Bookmark #1
//Threshold quan vacancy es manté
*Per a vacancy/població
graph dot (mean) vac_vtot vac_pop if (poblacion > 20000 & poblacion < 27000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(20000 < población < 27000) name(graph3, replace)

*Per a vacancy rate
graph dot (mean) vac_vtot vac_pop if (poblacion > 6000 & poblacion < 10000) & (año == 2011 | año == 2021) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], over(año) over(registro) title(6000 < población < 10000) name(graph3, replace)

**# Scatterplots

************************Scatter plolts************************

//vacancy rate-població per any, INE i estimació

capture separate vac_vtot, by(año) 
colorpalette tableau, nograph intensity(0.8)
twoway (scatter vac_vtot poblacion if registro == "ine" & ((año == 2011) & (poblacion > 50000 & poblacion < 200000)) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999"), sort color(blue)) (scatter vac_vtot poblacion if registro == "ine" & ((año == 2021) & (poblacion > 50000 & poblacion < 200000)) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999"), sort color(red)) (lfit vac_vtot poblacion if registro == "ine" & ((año == 2011) & (poblacion > 50000 & poblacion < 200000)) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], color(navy)) (lfit vac_vtot poblacion if registro == "ine" & ((año == 2021) & (poblacion > 50000 & poblacion < 200000)) & (codi_regio >52) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], color("cranberry")), legend(order(1 "2011" 2 "2021" 3 "fitted 2011" 4 "fitted 2021") pos(1) ring(0)) ytitle("vacancy rate") scheme(white_w3d) name(graph5, replace) note("Data: INE and EUSTAT") 


graph export "$figures\ccaa_vacrate.png", replace


**# By territory

****************Graphs over territory******************

graph dot (mean) vac_vtot if registro == "ine" & ((año == 2011)) & (substr(string(codi_regio), -3, 3) != "999")  & (codi_regio >52) & codi_regio != . [aw=poblacion], o(com_autonoma, sort(1)) name(ccaa1, replace) scheme(white_w3d) title("2011") leg(off) ytitle("")

graph dot (mean) vac_vtot if registro == "ine" & ((año == 2021)) & (substr(string(codi_regio), -3, 3) != "999")  & (codi_regio >52) & codi_regio != . [aw=poblacion], o(com_autonoma, sort(1)) marker(1, mcolor(red)) name(ccaa2, replace) scheme(white_w3d) title("2021") leg(off) ytitle("")

//graph box vac_vtot if registro == "ine" & ((año == 2011) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], o(com_autonoma, sort(1)) scheme(white_w3d)

//graph box (mean) vac_vtot if registro == "ine" & ((año == 2021) & (poblacion > 50000 & poblacion < 200000)) & (substr(string(codi_regio), -3, 3) != "999") [aw=poblacion], o(com_autonoma, sort(1)) marker(1, mcolor(red)) scheme(white_w3d)


graph combine ccaa1 ccaa2, rows(1) scheme(white_w3d) title("Vacancy rate by Autonomous Comunity") note("Data: INE.") 

graph export "$figures\ccaa_viv_ordered_grid.png", replace


*____________________________________________________________________EN CONSTRUCCIÓ
graph dot (mean) vac_vtot if registro == "ine" & ((año == 2011)) & (substr(string(codi_regio), -3, 3) != "999")  & (codi_regio >52) & codi_regio < 25999 & codi_regio != . [aw=poblacion], o(provincia, sort(1))  name(ccaa1, replace) scheme(white_w3d) title("2011") leg(off) ytitle("")









