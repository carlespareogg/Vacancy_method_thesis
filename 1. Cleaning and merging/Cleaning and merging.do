
cd "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\Bases de dades" 


//MERGE POPULATION AND INE VACANCY DATASET
//* Prepare population dataset 
import excel "INE\relación vivenda 2011 y 2021_merge_sensenacionalitat.xlsx", sheet("tabla-55248") firstrow
gen idpoblacio = _n
expand 2, gen(new_id)
replace año = 2011 if new_id == 1
drop new_id
save "INE\vivienda_2011_2021_nonacionalitat.dta", replace

//* Prepare vacancy dataset
import excel "ine_euv_merge.xlsx", sheet("Hoja1") firstrow
gen idvivenda = _n
save "ine_euv_merge.dta", replace

//* Fuzzymerge

reclink codi_regio nom_regio año using "INE\vivienda_2011_2021_nonacionalitat.dta", idmaster(idvivenda) idusing(idpoblacio) required(año) minscore(0.9) gen(poblacio_score)

//////////////////////7IN CONSTRUCTION
//* Clean
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

save "INE\ine_vivienda_poblacion", replace
