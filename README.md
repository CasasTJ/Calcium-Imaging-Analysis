# Calcium Imaging Analysis
MATLAB & R toolkit for calcium imaging analysis. Includes fluorescence trace detrending (Savitzky-Golay + Butterworth), automated astrocytic/non-astrocytic event detection (AUC, amplitude, rise/decay), and negative binomial GLM validation via DHARMa diagnostics.
# How to cite
Please acknowledge these scripts if you use them in your publication. Cite the DOI from Zenodo https://doi.org/10.5281/zenodo.19188776
## Trace_Detrend_v05.m 
MATLAB script for fluorescence trace correction. Removes trends using Savitzky-Golay smoothing, high-pass Butterworth filtering & local baseline estimation. Outputs per-ROI figures (raw vs. corrected trace) and a xlsx file with normalized data.
### How to use
1.	Extract data fluorescent data from the software of choice (like Calsee). 
2.	Copy the fluorescent traces data and paste them in a new xlsx file with the following format: ROI 1: name the columns with the name of the ROIs, see example below.
   
<img width="886" height="153" alt="image" src="https://github.com/user-attachments/assets/e0415b52-82d6-42c2-a5b0-3afe203ba2bb" />

3.	Run the script. A GUI will let you choose the input file, and the parameters that you want to select for the normalization/detrend of your data. After selecting your input file and choosing the parameters, remember to press Load & Preview. Now you can preview the data before running the code to check if the format of your table is correct. See below:

<img width="657" height="547" alt="image" src="https://github.com/user-attachments/assets/5b02f359-091a-4b81-9d22-00d46b6c48be" />

4.	After running the script, the corrected data will be saved with the name you chose in the place you selected, and it will create a figure per ROI where you will be able to see the original trace (Original), the filtered trace and the corrected trace (Fcorr). The data from the Fcorr trace (yellow) will be the one exported to the new file. See below:

   <img width="775" height="484" alt="image" src="https://github.com/user-attachments/assets/192bf2f1-937f-4548-9f20-f3126caaf7f2" />

### Notes: 
- Make sure your input table follows the format described previously.
- The script won´t work properly if there´s more than one sheet per .xlsx input file.
- You can save the images in MATLAB, but the script won´t automatically save them for you. 

## CaEvent_Detector_.m
MATLAB script for detecting and characterizing calcium events from normalized fluorescence traces. Extracts AUC, amplitude, duration, rise/decay times, classifies astrocytic vs. non-astrocytic events, and generates a binary bin raster table. Exports to XLSX.
### How to use
1.	After normalizing the data, open that .xlsx file and insert one column, where each row represents one frame (Important). See example below:

<img width="886" height="146" alt="image" src="https://github.com/user-attachments/assets/4c36f3ee-c1fc-46f5-b2be-35edc1babd5a" />

2.	Run the script. A GUI will let you choose the input file, and the parameters that you want to select for the detection of events (baseline percentile, threshold multiplier, and minimum amplitude filter). After selecting your input file and choosing the parameters, remember to press Load & Preview. Now you can preview the data before running the code to check if the format of your table is correct. Important: if you do not see ROI 1 in the Data Preview window, you forgot to insert the first column. See below:

<img width="724" height="647" alt="image" src="https://github.com/user-attachments/assets/061fce91-fb2d-469c-af6e-3f8aa586a5ab" />

## Negative_binomial.R
R tool for count data modeling. Compares Poisson vs. negative binomial GLMs using AIC, validates fit via DHARMa residual diagnostics (simulated vs. observed), and exports pairwise factor comparisons to XLSX. Outputs model summary, AIC table & diagnostic plots.
### How to use
1.	In order to run the code and perform a negative binomial test, your input table must have the following format (see below). When using this format, you are establishing the following: ROIs are nested within slices, and every ROI and slice goes under the same treatment. This test does not treat each ROI as an independent variable. Example of the table input needed for this code:

<img width="297" height="504" alt="image" src="https://github.com/user-attachments/assets/8c33e631-611e-4895-b162-0675ac270223" />

2.	Run the script. Output of the code: Model Summary, AIC Comparison, DHARMa diagnostics, pairwise comparisons (plot), and pairwise comparisons (table). These files will be automatically saved to your working directory.

- Model Summary: it contains: 
Estimate value: the effect of each treatment on log relative to the treatment you want to compare you treatment of interest to. 
Std. Error: uncertainty around the estimate.
Z value: estimate divided by SE, the test statistic. 
P-value: whether each treatment differs significantly from the treatment you are comparing to.
- AIC (Akaike Information Criterion) comparison: compares which model fits the best (Poisson Model or Negative Binomial). Lower AIC = better fit.
- DHARMa diagnostics: checks whether the model is a good fit for the data by running simulations. It simulates thousands of datasets from the fitted model and compares them to your real data, if the model fits well then the simulated data should look like the simulated data. p-value > 0.05 = no dispersion problem. If p < 0.05 = dispersion problem, the model can´t be used. 
- Post-hoc Pairwise comparisons (plot and table)

***These scripts have been tested with our data only. Feel free to e-mail me (tomas.casas@achucarro.org) in case you you have any suggestions or encounter any bugs.***
