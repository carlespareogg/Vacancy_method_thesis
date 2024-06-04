
///////////////////////////////////////////////////////////////////////////////
///////* MASTER DO FILE TO REPLICATE THESIS *//////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


clear 
//set max off

//* Set Current Directory path
cd "C:/Users/hp/OneDrive/UPF/6. Sisè/TFG Economia/Habitatge/GitHub/TFG-Eco"


//*Macros. To run the file, change path to desired directory
global path "C:/Users/hp/OneDrive/UPF/6. Sisè/TFG Economia/Habitatge/GitHub/TFG-Eco"
global interdata "$path/1. Cleaning and merging/2. Intermediate datasets"
global ineinput "$path/1. Cleaning and merging/2. Intermediate datasets/INE/input"
global ineoutput "$path/1. Cleaning and merging/2. Intermediate datasets/INE/output" 
global interdata "$path/1. Cleaning and merging/2. Intermediate datasets"
global dataoutput "$path/1. Cleaning and merging/3. Clean data"
global data "$path/1. Cleaning and merging/3. Clean data"
global figures "$path/2. Analysis/Figures"
global tables "$path/2. Analysis/Tables"


//*Installing packages
ssc install schemepack, replace
ssc install colrspace, replace
ssc install palettes, replace

//* Clean data
do "$path/1. Cleaning and merging/Cleaning and merging.do"
do "$path/2. Analysis/Graphs and tables.do"


