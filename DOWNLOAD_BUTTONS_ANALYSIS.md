# Analyse des fonctionnalités Save/Download de MSPANDA

## État actuel : UN SEUL bouton de téléchargement

### Bouton existant :
**"Export the parameters"** (ExportParam)
- **Localisation** : Analysis new samples → Samples normalization
- **Fonction** : Télécharge un fichier .txt contenant les paramètres utilisés
- **Fichier** : `ui/analysisNewSamples.ui/normalizationItemNewSamples.ui.R` (ligne 418)
- **Handler** : `server/analysisNewSamples.server/normalzationItemNewSamples.server.R` (ligne 2408)

## Données actuellement sauvegardées en interne (mais non téléchargeables)

### 1. Base de données (Database)
- **Cartes de référence** (`map_ref.csv`) - Affichées dans `ReferenceMapShow`
- **Normalisateurs** (`normalizers_ref.csv`) - Affichés dans `normalizersRefShow`
- **Sauvegardées dans** : `data/References/[nom_reference]/`

### 2. New Reference Map
- **Carte de référence** (`map_ref.csv`, `MatrixAbundance_Before.csv`, `MatrixAbundance_After.csv`)
- **Paramètres par défaut** (`defaultParam.txt`, `Parameters_Used.txt`)
- **Fichier run_ref.mzML**
- **Affichée dans** : `dataTableRefernceMapViewer`

### 3. Analysis New Samples
- **Tables de correspondance** (`matchedTableViewer`)
- **Pourcentage de match** (`percent_matchViewer`)
- **Graphiques de correction CE-time** (multiples plotOutput)
- **Graphiques de filtrage par densité**

## Recommandations : Boutons Save/Download à ajouter

### PRIORITÉ ÉLEVÉE ⭐⭐⭐

#### 1. Database Module
**Bouton : "Download Reference Map"**
- Localisation : À côté du tableau `ReferenceMapShow`
- Format : CSV ou Excel
- Contenu : Carte de référence complète avec tous les pics identifiés
- Utilité : Permet aux utilisateurs de réutiliser les données dans d'autres outils

**Bouton : "Download Normalizers Table"**
- Localisation : À côté du tableau `normalizersRefShow`
- Format : CSV
- Contenu : Liste des normalisateurs avec leurs propriétés
- Utilité : Documentation et réutilisation

#### 2. New Reference Map → Generate the reference map
**Bouton : "Download Complete Reference Map Package"**
- Localisation : Page "Generate the reference map"
- Format : ZIP contenant :
  - map_ref.csv (carte de référence)
  - MatrixAbundance_Before.csv
  - MatrixAbundance_After.csv
  - defaultParam.txt
  - Parameters_Used.txt
  - run_ref.mzML
- Utilité : Package complet pour archivage et partage

**Bouton : "Download Reference Map Table (CSV)"**
- Localisation : Sous le tableau `dataTableRefernceMapViewer`
- Format : CSV
- Contenu : Table de référence affichée
- Utilité : Export rapide pour Excel/R/Python

#### 3. Analysis New Samples → Match reference map
**Bouton : "Download Match Results"**
- Localisation : À côté de `matchedTableViewer`
- Format : CSV ou Excel avec plusieurs onglets
- Contenu :
  - Table des correspondances
  - Statistiques de match
  - Pourcentages de correspondance
- Utilité : Analyse statistique et publication

**Bouton : "Download Match Statistics"**
- Localisation : À côté de `percent_matchViewer`
- Format : CSV
- Contenu : Pourcentages de match par échantillon
- Utilité : Métriques de qualité

#### 4. Analysis New Samples → Samples normalization
**Bouton : "Download Normalized Data"**
- Localisation : Page de normalisation (en plus du bouton paramètres existant)
- Format : CSV ou Excel
- Contenu : Données normalisées finales
- Utilité : Données prêtes pour l'analyse statistique downstream

### PRIORITÉ MOYENNE ⭐⭐

#### 5. CE-time Correction
**Bouton : "Download Correction Plots (PDF)"**
- Localisation : Page CE-time correction
- Format : PDF multi-pages
- Contenu : Tous les graphiques de correction
- Utilité : Rapport visuel pour publications

**Bouton : "Download Corrected Data"**
- Localisation : Page CE-time correction
- Format : CSV
- Contenu : Temps de migration corrigés
- Utilité : Contrôle qualité et traçabilité

#### 6. Peak Detection (New Reference Map)
**Bouton : "Download Peak List"**
- Localisation : Page Peak detection
- Format : CSV
- Contenu : Liste des pics détectés avec leurs propriétés
- Utilité : Vérification de la détection

#### 7. Peak Detection (Analysis New Samples)
**Bouton : "Download Detected Peaks"**
- Localisation : Page Peak detection and grouping
- Format : CSV
- Contenu : Pics détectés pour le nouvel échantillon
- Utilité : Comparaison avec référence

### PRIORITÉ BASSE ⭐

#### 8. Export graphiques individuels
**Boutons : "Download Plot (PNG/PDF)"**
- Localisation : Sur chaque graphique majeur
- Format : PNG haute résolution ou PDF vectoriel
- Contenu : Graphique individuel
- Utilité : Figures pour présentations/publications

#### 9. Export rapport complet
**Bouton : "Generate Analysis Report (PDF)"**
- Localisation : Page finale de chaque workflow
- Format : PDF
- Contenu : Rapport complet avec tous les résultats, graphiques, et paramètres
- Utilité : Documentation complète de l'analyse

## Implémentation suggérée

### Template de code pour ajouter un bouton download

**Dans le fichier UI :**
```r
downloadButton(
  outputId = "downloadRefMap",
  label = "Download Reference Map",
  class = "btn-success",
  icon = icon("download")
)
```

**Dans le fichier Server :**
```r
output$downloadRefMap <- downloadHandler(
  filename = function() {
    paste0("reference_map_",
           format(Sys.time(), "%Y%m%d_%H%M%S"),
           ".csv")
  },
  content = function(file) {
    write.csv(RvarsInternalStandard$map_ref_ToSave,
              file,
              row.names = FALSE)
  }
)
```

### Pour un export ZIP avec plusieurs fichiers :
```r
output$downloadPackage <- downloadHandler(
  filename = function() {
    paste0("reference_map_package_",
           format(Sys.time(), "%Y%m%d_%H%M%S"),
           ".zip")
  },
  content = function(file) {
    # Créer un dossier temporaire
    temp_dir <- tempdir()
    temp_files <- c()

    # Sauvegarder chaque fichier
    file1 <- file.path(temp_dir, "map_ref.csv")
    write.csv(data1, file1, row.names = FALSE)
    temp_files <- c(temp_files, file1)

    file2 <- file.path(temp_dir, "parameters.txt")
    writeLines(params, file2)
    temp_files <- c(temp_files, file2)

    # Créer le ZIP
    zip(zipfile = file, files = temp_files, flags = "-j")
  },
  contentType = "application/zip"
)
```

### Pour exporter des graphiques :
```r
output$downloadPlot <- downloadHandler(
  filename = function() {
    paste0("plot_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".png")
  },
  content = function(file) {
    png(file, width = 1200, height = 800, res = 150)
    print(plot_object)  # Votre ggplot ou plot R
    dev.off()
  },
  contentType = "image/png"
)
```

## Bénéfices pour les utilisateurs

1. **Traçabilité** : Tous les résultats peuvent être archivés
2. **Reproductibilité** : Les données exportées permettent de refaire les analyses
3. **Publication** : Graphiques et tables prêts pour les articles scientifiques
4. **Intégration** : Données exportables vers Excel, R, Python, GraphPad Prism, etc.
5. **Collaboration** : Partage facile des résultats avec des collègues
6. **Backup** : Sauvegarde des résultats importants
7. **Analyse avancée** : Utilisation des données dans d'autres outils statistiques

## Conclusion

**L'application a actuellement 1 seul bouton de téléchargement sur environ 10-15 sections qui génèrent des données importantes.**

**Recommandation minimale** : Ajouter au moins 5-7 boutons de téléchargement (priorité élevée)
**Recommandation optimale** : Ajouter 12-15 boutons pour une couverture complète

Cela transformerait MSPANDA d'un outil d'analyse interne en une plateforme complète avec export de données pour workflows scientifiques.
