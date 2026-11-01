# AI Business Intelligence : assistant décisionnel intelligent

Application mobile Flutter qui accompagne la [plateforme décisionnelle de ventes](https://github.com/YoussefBecher/Plateforme-decisionnelle-ventes) : indicateurs, prévisions, alertes et assistant conversationnel pour interroger les données.

**Technologies** : Flutter, Dart (aucune dépendance externe).

## Fonctionnalités

| Écran | Contenu |
|---|---|
| Tableau | Six KPI (CA, marge, marge %, panier moyen, réalisation des objectifs, croissance mensuelle), courbe du CA, classement des régions, produits les plus rentables. Filtres par année et par région. |
| Prévisions | Prévision du CA par mois (6 mois, intervalle de confiance) ou par semaine (estimation répartie), avec courbe interactive. |
| Alertes | Détection des baisses de CA, des régions en retard sur leurs objectifs, des produits à faible marge et des baisses prévues, avec une recommandation pour chacune. |
| Assistant | Questions en français sur les données : « chiffre d'affaires en mars 2026 », « meilleure région », « marge à Sfax », « alertes »... |

## Comment ça marche

- Les données (ventes, objectifs, prévision Holt-Winters) sont embarquées dans `assets/data.json`, exportées depuis le pipeline Python du projet principal.
- L'assistant fonctionne **sans connexion ni clé d'API** : il reconnaît l'intention de la question, repère la période et la région citées, puis calcule la réponse sur les données.
- Les alertes appliquent des règles simples et documentées dans `lib/alerts.dart` (baisse du CA de plus de 5 % ou 10 %, objectif sous 90 % ou 80 %, taux de marge de plus de 3 points sous la moyenne, baisse prévue de plus de 8 %).

## Lancer l'application

Prérequis : Flutter 3.22 ou plus.

```bash
flutter create --project-name ai_business_intelligence .   # génère les dossiers android, ios...
flutter pub get
flutter run
```

## Structure

```
lib/
  main.dart             navigation et chargement des données
  data.dart             modèle de données et agrégations
  dashboard_page.dart   tableau de bord
  forecast_page.dart    prévisions mensuelles et hebdomadaires
  alerts.dart           règles de détection
  alerts_page.dart      écran des alertes
  assistant.dart        moteur de réponses
  assistant_page.dart   interface de discussion
  charts.dart           courbe dessinée avec CustomPaint
assets/data.json        données de démonstration
```

## Limites

- Les données sont générées pour la démonstration (voir le projet principal).
- La prévision hebdomadaire est une estimation : le modèle est mensuel.
- L'assistant comprend un ensemble défini de questions ; il ne s'agit pas d'un modèle de langage.

## Pistes d'amélioration

- Connecter l'application à la base PostgreSQL via une petite API.
- Brancher un modèle de langage pour des réponses libres.
- Notifications push pour les alertes critiques.
