# Les 6 Chargements de CE_time_Correction.lib.R

## Vue d'ensemble

Le fichier `CE_time_Correction.lib.R` est chargé **6 fois** dans l'application :
- **5 fois** dans `CorrectionTime.Server_NewRefMap.R`
- **1 fois** dans `analysisItemNewSamples.server.R`

---

## Chargement #1 - Initialisation XCMS

**Fichier** : `CorrectionTime.Server_NewRefMap.R`
**Ligne** : 3435
**Contexte** : Initialisation de la correction XCMS Obiwarp

```r
withProgress(message = 'CE-time correction:', value = 0, {
  message("\n 1. Importing the necessary functions...")
  incProgress(1 / 6, detail = "Importing the necessary functions...")
  source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",  # ← CHARGEMENT #1
         local = TRUE)

  message("\n 2. Getting data...")
  # ... correction XCMS ...
})
```

**Fréquence** : Une fois au début de la correction
**Problème** : Démarre 1er cluster

---

## Chargement #2 - Viewer XCMS 1

**Fichier** : `CorrectionTime.Server_NewRefMap.R`
**Ligne** : 3678
**Contexte** : Premier graphique de visualisation XCMS

```r
output$CorrectimeXCMSViewer_1 <- renderPlot({
  if (!is.null(RvarsCorrectionTime$peakListAligned) &
      !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
      !is.null(input$SelectSample_ViewerCorrectimeXcms)) {
    source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",  # ← CHARGEMENT #2
           local = TRUE)

    ref <- RvarsCorrectionTime$ref_sample_samplePeaks
    # ... génération du graphique ...
  }
})
```

**Fréquence** : À chaque fois que le graphique est re-rendu
**Problème** : Si vous changez d'échantillon 50 fois → 50 clusters créés

---

## Chargement #3 - Viewer XCMS Before (renderPlot)

**Fichier** : `CorrectionTime.Server_NewRefMap.R`
**Ligne** : 3905
**Contexte** : Graphique "Before" XCMS correction

```r
output$CorrectimeXCMSViewer_Before <- renderPlot({
  if (!is.null(RvarsCorrectionTime$peakListBefore) &
      !is.null(RvarsCorrectionTime$peakListAligned) &
      !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
      !is.null(input$SelectSample_ViewerCorrectimeXcms)) {
    source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",  # ← CHARGEMENT #3
           local = TRUE)

    ref <- RvarsCorrectionTime$ref_sample_samplePeaks
    # ... graphique avant correction ...
  }
})
```

**Fréquence** : Re-rendu à chaque changement d'échantillon
**Problème** : renderPlot() peut être appelé plusieurs fois même sans interaction utilisateur

---

## Chargement #4 - Viewer XCMS After (renderPlot)

**Fichier** : `CorrectionTime.Server_NewRefMap.R`
**Ligne** : 4097
**Contexte** : Graphique "After" XCMS correction

```r
output$CorrectimeXCMSViewer_After <- renderPlot({
  if (!is.null(RvarsCorrectionTime$peakListBefore) &
      !is.null(RvarsCorrectionTime$peakListAligned) &
      !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
      !is.null(input$SelectSample_ViewerCorrectimeXcms)) {
    source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",  # ← CHARGEMENT #4
           local = TRUE)

    ref <- RvarsCorrectionTime$ref_sample_samplePeaks
    # ... graphique après correction ...
  }
})
```

**Fréquence** : Re-rendu à chaque changement d'échantillon
**Problème** : Appelé en même temps que #3 → double cluster

---

## Chargement #5 - Kernel Density Filter

**Fichier** : `CorrectionTime.Server_NewRefMap.R`
**Ligne** : 4532
**Contexte** : Filtre kernel density pour la sélection d'échantillon

```r
observeEvent(input$SelectSample_KernelDensity, {
  if (!is.null(input$SelectSample_KernelDensity) &
      !is.null(RvarsCorrectionTime$peakListAligned) &
      !is.null(RvarsCorrectionTime$ref_sample_samplePeaks)) {

    source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",  # ← CHARGEMENT #5
           local = TRUE)

    ref <- RvarsCorrectionTime$ref_sample_samplePeaks
    # ... calcul densité kernel ...
  }
})
```

**Fréquence** : À chaque changement de sélection d'échantillon Kernel Density
**Problème** : Si vous testez 50 échantillons → 50 clusters

---

## Chargement #6 - Analysis New Samples

**Fichier** : `analysisItemNewSamples.server.R`
**Ligne** : 3364
**Contexte** : Analyse de nouveaux échantillons (module différent)

```r
observeEvent(..., {
  # ... préparation données ...

  source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",  # ← CHARGEMENT #6
         local = TRUE)

  # ... calculs sur nouveaux échantillons ...
})
```

**Fréquence** : À chaque analyse de nouveau échantillon
**Problème** : Encore un cluster supplémentaire

---

## Calcul du Nombre Total de Clusters Créés

### Scénario : Traitement de 50 échantillons

| Chargement | Appels | Total |
|------------|--------|-------|
| #1 - Initialisation | 1 | 1 cluster |
| #2 - Viewer 1 | 50× (changement échantillon) | 50 clusters |
| #3 - Before plot | 50× (auto-rerender) | 50 clusters |
| #4 - After plot | 50× (auto-rerender) | 50 clusters |
| #5 - Kernel Density | 50× (sélection) | 50 clusters |
| #6 - Analysis | 0× (module non utilisé ici) | 0 cluster |
| **TOTAL** | | **201 clusters** |

**MAIS** - Souvent les graphiques se re-rendent plusieurs fois :
- Changement de paramètres
- Zoom
- Resize de fenêtre
- Invalidation réactive

**Total réaliste** : **300-500 clusters** après traitement de 50 échantillons !

---

## Le Problème

**AVANT le fix** :

Chaque `source()` exécutait :
```r
register(bpstart(SnowParam(1)))
```

Ce qui :
1. Démarrait un nouveau processus R worker (Rscript.exe)
2. Ouvrait une nouvelle socket (port 11432, 11433, 11434...)
3. Enregistrait un nouveau backend BiocParallel

**Les anciens clusters n'étaient JAMAIS fermés !**

---

## La Solution

**APRÈS le fix** :

```r
if (!exists(".biocparallel_registered_ce_time", envir = .GlobalEnv)) {
  register(SnowParam(workers = 1, type = "SOCK"), default = FALSE)
  assign(".biocparallel_registered_ce_time", TRUE, envir = .GlobalEnv)
}
```

Maintenant :
- Premier `source()` → Enregistre 1 cluster
- Tous les autres `source()` → **SKIP** (flag déjà présent)
- Cluster créé **on-demand** quand bplapply() est appelé
- Cluster **détruit automatiquement** après usage

**Résultat** : 1 seul cluster au lieu de 300+ !

---

## Pourquoi CE_time_Correction.lib.R Est Sourcé Partout ?

**Raison historique** : Le fichier contient des fonctions utilitaires :
- `matchMz()` - Match des m/z entre échantillons
- `alignement_Obiwrap()` - Fonction wrapper XCMS
- Autres fonctions helper

**Problème d'architecture** :
- Ces fonctions devraient être chargées UNE FOIS au démarrage
- Actuellement rechargées à chaque graphique
- Le cluster BiocParallel était un "effet de bord" non désiré

---

## Vérification

Pour vérifier combien de fois le fichier est chargé :

**Recherche complète** :
```bash
grep -r 'source.*CE_time_Correction.lib.R' /home/user/MSpandas/server --include="*.R"
```

**Résultat** :
- 5 occurrences dans CorrectionTime.Server_NewRefMap.R
- 1 occurrence dans analysisItemNewSamples.server.R
- **Total : 6 occurrences**

**Ligne commentée** (ligne 3649) :
```r
#     source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R", local=TRUE)
```
Cette ligne est commentée donc ne compte pas dans les 6 actifs.

---

**Conclusion** : Le fix empêche la création de centaines de clusters inutiles en enregistrant le backend BiocParallel UNE SEULE FOIS au lieu de 300+ fois.
