
clear 

//MERGE POPULATION AND INE-EUV VACANCY DATASET
//* Prepare population dataset having premerged manually 2011 and 2021 data and erasing nationality-specific data
import excel "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\relación vivenda 2011 y 2021_merge_sensenacionalitat.xlsx", sheet("tabla-55248") firstrow
/*expand 2, gen(new_id)
replace año = 2011 if new_id == 1
drop new_id
*/
gen idpoblacio = _n
save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivienda_2011_2021_nonacionalitat.dta", replace

clear
//* Prepare 2011-2019 population dataset having premerged manually every year
import excel "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\poblacion_2011_2019.xlsx", sheet("Hoja1") firstrow
gen idpoblacio = _n
gen codi_regio = CPRO + CMUN
destring codi_regio, replace
drop if año==.
save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\poblacion_2011_2019.dta", replace


clear
//*Prepare construction dataset to merge with INE and EUV vacancy datasets
import excel "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivienda_año_construccion.xlsx", sheet("Hoja1") firstrow
/*gen año = 2021
expand 2, gen(new_id)
replace año = 2011 if new_id == 1
drop new_id
*/
gen idvivenda = _n
save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivenda_año_construccion.dta", replace

clear
//* Prepare vacancy dataset having premerged INE and EUV datasets (Capitals and "Porcentaje de viviendas familiares no principales por municipios de 10.001 a 100.000 habitantes. 2011-2021", provided by the Departamento de Planificación Territorial, Vivienda y Transportes of the Basque Country)
import excel "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\ine_euv_merge.xlsx", sheet("Hoja1") firstrow
gen idvivenda1 = _n
replace nom_regio = subinstr(nom_regio, " *", "", .)
save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\ine_euv_merge.dta", replace

reclink codi_regio nom_regio año using "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivenda_año_construccion.dta", idmaster(idvivenda1) idusing(idvivenda) minscore(0.95) required (año) gen(vivenda_score)
////Non-merged observations are the ones which correspond to years others than 2011 or 2021 or provinces
drop _merge

//*merge with 2011 to 2021 population data from INE, which includes mobility variables with a 90% merging statistical score
reclink codi_regio nom_regio año using "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivienda_2011_2021_nonacionalitat.dta", idmaster(idvivenda1) idusing(idpoblacio) minscore(0.9) gen(poblacio_score)
////Non-merged observations are the ones which correspond to years others than 2011 or 2021 or provinces
drop _merge
drop idpoblacio

//save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\vivienda_dropaftemerge.dta", replace

//use "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\vivienda_dropaftemerge.dta"
//*merge with 2011 to 2019 population data from INE with a 90% merging statistical score
merge m:1 codi_regio año using "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\poblacion_2011_2019.dta", update

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

save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\3. Clean data\ine_euv_vivienda_poblacion", replace
