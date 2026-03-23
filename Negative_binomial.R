# ============================================================
#   CaEvents_NegBinom_GLM
#   Negative binomial GLMM for calcium event count data
#
#   Description:
#   This script fits Poisson and negative binomial GLMMs to
#   calcium event count data, compares model fit using AIC,
#   validates the negative binomial model using DHARMa residual
#   diagnostics, and performs post-hoc pairwise comparisons
#   between treatment groups using emmeans.
#
#   Output:
#   - DHARMa diagnostics plot (.png)
#   - Pairwise contrasts plot (.png)
#   - AIC comparison (.txt)
#   - Model summary (.txt)
#   - Pairwise contrasts table (.xlsx)
#
#   Requirements:
#   install.packages(c("lme4","glmmTMB","DHARMa","emmeans",
#                      "openxlsx","ggplot2","readxl"))
#
#   Author: Tomás Joaquin Casas
# ============================================================

# ============================================================
#   USER PARAMETERS — modify here, do not change code below
# ============================================================

# --- Input file ---
input_file        <- "ZT 0-2 nested analysis test.xlsx"  # Path to your Excel file

# --- Experimental design ---
reference_level   <- "vehicle"       # Reference treatment group
random_effects    <- "slice/ROI"     # Random effects structure (e.g. "slice/ROI" or "slice")

# --- Statistical options ---
correction_method <- "holm"          # P-value correction: "holm", "bonferroni", "fdr", "none"

# --- Output file names ---
out_aic           <- "AIC_comparison.txt"
out_summary       <- "model_summary.txt"
out_dharma_plot   <- "dharma_diagnostics.png"
out_contrasts_plot <- "pairwise_contrasts.png"
out_contrasts_xlsx <- "pairwise_contrasts.xlsx"

# ============================================================
#   1. LOAD LIBRARIES
# ============================================================
library(lme4)
library(glmmTMB)
library(DHARMa)
library(emmeans)
library(openxlsx)
library(ggplot2)
library(readxl)

# ============================================================
#   2. LOAD AND PREPARE DATA
# ============================================================
df <- read_excel(input_file)

# Ensure grouping variables are factors
df$slice     <- factor(df$slice)
df$ROI       <- factor(df$ROI)
df$Treatment <- factor(df$Treatment)

# Set reference level for treatment
df$Treatment <- relevel(df$Treatment, ref = reference_level)

cat("Data loaded successfully.\n")
cat(sprintf("  Rows: %d\n", nrow(df)))
cat(sprintf("  Treatment levels: %s\n", paste(levels(df$Treatment), collapse = ", ")))

# ============================================================
#   3. FIT MODELS
# ============================================================

# Build random effects formula dynamically from parameter
re_formula <- as.formula(
  paste("Events ~ Treatment + (1 |", random_effects, ")")
)

cat("\nFitting Poisson model...\n")
m_pois <- glmer(
  re_formula,
  data   = df,
  family = poisson
)

cat("Fitting Negative Binomial model...\n")
m_nb <- glmmTMB(
  re_formula,
  data   = df,
  family = nbinom2
)

# ============================================================
#   4. AIC COMPARISON (Poisson vs Negative Binomial)
# ============================================================
aic_table <- AIC(m_pois, m_nb)
print(aic_table)
capture.output(aic_table, file = out_aic)
cat(sprintf("AIC comparison saved to: %s\n", out_aic))

# ============================================================
#   5. DHARMA DIAGNOSTICS
# ============================================================
cat("\nRunning DHARMa diagnostics...\n")
sim_output <- simulateResiduals(fittedModel = m_nb)

png(out_dharma_plot, width = 800, height = 600)
plot(sim_output)
dev.off()
cat(sprintf("DHARMa diagnostics plot saved to: %s\n", out_dharma_plot))

testDispersion(sim_output)

# ============================================================
#   6. MODEL SUMMARY
# ============================================================
capture.output(summary(m_nb), file = out_summary)
cat(sprintf("Model summary saved to: %s\n", out_summary))

# ============================================================
#   7. POST-HOC PAIRWISE COMPARISONS
# ============================================================
cat(sprintf("\nRunning pairwise comparisons with %s correction...\n", correction_method))

emm    <- emmeans(m_nb, pairwise ~ Treatment,
                  type   = "response",
                  adjust = correction_method)
contr_df <- as.data.frame(emm$contrasts)
print(contr_df)

# ============================================================
#   8. PLOT PAIRWISE CONTRASTS
# ============================================================
p <- ggplot(contr_df, aes(x = contrast, y = ratio)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = ratio - SE, ymax = ratio + SE), width = 0.2) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50") +
  theme_bw() +
  labs(
    title = paste("Pairwise Treatment Contrasts —", tools::file_path_sans_ext(input_file)),
    y     = "Rate Ratio",
    x     = "Contrast"
  )

ggsave(out_contrasts_plot, plot = p, width = 6, height = 4, dpi = 300)
cat(sprintf("Contrasts plot saved to: %s\n", out_contrasts_plot))

# ============================================================
#   9. EXPORT CONTRASTS TO XLSX
# ============================================================
write.xlsx(contr_df, file = out_contrasts_xlsx, overwrite = TRUE)
cat(sprintf("Contrasts table saved to: %s\n", out_contrasts_xlsx))

cat("\nAnalysis complete.\n")