
clear 

//MERGE POPULATION AND INE-EUV VACANCY DATASET
//* Prepare population dataset having premerged manually 2011 and 2021 data and erasing nationality-specific data
import excel "$ineinput\relación vivenda 2011 y 2021_merge_sensenacionalitat.xlsx", sheet("tabla-55248") firstrow
/*expand 2, gen(new_id)
replace año = 2011 if new_id == 1
drop new_id
*/
gen idpoblacio = _n
save "$ineoutput\vivienda_2011_2021_nonacionalitat.dta", replace

clear
//* Prepare 2011-2019 population dataset having premerged manually every year
import excel "$ineinput\poblacion_2011_2019.xlsx", sheet("Hoja1") firstrow
gen idpoblacio = _n
gen codi_regio = CPRO + CMUN
destring codi_regio, replace
drop if año==.
gen registro = "ine"
save "$ineoutput\poblacion_2011_2019.dta", replace


clear
//*Prepare construction dataset to merge with INE and EUV vacancy datasets
import excel "$ineinput\vivienda_año_construccion.xlsx", sheet("Hoja1") firstrow
gen año = 2021
/*expand 2, gen(new_id)
replace año = 2011 if new_id == 1
drop new_id
*/
gen idvivenda = _n
save "$ineoutput\vivenda_año_construccion.dta", replace

clear
//* Prepare vacancy dataset having premerged INE and EUV datasets (Capitals and "Porcentaje de viviendas familiares no principales por municipios de 10.001 a 100.000 habitantes. 2011-2021", provided by the Departamento de Planificación Territorial, Vivienda y Transportes of the Basque Country)
import excel "$interdata\ine_euv_merge.xlsx", sheet("Hoja1") firstrow
gen idvivenda1 = _n
replace nom_regio = subinstr(nom_regio, " *", "", .)
save "$interdata\ine_euv_merge.dta", replace

reclink codi_regio nom_regio año using "$ineoutput\vivenda_año_construccion.dta", idmaster(idvivenda1) idusing(idvivenda) minscore(0.95) required (año) gen(vivenda_score)
////Non-merged observations are the ones which correspond to years others than 2011 or 2021 or provinces
drop _merge

//*merge with 2011 to 2021 population data from INE, which includes mobility variables with a 90% merging statistical score
reclink codi_regio nom_regio año using "$ineoutput\vivienda_2011_2021_nonacionalitat.dta", idmaster(idvivenda1) idusing(idpoblacio) minscore(0.9) gen(poblacio_score)
////Non-merged observations are the ones which correspond to years others than 2011 or 2021 or provinces
drop _merge
drop idpoblacio


//*merge with 2011 to 2019 population data from INE with a 90% merging statistical score

merge m:1 codi_regio año using "$ineoutput\poblacion_2011_2019.dta", update

drop if (año == 2011 | año == 2013 | año == 2015 | año == 2017 | año == 2019) & missing(viviendas_totales)

/*sort codi_regio año
* Asignar los valores de población de registros "euv" a las observaciones con el mismo año y nom_regio pero con registro "ine"
replace poblacion = poblacion[_n-1] if registro == "ine" & registro[_n-1] == "euv" & año == año[_n-1] & nom_regio == nom_regio[_n-1]


/*reclink codi_regio año using "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\poblacion_2011_2019.dta", idmaster(idvivenda1) idusing(idpoblacio) gen(poblacio_score1)
*/
*/
replace viviendas_vacias = . if viviendas_vacias == 0
rename PROVINCIA provincia
drop CPRO
drop CMUN
drop I


drop vivenda_score
drop poblacio_score
drop idpoblacio
drop idvivenda1
drop idvivenda
drop ciudadanía
drop _merge
drop Ucodi_regio
drop Unom_regio
drop Uaño

//////////////////////IN CONSTRUCTION
/* Clean
**Generar nivel de territorialidad
* Definir nombres de provincias y comunidades autónomas
local provincias "Araba/Álava Albacete Alicante/Alacant Almería Ávila Badajoz Baleares Barcelona Bizkaia Burgos Cáceres Cádiz Castellón/Castelló Ciudad Real Córdoba Coruña, A Cuenca Girona Granada Guadalajara Gipuzkoa Huelva Huesca Jaén León Lleida La Rioja Lugo Madrid Málaga Murcia Navarra Ourense Asturias Palencia Palmas, Las Pontevedra Salamanca Santa Cruz de Tenerife Cantabria Segovia Sevilla Soria Tarragona Teruel Toledo Valencia/València Valladolid Zamora Zaragoza"
local comunidades_autonomas "Andalucía Aragón Asturias, Principado de Balears, Illes Canarias Cantabria Castilla y León Castilla - La Mancha Cataluña Extremadura Galicia Rioja, La Madrid, Comunidad de Murcia, Región de Navarra, Comunidad Foral de País Vasco Comunitat Valenciana Ceuta Melilla"

* Generar variable nivel_region
generate nivel_region = 0


foreach provincia in `provincias' {
    if strpos(lower(nom_regio), lower("`provincia'")) > 0 {
        replace nivel_region = 1
    }
}

* Asignar valor 2 a comunidades autónomas
foreach comunidad in `comunidades_autonomas' {
    if strpos(lower(nom_regio), lower("`comunidad'")) > 0 {
        replace nivel_region = 2
    }
}


* Asignar valor 1 a provincias
foreach provincia in `provincias' {
    replace nivel_region = 1 if lower(nom_regio) == lower("`provincia'")
}

* Asignar valor 2 a comunidades autónomas
foreach comunidad in `comunidades_autonomas' {
    replace nivel_region = 2 if lower(nom_regio) == lower("`comunidad'")
}

* Verificar la variable nivel_region
tabulate nivel_region
/////////////////////////7 IN CONSTRUCTION
*/

* Canviar nom dels labels per les variables mobilitat general, homes i dones*

label variable a_misma_vivienda "Misma vivienda"
label variable a_dist_viv_mismo_muni "Distinta vivienda del mismo municipio"
label variable a_dist_muni_misma_prov "Distinto municipio de la misma provincia"
label variable a_dist_prov_misma_ccaa "Distinta provincia de la misma comunidad"
label variable a_otra_ccaa "Otra comunidad"
label variable a_venidodeestranj "Residía en el extranjero"
label variable a_nores2011_siempreesp "No consta la residencia hace diez años, pero siempre ha residido en España"
label variable a_nores2011_nosiempreesp "No consta la residencia hace diez años, y no siempre ha residido en España"
label variable a_nacido "No había nacido"
label variable a_misma_vivienda_h "Misma vivienda Hombre"
label variable a_dist_viv_mismo_muni_h "Distinta vivienda del mismo municipio Hombre"
label variable a_dist_muni_misma_prov_h "Distinto municipio de la misma provincia Hombre"
label variable a_dist_prov_misma_ccaa_h "Distinta provincia de la misma comunidad Hombre"
label variable a_otra_ccaa_h "Otra comunidad Hombre"
label variable a_venidodeestranj_h "Residía en el extranjero Hombre"
label variable a_nores2011_siempreesp_h "No consta la residencia hace diez años, pero siempre ha residido en España Hombre"
label variable a_nores2011_nosiempreesp_h "No consta la residencia hace diez años, y no siempre ha residido en España Hombre"
label variable a_nacido_h "No había nacido Hombre"
label variable a_misma_vivienda_m "Misma vivienda Mujer"
label variable a_dist_viv_mismo_muni_m "Distinta vivienda del mismo municipio Mujer"
label variable a_dist_muni_misma_prov_m "Distinto municipio de la misma provincia Mujer"
label variable a_dist_prov_misma_ccaa_m "Distinta provincia de la misma comunidad Mujer"
label variable a_otra_ccaa_m "Otra comunidad Mujer"
label variable a_venidodeestranj_m "Residía en el extranjero Mujer"
label variable a_nores2011_siempreesp_m "No consta la residencia hace diez años, pero siempre ha residido en España Mujer"
label variable a_nores2011_nosiempreesp_m "No consta la residencia hace diez años, y no siempre ha residido en España Mujer"
label variable a_nacido_m "No había nacido Mujer"

*Crear variable provincia i CCAA*

gen provincia = ""
 
 replace provincia= "Álava" if codi_regio >= 1000 & codi_regio <= 1999
 replace provincia= "Albacete" if codi_regio >= 2000 & codi_regio <= 2999
 replace provincia= "Almeria" if codi_regio >= 3000 & codi_regio <= 3999
 replace provincia= "Alicante" if codi_regio >= 4000 & codi_regio <= 4999
 replace provincia= "Ávila" if codi_regio >= 5000 & codi_regio <= 5999
 replace provincia= "Badajoz" if codi_regio >= 6000 & codi_regio <= 6999
 replace provincia= "Illes Balears" if codi_regio >= 7000 & codi_regio <= 7999
 replace provincia= "Barcelona" if codi_regio >= 8000 & codi_regio <= 8999
 replace provincia= "Burgos" if codi_regio >= 9000 & codi_regio <= 9999
 replace provincia= "Burgos" if codi_regio >= 10000 & codi_regio <= 10999
 replace provincia= "Cádiz" if codi_regio >= 11000 & codi_regio <= 11999
 replace provincia= "Castelló" if codi_regio >= 12000 & codi_regio <= 12999
 replace provincia= "Ciudad Real" if codi_regio >= 13000 & codi_regio <= 13999
 replace provincia= "Cordoba" if codi_regio >= 14000 & codi_regio <= 14999
 replace provincia= "A Coruña" if codi_regio >= 15000 & codi_regio <= 15999
 replace provincia= "Cuenca" if codi_regio >= 16000 & codi_regio <= 16999
 replace provincia= "Girona" if codi_regio >= 17000 & codi_regio <= 17999
 replace provincia= "Granada" if codi_regio >= 18000 & codi_regio <= 18999
 replace provincia= "Guadalajara" if codi_regio >= 19000 & codi_regio <= 19999
 replace provincia= "Gipuzkoa" if codi_regio >= 20000 & codi_regio <= 20999
 replace provincia= "Huelva" if codi_regio >= 21000 & codi_regio <= 21999
 replace provincia= "Huesca" if codi_regio >= 22000 & codi_regio <= 22999
 replace provincia= "Jaén" if codi_regio >= 23000 & codi_regio <= 23999
 replace provincia= "Leon" if codi_regio >= 24000 & codi_regio <= 24999
 replace provincia= "Lleida" if codi_regio >= 25000 & codi_regio <= 25999
 replace provincia= "La Rioja" if codi_regio >= 26000 & codi_regio <= 26999
 replace provincia= "Lugo" if codi_regio >= 27000 & codi_regio <= 27999
 replace provincia= "Madrid" if codi_regio >= 28000 & codi_regio <= 28999
 replace provincia= "Málaga" if codi_regio >= 29000 & codi_regio <= 29999
 replace provincia= "Murcia" if codi_regio >= 30000 & codi_regio <= 30999
 replace provincia= "Navarra" if codi_regio >= 31000 & codi_regio <= 31999
 replace provincia= "Ourense" if codi_regio >= 32000 & codi_regio <= 32999
 replace provincia= "Asturias" if codi_regio >= 33000 & codi_regio <= 33999
 replace provincia= "Palencia" if codi_regio >= 34000 & codi_regio <= 34999
 replace provincia= "Tenerife" if codi_regio >= 35000 & codi_regio <= 35999
  replace provincia= "Salamanca" if codi_regio >= 37000 & codi_regio <= 37999
 replace provincia= "Pontevedra" if codi_regio >= 36000 & codi_regio <= 36999
 replace provincia= "Las Palmas" if codi_regio >= 38000 & codi_regio <= 38999
 replace provincia= "Cantabria" if codi_regio >= 39000 & codi_regio <= 39999
 replace provincia= "Segovia" if codi_regio >= 40000 & codi_regio <= 40999
 replace provincia= "Sevilla" if codi_regio >= 41000 & codi_regio <= 41999
 replace provincia= "Soria" if codi_regio >= 42000 & codi_regio <= 42999
 replace provincia= "Tarragona" if codi_regio >= 43000 & codi_regio <= 43999
 replace provincia= "Tarragona" if codi_regio >= 44000 & codi_regio <= 44999
 replace provincia= "Toledo" if codi_regio >= 45000 & codi_regio <= 45999
 replace provincia= "Valencia" if codi_regio >= 46000 & codi_regio <= 46999
replace provincia= "Valladolid" if codi_regio >= 47000 & codi_regio <= 47999
replace provincia= "Bizkaia" if codi_regio >= 48000 & codi_regio <= 48999
replace provincia= "Zamora" if codi_regio >= 49000 & codi_regio <= 49999
replace provincia= "Zaragoza" if codi_regio >= 50000 & codi_regio <= 50999
replace provincia= "Ceuta" if codi_regio >= 51000 & codi_regio <= 51999
replace provincia= "Melilla" if codi_regio >= 52000 & codi_regio <= 52999 

gen com_autonoma = ""

replace comunidad_autonoma = "Cataluña" if provincia == "Barcelona" | provincia == "Girona" | provincia == "Lleida" | provincia == "Tarragona"
replace comunidad_autonoma = "Aragón" if provincia == "Huesca" | provincia == "Teruel" | provincia == "Zaragoza" 
replace comunidad_autonoma = "CyL" if provincia == "Salamanca" | provincia == "Ávila" | provincia == "Burgos" | provincia == "Leon" | provincia == "Palencia" | provincia == "Valladolid" | provincia == "Soria" | provincia == "Segovia" | provincia == "Zamora" 
replace comunidad_autonoma = "CyM" if provincia == "Albacete" | provincia == "Ciudad Real"| provincia == "Cuenca"| provincia == "Guadalajara" |  provincia == "Toledo" 
replace comunidad_autonoma = "Cantabria" if provincia == "Cantabria" 
replace comunidad_autonoma = "Canarias" if provincia == "Tenerife" | provincia == "Las Palmas"
replace comunidad_autonoma = "País Valencià" if provincia == "Valencia" | provincia == "Alicante" | provincia == "Castelló" 
replace comunidad_autonoma = "Euskadi" if provincia == "Bizkaia" | provincia == "Gipuzkoa" | provincia == "Álava" 
replace comunidad_autonoma = "Navarra" if provincia == "Navarra" 
replace comunidad_autonoma = "Murcia" if provincia == "Murcia" 
replace comunidad_autonoma = "Illes Balears" if provincia == "Illes Balears" 
replace comunidad_autonoma = "Extremadura" if provincia == "Badajoz" | provincia == "Caceres"
replace comunidad_autonoma = "Galicia" if provincia == "A Coruña" | provincia == "Lugo" | provincia == "Ourense" | provincia == "Pontevedra"
replace comunidad_autonoma = "Asturias" if provincia == "Asturias" 
replace comunidad_autonoma = "Madrid" if provincia == "Madrid" 
replace comunidad_autonoma = "Andalucia" if provincia == "Almeria" | provincia == "Cádiz" | provincia == "Cordoba" | provincia == "Granada" | provincia == "Huelva" | provincia == "Jaén" | provincia == "Málaga" | provincia == "Sevilla" 
replace comunidad_autonoma = "Ceuta" if provincia == "Ceuta"
replace comunidad_autonoma = "Melilla" if provincia == "Melilla"
replace comunidad_autonoma = "La Rioja" if provincia == "La Rioja"

save "$data\ine_euv_vivienda_poblacion.dta", replace
