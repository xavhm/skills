# ORM “Boundaries”

Dans ce projet, les composants `ORMEntityBoundary` et `ORMEntityListBoundary` servent de “passerelles” entre les vues et la couche ORM (via `useORMApi()`), avec :

- une gestion standardisée du chargement (loader, `loading`)
- un contrat de slot pour rendre l’UI (entité unique vs liste paginée)
- un mécanisme d’injection pour permettre l’édition des entités via `useORMUI()`

Ils s’appuient tous les deux sur les types/filtres définis dans `src/types/ORM.ts` et sur l’appel ORM centralisé `useORMApi().model(...).search(...)`.

---

## ORMEntityBoundary (`src/components/ORMEntityBoundary.vue`)

### Objectif

Récupérer une **entité unique** par son `id`, puis exposer son contenu via un slot. Le composant fournit aussi le contexte nécessaire à l’édition (écriture REST vers l’Odoo backend) aux composants “field” descendants.

### Props

Les props attendues :

- `model`: un `ORMModel` (contient `model` et `schema` Zod, ainsi que des éventuelles “computed”)
- `schema`: la schema Zod de l’entité (principalement pour l’inférence TypeScript ; ce prop n’est pas utilisé directement côté runtime dans le composant)
- `id: number`: identifiant de l’entité à charger
- `source: Selection`: liste des champs à récupérer (incluant les relations via `children`)

Exemple de `source` dans le projet (relations imbriquées) :

```ts
['id', 'name', { field: 'owner_id', children: ['id', 'name', 'image_medium'] }];
```

### Cycle de vie et chargement

Le composant maintient :

- `loaded`: booléen pour contrôler l’affichage du slot
- `entity`: un `defineModel('modelValue')` servant de stockage local (et optionnellement synchronisé si un parent fournit `v-model`)

Quand le composant s’exécute :

1. `onMounted` :
   - si `modelValue` est déjà présent (`entity.value != null`), alors `loaded = true` et aucune requête n’est faite
   - sinon, il déclenche `reload()`
2. `reload()` / `softReload()` :
   - appelle `useORMApi().model(props.model).search(...)`
   - requête : filtre `id == props.id` avec `query: [{ '=': { id: props.id } }]`
   - champ `source`: `props.source`
3. à la réception :
   - si `results[0]` est absent, un toast d’erreur est affiché
   - sinon, l’entité est stockée dans `entity.value` et l’événement `entityLoaded` est émis
4. `watch(props.id)` : recharge dès que l’`id` change
5. `watch(props.source, { deep: true })` : recharge si `source` a réellement changé (comparaison via `JSON.stringify`)

Le loader est affiché tant que `loaded && entity` n’est pas vrai.

### Slot (contrat d’utilisation)

Le slot par défaut reçoit :

- `entity`: l’entité chargée
- `type`: alias de l’entité (utilisé pour l’inférence des composants de champs)
- `schema`: la schema (pour compatibilité, même si la validation runtime dépend de `model.schema` côté `useORMApi`)
- `loading`: booléen (`!loaded`) pour afficher/masquer finement l’UI

Dans les vues, le pattern courant est :

```vue
<ORMEntityBoundary
  :model="SheetModel"
  :schema="SheetModel.schema"
  :source="['id', 'name', { field: 'owner_id', children: ['id', 'name', 'image_medium'] }]"
  :id
  v-slot="{ entity, type }"
>
  <MainPageLayout :breadcrumb-name="`Fiche SIT - ${entity.name}`">
    <template #title>
      Fiche SIT -
      <FieldTextField :type field="name" />
    </template>
  </MainPageLayout>
</ORMEntityBoundary>
```

### Injection pour l’édition (`useORMUI`)

`ORMEntityBoundary` fournit deux clés d’injection :

- `ormUIConfigKey`: `{ model: props.model, id: props.id, reload: softReload }`
- `ormUIEntityKey`: la `Ref` contenant `entity`

Cela permet aux composants “field” (ex: `FieldTextField`, `FieldMany2One`, etc.) qui utilisent `useORMUI()` d’effectuer :

- un `write()` (PATCH) ou un `callFunction()` sur l’entité courante
- puis un refresh via `config.reload()` (ici, `softReload` du boundary)

Autrement dit : `ORMEntityBoundary` ne fait pas que lire, il rend aussi possible l’écriture.

---

## ORMEntityListBoundary (`src/components/ORMEntityListBoundary.vue`)

### Objectif

Récupérer une **liste paginée** d’entités (avec `pageSize` et `nextPage()`), et exposer :

- `entities`: tableau d’entités accumulées (append sur la pagination)
- `loading`: état de chargement (via `v-model:loading` ou via le slot)
- `reload` / `nextPage`: méthodes exposées (via `defineExpose`)

### Props

Les props attendues :

- `model`: un `ORMModel`
- `schema`: schema Zod de l’entité (utilisée pour le fallback du slot par défaut)
- `source: Selection`: liste de champs à récupérer
- `query`: filtres ORM (`ORMQuery['query']`)
- `sort?`: tri (`ORMQuery['sort']`)
- `search?`: texte à chercher
- `searchFields?`: champs sur lesquels s’applique le `search`
- `pageSize?`: taille de page (défaut `200`)

En plus : le composant a aussi un `defineModel<boolean>('loading')`.
Donc, dans les vues, on peut faire :

```vue
<ORMEntityListBoundary v-model:loading="loading" ... />
```

Pour suivre l’état à l’extérieur.

### Comportement de pagination

Le composant maintient :

- `page`: numéro de page (démarre à `1`, et `reload()` met à `0` avant `nextPage()`)
- `entities`: liste accumulée (les pages s’ajoutent : `entities = [...o, ...n]`)
- `loading`: booléen (mis à `true` pendant la requête)

Flux :

1. `onMounted` -> `reload()`
2. `reload()` vide `entities`, remet `page=0`, puis appelle `nextPage()`
3. `nextPage()` :
   - incrémente `page`
   - crée un `AbortController` et annule la requête précédente (`abortController?.abort()`)
   - construit `search` uniquement si `search` et `searchFields` sont fournis
   - appelle `useORMApi().model(props.model).search(...)` avec :
     - `size: props.pageSize`
     - `page: page.value`
     - `source: props.source`
     - `query: props.query`
     - `sort: props.sort`
     - `search` (optionnel)
4. au succès :
   - `entities` est étendu
   - `loading=false`
   - si c’est le premier chargement (`!loaded.value`), alors :
     - `loaded=true`
     - émission de `initialEntitiesLoaded` avec les résultats

### Réactivité (watchers) et debounce

- `watch(props.source, { deep: true })` : recharge si le `source` a réellement changé
- `watch(props.query, { deep: true })` : recharge si le `query` a réellement changé
- `watch(props.search)` :
  - `debounce` de `300ms`
  - puis `reload()`

Le but de ces comparaisons `JSON.stringify` est de limiter les rechargements “parasites” lorsque Vue déclenche un watcher même sans changement réel.

### Exposition de méthodes (`ref` + `defineExpose`)

Le composant expose :

- `reload()`
- `nextPage()`

Exemple d’utilisation avec un `ref` (chargement progressif) :

```vue
<ORMEntityListBoundary
  v-model:loading="loading"
  :model="CustomerModel"
  :schema="CustomerModel.schema"
  :source="[...]"
  :query="[...]"
  :sort="{ name: 'ASC' }"
  :page-size="40"
  :search
  :search-fields="['name']"
  ref="$list"
>
  <template #entities="{ entities, pageSize, loading }">
    <!-- rendu -->
  </template>
</ORMEntityListBoundary>

<Button :loading @click="$list?.nextPage()">Charger plus</Button>
```

Exemple d’utilisation de `reload()` (rechargement après action) dans `DealTable.vue` :

```ts
const reload = () => {
  $ormList.value?.reload();
};
```

### Slot `#entities` (rendu liste)

Le slot nommé `entities` reçoit :

- `entities`
- `reload`
- `pageSize`
- `loading`

Dans la majorité des vues, le pattern est :

```vue
<ORMEntityListBoundary ...>
  <template #entities="{ entities, loading }">
    <!-- Rendre le tableau/kanban -->
  </template>
</ORMEntityListBoundary>
```

Exemple avec `initialEntitiesLoaded` (pour enrichir dynamiquement des filtres UI) :

```vue
<ORMEntityListBoundary
  :model="ProductConfigModel"
  :schema="ProductConfigModel.schema"
  :source="[...relations...]"
  :query="[...query...]"
  @initial-entities-loaded="onEntitiesLoaded"
>
  <template #entities="{ entities, loading }">
    <!-- rendu -->
  </template>
</ORMEntityListBoundary>
```

### Exemple : pagination + recherche (`CustomerListPage.vue`)

```vue
<ORMEntityListBoundary
  v-model:loading="loading"
  :model="CustomerModel"
  :schema="CustomerModel.schema"
  :source="[
    'id',
    'name',
    'email',
    'city',
    'image_medium',
    'phone',
    { field: 'account_type_ids', children: ['id', 'name'] },
  ]"
  :query="[...baseQuery, ...query]"
  :sort="{ name: 'ASC' }"
  :page-size="40"
  :search
  :search-fields="['name']"
  ref="$list"
>
  <template #entities="{ entities, pageSize, loading }">
    <InteractiveGrid class="w-full p-6" :loading>
      <InteractiveGridItem v-for="(entity, i) in entities" :key="i" :i="i % pageSize">
        <CustomerKanbanItem :customer="entity" />
      </InteractiveGridItem>
    </InteractiveGrid>
  </template>
</ORMEntityListBoundary>

<Button :loading @click="$list?.nextPage()">Charger plus</Button>
```

### Exemple : enrichissement de filtres (`CustomerProductsPage.vue`)

```vue
<ORMEntityListBoundary
  :model="ProductConfigModel"
  :schema="ProductConfigModel.schema"
  :source="[...relations...]"
  :query="[...query...]"
  @initial-entities-loaded="onEntitiesLoaded"
>
  <template #entities="{ entities, loading }">
    <Loader v-if="loading" class="m-auto w-10" />
    <!-- rendu -->
  </template>
</ORMEntityListBoundary>
```

Dans `CustomerProductsPage.vue`, `onEntitiesLoaded` s’appuie sur les entités reçues pour construire de nouvelles valeurs de filtre (amélioration UX sans requête additionnelle “spéciale filtre”).

### Exemple : liste filtrée par l’entité parent (`CustomerProfileAboutPage.vue` -> Contacts)

```vue
<ORMEntityListBoundary
  :model="ContactModel"
  :schema="ContactModel.schema"
  :source="['id', 'name', 'email', 'image_medium', 'user_login', 'roles']"
  :query="[{ '=': { parent_id: entity.id } }, ...contactQuery]"
  :sort="{ name: 'ASC' }"
  :search="contactSearch"
  :search-fields="['name', 'email', 'first_name', 'last_name']"
  @initial-entities-loaded="onContactsLoaded"
>
  <template #entities="{ entities, loading }">
    <InteractiveGrid :loading="loading">
      <InteractiveGridItem v-for="(entity, i) in entities" :key="i" :i>
        <ContactKanbanItem :contact="entity" />
      </InteractiveGridItem>
    </InteractiveGrid>
  </template>
</ORMEntityListBoundary>
```

### Slot par défaut (fallback)

Si aucun slot `#entities` n’est fourni, `ORMEntityListBoundary` rend un fallback qui :

- itère sur `entities`
- pour chaque item, enveloppe un `ORMEntityBoundary`
- fournit un slot “par entité” via le slot par défaut du composant parent

Ce fallback sert surtout à réutiliser directement les composants “field” qui dépendent de `ORMEntityBoundary` (contexte d’édition via injection).

---

## Notes pratiques

### Le prop `type` est “fantôme”

Dans les vues, on passe `:type` aux composants de champs (ex: `FieldTextField :type field="name"`).
Ce `type` n’est utilisé que pour l’inférence TypeScript : il n’est pas lu à l’exécution.

### Le format “source” pilote aussi la validation Zod

Côté `useORMApi`, la réponse ORM est validée via Zod en fonction de la `source` demandée. Les boundary ne font pas de magie supplémentaire : elles pilotent `source`/`query` et délèguent l’exécution/validation à `useORMApi`.
