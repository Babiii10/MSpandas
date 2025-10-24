# Limites et scalabilité de la correction CE-time dans MSPANDA

## Questions répondues

### 1. Existe-t-il une limite au nombre de runs réajustés ?
**Réponse : NON, aucune limite hardcodée dans le code.**

### 2. L'application peut-elle supporter plusieurs centaines d'ajustements ?
**Réponse : OUI, techniquement possible, mais avec des contraintes de performance.**

### 3. ParallelExtensionsExtras.dll intervient-il dans la correction CE-time ?
**Réponse : NON, cette DLL est utilisée uniquement par MSConvert, pas pour la correction CE-time.**

---

## Architecture de la correction CE-time

### Étape 1 : Correction XCMS (Obiwarp)

**Code** : `server/newReferenceMap.server/CorrectionTime.Server_NewRefMap.R` (lignes 3520-3533)

```r
RvarsCorrectionTime$dataObiwarp_Aligned <-
  alignement_Obiwrap(
    xdata = rawData_mzML_XCMSnExp,
    binSize = input$binSizeObiwrap,
    msLevel = input$MSlevelObiwrap,
    subset = which(pheno_Data$Filenames %in% req(input$subsetObiwrap)),
    subsetAdjust = input$subsetAdjustObiwarp,
    centerSample = which(pheno_Data$Filenames == ref_sample_sampleName)
  )
```

**Fonctionnement** :
- Utilise le package R `xcms`
- Algorithme Obiwarp (Optimal Binned Warping)
- **Traitement séquentiel** échantillon par échantillon
- Aligne chaque échantillon par rapport à l'échantillon de référence
- **PAS de parallélisme** dans cette étape

**Complexité** :
- Temps : O(n × m) où n = nombre d'échantillons, m = nombre de scans
- Mémoire : O(n × s) où s = taille d'un scan

### Étape 2 : Correction Kernel Density

**Code** : `server/newReferenceMap.server/CorrectionTime.Server_NewRefMap.R` (lignes 4784-4807)

```r
# Fit kernel density model
RvarsCorrectionTime$modelKernelDensity <-
  npreg(
    rt.1 ~ rt.2,
    bws = req(input$"bandwidth_Model"),
    bwtype = "fixed",
    regtype = "ll",
    ckertype = input$KernelType,  # gaussian, truncated gaussian, etc.
    gradients = TRUE,
    data = dataDensity
  )

# Apply correction to selected sample
RvarsCorrectionTime$peakListAligned_KernelDensity[sample == selected_sample,]$rt <-
  predict(modelKernelDensity, newdata = data.frame(rt.2 = rt_values))
```

**Fonctionnement** :
- Utilise le package R `np` (nonparametric regression)
- **Correction échantillon par échantillon** (un à la fois)
- L'utilisateur ajuste interactivement les paramètres
- **PAS de parallélisme** - processus itératif manuel
- Chaque échantillon doit être validé visuellement

**Complexité** :
- Temps : O(p²) pour le fit + O(p) pour la prédiction, où p = nombre de pics
- Mémoire : O(p) par échantillon

### Étape 3 : Groupement (APRÈS correction)

**Code** : `server/newReferenceMap.server/GenerateMapRef.Server_NewRefMap.R` (lignes 118-137)

```r
# Utilise BiocParallel pour le parallélisme
workers <- ceiling((detectCores()) - 1)
param <- SnowParam(workers = workers, type = "SOCK")

# Premier groupement en parallèle
res1 <- bplapply(
  Massif_List_ToGroup,
  Grouping.Massif_NewRefMap,
  mz.tolerance = 0.15,
  rt.tolerance = 30,
  BPPARAM = param  # <-- Parallélisme ICI
)

# Deuxième groupement en parallèle
res2 <- bplapply(
  res1,
  Grouping.Massif_NewRefMap_Second,
  mz.tolerance = 0.09,
  rt.tolerance = 180,
  BPPARAM = param  # <-- Parallélisme ICI
)
```

**Fonctionnement** :
- Utilise `BiocParallel` (package R)
- **Parallélisme R natif**, pas de DLL externe
- Distribue le groupement sur plusieurs cœurs CPU
- Se produit APRÈS la correction, pas pendant

---

## Limites pratiques

### Pas de limite hardcodée

**Aucune limite dans le code** :
```r
# Pas de vérification du type:
if (nrow(samples) > MAX_SAMPLES) { stop("Too many samples") }

# Le code traite N'IMPORTE QUEL nombre d'échantillons
for (i in 1:nrow(pheno_Data_mzML)) {
  # Traitement de l'échantillon i
}
```

### Limites imposées par les ressources

#### 1. Mémoire RAM

**Étape XCMS** :
```
Mémoire requise = N_échantillons × Taille_fichier_mzML

Exemple :
- 10 échantillons × 200 MB = 2 GB RAM
- 50 échantillons × 200 MB = 10 GB RAM
- 100 échantillons × 200 MB = 20 GB RAM
- 500 échantillons × 200 MB = 100 GB RAM ❌ Problématique
```

**XCMS charge tous les fichiers en mémoire** :
```r
rawData_mzML_OnDiskMSnExp <- readMSData(
  RvarsCorrectionTime$rawData_mzML_path,  # TOUS les fichiers
  pdata = new("NAnnotatedDataFrame", pheno_Data_mzML),
  mode = "onDisk"  # Mode "onDisk" mais toujours consommateur
)
```

**Limite pratique RAM** :
| RAM disponible | Nombre max d'échantillons (estimation) |
|----------------|----------------------------------------|
| 8 GB           | ~10-20 échantillons                    |
| 16 GB          | ~30-50 échantillons                    |
| 32 GB          | ~80-120 échantillons                   |
| 64 GB          | ~200-300 échantillons                  |
| 128 GB         | ~500-600 échantillons                  |

#### 2. Temps de calcul

**XCMS Obiwarp** :
- Temps par échantillon : ~30 secondes à 5 minutes (selon la taille)
- **Séquentiel**, pas de parallélisme

```
Temps total XCMS = N_échantillons × Temps_par_échantillon

Exemple avec 2 min/échantillon :
- 10 échantillons : 20 minutes
- 50 échantillons : 100 minutes (~1h40)
- 100 échantillons : 200 minutes (~3h20)
- 500 échantillons : 1000 minutes (~16h40) ⏰
```

**Kernel Density** :
- Temps par échantillon : ~10-60 secondes
- **MAIS** : processus MANUEL, un échantillon à la fois
- L'utilisateur doit valider visuellement chaque ajustement

```
Temps total Kernel Density = N_échantillons × (Temps_fit + Temps_validation_visuelle)

Exemple avec 1 min/échantillon (fit + validation) :
- 10 échantillons : 10 minutes
- 50 échantillons : 50 minutes
- 100 échantillons : 100 minutes (~1h40)
- 500 échantillons : 500 minutes (~8h20) ⏰⏰⏰
```

**Temps total pour 500 échantillons** :
```
XCMS : ~16h
Kernel Density : ~8h (si manuel)
TOTAL : ~24h de traitement
```

#### 3. Interface utilisateur

**Kernel Density** = Processus **MANUEL** :
- L'utilisateur doit :
  1. Sélectionner un échantillon
  2. Ajuster les paramètres (bandwidth, min density, intensity filter)
  3. Cliquer sur "Adjust CE-time"
  4. Valider visuellement les graphiques
  5. Répéter pour CHAQUE échantillon

**Limite pratique humaine** : ~50-100 échantillons maximum avant fatigue/erreurs

---

## ParallelExtensionsExtras.dll : NON utilisée pour CE-time

### Où est-elle utilisée ?

**UNIQUEMENT dans MSConvert** (avant la correction CE-time) :

```
[Fichiers RAW]
    ↓
MSConvert.exe (+ ParallelExtensionsExtras.dll)
    ↓ (Parallélisme .NET)
[Fichiers mzML]
    ↓
XCMS Obiwarp (R séquentiel, PAS de ParallelExtensionsExtras.dll)
    ↓
Kernel Density (R séquentiel, PAS de ParallelExtensionsExtras.dll)
    ↓
BiocParallel (R parallèle natif, PAS de ParallelExtensionsExtras.dll)
    ↓
[Données corrigées]
```

### Pourquoi pas de parallélisme dans CE-time ?

1. **XCMS Obiwarp** :
   - Algorithme séquentiel par nature
   - Chaque échantillon dépend de l'alignement précédent
   - Difficile à paralléliser sans affecter la qualité

2. **Kernel Density** :
   - Processus **interactif** avec validation visuelle
   - Un échantillon à la fois par design
   - L'utilisateur contrôle le processus

3. **Package R `xcms`** :
   - Pas conçu pour le parallélisme massif
   - BiocParallel disponible mais pas utilisé dans MSPANDA pour cette étape

---

## Tests de scalabilité

### Testé par les développeurs

D'après les chemins dans le code :
```r
# Exemple de test visible dans le code
"C:/Users/mouhamed.seye.ADN/Desktop/Test"
```

**Estimation** : Tests probablement effectués avec 5-15 échantillons

### Recommandations par taille de dataset

| Nombre d'échantillons | Faisabilité | RAM min | Temps estimé | Recommandation |
|-----------------------|-------------|---------|--------------|----------------|
| 1-20                  | ✅ Facile   | 8 GB    | <1h          | Optimal        |
| 20-50                 | ✅ OK       | 16 GB   | 1-3h         | Faisable       |
| 50-100                | ⚠️ Difficile | 32 GB   | 3-6h         | Fatigant (kernel density manuel) |
| 100-200               | ⚠️ Très difficile | 64 GB   | 6-12h        | Diviser en batches |
| 200-500               | ❌ Peu pratique | 128 GB  | 12-24h       | Automatisation nécessaire |
| >500                  | ❌ Non recommandé | >128 GB | >24h         | Repenser le workflow |

---

## Solutions pour traiter plusieurs centaines d'échantillons

### Option 1 : Traitement par batches

```r
# Diviser en groupes de 30-50 échantillons
batch1 <- samples[1:50]
batch2 <- samples[51:100]
batch3 <- samples[101:150]
# etc.

# Traiter chaque batch séparément
# Puis fusionner les résultats
```

**Avantages** :
- Réduit l'utilisation mémoire
- Permet de reprendre en cas d'erreur
- Plus gérable humainement pour kernel density

**Inconvénients** :
- Nécessite de fusionner les résultats
- Peut introduire des biais entre batches

### Option 2 : Automatiser Kernel Density

**Modification suggérée** : Appliquer les mêmes paramètres à tous les échantillons

```r
# Au lieu de correction manuelle échantillon par échantillon
for (sample_name in unique(peakListAligned$sample)) {
  # Fit model
  model <- npreg(rt.1 ~ rt.2, bws = bandwidth, data = data_sample)

  # Apply correction
  peakListAligned_KernelDensity[sample == sample_name,]$rt <-
    predict(model, newdata = rt_data)
}
```

**Avantages** :
- Automatique, pas d'intervention manuelle
- Peut traiter 500+ échantillons

**Inconvénients** :
- Perd la validation visuelle
- Paramètres identiques pour tous (peut ne pas être optimal)

### Option 3 : Optimiser la mémoire

**Mode streaming** (modification avancée) :
```r
# Au lieu de charger TOUS les fichiers
readMSData(all_files, mode = "onDisk")

# Traiter un par un
for (file in mzML_files) {
  data <- readMSData(file, mode = "onDisk")
  aligned_data <- adjustRtime(data, ...)
  save(aligned_data, file = output_file)
  rm(data)  # Libérer la mémoire
  gc()      # Garbage collection
}
```

### Option 4 : Utiliser XCMS parallèle (modification du code)

**Activer BiocParallel pour XCMS** :
```r
# Ajouter BPPARAM à adjustRtime
library(BiocParallel)
param <- SnowParam(workers = 4)

rawData_aligned <- adjustRtime(
  rawData_mzML_XCMSnExp,
  param = ObiwarpParam(...),
  BPPARAM = param  # <-- Ajouter ceci
)
```

**Gain estimé** : 2-4x plus rapide avec 4-8 cœurs

---

## Monitoring pour grands datasets

### Ajouter des logs de progression

```r
# Au début de la correction XCMS
cat(sprintf("Processing %d samples\n", nrow(pheno_Data_mzML)))
cat(sprintf("Estimated RAM usage: %.1f GB\n",
            nrow(pheno_Data_mzML) * 0.2))
cat(sprintf("Estimated time: %.1f hours\n",
            nrow(pheno_Data_mzML) * 2 / 60))

# Pendant le traitement
for (i in 1:n_samples) {
  cat(sprintf("[%d/%d] Processing sample %s\n",
              i, n_samples, sample_name))
  # ... traitement ...
}
```

### Checkpoints pour reprendre en cas d'erreur

```r
# Sauvegarder après chaque échantillon
saveRDS(partial_results,
        file = sprintf("checkpoint_sample_%d.rds", i))

# En cas d'interruption, reprendre
if (file.exists("checkpoint_sample_50.rds")) {
  partial_results <- readRDS("checkpoint_sample_50.rds")
  start_from <- 51
}
```

---

## Conclusion

### Réponses finales

#### 1. Limite du nombre de runs ?
**NON**, aucune limite hardcodée dans le code. La limite est imposée par :
- RAM disponible
- Temps de calcul acceptable
- Capacité humaine de validation (pour kernel density)

#### 2. Supporter plusieurs centaines d'ajustements ?
**OUI**, techniquement possible MAIS :
- Nécessite beaucoup de RAM (64-128 GB pour 200-500 échantillons)
- Temps de traitement très long (12-24h+)
- Kernel density manuel devient impraticable au-delà de ~100 échantillons

**Recommandation** :
- **Optimal** : 20-50 échantillons
- **Maximum pratique** : 100 échantillons
- **Au-delà** : Diviser en batches ou automatiser kernel density

#### 3. ParallelExtensionsExtras.dll intervient-elle ?
**NON**, cette DLL est utilisée uniquement par MSConvert (conversion RAW → mzML).

La correction CE-time utilise :
- **XCMS** : R séquentiel (pas de parallélisme)
- **Kernel Density** : R séquentiel manuel
- **BiocParallel** : Uniquement APRÈS correction (groupement)

### Améliorations suggérées pour scalabilité

1. **Court terme** :
   - Ajouter logs de progression
   - Implémenter checkpoints
   - Documenter les limites mémoire

2. **Moyen terme** :
   - Automatiser kernel density avec paramètres par défaut
   - Traitement par batches intégré
   - Mode "streaming" pour réduire l'empreinte mémoire

3. **Long terme** :
   - Activer BiocParallel pour XCMS
   - Implémenter correction GPU (si disponible)
   - Interface pour traitement distribué (cluster)
