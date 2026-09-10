# Guide opérationnel 04 : Suspension d'urgence de l'émission

## Objectif

Suspendre la création de nouveaux **CBDT (Central Bank Digital Token)** lorsque l'intégrité monétaire est menacée par une émission non autorisée, un écart de réconciliation de l'offre, une compromission de clé de signature, une vulnérabilité de contrat intelligent ou un autre incident majeur.

Ce guide décrit le processus générique CentralBank. L'autorité habilitée à ordonner ou approuver la suspension est définie par le profil de déploiement et le modèle de gouvernance actifs.

## Préconditions

1. Une condition confirmée ou crédible nécessitant la suspension de l'émission.
2. Un accès authentifié au plan de contrôle institutionnel.
3. L'autorité d'urgence ou de contrôle d'émission requise pour le contrat ou contrôleur concerné.
4. Une référence d'incident/dossier et une preuve d'approbation enregistrée.

## Étapes d'exécution

### 1. Déterminer la portée de la suspension

Déterminer si l'incident nécessite uniquement la pause de l'émission via `MintBurnControllerV2`, la pause du `DigitalToken` actuel, ou une suspension plus large des transferts si l'intégrité du grand livre est mise en doute. Utiliser le contrôle le plus limité permettant de contenir l'incident en toute sécurité.

### 2. Exécuter la pause approuvée

Pour les déploiements utilisant le point de terminaison global actuel du gateway :

```bash
curl -X POST "https://[internal-gateway]/api/v1/admin/system/pause" \
     -H "X-API-KEY: [AUTHORIZED_KEY]"
```

Le déploiement peut également exiger le mTLS institutionnel et la signature des requêtes.

Lorsque le contrôleur modulaire d'émission/rémission est déployé, privilégier sa pause dédiée de l'émission si seuls les nouveaux mint doivent être interrompus et que les transferts/rémissions peuvent continuer en toute sécurité.

### 3. Vérifier l'état on-chain

Confirmer directement l'état de pause concerné sur le contrat/contrôleur déployé et enregistrer le reçu de transaction ainsi que la hauteur de bloc.

### 4. Informer les participants

La notification opérationnelle doit indiquer au minimum la fonction suspendue, l'heure d'effet, le comportement attendu des participants, la disponibilité des transferts/rémissions, la référence d'incident et le canal de mise à jour.

Ne pas prétendre qu'une notification automatique existe si le déploiement ne fournit pas et ne vérifie pas réellement ce mécanisme.

## Réconciliation pendant la suspension

Poursuivre la réconciliation et la conservation des preuves. Enregistrer notamment la dernière offre totale valide connue, les opérations d'émission/rémission autorisées, les transactions ou opérations non reconnues, ainsi que les données pertinentes liées aux signataires, KMS et nœuds.

Un écart d'offre inexpliqué ne doit pas être traité comme une simple correction comptable.

## Reprise sûre de l'émission

1. Réaliser une analyse suffisante de la cause ou contenir la menace.
2. Réconcilier l'offre totale et toutes les opérations d'émission/rémission de la fenêtre d'incident.
3. Vérifier l'intégrité des signataires et autorités ; faire tourner toute autorité compromise avant la reprise.
4. Obtenir l'approbation requise par le profil de déploiement.
5. Réactiver uniquement les contrôles réellement suspendus.
6. Si approprié, effectuer une petite opération de validation autorisée.
7. Confirmer à nouveau une réconciliation exacte.

Pour une reprise globale du gateway :

```bash
curl -X POST "https://[internal-gateway]/api/v1/admin/system/unpause" \
     -H "X-API-KEY: [AUTHORIZED_KEY]"
```

## Gestion des échecs

- **Autorité d'émission compromise :** révoquer ou faire tourner l'autorité via la gouvernance avant de rétablir la capacité d'émission.
- **Offre non réconciliable :** rester en suspension et escalader ; ne pas normaliser un écart inexpliqué.
- **Vulnérabilité de contrat :** maintenir les chemins affectés en pause jusqu'à validation du correctif et du plan de déploiement/migration.
- **Partition réseau :** ne pas émettre indépendamment dans des partitions isolées sauf si le profil prévoit explicitement une procédure sûre et réconciliable.

## Artefacts d'audit

Les preuves attendues comprennent les reçus et événements de pause/reprise, la référence d'incident et d'approbation, l'identité institutionnelle de l'acteur, le rapport de réconciliation de l'offre, les preuves d'intégrité des signataires/autorités et les résultats de validation de reprise.

## Profil de référence Eurosystème

Un déploiement orienté Eurosystème peut mapper la chaîne d'approbation sur des autorités BCE/BCN ou des autorités d'urgence déléguées. Ce mapping est spécifique au profil et ne constitue pas une autorité conférée par le logiciel CentralBank lui-même.

CentralBank et CBDT ne sont ni émis, ni approuvés, ni parrainés, ni exploités par la Banque centrale européenne, l'Eurosystème ou une banque centrale nationale.
