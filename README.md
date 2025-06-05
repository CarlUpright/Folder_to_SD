# Folder to SD Card Copier

Un script Windows pour copier facilement un dossier vers des cartes SD multiples avec gestion automatique de l'éjection et de la boucle.

## Installation

1. Téléchargez le fichier `Folder_to_SD.cmd`
2. Placez-le dans un dossier facilement accessible
3. Voir la section "Déblocage Windows" ci-dessous si le fichier est bloqué

## Utilisation

### Démarrage
- Double-cliquez sur `Folder_to_SD.cmd` pour lancer le script
- Une fenêtre de terminal s'ouvrira avec l'interface du script

### Workflow complet

#### 1. Configuration initiale
- **Source folder** : Entrez le chemin complet du dossier à copier
  - Avec ou sans guillemets : `C:\Mon Dossier` ou `"C:\Mon Dossier"`
  - Supporte les caractères accentués (é, è, ç, etc.)

#### 2. Sélection de la carte SD
- Le script liste automatiquement tous les lecteurs amovibles détectés
- Affiche : numéro, lettre de lecteur, capacité en GB, et nom de volume
- Exemple : `1. E: - 59.5 GB - H3VR_SD`
- Entrez le numéro correspondant à votre carte SD

#### 3. Options de fonctionnement
- **Export device after copying?** (Défaut: Y)
  - `Y` : Éjecte automatiquement la carte après copie
  - `N` : Laisse la carte connectée
  
- **Loop operation?** (Défaut: Y)
  - `Y` : Redémarre automatiquement pour la carte suivante
  - `N` : Arrête après une seule copie

#### 4. Processus de copie
- Affiche les chemins source et destination
- Lance robocopy avec les paramètres : `/MIR /COPY:DAT /DCOPY:T /R:3 /W:5`
- Montre la progression complète de robocopy en temps réel
- Vérifie le succès de l'opération

#### 5. Gestion automatique des cartes (mode boucle)

##### Si éjection activée :
1. **Capture de l'ID** : Mémorise l'identifiant unique de la carte actuelle
2. **Éjection sécurisée** : Éjecte la carte proprement via Windows
3. **Attente de retrait** : Vérifie que la carte est physiquement retirée
4. **Attente nouvelle carte** : Surveille l'insertion d'une nouvelle carte
5. **Vérification d'unicité** : S'assure que c'est une carte différente (ID unique)
6. **Contrôle de capacité** : 
   - Même capacité → démarre automatiquement la copie
   - Capacité différente → demande confirmation à l'utilisateur
7. **Redémarrage** : Lance la copie pour la nouvelle carte

##### Messages d'état :
- `Getting current SD card ID...` : Capture de l'identifiant
- `Device ejected safely.` : Éjection réussie
- `Waiting for card to be removed...` : Attente du retrait physique
- `Card removed. Waiting for new SD card...` : Prêt pour nouvelle carte
- `New SD card detected with same capacity.` : Nouvelle carte compatible
- `Warning: Different capacity SD card detected!` : Alerte capacité

#### 6. Gestion d'erreurs
- **Dossier source introuvable** : Redemande le chemin
- **Aucun lecteur amovible** : Attend l'insertion d'une carte
- **Échec robocopy** : Arrête l'opération et affiche le code d'erreur
- **Capacité différente** : Demande confirmation avant de continuer

## Déblocage Windows

Si Windows bloque l'exécution du fichier .cmd :

### Méthode 1 : Propriétés du fichier
1. **Clic droit** sur `Folder_to_SD.cmd`
2. Sélectionnez **"Propriétés"**
3. En bas de l'onglet "Général", si vous voyez :
   ```
   Sécurité : Ce fichier provient d'un autre ordinateur et peut être bloqué
   pour protéger cet ordinateur.
   [✓] Débloquer
   ```
4. **Cochez "Débloquer"**
5. Cliquez **"OK"**
6. Essayez de relancer le script

### Méthode 2 : Exécution manuelle
1. Appuyez sur **Windows + R**
2. Tapez `cmd` et appuyez sur **Entrée**
3. Naviguez vers le dossier contenant le script :
   ```cmd
   cd "C:\chemin\vers\votre\dossier"
   ```
4. Exécutez le script :
   ```cmd
   Folder_to_SD.cmd
   ```

### Méthode 3 : PowerShell (si cmd bloqué)
1. Appuyez sur **Windows + X**
2. Sélectionnez **"Windows PowerShell"**
3. Naviguez vers le dossier :
   ```powershell
   cd "C:\chemin\vers\votre\dossier"
   ```
4. Exécutez :
   ```powershell
   .\Folder_to_SD.cmd
   ```

### Méthode 4 : Politique d'exécution (administrateur)
1. **Clic droit** sur "Invite de commandes" → **"Exécuter en tant qu'administrateur"**
2. Tapez :
   ```cmd
   powershell Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Confirmez avec `Y`
4. Essayez de relancer le script normalement

## Fonctionnalités techniques

- **Support Unicode** : Gère les caractères accentués dans les chemins
- **Détection robuste** : Identifie les lecteurs amovibles via WMI
- **ID unique** : Utilise le VolumeSerialNumber pour différencier les cartes
- **Gestion d'erreurs** : Validation des entrées et codes de retour robocopy
- **Interface intuitive** : Messages clairs et options par défaut pratiques

## Notes importantes

- Le script utilise la commande robocopy exacte sans modification
- Fonctionne avec toutes les tailles de cartes SD (support des grandes capacités)
- Respecte le timing nécessaire pour le changement physique des cartes
- Arrêt d'urgence possible avec **Ctrl+C** à tout moment
- Compatible Windows 10/11 avec PowerShell intégré

## Dépannage

**"Nombre non valide" lors du listage** : Carte SD de très grande capacité → le script utilise maintenant PowerShell pour le calcul

**"Robocopy failed with error code X"** : Vérifiez que la carte SD n'est pas protégée en écriture

**"Same card detected, waiting for a different one"** : Le script détecte la même carte, retirez-la complètement avant d'insérer la suivante

**Script ne démarre pas en boucle** : Vérifiez que l'éjection automatique est activée (Y) pour le mode boucle
