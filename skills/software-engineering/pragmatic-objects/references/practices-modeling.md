# Pratiques — Modélisation du domaine

Sources : *Model the Domain*, *Wrap Null*, *Wrap Collections*, *Immutability*, *Forbid Indecisive Objects* — book.pragmatic-objects.com

## Sommaire
- [Model the Domain (primitives → objets)](#model-the-domain-primitives--objets)
- [Wrap Null (Airlocking)](#wrap-null-airlocking)
- [Wrap Collections](#wrap-collections)
- [Immutabilité](#immutabilité)
- [Forbid Indecisive Objects](#forbid-indecisive-objects)

## Model the Domain (primitives → objets)

Une primitive "signifiante" (email, durée, date métier...) n'a de sens que pour l'ordinateur, jamais pour le métier. Dès qu'une primitive porte des **règles ou du comportement** (validation, arithmétique, conversion), elle mérite un objet dédié.

**Test rapide** : "avez-vous déjà entendu un métier parler de `string` ou de `number` ?" Si non, la primitive doit devenir un objet.

```typescript
// String → Value Object
class EmailAddress {
  constructor(private readonly value: string) { /* validate */ }
  localPart(): string { /* ... */ }
  domain(): string { /* ... */ }
  canonicalAddress(): string { /* ... */ }
}

// Number → Value Object
class Duration {
  private constructor(private readonly seconds: number) {}
  static fromSeconds(s: number): Duration { /* ... */ }
  static fromMinutes(m: number): Duration { /* ... */ }
  add(d: Duration): Duration { /* ... */ }
  toSeconds(): number { /* ... */ }
}

// Date → Value Object avec règles métier + dépendances explicites
class DepartureDate {
  private constructor(private readonly value: Date) {}
  static create(date: Date, now: Date): DepartureDate {
    if (date < now) throw new Error("Departure Date cannot be in the past");
    // now est injecté, pas lu depuis Date.now() en interne → testable
  }
}
```

Le coût (quelques lignes de plus) est largement compensé par la documentation vivante que ça produit : les règles métier deviennent visibles et centralisées au lieu d'être dispersées en validations éparses. Argument anti-"perf prématurée" : le coût d'un niveau d'indirection est négligeable comparé au coût d'un logiciel invivable à maintenir — mesurer avant d'optimiser.

## Wrap Null (Airlocking)

Le `null` ne doit **jamais** traverser la couche domaine. Les annotations `@NonNull` ne protègent pas à la compilation dans la plupart des langages — il faut une discipline architecturale, pas une décoration.

**Pattern Airlocking** : une couche "sas" (souvent la couche Service/UseCase) valide et assainit toutes les entrées **avant** qu'elles n'atteignent le domaine. Une fois dans le domaine, on peut supposer qu'aucune valeur n'est `null` de façon non déclarée.

```typescript
// Couche Service = airlock : le domaine n'a plus jamais à vérifier null
class AddDurationCommandHandler {
  execute(a: Duration, b: Duration): Duration {
    Objects.requireNonNull(a);
    Objects.requireNonNull(b);
    return a.add(b); // Duration.add() n'a plus à se soucier de null
  }
}
```

Pour les cas où une absence de valeur est **légitime** (recherche en base par ex.), ne pas mentir sur le type de retour : utiliser un **Optional/Maybe** explicite plutôt qu'un `null` implicite.

```typescript
interface IUserRepository {
  byId(id: string): Optional<User>;
}
// Le client choisit explicitement comment traiter l'absence :
const user = repo.byId(id).orElseThrow(() => new Error("no user found"));
```

## Wrap Collections

Une collection métier (liste d'utilisateurs, de produits...) est un **concept**, pas un simple array/Map. L'implémentation interne (array, linked-list) est un détail — les autres objets n'ont pas à le savoir.

```typescript
class UsersCollection extends Collection<User> {
  legalUsers(): User[] { /* logique de filtrage encapsulée ici */ }
  deleteUnderages(): void { /* ... */ }
}
```

Sans classe dédiée, toute logique de filtre/recherche/agrégation finit dispersée en code procédural dans les objets appelants (boucles `for`, `filter` ad hoc répétés). → Voir aussi [Inherit Wisely — Extensions Only](practices-structure.md#quand-lhéritage-concret-a-du-sens) pour la justification de ce cas d'héritage concret.

## Immutabilité

Deux enseignements distincts, à ne pas confondre :

**1. Regrouper les mutations, même sur un objet mutable.** Illustré par le kata *Gilded Rose* : le pire bug est un enchaînement de mutations dispersées dans des conditions imbriquées. Solution : calculer un **delta immuable** via des fonctions pures nommées, puis muter en **un seul endroit**, en fin de méthode.

```typescript
updateOneItemQuality(item: Item) {
  const delta = this.qualityUpdate(item); // calcul pur, pas de mutation
  item.sellIn--;
  item.quality = this.clamp(item, delta); // mutation groupée, unique
}
```

**2. Rendre un objet réellement immuable quand c'est pertinent.** Un objet est un bon candidat à l'immutabilité si :
- deux instances sont égales dès lors que leur représentation "bits" est identique (pas d'identité propre) ;
- l'objet a des opérations de type arithmétique (addition, comparaison...).

C'est exactement la définition d'un [Value Object](patterns.md#value-object) : chaque opération retourne une **nouvelle instance**, jamais une mutation en place.

```typescript
class Seconds {
  constructor(private value: number) { if (value < 0) throw new Error(...); }
  difference(other: Seconds): Seconds { return new Seconds(Math.abs(this.value - other.value)); }
}
```

**Contre-indication** : les **Entités** à cycle de vie long (un `User` qu'on renomme reste la même personne) ne sont pas de bons candidats à l'immutabilité — leur identité prime sur leur état.

## Forbid Indecisive Objects

Un **objet indécis** se comporte comme deux (ou plus) objets selon un état interne (souvent un booléen, parfois une combinaison de conditions).

**Forme évidente** (booléen pivot) :
```typescript
// Mauvais : un seul DateRange qui se comporte différemment selon inBusinessDays
class DateRange {
  isInRange(date: Date) { if (this.inBusinessDays) { /* A */ } else { /* B */ } }
}

// Bon : deux classes distinctes, chacune avec un seul comportement
class BusinessDateRange { isInRange(date: Date) { /* A */ } }
class DateRange { isInRange(date: Date) { /* B */ } }
```

**Forme subtile** (conditions combinées) : des `if` imbriqués sur plusieurs axes (année × type d'entité, etc.) cachent souvent un ou plusieurs concepts de domaine non extraits. Méthode de refactoring :
1. Réorganiser les `if` par axe le plus stable/porteur de sens métier en premier (ex. type d'entité avant année).
2. Si un axe correspond à un concept métier récurrent → l'extraire en classe dédiée (`CompanyTax`, `CitizenTax`).
3. N'introduire une interface commune que **s'il existe un objet qui a réellement besoin de manipuler ces variantes de façon polymorphe** ; sinon, ce n'est pas nécessaire.

**Signal d'alerte à surveiller** : tout `if`/`switch` qui n'est ni dans une factory/méthode statique de création, ni ne s'exécute en début de méthode pour toute sa durée. Un objet indécis est difficile à comprendre (il faut connaître son état pour savoir ce qu'il fait), difficile à tester (cyclomatic complexity élevée) et son cycle de vie mutable aggrave le problème.
