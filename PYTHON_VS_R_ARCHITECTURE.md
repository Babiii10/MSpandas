# Architecture Python vs R dans MSPANDA

## Vue d'Ensemble Rapide

**MSPANDA est une application R/Shiny avec des scripts Python auxiliaires.**

```
┌──────────────────────────────────────────────────────────────┐
│                    APPLICATION MSPANDA                       │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           PARTIE R (100% UI + SERVER)                  │ │
│  │                                                         │ │
│  │  ui.R  ──┐                                             │ │
│  │  server.R ├──→ Interface Shiny                         │ │
│  │  global.R ┘    Logique métier                          │ │
│  │                Traitement données                       │ │
│  │                Visualisations                           │ │
│  │                                                         │ │
│  │  Appelle Python via reticulate ──────┐                 │ │
│  └──────────────────────────────────────┼─────────────────┘ │
│                                         │                   │
│  ┌──────────────────────────────────────▼─────────────────┐ │
│  │           PARTIE PYTHON (Scripts Utilitaires)         │ │
│  │                                                        │ │
│  │  • Génération fichiers .bat                           │ │
│  │  • Modification paramètres MS-DIAL                    │ │
│  │  • Export de configurations                           │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

---

## 📊 Statistiques

| Langage | Fichiers | Rôle |
|---------|----------|------|
| **R** | **37 fichiers** | UI + Server + Logique métier |
| **Python** | **6 fichiers** | Scripts utilitaires uniquement |

---

## 1. UI (Interface Utilisateur) - 100% R

### Fichiers UI

```
ui/
├── newReferenceMap.ui/
│   ├── CorrectionTime.Ui_NewRefMap.R          ✅ R
│   ├── peakDetection.Ui_NewRefMap.R           ✅ R
│   ├── GenerateMapRef.Ui_NewRefMap.R          ✅ R
│   └── InternalStandard.Ui_NewRefMap.R        ✅ R
├── analysisNewSamples.ui/
│   ├── analysisItemNewSamples.ui.R            ✅ R
│   └── normalizationItemNewSamples.ui.R       ✅ R
├── database.ui/
│   └── database.ui.R                           ✅ R
└── About.ui/
    └── about.ui.R                              ✅ R
```

### Technologie UI

**Framework** : Shiny (R)
**Composants** :
- `fluidPage()` - Mise en page responsive
- `tabsetPanel()` - Onglets
- `plotOutput()` - Graphiques
- `dataTableOutput()` - Tables de données
- `actionButton()` - Boutons
- `sliderInput()` - Contrôles

**Exemple de code UI (CorrectionTime.Ui_NewRefMap.R)** :

```r
fluidRow(column(
  12,
  div(
    class = "well well-sm",
    style = "background-color: #e8f5e9;",
    h4("Export corrected data", style = "color: #2e7d32;"),
    downloadButton(
      outputId = "downloadCETimeCorrected",
      label = "Download Corrected Data (Excel)",
      class = "btn-success",
      icon = icon("file-excel")
    )
  )
))
```

**❌ Aucun Python dans la partie UI**

---

## 2. SERVER (Logique Backend) - 95% R + 5% Python

### Fichiers Server

```
server/
├── newReferenceMap.server/
│   ├── CorrectionTime.Server_NewRefMap.R       ✅ R (100%)
│   ├── peakDetection.Server_NewRefMap.R        ✅ R (95%) + Python (5%)
│   ├── GenerateMapRef.Server_NewRefMap.R       ✅ R (100%)
│   ├── InternalStandard.server_NewRefMap.R     ✅ R (95%) + Python (5%)
│   └── reactiveVarsNewRefMap.R                 ✅ R (100%)
├── analysisNewSamples.server/
│   ├── analysisItemNewSamples.server.R         ✅ R (95%) + Python (5%)
│   ├── normalzationItemNewSamples.server.R     ✅ R (95%) + Python (5%)
│   └── reactiveVarsAnalysisNewSample.R         ✅ R (100%)
└── database.server/
    ├── database.server.R                       ✅ R (100%)
    └── reactiveValuesDatabase.server.R         ✅ R (100%)
```

### Technologie Server

**Framework** : Shiny Server (R)
**Packages R utilisés** :
- `shiny` - Réactivité et server logic
- `XCMS` - Correction CE-time (Obiwarp, Kernel Density)
- `BiocParallel` - Calcul parallèle
- `ggplot2` - Graphiques
- `dplyr` - Manipulation de données
- `openxlsx` - Export Excel
- `reticulate` - Interface R ↔ Python

**Python appelé via** : `reticulate::source_python()`

---

## 3. Les 6 Scripts Python

### NewReferenceMap (3 scripts Python)

| Fichier | Rôle | Appelé par (R) | Fréquence |
|---------|------|----------------|-----------|
| **msconverter_command_line.py** | Génère `.bat` pour MSConvert | peakDetection.Server_NewRefMap.R:187 | 1× par conversion |
| **modify_ParamMsdialNewReferenceMap.py** | Modifie paramètres MS-DIAL | peakDetection.Server_NewRefMap.R | 1× par projet |
| **exportDefaultParam.py** | Exporte config par défaut | InternalStandard.server_NewRefMap.R:439 | 1× par export |

### AnalysisNewSample (3 scripts Python)

| Fichier | Rôle | Appelé par (R) | Fréquence |
|---------|------|----------------|-----------|
| **msconverter_command_line.py** | Génère `.bat` pour MSConvert | analysisItemNewSamples.server.R:446 | 1× par analyse |
| **modify_ParamMsdial.py** | Modifie paramètres MS-DIAL | analysisItemNewSamples.server.R:197, 786 | 2× par analyse |
| **export.parameters.py** | Exporte paramètres finaux | analysisItemNewSamples.server.R:613<br>normalzationItemNewSamples.server.R:2172 | Variable |

---

## 4. Flux d'Exécution Typique

### Exemple : Peak Detection (New Reference Map)

```
┌─────────────────────────────────────────────────────────────────┐
│  1. USER clique sur "Start Peak Detection" dans l'UI (R)       │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. SERVER R (peakDetection.Server_NewRefMap.R)                 │
│                                                                  │
│     observeEvent(input$StartPeakDetection, {                    │
│        # R: Validation des inputs                               │
│        # R: Création des dossiers                               │
│        # R: Préparation des données                             │
│                                                                  │
│        # APPEL PYTHON #1                                        │
│        source_python("msconverter_command_line.py")      ◄──────┤─┐
│        convert_to_mzML(input_dir, output_dir)                   │ │
│     })                                                           │ │
└─────────────────────────┬───────────────────────────────────────┘ │
                          │                                         │
                          ▼                                         │
┌─────────────────────────────────────────────────────────────────┐ │
│  3. PYTHON génère le fichier .bat                               │ │
│                                                                  │ │
│     def convert_to_mzML(input_directory, output_directory):     │ │
│        # Lit le template                                        │ │
│        # Remplace les chemins                                   │ │
│        # ÉCRIT convert_raw_data_to_mzML_centroid.bat            │ │
│        with open("cmd/convert_to_mzML.bat", 'w') as f:          │ │
│           f.write(msconvert_command)                             │ │
│                                                                  │ │
│     RETOURNE à R  ────────────────────────────────────────────────┘
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. SERVER R exécute le .bat                                    │
│                                                                  │
│     system2("cmd.exe",                                           │
│             args = c("/c", "cmd/convert_to_mzML.bat"))          │
│                                                                  │
│     # Le .bat appelle MSConvert.exe (C++ + DLL)                 │
│     # MSConvert convertit RAW → mzML                            │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. SERVER R continue le traitement                             │
│                                                                  │
│     # R: Lit les fichiers mzML avec XCMS                        │
│     # R: Détection de pics avec MS-DIAL (via .bat similaire)   │
│     # R: Traitement des résultats                               │
│     # R: Génération des graphiques                              │
│     # R: Mise à jour UI                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Pourquoi Python Est Utilisé ?

### Raison 1 : Manipulation de Fichiers Texte

**Python excelle dans** :
- Lecture/écriture de fichiers ligne par ligne
- Recherche/remplacement de chaînes
- Génération de scripts `.bat`

**Exemple** : `msconverter_command_line.py`

```python
def convert_to_mzML(input_directory, output_directory):
    param_convert = open("parameters/convert_template.txt", 'r')
    fileContent = param_convert.readlines()

    # Remplace les placeholders
    fileContent[0] = fileContent[0].replace("input_directory", input_directory)
    fileContent[0] = fileContent[0].replace("output_directory", output_directory)

    # Écrit le .bat
    with open("cmd/convert.bat", 'w', encoding='cp1252', newline='\r\n') as f:
        for line in fileContent:
            f.write(line)
```

**Pourquoi pas R ?** :
- R est moins concis pour ce type de manipulation
- Python a une syntaxe plus claire pour les fichiers
- Historique du projet (scripts Python existants)

---

### Raison 2 : Modification de Paramètres MS-DIAL

**MS-DIAL** utilise des fichiers de paramètres texte complexes.

**Python** : Ideal pour parser et modifier ligne par ligne

**Exemple** : `modify_ParamMsdialNewReferenceMap.py`

```python
def MsdialParam(input_param, output_param, MS1_type, MS2_type,
                ion, rt_begin, rt_end, ...):
    paramMsdial = open(input_param, 'r')
    fileContent = paramMsdial.readlines()

    # Modifie ligne par ligne
    fileContent[1] = fileContent[1].replace("MS1_type", MS1_type)
    fileContent[7] = fileContent[7].replace("rt_begin", rt_begin)
    fileContent[8] = fileContent[8].replace("rt_end", rt_end)
    ...

    with open(output_param, 'w') as f:
        for line in fileContent:
            f.write(line)
```

---

## 6. Ce Que Python NE Fait PAS

### ❌ Python n'est PAS utilisé pour :

1. **Interface utilisateur** → 100% R/Shiny
2. **Logique métier** → 100% R
3. **Traitement des données** → 100% R (XCMS, dplyr)
4. **Correction CE-time** → 100% R (Obiwarp, Kernel Density)
5. **Calcul parallèle** → 100% R (BiocParallel)
6. **Graphiques** → 100% R (ggplot2)
7. **Export Excel** → 100% R (openxlsx)
8. **Base de données** → 100% R (SQLite)

### ✅ Python est utilisé UNIQUEMENT pour :

1. **Génération de fichiers .bat** (6× dans l'application)
2. **Modification de fichiers de paramètres** (6× dans l'application)

**Total** : ~12 appels Python dans toute l'application

---

## 7. Intégration R ↔ Python

### Package utilisé : `reticulate`

**Configuration** : `global.R` (lignes 77-104)

```r
# Configuration Python
python_path <- normalizePath(file.path(getwd(), "lib", "Python", "python.exe"),
                             winslash = "/", mustWork = FALSE)

if (file.exists(python_path)) {
  Sys.setenv(RETICULATE_PYTHON = python_path)
  suppressWarnings({
    tryCatch({
      use_python(python_path, required = FALSE)
    }, error = function(e) {
      message("Python initialization warning: ", e$message)
    })
  })
}
```

### Appel Python depuis R

```r
# Dans le server R
source_python("lib/NewReferenceMap/Python_files/msconverter_command_line.py")

# Appelle la fonction Python
convert_to_mzML(
  input_directory = "/path/to/raw/files",
  output_directory = "/path/to/mzml/output"
)

# Python génère le .bat puis retourne à R
```

---

## 8. Comparaison des Responsabilités

| Tâche | R | Python | Outils Externes |
|-------|---|--------|-----------------|
| **Interface UI** | ✅ 100% | ❌ | - |
| **Logique Server** | ✅ 95% | ✅ 5% | - |
| **Import données RAW** | ✅ (XCMS) | ❌ | MSConvert.exe |
| **Conversion RAW→mzML** | ⚠️ Orchestration | ✅ Génère .bat | ✅ MSConvert.exe |
| **Détection de pics** | ⚠️ Orchestration | ✅ Config MS-DIAL | ✅ MsdialConsoleApp.exe |
| **Correction CE-time** | ✅ 100% | ❌ | - |
| **Groupement de pics** | ✅ 100% | ❌ | - |
| **Graphiques** | ✅ 100% | ❌ | - |
| **Export résultats** | ✅ 100% | ✅ Config export | - |

---

## 9. Architecture en Couches

```
┌─────────────────────────────────────────────────────────────┐
│                      LAYER 1: UI (R)                        │
│  Shiny UI components, HTML, CSS, JavaScript                │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   LAYER 2: SERVER (R)                       │
│  Reactive logic, event handlers, data processing            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  XCMS, BiocParallel, ggplot2, dplyr, openxlsx        │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                LAYER 3: UTILITIES (Python)                  │
│  File generation, parameter modification                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  msconverter_command_line.py                          │  │
│  │  modify_ParamMsdial.py                                │  │
│  │  export.parameters.py                                 │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              LAYER 4: EXTERNAL TOOLS (C++/.NET)             │
│  MSConvert.exe, MsdialConsoleApp.exe                        │
│  + 181 DLL files                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. Résumé Exécutif

### UI (Interface)
- **100% R** (Shiny)
- 8 fichiers UI
- Aucun Python

### SERVER (Logique)
- **~95% R** (Shiny Server + XCMS + BiocParallel)
- **~5% Python** (6 scripts utilitaires)
- 10 fichiers server R
- Python appelé 12× via `reticulate::source_python()`

### Rôle de Python
- ✅ Génération de fichiers `.bat` pour MSConvert
- ✅ Modification de fichiers paramètres MS-DIAL
- ✅ Export de configurations
- ❌ **Aucun** rôle dans l'UI
- ❌ **Aucun** rôle dans les calculs scientifiques
- ❌ **Aucun** rôle dans les graphiques

### Points Clés
1. **MSPANDA est une application R/Shiny**
2. **Python est un utilitaire auxiliaire** (5% du code)
3. **Toute l'interface et la logique sont en R**
4. **Python génère des scripts pour outils externes** (MSConvert, MS-DIAL)

---

**Analogie** :
- R = Chef cuisinier (fait 95% du travail)
- Python = Aide de cuisine (prépare quelques ingrédients)
- Outils externes (.exe) = Four, mixeur (équipement spécialisé)

---

## 11. Fichiers Importants à Retenir

### Fichiers R Principaux
- `ui.R` - Point d'entrée UI
- `server.R` - Point d'entrée Server
- `global.R` - Configuration globale
- `CorrectionTime.Server_NewRefMap.R` - **Correction CE-time (6396 lignes !)**

### 6 Scripts Python
1. `lib/NewReferenceMap/Python_files/msconverter_command_line.py` (19 lignes)
2. `lib/NewReferenceMap/Python_files/modify_ParamMsdialNewReferenceMap.py` (117 lignes)
3. `lib/NewReferenceMap/Python_files/exportDefaultParam.py` (66 lignes)
4. `lib/AnalysisNewSample/Python_files/msconverter_command_line.py` (19 lignes)
5. `lib/AnalysisNewSample/Python_files/modify_ParamMsdial.py` (180 lignes)
6. `lib/AnalysisNewSample/Python_files/export.parameters.py` (81 lignes)

**Total Python** : ~482 lignes
**Total R** : ~20,000+ lignes

**Ratio** : R représente **98% du code**, Python **2%**

---

**Conclusion** : MSPANDA est une application **R/Shiny** qui utilise Python comme **outil auxiliaire** pour générer des fichiers de configuration et des scripts batch.
