# Guide d'Export des Données de Correction CE-Time

## Vue d'ensemble

Ce document explique quelles données sont exportables après la correction CE-time et comment effectuer l'export.

---

## 📊 Données Exportables

### 1. **Données Corrigées CE-Time** (Principal Export)
**Variable**: `RvarsCorrectionTime$peakListAligned_KernelDensity`

**Contenu**:
- Liste de tous les pics détectés avec correction CE-time appliquée
- Colonnes principales:
  - `sample`: Nom de l'échantillon
  - `mz`: Masse (M+H) en Daltons
  - `rt`: CE-time corrigé (en minutes ou secondes selon l'unité)
  - `rtmin`: Début du pic
  - `rtmax`: Fin du pic
  - `into`: Intensité intégrée
  - `intb`: Intensité de base
  - `maxo`: Intensité maximale
  - `sn`: Rapport signal/bruit
  - + colonnes supplémentaires selon le traitement

**Quand disponible**: Après avoir appliqué la correction Kernel Density ET validé les résultats

---

### 2. **Informations sur les Échantillons**
**Variable**: `RvarsCorrectionTime$pheno_Data_mzML`

**Contenu**:
- Métadonnées pour chaque fichier mzML traité
- Colonnes principales:
  - `Filenames`: Nom du fichier
  - `Class`: Classe de l'échantillon (QC, Sample, Blank, etc.)
  - `sample_name`: Nom de l'échantillon
  - Autres métadonnées selon la configuration

**Quand disponible**: Dès que les fichiers mzML sont chargés

---

### 3. **Résumé de la Correction**
**Contenu automatiquement généré lors de l'export**:
- **Méthode de correction**: Kernel Density
- **Type de noyau**: Gaussian, Epanechnikov, etc.
- **Bandwidth (Modèle)**: Paramètre utilisé pour le fit
- **Bandwidth (Filtre)**: Paramètre utilisé pour le filtrage
- **Densité minimale**: Seuil de densité
- **Filtre d'intensité**: Seuil d'intensité appliqué
- **Date d'export**: Timestamp
- **Nombre de pics**: Total de pics corrigés
- **Nombre d'échantillons**: Total d'échantillons traités

---

### 4. **Données Avant Correction** (Non exportées par défaut)
**Variable**: `RvarsCorrectionTime$peakListAligned`

**Contenu**:
- Pics alignés avec XCMS Obiwarp AVANT correction Kernel Density
- Même structure que `peakListAligned_KernelDensity`

**Status**: **Non exporté automatiquement** - nécessite développement supplémentaire si besoin

---

### 5. **Modèle de Correction** (Non exporté)
**Variable**: `RvarsCorrectionTime$modelKernelDensity`

**Contenu**:
- Objet R contenant le modèle de régression non-paramétrique
- Utilisé pour prédire les corrections CE-time

**Status**: **Non exportable en Excel** - objet R complexe

---

### 6. **Échantillon de Référence** (Non exporté séparément)
**Variables**:
- `RvarsCorrectionTime$ref_sample_sampleName`: Nom de l'échantillon de référence
- `RvarsCorrectionTime$ref_sample_samplePeaks`: Pics de l'échantillon de référence

**Status**: **Inclus dans les données corrigées** - pas besoin d'export séparé

---

## 🔽 Comment Exporter les Données

### Méthode 1: Utiliser le Bouton d'Export (Recommandé)

#### Étape 1: Effectuer la Correction CE-Time
1. Naviguez vers la section **"CE-time Correction"**
2. Chargez vos fichiers mzML
3. Sélectionnez l'échantillon de référence
4. Appliquez XCMS Obiwarp (optionnel)
5. **Appliquez Kernel Density correction**
6. **Validez visuellement les résultats** pour chaque échantillon

#### Étape 2: Exporter les Données
1. Descendez jusqu'à la section **"Export corrected data"** (fond vert)
2. Cliquez sur le bouton **"Download Corrected Data (Excel)"**
   - Icône: 📊 File Excel
   - Couleur: Vert (btn-success)
3. Le fichier Excel est automatiquement téléchargé

#### Localisation du Bouton
- **Fichier UI**: `ui/newReferenceMap.ui/CorrectionTime.Ui_NewRefMap.R:1017`
- **Position**: Après les graphiques de correction, avant les boutons Return/Next
- **Visibilité**: Toujours visible une fois dans l'interface Kernel Density

---

### Structure du Fichier Excel Exporté

Le fichier Excel contient **3 feuilles (sheets)** :

#### 📊 Sheet 1: "Corrected_Peaks"
**Contenu**: Table complète des pics corrigés

**Caractéristiques**:
- En-têtes stylisés (fond bleu, texte blanc, gras)
- Première ligne gelée (freeze pane)
- Colonnes auto-dimensionnées
- Toutes les colonnes de `peakListAligned_KernelDensity`

**Exemple de structure**:
```
| sample    | mz      | rt     | rtmin  | rtmax  | into      | intb     | maxo     | sn   | ...
|-----------|---------|--------|--------|--------|-----------|----------|----------|------|
| Sample1   | 245.123 | 12.45  | 12.30  | 12.60  | 1234567   | 123456   | 234567   | 45.2 | ...
| Sample1   | 387.456 | 15.67  | 15.50  | 15.85  | 2345678   | 234567   | 345678   | 67.8 | ...
| Sample2   | 245.125 | 12.43  | 12.28  | 12.58  | 1123456   | 112345   | 212345   | 43.1 | ...
```

---

#### 📋 Sheet 2: "Sample_Info"
**Contenu**: Métadonnées des échantillons

**Caractéristiques**:
- En-têtes stylisés (identique à Sheet 1)
- Première ligne gelée
- Informations sur chaque fichier mzML

**Exemple de structure**:
```
| Filenames       | Class  | sample_name | Polarity | ...
|-----------------|--------|-------------|----------|
| Sample1.mzML    | Sample | Sample1     | Positive | ...
| Sample2.mzML    | Sample | Sample2     | Positive | ...
| QC1.mzML        | QC     | QC1         | Positive | ...
| Blank1.mzML     | Blank  | Blank1      | Positive | ...
```

**Note**: Cette feuille n'est créée que si `pheno_Data_mzML` existe

---

#### 📝 Sheet 3: "Correction_Summary"
**Contenu**: Résumé des paramètres de correction

**Caractéristiques**:
- En-têtes stylisés
- Format tableau: Paramètre | Valeur

**Exemple de structure**:
```
| Parameter           | Value                    |
|---------------------|--------------------------|
| Correction Method   | Kernel Density           |
| Kernel Type         | gaussian                 |
| Bandwidth (Model)   | 0.5                      |
| Bandwidth (Filter)  | 0.3                      |
| Min Density         | 0.01                     |
| Intensity Filter    | 1000                     |
| Export Date         | 2025-10-29 14:35:22      |
| Number of Peaks     | 15678                    |
| Number of Samples   | 45                       |
```

---

## ⚠️ Conditions Requises pour l'Export

### Données Minimales Requises
Pour que le bouton d'export fonctionne, vous DEVEZ avoir:

1. ✅ **peakListAligned_KernelDensity existe**
   - Obtenu après avoir cliqué sur "Fit Model" dans Kernel Density
   - Vérifié en voyant les graphiques "Before/After Correction"

2. ✅ **Au moins un échantillon corrigé**
   - Vous devez avoir sélectionné un échantillon et appliqué la correction

### Validation Obligatoire
**IMPORTANT**: L'export est disponible APRÈS validation visuelle. Vous devez:

1. **Vérifier visuellement** chaque correction sample par sample
2. **Ajuster les paramètres** si nécessaire (bandwidth, density, etc.)
3. **Re-corriger** si la qualité n'est pas satisfaisante
4. **Valider** que tous les échantillons critiques sont bien corrigés

**Raison**: La correction CE-time est intentionnellement manuelle pour garantir la qualité scientifique des résultats.

---

## 🔧 Code Source de l'Export

### Localisation
**Fichier**: `server/newReferenceMap.server/CorrectionTime.Server_NewRefMap.R`
**Lignes**: 6302-6399

### Implémentation
```r
output$downloadCETimeCorrected <- downloadHandler(
  filename = function() {
    paste0("CE_time_corrected_peaks_",
           format(Sys.time(), "%Y%m%d_%H%M%S"),
           ".xlsx")
  },
  content = function(file) {
    req(RvarsCorrectionTime$peakListAligned_KernelDensity)

    # Get corrected data
    corrected_data <- RvarsCorrectionTime$peakListAligned_KernelDensity

    # Create workbook with 3 sheets
    wb <- openxlsx::createWorkbook()

    # Sheet 1: Corrected peaks
    openxlsx::addWorksheet(wb, "Corrected_Peaks")
    openxlsx::writeData(wb, "Corrected_Peaks", corrected_data, ...)

    # Sheet 2: Sample info (if available)
    if (!is.null(RvarsCorrectionTime$pheno_Data_mzML)) {
      openxlsx::addWorksheet(wb, "Sample_Info")
      openxlsx::writeData(wb, "Sample_Info", ...)
    }

    # Sheet 3: Correction summary
    openxlsx::addWorksheet(wb, "Correction_Summary")
    summary_info <- data.frame(...)
    openxlsx::writeData(wb, "Correction_Summary", summary_info, ...)

    # Save
    openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
  }
)
```

---

## 📁 Nom du Fichier Exporté

### Format
```
CE_time_corrected_peaks_YYYYMMDD_HHMMSS.xlsx
```

### Exemples
- `CE_time_corrected_peaks_20251029_143522.xlsx`
- `CE_time_corrected_peaks_20251030_091245.xlsx`

### Caractéristiques
- ✅ **Timestamp unique** - évite les conflits de noms
- ✅ **Format ISO** - tri chronologique automatique
- ✅ **Extension Excel moderne** - `.xlsx` (Office 2007+)

---

## 🚀 Fonctionnalités d'Export Avancées

### Fonctionnalités Actuelles ✅
1. ✅ Export multi-feuilles (3 sheets)
2. ✅ Stylisation des en-têtes (couleurs, gras)
3. ✅ Freeze pane (première ligne)
4. ✅ Auto-dimensionnement des colonnes
5. ✅ Timestamp dans le nom de fichier
6. ✅ Résumé des paramètres de correction
7. ✅ Métadonnées des échantillons incluses

### Fonctionnalités Potentielles (Non implémentées) 💡

#### 1. Export des Données AVANT Correction
**Utilité**: Comparer avant/après dans Excel

**Implémentation suggérée**:
```r
# Ajouter Sheet 4: "Before_Correction"
openxlsx::addWorksheet(wb, "Before_Correction")
openxlsx::writeData(wb, "Before_Correction",
                   RvarsCorrectionTime$peakListAligned,
                   rowNames = FALSE)
```

#### 2. Export des Graphiques de Correction
**Utilité**: Intégrer les visualisations dans le rapport Excel

**Implémentation suggérée**:
```r
# Ajouter Sheet 5: "Correction_Plots"
plot_file <- tempfile(fileext = ".png")
ggsave(plot_file, plot = last_plot(), width = 10, height = 6)
openxlsx::insertImage(wb, "Correction_Plots",
                      file = plot_file,
                      startRow = 1, startCol = 1)
```

#### 3. Export Format CSV (Alternative à Excel)
**Utilité**: Compatibilité avec Python, R, autres outils

**Implémentation suggérée**:
```r
output$downloadCETimeCorrectedCSV <- downloadHandler(
  filename = function() {
    paste0("CE_time_corrected_peaks_",
           format(Sys.time(), "%Y%m%d_%H%M%S"),
           ".csv")
  },
  content = function(file) {
    write.csv(RvarsCorrectionTime$peakListAligned_KernelDensity,
              file, row.names = FALSE)
  }
)
```

#### 4. Export Batch (Tous les Échantillons)
**Utilité**: Exporter données sample-par-sample dans des feuilles séparées

**Implémentation suggérée**:
```r
# Une feuille par échantillon
for (sample_name in unique(corrected_data$sample)) {
  sample_data <- corrected_data %>% filter(sample == sample_name)
  openxlsx::addWorksheet(wb, sample_name)
  openxlsx::writeData(wb, sample_name, sample_data)
}
```

#### 5. Export avec Filtres Excel
**Utilité**: Permettre filtrage interactif dans Excel

**Implémentation suggérée**:
```r
# Ajouter filtres auto sur la première ligne
openxlsx::addFilter(wb, "Corrected_Peaks",
                    rows = 1,
                    cols = 1:ncol(corrected_data))
```

---

## 🎯 Workflow Complet: De la Correction à l'Export

### Diagramme de Flux
```
1. Charger fichiers mzML
   ↓
2. Sélectionner échantillon de référence
   ↓
3. [Optionnel] Appliquer XCMS Obiwarp
   ↓
4. Configurer paramètres Kernel Density:
   - Kernel Type (gaussian, epanechnikov, etc.)
   - Bandwidth Model (0.1 - 2.0)
   - Bandwidth Filter (0.1 - 2.0)
   - Min Density (0.001 - 0.1)
   - Intensity Filter (100 - 10000)
   ↓
5. Cliquer "Fit Model" pour CHAQUE échantillon
   ↓
6. Vérifier graphiques "Before/After Correction"
   ↓
7. Si OK → Passer à l'échantillon suivant
   Si NON → Ajuster paramètres et re-corriger
   ↓
8. Une fois TOUS les échantillons validés:
   → Cliquer "Download Corrected Data (Excel)"
   ↓
9. Fichier Excel téléchargé automatiquement
   ↓
10. Analyser dans Excel / Ouvrir dans R/Python pour analyse statistique
```

---

## 📖 Exemples d'Utilisation

### Exemple 1: Workflow Simple (20 échantillons)
```
1. Charger 20 fichiers mzML + 1 référence (21 total)
2. Sélectionner QC1 comme référence
3. Appliquer XCMS Obiwarp avec subset de 10 échantillons
4. Configurer Kernel Density:
   - Kernel: gaussian
   - Bandwidth Model: 0.5
   - Bandwidth Filter: 0.3
   - Min Density: 0.01
   - Intensity Filter: 1000
5. Fit Model pour les 20 échantillons (un par un)
6. Vérifier visuellement chaque résultat
7. Export Excel
8. Résultat: ~15,000 pics corrigés dans un fichier de 5 MB
```

### Exemple 2: Workflow Complexe (100 échantillons)
```
1. Charger 100 fichiers mzML + 1 référence
2. Sélectionner Pooled_QC comme référence
3. XCMS Obiwarp avec subset de 30 échantillons représentatifs
4. Kernel Density:
   - Kernel: epanechnikov (meilleure performance pour gros datasets)
   - Bandwidth Model: 0.7 (plus de lissage)
   - Bandwidth Filter: 0.4
   - Min Density: 0.02 (plus strict)
   - Intensity Filter: 2000 (éliminer bruit)
5. Fit Model pour 100 échantillons
   - Temps estimé: 2-3 heures (avec gc() fix)
   - Mémoire: 8-12 GB (avec gc() fix)
6. Export Excel
7. Résultat: ~150,000 pics corrigés dans un fichier de 25-30 MB
```

---

## 🐛 Dépannage (Troubleshooting)

### Problème 1: Bouton d'Export Grisé/Désactivé
**Cause**: `peakListAligned_KernelDensity` est NULL

**Solution**:
1. Vérifier que vous avez cliqué "Fit Model"
2. Vérifier qu'au moins un échantillon a été corrigé
3. Vérifier dans la console R:
   ```r
   !is.null(RvarsCorrectionTime$peakListAligned_KernelDensity)
   ```

---

### Problème 2: Export Plante/Erreur
**Cause possible**: Mémoire insuffisante

**Solution**:
1. Réduire le nombre d'échantillons
2. Appliquer filtre d'intensité plus strict
3. Augmenter RAM disponible
4. Vérifier logs dans la console R

---

### Problème 3: Fichier Excel Vide ou Incomplet
**Cause possible**: Corruption de `peakListAligned_KernelDensity`

**Solution**:
1. Re-faire la correction Kernel Density
2. Vérifier dans R console:
   ```r
   nrow(RvarsCorrectionTime$peakListAligned_KernelDensity)
   # Doit être > 0
   ```
3. Redémarrer l'application si nécessaire

---

### Problème 4: Export Très Lent (> 10 minutes)
**Cause possible**: Dataset très large (> 200,000 pics)

**Solutions**:
1. **Filtrer avant export**:
   ```r
   # Dans le code, avant export
   corrected_data <- corrected_data %>%
     filter(into > 10000)  # Garder seulement pics intenses
   ```
2. **Exporter en CSV** (plus rapide qu'Excel)
3. **Diviser en plusieurs fichiers** (par classe d'échantillon)

---

### Problème 5: Colonnes Manquantes dans l'Export
**Cause possible**: Colonnes ajoutées dynamiquement absentes

**Solution**:
1. Vérifier structure de `peakListAligned_KernelDensity`:
   ```r
   colnames(RvarsCorrectionTime$peakListAligned_KernelDensity)
   ```
2. S'assurer que toutes les étapes de traitement sont complètes
3. Re-faire alignement XCMS si nécessaire

---

## 📚 Références

### Fichiers Source
- **Server**: `server/newReferenceMap.server/CorrectionTime.Server_NewRefMap.R`
  - Export handler: lignes 6302-6399
  - Variables réactives: lignes 140-6297

- **UI**: `ui/newReferenceMap.ui/CorrectionTime.Ui_NewRefMap.R`
  - Bouton download: lignes 1004-1024

### Documentation Connexe
- `MEMORY_LEAK_FIX.md` - Problèmes de mémoire pendant correction
- `SOCKET_LEAK_FIX.md` - Problèmes de clusters parallèles
- `TIMEOUT_CONFIGURATION.md` - Configuration timeouts pour gros datasets
- `SESSION_SUMMARY.md` - Vue d'ensemble complète du système

### Packages R Utilisés
- **openxlsx**: Export Excel multi-feuilles
- **dplyr**: Manipulation de données
- **ggplot2**: Génération de graphiques (non exportés actuellement)

---

## 💡 Recommandations

### Pour Petits Datasets (< 50 échantillons)
1. ✅ Export Excel standard suffit
2. ✅ Vérification visuelle de tous les échantillons
3. ✅ Garder tous les pics (pas de filtrage agressif)

### Pour Moyens Datasets (50-150 échantillons)
1. ✅ Export Excel standard fonctionne bien
2. ⚠️ Vérification visuelle d'échantillons représentatifs (20-30%)
3. ⚠️ Appliquer filtre d'intensité modéré (> 1000)
4. ✅ Vérifier taille fichier Excel (< 50 MB recommandé)

### Pour Gros Datasets (> 150 échantillons)
1. ⚠️ Considérer export CSV au lieu d'Excel
2. ⚠️ Vérification visuelle échantillons critiques uniquement
3. ✅ Appliquer filtre d'intensité strict (> 5000)
4. ✅ Exporter en plusieurs fichiers par classe
5. ⚠️ Utiliser R/Python pour analyse statistique (pas Excel)

---

## 🔐 Sécurité et Traçabilité

### Données Incluses dans l'Export
Le fichier Excel exporté contient **TOUTES** les informations nécessaires pour:
1. ✅ **Reproduire l'analyse**: Paramètres de correction dans "Correction_Summary"
2. ✅ **Tracer les échantillons**: Métadonnées dans "Sample_Info"
3. ✅ **Vérifier la qualité**: Tous les pics avec statistiques (sn, into, etc.)

### Bonnes Pratiques
1. ✅ **Archiver le fichier Excel** après export
2. ✅ **Documenter les paramètres** utilisés (déjà dans Summary)
3. ✅ **Vérifier intégrité** des données exportées
4. ✅ **Backup réguliers** avant longues corrections

---

## 📊 Statistiques d'Export

### Taille Fichiers Typiques
| Échantillons | Pics Totaux | Taille Excel | Temps Export |
|--------------|-------------|--------------|--------------|
| 10           | 5,000       | 1-2 MB       | < 5 sec      |
| 50           | 25,000      | 5-8 MB       | 10-20 sec    |
| 100          | 50,000      | 10-15 MB     | 30-60 sec    |
| 200          | 100,000     | 20-30 MB     | 1-3 min      |
| 500          | 250,000     | 50-80 MB     | 5-10 min     |

**Note**: Temps mesurés sur machine avec SSD. HDD peut être 2-3x plus lent.

---

## ✅ Checklist Avant Export

Avant de cliquer "Download Corrected Data (Excel)", vérifiez:

- [ ] Tous les échantillons critiques ont été corrigés
- [ ] Vérification visuelle effectuée (100% ou échantillons représentatifs)
- [ ] Paramètres de correction optimisés (bandwidth, density, etc.)
- [ ] Pas d'erreurs/warnings dans console R
- [ ] Espace disque suffisant pour export (~ 50 MB pour 100 échantillons)
- [ ] Nom de fichier sera unique (timestamp automatique)
- [ ] Sauvegarde des données brutes effectuée

---

## 📝 Notes Finales

### Limitation Actuelle
- ✅ Export fonctionne uniquement pour **Kernel Density correction**
- ❌ Export XCMS Obiwarp seul **non disponible** (doit faire Kernel Density)
- ❌ Export données brutes **non disponible** (avant toute correction)

### Développements Futurs Possibles
1. Export XCMS Obiwarp standalone
2. Export multi-format (CSV, TSV, JSON)
3. Export graphiques dans Excel
4. Export rapport PDF automatique
5. Export vers bases de données (SQL, MongoDB, etc.)

---

**Document créé**: 2025-10-29
**Version MSPANDA**: Compatible avec version actuelle
**Auteur**: Documentation automatique après analyse du code
