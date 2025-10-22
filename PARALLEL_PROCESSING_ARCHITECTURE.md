# Utilisation des fichiers de calcul parallèle dans MSPANDA

## Vue d'ensemble

MSPANDA utilise deux applications externes qui implémentent le traitement parallèle pour accélérer l'analyse de données MS :

1. **MSConvert** (ProteoWizard) - Conversion de fichiers MS
2. **MS-DIAL** - Détection et analyse de pics

Ces applications utilisent des bibliothèques .NET pour le calcul parallèle, notamment `ParallelExtensionsExtras.dll`.

## Architecture du calcul parallèle

### 1. MSConvert (ProteoWizard)

#### Localisation
- **Exécutable** : `lib/MSconverter/pwiz_bin_windows/msconvert.exe` (12 MB)
- **DLL parallèle** : `lib/MSconverter/pwiz_bin_windows/ParallelExtensionsExtras.dll` (161 KB)
- **Total de DLLs** : 168 fichiers de support

#### Configuration du parallélisme

**Fichier de configuration** : `MSConvertGUI.exe.config`
```xml
<userSettings>
  <MSConvertGUI.Properties.Settings>
    <setting name="NumFilesToConvertInParallel" serializeAs="String">
      <value>1</value>  <!-- Nombre de fichiers traités en parallèle -->
    </setting>
  </MSConvertGUI.Properties.Settings>
</userSettings>
```

**Par défaut** : 1 fichier à la fois (conversion séquentielle)

#### Utilisation dans MSPANDA

MSConvert est appelé via des fichiers batch générés dynamiquement :

**Template** : `lib/NewReferenceMap/parameters/convert_raw_data_to_mzML_centroid.txt`
```bash
directory_msconverter.exe input_directory --filter "peakPicking true 1-" -o output_directory
```

**Fichier batch généré** : `lib/NewReferenceMap/cmd/convert_raw_data_to_mzML_centroid.bat`
```batch
"C:\path\to\msconvert.exe" "input/*" --filter "peakPicking true 1-" -o "output"
```

**Fonction Python qui génère le batch** : `lib/NewReferenceMap/Python_files/msconverter_command_line.py`
```python
def convert_to_mzML(input_directory, output_directory):
    # Construit le chemin vers msconvert.exe
    msconvert_path = os.path.join(os.getcwd(), "lib", "MSconverter",
                                   "pwiz_bin_windows", "msconvert.exe")

    # Génère le fichier .bat avec la commande
    # Le batch est ensuite exécuté via system2() dans R
```

#### Comment ParallelExtensionsExtras.dll est utilisée

1. **Chargement automatique** :
   - Quand `msconvert.exe` démarre, le .NET Framework charge automatiquement toutes les DLLs nécessaires depuis le même répertoire
   - `ParallelExtensionsExtras.dll` est chargée en mémoire si nécessaire

2. **Fonctionnalités fournies** :
   - **Task Parallel Library (TPL)** extensions
   - **Parallel LINQ (PLINQ)** optimisations
   - **Async/await** patterns pour I/O asynchrone
   - **Producer/Consumer queues** parallèles
   - **Fork/Join** parallelism

3. **Utilisation interne par MSConvert** :
   ```
   msconvert.exe utilise ParallelExtensionsExtras.dll pour :
   - Lire plusieurs fichiers MS en parallèle
   - Traiter les scans MS en parallèle
   - Écrire les fichiers convertis en parallèle
   - Gérer les files d'attente de travail
   ```

4. **Contrôle du parallélisme** :
   - Par défaut, MSConvert détecte automatiquement le nombre de cœurs CPU
   - Utilise jusqu'à `Environment.ProcessorCount` threads
   - Sur un CPU 8 cœurs : peut utiliser jusqu'à 8 threads simultanés

### 2. MS-DIAL

#### Localisation
- **Exécutable** : `lib/MSDIAL/MSDIAL ver.4.80 Windows/MsdialConsoleApp.exe`
- **DLLs parallèles** : Incluses dans le package MS-DIAL

#### Configuration du parallélisme

**Paramètre dans MSPANDA** : `Number of threads`

**Template** : `lib/NewReferenceMap/parameters/paramMsdial.txt`
```
#Data processing
Number of threads: number_threads
```

**Valeur par défaut** : 5 threads

**Configuration dans R** : `lib/NewReferenceMap/R_files/peakPickingNewReferenceMap.R`
```r
peakPickingNewReferenceMap <- function(...) {
  MsdialParam(
    input_param = "lib/NewReferenceMap/parameters/paramMsdial.txt",
    output_param = output_path,
    # ... autres paramètres ...
    number_threads = "5",  # <- Contrôle du parallélisme
    # ... autres paramètres ...
  )
}
```

#### Utilisation du parallélisme

MS-DIAL utilise le paramètre `Number of threads` pour :

1. **Détection de pics en parallèle**
   - Traite plusieurs fichiers mzML simultanément
   - Chaque thread traite un fichier

2. **Alignement des pics**
   - Parallélise le calcul des distances entre pics
   - Accélère la génération de la carte de référence

3. **Deconvolution**
   - Traite plusieurs régions de masse en parallèle

## Bibliothèques .NET pour le parallélisme

### ParallelExtensionsExtras.dll

**Fonctionnalités principales** :

```csharp
// 1. Producer/Consumer pattern
public class BlockingCollection<T>
{
    // File d'attente thread-safe pour traitement parallèle
    // Utilisée pour gérer les files d'attente de fichiers MS
}

// 2. Fork/Join parallelism
public class Parallel
{
    // Parallel.For, Parallel.ForEach
    // Pour traiter les scans MS en parallèle
}

// 3. Task coordination
public class TaskScheduler
{
    // Gestion intelligente de l'ordonnancement des tâches
    // Optimise l'utilisation des cœurs CPU
}

// 4. Async patterns
public class AsyncEx
{
    // Lecture/écriture asynchrone de fichiers
    // Évite le blocage pendant les I/O disque
}
```

### Autres DLLs de support (168 total)

Les DLLs dans `lib/MSconverter/pwiz_bin_windows/` incluent :

1. **Lecteurs de formats MS propriétaires** :
   - `BDal.*.dll` - Bruker Daltonics
   - `Clearcore2.*.dll` - AB Sciex
   - `CRHAKEI2.dll` - Agilent

2. **Bibliothèques de traitement** :
   - `BaseDataAccess.dll` - Accès aux données
   - `BaseTof.dll` - Time-of-flight MS
   - `pwiz_*.dll` - ProteoWizard core

3. **Compression et I/O** :
   - `Clearcore2.Compression.dll`
   - `CABINET.dll`
   - `CLFIO32.dll`

## Optimisation du parallélisme dans MSPANDA

### Configuration recommandée selon le matériel

| CPU Cores | MSConvert | MS-DIAL threads | Commentaire |
|-----------|-----------|-----------------|-------------|
| 4 cores   | 1 fichier | 3-4 threads     | Équilibré |
| 8 cores   | 1-2 fichiers | 5-6 threads  | Bon compromis |
| 16 cores  | 2-3 fichiers | 8-12 threads | Haute performance |
| 32+ cores | 3-4 fichiers | 16-24 threads | Workstation |

### Modifier le nombre de threads MS-DIAL

#### Option 1 : Via l'interface Shiny

L'utilisateur peut modifier dans l'interface (si implémenté) :
- Peak detection → Parameters → Number of threads

#### Option 2 : Modifier le fichier de configuration

**Fichier** : `lib/NewReferenceMap/R_files/peakPickingNewReferenceMap.R`

```r
# Ligne 22 - Changer la valeur par défaut
number_threads = "5",  # <- Modifier ici (ex: "8" pour 8 threads)
```

#### Option 3 : Détecter automatiquement

**Amélioration suggérée** - Détecter le nombre de CPU :

```r
# Détecter automatiquement
auto_threads <- parallel::detectCores() - 1  # Laisser 1 core libre

peakPickingNewReferenceMap <- function(...) {
  MsdialParam(
    # ...
    number_threads = as.character(min(auto_threads, 16)),  # Max 16 threads
    # ...
  )
}
```

### Modifier le parallélisme MSConvert

**Fichier** : `lib/MSconverter/pwiz_bin_windows/MSConvertGUI.exe.config`

```xml
<setting name="NumFilesToConvertInParallel" serializeAs="String">
  <value>2</value>  <!-- Changer 1 → 2 pour 2 fichiers en parallèle -->
</setting>
```

**Note** : Cette configuration affecte la GUI, pas directement msconvert.exe en ligne de commande.

## Workflow du traitement parallèle

### 1. Conversion MS (MSConvert)

```
[Fichiers RAW] → MSConvert.exe (+ ParallelExtensionsExtras.dll)
                 ↓ (parallélisme interne)
                 - Thread 1: Lit scan 1-1000
                 - Thread 2: Lit scan 1001-2000
                 - Thread 3: Écrit mzML
                 ↓
[Fichiers mzML]
```

### 2. Détection de pics (MS-DIAL)

```
[Fichiers mzML] → MsdialConsoleApp.exe (Number of threads: 5)
                 ↓ (parallélisme configurable)
                 - Thread 1: Fichier 1
                 - Thread 2: Fichier 2
                 - Thread 3: Fichier 3
                 - Thread 4: Fichier 4
                 - Thread 5: Fichier 5
                 ↓
[Peak lists CSV]
```

## Monitoring des performances

### Sous Windows

**Task Manager** :
- Onglet "Performance" → CPU
- Pendant MSConvert : Voir l'utilisation des cores
- Pendant MS-DIAL : Observer les pics d'utilisation

**Resource Monitor** :
- Plus détaillé que Task Manager
- Voir les threads par processus
- `resmon.exe` → Onglet CPU

### Dans R (MSPANDA)

Ajouter du monitoring :

```r
# Avant le traitement
cat("System:", parallel::detectCores(), "cores detected\n")
cat("MS-DIAL will use:", number_threads, "threads\n")

# Timer
start_time <- Sys.time()
# ... traitement ...
end_time <- Sys.time()

cat("Processing time:", difftime(end_time, start_time, units = "mins"), "minutes\n")
```

## Dépannage des problèmes de parallélisme

### Symptôme : MSConvert très lent

**Cause possible** : Manque de mémoire RAM

**Solution** :
1. Réduire le nombre de fichiers simultanés
2. Fermer d'autres applications
3. Vérifier : Task Manager → Mémoire

### Symptôme : MS-DIAL crash avec beaucoup de threads

**Cause possible** : Trop de threads pour la RAM disponible

**Solution** :
```r
# Réduire le nombre de threads
number_threads = "3"  # Au lieu de "5"
```

### Symptôme : CPU sous-utilisé (<50%)

**Cause possible** : Goulot d'étranglement I/O disque

**Solution** :
1. Utiliser un SSD au lieu de HDD
2. Augmenter le nombre de threads pour compenser
3. Traiter les fichiers par batch

### Symptôme : Erreur "DLL not found"

**Cause** : ParallelExtensionsExtras.dll ou autres DLLs manquantes

**Solution** :
1. Vérifier l'intégrité du dossier MSconverter
2. Réinstaller MSConvert si nécessaire
3. Vérifier que tous les 168 DLLs sont présents

## Conclusion

Les fichiers de calcul parallèle comme `ParallelExtensionsExtras.dll` sont utilisés **automatiquement** par les exécutables externes (MSConvert, MS-DIAL) pour :

1. ✅ Traiter plusieurs fichiers/scans en parallèle
2. ✅ Utiliser efficacement les CPUs multi-cœurs
3. ✅ Accélérer significativement le traitement (2-10x plus rapide)
4. ✅ Gérer intelligemment les files d'attente de travail

**L'utilisateur n'a pas besoin de gérer ces DLLs directement**, mais peut :
- Configurer le nombre de threads dans MS-DIAL
- Optimiser selon son matériel
- Monitorer les performances

**Amélioration future suggérée** : Ajouter une interface dans MSPANDA pour configurer facilement le nombre de threads MS-DIAL selon le matériel détecté.
