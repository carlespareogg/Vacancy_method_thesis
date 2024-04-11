
///////////////////////////////////////////////////////////////////////////////
///////* MASTER DO FILE TO REPLICATE THESIS *//////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


Clean 
set max off

//* Set Current Directory path
cd "C:\Users\hp\OneDrive\UPF\6. Sisè\TFG Economia\Habitatge\GitHub\TFG-Eco\"


//*Macros
global rawdata "1. Cleaning and merging\1. Raw data"
global intdata "1. Cleaning and merging\2. Intermediate datasets" 
global data "1. Cleaning and merging\3. Clean data"


//* Clean data
do "1. Cleaning and merging\Cleaning and merging.do"


