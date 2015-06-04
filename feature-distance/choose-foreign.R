# /usr/bin/env Rscript

## ## ## ## ## ## ##
## general setup  ##
## ## ## ## ## ## ##
## set global options (to be restored at end)
saf <- getOption("stringsAsFactors")
options(stringsAsFactors=FALSE)

## load data
in.file  <- "phoible-phoneme-level.RData"
load(in.file)  # provides final.data

## these are the languages that (1) are in PHOIBLE, (2) have JIPA sound files,
## and (3) are listed as having volunteers in Preethi's spreadsheet
lxs <- c("amh", "yue", "nld", "deu", "hin", "hun", "jpn", "kor", "cmn", "por",
         "spa", "tur", "vie")
lxdata <- final.data[final.data$LanguageCode %in% c("eng", lxs),]
## keep only the good data sources (in case we want allophones & tonemes)
lxdata <- lxdata[lxdata$Source %in% c("ph", "gm", "spa"),]
## get rid of duplicate CMN inventory (separate entries in SPA and PHOIBLE)
exclude_rows <- rownames(lxdata[lxdata$LanguageCode %in% "cmn" &
                                lxdata$Source %in% "spa",])
lxdata <- lxdata[!rownames(lxdata) %in% exclude_rows,]


## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## assess distance from English based on features  ##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
cols <- colnames(final.data)
feat_cols <- cols[match("tone", cols):match("click", cols)]
split_by_lx <- split(lxdata, lxdata$LanguageCode)
en <- split_by_lx[["eng"]]  # english
en_feat_mat <- as.data.frame(t(en[feat_cols]))
colnames(en_feat_mat) <- en$Phoneme

## list of feature distance matrices (rows=foreign; cols=English phonemes)
feat_dist_mat_by_lx <- lapply(split_by_lx, function(lx) {
    lx_feat_mat <- as.data.frame(t(lx[feat_cols]))
    colnames(lx_feat_mat) <- lx$Phoneme
    feat_dist_mat <- sapply(lx_feat_mat, function(lx_ph) {
        feat_dist <- sapply(en_feat_mat, function(en_ph) {
            ## ignore tonemes
            ifelse(lx_ph["tone"] %in% "+", NA, sum(lx_ph != en_ph))
        })
    })
    as.data.frame(t(feat_dist_mat))
})

## fill rows with NA except for the lowest distance value
feat_dist_mat_lowest <- lapply(feat_dist_mat_by_lx, function(lx) {
    for(i in 0:length(feat_cols)) {
        row_has_match <- apply(lx, 1, function(ph) min(ph, na.rm=TRUE) == i)
        if(any(row_has_match)) {
            lx[row_has_match,][lx[row_has_match,] > i] <- NA
        }
    }
    lx
})

## for foreign phonemes with more than one best match in English, divide by
## number of matches (so as not to exaggerate the one-to-many count)
feat_dist_mat_normed <- lapply(feat_dist_mat_lowest, function(lx) {
    row_multiplier <- 1 / apply(lx, 1, function(ph) sum(!is.na(ph)))
    lx[!is.na(lx)] <- 1
    lx <- lx * row_multiplier
})

## sum across rows for each English phoneme, to get a number for "many" in
## "one-to-many". rows=foreign language codes, cols=English phonemes
feat_dist_mat_summed <- do.call(rbind, lapply(feat_dist_mat_normed, function(lx) {
    x <- colSums(lx, na.rm=TRUE)
}))

## mean value of "one-to-many" for each language
result <- sort(apply(feat_dist_mat_summed, 1, mean))
result <- result[-which(names(result) %in% "eng")]
cat("\nmean one-to-many value by language\n")
print(result)

## mean value of "one-to-many" for each language, excluding zero values
feat_dist_mat_nozero <- feat_dist_mat_summed
feat_dist_mat_nozero[feat_dist_mat_nozero == 0] <- NA
result <- sort(apply(feat_dist_mat_nozero, 1, mean, na.rm=TRUE))
result <- result[-which(names(result) %in% "eng")]
cat("\nmean one-to-many value by language (excluding zeros)\n")
print(round(result, 3))
cat("\n")


## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## assess distance from English simple setdiff on phoneme glyphs  ##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# split_pho <- lapply(split_by_lx, function(i) i$Phoneme)
# set_dists <- sapply(split_pho, function(i) sapply(split_pho, function(j) length(setdiff(i, j))))
#
# ## fewest phonemes not in English:
# few_not_in_eng <- sort(set_dists["eng",])[2:7]  # element 1 is english itself, setdiff 0
# ## fewest English phonemes not in Lx:
# few_eng_not_in_lx <- sort(set_dists[,"eng"])[2:7]
# ## most phonemes not in English:
# most_not_in_eng <- sort(set_dists["eng",])[(ncol(set_dists)-5):ncol(set_dists)]
# ## most English phonemes not in Lx:
# most_eng_not_in_lx <- sort(set_dists[,"eng"])[(ncol(set_dists)-5):ncol(set_dists)]
#
# aa <- merge(cbind(few_not_in_eng, names(few_not_in_eng)),
#             cbind(few_eng_not_in_lx, names(few_eng_not_in_lx)), all=TRUE)
# bb <- merge(cbind(most_not_in_eng, names(most_not_in_eng)),
#             cbind(most_eng_not_in_lx, names(most_eng_not_in_lx)), all=TRUE)
# results_by_phoneme <- merge(aa, bb, all=TRUE)
# row.names(results_by_phoneme) <- results_by_phoneme$V2
# results_by_phoneme$V2 <- NULL
# write.table(results_by_phoneme[with(results_by_phoneme,
#                                     order(few_not_in_eng, few_eng_not_in_lx,
#                                           most_not_in_eng, most_eng_not_in_lx)),],
#             "dist-from-eng-by-phoneme.tsv", row.names=TRUE, col.names=NA, na="-")
# rm(aa, bb)

## reset global options
options(stringsAsFactors=saf)
