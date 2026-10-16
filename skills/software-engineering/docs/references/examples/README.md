# Stargate — Portail ERP Raccourci

Interface interne de gestion centralisée pour **Raccourci**, connectée à l'ERP Odoo. Stargate unifie la gestion des clients, des contacts, des produits, des deals, des projets, des factures et du suivi du temps dans une seule application web.

---

## Sommaire

- [Vue d'ensemble](#vue-densemble)
- [Stack technique](#stack-technique)
- [Architecture du projet](#architecture-du-projet)
- [Pages & routes](#pages--routes)
- [Authentification](#authentification)
- [Installation & développement](#installation--développement)
- [Scripts disponibles](#scripts-disponibles)
- [Configuration](#configuration)
- [Tests](#tests)
- [Documentation](#documentation)
- [Contribuer](#contribuer)
- [IDE recommandé](#ide-recommandé)

---

## Vue d'ensemble

Stargate est un portail front-end SPA (Single Page Application) qui expose les données de l'ERP Odoo à travers une couche API propre. Il fonctionne en deux environnements :

| Environnement | Domaine                   | ERP cible                    |
| ------------- | ------------------------- | ---------------------------- |
| Production    | `stargate.raccourci.fr`   | `https://erpv8.raccourci.fr` |
| Preprod       | `stargate.rc-preprod.com` | `https://erp.rc-preprod.com` |

L'environnement est détecté automatiquement à partir de `window.location.origin`.

---

## Stack technique

| Technologie                                                             | Rôle                                                                                               |
| ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [Vue 3](https://vuejs.org/) (Composition API)                           | Framework UI                                                                                       |
| [Vue Router 5](https://router.vuejs.org/)                               | Routing côté client (hash history)                                                                 |
| [TypeScript ~5.9](https://www.typescriptlang.org/)                      | Typage statique                                                                                    |
| [Vite 8](https://vite.dev/)                                             | Build tool & dev server                                                                            |
| [Tailwind CSS 4](https://tailwindcss.com/)                              | Styles utilitaires                                                                                 |
| [shadcn-vue](https://www.shadcn-vue.com/)                               | Composants UI (style _new-york_, `src/components/ui/`, primitives [Reka UI](https://reka-ui.com/)) |
| [Zod](https://zod.dev/)                                                 | Validation de schémas à l'exécution                                                                |
| [Luxon](https://moment.github.io/luxon/)                                | Manipulation des dates                                                                             |
| [Lucide Vue Next](https://lucide.dev/)                                  | Icônes                                                                                             |
| [Floating UI](https://floating-ui.com/)                                 | Tooltips & popovers                                                                                |
| [Vitest](https://vitest.dev/) + [jsdom](https://github.com/jsdom/jsdom) | Tests unitaires                                                                                    |
| [Playwright](https://playwright.dev/)                                   | Tests E2E (navigateur réel)                                                                        |

---

## Architecture du projet

```
src/
├── assets/          # CSS global (Tailwind entry point)
├── components/      # Composants réutilisables
│   ├── entities/    # Composants liés aux entités métier
│   ├── fields/      # Champs éditables ORM (FieldTextField, FieldMany2One, …)
│   ├── input/       # Primitives d'interface (Button, Select, DatePicker, …)
│   ├── tables/      # Tableaux spécialisés
│   └── ui/          # shadcn-vue (Button, DropdownMenu, …) + layout partagé (AppHeader, SideMenu, …)
├── composables/     # Logique métier réutilisable (hooks Vue)
├── router/          # Configuration des routes et garde d'authentification
├── types/           # Types TypeScript & schémas Zod
├── utils/           # Utilitaires généraux
└── pages/           # Pages de l'application
    ├── accounts/
    ├── contact/
    ├── deals/
    ├── fairguest/
    ├── partner/
    ├── products/
    └── sheet/
```

### Composables clés

| Composable        | Rôle                                                       |
| ----------------- | ---------------------------------------------------------- |
| `useSession`      | Singleton global de l'utilisateur authentifié              |
| `useORMApi`       | Couche de requêtes ORM typée (search/read via Zod)         |
| `useORMUI`        | Écriture inline sur les entités ORM avec retour toast      |
| `useAPI`          | Wrappers fetch avec gestion d'erreurs centralisée          |
| `useOdoo`         | Génération d'URLs vers le back-office Odoo                 |
| `useGlobalSearch` | État de la modale de recherche globale (Ctrl+K)            |
| `useToast`        | File de notifications toast (expiration auto 10 s)         |
| `useTheme`        | Dark mode (préférence système + persistance localStorage)  |
| `useBreadcrumb`   | Gestion du fil d'Ariane                                    |
| `useApplications` | Catalogue des applications clientes (FairGuest, Django, …) |

### Composants de boundary ORM

- **`ORMEntityBoundary`** — récupère une entité par `id`, gère les états loading/erreur, expose `{ entity, type }` via slot
- **`ORMEntityListBoundary`** — récupère une liste paginée, expose `{ entities, pageSize, loading }` via slot

---

## Pages & routes

| Route                      | Vue                        | Description                              |
| -------------------------- | -------------------------- | ---------------------------------------- |
| `/`                        | —                          | Redirige vers `/customer`                |
| `/customer`                | `CustomerListPage`         | Liste paginée des clients (kanban)       |
| `/customer/:id`            | `CustomerProfilePage`      | Profil client (shell à onglets)          |
| `/customer/:id/about`      | `CustomerProfileAboutPage` | Infos client, responsables, fiches SIT   |
| `/customer/:id/products`   | `CustomerProductsPage`     | Produits souscrits                       |
| `/customer/:id/sale-order` | `CustomerSaleOrder`        | Bons de commande                         |
| `/customer/:id/deals`      | `CustomerDealsPage`        | Deals associés                           |
| `/customer/:id/projects`   | `CustomerProjectsPage`     | Projets associés                         |
| `/customer/:id/invoices`   | `CustomerInvoicePage`      | Factures                                 |
| `/customer/type/:id`       | `CustomerTypeDetailPage`   | Type de client                           |
| `/contact/:id`             | `ContactPage`              | Profil contact / employé                 |
| `/product/instance/:id`    | `ProductInstancePage`      | Instance produit                         |
| `/product/type/:id`        | `ProductConfigTypePage`    | Type de configuration produit            |
| `/deal`                    | `DealListPage`             | Liste des deals                          |
| `/fairguest-group/:id`     | `FairguestGroupPage`       | Groupe FairGuest                         |
| `/external-account/:id`    | `ExternalAccountPage`      | Compte externe (identifiants)            |
| `/sheet/:id`               | `SheetPage`                | Fiche SIT                                |
| `/time-entry`              | `TimeEntryPage`            | Redirige vers la saisie de temps Odoo    |
| `/login`                   | —                          | Déclenche la redirection OIDC            |
| `/logout`                  | —                          | Efface la session et redirige vers login |
| `/*`                       | `NotFoundPage`             | Page 404                                 |

---

## Authentification

Stargate utilise **OIDC/OAuth2** via `connect.raccourci.fr` (prod) ou `connect.rc-preprod.com` (preprod).

- **Client ID :** `stargate`
- **Session :** cookie `STARGATESESSION`
- **Callback :** géré côté serveur via `/api/idp/callback`
- **Garde de route :** tout utilisateur non authentifié est redirigé vers `/login` avant chaque navigation

---

## Installation & développement

**Prérequis :** [Bun](https://bun.sh/) et Node.js `^20.19.0` ou `>=22.12.0`

```sh
# Installer les dépendances
bun install

# Lancer le serveur de développement (HMR activé)
bun dev
```

Le serveur de développement proxifie automatiquement les requêtes `/api/*` vers le backend local sur `http://localhost:8081/v2/erp`.
Pour lancer l'application en dev, il faut donc que l'API Ktor `ERP` (repo: https://git.rc-prod.com/raccourci/erp/erp_api_ktor) tourne sur la machine du développeur.

---

## Scripts disponibles

| Commande           | Description                                     |
| ------------------ | ----------------------------------------------- |
| `bun dev`          | Serveur de développement avec HMR               |
| `bun run build`    | Type-check + build de production (en parallèle) |
| `bun preview`      | Prévisualisation du build de production         |
| `bun lint`         | Lint avec ESLint (auto-fix + cache)             |
| `bun format`       | Formatage de `src/` avec Prettier               |
| `bun run test`     | Tests unitaires en mode watch (Vitest)          |
| `bun run test:e2e` | Tests E2E (Playwright, Chromium)                |

---

## Configuration

### Proxy de développement (`vite.config.ts`)

```
/api/* → http://localhost:8081/v2/erp
```

### Alias

```
@ → ./src
```

### ESLint

Configuration flat config avec `eslint-plugin-vue` (niveau `essential`) et `@vue/eslint-config-typescript`. La règle `vue/multi-word-component-names` est désactivée.

### Hooks Git (Husky)

`husky` configure des hooks Git pour lancer automatiquement des checks côté développeur avant certaines actions (commit/push).

Dans ce projet, les hooks principaux sont :

- `pre-commit` : exécute `bunx lint-staged` (lint/format uniquement sur les fichiers _staged_ selon la config `lint-staged` de `package.json`).
- `commit-msg` : exécute `bunx commitlint --edit "$1"` pour valider le message de commit (règles Conventional Commits via `@commitlint/config-conventional`).
- `pre-push` : exécute `bun run test:ci` (lance `vitest run`) avant d'envoyer des commits.

---

## Tests

Les tests unitaires utilisent **Vitest** avec l'environnement **jsdom**.

```sh
bun run test
```

Pour tester un fichier, placez le test dans un dossier `__tests__/` situé au même niveau que le fichier testé, avec un nom `<filename>.spec.ts`.
Les tests `e2e/**` sont exclus de la configuration Vitest.

### Tests E2E (Playwright)

Les tests E2E utilisent **Playwright** (navigateur réel, **Chromium**).

```sh
bun run test:e2e
```

- Pour lancer un seul fichier : `bunx playwright test e2e/pages/<fichier>-page.spec.ts`

- Emplacement : `e2e/pages/*-page.spec.ts` (et `playwright.config.ts` pour la config)
- Auth : l’app n’est “logged in” qu’après chargement de `/api/stargate/user` ; les tests doivent donc mock cette route avant de faire `goto` (sinon la garde redirige vers `/login`)
- Routage : l’app utilise le hash routing (ex. `page.goto('/#/customer')`)

---

## Documentation

Pour les détails sur les schémas ORM et les conventions internes, voir :

- [`documentation/index.md`](./documentation/index.md)

---

## Contribuer

### Convention de commits

Les messages de commit suivent la convention [**Conventional Commits**](https://www.conventionalcommits.org/), vérifiée automatiquement par `commitlint` au hook `commit-msg`.

Format : `<type>(<scope>): <description>`

| Type       | Usage                                             |
| ---------- | ------------------------------------------------- |
| `feat`     | Nouvelle fonctionnalité                           |
| `fix`      | Correction de bug                                 |
| `refactor` | Refactoring sans changement de comportement       |
| `style`    | Changements de style (formatage, espaces, etc.)   |
| `docs`     | Documentation uniquement                          |
| `test`     | Ajout ou modification de tests                    |
| `chore`    | Tâches de maintenance (deps, CI, config)          |
| `perf`     | Amélioration de performance                       |
| `ci`       | Changements liés à la CI/CD                       |
| `build`    | Changements affectant le build ou les dépendances |
| `revert`   | Revenir sur un commit précédent                   |

Exemples :

```
feat(customer): add invoice export button
fix(datepicker): correct month/year model binding
refactor(orm): simplify search query builder
test(deal-list): add e2e tests for filter controls
```

### Workflow

1. Créer une branche depuis `release`
2. Développer avec des commits conventionnels
3. Ouvrir une Merge Request vers `release`
4. Passer la CI (lint, type-check, tests unitaires, tests E2E)
5. Review par au moins un pair, puis merge

### Hooks Git automatiques

Les hooks suivants sont exécutés automatiquement via **Husky** :

| Hook         | Action                                                 |
| ------------ | ------------------------------------------------------ |
| `pre-commit` | `lint-staged` — lint + format sur les fichiers staged  |
| `commit-msg` | `commitlint` — valide le format du message de commit   |
| `pre-push`   | `vitest run` — lance les tests unitaires avant le push |

---

## IDE recommandé

### VS Code

- **Éditeur :** [VS Code (ou variante)](https://code.visualstudio.com/)

#### Extensions recommandées

| Extension                                                                                                  | Rôle                                                                |
| ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [Vue - Official (Volar)](https://marketplace.visualstudio.com/items?itemName=Vue.volar)                    | Support Vue 3 + TypeScript — **désactiver Vetur** s'il est installé |
| [Tailwind CSS IntelliSense](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) | Autocomplétion et preview des classes Tailwind                      |
| [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)                       | Lint intégré à l'éditeur                                            |
| [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)                     | Formatage automatique à la sauvegarde                               |
| [EditorConfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig)              | Applique les conventions `.editorconfig`                            |
| [Commitlint](https://marketplace.visualstudio.com/items?itemName=joshbolduc.commitlint)                    | Validation des messages de commit dans l'éditeur                    |
