# Champs ORM utilisables (contrat de valeurs)

Les composants “field” situés dans `src/components/fields/` servent de passerelle entre :

- l’entité chargée via `ORMEntityBoundary` (source ORM → `entity.value`)
- les écritures via `useORMUI().write()` (PATCH REST)

Ils reposent sur un contrat simple : chaque composant lit un champ depuis `entity.value[props.field]` et écrit une valeur du même “type logique” dans le payload de PATCH.

> Important : le composant “field” ne remplace pas la définition de votre `source`/`children` dans `ORMEntityBoundary`. Si un champ n’est pas dans `source`, l’UI n’aura pas la donnée.

---

## `FieldTextField` (texte)

- Composant : `src/components/fields/FieldTextField.vue`
- Valeur attendue côté ORM (`entity[field]`) : `string | null` (zéro valeur = `null` / `undefined`)
- Édition : champ texte (`TextField`)
- Écriture : la valeur éditée est envoyée telle quelle via `write()`

Exemple `source` (avec `name`) :

```ts
const source = ['id', 'name', 'email'];
```

Exemple d’entité (valeurs) :

```json
{
  "name": "ACME",
  "email": null
}
```

Exemple d’usage :

```vue
<FieldTextField :type field="name" :icon="Mail">Email</FieldTextField>
```

---

## `FieldNumber` (nombre)

- Composant : `src/components/fields/FieldNumber.vue`
- Valeur attendue côté ORM (`entity[field]`) : `number | null`
- Édition : l’UI manipule une valeur `string | null` (via `TextField`) et la renvoie telle quelle dans le payload de PATCH
- Option : `isPrice` affiche une présentation “prix”
- Prop : `readonly?: boolean`

Exemple d’entité :

```json
{
  "computed_price": 1234.5
}
```

Exemple d’usage :

```vue
<FieldNumber :type field="computed_price" :is-price="true" :readonly="true">
  Prix calculé
</FieldNumber>
```

---

## `FieldBoolean` (booléen)

- Composant : `src/components/fields/FieldBoolean.vue`
- Valeur attendue côté ORM (`entity[field]`) : `boolean | null`
- Affichage : `null` est traité comme `false` à l’écran
- Édition : le `Switch` passe à `true/false` (si le champ ORM est `null`, l’utilisateur repart sur `false`)

Exemple d’entité :

```json
{
  "is_active": true
}
```

Exemple d’usage :

```vue
<FieldBoolean :type field="is_active" :icon="CheckSquare">Actif</FieldBoolean>
```

---

## `FieldMany2One` (relation N:1)

- Composant : `src/components/fields/FieldMany2One.vue`
- Valeur attendue côté ORM (`entity[field]`) :
  - `null`
  - ou un objet “minimal” : `{ id: number; name: string; image_medium?: string }`
- Prop obligatoire : `target-model` (pour le modal de recherche / sélection)
- Prop optionnelle : `name-field?: string` (par défaut `name`) pour contrôler quel attribut de l’objet afficher
- Prop : `readonly?: boolean`
- Pour que la recherche fonctionne, vous renseignez `source?`, `filters?`, `sort?` (optionnels) sur le modal

Exemple de `source` pour charger la relation dans `ORMEntityBoundary` :

```ts
const source = ['id', { field: 'director', children: ['id', 'name', 'image_medium'] }];
```

Exemple d’entité (valeur Many2One) :

```json
{
  "director": { "id": 1, "name": "Jane Doe", "image_medium": "..." }
}
```

Exemple d’usage :

```vue
<FieldMany2One :type field="director" :target-model="ContactModel" :readonly="true">
  Directeur
</FieldMany2One>
```

Cas “champ de nom custom” :

```vue
<FieldMany2One
  :type
  field="sale_order_id"
  :target-model="SaleOrderModel"
  name-field="computed_name"
>
  Devis lié
</FieldMany2One>
```

---

## `FieldList` (relation 1:N / N:N sous forme de liste)

- Composant : `src/components/fields/FieldList.vue`
- Valeur attendue côté ORM (`entity[field]`) :
  - `[]` (ou `undefined` → rendu vide)
  - ou un tableau d’objets “minimal” : `Array<{ id: number; name: string }>`
- Prop obligatoire : `target-model` (pour le modal de recherche / sélection)
- Prop : `tags-mode?: boolean`
  - `true` : rendu en “tags”
  - `false` : rendu en tableau (`AutoTable`)
- Prop : `readonly?: boolean`

Exemple de `source` pour charger la liste (children) :

```ts
const source = ['id', { field: 'sheet_ids', children: ['id', 'name'] }];
```

Exemple d’entité :

```json
{
  "sheet_ids": [
    { "id": 10, "name": "Fiche 10" },
    { "id": 11, "name": "Fiche 11" }
  ]
}
```

Exemple d’usage :

```vue
<FieldList :type field="sheet_ids" :target-model="SheetModel" tags-mode>
  Fiches SIT
</FieldList>
```

---

## `FieldDatePicker` (date)

- Composant : `src/components/fields/FieldDatePicker.vue`
- Valeur attendue côté ORM (`entity[field]`) : `number | null`
- Format : timestamp Unix en **millisecondes** (utilisé tel quel avec `luxon`)
- Édition : `DatePickerInline`
  - l’UI travaille avec un `DateRange` interne
  - l’écriture PATCH renvoie le timestamp (du jour “from”)
- Prop : `readonly?: boolean`

Exemple d’entité :

```json
{
  "activation_date": 1718409600000
}
```

Exemple d’usage :

```vue
<FieldDatePicker :type field="activation_date" :icon="CalendarCheck">
  Date de mise en production
</FieldDatePicker>
```
