---
name: github-issue-generator
description: Créer des issues GitHub structurées en français. Utilise ce skill lorsque l'utilisateur demande de créer une issue, de signaler un bug ou de documenter une nouvelle tâche à faire sur GitHub.
---

# GitHub Issue Generator

## Instructions
Utilise ce skill pour générer le titre, le corps et les labels d'une issue GitHub en français. Analyse le contexte de la conversation ou les erreurs de code pour remplir les sections.

### Structure de l'Issue
L'issue doit être rédigée en **français** et suivre cette structure :

1. **Titre** : Clair et concis (ex: `bug: Correction du calcul de dégâts`).
2. **Description** :
   - **## Contexte** : Pourquoi cette issue est créée ? Quel est le problème ou le besoin ?
   - **## Détails techniques** : (Si applicable) Quelles parties du code sont concernées ?
   - **## Étapes pour reproduire / Critères d'acceptation** :
     - Pour un bug : liste des étapes.
     - Pour une feature : liste des points à valider.
3. **Labels** : Choisis parmi la liste officielle ci-dessous.

## Labels Disponibles
- `bug` : Quelque chose ne fonctionne pas.
- `feature` : Nouvelle fonctionnalité.
- `refactor` : Modification ou réécriture d'une fonctionnalité existante.
- `ui` : Travail sur l'interface graphique.
- `enemies` : Travail sur les ennemis.
- `towers` : Travail sur les tours.
- `level` : Travail sur les niveaux.
- `map` : Travail sur la carte.
- `bullet` : Travail sur les projectiles.
- `cannon` : Travail sur les canons.
- `documentation` : Travail sur la documentation.
- `tests` : Travail sur les tests unitaires.
- `tweak` : Ajustement des valeurs d'une fonctionnalité.
- `POC` : Preuve de concept.
- `help wanted` : Attention particulière requise.
- `invalid` : Ne semble pas correct.

## Exemple d'utilisation

**Commande suggérée :**
```bash
gh issue create --title "bug: La barre fantôme ne s'affiche pas lors de dégâts rapides" --body "## Contexte
Lorsqu'un deuxième zombie inflige des dégâts avant que la première animation de barre fantôme ne soit terminée, l'effet visuel est annulé.

## Détails techniques
Fichier : \`scenes/ui/menus/hud/hud.gd\`
Le Tween précédent doit être tué avant d'en créer un nouveau.

## Étapes pour reproduire
1. Lancer un niveau.
2. Faire en sorte que deux ennemis atteignent la fin du chemin à moins de 0.3s d'intervalle.
3. Observer que la barre fantôme ne fait pas l'effet de traînée pour le deuxième coup." --label "bug,ui"
```

## Workflow
1. Analyse le besoin de l'utilisateur.
2. Propose le titre, la description et les labels.
3. Demande confirmation avant d'exécuter la commande `gh issue create`.
