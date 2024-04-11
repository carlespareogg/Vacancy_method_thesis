
clear 

//MERGE POPULATION AND INE-EUV VACANCY DATASET
//* Prepare population dataset having premerged manually 2011 and 2021 data and erasing nationality-specific data
import excel "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\relación vivenda 2011 y 2021_merge_sensenacionalitat.xlsx", sheet("tabla-55248") firstrow
expand 2, gen(new_id)
replace año = 2011 if new_id == 1
drop new_id
gen idpoblacio = _n
save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivienda_2011_2021_nonacionalitat.dta", replace

clear
//*Prepare construction dataset to merge with INE and EUV vacancy datasets
import excel "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivienda_año_construccion.xlsx", sheet("Hoja1") firstrow
gen año = 2021
expand 2, gen(new_id)
replace año = 2011 if new_id == 1
drop new_id
gen idvivenda = _n
save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivenda_año_construccion.dta", replace

clear
//* Prepare vacancy dataset having premerged INE and EUV datasets
import excel "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\ine_euv_merge.xlsx", sheet("Hoja1") firstrow
gen idvivenda1 = _n
save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\ine_euv_merge.dta", replace

reclink codi_regio nom_regio año using "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivenda_año_construccion.dta", idmaster(idvivenda1) idusing(idvivenda) minscore(0.95) required (año) gen(vivenda_score)
drop _merge
//save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\ine_euv_vivienda_poblacion.dta", replace
//* Fuzzymerge

reclink codi_regio nom_regio año using "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\2. Intermediate datasets\INE\vivienda_2011_2021_nonacionalitat.dta", idmaster(idvivenda1) idusing(idpoblacio) required(año) minscore(0.9) gen(poblacio_score)

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
save "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\1. Cleaning and merging\3. Clean data\ine_euv_vivienda_poblacion", replace
