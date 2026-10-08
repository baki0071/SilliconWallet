# Référentiel frontend — Silicon Wallet

Ce document décrit les choix visibles dans `index.html` et `style.Css` à la racine du projet. Il distingue ce qui est déjà présent de ce qui n'est pas encore implémenté.

## Couleurs

La page utilise un thème clair, avec une palette sobre et des accents violets :

| Rôle | Valeur observée |
| --- | --- |
| Texte principal | `#24212b`, `#272132`, `#292332` |
| Texte secondaire | `#68616f`, `#716b78`, `#77717e` |
| Accent violet | `#75539c`, `#7652a2`, `#725193` |
| Fond principal | `#ffffff` |
| Fond lavande / sections | `#f0edf4`, `#f7f5f8`, `#eee9f3` |
| CTA sombre et footer | `#292332`, `#30283c` |
| Accents complémentaires | verts doux pour certains indicateurs, beige pour l'illustration d'objectif |

La première section conserve également son motif SVG lavande. Les logos et plateformes de démonstration sont volontairement gris et discrets.

## Typographie

- Police système : `Arial, Helvetica, sans-serif`.
- Texte courant : taille de base héritée du navigateur, interligne `1.6`.
- Titres principaux : tailles adaptatives avec `clamp()` (par exemple, titre du hero de `34px` à `58px`).
- Titres de section : environ `28px` à `42px`, également adaptatifs.
- Labels : petits caractères violets en majuscules, gras, avec espacement des lettres (`letter-spacing: 1.5px`).
- Les liens, boutons et descriptions utilisent principalement des tailles de `12px` à `17px`.

Aucune police web externe n'est chargée.

## Espacements

Les espacements sont définis directement en pixels et pourcentages dans les règles CSS ; il n'y a pas encore d'échelle centralisée de variables CSS.

Quelques repères actuels :

- En-tête : hauteur minimale de `72px`, avec marges horizontales de `8%`.
- Sections fonctionnalités et témoignages : largeur maximale de `1120px`, padding vertical de `100px` sur grand écran.
- Espacement entre les fonctionnalités : `78px`.
- Cartes : padding de `24px` à `26px`, espacement de grille de `20px`.
- Sur mobile : sections réduites à `70px` de padding vertical et écart de `25px` dans les fonctionnalités.

## Rayons

- Boutons : `6px`.
- Petites cartes : `8px` à `13px`.
- Cartes/illustrations principales et bannières CTA : `16px` à `18px`.
- Avatars et éléments circulaires : `50%`.

## Ombres

Les ombres sont légères et de teinte violette/noire, avec opacité réduite :

- En-tête : `0 2px 14px rgba(30, 20, 45, 0.06)`.
- Cartes : ombre douce, par exemple `0 8px 24px rgba(45, 35, 55, 0.05)`.
- CTA intermédiaire : ombre plus présente, `0 18px 40px rgba(48, 40, 60, 0.18)`.
- Illustration vidéo et cartes illustrées : ombres plus marquées afin de les distinguer du fond.

## Animations et interactions visuelles

- Défilement fluide pour les liens d'ancrage (`scroll-behavior: smooth`).
- Soulignement animé au survol des liens du menu (`transition: width 0.3s ease`).
- Les boutons remontent légèrement au survol et changent de couleur (`transition: transform 0.2s ease, background-color 0.2s ease`).
- Les liens du footer changent de couleur au survol.
- Il n'y a pas d'animation d'entrée, de chargement ou de mouvement continu déclarée.

## Skeleton design et chargement

Aucun skeleton/loading placeholder n'est actuellement implémenté. Les illustrations des fonctionnalités sont des maquettes statiques en HTML/CSS ; elles ne représentent pas un chargement réel de données.

La vidéo du hero utilise `autoplay`, `loop`, `muted` et `playsinline`. Aucun écran de remplacement spécifique à son chargement ou à une erreur de lecture n'est prévu au-delà du texte de secours HTML.

## Règles de validation et comportement

- La page est une landing page statique : aucun formulaire de connexion, d'inscription ou de saisie financière n'est présent.
- Il n'y a donc pas de règles de validation de formulaire côté HTML ou JavaScript (champs requis, format, messages d'erreur, etc.).
- Les liens de navigation pointent vers des ancres internes. Les boutons « En savoir plus » et les CTA font défiler vers les sections de la page.
- Le bouton d'en-tête « Se connecter » pointe actuellement vers la section Contact ; il ne déclenche pas une véritable authentification.
- Les noms de partenaires, témoignages et statistiques de la page sont fictifs et accompagnés d'indications de démonstration.

## Jauge de robustesse du mot de passe

Non implémentée : la page ne comporte ni champ mot de passe, ni inscription, ni jauge de robustesse. Les critères d'un futur formulaire devront être définis avant d'ajouter cette fonctionnalité.

## Thème clair / sombre

Seul le thème clair est actuellement stylisé. Il n'y a ni bouton de bascule, ni thème sombre, ni détection de préférence système (`prefers-color-scheme`).

## Architecture Atomic Design

Le projet ne met pas formellement en œuvre Atomic Design : il s'agit d'une page HTML et d'une feuille CSS, sans composants réutilisables séparés.

À titre de lecture de la page, les éléments pourraient être classés ainsi :

- **Atomes** : liens, boutons, labels, texte, pastilles/avatar.
- **Molécules** : carte de témoignage, carte d'illustration, groupe de boutons d'action.
- **Organismes** : en-tête, lignes de fonctionnalités, grille de témoignages, CTA, footer.
- **Templates/pages** : la page d'accueil complète de Silicon Wallet.

Cette liste est un repérage conceptuel des éléments présents, pas une architecture déjà extraite ou appliquée dans le code.

## Icônes

Aucune bibliothèque d'icônes ni aucun fichier d'icônes SVG dédié n'est utilisé. Les symboles visibles (`→`, `✦`, `◈`, etc.) sont des caractères Unicode placés dans le HTML. Les indicateurs graphiques des fonctionnalités sont dessinés avec des éléments HTML et du CSS.

## Responsive

- À `760px` et moins : navigation réorganisée, fonctionnalités en une colonne, témoignages en une colonne et footer en deux colonnes.
- À `420px` et moins : menu et logo réduits, actions du hero empilées et bas de page réorganisé.
- Les groupes de logos/statistiques peuvent revenir à la ligne.
