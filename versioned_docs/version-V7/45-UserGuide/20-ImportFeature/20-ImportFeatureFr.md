---
sidebar_position: 21
---

# fr - Fonctionnalité d'import
La fonctionnalité d'import de données permet d'ajouter, mettre à jour et/ou supprimer des données en masse dans l'écran concerné.
Les exemples ci-après utiliseront les **Avions** comme données de référence.

## Commençons par exporter
Avant d'importer des données en masse, il peut-être intéressant de récupérer le fichier complet de la liste des données actuelle.
Afin de réaliser un export et de conservé le lien entre la donnée contenu dans le site et la donnée du fichier exporté, une colonne *Id* (pour idnetifiant) doit être ajouté au fichier exporté.
Afin de réaliser cet export, un bouton à cet effet est disponible dans le menu en haut à droite de la liste de données :
![ExporterPourImport](../../Images/Tuto/Import/ExportForImportButtonFr.png)

Le fichier qui est téléchargé peut ensuite être ouvert dans Excel et sert de base pour l'ajout, la modification ou la suppression d'information.
![ExportExcel](../../Images/Tuto/Import/ExportExcel.png)

## Importer des données
### Ajouter de nouvelles données
Afin d'ajouter une nouvelle ligne de données (dans l'exemple: un nouvel avion), il suffit d'ajouter une nouvelle ligne à la liste des données Excel sans renseigner de valeur dans la première colonne (id).
![NewLine](../../Images/Tuto/Import/NewLine.png)

### Modifier des données
Afin de modifier une ligne de données existante, il suffit de modifier la ou les données de la ligne dans les données Excel tout en concervant l'id en première colonne.

### Supprimer des données
Afin de supprimer une ligne de données existante, vous pouvez supprimer la ligne de données du fichier excel. 
*Si vous souhaiter supprimer la ligne et en créer une nouvelle similaire, vous pouvez également supprimer l'identifiant de la première colonne et modifier les colonnes que vous souhaitez. La disparition de l'id considérera la ligne comme supprimée et effectuera un ajout en trouvant la ligne sans identifiant.*

### Importer le fichier Excel
Une fois que vos modifications sont terminées, vous pouvez sauvegarder le fichier excel (en tant que fichier .csv) et le réimporter dans l'application.
Pour ce faire, cliquez sur la le bouton d'import dans le menu en haut à droite de la liste de données :
![Importer](../../Images/Tuto/Import/ImportButtonFr.png)

La fenêtre d'import va s'ouvrir vous demandant de renseigner certaines informations :
1) le fichier contenant les données à importer
2) le format de date utilisé dans Excel (jour/mois/année, mois/jour/année ou jour.mois.année)
3) le format d'heure utilisé dans Excel
4) option pour n'appliquer l'import que sur les données actuellement filtrées dans l'écran

Une fois ces informations renseignées, cliquez sur **Analyser** afin de lire le fichier et de vérifier la cohérence des données.

En fonction des écrans, certaines fonctionnalités peuvent ne pas être disponible (ajout, modification ou suppression).
#### Ajout
Si la fonctionnalité d'ajout est activée, les nouvelles lignes du fichier excel vont apparaitre dans la section **A Ajouter**
Cette liste contient le récapitulatif de toute les nouvelles lignes (identifiant vide) détectées et valides dans le fichier Excel.

Si vous êtes satisfait des données détectées, vous pouvez cocher la case située à côté de **A Ajouter** afin d'indiquer de prendre en compte ces ajouts à la sauvegarde.
![AAjouter](../../Images/Tuto/Import/ToAddFr.png)

#### Modification
Si la fonctionnalité de modification est activée, les lignes modifiées du fichier excel vont apparaitre dans la section **A Modifier**
Cette liste contient le récapitulatif de toute les lignes modifiées détectées et valides dans le fichier Excel.

Si vous êtes satisfait des données détectées, vous pouvez cocher la case située à côté de **A Modifier** afin d'indiquer de prendre en compte ces modifications à la sauvegarde.

#### Suppression
Si la fonctionnalité de suppression est activée, les lignes supprimées du fichier excel vont apparaitre dans la section **A Supprimer**
Cette liste contient le récapitulatif de toute les lignes supprimées détectées dans le fichier Excel.

Si vous êtes satisfait des données détectées, vous pouvez cocher la case située à côté de **A Supprimer** afin d'indiquer de prendre en compte ces suppressions à la sauvegarde.

#### Traitement des erreurs
Si des erreurs ont été détectées dans les données du fichiers excel, la liste de ces erreurs sera affichée dans la section **Erreur(s)**.
Des informations sur la ou les erreurs détectées sur chaque ligne est disponible dans la dernière colonne du tableau (si vous avez beaucoup de colonne, un défilement horizontal est disponible).
Exemple d'erreurs détectées pour un import :
![ImportErrors](../../Images/Tuto/Import/ImportErrorsFr.png)
- le champ firstFlightDate (Date du premier vol) obligatoire n'a pas été renseigné (firstFlightDate -> Date du premier vol).
- le format du champ nextMaintenanceDate (Prochaine date de maintenance) pour cette ligne est incorrect.

#### Appliquer les modifications
Une fois que vous avez terminé, vous pouvez appliquer les modifications en cliquant sur le bouton **Appliquer** en bas à droite de la fenêtre.