# Instructions pour Appliquer le Fix de Fuite Mémoire

## Résumé du Problème

L'application crashe après ~50-150 échantillons même avec 64 GB RAM car **6 renderPlot() sont recréés à chaque clic** sans jamais être libérés.

## Fichiers Affectés

- `server/newReferenceMap.server/CorrectionTime.Server_NewRefMap.R`

## Changements Requis

### Changement 1: Ajouter le Reactive Trigger (DÉJÀ FAIT ✅)

Ligne 6 a été ajoutée:
```r
plotUpdateTrigger_KernelDensity <- reactiveVal(0)
```

### Changement 2: Remplacer l'observe() Lignes 6273-6293

**Actuellement** (lignes 6273-6293):
```r
observe({
  if (is.null(RvarsCorrectionTime$modelKernelDensity)) {
    output$PlotCorrectionKernelDensity_Before <- renderPlot({})
    output$PlotCorrectionKernelDensity_After <- renderPlot({})
    output$CorrectimeKernelDensityViewer_2 <- renderPlot({})
  }

  if (is.null(input$SelectSample_KernelDensity) ||
      is.null(RvarsCorrectionTime$peakListAligned) ||
      is.null(RvarsCorrectionTime$ref_sample_samplePeaks)) {
    output$DensityFilterPlot <- renderPlot({})
  }
})
```

**À SUPPRIMER** car cela crée aussi des renderPlot() dynamiques !

### Changement 3: Supprimer les renderPlot() des observeEvent()

#### Dans observeEvent(input$fitModel) - Lignes 4822-4998

**SUPPRIMER** les lignes 4822-5488 (tout le bloc avec 3 renderPlot())

#### Dans observeEvent(input$resetFitModel) - Lignes 5592-6253

**SUPPRIMER** les lignes 5592-6253 (tout le bloc avec 3 renderPlot())

### Changement 4: Ajouter les Triggers dans les observeEvent()

#### Dans observeEvent(input$fitModel) - Ligne ~4808

**AJOUTER** juste après la correction:
```r
# Update plot trigger to refresh visualizations
plotUpdateTrigger_KernelDensity(plotUpdateTrigger_KernelDensity() + 1)
```

#### Dans observeEvent(input$resetFitModel) - Ligne ~5582

**AJOUTER** juste après la réinitialisation:
```r
# Update plot trigger to refresh visualizations
plotUpdateTrigger_KernelDensity(plotUpdateTrigger_KernelDensity() + 1)
```

### Changement 5: Créer les renderPlot() Statiques

**AJOUTER** à la place de l'ancien observe() (ligne ~6273), AVANT le downloadHandler:

Voir le fichier `MEMORY_LEAK_FIX_RENDERPLOTS.R` pour le code complet.

## Difficulté d'Implémentation

⚠️ **Ce fix est COMPLEXE** car il nécessite:
1. Extraire >1500 lignes de code de renderPlot()
2. Les déplacer en dehors des observeEvent()
3. Ajouter les dépendances réactives correctement
4. Tester extensivement

## Option Alternative: Fix Simplifié

Si le fix complet est trop risqué, une **solution plus simple mais moins optimale** est possible:

### Option B: Garbage Collection Forcé

Ajouter à la fin de chaque observeEvent():

```r
# Force garbage collection to free memory
invisible(gc(verbose = FALSE))
```

**Avantages:**
- Changement minimal (2 lignes)
- Aucun risque de casser l'application

**Inconvénients:**
- Ne résout PAS la fuite mémoire (juste ralentit le crash)
- Toujours un crash après ~200-300 échantillons au lieu de 100-150
- Performance légèrement réduite

## Recommandation

Étant donné la complexité du fix complet et les risques, je recommande:

1. **Court terme:** Appliquer l'Option B (gc()) immédiatement
2. **Moyen terme:** Créer une branche de test pour le fix complet
3. **Long terme:** Refactoriser complètement le module Kernel Density

## Test du Fix

Après application du fix:

1. Ouvrir Task Manager
2. Noter la mémoire R au démarrage
3. Traiter 20 échantillons
4. **Vérifier**: Mémoire ne devrait PAS augmenter significativement après les 5 premiers
5. Traiter 30 échantillons supplémentaires (50 total)
6. **Vérifier**: Mémoire stable à ~400-600 MB

Si la mémoire continue d'augmenter linéairement, le fix n'a pas fonctionné.

## Support

Pour toute question sur l'implémentation de ce fix, référez-vous à:
- `MEMORY_LEAK_FIX.md` - Documentation technique complète
- Code original: lignes 4731-6293

---

*Généré par Claude Code - Fix pour Windows 11*
